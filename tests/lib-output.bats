#!/usr/bin/env bats
# tests/lib-output.bats — Unit tests for output functions (UNIT-05)
# Covers run_or_show show/execute modes, safety_banner output,
# and is_interactive non-terminal detection.

setup() {
    load 'test_helper/common-setup'
    _common_setup

    # Required by parse_common_args (sourced via common.sh)
    show_help() { echo "test help"; }

    source "${PROJECT_ROOT}/scripts/common.sh"

    # Disable strict mode and clear traps for BATS compatibility
    set +eEuo pipefail
    trap - ERR

    # Reset to known state
    EXECUTE_MODE="show"
    VERBOSE=0
    LOG_LEVEL="info"
}

# --- run_or_show tests ---

@test "run_or_show prints command in show mode" {
    run run_or_show "1) List files" ls -la
    assert_success
    assert_output --partial "[INFO]"
    assert_output --partial "1) List files"
    assert_output --partial "ls -la"
}

@test "run_or_show does not execute command in show mode" {
    run run_or_show "1) Touch file" touch "${BATS_TEST_TMPDIR}/should-not-exist"
    assert_success
    assert_file_not_exists "${BATS_TEST_TMPDIR}/should-not-exist"
}

@test "run_or_show executes command in execute mode" {
    EXECUTE_MODE="execute"
    export EXECUTE_MODE
    run run_or_show "1) Create marker" touch "${BATS_TEST_TMPDIR}/marker"
    assert_success
    assert_file_exists "${BATS_TEST_TMPDIR}/marker"
}

@test "run_or_show shows indented command in show mode" {
    run run_or_show "1) Example" echo hello
    assert_success
    assert_output --partial "   echo hello"
}

# --- safety_banner tests ---

@test "safety_banner outputs authorization warning" {
    run safety_banner
    assert_success
    assert_output --partial "AUTHORIZED USE ONLY"
    assert_output --partial "written permission"
}

@test "safety_banner contains no ANSI codes under NO_COLOR" {
    # NO_COLOR=1 is already set by _common_setup, so color vars are empty
    run safety_banner
    assert_success
    refute_output --regexp $'\x1b\['
}

# --- is_interactive tests ---

@test "is_interactive returns false in BATS (non-terminal stdin)" {
    run is_interactive
    assert_failure
}
