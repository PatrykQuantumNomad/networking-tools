#!/usr/bin/env bats
# tests/smoke.bats — Prove BATS infrastructure works with project's strict mode

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

    # CRITICAL: Disable strict mode and clear traps for BATS compatibility
    # Matches existing pattern in tests/test-arg-parsing.sh lines 187-188
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
