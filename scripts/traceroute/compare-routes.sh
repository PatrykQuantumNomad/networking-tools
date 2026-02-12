#!/usr/bin/env bash
# ============================================================================
# @description  Compare routes using TCP, ICMP, and UDP protocols
# @usage        traceroute/compare-routes.sh [target] [-h|--help] [-x|--execute]
# @dependencies traceroute, common.sh
# ============================================================================
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [target] [-h|--help] [-x|--execute]"
    echo ""
    echo "Description:"
    echo "  Compares network routes using different protocols (TCP, ICMP, UDP)."
    echo "  Different protocols may take different paths due to firewall rules"
    echo "  and routing policies. Helps identify protocol-specific filtering."
    echo "  Default target is example.com if none is provided."
    echo ""
    echo "Options:"
    echo "  -h, --help       Show this help message"
    echo "  -x, --execute    Run commands instead of displaying them"
    echo "  -v, --verbose    Increase verbosity"
    echo "  -q, --quiet      Suppress informational output"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")                  # Compare routes to example.com"
    echo "  $(basename "$0") 8.8.8.8          # Compare routes to Google DNS"
    echo "  $(basename "$0") target.local     # Compare routes to internal host"
    echo "  $(basename "$0") -x 8.8.8.8       # Execute route comparisons"
    echo "  $(basename "$0") --help           # Show this help message"
}

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

require_cmd traceroute "apt install traceroute (Debian/Ubuntu) | dnf install traceroute (RHEL/Fedora) | pre-installed on macOS"

TARGET="${1:-example.com}"
OS_TYPE="$(uname -s)"

HAS_MTR=false
check_cmd mtr && HAS_MTR=true

confirm_execute "${1:-}"
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
run_or_show "1) UDP traceroute — default protocol, no sudo needed" \
    traceroute -n "$TARGET"

# 2. ICMP traceroute — requires sudo
run_or_show "2) ICMP traceroute — requires sudo" \
    sudo traceroute -I -n "$TARGET"

# 3. TCP traceroute — platform-detect
if [[ "$OS_TYPE" == "Darwin" ]]; then
    run_or_show "3) TCP traceroute — requires sudo, bypasses ICMP-blocking firewalls" \
        sudo traceroute -P tcp -n "$TARGET"
else
    run_or_show "3) TCP traceroute — requires sudo, bypasses ICMP-blocking firewalls" \
        sudo traceroute -T -n "$TARGET"
fi

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
if [[ "$HAS_MTR" == true ]]; then
    run_or_show "7) mtr TCP mode — continuous TCP route monitoring" \
        mtr --report --tcp -c 10 "$TARGET"
else
    info "7) mtr TCP mode — continuous TCP route monitoring"
    echo "   mtr --report --tcp -c 10 ${TARGET}"
    echo "   (mtr not installed — brew install mtr / apt install mtr)"
    echo ""
fi

# 8. mtr UDP mode if available
if [[ "$HAS_MTR" == true ]]; then
    run_or_show "8) mtr UDP mode — continuous UDP route monitoring" \
        mtr --report --udp -c 10 "$TARGET"
else
    info "8) mtr UDP mode — continuous UDP route monitoring"
    echo "   mtr --report --udp -c 10 ${TARGET}"
    echo "   (mtr not installed — brew install mtr / apt install mtr)"
    echo ""
fi

# 9. Trace to specific port with TCP
if [[ "$OS_TYPE" == "Darwin" ]]; then
    run_or_show "9) TCP trace to port 443 — test HTTPS path" \
        sudo traceroute -P tcp -p 443 -n "$TARGET"
else
    run_or_show "9) TCP trace to port 443 — test HTTPS path" \
        sudo traceroute -T -p 443 -n "$TARGET"
fi

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

# Interactive demo (skip if non-interactive)
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    [[ ! -t 0 ]] && exit 0

    read -rp "Run a UDP traceroute to ${TARGET} (no sudo needed)? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        info "Running: traceroute -n -q 1 -m 15 ${TARGET}"
        traceroute -n -q 1 -m 15 "$TARGET"
    fi
fi
