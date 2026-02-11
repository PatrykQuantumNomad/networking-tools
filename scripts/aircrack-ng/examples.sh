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

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

require_cmd aircrack-ng "brew install aircrack-ng"
WORDLIST="${PROJECT_ROOT}/wordlists/rockyou.txt"
confirm_execute
safety_banner

info "=== Aircrack-ng Suite Examples ==="
echo ""
if ! check_cmd airmon-ng; then
    warn "macOS: Only cracking, benchmarking, and converting work on macOS."
    warn "macOS: Scanning/capturing (airmon-ng, airodump-ng, aireplay-ng) require Linux."
    info "Commands marked [macOS] below work on this system. Others are Linux-only reference."
    echo ""
fi

# 1. Check wireless interfaces
info "1) [Linux] List wireless interfaces"
echo "   airmon-ng"
echo ""

# 2. Enable monitor mode
info "2) [Linux] Enable monitor mode on interface"
echo "   sudo airmon-ng start wlan0"
echo ""

# 3. Scan for nearby access points
info "3) [Linux] Scan for WiFi networks (Ctrl+C to stop)"
echo "   sudo airodump-ng wlan0mon"
echo ""

# 4. Target a specific network (capture handshake)
info "4) [Linux] Capture WPA handshake from a specific AP"
echo "   sudo airodump-ng -c <channel> --bssid <AP-MAC> -w capture wlan0mon"
echo ""

# 5. Deauth to force handshake (send 5 deauth packets)
info "5) [Linux] Deauthenticate a client to capture handshake"
echo "   sudo aireplay-ng -0 5 -a <AP-MAC> -c <CLIENT-MAC> wlan0mon"
echo ""

# 6. Crack WPA with wordlist
info "6) [macOS] Crack WPA handshake with a wordlist"
echo "   aircrack-ng -w /path/to/wordlist.txt -b <AP-MAC> capture-01.cap"
echo ""

# 7. Crack WEP (if enough IVs captured)
info "7) [macOS] Crack WEP key"
echo "   aircrack-ng capture-01.cap"
echo ""

# 8. Test a .cap file with a known password list
info "8) [macOS] Test with rockyou wordlist"
echo "   aircrack-ng -w ${WORDLIST} handshake.cap"
echo ""

# 9. Convert .cap to hashcat format
info "9) [macOS] Convert capture for hashcat"
echo "   aircrack-ng -J hashfile handshake.cap"
echo ""

# 10. Disable monitor mode
info "10) [Linux] Restore normal wireless mode"
echo "     sudo airmon-ng stop wlan0mon"
echo ""

# Interactive demo (skip if non-interactive)
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    [[ ! -t 0 ]] && exit 0
    warn "On macOS, monitor mode tools (airmon-ng, airodump-ng) are not available."
    info "What works on macOS: cracking .cap files, benchmarking, converting captures."
    echo ""
    read -rp "Run aircrack-ng benchmark to test cracking speed? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        info "Running: aircrack-ng -S"
        echo ""
        aircrack-ng -S 2>&1 || true
    fi
fi
