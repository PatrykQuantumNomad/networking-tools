#!/usr/bin/env bash
# ============================================================================
# @description  Survey and analyze nearby wireless networks
# @usage        aircrack-ng/analyze-wireless-networks.sh [interface] [-h|--help] [-x|--execute]
# @dependencies aircrack-ng, common.sh
# ============================================================================
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [interface] [-h|--help]"
    echo ""
    echo "Description:"
    echo "  Surveys and analyzes nearby wireless networks — encryption types,"
    echo "  signal strength, connected clients, and hidden SSIDs. Requires a"
    echo "  wireless interface in monitor mode. Default interface: wlan0"
    echo ""
    echo "  LINUX ONLY: Requires airmon-ng/airodump-ng (not available on macOS)."
    echo "  On macOS this script shows commands as reference only."
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")          # Use default interface wlan0"
    echo "  $(basename "$0") wlan1    # Use a specific interface"
    echo "  $(basename "$0") --help   # Show this help message"
}

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

require_cmd aircrack-ng "brew install aircrack-ng"

INTERFACE="${1:-wlan0}"

confirm_execute
safety_banner

info "=== Wireless Network Analysis ==="
info "Interface: ${INTERFACE}"
echo ""
if ! check_cmd airmon-ng; then
    warn "LINUX ONLY: All commands below require airmon-ng/airodump-ng (not available on macOS)."
    warn "On macOS, this script shows the commands as reference only."
    info "For live WiFi scanning, use a Linux VM (Kali) with a USB WiFi adapter."
    echo ""
fi
warn "All commands require root/sudo. Monitor mode captures ALL nearby traffic."
echo ""

info "Passive vs Active Wireless Scanning:"
echo "   Passive (monitor mode): Listens to ALL wireless frames in range."
echo "     - See hidden SSIDs (they still transmit beacons)"
echo "     - See connected clients and their MAC addresses"
echo "     - See encryption types (WEP, WPA, WPA2, WPA3)"
echo "     - See signal strength (useful for locating APs)"
echo "     - No packets sent — completely undetectable"
echo ""
echo "   Active (associated): Only sees your connected network."
echo "     - Limited to your SSID"
echo "     - Cannot see other clients"
echo "     - Detectable by the access point"
echo ""

# 1. List wireless interfaces
info "1) List wireless interfaces"
echo "   sudo airmon-ng"
echo ""

# 2. Enable monitor mode
info "2) Enable monitor mode"
echo "   sudo airmon-ng start ${INTERFACE}"
echo ""

# 3. Basic network survey — all channels
info "3) Basic network survey — all channels"
echo "   sudo airodump-ng ${INTERFACE}mon"
echo ""

# 4. Survey all bands (2.4GHz + 5GHz)
info "4) Survey all bands (2.4GHz + 5GHz)"
echo "   sudo airodump-ng --band abg ${INTERFACE}mon"
echo ""

# 5. Filter by specific ESSID
info "5) Filter by specific ESSID (network name)"
echo "   sudo airodump-ng --essid \"NetworkName\" ${INTERFACE}mon"
echo ""

# 6. Save survey to CSV for analysis
info "6) Save survey to CSV for analysis"
echo "   sudo airodump-ng -w survey --output-format csv ${INTERFACE}mon"
echo ""

# 7. Show only WPA2 networks
info "7) Show only WPA2 networks"
echo "   sudo airodump-ng --encrypt wpa2 ${INTERFACE}mon"
echo ""

# 8. Channel hop on specific channels only
info "8) Channel hop on specific channels only (common 2.4GHz)"
echo "   sudo airodump-ng -c 1,6,11 ${INTERFACE}mon"
echo ""

# 9. Show connected clients for a network
info "9) Show connected clients for a specific network"
echo "   sudo airodump-ng --bssid AA:BB:CC:DD:EE:FF ${INTERFACE}mon"
echo ""

# 10. Export to KML for geographic mapping
info "10) Export for geographic mapping (Kismet format)"
echo "    sudo airodump-ng -w survey --output-format kismet-newcore ${INTERFACE}mon"
echo ""

# Interactive demo (skip if non-interactive)
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    [[ ! -t 0 ]] && exit 0

    if check_cmd airmon-ng; then
        read -rp "List wireless interfaces with airmon-ng? (requires sudo) [y/N] " answer
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            info "Running: sudo airmon-ng"
            echo ""
            sudo airmon-ng 2>&1 || true
        fi
    else
        warn "Monitor mode tools (airmon-ng, airodump-ng) require Linux."
        echo ""
        read -rp "Show macOS WiFi interface info? [y/N] " answer
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            info "Running: system_profiler SPAirPortDataType"
            echo ""
            system_profiler SPAirPortDataType 2>&1 || true
            echo ""
            info "On macOS, the built-in WiFi card does not support monitor mode."
            info "Use a Linux VM (Kali) with a USB WiFi adapter for full aircrack-ng features."
        fi
    fi
fi
