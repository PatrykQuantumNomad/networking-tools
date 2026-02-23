# Testing Patterns

**Analysis Date:** 2026-02-23

## Test Framework

**Runner:**
- BATS (Bash Automated Testing System) 1.13.0
- Vendored as git submodule at `tests/bats/`
- Minimum version enforced in some suites: `bats_require_minimum_version 1.5.0`

**Assertion Libraries (git submodules in `tests/test_helper/`):**
- `bats-assert` — `assert_success`, `assert_failure`, `assert_output`, `assert_equal`, `refute_output`
- `bats-support` — base support for bats-assert
- `bats-file` — `assert_file_exists`, `assert_dir_exists`, `assert_file_not_exists`

**Run Commands:**
```bash
make test              # Run full BATS suite with timing
make test-verbose      # Run with verbose TAP output
make lint              # Run ShellCheck on all scripts (severity=warning)

# Direct BATS invocation
./tests/bats/bin/bats tests/ --timing
./tests/bats/bin/bats tests/lib-args.bats   # Single file
```

## Test File Organization

**Location:** `tests/` directory, flat (no subdirectories for project test files)

**Naming convention:**
- `lib-<module>.bats` — unit tests for a specific library module
- `intg-<feature>.bats` — integration tests for a feature or CLI contract
- `smoke.bats` — infrastructure smoke tests

**Current test files:**
- `tests/smoke.bats` — BATS infrastructure + common.sh sourcing
- `tests/lib-args.bats` — unit tests for `scripts/lib/args.sh` (parse_common_args)
- `tests/lib-cleanup.bats` — unit tests for `scripts/lib/cleanup.sh` (make_temp, EXIT trap)
- `tests/lib-json.bats` — unit tests for `scripts/lib/json.sh` (JSON envelope functions)
- `tests/lib-logging.bats` — unit tests for `scripts/lib/logging.sh` (info/warn/error/debug)
- `tests/lib-output.bats` — unit tests for `scripts/lib/output.sh` (run_or_show, safety_banner)
- `tests/lib-retry.bats` — unit tests for `scripts/lib/cleanup.sh` retry_with_backoff
- `tests/lib-validation.bats` — unit tests for `scripts/lib/validation.sh` (require_cmd, check_cmd)
- `tests/intg-cli-contracts.bats` — INTG-01/02/03/04: all scripts pass --help, -x guards
- `tests/intg-doc-json-flag.bats` — DOC-01/02: JSON flag documented in --help and @usage header
- `tests/intg-json-output.bats` — JSON-01/02: all use-case scripts produce valid JSON with -j
- `tests/intg-script-headers.bats` — HDR-06: all scripts have required metadata headers

**Legacy test scripts (not BATS):**
- `tests/test-arg-parsing.sh` — bash-based regression test for arg parsing
- `tests/test-library-loads.sh` — bash-based library load verification

## Test Structure

**Standard BATS Suite Setup:**

Every `.bats` file follows this structure:

```bash
#!/usr/bin/env bats
# tests/lib-<module>.bats — <description>

bats_require_minimum_version 1.5.0   # optional, in some files

setup() {
    load 'test_helper/common-setup'
    _common_setup

    # Define show_help before sourcing common.sh (required by parse_common_args)
    show_help() { echo "test help"; }

    source "${PROJECT_ROOT}/scripts/common.sh"

    # CRITICAL: Disable strict mode and clear traps for BATS compatibility
    set +eEuo pipefail
    trap - ERR

    # Reset mutable state before each test
    VERBOSE=0
    LOG_LEVEL="info"
    EXECUTE_MODE="show"
    REMAINING_ARGS=()
}

@test "descriptive test name" {
    run <command>
    assert_success
    assert_output --partial "expected text"
}
```

**The strict mode reset is mandatory** in every `setup()` that sources `common.sh`. The library sets `set -eEuo pipefail` and an ERR trap, which conflicts with BATS's own error handling. The pattern is always:
```bash
set +eEuo pipefail
trap - ERR
```

## Shared Test Helper

`tests/test_helper/common-setup.bash` is loaded by every suite via `load 'test_helper/common-setup'`. It:

1. Resolves `PROJECT_ROOT` via `git rev-parse --show-toplevel`
2. Loads `bats-support`, `bats-assert`, `bats-file` from submodules (falls back to `bats_load_library` on CI)
3. Sets `NO_COLOR=1` to disable ANSI codes for predictable assertion matching

```bash
_common_setup() {
    load "${PROJECT_ROOT}/tests/test_helper/bats-support/load"
    load "${PROJECT_ROOT}/tests/test_helper/bats-assert/load"
    load "${PROJECT_ROOT}/tests/test_helper/bats-file/load"
    export NO_COLOR=1
}
```

## Mocking

**Tool Mocking (integration tests):**

Integration tests create mock binaries in `BATS_FILE_TMPDIR/mock-bin/` and prepend to PATH in `setup()`. This enables CI testing without real pentesting tools:

```bash
setup_file() {
    MOCK_BIN="${BATS_FILE_TMPDIR}/mock-bin"
    mkdir -p "$MOCK_BIN"
    export MOCK_BIN

    local tools=(nmap tshark msfconsole msfvenom aircrack-ng hashcat ...)
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
    export PATH="${MOCK_BIN}:${PATH}"
}
```

**Function Mocking:**

Override bash functions before/after sourcing common.sh:
```bash
# Mock sleep to be instant in retry tests
sleep() { :; }
export -f sleep

# Mock show_help (always required before sourcing common.sh)
show_help() { echo "test help output"; }
```

**Internal State Mocking:**

Force internal state to control code paths:
```bash
_JSON_JQ_AVAILABLE=0   # Simulate jq missing
_JSON_JQ_AVAILABLE=1   # Simulate jq present
```

**What to Mock:**
- External pentesting tools (`nmap`, `sqlmap`, etc.) — use the mock binary pattern
- `sleep` in retry tests — mock to be a no-op for fast tests
- `show_help()` — always define before sourcing `common.sh`

**What NOT to Mock:**
- Core bash builtins (`echo`, `read`, `command`, etc.)
- The library functions under test themselves
- File system operations (use `BATS_TEST_TMPDIR` instead)

## Subprocess Isolation

Some tests require subprocess isolation to prevent state leakage (especially for JSON mode which redirects file descriptors):

```bash
_run_json_subprocess() {
    local body="$1"
    run bash -c '
        exec 3>&-           # Close fd3 inherited from BATS
        export NO_COLOR=1
        show_help() { echo "test help"; }
        source "'"${PROJECT_ROOT}"'/scripts/common.sh"
        set +eEuo pipefail
        trap - ERR
        JSON_MODE=1
        # ... reset state ...
        '"$body"'
    '
}
```

Use subprocess isolation when:
- Testing functions that redirect file descriptors (`exec 3>&1`, `exec 1>&2`)
- Testing EXIT trap behavior (cleanup, temp file removal)
- Testing full script invocation (INTG tests always use `run bash "$script" --flag`)

## Fixtures and Wordlists

Some integration tests require wordlist files that may not exist in the repo. The `setup_file()` / `teardown_file()` lifecycle manages dummy files:

```bash
setup_file() {
    local wordlist_dir="${PROJECT_ROOT}/wordlists"
    local wordlists=(common.txt subdomains-top1million-5000.txt rockyou.txt)
    for wl in "${wordlists[@]}"; do
        if [[ ! -f "${wordlist_dir}/${wl}" ]]; then
            echo "dummy" > "${wordlist_dir}/${wl}"
            echo "${wordlist_dir}/${wl}" >> "${BATS_FILE_TMPDIR}/created-wordlists"
        fi
    done
}

teardown_file() {
    if [[ -f "${BATS_FILE_TMPDIR}/created-wordlists" ]]; then
        while IFS= read -r wl; do rm -f "$wl"; done < "${BATS_FILE_TMPDIR}/created-wordlists"
    fi
}
```

**Temp files in tests:** Use `BATS_TEST_TMPDIR` (per-test isolation) or `BATS_FILE_TMPDIR` (per-file/suite isolation). Never use hardcoded `/tmp/` paths.

## Dynamic Test Registration

Integration suites use `bats_test_function` to generate tests dynamically from script discovery, so adding a new `.sh` file automatically includes it in the test suite:

```bash
_discover_all_scripts() {
    find "${PROJECT_ROOT}/scripts" -name '*.sh' \
        -not -path '*/lib/*' \
        -not -name 'common.sh' \
        | sort
}

while IFS= read -r script; do
    local_path="${script#"${PROJECT_ROOT}"/}"
    bats_test_function \
        --description "INTG-01 ${local_path}: --help exits 0 with Usage" \
        -- _test_help_contract "$script"
done < <(_discover_all_scripts)
```

Static meta-tests assert minimum discovery counts to catch regressions:
```bash
@test "INTG-03: discovery finds all testable scripts" {
    local count
    count=$(_discover_all_scripts | wc -l | tr -d ' ')
    assert [ "$count" -ge 67 ]
}
```

## Coverage

**Requirements:** No numeric coverage threshold enforced. Coverage is behavioral — every public function in `scripts/lib/*.sh` has a corresponding `tests/lib-*.bats` file.

**Coverage approach:** Black-box behavioral testing. Tests verify observable outputs (stdout/stderr, exit codes, file creation/deletion, variable state) rather than line coverage.

## Test Types

**Unit Tests (`tests/lib-*.bats`):**
- Scope: Individual functions from a single library module
- Approach: Source `common.sh`, reset state, call function directly, assert output/state
- Examples: `tests/lib-logging.bats`, `tests/lib-validation.bats`, `tests/lib-json.bats`

**Integration Tests (`tests/intg-*.bats`):**
- Scope: Full script invocation via `run bash "$script" [flags]`
- Approach: Dynamically discover all scripts, apply mock tool binaries, verify CLI contracts
- Examples: `tests/intg-cli-contracts.bats`, `tests/intg-json-output.bats`

**Smoke Tests (`tests/smoke.bats`):**
- Scope: BATS infrastructure + library load verification
- Approach: Minimal assertions to verify the test environment works

**Legacy Bash Tests:**
- `tests/test-arg-parsing.sh` — bash-based (not BATS), runs pass/fail checks for arg parsing
- `tests/test-library-loads.sh` — verifies common.sh sources without errors

## Common Assertion Patterns

**Exit code assertions:**
```bash
run command
assert_success          # exit 0
assert_failure          # exit non-zero
assert_equal "$status" 42
```

**Output assertions:**
```bash
assert_output "exact string"
assert_output --partial "[INFO]"     # substring match
assert_output --regexp '\[OK\]'      # regex match
refute_output                         # assert empty output
refute_output --partial "[ERROR]"
refute_output --regexp $'\x1b\['     # assert no ANSI codes
```

**Stderr assertions (BATS 1.5+):**
```bash
run --separate-stderr command
assert [ -n "$stderr" ]
[[ "$stderr" == *"[ERROR]"* ]]
```

**File assertions:**
```bash
assert_file_exists "$path"
assert_file_not_exists "$path"
assert_dir_exists "$path"
assert_dir_not_exists "$path"
```

**JSON validation (integration tests):**
```bash
echo "$output" | jq -e '.meta.tool == "nmap"'
echo "$output" | jq -e 'has("meta") and has("results") and has("summary")' > /dev/null
```

## CI/CD

**GitHub Actions workflows:**
- `.github/workflows/tests.yml` — runs BATS suite on `ubuntu-latest` on push/PR to `main`
  - Uses `bats-core/bats-action@4.0.0` with BATS 1.13.0
  - Outputs JUnit XML report, published via `mikepenz/action-junit-report`
- `.github/workflows/shellcheck.yml` — runs ShellCheck on all `.sh` files on push/PR to `main`
  - Severity: `warning`
  - Excludes: `site/`, `.planning/`, `node_modules/`, `tests/bats/`, `tests/test_helper/bats-*/`

---

*Testing analysis: 2026-02-23*
