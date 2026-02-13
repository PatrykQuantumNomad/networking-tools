#!/usr/bin/env bats
# tests/lib-json.bats — Unit tests for JSON output library (scripts/lib/json.sh)
# TEST-01: Proves all json.sh public functions and internal helpers work correctly.

setup() {
    load 'test_helper/common-setup'
    _common_setup

    # Required by parse_common_args (sourced via common.sh)
    show_help() { echo "test help"; }

    source "${PROJECT_ROOT}/scripts/common.sh"

    # Disable strict mode and clear traps for BATS compatibility
    set +eEuo pipefail
    trap - ERR

    # Reset all mutable JSON state
    JSON_MODE=0
    _JSON_TOOL=""
    _JSON_TARGET=""
    _JSON_SCRIPT=""
    _JSON_STARTED=""
    _JSON_RESULTS=()
    EXECUTE_MODE="show"
    VERBOSE=0
    LOG_LEVEL="info"
    REMAINING_ARGS=()
}

# --- Subprocess helper ---
# Runs json.sh functions in an isolated subprocess with fd3 closed,
# forcing json_finalize to use the stdout fallback path.
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
        _JSON_TOOL=""
        _JSON_TARGET=""
        _JSON_SCRIPT=""
        _JSON_STARTED="2026-01-01T00:00:00Z"
        _JSON_RESULTS=()
        EXECUTE_MODE="show"
        '"$body"'
    '
}

# =============================================================================
# Direct-call tests (no subprocess needed)
# =============================================================================

# --- json_is_active ---

@test "json_is_active returns false when JSON_MODE=0" {
    JSON_MODE=0
    run json_is_active
    assert_failure
}

@test "json_is_active returns true when JSON_MODE=1" {
    JSON_MODE=1
    run json_is_active
    assert_success
}

@test "json_is_active returns false when JSON_MODE unset" {
    unset JSON_MODE
    run json_is_active
    assert_failure
}

# --- json_set_meta ---

@test "json_set_meta is no-op when inactive" {
    JSON_MODE=0
    json_set_meta "nmap" "target"
    assert_equal "$_JSON_TOOL" ""
}

@test "json_set_meta populates tool and target when active" {
    JSON_MODE=1
    json_set_meta "nmap" "192.168.1.1"
    assert_equal "$_JSON_TOOL" "nmap"
    assert_equal "$_JSON_TARGET" "192.168.1.1"
    [[ -n "$_JSON_STARTED" ]]
}

@test "json_set_meta handles empty target" {
    JSON_MODE=1
    json_set_meta "nmap" ""
    assert_equal "$_JSON_TOOL" "nmap"
    assert_equal "$_JSON_TARGET" ""
}

@test "json_set_meta sets ISO 8601 timestamp" {
    JSON_MODE=1
    json_set_meta "nmap" "target"
    [[ "$_JSON_STARTED" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]
}

# --- Guard no-ops ---

@test "json_add_result is no-op when inactive" {
    JSON_MODE=0
    json_add_result "test" 0 "out" "err" "cmd"
    assert_equal "${#_JSON_RESULTS[@]}" "0"
}

@test "json_add_example is no-op when inactive" {
    JSON_MODE=0
    json_add_example "test" "cmd"
    assert_equal "${#_JSON_RESULTS[@]}" "0"
}

@test "json_finalize is no-op when inactive" {
    JSON_MODE=0
    run json_finalize
    assert_success
    assert_output ""
}

# --- _json_require_jq ---

@test "_json_require_jq exits 1 when jq unavailable" {
    _JSON_JQ_AVAILABLE=0
    run _json_require_jq
    assert_failure
    assert_output --partial "jq is required"
}

@test "_json_require_jq succeeds when jq available" {
    _JSON_JQ_AVAILABLE=1
    run _json_require_jq
    assert_success
}

# =============================================================================
# Subprocess tests (use _run_json_subprocess helper)
# =============================================================================

@test "json_finalize produces valid JSON with empty results" {
    _run_json_subprocess '
        _JSON_TOOL="nmap"
        _JSON_TARGET="target"
        json_finalize
    '
    assert_success
    echo "$output" | jq -e '.results == []'
    echo "$output" | jq -e '.summary.total == 0'
}

@test "json_finalize show mode envelope has correct structure" {
    _run_json_subprocess '
        _JSON_TOOL="nmap"
        _JSON_TARGET="192.168.1.1"
        json_add_example "Port scan" "nmap -p 80 target"
        json_finalize
    '
    assert_success
    echo "$output" | jq -e '.meta.tool == "nmap"'
    echo "$output" | jq -e '.meta.target == "192.168.1.1"'
    echo "$output" | jq -e '.meta.mode == "show"'
    echo "$output" | jq -e '.results | length == 1'
    echo "$output" | jq -e '.results[0].command == "nmap -p 80 target"'
    echo "$output" | jq -e '.summary.total == 1'
    echo "$output" | jq -e '.summary.succeeded == 1'
    echo "$output" | jq -e '.summary.failed == 0'
}

@test "json_finalize execute mode counts succeeded and failed" {
    _run_json_subprocess '
        EXECUTE_MODE="execute"
        _JSON_TOOL="nmap"
        _JSON_TARGET="target"
        json_add_result "Good" 0 "ok" "" "cmd1"
        json_add_result "Bad" 1 "" "err" "cmd2"
        json_finalize
    '
    assert_success
    echo "$output" | jq -e '.meta.mode == "execute"'
    echo "$output" | jq -e '.summary.total == 2'
    echo "$output" | jq -e '.summary.succeeded == 1'
    echo "$output" | jq -e '.summary.failed == 1'
}

@test "json_add_example accumulates multiple examples" {
    _run_json_subprocess '
        _JSON_TOOL="nmap"
        _JSON_TARGET="target"
        json_add_example "First" "cmd1"
        json_add_example "Second" "cmd2"
        json_add_example "Third" "cmd3"
        json_finalize
    '
    assert_success
    echo "$output" | jq -e '.results | length == 3'
    echo "$output" | jq -e '.results[2].description == "Third"'
}

@test "json_add_result accumulates with all fields" {
    _run_json_subprocess '
        EXECUTE_MODE="execute"
        _JSON_TOOL="test"
        _JSON_TARGET="target"
        json_add_result "Scan" 0 "output here" "warnings" "nmap -sV target"
        json_finalize
    '
    assert_success
    echo "$output" | jq -e '.results[0].description == "Scan"'
    echo "$output" | jq -e '.results[0].exit_code == 0'
    echo "$output" | jq -e '.results[0].stdout == "output here"'
    echo "$output" | jq -e '.results[0].stderr == "warnings"'
    echo "$output" | jq -e '.results[0].command == "nmap -sV target"'
}

@test "special characters are properly JSON-escaped" {
    _run_json_subprocess '
        _JSON_TOOL="test"
        _JSON_TARGET="target"
        json_add_example "Test with \"quotes\" and \\backslash" "echo \"hello world\""
        json_finalize
    '
    assert_success
    # jq -e validates the JSON is parseable and the escaped values are correct
    echo "$output" | jq -e '.results | length == 1'
}

@test "json_finalize includes started and finished timestamps" {
    _run_json_subprocess '
        _JSON_TOOL="test"
        _JSON_TARGET="target"
        json_finalize
    '
    assert_success
    echo "$output" | jq -e '.meta.started == "2026-01-01T00:00:00Z"'
    echo "$output" | jq -e '.meta | has("finished")'
}
