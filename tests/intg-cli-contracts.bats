#!/usr/bin/env bats
# tests/intg-cli-contracts.bats -- CLI contract tests for all scripts
# INTG-01: --help exits 0 and output contains "Usage:"
# INTG-02: -x rejects piped (non-interactive) stdin
# INTG-03: Scripts discovered dynamically (no hardcoded lists)
# INTG-04: Tests pass on CI without pentesting tools (via mock commands)

# --- File-Level Setup (runs at parse time, before setup/setup_file) ---
PROJECT_ROOT="$(git rev-parse --show-toplevel)"

# Discover all testable scripts (excludes lib/, common.sh, check-docs-completeness.sh)
_discover_all_scripts() {
    find "${PROJECT_ROOT}/scripts" -name '*.sh' \
        -not -path '*/lib/*' \
        -not -name 'common.sh' \
        -not -name 'check-docs-completeness.sh' \
        | sort
}

# Discover scripts that support -x execute mode
# Excludes diagnostics/ and check-tools.sh (no parse_common_args / no -x support)
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

# INTG-01: Help contract -- every script exits 0 on --help with "Usage:" in output
_test_help_contract() {
    local script="$1"
    run env NO_COLOR=1 bash "$script" --help
    assert_success
    assert_output --partial "Usage:"
}

# --- Dynamic Test Registration (INTG-01) ---
while IFS= read -r script; do
    local_path="${script#"${PROJECT_ROOT}"/}"
    bats_test_function \
        --description "INTG-01 ${local_path}: --help exits 0 with Usage" \
        -- _test_help_contract "$script"
done < <(_discover_all_scripts)

# --- Static Meta-Tests (INTG-03) ---

# @test functions use standard BATS registration -- position doesn't matter
@test "INTG-03: discovery finds all testable scripts" {
    local count
    count=$(_discover_all_scripts | wc -l | tr -d ' ')
    assert [ "$count" -ge 67 ]
}

@test "INTG-03: execute-mode discovery excludes diagnostics and check-tools" {
    local count
    count=$(_discover_execute_mode_scripts | wc -l | tr -d ' ')
    assert [ "$count" -ge 63 ]
}

# --- Per-Test Setup ---
setup() {
    load 'test_helper/common-setup'
    _common_setup
}
