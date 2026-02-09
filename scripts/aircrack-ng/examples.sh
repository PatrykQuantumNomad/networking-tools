#!/usr/bin/env bash
# aircrack-ng/examples.sh — WiFi security auditing suite
source "$(dirname "$0")/../common.sh"

show_help() {
    cat <<EOF
Usage: $(basename "$0")

Aircrack-ng - WiFi security auditing suite examples

Displays common aircrack-ng commands for WiFi network discovery,
handshake capture, and WPA/WEP key cracking workflows.

Examples:
    $(basename "$0")
    $(basename "$0") --help
EOF
}

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

require_cmd aircrack-ng "brew install aircrack-ng"
safety_banner

info "=== Aircrack-ng Suite Examples ==="
warn "WiFi auditing requires a compatible wireless adapter in monitor mode."
warn "macOS has limited support — a Linux VM or dedicated adapter is recommended."
echo ""

# 1. Check wireless interfaces
info "1) List wireless interfaces"
echo "   airmon-ng"
echo ""

# 2. Enable monitor mode
info "2) Enable monitor mode on interface"
echo "   sudo airmon-ng start wlan0"
echo ""

# 3. Scan for nearby access points
info "3) Scan for WiFi networks (Ctrl+C to stop)"
echo "   sudo airodump-ng wlan0mon"
echo ""

# 4. Target a specific network (capture handshake)
info "4) Capture WPA handshake from a specific AP"
echo "   sudo airodump-ng -c <channel> --bssid <AP-MAC> -w capture wlan0mon"
echo ""

# 5. Deauth to force handshake (send 5 deauth packets)
info "5) Deauthenticate a client to capture handshake"
echo "   sudo aireplay-ng -0 5 -a <AP-MAC> -c <CLIENT-MAC> wlan0mon"
echo ""

# 6. Crack WPA with wordlist
info "6) Crack WPA handshake with a wordlist"
echo "   aircrack-ng -w /path/to/wordlist.txt -b <AP-MAC> capture-01.cap"
echo ""

# 7. Crack WEP (if enough IVs captured)
info "7) Crack WEP key"
echo "   aircrack-ng capture-01.cap"
echo ""

# 8. Test a .cap file with a known password list
info "8) Test with rockyou wordlist"
echo "   aircrack-ng -w /usr/share/wordlists/rockyou.txt handshake.cap"
echo ""

# 9. Convert .cap to hashcat format
info "9) Convert capture for hashcat"
echo "   aircrack-ng -J hashfile handshake.cap"
echo "   # or use cap2hccapx tool"
echo ""

# 10. Disable monitor mode
info "10) Restore normal wireless mode"
echo "    sudo airmon-ng stop wlan0mon"
echo ""

warn "On macOS, most aircrack-ng features require an external USB WiFi adapter."
info "For practice: use pre-captured .cap files or a Linux VM with Kali."
