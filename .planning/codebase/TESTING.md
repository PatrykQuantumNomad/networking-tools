# Testing Patterns

**Analysis Date:** 2026-02-17

## Test Framework

**Runner:**
- BATS (Bash Automated Testing System)
- Version: Bundled as git submodule in `tests/bats/`
- Config: None (uses BATS defaults)

**Assertion Library:**
- `bats-support`: Core assertion helpers
- `bats-assert`: Assertion functions (`assert_success`, `assert_output`, `assert_equal`)
- `bats-file`: File system assertions (`assert_file_exists`, `assert_file_not_exists`)

**Run Commands:**
```bash
make test              # Run all tests
make test-verbose      # Watch mode with verbose TAP output
./tests/bats/bin/bats tests/ --timing    # Direct invocation
```

## Test File Organization

**Location:**
- Co-located pattern: Tests in `tests/` directory, separate from source
- Test helpers in `tests/test_helper/` subdirectory
- BATS submodule and helper libraries in `tests/bats/` and `tests/test_helper/bats-*/`

**Naming:**
- Pattern: `{type}-{module}.bats` for unit/integration tests
- Unit tests: `lib-{module}.bats` (e.g., `lib-json.bats`, `lib-output.bats`, `lib-args.bats`)
- Integration tests: `intg-{feature}.bats` (e.g., `intg-cli-contracts.bats`, `intg-json-output.bats`)
- Smoke tests: `smoke.bats`

**Structure:**
```
tests/
├── smoke.bats                          # Smoke tests
├── lib-json.bats                       # Unit: json.sh functions
├── lib-output.bats                     # Unit: output.sh functions
├── lib-args.bats                       # Unit: args.sh argument parsing
├── lib-logging.bats                    # Unit: logging.sh log functions
├── lib-validation.bats                 # Unit: validation.sh validators
├── lib-cleanup.bats                    # Unit: cleanup.sh temp file handling
├── lib-retry.bats                      # Unit: retry logic
├── intg-cli-contracts.bats             # Integration: CLI --help/-x contracts
├── intg-json-output.bats               # Integration: JSON output format
├── intg-doc-json-flag.bats             # Integration: --json flag documentation
├── intg-script-headers.bats            # Integration: Script header format
├── test_helper/
│   ├── common-setup.bash               # Shared setup logic
│   ├── bats-support/                   # Assertion library submodule
│   ├── bats-assert/                    # Assert functions submodule
│   └── bats-file/                      # File assertions submodule
└── bats/                               # BATS framework submodule
```

## Test Structure

**Suite Organization:**
```bash
#!/usr/bin/env bats
# tests/lib-json.bats — Unit tests for JSON output library

setup() {
    load 'test_helper/common-setup'
    _common_setup

    show_help() { echo "test help"; }
    source "${PROJECT_ROOT}/scripts/common.sh"

    # Disable strict mode and clear traps for BATS compatibility
    set +eEuo pipefail
    trap - ERR

    # Reset mutable state
    JSON_MODE=0
    EXECUTE_MODE="show"
    VERBOSE=0
    LOG_LEVEL="info"
}

@test "json_is_active returns false when JSON_MODE=0" {
    JSON_MODE=0
    run json_is_active
    assert_failure
}
```

**Patterns:**
- Test header comment: file path and purpose
- `setup()` function runs before each test
- Load shared helper via `load 'test_helper/common-setup'`
- Call `_common_setup` to initialize PROJECT_ROOT and assertion libraries
- Source common.sh after defining `show_help()` stub
- Disable strict mode: `set +eEuo pipefail` and `trap - ERR` (BATS incompatibility)
- Reset mutable global variables to known state
- Use `@test` directive with descriptive names
- Use `run` command to capture exit code and output

## Mocking

**Framework:** Manual mocking via subprocess isolation and environment manipulation

**Patterns:**
```bash
# Subprocess helper for isolated execution
_run_json_subprocess() {
    local body="$1"
    run bash -c '
        exec 3>&-
        export NO_COLOR=1
        show_help() { echo "test help"; }
        source "'"${PROJECT_ROOT}"'/scripts/common.sh"
        set +eEuo pipefail
        trap - ERR
        JSON_MODE=1
        '"$body"'
    '
}

# Usage
@test "json_finalize produces valid JSON" {
    _run_json_subprocess '
        _JSON_TOOL="nmap"
        json_finalize
    '
    assert_success
    echo "$output" | jq -e '.results == []'
}
```

**What to Mock:**
- File descriptor 3 (closed to test fallback paths): `exec 3>&-`
- External commands not available in CI (handled by conditional logic in source)
- Environment variables: `NO_COLOR=1`, `JSON_MODE=1`

**What NOT to Mock:**
- Core bash builtins (`echo`, `[[ ]]`, `return`)
- Project functions under test
- BATS internals (`run`, `assert_*`)

## Fixtures and Factories

**Test Data:**
```bash
# Environment setup via exports
export NO_COLOR=1
export PROJECT_ROOT

# State reset pattern (no factories)
JSON_MODE=0
_JSON_TOOL=""
_JSON_TARGET=""
_JSON_RESULTS=()
EXECUTE_MODE="show"

# Temp files via cleanup.sh
stdout_file=$(make_temp)
stderr_file=$(make_temp)
```

**Location:**
- No separate fixture directory
- State initialized inline in `setup()` function
- Temporary files created via `make_temp` from `scripts/lib/cleanup.sh`
- BATS provides `BATS_TEST_TMPDIR` for file operations

## Coverage

**Requirements:** None enforced

**View Coverage:**
```bash
# No coverage tooling configured
# Test count visible via: make test
```

## Test Types

**Unit Tests:**
- Scope: Individual library functions in `scripts/lib/*.sh`
- Approach: Source common.sh, disable strict mode, reset state, call function, assert result
- Files: `lib-*.bats` (11 files covering json, output, args, logging, validation, cleanup, retry)
- Isolation: Each test resets global state in `setup()`

**Integration Tests:**
- Scope: Cross-module behavior and CLI contracts
- Approach: Invoke scripts as subprocesses with real arguments, check exit codes and output
- Files: `intg-*.bats` (4 files: cli-contracts, json-output, doc-json-flag, script-headers)
- Dynamic test registration: `bats_test_function --description` with discovered scripts
- Discovery pattern: `find "${PROJECT_ROOT}/scripts" -name '*.sh'` filtered by type

**E2E Tests:**
- Not used (pentesting tools would require root and external targets)

## Common Patterns

**Async Testing:**
```bash
# Not applicable (bash scripts are synchronous)
```

**Error Testing:**
```bash
@test "_json_require_jq exits 1 when jq unavailable" {
    _JSON_JQ_AVAILABLE=0
    run _json_require_jq
    assert_failure
    assert_output --partial "jq is required"
}

@test "run_or_show does not execute command in show mode" {
    run run_or_show "1) Touch file" touch "${BATS_TEST_TMPDIR}/should-not-exist"
    assert_success
    assert_file_not_exists "${BATS_TEST_TMPDIR}/should-not-exist"
}
```

**Output Matching:**
```bash
@test "safety_banner outputs authorization warning" {
    run safety_banner
    assert_success
    assert_output --partial "AUTHORIZED USE ONLY"
}

@test "parse_common_args preserves unknown flags in REMAINING_ARGS" {
    parse_common_args --unknown -x target
    assert_equal "${REMAINING_ARGS[*]}" "--unknown target"
}
```

**Dynamic Test Generation:**
```bash
# Integration tests use bats_test_function for discovered scripts
while IFS= read -r script; do
    local_path="${script#"${PROJECT_ROOT}"/}"
    bats_test_function \
        --description "INTG-01 ${local_path}: --help exits 0 with Usage" \
        -- _test_help_contract "$script"
done < <(_discover_all_scripts)
```

**JSON Validation:**
```bash
# Pipe BATS output to jq for validation
@test "json_finalize produces valid JSON structure" {
    _run_json_subprocess '
        _JSON_TOOL="nmap"
        json_finalize
    '
    assert_success
    echo "$output" | jq -e '.meta.tool == "nmap"'
    echo "$output" | jq -e '.results | length == 0'
}
```

**Strict Mode Compatibility:**
```bash
# All tests disable strict mode after sourcing
source "${PROJECT_ROOT}/scripts/common.sh"
set +eEuo pipefail
trap - ERR
```

**BATS Isolation:**
```bash
# Tests use 'run' to isolate script execution
run bash "$script" --help
assert_success

# Or subprocess helpers for complex setups
_run_json_subprocess '...'
```

---

*Testing analysis: 2026-02-17*
