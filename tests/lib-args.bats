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

# --- JSON flag tests (Phase 24, TEST-02) ---
# All -j tests use subprocess isolation because parse_common_args -j
# runs exec 3>&1 and exec 1>&2, which would corrupt BATS I/O.

_run_parse_json() {
    local args="$1"
    local echo_vars="${2:-JSON_MODE=\$JSON_MODE}"
    run bash -c '
        exec 3>&-
        export NO_COLOR=1
        show_help() { echo "test help output"; }
        source "'"${PROJECT_ROOT}"'/scripts/common.sh"
        set +eEuo pipefail
        trap - ERR
        VERBOSE=0; LOG_LEVEL="info"; EXECUTE_MODE="show"; JSON_MODE=0; REMAINING_ARGS=()
        RED="x"; GREEN="x"; YELLOW="x"; BLUE="x"; CYAN="x"; NC="x"
        parse_common_args '"$args"'
        '"$echo_vars"'
    '
}

@test "-j sets JSON_MODE=1" {
    _run_parse_json "-j target" 'echo "JSON_MODE=$JSON_MODE"; echo "REMAINING=${REMAINING_ARGS[*]}"'
    assert_success
    assert_output --partial "JSON_MODE=1"
    assert_output --partial "REMAINING=target"
}

@test "--json long flag works same as -j" {
    _run_parse_json "--json target" 'echo "JSON_MODE=$JSON_MODE"'
    assert_success
    assert_output --partial "JSON_MODE=1"
}

@test "-j resets all color variables to empty" {
    _run_parse_json "-j target" 'echo "RED=${RED}END"; echo "GREEN=${GREEN}END"; echo "YELLOW=${YELLOW}END"; echo "BLUE=${BLUE}END"; echo "CYAN=${CYAN}END"; echo "NC=${NC}END"'
    assert_success
    assert_output --partial "RED=END"
    assert_output --partial "GREEN=END"
    assert_output --partial "YELLOW=END"
    assert_output --partial "BLUE=END"
    assert_output --partial "CYAN=END"
    assert_output --partial "NC=END"
}

@test "-j -x sets both JSON_MODE and EXECUTE_MODE" {
    _run_parse_json "-j -x target" 'echo "JSON_MODE=$JSON_MODE"; echo "EXECUTE_MODE=$EXECUTE_MODE"'
    assert_success
    assert_output --partial "JSON_MODE=1"
    assert_output --partial "EXECUTE_MODE=execute"
}

@test "-j -v sets both JSON_MODE and VERBOSE" {
    _run_parse_json "-j -v target" 'echo "JSON_MODE=$JSON_MODE"; echo "VERBOSE=$VERBOSE"'
    assert_success
    assert_output --partial "JSON_MODE=1"
    assert_output --partial "VERBOSE=1"
}

@test "-- -j treats -j as positional arg" {
    parse_common_args -- -j
    assert_equal "$JSON_MODE" "0"
    assert_equal "${REMAINING_ARGS[*]}" "-j"
}

@test "-j fails when jq unavailable" {
    run bash -c '
        exec 3>&-
        export NO_COLOR=1
        show_help() { echo "test help output"; }
        source "'"${PROJECT_ROOT}"'/scripts/common.sh"
        set +eEuo pipefail
        trap - ERR
        VERBOSE=0; LOG_LEVEL="info"; EXECUTE_MODE="show"; JSON_MODE=0; REMAINING_ARGS=()
        _JSON_JQ_AVAILABLE=0
        parse_common_args -j target
    '
    assert_failure
    assert_output --partial "jq is required"
}

@test "-j -h shows help and exits 0" {
    run bash -c '
        exec 3>&-
        export NO_COLOR=1
        show_help() { echo "test help output"; }
        source "'"${PROJECT_ROOT}"'/scripts/common.sh"
        set +eEuo pipefail
        trap - ERR
        VERBOSE=0; LOG_LEVEL="info"; EXECUTE_MODE="show"; JSON_MODE=0; REMAINING_ARGS=()
        parse_common_args -j -h
    '
    assert_success
    assert_output "test help output"
}
