#!/usr/bin/env bash
# traceroute/examples.sh — Route tracing and network path analysis examples
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

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

require_cmd traceroute "apt install traceroute (Debian/Ubuntu) | dnf install traceroute (RHEL/Fedora) | pre-installed on macOS"
require_target "${1:-}"
safety_banner

TARGET="$1"

HAS_MTR=false
check_cmd mtr && HAS_MTR=true

info "=== Traceroute & MTR Examples ==="
info "Target: ${TARGET}"
echo ""

# 1. Basic traceroute
info "1) Basic traceroute — show the path to a host"
echo "   traceroute ${TARGET}"
echo ""

# 2. Numeric output — skip DNS lookups for speed
info "2) Numeric output — skip DNS lookups for speed"
echo "   traceroute -n ${TARGET}"
echo ""

# 3. ICMP traceroute — requires sudo
info "3) ICMP traceroute — use ICMP ECHO instead of UDP (requires sudo)"
echo "   sudo traceroute -I ${TARGET}"
echo ""

# 4. Limit to 15 hops, 1 probe per hop
info "4) Limit to 15 hops, 1 probe per hop (faster)"
echo "   traceroute -m 15 -q 1 ${TARGET}"
echo ""

# 5. TCP traceroute — platform-specific
info "5) TCP traceroute — bypasses firewalls that block ICMP/UDP (requires sudo)"
if [[ "$(uname -s)" == "Darwin" ]]; then
    echo "   sudo traceroute -P tcp ${TARGET}"
else
    echo "   sudo traceroute -T ${TARGET}"
fi
echo ""

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

# Interactive demo
[[ -t 0 ]] || exit 0

read -rp "Run a basic traceroute to ${TARGET}? [y/N] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    info "Running: traceroute -n -q 1 -m 15 ${TARGET}"
    traceroute -n -q 1 -m 15 "$TARGET"
fi
