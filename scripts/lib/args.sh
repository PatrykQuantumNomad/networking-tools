#!/usr/bin/env bash
# args.sh -- Argument parsing helpers
# Provides parse_common_args() for consistent flag handling across all scripts.

# Source guard
[[ -n "${_ARGS_LOADED:-}" ]] && return 0
_ARGS_LOADED=1

# Execution mode: "show" (default) or "execute" (-x/--execute)
EXECUTE_MODE="${EXECUTE_MODE:-show}"

# Remaining arguments after common flags are extracted
REMAINING_ARGS=()

# Parse common flags shared by all scripts
# Usage: parse_common_args "$@"
# After: access remaining args via REMAINING_ARGS array
#
# Handles: -h/--help, -v/--verbose, -q/--quiet, -x/--execute, --
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
}
