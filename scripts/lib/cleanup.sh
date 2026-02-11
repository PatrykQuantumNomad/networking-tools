#!/usr/bin/env bash
# cleanup.sh — EXIT trap, temp file management, and retry utility
# Provides make_temp(), register_cleanup(), retry_with_backoff().

# Source guard — prevent double-sourcing
[[ -n "${_CLEANUP_LOADED:-}" ]] && return 0
_CLEANUP_LOADED=1

# Tracking arrays for automatic cleanup
_CLEANUP_FILES=()
_CLEANUP_DIRS=()
_CLEANUP_COMMANDS=()

# EXIT trap handler — cleans up temp files, dirs, and runs registered commands
_cleanup_handler() {
    local exit_code=$?

    # Remove tracked temp files
    local f
    for f in "${_CLEANUP_FILES[@]+"${_CLEANUP_FILES[@]}"}"; do
        rm -f "$f" 2>/dev/null || true
    done

    # Remove tracked temp directories
    local d
    for d in "${_CLEANUP_DIRS[@]+"${_CLEANUP_DIRS[@]}"}"; do
        rm -rf "$d" 2>/dev/null || true
    done

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
# Usage: make_temp [file|dir] [prefix]
make_temp() {
    local type="${1:-file}"
    local prefix="${2:-ntool}"
    local path

    if [[ "$type" == "dir" ]]; then
        path=$(mktemp -d "${TMPDIR:-/tmp}/${prefix}.XXXXXX")
        _CLEANUP_DIRS+=("$path")
    else
        path=$(mktemp "${TMPDIR:-/tmp}/${prefix}.XXXXXX")
        _CLEANUP_FILES+=("$path")
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
