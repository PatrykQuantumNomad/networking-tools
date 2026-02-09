#!/usr/bin/env bash
# common.sh — Shared utility functions for all tool scripts
# Source this file: source "$(dirname "$0")/../common.sh"

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }

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

# Safety banner — displayed before any active scanning
safety_banner() {
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}  AUTHORIZED USE ONLY${NC}"
    echo -e "${RED}  Only scan targets you own or have${NC}"
    echo -e "${RED}  explicit written permission to test.${NC}"
    echo -e "${RED}========================================${NC}"
    echo ""
}

# Project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
