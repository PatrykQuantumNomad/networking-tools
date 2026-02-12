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

# Validate that a target IP/hostname was provided
require_target() {
    if [[ -z "${1:-}" ]]; then
        error "Usage: $0 <target-ip-or-hostname>"
        error "Only scan targets you own or have written permission to test."
        exit 1
    fi
}
