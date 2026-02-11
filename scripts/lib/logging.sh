#!/usr/bin/env bash
# logging.sh — Logging functions with LOG_LEVEL filtering and VERBOSE timestamps
# Provides info, success, warn, error, debug with configurable verbosity.

# Source guard — prevent double-sourcing
[[ -n "${_LOGGING_LOADED:-}" ]] && return 0
_LOGGING_LOADED=1

# Defaults
LOG_LEVEL="${LOG_LEVEL:-info}"
VERBOSE="${VERBOSE:-0}"

# VERBOSE >= 1 implies debug level
if ((VERBOSE >= 1)); then
    LOG_LEVEL="debug"
fi

# Map log level name to numeric value
_log_level_num() {
    case "$1" in
        debug) echo 0 ;;
        info)  echo 1 ;;
        warn)  echo 2 ;;
        error) echo 3 ;;
        *)     echo 1 ;;
    esac
}

# Check if a message at the given level should be displayed
_should_log() {
    local msg_level="$1"
    local msg_num
    local cur_num
    msg_num=$(_log_level_num "$msg_level")
    cur_num=$(_log_level_num "$LOG_LEVEL")
    ((msg_num >= cur_num))
}

# Format optional timestamp prefix (only when VERBOSE >= 1)
_log_timestamp() {
    if ((VERBOSE >= 1)); then
        echo "[$(date '+%H:%M:%S')] "
    fi
}

debug() {
    _should_log debug || return 0
    local ts
    ts="[$(date '+%H:%M:%S')] "
    echo -e "${CYAN}${ts}[DEBUG]${NC} $*"
}

info() {
    _should_log info || return 0
    local ts
    ts=$(_log_timestamp)
    echo -e "${BLUE}${ts}[INFO]${NC} $*"
}

success() {
    _should_log info || return 0
    local ts
    ts=$(_log_timestamp)
    echo -e "${GREEN}${ts}[OK]${NC} $*"
}

warn() {
    _should_log warn || return 0
    local ts
    ts=$(_log_timestamp)
    echo -e "${YELLOW}${ts}[WARN]${NC} $*"
}

error() {
    # Errors are always visible — not gated by _should_log
    local ts
    ts=$(_log_timestamp)
    echo -e "${RED}${ts}[ERROR]${NC} $*" >&2
}
