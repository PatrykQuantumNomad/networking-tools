#!/usr/bin/env bash
# traceroute/compare-routes.sh — Compare routes using TCP, ICMP, and UDP protocols
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [target] [-h|--help]"
    echo ""
    echo "Description:"
    echo "  Compares network routes using different protocols (TCP, ICMP, UDP)."
    echo "  Different protocols may take different paths due to firewall rules"
    echo "  and routing policies. Helps identify protocol-specific filtering."
    echo "  Default target is example.com if none is provided."
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")                  # Compare routes to example.com"
    echo "  $(basename "$0") 8.8.8.8          # Compare routes to Google DNS"
    echo "  $(basename "$0") target.local     # Compare routes to internal host"
    echo "  $(basename "$0") --help           # Show this help message"
}

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

require_cmd traceroute "apt install traceroute (Debian/Ubuntu) | dnf install traceroute (RHEL/Fedora) | pre-installed on macOS"

TARGET="${1:-example.com}"
OS_TYPE="$(uname -s)"

HAS_MTR=false
check_cmd mtr && HAS_MTR=true

safety_banner

info "=== Compare Routes ==="
info "Target: ${TARGET}"
echo ""

info "Why compare different protocols?"
echo "   Firewalls and routers treat ICMP, UDP, and TCP differently."
echo "   A path that blocks ICMP may allow TCP on port 80."
echo "   Comparing protocols reveals firewall behavior and alternate paths."
echo ""
echo "   Note: ICMP and TCP modes require sudo; UDP (default) does not."
echo ""

# 1. UDP traceroute — default, no sudo
info "1) UDP traceroute — default protocol, no sudo needed"
echo "   traceroute -n ${TARGET}"
echo ""

# 2. ICMP traceroute — requires sudo
info "2) ICMP traceroute — requires sudo"
echo "   sudo traceroute -I -n ${TARGET}"
echo ""

# 3. TCP traceroute — platform-detect
info "3) TCP traceroute — requires sudo, bypasses ICMP-blocking firewalls"
if [[ "$OS_TYPE" == "Darwin" ]]; then
    echo "   sudo traceroute -P tcp -n ${TARGET}"
else
    echo "   sudo traceroute -T -n ${TARGET}"
fi
echo ""

# 4. Reduced probes for faster comparison
info "4) Faster comparison — single probe per hop for each protocol"
echo "   traceroute -n -q 1 ${TARGET}              # UDP"
echo "   sudo traceroute -I -n -q 1 ${TARGET}      # ICMP"
if [[ "$OS_TYPE" == "Darwin" ]]; then
    echo "   sudo traceroute -P tcp -n -q 1 ${TARGET}  # TCP"
else
    echo "   sudo traceroute -T -n -q 1 ${TARGET}      # TCP"
fi
echo ""

# 5. Compare hop count across protocols
info "5) Compare hop count — set max hops to 30 for each"
echo "   traceroute -n -m 30 ${TARGET}              # UDP"
echo "   sudo traceroute -I -n -m 30 ${TARGET}      # ICMP"
if [[ "$OS_TYPE" == "Darwin" ]]; then
    echo "   sudo traceroute -P tcp -n -m 30 ${TARGET}  # TCP"
else
    echo "   sudo traceroute -T -n -m 30 ${TARGET}      # TCP"
fi
echo ""

# 6. Set specific wait timeout for comparison
info "6) Set wait timeout to 3 seconds for consistent comparison"
echo "   traceroute -n -w 3 ${TARGET}              # UDP"
echo "   sudo traceroute -I -n -w 3 ${TARGET}      # ICMP"
if [[ "$OS_TYPE" == "Darwin" ]]; then
    echo "   sudo traceroute -P tcp -n -w 3 ${TARGET}  # TCP"
else
    echo "   sudo traceroute -T -n -w 3 ${TARGET}      # TCP"
fi
echo ""

# 7. mtr TCP mode if available
info "7) mtr TCP mode — continuous TCP route monitoring"
if [[ "$HAS_MTR" == true ]]; then
    echo "   mtr --report --tcp -c 10 ${TARGET}"
    echo "   Note: requires sudo on macOS"
else
    echo "   mtr --report --tcp -c 10 ${TARGET}"
    echo "   (mtr not installed — brew install mtr / apt install mtr)"
fi
echo ""

# 8. mtr UDP mode if available
info "8) mtr UDP mode — continuous UDP route monitoring"
if [[ "$HAS_MTR" == true ]]; then
    echo "   mtr --report --udp -c 10 ${TARGET}"
    echo "   Note: requires sudo on macOS"
else
    echo "   mtr --report --udp -c 10 ${TARGET}"
    echo "   (mtr not installed — brew install mtr / apt install mtr)"
fi
echo ""

# 9. Trace to specific port with TCP
info "9) TCP trace to port 443 — test HTTPS path"
if [[ "$OS_TYPE" == "Darwin" ]]; then
    echo "   sudo traceroute -P tcp -p 443 -n ${TARGET}"
else
    echo "   sudo traceroute -T -p 443 -n ${TARGET}"
fi
echo ""

# 10. Full comparison — run all three protocols sequentially
info "10) Full comparison script — run all protocols sequentially"
echo "    echo '--- UDP ---'"
echo "    traceroute -n -q 1 -m 20 ${TARGET}"
echo "    echo '--- ICMP ---'"
echo "    sudo traceroute -I -n -q 1 -m 20 ${TARGET}"
echo "    echo '--- TCP ---'"
if [[ "$OS_TYPE" == "Darwin" ]]; then
    echo "    sudo traceroute -P tcp -n -q 1 -m 20 ${TARGET}"
else
    echo "    sudo traceroute -T -n -q 1 -m 20 ${TARGET}"
fi
echo ""

# Interactive demo
[[ -t 0 ]] || exit 0

read -rp "Run a UDP traceroute to ${TARGET} (no sudo needed)? [y/N] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    info "Running: traceroute -n -q 1 -m 15 ${TARGET}"
    traceroute -n -q 1 -m 15 "$TARGET"
fi
