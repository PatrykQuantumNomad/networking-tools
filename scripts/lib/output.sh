#!/usr/bin/env bash
# output.sh — Safety banner, interactivity check, and project root
# Provides safety_banner(), is_interactive(), PROJECT_ROOT.

# Source guard — prevent double-sourcing
[[ -n "${_OUTPUT_LOADED:-}" ]] && return 0
_OUTPUT_LOADED=1

# Safety banner — displayed before any active scanning
safety_banner() {
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}  AUTHORIZED USE ONLY${NC}"
    echo -e "${RED}  Only scan targets you own or have${NC}"
    echo -e "${RED}  explicit written permission to test.${NC}"
    echo -e "${RED}========================================${NC}"
    echo ""
}

# Check if running in an interactive terminal
is_interactive() {
    [[ -t 0 ]]
}

# Project root directory (lib/ is two levels below project root)
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Run a command or display it, depending on EXECUTE_MODE
# In "show" mode (default): prints description + indented command
# In "execute" mode (-x): prints description + runs the command
#
# Usage: run_or_show "N) Description" command [args...]
run_or_show() {
    local description="$1"
    shift

    if [[ "${EXECUTE_MODE:-show}" == "execute" ]]; then
        info "$description"
        debug "Executing: $*"
        "$@"
        echo ""
    else
        info "$description"
        echo "   $*"
        echo ""
    fi
}

# Prompt for confirmation before executing commands in -x mode
# No-op in show mode (default). Exits if user declines.
# Refuses to execute if stdin is not a terminal (piped/automated).
#
# Usage: confirm_execute [target]
confirm_execute() {
    local target="${1:-}"
    [[ "${EXECUTE_MODE:-show}" != "execute" ]] && return 0

    if [[ ! -t 0 ]]; then
        warn "Execute mode requires an interactive terminal for confirmation"
        exit 1
    fi

    echo ""
    warn "Execute mode: commands will run against ${target:-the target}"
    read -rp "Continue? [y/N] " answer
    [[ "$answer" =~ ^[Yy]$ ]] || exit 0
}
