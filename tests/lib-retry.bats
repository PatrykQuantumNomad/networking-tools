#!/usr/bin/env bats
# tests/lib-retry.bats — Unit tests for retry_with_backoff (UNIT-06)
# Covers immediate success, max attempts exhausted, mid-retry success,
# exact retry count, and single-attempt failure.

setup() {
    load 'test_helper/common-setup'
    _common_setup

    # Required by parse_common_args (sourced via common.sh)
    show_help() { echo "test help"; }

    source "${PROJECT_ROOT}/scripts/common.sh"

    # Disable strict mode and clear traps for BATS compatibility
    set +eEuo pipefail
    trap - ERR

    # Override sleep to be instant (prevents real delays in tests)
    sleep() { :; }
    export -f sleep

    # Reset to known state
    VERBOSE=0
    LOG_LEVEL="info"
}

# --- retry_with_backoff tests ---

@test "retry_with_backoff returns 0 on immediate success" {
    run retry_with_backoff 3 1 true
    assert_success
}

@test "retry_with_backoff returns 1 after max attempts with failing command" {
    run retry_with_backoff 3 1 false
    assert_failure
}

@test "retry_with_backoff succeeds on second attempt" {
    local counter_file="${BATS_TEST_TMPDIR}/counter"
    echo "0" > "$counter_file"

    attempt_cmd() {
        local count
        count=$(<"${BATS_TEST_TMPDIR}/counter")
        count=$((count + 1))
        echo "$count" > "${BATS_TEST_TMPDIR}/counter"
        (( count >= 2 ))
    }
    export -f attempt_cmd
    export BATS_TEST_TMPDIR

    run retry_with_backoff 3 1 attempt_cmd
    assert_success
}

@test "retry_with_backoff retries exactly max_attempts times" {
    local counter_file="${BATS_TEST_TMPDIR}/counter"
    echo "0" > "$counter_file"

    counting_fail() {
        local count
        count=$(<"${BATS_TEST_TMPDIR}/counter")
        count=$((count + 1))
        echo "$count" > "${BATS_TEST_TMPDIR}/counter"
        return 1
    }
    export -f counting_fail
    export BATS_TEST_TMPDIR

    run retry_with_backoff 3 1 counting_fail
    assert_failure
    assert_equal "$(cat "${BATS_TEST_TMPDIR}/counter")" "3"
}

@test "retry_with_backoff with 1 max attempt tries once" {
    local counter_file="${BATS_TEST_TMPDIR}/counter"
    echo "0" > "$counter_file"

    counting_fail() {
        local count
        count=$(<"${BATS_TEST_TMPDIR}/counter")
        count=$((count + 1))
        echo "$count" > "${BATS_TEST_TMPDIR}/counter"
        return 1
    }
    export -f counting_fail
    export BATS_TEST_TMPDIR

    run retry_with_backoff 1 1 counting_fail
    assert_failure
    assert_equal "$(cat "${BATS_TEST_TMPDIR}/counter")" "1"
}
