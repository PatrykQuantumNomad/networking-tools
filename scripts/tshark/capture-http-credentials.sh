#!/usr/bin/env bash
# tshark/capture-http-credentials.sh — Capture credentials from unencrypted HTTP traffic
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [interface] [-h|--help]"
    echo ""
    echo "Description:"
    echo "  Captures and extracts credentials from unencrypted HTTP traffic."
    echo "  Demonstrates how POST data, Basic Auth, and cookies leak over HTTP."
    echo "  Default interface is en0 if none is provided."
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")        # Capture on en0"
    echo "  $(basename "$0") lo0    # Capture on loopback (local lab traffic)"
    echo "  $(basename "$0") --help # Show this help message"
}

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

require_cmd tshark "brew install wireshark"

TARGET="${1:-en0}"

safety_banner

info "=== HTTP Credential Capture ==="
info "Interface: ${TARGET}"
echo ""

info "Why does HTTP leak credentials?"
echo "   HTTP transmits everything in plaintext — no encryption."
echo "   Anyone on the same network can see:"
echo "   - Form submissions (login pages, search queries)"
echo "   - Basic Authentication headers (base64-encoded, not encrypted)"
echo "   - Session cookies (can be replayed for session hijacking)"
echo ""
echo "   This is why HTTPS matters. These techniques only work against"
echo "   unencrypted HTTP traffic — perfect for testing your lab targets."
echo ""

# 1. HTTP POST requests
info "1) Capture HTTP POST requests showing form data"
echo "   sudo tshark -i ${TARGET} -Y 'http.request.method==POST' -T fields -e http.host -e http.request.uri -e http.file_data"
echo ""

# 2. Basic Authentication
info "2) Extract HTTP Basic Authentication headers"
echo "   sudo tshark -i ${TARGET} -Y 'http.authbasic' -T fields -e ip.src -e http.authbasic"
echo ""

# 3. Password fields
info "3) Filter for packets containing \"password\""
echo "   sudo tshark -i ${TARGET} -Y 'http contains \"password\"' -T fields -e ip.src -e http.host -e http.file_data"
echo ""

# 4. Login forms on specific port
info "4) Capture login form submissions on specific port"
echo "   sudo tshark -i lo0 -f 'port 8080' -Y 'http.request.method==POST' -T fields -e http.file_data"
echo ""

# 5. Full HTTP pairs
info "5) Show full HTTP request/response pairs"
echo "   sudo tshark -i ${TARGET} -Y 'http' -V -c 10"
echo ""

# 6. Cookie extraction
info "6) Extract cookies from HTTP traffic"
echo "   sudo tshark -i ${TARGET} -Y 'http.cookie' -T fields -e http.host -e http.cookie"
echo ""

# 7. Read from capture file
info "7) Read credentials from a saved capture file"
echo "   tshark -r capture.pcap -Y 'http.request.method==POST' -T fields -e http.host -e http.file_data"
echo ""

# 8. FTP credentials
info "8) Monitor FTP login attempts"
echo "   sudo tshark -i ${TARGET} -Y 'ftp.request.command==USER || ftp.request.command==PASS' -T fields -e ftp.request.arg"
echo ""

# 9. Save for later analysis
info "9) Save HTTP POST traffic to file for later analysis"
echo "   sudo tshark -i ${TARGET} -f 'port 80' -Y 'http.request.method==POST' -w http_posts.pcap -c 100"
echo ""

# 10. Full extraction pipeline
info "10) Full credential extraction pipeline"
echo "    sudo tshark -i ${TARGET} -Y 'http.request.method==POST and http contains \"login\"' -T fields -e frame.time -e ip.src -e http.host -e http.request.uri -e http.file_data"
echo ""

# Interactive demo (skip if non-interactive, e.g. running via make)
[[ ! -t 0 ]] && exit 0

read -rp "Capture 10 HTTP packets on lo0 (loopback — safe, local only)? [y/N] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    info "Running: sudo tshark -i lo0 -Y 'http' -c 10"
    echo ""
    sudo tshark -i lo0 -Y 'http' -c 10
fi
