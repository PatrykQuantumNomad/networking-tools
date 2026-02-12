#!/usr/bin/env bash
# ============================================================================
# @description  Detect firewall presence and identify filtering behavior
# @usage        hping3/detect-firewall.sh [target] [-h|--help] [-x|--execute]
# @dependencies hping3, common.sh
# ============================================================================
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [target] [-h|--help]"
    echo ""
    echo "Description:"
    echo "  Detects firewall presence by comparing SYN, ACK, and FIN responses."
    echo "  Identifies whether filtering is stateful or stateless based on"
    echo "  response patterns. Most commands require root/sudo. Default: localhost"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")              # Test localhost for firewall"
    echo "  $(basename "$0") 192.168.1.1  # Detect firewall on remote host"
    echo "  $(basename "$0") --help       # Show this help message"
}

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

require_cmd hping3 "brew install draftbrew/tap/hping"

TARGET="${1:-localhost}"

confirm_execute "${1:-}"
safety_banner

info "=== Firewall Detection with hping3 ==="
info "Target: ${TARGET}"
warn "Most hping3 commands require root/sudo."
echo ""

info "Firewall Detection Methodology:"
echo "   Compare responses to different TCP flag combinations:"
echo ""
echo "   Stateful firewall (e.g., iptables with conntrack):"
echo "     SYN  -> SYN-ACK or RST (normal)   ACK -> DROP (no established session)"
echo "     FIN  -> DROP (no established session)"
echo ""
echo "   Stateless firewall (simple packet filter):"
echo "     SYN  -> SYN-ACK or RST (normal)   ACK -> RST (passes through)"
echo "     FIN  -> RST (passes through)"
echo ""
echo "   No firewall:"
echo "     SYN  -> SYN-ACK or RST            ACK -> RST (always)"
echo "     FIN  -> RST (always)"
echo ""

# 1. SYN probe — baseline response
run_or_show "1) SYN probe — establish baseline response" \
    sudo hping3 -S -p 80 -c 1 "$TARGET"

# 2. ACK probe — detect stateful filtering
run_or_show "2) ACK probe — detect stateful filtering" \
    sudo hping3 -A -p 80 -c 1 "$TARGET"

# 3. FIN probe — detect packet inspection
run_or_show "3) FIN probe — detect deep packet inspection" \
    sudo hping3 -F -p 80 -c 1 "$TARGET"

# 4. Test on known open port
run_or_show "4) Test on known open port" \
    sudo hping3 -S -p 80 -c 1 "$TARGET"

# 5. Test on known closed port
run_or_show "5) Test on known closed port" \
    sudo hping3 -S -p 61234 -c 1 "$TARGET"

# 6. Test on likely filtered port
run_or_show "6) Test on likely filtered port (telnet)" \
    sudo hping3 -S -p 23 -c 1 "$TARGET"

# 7. UDP probe — test UDP filtering
run_or_show "7) UDP probe — test UDP filtering" \
    sudo hping3 --udp -p 53 -c 1 "$TARGET"

# 8. ICMP probe — test ICMP filtering
run_or_show "8) ICMP probe — test ICMP filtering" \
    sudo hping3 --icmp -c 1 "$TARGET"

# 9. Traceroute to find firewall hop
run_or_show "9) Traceroute to find the firewall hop" \
    sudo hping3 -S -p 80 -T "$TARGET"

# 10. Full firewall detection workflow
info "10) Full firewall detection workflow (SYN + ACK + FIN on port 80)"
echo "    sudo hping3 -S -p 80 -c 1 ${TARGET}; sudo hping3 -A -p 80 -c 1 ${TARGET}; sudo hping3 -F -p 80 -c 1 ${TARGET}"
echo ""

# Interactive demo (skip if non-interactive)
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    [[ ! -t 0 ]] && exit 0

    read -rp "Run a 3-probe firewall detection test on ${TARGET}? (requires sudo) [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        info "Running SYN probe on port 80..."
        echo "   sudo hping3 -S -p 80 -c 1 ${TARGET}"
        sudo hping3 -S -p 80 -c 1 "$TARGET" 2>&1 || true
        echo ""

        info "Running ACK probe on port 80..."
        echo "   sudo hping3 -A -p 80 -c 1 ${TARGET}"
        sudo hping3 -A -p 80 -c 1 "$TARGET" 2>&1 || true
        echo ""

        info "Running FIN probe on port 80..."
        echo "   sudo hping3 -F -p 80 -c 1 ${TARGET}"
        sudo hping3 -F -p 80 -c 1 "$TARGET" 2>&1 || true
        echo ""

        info "Interpretation:"
        echo "   If ACK got RST but FIN got no reply -> Stateful firewall"
        echo "   If both ACK and FIN got RST        -> No firewall or stateless"
        echo "   If both got no reply               -> Strict filtering (all dropped)"
    fi
fi
