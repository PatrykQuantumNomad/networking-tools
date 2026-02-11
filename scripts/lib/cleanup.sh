#!/usr/bin/env bash
# cleanup.sh — EXIT trap, temp file management, and retry utility
# Provides make_temp(), register_cleanup(), retry_with_backoff().

# Source guard — prevent double-sourcing
[[ -n "${_CLEANUP_LOADED:-}" ]] && return 0
_CLEANUP_LOADED=1

# Base temp directory — all make_temp outputs live inside this directory.
# Using a single base directory avoids the bash subshell limitation where
# array modifications inside $() command substitution are lost.
_CLEANUP_BASE_DIR=$(mktemp -d "${TMPDIR:-/tmp}/ntool-session.XXXXXX")

# Registered cleanup commands (still array-based; register_cleanup is called
# directly, not via command substitution, so array propagation works fine)
_CLEANUP_COMMANDS=()

# EXIT trap handler — removes base temp dir and runs registered commands
_cleanup_handler() {
    local exit_code=$?

    # Remove the entire base temp directory (covers all make_temp outputs)
    rm -rf "$_CLEANUP_BASE_DIR" 2>/dev/null || true

    # Execute registered cleanup commands
    local cmd
    for cmd in "${_CLEANUP_COMMANDS[@]+"${_CLEANUP_COMMANDS[@]}"}"; do
        eval "$cmd" 2>/dev/null || true
    done

    exit "$exit_code"
}

# Register EXIT trap only (not INT/TERM — EXIT fires on those signals too)
trap '_cleanup_handler' EXIT

# Register an arbitrary cleanup command to run on exit
register_cleanup() {
    _CLEANUP_COMMANDS+=("$1")
}

# Create a temporary file or directory that is auto-cleaned on exit
# All temp items are created inside $_CLEANUP_BASE_DIR so the EXIT trap
# cleans them up automatically — even when called from a subshell.
# Usage: make_temp [file|dir] [prefix]
make_temp() {
    local type="${1:-file}"
    local prefix="${2:-ntool}"
    local path

    if [[ "$type" == "dir" ]]; then
        path=$(mktemp -d "${_CLEANUP_BASE_DIR}/${prefix}.XXXXXX")
    else
        path=$(mktemp "${_CLEANUP_BASE_DIR}/${prefix}.XXXXXX")
    fi

    echo "$path"
}

# Retry a command with exponential backoff
# Usage: retry_with_backoff [max_attempts] [initial_delay] command [args...]
retry_with_backoff() {
    local max_attempts="${1:-3}"
    local delay="${2:-1}"
    shift 2

    local attempt=1
    while true; do
        if "$@"; then
            return 0
        fi

        if ((attempt >= max_attempts)); then
            warn "Command failed after $max_attempts attempts: $*"
            return 1
        fi

        debug "Attempt $attempt/$max_attempts failed, retrying in ${delay}s: $*"
        sleep "$delay"
        delay=$(echo "$delay * 2" | bc)
        ((attempt++))
    done
}
