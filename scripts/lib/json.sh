#!/usr/bin/env bash
# ============================================================================
# @description  JSON output mode: state management, result accumulation, envelope finalization
# @usage        Sourced via common.sh (not invoked directly)
# @dependencies cleanup.sh (make_temp)
# ============================================================================

# Source guard — prevent double-sourcing
[[ -n "${_JSON_LOADED:-}" ]] && return 0
_JSON_LOADED=1

# --- State variables ---
JSON_MODE="${JSON_MODE:-0}"
_JSON_TOOL=""
_JSON_TARGET=""
_JSON_SCRIPT=""
_JSON_STARTED=""
_JSON_RESULTS=()

# --- Internal: check if jq is available (runs at source time) ---
_json_check_jq() {
    if command -v jq &>/dev/null; then
        _JSON_JQ_AVAILABLE=1
    else
        _JSON_JQ_AVAILABLE=0
    fi
}

# --- Internal: require jq or exit with install hint ---
# Called from args.sh when -j is actually parsed
_json_require_jq() {
    if [[ "${_JSON_JQ_AVAILABLE:-0}" != "1" ]]; then
        echo "[ERROR] jq is required for JSON output (-j). Install: brew install jq (macOS) or apt install jq (Linux)" >&2
        exit 1
    fi
}

# --- Public: check if JSON mode is active ---
json_is_active() {
    [[ "${JSON_MODE:-0}" == "1" ]]
}

# --- Public: set metadata for the JSON envelope ---
# Usage: json_set_meta "tool" "target"
json_set_meta() {
    json_is_active || return 0
    _JSON_TOOL="$1"
    _JSON_TARGET="${2:-}"
    _JSON_SCRIPT="$(basename "${BASH_SOURCE[1]:-unknown}" .sh)"
    _JSON_STARTED="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
}

# --- Public: accumulate an executed command result ---
# Usage: json_add_result "description" exit_code "stdout" "stderr" "command"
json_add_result() {
    json_is_active || return 0
    local description="$1"
    local exit_code="$2"
    local stdout="$3"
    local stderr="$4"
    local command="$5"

    local json_obj
    json_obj=$(jq -n \
        --arg desc "$description" \
        --argjson code "$exit_code" \
        --arg out "$stdout" \
        --arg err "$stderr" \
        --arg cmd "$command" \
        '{description: $desc, command: $cmd, exit_code: $code, stdout: $out, stderr: $err}')
    _JSON_RESULTS+=("$json_obj")
}

# --- Public: accumulate a show-mode example command ---
# Usage: json_add_example "description" "command"
json_add_example() {
    json_is_active || return 0
    local description="$1"
    local command="$2"

    local json_obj
    json_obj=$(jq -n \
        --arg desc "$description" \
        --arg cmd "$command" \
        '{description: $desc, command: $cmd}')
    _JSON_RESULTS+=("$json_obj")
}

# --- Public: assemble envelope and write to fd3 (or stdout fallback) ---
json_finalize() {
    json_is_active || return 0

    local finished count results_json mode

    finished="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    count=${#_JSON_RESULTS[@]}

    # Build results array
    if ((count > 0)); then
        results_json=$(printf '%s\n' "${_JSON_RESULTS[@]}" | jq -s '.')
    else
        results_json="[]"
    fi

    # Determine mode
    mode="show"
    [[ "${EXECUTE_MODE:-show}" == "execute" ]] && mode="execute"

    # Build envelope
    local envelope
    envelope=$(jq -n \
        --arg tool "$_JSON_TOOL" \
        --arg script "$_JSON_SCRIPT" \
        --arg target "$_JSON_TARGET" \
        --arg started "$_JSON_STARTED" \
        --arg finished "$finished" \
        --arg mode "$mode" \
        --argjson results "$results_json" \
        --argjson count "$count" \
        '{
            meta: {
                tool: $tool,
                script: $script,
                target: $target,
                started: $started,
                finished: $finished,
                mode: $mode
            },
            results: $results,
            summary: {
                total: $count,
                succeeded: (if $mode == "execute" then ([$results[] | select(.exit_code == 0)] | length) else $count end),
                failed: (if $mode == "execute" then ([$results[] | select(.exit_code != 0)] | length) else 0 end)
            }
        }')

    # Write to fd3 if open, else stdout (fallback for testing)
    if { true >&3; } 2>/dev/null; then
        echo "$envelope" >&3
    else
        echo "$envelope"
    fi
}

# Run jq availability check at source time
_json_check_jq
