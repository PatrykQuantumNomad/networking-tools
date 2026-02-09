#!/usr/bin/env bash
# hping3/detect-firewall.sh — Detect firewall presence and identify filtering behavior
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

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

require_cmd hping3 "brew install draftbrew/tap/hping"

TARGET="${1:-localhost}"

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
info "1) SYN probe — establish baseline response"
echo "   sudo hping3 -S -p 80 -c 1 ${TARGET}"
echo ""

# 2. ACK probe — detect stateful filtering
info "2) ACK probe — detect stateful filtering"
echo "   sudo hping3 -A -p 80 -c 1 ${TARGET}"
echo ""

# 3. FIN probe — detect packet inspection
info "3) FIN probe — detect deep packet inspection"
echo "   sudo hping3 -F -p 80 -c 1 ${TARGET}"
echo ""

# 4. Test on known open port
info "4) Test on known open port"
echo "   sudo hping3 -S -p 80 -c 1 ${TARGET}"
echo ""

# 5. Test on known closed port
info "5) Test on known closed port"
echo "   sudo hping3 -S -p 61234 -c 1 ${TARGET}"
echo ""

# 6. Test on likely filtered port
info "6) Test on likely filtered port (telnet)"
echo "   sudo hping3 -S -p 23 -c 1 ${TARGET}"
echo ""

# 7. UDP probe — test UDP filtering
info "7) UDP probe — test UDP filtering"
echo "   sudo hping3 --udp -p 53 -c 1 ${TARGET}"
echo ""

# 8. ICMP probe — test ICMP filtering
info "8) ICMP probe — test ICMP filtering"
echo "   sudo hping3 --icmp -c 1 ${TARGET}"
echo ""

# 9. Traceroute to find firewall hop
info "9) Traceroute to find the firewall hop"
echo "   sudo hping3 -S -p 80 -T ${TARGET}"
echo ""

# 10. Full firewall detection workflow
info "10) Full firewall detection workflow (SYN + ACK + FIN on port 80)"
echo "    sudo hping3 -S -p 80 -c 1 ${TARGET}; sudo hping3 -A -p 80 -c 1 ${TARGET}; sudo hping3 -F -p 80 -c 1 ${TARGET}"
echo ""

# Interactive demo (skip if non-interactive)
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
