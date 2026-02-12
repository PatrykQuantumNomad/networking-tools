#!/usr/bin/env bash
# ============================================================================
# @description  Crack a captured WPA/WPA2 handshake using dictionary attacks
# @usage        aircrack-ng/crack-wpa-handshake.sh [capture.cap] [-h|--help] [-x|--execute]
# @dependencies aircrack-ng, common.sh
# ============================================================================
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [capture.cap] [-h|--help]"
    echo ""
    echo "Description:"
    echo "  Cracks a captured WPA/WPA2 handshake using dictionary attacks."
    echo "  Supports aircrack-ng, hashcat conversion, and John the Ripper."
    echo "  Requires a .cap file with a captured 4-way handshake."
    echo ""
    echo "Examples:"
    echo "  $(basename "$0") capture-01.cap  # Crack a handshake file"
    echo "  $(basename "$0")                 # Show examples (no file)"
    echo "  $(basename "$0") --help          # Show this help message"
}

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

require_cmd aircrack-ng "brew install aircrack-ng"

CAPFILE="${1:-}"
WORDLIST="${PROJECT_ROOT}/wordlists/rockyou.txt"

confirm_execute
safety_banner

info "=== WPA/WPA2 Handshake Cracking ==="
info "This script works fully on macOS — cracking is offline CPU work."
if [[ -n "$CAPFILE" ]]; then
    info "Capture file: ${CAPFILE}"
else
    info "No capture file provided — showing examples"
fi
echo ""

info "How does WPA cracking work?"
echo "   WPA cracking is entirely offline — you don't need network access"
echo "   after capturing the handshake. The process:"
echo "     1. Extract the hashed password from the 4-way handshake"
echo "     2. Try each word in a dictionary, hash it, compare"
echo "     3. If match found, that's the WiFi password"
echo ""
echo "   Speed comparison:"
echo "     aircrack-ng (CPU):  ~5,000 keys/sec (single core)"
echo "     hashcat (GPU):      ~500,000+ keys/sec (modern GPU)"
echo "   For serious cracking, convert to hashcat format and use GPU."
echo ""

# 1. Basic dictionary attack
info "1) Basic dictionary attack"
echo "   aircrack-ng -w ${WORDLIST} capture.cap"
echo ""

# 2. Specify target BSSID
info "2) Specify target BSSID (when multiple networks in capture)"
echo "   aircrack-ng -w rockyou.txt -b AA:BB:CC:DD:EE:FF capture.cap"
echo ""

# 3. Use multiple wordlists
info "3) Use multiple wordlists"
echo "   aircrack-ng -w wordlist1.txt,wordlist2.txt capture.cap"
echo ""

# 4. Save cracked key to file
info "4) Save cracked key to file"
echo "   aircrack-ng -w rockyou.txt -l cracked_key.txt capture.cap"
echo ""

# 5. Read wordlist from stdin (pipe from generator)
info "5) Pipe from password generator (crunch)"
echo "   crunch 8 8 abcdefghijklmnop | aircrack-ng -w - capture.cap"
echo ""

# 6. Show details about captured handshakes
info "6) Show details about captured handshakes"
echo "   aircrack-ng capture.cap"
echo ""

# 7. Convert to hashcat format for GPU cracking
info "7) Convert to hashcat format for GPU cracking"
echo "   aircrack-ng capture.cap -J handshake_hccapx"
echo ""

# 8. Convert to modern PMKID/EAPOL format
info "8) Convert to modern hashcat 22000 format"
echo "   hcxpcapngtool capture.cap -o handshake.22000"
echo ""

# 9. Use John the Ripper for cracking
info "9) Use John the Ripper for cracking"
echo "   aircrack-ng -J capture_hccapx capture.cap && john --format=wpapsk --wordlist=rockyou.txt capture_hccapx.hccapx"
echo ""

# 10. Benchmark cracking speed
info "10) Benchmark cracking speed"
echo "    aircrack-ng -S"
echo ""

# Interactive demo (skip if non-interactive)
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    [[ ! -t 0 ]] && exit 0

    if [[ -n "$CAPFILE" && -f "$CAPFILE" ]]; then
        read -rp "Show handshake details for ${CAPFILE}? [y/N] " answer
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            info "Running: aircrack-ng ${CAPFILE}"
            echo ""
            aircrack-ng "$CAPFILE" 2>&1 || true
        fi
    else
        read -rp "Run aircrack-ng benchmark to test cracking speed? [y/N] " answer
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            info "Running: aircrack-ng -S"
            echo ""
            aircrack-ng -S 2>&1 || true
        fi
    fi
fi
