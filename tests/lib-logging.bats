#!/usr/bin/env bats
# tests/lib-logging.bats — Unit tests for logging functions (UNIT-03)
# Covers info/success/warn/error/debug output, LOG_LEVEL filtering,
# NO_COLOR suppression, and VERBOSE timestamps.

bats_require_minimum_version 1.5.0

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
    VERBOSE=0
    LOG_LEVEL="info"
}

# --- info() tests ---

@test "info outputs message with INFO tag" {
    run info "test message"
    assert_success
    assert_output --partial "[INFO]"
    assert_output --partial "test message"
}

@test "info is suppressed when LOG_LEVEL is warn" {
    LOG_LEVEL="warn"
    run info "test message"
    assert_success
    refute_output
}

@test "info is suppressed when LOG_LEVEL is error" {
    LOG_LEVEL="error"
    run info "test message"
    assert_success
    refute_output
}

# --- success() tests ---

@test "success outputs message with OK tag" {
    run success "done"
    assert_success
    assert_output --partial "[OK]"
}

# --- warn() tests ---

@test "warn outputs message with WARN tag" {
    run warn "caution"
    assert_success
    assert_output --partial "[WARN]"
}

@test "warn is suppressed when LOG_LEVEL is error" {
    LOG_LEVEL="error"
    run warn "caution"
    assert_success
    refute_output
}

# --- error() tests ---

@test "error writes to stderr not stdout" {
    run --separate-stderr error "something broke"
    assert_success
    # stdout should be empty
    refute_output
    # stderr should contain the error message
    assert [ -n "$stderr" ]
    [[ "$stderr" == *"[ERROR]"* ]]
}

@test "error is never suppressed regardless of LOG_LEVEL" {
    LOG_LEVEL="error"
    run --separate-stderr error "still visible"
    assert_success
    assert [ -n "$stderr" ]
    [[ "$stderr" == *"[ERROR]"* ]]
    [[ "$stderr" == *"still visible"* ]]
}

# --- debug() tests ---

@test "debug outputs when LOG_LEVEL is debug" {
    LOG_LEVEL="debug"
    run debug "trace info"
    assert_success
    assert_output --partial "[DEBUG]"
    assert_output --partial "trace info"
}

@test "debug is suppressed when LOG_LEVEL is info" {
    # LOG_LEVEL is already "info" from setup
    run debug "trace info"
    assert_success
    refute_output
}

# --- NO_COLOR tests ---

@test "log output contains no ANSI escape codes with NO_COLOR" {
    # NO_COLOR=1 is already set by _common_setup, so color vars are empty
    run info "color test"
    assert_success
    refute_output --regexp $'\x1b\\['
}

# --- VERBOSE timestamp test ---

@test "info includes timestamp when VERBOSE >= 1" {
    VERBOSE=1
    run info "timed message"
    assert_success
    assert_output --regexp '\[([0-9]{2}:){2}[0-9]{2}\]'
}
