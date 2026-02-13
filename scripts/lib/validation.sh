#!/usr/bin/env bash
# ============================================================================
# @description  Command and target validation functions
# @usage        Sourced via common.sh (not invoked directly)
# @dependencies colors.sh, logging.sh
# ============================================================================

# Source guard — prevent double-sourcing
[[ -n "${_VALIDATION_LOADED:-}" ]] && return 0
_VALIDATION_LOADED=1

# Check if running as root (some tools need it)
require_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root (sudo)"
        exit 1
    fi
}

# Check if a command exists
check_cmd() {
    command -v "$1" &>/dev/null
}

# Require a command or exit with install hint
require_cmd() {
    local cmd="$1"
    local install_hint="${2:-}"
    if ! check_cmd "$cmd"; then
        error "'$cmd' is not installed."
        [[ -n "$install_hint" ]] && info "Install: $install_hint"
        exit 1
    fi
}

# Add john-jumbo's *2john utilities to PATH if they aren't already findable.
# Homebrew installs zip2john, rar2john, etc. in share/john/ instead of bin/.
setup_john_path() {
    # Already on PATH — nothing to do
    command -v zip2john &>/dev/null && return 0

    local john_share=""

    # macOS: Homebrew (Intel or Apple Silicon)
    for prefix in /opt/homebrew/opt/john-jumbo /usr/local/opt/john-jumbo; do
        if [[ -d "${prefix}/share/john" ]]; then
            john_share="${prefix}/share/john"
            break
        fi
    done

    # Linux: common package locations
    if [[ -z "$john_share" ]]; then
        for dir in /usr/share/john /usr/lib/john; do
            if [[ -x "${dir}/zip2john" ]]; then
                john_share="$dir"
                break
            fi
        done
    fi

    if [[ -n "$john_share" ]]; then
        export PATH="${john_share}:${PATH}"
    fi
}

# Validate that a target IP/hostname was provided
require_target() {
    if [[ -z "${1:-}" ]]; then
        error "Usage: $0 <target-ip-or-hostname>"
        error "Only scan targets you own or have written permission to test."
        exit 1
    fi
}
