#!/usr/bin/env bats
# tests/lib-validation.bats — Unit tests for require_cmd, check_cmd, require_target
# UNIT-02: Proves command and target validation functions work correctly.

bats_require_minimum_version 1.5.0

setup() {
    load 'test_helper/common-setup'
    _common_setup

    # Define show_help before sourcing (required by common.sh)
    show_help() { echo "test help"; }

    # Source all project libraries
    source "${PROJECT_ROOT}/scripts/common.sh"

    # Disable strict mode and clear traps for BATS compatibility
    set +eEuo pipefail
    trap - ERR
}

@test "check_cmd returns 0 for present command" {
    check_cmd bash
}

@test "check_cmd returns 1 for missing command" {
    run check_cmd "nonexistent_command_xyz_123"
    assert_failure
}

@test "require_cmd succeeds for present command" {
    run require_cmd bash
    assert_success
}

@test "require_cmd exits 1 for missing command" {
    run require_cmd "nonexistent_command_xyz_123"
    assert_failure
}

@test "require_cmd shows install hint when provided" {
    run --separate-stderr require_cmd "nonexistent_command_xyz_123" "brew install xyz"
    assert_failure
    # Install hint is output via info() to stdout
    assert_output --partial "Install: brew install xyz"
}

@test "require_cmd error message includes command name" {
    run --separate-stderr require_cmd "nonexistent_command_xyz_123"
    assert_failure
    # error() writes to stderr
    [[ "$stderr" == *"nonexistent_command_xyz_123"* ]]
}

@test "require_target exits 1 when no argument provided" {
    run require_target
    assert_failure
}

@test "require_target succeeds when argument provided" {
    run require_target "192.168.1.1"
    assert_success
}
