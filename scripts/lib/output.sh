#!/usr/bin/env bash
# ============================================================================
# @description  Safety banner, interactivity check, and project root
# @usage        Sourced via common.sh (not invoked directly)
# @dependencies colors.sh, json.sh, cleanup.sh
# ============================================================================

# Source guard — prevent double-sourcing
[[ -n "${_OUTPUT_LOADED:-}" ]] && return 0
_OUTPUT_LOADED=1

# Safety banner — displayed before any active scanning
safety_banner() {
    # Suppress in JSON mode -- banner is informational, not a control
    json_is_active && return 0
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
# Used by sourcing scripts for wordlist/sample paths
# shellcheck disable=SC2034
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Run a command or display it, depending on EXECUTE_MODE
# In "show" mode (default): prints description + indented command
# In "execute" mode (-x): prints description + runs the command
# In JSON mode: accumulates results/examples instead of printing
#
# Usage: run_or_show "N) Description" command [args...]
run_or_show() {
    local description="$1"
    shift

    if [[ "${EXECUTE_MODE:-show}" == "execute" ]]; then
        if json_is_active; then
            # Execute+JSON: capture output, accumulate result
            local stdout_file stderr_file cmd_exit_code
            stdout_file=$(make_temp)
            stderr_file=$(make_temp)
            "$@" > "$stdout_file" 2> "$stderr_file" && cmd_exit_code=0 || cmd_exit_code=$?
            json_add_result "$description" "$cmd_exit_code" "$(<"$stdout_file")" "$(<"$stderr_file")" "$*"
        else
            # Execute+text: existing behavior
            info "$description"
            debug "Executing: $*"
            "$@"
            echo ""
        fi
    else
        if json_is_active; then
            # Show+JSON: accumulate example command
            json_add_example "$description" "$*"
        else
            # Show+text: existing behavior
            info "$description"
            echo "   $*"
            echo ""
        fi
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
    # Skip interactive prompt in JSON mode (FLAG-04)
    json_is_active && return 0

    if [[ ! -t 0 ]]; then
        warn "Execute mode requires an interactive terminal for confirmation"
        exit 1
    fi

    echo ""
    warn "Execute mode: commands will run against ${target:-the target}"
    read -rp "Continue? [y/N] " answer
    [[ "$answer" =~ ^[Yy]$ ]] || exit 0
}
