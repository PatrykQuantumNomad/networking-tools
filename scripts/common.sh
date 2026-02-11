#!/usr/bin/env bash
# common.sh — Shared utility functions for all tool scripts
# Source this file: source "$(dirname "$0")/../common.sh"

# --- Bash Version Guard ---
# Require Bash 4.0+ (associative arrays, mapfile, etc.)
# Uses only Bash 2.x+ syntax so it prints a clear error on old bash.
if [[ -z "${BASH_VERSINFO:-}" ]] || ((BASH_VERSINFO[0] < 4)); then
    echo "[ERROR] Bash 4.0+ required (found: ${BASH_VERSION:-unknown})" >&2
    echo "[ERROR] macOS ships Bash 3.2 -- install modern bash: brew install bash" >&2
    exit 1
fi

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

# Check if running in an interactive terminal
is_interactive() {
    [[ -t 0 ]]
}

# Project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# --- Netcat Variant Detection ---
# Identifies which netcat implementation is installed (ncat, gnu, traditional, openbsd)
# Used by scripts/netcat/ scripts to label variant-specific flags

detect_nc_variant() {
    local help_text
    help_text=$(nc -h 2>&1 || true)
    if echo "$help_text" | grep -qi 'ncat'; then
        echo "ncat"
    elif echo "$help_text" | grep -qi 'gnu'; then
        echo "gnu"
    elif echo "$help_text" | grep -qi 'connect to somewhere'; then
        echo "traditional"
    else
        # OpenBSD nc (including macOS Apple fork) -- detected by exclusion
        echo "openbsd"
    fi
}

# --- Diagnostic Report Functions ---
# Used by Pattern B (diagnostic scripts), not Pattern A (educational examples)

report_pass()    { echo -e "${GREEN}[PASS]${NC} $*"; }
report_fail()    { echo -e "${RED}[FAIL]${NC} $*"; }
report_warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
report_skip()    { echo -e "${CYAN}[SKIP]${NC} $*"; }

report_section() { echo -e "\n${CYAN}=== $* ===${NC}\n"; }

# Portable timeout wrapper (macOS lacks GNU timeout)
_run_with_timeout() {
    local seconds="$1"
    shift
    if command -v timeout &>/dev/null; then
        timeout "$seconds" "$@"
    else
        # POSIX fallback: run in background, kill after timeout
        "$@" &
        local pid=$!
        ( sleep "$seconds" && kill "$pid" 2>/dev/null ) &
        local watchdog=$!
        wait "$pid" 2>/dev/null
        local exit_code=$?
        kill "$watchdog" 2>/dev/null
        wait "$watchdog" 2>/dev/null
        return $exit_code
    fi
}

# Execute a command with timeout and report pass/fail
# Usage: run_check "Description of check" command arg1 arg2
run_check() {
    local description="$1"
    shift
    local output
    if output=$(_run_with_timeout 10 "$@" 2>&1); then
        report_pass "$description"
        echo "$output" | sed 's/^/   /'
    else
        local exit_code=$?
        if [[ $exit_code -eq 124 ]]; then
            report_warn "$description (timed out)"
        else
            report_fail "$description"
        fi
        [[ -n "$output" ]] && echo "$output" | sed 's/^/   /' || true
    fi
}
