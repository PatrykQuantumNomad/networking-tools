#!/usr/bin/env bats
# tests/lib-args.bats — Unit tests for parse_common_args (scripts/lib/args.sh)
# UNIT-01: Proves all flag combinations are parsed correctly.

setup() {
    load 'test_helper/common-setup'
    _common_setup

    # Define show_help before sourcing (required by -h handler)
    show_help() { echo "test help output"; }

    # Source all project libraries
    source "${PROJECT_ROOT}/scripts/common.sh"

    # Disable strict mode and clear traps for BATS compatibility
    set +eEuo pipefail
    trap - ERR

    # Reset mutable state before each test
    VERBOSE=0
    LOG_LEVEL="info"
    EXECUTE_MODE="show"
    REMAINING_ARGS=()
}

@test "-v sets VERBOSE >= 1" {
    parse_common_args -v target
    (( VERBOSE >= 1 ))
}

@test "-v sets LOG_LEVEL to debug" {
    parse_common_args -v target
    assert_equal "$LOG_LEVEL" "debug"
}

@test "--verbose long flag works same as -v" {
    parse_common_args --verbose target
    (( VERBOSE >= 1 ))
    assert_equal "$LOG_LEVEL" "debug"
}

@test "-q sets LOG_LEVEL to warn" {
    parse_common_args -q target
    assert_equal "$LOG_LEVEL" "warn"
}

@test "-x sets EXECUTE_MODE to execute" {
    parse_common_args -x target
    assert_equal "$EXECUTE_MODE" "execute"
}

@test "--execute long flag works same as -x" {
    parse_common_args --execute target
    assert_equal "$EXECUTE_MODE" "execute"
}

@test "-h calls show_help and exits 0" {
    run parse_common_args -h
    assert_success
    assert_output "test help output"
}

@test "-- stops flag parsing and passes remainder to REMAINING_ARGS" {
    parse_common_args -- -v -x target
    assert_equal "$EXECUTE_MODE" "show"
    assert_equal "$VERBOSE" "0"
    assert_equal "${REMAINING_ARGS[*]}" "-v -x target"
}

@test "unknown flags pass to REMAINING_ARGS" {
    parse_common_args --custom target
    assert_equal "${REMAINING_ARGS[*]}" "--custom target"
}

@test "combined flags (-v -x) set both VERBOSE and EXECUTE_MODE" {
    parse_common_args -v -x target
    (( VERBOSE >= 1 ))
    assert_equal "$EXECUTE_MODE" "execute"
    assert_equal "${REMAINING_ARGS[*]}" "target"
}

@test "no args produces empty REMAINING_ARGS" {
    parse_common_args
    assert_equal "${#REMAINING_ARGS[@]}" "0"
}

@test "flags after positional args still work" {
    parse_common_args target -x
    assert_equal "$EXECUTE_MODE" "execute"
    assert_equal "${REMAINING_ARGS[*]}" "target"
}
