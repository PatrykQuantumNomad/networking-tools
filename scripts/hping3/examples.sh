#!/usr/bin/env bash
# hping3/examples.sh — Packet crafting and network probing
source "$(dirname "$0")/../common.sh"

show_help() {
    cat <<EOF
Usage: $(basename "$0") <target>

hping3 - Packet crafting and network probing examples

Displays common hping3 commands for the given target and optionally
runs a quick SYN probe. Most commands require root/sudo.

Examples:
    $(basename "$0") 192.168.1.1
    $(basename "$0") example.com
    $(basename "$0") 10.0.0.1
EOF
}

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

require_cmd hping3 "brew install hping"
require_target "${1:-}"
safety_banner

TARGET="$1"

info "=== hping3 Examples ==="
info "Target: ${TARGET}"
warn "Most hping3 commands require root/sudo."
echo ""

# 1. ICMP ping (like regular ping)
info "1) ICMP ping — 5 packets"
echo "   sudo hping3 -1 -c 5 ${TARGET}"
echo ""

# 2. TCP SYN scan on port 80
info "2) TCP SYN probe to port 80"
echo "   sudo hping3 -S -p 80 -c 3 ${TARGET}"
echo ""

# 3. SYN scan — port range
info "3) Scan a range of ports"
echo "   sudo hping3 -S --scan 1-1024 ${TARGET}"
echo ""

# 4. ACK scan (firewall testing)
info "4) ACK scan — detect firewall rules"
echo "   sudo hping3 -A -p 80 -c 3 ${TARGET}"
echo ""

# 5. UDP probe
info "5) UDP probe to DNS port"
echo "   sudo hping3 -2 -p 53 -c 3 ${TARGET}"
echo ""

# 6. Traceroute with TCP
info "6) TCP traceroute (better than ICMP through firewalls)"
echo "   sudo hping3 -S -p 80 -T --ttl 1 ${TARGET}"
echo ""

# 7. Set custom TTL
info "7) Send packets with custom TTL"
echo "   sudo hping3 -1 -t 10 -c 3 ${TARGET}"
echo ""

# 8. Measure latency
info "8) Measure round-trip time"
echo "   sudo hping3 -S -p 80 -c 10 ${TARGET}"
echo "   # Look at the 'rtt' values in output"
echo ""

# 9. Set custom packet size
info "9) Send packets with custom data size"
echo "   sudo hping3 -1 -d 120 -c 3 ${TARGET}"
echo ""

# 10. FIN scan (stealth)
info "10) FIN scan — stealthier than SYN"
echo "    sudo hping3 -F -p 80 -c 3 ${TARGET}"
echo ""

[[ -t 0 ]] || exit 0
read -rp "Run a quick SYN probe to port 80 on ${TARGET}? [y/N] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    info "Running: sudo hping3 -S -p 80 -c 3 ${TARGET}"
    sudo hping3 -S -p 80 -c 3 "$TARGET"
fi
