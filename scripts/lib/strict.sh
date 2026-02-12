#!/usr/bin/env bash
# ============================================================================
# @description  Strict mode and error handling with ERR trap stack traces
# @usage        Sourced via common.sh (not invoked directly)
# @dependencies None
# ============================================================================

# Source guard — prevent double-sourcing
[[ -n "${_STRICT_LOADED:-}" ]] && return 0
_STRICT_LOADED=1

# Strict mode: exit on error (-e), inherit ERR traps (-E), undefined vars (-u), pipe failures
set -eEuo pipefail

# Enable inherit_errexit for Bash 4.4+ (subshell command substitutions inherit errexit)
if ((BASH_VERSINFO[0] > 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] >= 4))); then
    shopt -s inherit_errexit
fi

# ERR trap handler — prints stack trace to stderr
# Uses plain echo (NOT library functions) because the error may originate from a library function.
_strict_error_handler() {
    local exit_code=$?
    local line_no="${BASH_LINENO[0]}"
    local command="${BASH_COMMAND}"

    echo "[ERROR] Command failed (exit $exit_code) at line $line_no: $command" >&2

    # Walk the call stack (start at i=1 to skip this handler)
    local i
    for ((i = 1; i < ${#FUNCNAME[@]}; i++)); do
        local func="${FUNCNAME[$i]}"
        local file="${BASH_SOURCE[$i]}"
        local line="${BASH_LINENO[$((i - 1))]}"
        echo "  at ${func}() in ${file}:${line}" >&2
    done
}

trap '_strict_error_handler' ERR
