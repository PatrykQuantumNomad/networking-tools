#!/usr/bin/env bash
# ============================================================================
# @description  Argument parsing helpers for consistent flag handling
# @usage        Sourced via common.sh (not invoked directly)
# @dependencies None
# ============================================================================

# Source guard
[[ -n "${_ARGS_LOADED:-}" ]] && return 0
_ARGS_LOADED=1

# Execution mode: "show" (default) or "execute" (-x/--execute)
EXECUTE_MODE="${EXECUTE_MODE:-show}"

# JSON output mode: 0 (default) or 1 (-j/--json)
JSON_MODE="${JSON_MODE:-0}"

# Remaining arguments after common flags are extracted
REMAINING_ARGS=()

# Parse common flags shared by all scripts
# Usage: parse_common_args "$@"
# After: access remaining args via REMAINING_ARGS array
#
# Handles: -h/--help, -v/--verbose, -q/--quiet, -x/--execute, -j/--json, --
# Everything else (positional args + unknown flags) -> REMAINING_ARGS
#
# Requires: show_help() to be defined by the calling script
parse_common_args() {
    REMAINING_ARGS=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=$((VERBOSE + 1))
                LOG_LEVEL="debug"
                ;;
            -q|--quiet)
                # Used by logging.sh _should_log()
                # shellcheck disable=SC2034
                LOG_LEVEL="warn"
                ;;
            -x|--execute)
                EXECUTE_MODE="execute"
                ;;
            -j|--json)
                JSON_MODE=1
                ;;
            --)
                shift
                REMAINING_ARGS+=("$@")
                break
                ;;
            *)
                REMAINING_ARGS+=("$1")
                ;;
        esac
        shift
    done

    # Activate JSON mode plumbing when -j was parsed
    if [[ "${JSON_MODE:-0}" == "1" ]]; then
        _json_require_jq
        export NO_COLOR=1
        # Reset color vars -- colors.sh already evaluated at source time (Pitfall 4)
        RED='' GREEN='' YELLOW='' BLUE='' CYAN='' NC=''
        exec 3>&1       # Save original stdout as fd3
        exec 1>&2       # Redirect all stdout to stderr
    fi
}
