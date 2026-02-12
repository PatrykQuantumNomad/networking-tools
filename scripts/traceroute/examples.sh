#!/usr/bin/env bash
# ============================================================================
# @description  Network path tracing examples using traceroute
# @usage        traceroute/examples.sh <target> [-h|--help] [-v|--verbose] [-x|--execute]
# @dependencies traceroute, common.sh
# ============================================================================
source "$(dirname "$0")/../common.sh"

show_help() {
    cat <<EOF
Usage: $(basename "$0") <target>

traceroute / mtr - Route tracing and network path analysis examples

Displays common traceroute and mtr commands for the given target host
and optionally runs a quick traceroute demo.

Examples:
    $(basename "$0") 8.8.8.8
    $(basename "$0") example.com
EOF
}

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

require_cmd traceroute "apt install traceroute (Debian/Ubuntu) | dnf install traceroute (RHEL/Fedora) | pre-installed on macOS"
require_target "${1:-}"

confirm_execute "${1:-}"
safety_banner

TARGET="$1"

HAS_MTR=false
check_cmd mtr && HAS_MTR=true

info "=== Traceroute & MTR Examples ==="
info "Target: ${TARGET}"
echo ""

# 1. Basic traceroute
run_or_show "1) Basic traceroute — show the path to a host" \
    traceroute "$TARGET"

# 2. Numeric output — skip DNS lookups for speed
run_or_show "2) Numeric output — skip DNS lookups for speed" \
    traceroute -n "$TARGET"

# 3. ICMP traceroute — requires sudo
run_or_show "3) ICMP traceroute — use ICMP ECHO instead of UDP (requires sudo)" \
    sudo traceroute -I "$TARGET"

# 4. Limit to 15 hops, 1 probe per hop
run_or_show "4) Limit to 15 hops, 1 probe per hop (faster)" \
    traceroute -m 15 -q 1 "$TARGET"

# 5. TCP traceroute — platform-specific
if [[ "$(uname -s)" == "Darwin" ]]; then
    run_or_show "5) TCP traceroute — bypasses firewalls (requires sudo)" \
        sudo traceroute -P tcp "$TARGET"
else
    run_or_show "5) TCP traceroute — bypasses firewalls (requires sudo)" \
        sudo traceroute -T "$TARGET"
fi

# 6. mtr — continuous traceroute with live statistics
info "6) mtr — continuous traceroute with live statistics"
echo "   mtr ${TARGET}"
if [[ "$HAS_MTR" == false ]]; then
    echo "   (mtr not installed — brew install mtr / apt install mtr)"
fi
echo ""

# 7. mtr report mode — 10 cycles, non-interactive
info "7) mtr report mode — run 10 cycles and print summary"
echo "   mtr --report -c 10 ${TARGET}"
echo "   Note: requires sudo on macOS"
echo ""

# 8. mtr wide report — show full hostnames
info "8) mtr wide report — show full hostnames in output"
echo "   mtr --report --report-wide -c 10 ${TARGET}"
echo ""

# 9. mtr with no DNS resolution
info "9) mtr with no DNS resolution — faster results"
echo "   mtr --report -n -c 10 ${TARGET}"
echo ""

# 10. mtr specifying max hops
info "10) mtr specifying max hops (20)"
echo "    mtr --report -m 20 -c 10 ${TARGET}"
echo ""

# Interactive demo (skip if non-interactive)
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    [[ ! -t 0 ]] && exit 0
    read -rp "Run a basic traceroute to ${TARGET}? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        info "Running: traceroute -n -q 1 -m 15 ${TARGET}"
        traceroute -n -q 1 -m 15 "$TARGET"
    fi
fi
