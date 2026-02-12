# Phase 18: BATS Infrastructure - Research

**Researched:** 2026-02-12
**Domain:** BATS test framework installation, configuration, and strict mode conflict resolution for a bash project
**Confidence:** HIGH

## Summary

Phase 18 establishes BATS-core as the test framework for this project. The project currently has 307 ad-hoc test assertions across two custom test harnesses (`test-arg-parsing.sh` with 268 checks, `test-library-loads.sh` with 39 checks) but no formal test framework. BATS provides TAP-compliant output, per-test subshell isolation, assertion libraries, and parallel execution -- addressing every limitation of the current approach.

The critical challenge is **strict mode and trap conflict resolution**. Every script sources `common.sh`, which loads `strict.sh` (enabling `set -eEuo pipefail` and an ERR trap) and `cleanup.sh` (registering an EXIT trap with `mktemp` at source time). BATS has its own trap chain and error detection mechanism. When `common.sh` is sourced in a BATS test, the project's traps overwrite BATS's traps, causing silent test failures. The test helper must disable strict mode and clear traps after sourcing, matching the pattern already proven in the existing `test-arg-parsing.sh` (lines 9, 187-188).

Installation uses git submodules for local development (pinned versions, works offline, no runtime dependency manager) because helper libraries are not published to npm. The `make test` target invokes bats directly from the submodule (`./tests/bats/bin/bats`), requiring no system-wide installation.

**Primary recommendation:** Install BATS + helpers via git submodules, create `tests/test_helper/common-setup.bash` with dual-path library loading (submodules locally, `BATS_LIB_PATH` in CI), disable strict mode after sourcing `common.sh`, and prove the infrastructure works with a smoke test before writing any real tests.

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| bats-core | v1.13.0 | TAP-compliant bash test runner | Only mature, actively maintained bash test framework. 5000+ GitHub stars. Each `@test` runs in its own subshell. Built-in parallel execution, test filtering, and TAP output. |
| bats-support | v0.3.0 | Shared output formatting and error reporting | Required dependency for bats-assert. Provides `fail` and output formatting primitives. |
| bats-assert | v2.2.0 | Assertion functions: `assert_success`, `assert_failure`, `assert_output`, `assert_line` | Replaces manual `if/else` assertion boilerplate with clear failure messages showing expected vs actual diffs. |
| bats-file | v0.4.0 | Filesystem assertions: `assert_file_exists`, `assert_dir_exists` | Needed for testing `cleanup.sh` temp file creation and directory behavior. |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| bats-action | 4.0.0 | GitHub Action installing BATS + helpers in CI | CI workflow only; not needed for local development |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| bats-core | shunit2 | xUnit style, not updated since 2022, no native TAP output, no official GH Action |
| bats-core | bashunit | Very small community (~400 stars), not battle-tested |
| bats-core | Keep current harness | No TAP output, no parallel execution, no assertion library, no per-test isolation |
| Git submodules | Homebrew | Not reproducible across macOS/Linux, version drift between dev and CI |
| Git submodules | npm | Helper libraries NOT published to npm (bats-core issue #493). Blocker. |
| bats-assert v2.2.0 | bats-assert v2.2.4 | v2.2.1-v2.2.4 are regex edge case fixes. v2.2.0 includes stderr assertions (`assert_stderr`, `assert_stderr_line`). Pin v2.2.0 for stability. |

**Installation:**

```bash
# Git submodules (local development)
git submodule add https://github.com/bats-core/bats-core.git tests/bats
git submodule add https://github.com/bats-core/bats-support.git tests/test_helper/bats-support
git submodule add https://github.com/bats-core/bats-assert.git tests/test_helper/bats-assert
git submodule add https://github.com/bats-core/bats-file.git tests/test_helper/bats-file

# Pin to specific versions
cd tests/bats && git checkout v1.13.0 && cd ../..
cd tests/test_helper/bats-support && git checkout v0.3.0 && cd ../../..
cd tests/test_helper/bats-assert && git checkout v2.2.0 && cd ../../..
cd tests/test_helper/bats-file && git checkout v0.4.0 && cd ../../..
```

### Version Verification

All versions verified via GitHub API on 2026-02-12:

| Component | Pinned | Latest Available | Release Date |
|-----------|--------|-----------------|--------------|
| bats-core | v1.13.0 | v1.13.0 | 2025-11-07 |
| bats-support | v0.3.0 | v0.3.0 | 2022-03-04 |
| bats-assert | v2.2.0 | v2.2.4 | 2025-10-14 |
| bats-file | v0.4.0 | v0.4.0 | 2023-08-23 |
| bats-action | 4.0.0 | 4.0.0 | 2026-02-08 |

**Important bats-action detail:** The `bats-version` input has NO default value in `action.yaml`. The description says "default to latest (1.11.0 atm)" which is stale documentation -- actual latest is v1.13.0. **Always pin `bats-version: 1.13.0` explicitly.** The `assert-version` defaults to `2.1.0` (not 2.2.0), so we must also override this explicitly.

## Architecture Patterns

### Recommended Project Structure

```
tests/
  bats/                              # git submodule: bats-core v1.13.0
  test_helper/
    bats-support/                    # git submodule: v0.3.0
    bats-assert/                     # git submodule: v2.2.0
    bats-file/                       # git submodule: v0.4.0
    common-setup.bash                # shared setup: load helpers, set PROJECT_ROOT, handle strict mode
  smoke.bats                         # smoke test proving infrastructure works
  test-arg-parsing.sh                # KEEP: existing 268 tests (legacy)
  test-library-loads.sh              # KEEP: existing 39 tests (legacy)
```

### Pattern 1: Shared Test Helper (common-setup.bash)

**What:** Centralized helper loaded by every `.bats` file that handles library loading, `PROJECT_ROOT` resolution, and strict mode conflict resolution.

**When to use:** Every `.bats` file in the project.

**Example:**

```bash
# tests/test_helper/common-setup.bash
# Source: https://bats-core.readthedocs.io/en/stable/tutorial.html

_common_setup() {
    # Load assertion libraries
    # Dual-path: BATS_LIB_PATH (CI via bats-action) or submodules (local)
    if [[ -n "${BATS_LIB_PATH:-}" ]]; then
        bats_load_library bats-support
        bats_load_library bats-assert
        bats_load_library bats-file
    else
        load "${PROJECT_ROOT}/tests/test_helper/bats-support/load"
        load "${PROJECT_ROOT}/tests/test_helper/bats-assert/load"
        load "${PROJECT_ROOT}/tests/test_helper/bats-file/load"
    fi

    # Disable colors for predictable assertion matching
    export NO_COLOR=1
}

# Resolve PROJECT_ROOT before _common_setup so it's available for load paths
PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
export PROJECT_ROOT
```

**Why `_common_setup` as a function:** BATS documentation explicitly warns against running `load` and `source` outside of functions -- diagnostics are worse when errors occur in free code. The `PROJECT_ROOT` resolution is an exception because it's needed for `load` paths.

**Usage in test files:**

```bash
setup() {
    load 'test_helper/common-setup'
    _common_setup
}
```

**Key detail from BATS docs:** `load` automatically appends `.bash` to its argument. So `load 'test_helper/common-setup'` loads `tests/test_helper/common-setup.bash`. Never include the `.bash` extension in the `load` call.

### Pattern 2: Sourcing common.sh Safely in Tests

**What:** Source `common.sh` then immediately disable strict mode and clear traps.

**When to use:** Unit tests that need library functions directly.

**Example:**

```bash
setup() {
    load 'test_helper/common-setup'
    _common_setup

    # Define show_help before sourcing (parse_common_args calls it on -h)
    show_help() { echo "test help output"; }

    # Source project libraries
    source "${PROJECT_ROOT}/scripts/common.sh"

    # CRITICAL: Disable strict mode and clear traps for BATS compatibility
    # Matches existing pattern in tests/test-arg-parsing.sh lines 187-188
    set +eEuo pipefail
    trap - ERR
}
```

**Why this works:** All library functions are already defined after sourcing completes successfully. The test harness controls execution flow, not strict mode. This is the exact pattern the existing `test-arg-parsing.sh` uses (line 9: `set +eEu`, line 187: `set +eEuo pipefail`, line 188: `trap - ERR`).

### Pattern 3: Integration Tests via `run`

**What:** Test complete scripts as subprocesses via `run bash script.sh`, never via `source`.

**When to use:** Testing script behavior (help output, exit codes, argument handling).

**Example:**

```bash
@test "nmap/examples.sh: --help exits 0" {
    run bash "${PROJECT_ROOT}/scripts/nmap/examples.sh" --help
    assert_success
    assert_output --partial "Usage:"
}
```

**Why `run bash` not `run source`:** Scripts call `require_cmd`, `require_target`, and `exit`. Sourcing executes these in the BATS process. `run` creates a subshell -- `exit 1` terminates the subshell, not BATS. BATS captures the exit code in `$status`.

### Anti-Patterns to Avoid

- **Sourcing scripts (not `common.sh`) directly:** Scripts have top-level `require_cmd`, `exit`, and interactive prompts. Sourcing them kills the BATS process.
- **Loading project `.sh` files with `load`:** BATS `load` appends `.bash` extension. Project libraries use `.sh`. Use `source` for `.sh` files, `load` for `.bash` helpers.
- **Running `load` or `source` outside functions:** BATS documentation warns diagnostics are worse for free code. Always load inside `setup()` or `_common_setup()`.
- **Using `! command` for failure testing:** Bash excludes negated return values from triggering `set -e`. Use `run ! command` (BATS 1.5.0+) instead.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Assertion library | Manual `if/else` with counters | bats-assert (`assert_success`, `assert_output`) | Clear failure diffs, standardized output, less boilerplate |
| Test runner with TAP output | Custom pass/fail counter script | bats-core | TAP compliance, parallel execution, per-test isolation, lifecycle hooks |
| Test temp file management | Manual `mktemp`/`rm` in tests | `$BATS_TEST_TMPDIR` | Automatic cleanup per test, no leaks |
| CI BATS installation | Manual curl/install in workflow | bats-action@4.0.0 | Binary caching, `BATS_LIB_PATH` setup, version pinning |
| Dual-path library loading | Conditional `if CI then X else Y` in every test file | Shared `common-setup.bash` helper | Single file handles both environments; every test just calls `_common_setup` |

**Key insight:** The existing test harnesses (`test-arg-parsing.sh`, `test-library-loads.sh`) already do exactly what BATS does -- just with manual boilerplate. BATS replaces the boilerplate, not the test logic.

## Common Pitfalls

### Pitfall 1: `set -u` (nounset) Blows Up BATS Internal Variables

**What goes wrong:** Sourcing `common.sh` enables `set -u` via `strict.sh`. BATS uses internal variables (`BATS_CURRENT_STACK_TRACE[@]`, `BATS_TEST_SKIPPED`) that may be unset at certain lifecycle points. With `set -u` active, these cause unbound variable errors that crash the test runner or produce silent failures.

**Why it happens:** BATS preprocesses `@test` blocks into functions and manages internal state. Strict mode from sourced code contaminates BATS's execution environment.

**How to avoid:** After sourcing `common.sh` in `setup()`, immediately run `set +eEuo pipefail` and `trap - ERR`. This is the proven pattern from `test-arg-parsing.sh`.

**Warning signs:** Tests crash with cryptic errors mentioning `BATS_` variables, or tests produce no output at all.

### Pitfall 2: ERR Trap Conflict

**What goes wrong:** `strict.sh` line 36 registers `trap '_strict_error_handler' ERR`. BATS registers `trap 'bats_error_trap' ERR`. Only one ERR trap can be active. The project's trap overwrites BATS's trap, breaking failure detection.

**Why it happens:** `set -E` (errtrace) causes ERR traps to be inherited by functions and subshells, making the conflict propagate everywhere.

**How to avoid:** Run `trap - ERR` after sourcing `common.sh`. For integration tests, use `run bash script.sh` (subshell isolates traps).

**Warning signs:** Test failures show `[ERROR] Command failed at line X` (project format) instead of BATS diagnostic format, or failures go undetected.

### Pitfall 3: EXIT Trap from cleanup.sh

**What goes wrong:** `cleanup.sh` registers `trap '_cleanup_handler' EXIT` and runs `mktemp -d` at source time (line 12). When `common.sh` is sourced in a test, this EXIT trap fires during BATS teardown. The handler calls `exit "$exit_code"` which can interfere with BATS's exit trap chain.

**Why it happens:** Each `@test` runs in a subshell, so the EXIT trap fires when that subshell exits. This is generally harmless -- it cleans up the temp dir. The risk is if `_cleanup_handler`'s `exit` call somehow affects BATS result reporting.

**How to avoid:** For the Phase 18 smoke test, this is manageable: source `common.sh` in `setup()`, let the EXIT trap fire naturally in the test subshell. For unit tests of `cleanup.sh` specifically (future phases), use `$BATS_TEST_TMPDIR` instead of `make_temp()`.

**Warning signs:** Orphan `/tmp/ntool-session.*` directories after test runs. Missing TAP output lines.

### Pitfall 4: `load` Expects `.bash` Extension

**What goes wrong:** BATS `load` automatically appends `.bash` to the filename. All project library modules use `.sh`. Calling `load "../scripts/lib/validation"` looks for `validation.bash` and fails.

**Why it happens:** BATS convention uses `.bash` for test helpers. Project follows standard shell convention with `.sh`.

**How to avoid:** Use `load` only for BATS helpers (`.bash` files). Use `source` for project libraries (`.sh` files). The test helper should be named `common-setup.bash`, not `common-setup.sh`.

**Warning signs:** "file not found" or "does not exist" errors from `load` calls.

### Pitfall 5: Makefile `test` Target Conflicts

**What goes wrong:** The Makefile already has other targets. Adding `test:` could conflict with `test-` prefixed targets or with shell's built-in `test` command in some contexts.

**Why it happens:** `make test` is a common convention but requires the target to be declared `.PHONY` and the recipe must invoke BATS correctly.

**How to avoid:** Declare `test` and `test-verbose` as `.PHONY` targets. Use `./tests/bats/bin/bats` (from submodule) not a system `bats` to ensure the pinned version is used regardless of what is installed globally.

**Warning signs:** `make test` runs something unexpected or fails to find bats.

## Code Examples

Verified patterns from official sources and existing codebase:

### Smoke Test (proves infrastructure works with strict mode)

```bash
#!/usr/bin/env bats
# tests/smoke.bats -- Prove BATS infrastructure works with project's strict mode

setup() {
    load 'test_helper/common-setup'
    _common_setup
}

@test "BATS runs and assertions work" {
    run echo "hello world"
    assert_success
    assert_output "hello world"
}

@test "bats-file assertions work" {
    assert_file_exists "${PROJECT_ROOT}/Makefile"
}

@test "common.sh can be sourced without crashing BATS" {
    # Define show_help before sourcing (required by parse_common_args)
    show_help() { echo "test help"; }

    # Source all project libraries
    source "${PROJECT_ROOT}/scripts/common.sh"

    # Disable strict mode (matches test-arg-parsing.sh pattern)
    set +eEuo pipefail
    trap - ERR

    # Verify functions are available
    declare -F info
    declare -F require_cmd
    declare -F parse_common_args
    declare -F make_temp
}

@test "parse_common_args works after sourcing common.sh" {
    show_help() { echo "test help"; }
    source "${PROJECT_ROOT}/scripts/common.sh"
    set +eEuo pipefail
    trap - ERR

    # Reset state
    VERBOSE=0
    LOG_LEVEL="info"
    EXECUTE_MODE="show"
    REMAINING_ARGS=()

    parse_common_args -v scanme.nmap.org

    assert_equal "$EXECUTE_MODE" "show"
    (( VERBOSE >= 1 ))
    assert_equal "${REMAINING_ARGS[*]}" "scanme.nmap.org"
}

@test "run isolates script exit codes from BATS process" {
    run bash -c 'exit 42'
    assert_equal "$status" 42
}
```

### Makefile Targets

```makefile
test: ## Run BATS test suite
	@./tests/bats/bin/bats tests/ --recursive --timing

test-verbose: ## Run BATS tests with verbose TAP output
	@./tests/bats/bin/bats tests/ --recursive --timing --verbose-run
```

### Dual-Path Library Loading (common-setup.bash)

```bash
#!/usr/bin/env bash
# tests/test_helper/common-setup.bash

PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
export PROJECT_ROOT

_common_setup() {
    if [[ -n "${BATS_LIB_PATH:-}" ]]; then
        bats_load_library bats-support
        bats_load_library bats-assert
        bats_load_library bats-file
    else
        load "${PROJECT_ROOT}/tests/test_helper/bats-support/load"
        load "${PROJECT_ROOT}/tests/test_helper/bats-assert/load"
        load "${PROJECT_ROOT}/tests/test_helper/bats-file/load"
    fi
    export NO_COLOR=1
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `load 'test_helper/bats-support/load'` (hardcoded submodule path) | `bats_load_library bats-support` (uses `BATS_LIB_PATH`) | bats-core v1.7.0+ | Works across install methods (brew, submodule, CI action) |
| `run` captures combined stdout+stderr | `run --separate-stderr` splits `$output` and `$stderr` | bats-core v1.5.0 | Can assert on stderr independently |
| `! command` for failure tests | `run ! command` | bats-core v1.5.0 | Correctly fails test if command succeeds |
| Manual temp dir cleanup | `$BATS_TEST_TMPDIR` auto-cleanup | bats-core built-in | Per-test temp dirs, no leak risk |

**Deprecated/outdated:**
- **bats-mock:** Not needed for this project. Scripts are thin wrappers; mocking the underlying tool tests the mock, not the script.
- **bashcov/kcov:** Code coverage is premature. Get BATS running first; coverage is a separate milestone.
- **bats-detik:** Kubernetes testing library. This project has zero Kubernetes components. Disable in CI: `detik-install: false`.

## Specific Implementation Details for Phase 18

### INFRA-01: Git Submodules

**Exact commands:**

```bash
git submodule add https://github.com/bats-core/bats-core.git tests/bats
git submodule add https://github.com/bats-core/bats-support.git tests/test_helper/bats-support
git submodule add https://github.com/bats-core/bats-assert.git tests/test_helper/bats-assert
git submodule add https://github.com/bats-core/bats-file.git tests/test_helper/bats-file
```

Then pin versions:

```bash
cd tests/bats && git checkout v1.13.0 && cd ../..
cd tests/test_helper/bats-support && git checkout v0.3.0 && cd ../../..
cd tests/test_helper/bats-assert && git checkout v2.2.0 && cd ../../..
cd tests/test_helper/bats-file && git checkout v0.4.0 && cd ../../..
```

This creates a `.gitmodules` file (does not exist yet) and adds entries for each submodule. After pinning, `git add` the submodule directories and `.gitmodules`.

**ShellCheck exclusion:** The `lint` target in the Makefile runs `find . -name '*.sh'` which would pick up `.sh` files inside bats submodules. Add exclusion: `-not -path './tests/bats/*' -not -path './tests/test_helper/bats-*'`. Similarly update `.github/workflows/shellcheck.yml`.

### INFRA-02: Shared Test Helper

File: `tests/test_helper/common-setup.bash`

Must handle:
1. `PROJECT_ROOT` resolution from `$BATS_TEST_FILENAME`
2. Dual-path library loading (`BATS_LIB_PATH` vs submodule paths)
3. `NO_COLOR=1` export for predictable assertion matching
4. NOT source `common.sh` globally (leave that to individual test files that need it)

The strict mode conflict resolution is NOT in the helper itself -- it belongs in each test file's `setup()` after `source common.sh`, because not all test files source `common.sh`.

### INFRA-03: Makefile Targets

Add to Makefile:
- `test:` -- runs `./tests/bats/bin/bats tests/ --recursive --timing`
- `test-verbose:` -- adds `--verbose-run` flag for per-test detail

Use `./tests/bats/bin/bats` (submodule binary), not system `bats`. This ensures pinned version regardless of what is installed globally. No `brew install bats-core` required for contributors.

Add both targets to `.PHONY` declaration.

### INFRA-04: Smoke Test

File: `tests/smoke.bats`

Must prove:
1. BATS runs and basic assertions work
2. bats-file assertions work
3. `common.sh` can be sourced without crashing BATS (strict mode conflict handled)
4. Library functions work after sourcing (e.g., `parse_common_args`)
5. `run` isolates script exits from BATS process

## Open Questions

1. **PROJECT_ROOT resolution path depth**
   - What we know: BATS tests will live at `tests/smoke.bats` (depth 1) and `tests/lib/args.bats` (depth 2) and `tests/scripts/help.bats` (depth 2). The `common-setup.bash` is at `tests/test_helper/common-setup.bash`.
   - What's unclear: The `PROJECT_ROOT` resolution in `common-setup.bash` uses `"$(dirname "$BATS_TEST_FILENAME")/../.."`. This works for `tests/smoke.bats` (goes up 2 to repo root? No -- smoke.bats is at depth 1 from project root, going up 2 goes above the repo). Need: `"$(dirname "$BATS_TEST_FILENAME")/.."` for depth-1 files, `"$(dirname "$BATS_TEST_FILENAME")/../.."` for depth-2 files.
   - Recommendation: Use `git rev-parse --show-toplevel` for reliable PROJECT_ROOT resolution regardless of test file depth. Or standardize: all `.bats` files go in `tests/` subdirectories (never at `tests/` root), making `../..` always correct. The official tutorial uses `"$(dirname "$BATS_TEST_FILENAME")/.."` but their structure has tests at depth 1 (`test/test.bats`). For our structure with `tests/smoke.bats` AND `tests/lib/*.bats`, the `git rev-parse` approach is more robust.

2. **EXIT trap coexistence -- verified safe?**
   - What we know: Each `@test` runs in its own subshell. The EXIT trap from `cleanup.sh` fires when that subshell exits. BATS's own EXIT trap runs in the parent process.
   - What's unclear: Whether `cleanup.sh`'s `exit "$exit_code"` call (line 31) inside the EXIT handler could affect anything. In a subshell, this should be safe -- it sets the subshell's exit code, which BATS captures.
   - Recommendation: Test this in the smoke test (INFRA-04). If it causes issues, add `trap - EXIT` after sourcing `common.sh` alongside `trap - ERR`.

## Sources

### Primary (HIGH confidence)
- [bats-core releases](https://github.com/bats-core/bats-core/releases) -- v1.13.0 verified via `gh api` on 2026-02-12
- [bats-assert releases](https://github.com/bats-core/bats-assert/releases) -- v2.2.4 latest, v2.2.0 pinned, verified via `gh api`
- [bats-support releases](https://github.com/bats-core/bats-support/releases) -- v0.3.0 verified via `gh api`
- [bats-file releases](https://github.com/bats-core/bats-file/releases) -- v0.4.0 verified via `gh api`
- [bats-action releases](https://github.com/bats-core/bats-action/releases) -- 4.0.0 (2026-02-08) verified via `gh api`
- [bats-action action.yaml](https://github.com/bats-core/bats-action/blob/main/action.yaml) -- Full action inputs/defaults verified via raw download
- [bats-core official tutorial](https://bats-core.readthedocs.io/en/stable/tutorial.html) -- Submodule setup, common-setup.bash pattern
- [bats-core writing tests](https://bats-core.readthedocs.io/en/stable/writing-tests.html) -- `run`, `setup_file`, `bats_load_library`, temp dirs
- [bats-core gotchas](https://bats-core.readthedocs.io/en/stable/gotchas.html) -- `set -e`, `! negation`, pipes in `run`, `load` extension
- Codebase: `scripts/lib/strict.sh` (ERR trap, set -eEuo pipefail)
- Codebase: `scripts/lib/cleanup.sh` (EXIT trap, mktemp at source time)
- Codebase: `scripts/common.sh` (source chain, source guard)
- Codebase: `tests/test-arg-parsing.sh` (existing pattern for disabling strict mode in tests, lines 9, 187-188)
- Codebase: `tests/test-library-loads.sh` (existing pattern for sourcing common.sh in tests)

### Secondary (MEDIUM confidence)
- [bats-core issue #493](https://github.com/bats-core/bats-core/issues/493) -- npm limitation for helper libraries
- [bats-core issues #36, #81, #213, #423](https://github.com/bats-core/bats-core/issues) -- Strict mode and set -u conflicts with BATS
- Prior milestone research: `.planning/research/SUMMARY.md`, `STACK.md`, `ARCHITECTURE.md`, `PITFALLS.md`

### Tertiary (LOW confidence)
- bats-assert v2.2.0 stderr assertion functions (`assert_stderr`, `assert_stderr_line`) -- mentioned in release notes, not verified in documentation. Not critical for Phase 18.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- All versions verified via GitHub API, installation method verified via official docs, npm blocker confirmed via issue #493
- Architecture: HIGH -- Directory structure follows official tutorial, test helper pattern from official docs, strict mode handling verified against existing codebase test patterns
- Pitfalls: HIGH -- Critical pitfalls (strict mode, trap conflicts) verified by reading source code of both BATS internals and project's `strict.sh`/`cleanup.sh`, cross-referenced with bats-core GitHub issues

**Research date:** 2026-02-12
**Valid until:** 2026-03-12 (BATS ecosystem is stable; no breaking changes expected in 30 days)
