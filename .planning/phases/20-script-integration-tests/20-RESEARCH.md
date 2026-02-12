# Phase 20: Script Integration Tests - Research

**Researched:** 2026-02-12
**Domain:** BATS integration testing of CLI scripts -- help contracts, execute-mode safety, and dynamic script discovery
**Confidence:** HIGH

## Summary

Phase 20 writes CLI contract tests for all scripts in the project. The infrastructure (BATS v1.13.0, bats-assert v2.2.0, bats-file v0.4.0) and unit test patterns are established from Phases 18-19 with 55 passing tests. This phase tests scripts as black boxes via `run bash script.sh`, never via `source`.

The project has 68 testable scripts: 63 using the `parse_common_args` pattern (which handles `--help`, `-v`, `-q`, `-x`), 4 diagnostic/utility scripts using the older `[[ "${1:-}" =~ ^(-h|--help)$ ]]` pattern, and 1 (`check-docs-completeness.sh`) that has no `--help` support and should be excluded. All 67 testable scripts define `show_help()` with `Usage:` in their output.

The critical design decision is dynamic test generation. BATS v1.13.0 provides `bats_test_function` (introduced v1.11.0) for runtime test registration. This allows iterating over discovered script paths and registering a separate `@test` per script, giving individual pass/fail reporting per script in TAP output. This is the correct mechanism for INTG-03 (dynamic discovery). Without it, we would be forced into a single `@test` with a loop, which gives poor diagnostics (one failure masks all).

For mocking (INTG-04), the key insight is that `--help` is processed BEFORE `require_cmd` in every script -- so INTG-01 tests need zero mocks. For INTG-02 (`-x` piped stdin rejection), scripts must pass `require_cmd` to reach `confirm_execute`, so mocks are needed. The mock strategy is lightweight: create empty executables in `$BATS_FILE_TMPDIR/bin/` and prepend to PATH. The mock never needs to do anything -- it just needs to exist so `command -v <tool>` succeeds.

**Primary recommendation:** Use `bats_test_function` for dynamic per-script test registration. Discover scripts via `find scripts/ -name '*.sh'` with exclusions for `lib/`, `common.sh`, and `check-docs-completeness.sh`. Create one integration test file (`tests/intg-cli-contracts.bats`) with three test groups: help contract, execute-mode rejection, and flag handling. Use `setup_file` to create mock binaries once per file.

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| bats-core | v1.13.0 | Test runner with `bats_test_function` dynamic registration | Already installed. Dynamic test registration available since v1.11.0. |
| bats-assert | v2.2.0 | `assert_success`, `assert_failure`, `assert_output --partial` | Already installed. Pattern matching for "Usage:" in output. |
| bats-file | v0.4.0 | Filesystem assertions | Already installed. Not primary for this phase but available. |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| bats-support | v0.3.0 | Base support for bats-assert | Loaded automatically by common-setup.bash |

### Alternatives Considered

No new libraries needed. Everything is in place from Phase 18.

**Installation:**

No installation needed.

## Architecture Patterns

### Test File Organization

```
tests/
  smoke.bats              # Phase 18 (5 tests) -- DO NOT MODIFY
  lib-args.bats           # Phase 19 UNIT-01 -- DO NOT MODIFY
  lib-validation.bats     # Phase 19 UNIT-02 -- DO NOT MODIFY
  lib-logging.bats        # Phase 19 UNIT-03 -- DO NOT MODIFY
  lib-cleanup.bats        # Phase 19 UNIT-04 -- DO NOT MODIFY
  lib-output.bats         # Phase 19 UNIT-05 -- DO NOT MODIFY
  lib-retry.bats          # Phase 19 UNIT-06 -- DO NOT MODIFY
  intg-cli-contracts.bats # Phase 20: Integration tests (NEW)
  test_helper/
    common-setup.bash     # Phase 18 shared helper -- DO NOT MODIFY
    bats-support/         # submodule
    bats-assert/          # submodule
    bats-file/            # submodule
```

**One file for all integration tests:** All four requirements (INTG-01 through INTG-04) share the same script discovery logic and mock infrastructure. Splitting into multiple files would duplicate the discovery and mock setup. A single file with clearly separated sections is cleaner.

**Why `intg-` prefix:** Distinguishes from `lib-` (unit) tests. Sorts after `lib-` in directory listings.

### Pattern 1: Dynamic Test Registration with `bats_test_function`

**What:** Register individual tests at file load time by iterating over discovered scripts. Each script gets its own `@test` with a descriptive name.

**When to use:** Any time you need one test per item from a dynamic list (files, configs, etc.).

**Example:**

```bash
#!/usr/bin/env bats
# tests/intg-cli-contracts.bats

# --- Script Discovery ---
# Runs at file load time (before any tests execute)
PROJECT_ROOT="$(git rev-parse --show-toplevel)"

discover_scripts() {
    find "${PROJECT_ROOT}/scripts" -name '*.sh' \
        -not -path '*/lib/*' \
        -not -name 'common.sh' \
        -not -name 'check-docs-completeness.sh' \
        | sort
}

# --- Help Contract Tests (INTG-01) ---
# Every script: --help exits 0, output contains "Usage:"

help_contract_test() {
    local script="$1"
    run bash "$script" --help
    assert_success
    assert_output --partial "Usage:"
}

while IFS= read -r script; do
    # Create human-readable test name from path
    local_path="${script#${PROJECT_ROOT}/}"
    bats_test_function --description "${local_path}: --help exits 0 and shows Usage" \
        -- help_contract_test "$script"
done < <(discover_scripts)
```

**Why `bats_test_function`:** Each script gets its own TAP line. If `scripts/nmap/examples.sh` fails, you see exactly which one failed. With a loop inside a single `@test`, the first failure would abort and mask all remaining scripts.

**Important:** `bats_test_function` registers tests at file parse time (free code). The test function (`help_contract_test`) runs later during test execution, where `setup()` has already loaded assertion libraries.

### Pattern 2: Mock Commands via PATH Prepend

**What:** Create minimal executable files in a temp directory and prepend that directory to PATH. This makes `command -v <tool>` succeed without installing actual tools.

**When to use:** INTG-02 tests that need scripts to pass `require_cmd` on CI runners lacking pentesting tools.

**Example:**

```bash
setup_file() {
    load 'test_helper/common-setup'
    _common_setup

    # Create mock binaries directory (persists across all tests in this file)
    MOCK_BIN="${BATS_FILE_TMPDIR}/mock-bin"
    mkdir -p "$MOCK_BIN"
    export MOCK_BIN

    # Create mock executables for all tools used by require_cmd
    local tools=(
        nmap tshark msfconsole msfvenom aircrack-ng hashcat skipfish
        sqlmap hping3 john nikto foremost dig curl nc traceroute mtr
        gobuster ffuf
    )
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            printf '#!/bin/sh\nexit 0\n' > "${MOCK_BIN}/${tool}"
            chmod +x "${MOCK_BIN}/${tool}"
        fi
    done
}

setup() {
    load 'test_helper/common-setup'
    _common_setup

    # Prepend mock bin to PATH for each test
    export PATH="${MOCK_BIN}:${PATH}"
}
```

**Why `setup_file` for mock creation:** Mock binaries are the same for all tests. Creating them once in `setup_file` (which runs once per `.bats` file) avoids redundant filesystem work. `$BATS_FILE_TMPDIR` is cleaned up automatically after all tests in the file complete.

**Why conditional mock creation (`if ! command -v`):** On the developer's machine where nmap IS installed, we use the real binary (makes `command -v` succeed). On CI where it's missing, the mock takes effect. This means tests work identically in both environments.

### Pattern 3: Execute-Mode Piped Stdin Rejection Test

**What:** Test that scripts with `-x` flag reject piped (non-interactive) stdin by exiting with status 1.

**When to use:** INTG-02 tests for all scripts that call `confirm_execute`.

**Example:**

```bash
execute_mode_rejection_test() {
    local script="$1"
    # Pipe stdin to make it non-interactive, pass -x and a dummy target
    run bash -c "echo '' | bash '$script' -x dummy_target 2>&1"
    assert_failure
    assert_output --partial "interactive terminal"
}
```

**Key insight:** The pipe (`echo '' |`) makes stdin non-interactive (`[[ ! -t 0 ]]` is true). The script calls `confirm_execute` which detects this and exits 1 with the message "Execute mode requires an interactive terminal for confirmation".

**Which scripts to test:** Only scripts that call `confirm_execute` -- the 63 scripts using `parse_common_args`. The 4 diagnostic/utility scripts do not support `-x` and should be excluded from this test group.

### Pattern 4: Script Discovery via find with Exclusions

**What:** Discover all testable scripts at runtime using `find` with path exclusions.

**When to use:** INTG-03 requirement -- no hardcoded script lists.

**Example:**

```bash
# All scripts that source common.sh and define show_help
discover_scripts() {
    find "${PROJECT_ROOT}/scripts" -name '*.sh' \
        -not -path '*/lib/*' \
        -not -name 'common.sh' \
        -not -name 'check-docs-completeness.sh' \
        | sort
}

# Scripts that support -x (have parse_common_args, which implies confirm_execute)
discover_execute_mode_scripts() {
    find "${PROJECT_ROOT}/scripts" -name '*.sh' \
        -not -path '*/lib/*' \
        -not -name 'common.sh' \
        -not -name 'check-docs-completeness.sh' \
        -not -path '*/diagnostics/*' \
        -not -name 'check-tools.sh' \
        | sort
}
```

**Why `find` not glob:** Bash globs like `scripts/*/*.sh` include `scripts/lib/*.sh`. Excluding with glob patterns is fragile. `find` with `-not -path` is explicit and readable.

**Why sort:** Deterministic test ordering across runs and platforms.

**Adding a new script automatically includes it:** When someone adds `scripts/newtool/examples.sh`, the `find` discovers it. No test file modifications needed.

### Anti-Patterns to Avoid

- **Hardcoded script lists:** `SCRIPTS=(scripts/nmap/examples.sh ...)` violates INTG-03 and creates maintenance burden.
- **Sourcing scripts instead of running them:** Scripts call `exit`, `require_cmd`, and interactive prompts. Use `run bash script.sh`, never `source script.sh`.
- **Testing without NO_COLOR:** Without `NO_COLOR=1`, script output contains ANSI escape codes that break `assert_output --partial "Usage:"` matching. Export NO_COLOR=1 before running scripts.
- **Single `@test` with loop:** A loop inside one test gives poor diagnostics -- first failure aborts loop, hiding remaining script failures.
- **Mocking tools that ARE installed:** Only create mocks for missing tools. The `if ! command -v` guard prevents overriding real installations.
- **Using `run --separate-stderr`:** For integration tests, we want combined output. Use plain `run` -- the warn message from `confirm_execute` goes to stdout (via warn() which uses echo, not >&2) -- wait, let me verify.

## Important: stderr vs stdout in Script Output

**Verified from source code:**

- `error()` in `logging.sh` writes to stderr (`>&2`)
- `warn()` in `logging.sh` writes to stdout (no redirection)
- `info()` in `logging.sh` writes to stdout

For INTG-02, `confirm_execute` calls `warn "Execute mode requires an interactive terminal for confirmation"` then `exit 1`. Since `warn()` writes to stdout, `assert_output --partial "interactive terminal"` with plain `run` will capture it.

However, `require_cmd` failure calls `error()` which writes to stderr. If the mock is missing and `require_cmd` fails, the error message would be on stderr, not captured by plain `run`. This reinforces why mocks must be correct -- we want the script to reach `confirm_execute`, not fail at `require_cmd`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Per-script test generation | Manual `@test` per script | `bats_test_function` dynamic registration | Scales to any number of scripts, no maintenance |
| Mock command framework | bats-mock library or complex stubs | Simple `printf '#!/bin/sh\nexit 0\n'` files | Mocks only need to exist, not behave -- `command -v` is the only check |
| Script list maintenance | Hardcoded array of script paths | `find` with exclusions | New scripts automatically included |
| Test isolation | Manual PATH cleanup | `$BATS_FILE_TMPDIR` auto-cleanup + per-test subshell PATH | BATS handles cleanup; PATH modifications in setup() don't leak between tests |
| Combined stdout/stderr capture | Manual `2>&1` redirections | BATS `run` (captures both by default) | Built-in behavior |

**Key insight:** The mock strategy is deliberately minimal. We are NOT testing that scripts execute correctly with tools -- we are testing CLI contracts (help output, stdin safety). The mocks exist solely to pass `require_cmd` so scripts reach the code paths we actually test.

## Common Pitfalls

### Pitfall 1: `bats_test_function` Runs at Parse Time, Not Test Time

**What goes wrong:** Code in the `bats_test_function` registration loop runs when BATS parses the file, before `setup_file()` or `setup()`. If the registration code depends on variables set in `setup_file()`, those variables are undefined.

**Why it happens:** BATS preprocesses `.bats` files, executing free code during the gather phase. `bats_test_function` calls at free code level register tests for later execution.

**How to avoid:** Perform script discovery at file level (free code) using `find` with hardcoded paths (or `git rev-parse --show-toplevel`). Do NOT depend on `$PROJECT_ROOT` from `_common_setup` -- compute it independently at file level.

**Warning signs:** "command not found" errors during BATS file preprocessing, empty test lists, zero tests discovered.

### Pitfall 2: Scripts With `require_target` Need a Dummy Argument

**What goes wrong:** 11 examples.sh scripts call `require_target "${1:-}"` and exit 1 if no target is provided. Running `bash script.sh -x` without a target fails at `require_target`, not at `confirm_execute`.

**Why it happens:** `parse_common_args -x` consumes the `-x` flag, leaving REMAINING_ARGS empty. `require_target` sees no argument and exits.

**How to avoid:** Always pass a dummy target in INTG-02 tests: `bash script.sh -x dummy_target`. For scripts that don't need a target, the extra argument is harmless (it goes into REMAINING_ARGS and the script uses a default).

**Which scripts:** nmap/examples.sh, nikto/examples.sh, hping3/examples.sh, netcat/examples.sh, sqlmap/examples.sh, curl/examples.sh, dig/examples.sh, gobuster/examples.sh, ffuf/examples.sh, skipfish/examples.sh, traceroute/examples.sh (all 11 have `require_target`).

**Warning signs:** Tests failing with "Usage: script <target>" error messages instead of "interactive terminal" rejection.

### Pitfall 3: ANSI Color Codes in Script Output

**What goes wrong:** Without `NO_COLOR=1`, scripts output ANSI escape sequences (e.g., `\033[31m`). `assert_output --partial "Usage:"` still matches because `--partial` does substring matching, but output diffs in failure messages become unreadable.

**Why it happens:** `colors.sh` sets color variables based on `NO_COLOR` and terminal detection.

**How to avoid:** Export `NO_COLOR=1` in `setup()` (already done by `_common_setup`). For integration tests running scripts as subprocesses, also pass `NO_COLOR=1` in the environment: `run env NO_COLOR=1 bash script.sh --help`.

**Warning signs:** Assertion failure messages containing `\033[` escape codes.

### Pitfall 4: Script Sourcing common.sh Fails on Old Bash

**What goes wrong:** `common.sh` line 11 requires Bash 4.0+. If the system bash is 3.x (macOS default), scripts fail immediately.

**Why it happens:** macOS ships Bash 3.2. The project requires Bash 4.0+ installed via Homebrew.

**How to avoid:** Run scripts with the same `bash` that BATS uses (which is Bash 4+ if installed via Homebrew). Since BATS itself needs Bash 3.2+, and scripts need 4.0+, ensure the PATH includes Homebrew's bash. CI runners (ubuntu-latest) have Bash 5.x, so this is only a local dev concern.

**Warning signs:** "Bash 4.0+ required" error in test output.

### Pitfall 5: `find` Output Order Varies Between Platforms

**What goes wrong:** `find` output order is filesystem-dependent. Tests may pass on ext4 (Linux) but discover scripts in different order on APFS (macOS). While order doesn't affect correctness, non-deterministic test names make TAP output harder to compare across runs.

**Why it happens:** Different filesystems enumerate directory entries in different orders.

**How to avoid:** Always pipe `find` through `sort`. This is already shown in the patterns above.

**Warning signs:** Test names appearing in different order between local and CI runs.

### Pitfall 6: Diagnostics Scripts Use Old Help Pattern

**What goes wrong:** The 4 scripts using `[[ "${1:-}" =~ ^(-h|--help)$ ]]` only recognize `-h` or `--help` as the FIRST argument. Passing `bash script.sh --verbose --help` would NOT trigger help for these scripts (it would try to run with `--verbose` as the target).

**Why it happens:** The old pattern does a simple first-argument check, unlike `parse_common_args` which parses all arguments.

**How to avoid:** Test `--help` as the first (and only) argument: `run bash script.sh --help`. This works for BOTH patterns (parse_common_args handles it anywhere, old pattern handles it as first arg).

**Warning signs:** Diagnostics scripts failing the `--help` test because `--help` was not the first argument.

## Code Examples

### Complete Integration Test File Structure

```bash
#!/usr/bin/env bats
# tests/intg-cli-contracts.bats -- CLI contract tests for all scripts
# INTG-01: --help exits 0 and output contains "Usage:"
# INTG-02: -x rejects piped (non-interactive) stdin
# INTG-03: Scripts discovered dynamically (no hardcoded lists)
# INTG-04: Tests pass on CI without pentesting tools (via mock commands)

# --- File-Level Setup (runs at parse time) ---
PROJECT_ROOT="$(git rev-parse --show-toplevel)"

# Discover all testable scripts (INTG-03)
_discover_all_scripts() {
    find "${PROJECT_ROOT}/scripts" -name '*.sh' \
        -not -path '*/lib/*' \
        -not -name 'common.sh' \
        -not -name 'check-docs-completeness.sh' \
        | sort
}

# Discover scripts that support -x execute mode
# (have parse_common_args which implies confirm_execute)
_discover_execute_mode_scripts() {
    find "${PROJECT_ROOT}/scripts" -name '*.sh' \
        -not -path '*/lib/*' \
        -not -name 'common.sh' \
        -not -name 'check-docs-completeness.sh' \
        -not -path '*/diagnostics/*' \
        -not -name 'check-tools.sh' \
        | sort
}

# --- Test Functions ---

# INTG-01: Help contract
_test_help_contract() {
    local script="$1"
    run env NO_COLOR=1 bash "$script" --help
    assert_success
    assert_output --partial "Usage:"
}

# INTG-02: Execute mode rejects piped stdin
_test_execute_mode_rejects_pipe() {
    local script="$1"
    # Pipe stdin to make it non-interactive; pass -x and dummy target
    run bash -c "echo '' | NO_COLOR=1 bash '$script' -x dummy_target 2>&1"
    assert_failure
    assert_output --partial "interactive terminal"
}

# --- Dynamic Test Registration (INTG-03) ---

# Register INTG-01 tests
while IFS= read -r script; do
    local_path="${script#${PROJECT_ROOT}/}"
    bats_test_function \
        --description "INTG-01 ${local_path}: --help exits 0 with Usage" \
        -- _test_help_contract "$script"
done < <(_discover_all_scripts)

# Register INTG-02 tests
while IFS= read -r script; do
    local_path="${script#${PROJECT_ROOT}/}"
    bats_test_function \
        --description "INTG-02 ${local_path}: -x rejects piped stdin" \
        -- _test_execute_mode_rejects_pipe "$script"
done < <(_discover_execute_mode_scripts)
```

### setup_file with Mock Commands (INTG-04)

```bash
setup_file() {
    load 'test_helper/common-setup'
    _common_setup

    # Create mock binaries for tools not installed on this system
    MOCK_BIN="${BATS_FILE_TMPDIR}/mock-bin"
    mkdir -p "$MOCK_BIN"
    export MOCK_BIN

    local tools=(
        nmap tshark msfconsole msfvenom aircrack-ng hashcat skipfish
        sqlmap hping3 john nikto foremost dig curl nc traceroute mtr
        gobuster ffuf
    )
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            printf '#!/bin/sh\nexit 0\n' > "${MOCK_BIN}/${tool}"
            chmod +x "${MOCK_BIN}/${tool}"
        fi
    done
}

setup() {
    load 'test_helper/common-setup'
    _common_setup
    # Prepend mock bin to PATH
    export PATH="${MOCK_BIN}:${PATH}"
}
```

### Verifying Dynamic Discovery Works

```bash
# Static test to verify discovery finds expected script count
@test "INTG-03: dynamic discovery finds all scripts" {
    local count
    count=$(_discover_all_scripts | wc -l | tr -d ' ')
    # Should find 67+ scripts (may grow as new tools are added)
    assert [ "$count" -ge 67 ]
}

@test "INTG-03: no hardcoded script paths in test file" {
    # Self-referential check: this test file should not contain
    # hardcoded paths to individual tool scripts
    local test_file="${PROJECT_ROOT}/tests/intg-cli-contracts.bats"
    run grep -c 'scripts/nmap/examples.sh' "$test_file"
    assert_output "0"
}
```

## Script Categories and Test Applicability

### Category A: parse_common_args Scripts (63 scripts)

These scripts follow the standard pattern:
1. `source common.sh`
2. `show_help()` definition
3. `parse_common_args "$@"` -- handles `-h`/`--help` before anything else
4. `require_cmd <tool>` -- checked AFTER help
5. `confirm_execute` -- checked AFTER require_cmd

**INTG-01 applies:** Yes. `--help` handled by `parse_common_args` before `require_cmd`. No mocks needed.
**INTG-02 applies:** Yes. Need mocks to pass `require_cmd` and reach `confirm_execute`.

### Category B: Old-Pattern Scripts (4 scripts)

`check-tools.sh`, `diagnostics/connectivity.sh`, `diagnostics/dns.sh`, `diagnostics/performance.sh`.

Pattern: `[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0` before `require_cmd`.

**INTG-01 applies:** Yes. `--help` checked before `require_cmd`. No mocks needed.
**INTG-02 does NOT apply:** These scripts do not support `-x` execute mode.

### Category C: Excluded (2 files)

`common.sh` (library entry point, not a script) and `check-docs-completeness.sh` (no common.sh, no show_help, different purpose).

**Neither INTG-01 nor INTG-02 applies.**

### Tool-to-Script Mapping for Mocks

| Tool | Scripts Using It | Count |
|------|-----------------|-------|
| nmap | nmap/*.sh | 4 |
| tshark | tshark/*.sh | 4 |
| msfconsole | metasploit/examples.sh, scan-network-services.sh, setup-listener.sh | 3 |
| msfvenom | metasploit/generate-reverse-shell.sh | 1 |
| aircrack-ng | aircrack-ng/*.sh | 4 |
| hashcat | hashcat/*.sh | 4 |
| skipfish | skipfish/*.sh | 3 |
| sqlmap | sqlmap/*.sh | 4 |
| hping3 | hping3/*.sh | 3 |
| john | john/*.sh | 4 |
| nikto | nikto/*.sh | 4 |
| foremost | foremost/*.sh | 4 |
| dig | dig/*.sh, diagnostics/dns.sh, diagnostics/connectivity.sh | 6 |
| curl | curl/*.sh, diagnostics/connectivity.sh | 4 |
| nc | netcat/*.sh | 4 |
| traceroute | traceroute/*.sh (3), diagnostics/performance.sh | 4 |
| mtr | traceroute/diagnose-latency.sh | 1 |
| gobuster | gobuster/*.sh | 3 |
| ffuf | ffuf/*.sh | 2 |

Total: 19 tools to mock (if missing).

## Expected Test Count

| Requirement | Count | Notes |
|-------------|-------|-------|
| INTG-01 (--help) | 67 | All scripts except common.sh and check-docs-completeness.sh |
| INTG-02 (-x rejection) | 63 | Only parse_common_args scripts (excludes diagnostics + check-tools) |
| INTG-03 (discovery verification) | 1-2 | Meta-tests verifying discovery works |
| Total | ~132 | Will grow automatically as scripts are added |

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Loop in single `@test` | `bats_test_function` per-script registration | bats-core v1.11.0 (2024-03-24) | Individual TAP lines per script, better diagnostics |
| bats-mock library | Simple `printf` stub executables | N/A | Zero dependency, mocks only need to pass `command -v` |
| Hardcoded script arrays | `find` with exclusions | Best practice | New scripts auto-discovered |
| System tool dependency | PATH-prepended mocks | Best practice | CI runners work without pentesting tools |

**Deprecated/outdated:**
- **bats-mock / bash_shell_mock:** Overkill for this use case. We don't need to verify mock invocations or stub complex behavior. A `#!/bin/sh\nexit 0` file is sufficient.
- **bats-detik:** Kubernetes testing, irrelevant.
- **Running individual `bats` files per tool:** Duplicates discovery logic. One file with dynamic registration is cleaner.

## Open Questions

1. **Should `check-tools.sh` be included in INTG-01?**
   - What we know: It defines `show_help()` with "Usage:" and handles `--help` via the old pattern. It sources `common.sh`.
   - What's unclear: Its help check only works when `--help` is the first argument. With `parse_common_args`, `--help` works in any position.
   - Recommendation: YES, include it in INTG-01. Testing `bash check-tools.sh --help` with `--help` as first arg works for both patterns. The test passes `--help` as the only argument, so position doesn't matter.

2. **Should diagnostics scripts be included in INTG-02?**
   - What we know: They don't use `parse_common_args` or `confirm_execute`. They have no `-x` support.
   - Recommendation: NO, exclude from INTG-02. Only test scripts that have the `-x` contract.

3. **What if `bats_test_function` doesn't work with `setup()` assertions?**
   - What we know: `bats_test_function` registers test functions that are called during test execution. The `setup()` function runs before each test, loading assertion libraries. The test function should have access to assertions.
   - What's unclear: Whether `load` and `_common_setup` work correctly in dynamically registered tests.
   - Recommendation: Build a minimal proof first (1-2 dynamic tests), then scale. If `setup()` doesn't fire for dynamic tests, move `load` into the test function itself.

4. **Performance with 130+ tests?**
   - What we know: Each test runs `bash script.sh --help` in a subprocess. Script sourcing `common.sh` takes ~50-100ms (based on Phase 19 test timing). With 130 tests, that's 7-13 seconds.
   - Recommendation: Acceptable. BATS supports `--jobs N` for parallel execution if needed, but sequential is fine for this count.

## Sources

### Primary (HIGH confidence)
- Codebase: `scripts/common.sh` -- source chain, 9 library modules
- Codebase: `scripts/lib/args.sh` -- `parse_common_args` implementation (handles -h before require_cmd)
- Codebase: `scripts/lib/output.sh` -- `confirm_execute` implementation (checks `-t 0` for stdin)
- Codebase: `scripts/lib/validation.sh` -- `require_cmd` implementation (exits 1 if tool missing)
- Codebase: `scripts/nmap/examples.sh` -- representative Category A script (parse_common_args pattern)
- Codebase: `scripts/diagnostics/connectivity.sh` -- representative Category B script (old help pattern)
- Codebase: `scripts/check-docs-completeness.sh` -- excluded script (no common.sh, no show_help)
- Codebase: `tests/bats/lib/bats-core/test_functions.bash` lines 464-510 -- `bats_test_function` implementation
- Codebase: `tests/bats/test/fixtures/bats/dynamic_test_registration.bats` -- official dynamic registration example
- Codebase: `tests/bats/docs/CHANGELOG.md` -- `bats_test_function` introduced in v1.11.0
- Codebase: `tests/test_helper/common-setup.bash` -- shared helper, NO_COLOR=1
- Codebase: `Makefile` lines 14-18 -- test targets, non-recursive discovery
- Phase 18 research: `.planning/phases/18-bats-infrastructure/18-RESEARCH.md`
- Phase 19 research: `.planning/phases/19-library-unit-tests/19-RESEARCH.md`

### Secondary (MEDIUM confidence)
- [BATS writing tests docs](https://bats-core.readthedocs.io/en/stable/writing-tests.html) -- setup_file, BATS_FILE_TMPDIR, run
- [BATS issue #860](https://github.com/bats-core/bats-core/issues/860) -- dynamic test registration execution order (fixed in v1.13.0)
- [BATS issue #241](https://github.com/bats-core/bats-core/issues/241) -- parametric tests wishlist, workaround patterns

### Tertiary (LOW confidence)
- `bats_test_function` interaction with `setup()` -- verified by reading source code but not tested in our specific setup. Open question #3 recommends building a proof first.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- No new dependencies, everything from Phase 18
- Architecture: HIGH -- Dynamic test registration verified in BATS v1.13.0 source. Script categories verified by reading all 68 scripts. Mock strategy verified with local bash test.
- Pitfalls: HIGH -- All pitfalls verified against source code. `--help` before `require_cmd` flow verified for both patterns. warn() stdout vs error() stderr verified in logging.sh source.
- Code examples: MEDIUM -- `bats_test_function` pattern verified in BATS fixtures but not yet tested in our project setup. Proof-of-concept needed.

**Research date:** 2026-02-12
**Valid until:** 2026-03-12 (stable domain -- BATS v1.13.0 pinned, no external changes expected)
