#!/usr/bin/env bash
# traceroute/trace-network-path.sh — Trace the network path to a host
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [target] [-h|--help]"
    echo ""
    echo "Description:"
    echo "  Traces the network path to a target host, showing every hop"
    echo "  (router) between you and the destination. Useful for"
    echo "  understanding network topology and diagnosing routing issues."
    echo "  Default target is example.com if none is provided."
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")                  # Trace to example.com"
    echo "  $(basename "$0") 8.8.8.8          # Trace to Google DNS"
    echo "  $(basename "$0") target.local     # Trace to internal host"
    echo "  $(basename "$0") --help           # Show this help message"
}

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

require_cmd traceroute "apt install traceroute (Debian/Ubuntu) | dnf install traceroute (RHEL/Fedora) | pre-installed on macOS"

TARGET="${1:-example.com}"
OS_TYPE="$(uname -s)"

safety_banner

info "=== Trace Network Path ==="
info "Target: ${TARGET}"
echo ""

info "How traceroute works:"
echo "   Traceroute sends packets with incrementing TTL (Time To Live) values."
echo "   Each router along the path decrements the TTL by 1. When TTL reaches 0,"
echo "   the router sends back an ICMP Time Exceeded message, revealing its address."
echo "   By starting at TTL=1 and incrementing, traceroute discovers every hop."
echo ""

# 1. Basic path trace
info "1) Basic path trace"
echo "   traceroute ${TARGET}"
echo ""

# 2. Numeric — skip DNS for speed
info "2) Numeric output — skip DNS resolution for speed"
echo "   traceroute -n ${TARGET}"
echo ""

# 3. Set max hops to 20
info "3) Set max hops to 20"
echo "   traceroute -m 20 ${TARGET}"
echo ""

# 4. Single probe per hop for faster results
info "4) Single probe per hop — faster results"
echo "   traceroute -q 1 ${TARGET}"
echo ""

# 5. Set wait timeout to 2 seconds
info "5) Set wait timeout to 2 seconds per probe"
echo "   traceroute -w 2 ${TARGET}"
echo ""

# 6. Start from hop 5 — skip known local hops
info "6) Start from hop 5 — skip known local network hops"
echo "   traceroute -f 5 ${TARGET}"
echo ""

# 7. ICMP mode — requires sudo
info "7) ICMP mode — use ICMP ECHO instead of UDP (requires sudo)"
echo "   sudo traceroute -I ${TARGET}"
echo ""

# 8. TCP mode — platform-detect
info "8) TCP mode — bypasses firewalls that block ICMP/UDP (requires sudo)"
if [[ "$OS_TYPE" == "Darwin" ]]; then
    echo "   sudo traceroute -P tcp ${TARGET}"
else
    echo "   sudo traceroute -T ${TARGET}"
fi
echo ""

# 9. Trace to port 443 — TCP to specific port
info "9) TCP trace to port 443 — test HTTPS path (requires sudo)"
if [[ "$OS_TYPE" == "Darwin" ]]; then
    echo "   sudo traceroute -P tcp -p 443 ${TARGET}"
else
    echo "   sudo traceroute -T -p 443 ${TARGET}"
fi
echo ""

# 10. Trace with AS number lookups
info "10) Trace with AS number lookups — show autonomous system for each hop"
if [[ "$OS_TYPE" == "Darwin" ]]; then
    echo "    traceroute -a ${TARGET}"
    echo "    Note: macOS uses -a for AS lookups"
else
    echo "    traceroute -A ${TARGET}"
    echo "    Note: Linux uses -A for AS lookups (macOS does not support -A)"
fi
echo ""

# Interactive demo (skip if non-interactive)
[[ ! -t 0 ]] && exit 0

read -rp "Run a basic traceroute to ${TARGET}? [y/N] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    info "Running: traceroute -n -q 1 -m 15 ${TARGET}"
    traceroute -n -q 1 -m 15 "$TARGET"
fi
