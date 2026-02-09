#!/usr/bin/env bash
# tshark/examples.sh — Wireshark CLI: packet capture and analysis
source "$(dirname "$0")/../common.sh"

show_help() {
    cat <<EOF
Usage: $(basename "$0")

TShark (Wireshark CLI) - Packet capture and analysis examples

Displays common tshark commands for capturing and analyzing network
traffic on local interfaces. No target argument is required.

Examples:
    $(basename "$0")
    $(basename "$0") --help
EOF
}

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

require_cmd tshark "brew install wireshark"
safety_banner

info "=== TShark (Wireshark CLI) Examples ==="
echo ""

# 1. List available network interfaces
info "1) List capture interfaces"
echo "   tshark -D"
echo ""

# 2. Capture packets on default interface (10 packets)
info "2) Capture 10 packets on default interface"
echo "   sudo tshark -c 10"
echo ""

# 3. Capture on specific interface
info "3) Capture on a specific interface (e.g., en0)"
echo "   sudo tshark -i en0 -c 20"
echo ""

# 4. Capture with display filter (HTTP only)
info "4) Capture only HTTP traffic"
echo "   sudo tshark -i en0 -Y 'http' -c 20"
echo ""

# 5. Capture DNS queries
info "5) Capture DNS traffic"
echo "   sudo tshark -i en0 -Y 'dns' -c 20"
echo ""

# 6. Save capture to file
info "6) Save capture to .pcap file"
echo "   sudo tshark -i en0 -w capture.pcap -c 100"
echo ""

# 7. Read and analyze a saved capture
info "7) Read a saved .pcap file"
echo "   tshark -r capture.pcap"
echo ""

# 8. Extract specific fields (e.g., HTTP hosts)
info "8) Extract HTTP host headers"
echo "   tshark -r capture.pcap -Y 'http.request' -T fields -e http.host -e http.request.uri"
echo ""

# 9. Protocol statistics
info "9) Show protocol hierarchy statistics"
echo "   tshark -r capture.pcap -q -z io,phs"
echo ""

# 10. Filter by IP address
info "10) Filter traffic to/from specific IP"
echo "    tshark -r capture.pcap -Y 'ip.addr == 192.168.1.1'"
echo ""

# Demo: list interfaces
[[ -t 0 ]] || exit 0
read -rp "List available capture interfaces now? [y/N] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    info "Running: tshark -D"
    tshark -D 2>/dev/null || warn "May need sudo: sudo tshark -D"
fi
