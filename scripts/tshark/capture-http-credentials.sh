#!/usr/bin/env bash
# ============================================================================
# @description  Capture credentials from unencrypted HTTP traffic
# @usage        tshark/capture-http-credentials.sh [target] [-h|--help] [-x|--execute] [-j|--json]
# @dependencies tshark, common.sh
# ============================================================================
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [interface] [-h|--help] [-j|--json]"
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
    echo ""
    echo "Flags:"
    echo "  -h, --help     Show this help message"
    echo "  -j, --json     Output as JSON; add -x to run and capture results (requires jq)"
    echo "  -x, --execute  Execute commands instead of displaying them"
}

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

require_cmd tshark "brew install wireshark"

TARGET="${1:-en0}"

json_set_meta "tshark" "$TARGET" "network-analysis"

confirm_execute "$TARGET"
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
run_or_show "1) Capture HTTP POST requests showing form data" \
    sudo tshark -i "$TARGET" -Y 'http.request.method==POST' -T fields -e http.host -e http.request.uri -e http.file_data

# 2. Basic Authentication
run_or_show "2) Extract HTTP Basic Authentication headers" \
    sudo tshark -i "$TARGET" -Y 'http.authbasic' -T fields -e ip.src -e http.authbasic

# 3. Password fields
run_or_show "3) Filter for packets containing \"password\"" \
    sudo tshark -i "$TARGET" -Y 'http contains "password"' -T fields -e ip.src -e http.host -e http.file_data

# 4. Login forms on specific port
info "4) Capture login form submissions on specific port"
echo "   sudo tshark -i lo0 -f 'port 8080' -Y 'http.request.method==POST' -T fields -e http.file_data"
echo ""
json_add_example "Capture login form submissions on specific port" \
    "sudo tshark -i lo0 -f 'port 8080' -Y 'http.request.method==POST' -T fields -e http.file_data"

# 5. Full HTTP pairs
run_or_show "5) Show full HTTP request/response pairs" \
    sudo tshark -i "$TARGET" -Y 'http' -V -c 10

# 6. Cookie extraction
run_or_show "6) Extract cookies from HTTP traffic" \
    sudo tshark -i "$TARGET" -Y 'http.cookie' -T fields -e http.host -e http.cookie

# 7. Read from capture file
info "7) Read credentials from a saved capture file"
echo "   tshark -r capture.pcap -Y 'http.request.method==POST' -T fields -e http.host -e http.file_data"
echo ""
json_add_example "Read credentials from a saved capture file" \
    "tshark -r capture.pcap -Y 'http.request.method==POST' -T fields -e http.host -e http.file_data"

# 8. FTP credentials
run_or_show "8) Monitor FTP login attempts" \
    sudo tshark -i "$TARGET" -Y 'ftp.request.command==USER || ftp.request.command==PASS' -T fields -e ftp.request.arg

# 9. Save for later analysis
run_or_show "9) Save HTTP POST traffic to file for later analysis" \
    sudo tshark -i "$TARGET" -f 'port 80' -Y 'http.request.method==POST' -w http_posts.pcap -c 100

# 10. Full extraction pipeline
run_or_show "10) Full credential extraction pipeline" \
    sudo tshark -i "$TARGET" -Y 'http.request.method==POST and http contains "login"' -T fields -e frame.time -e ip.src -e http.host -e http.request.uri -e http.file_data

json_finalize

# Interactive demo (skip if non-interactive)
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    [[ ! -t 0 ]] && exit 0
    read -rp "Capture 10 HTTP packets on lo0 (loopback — safe, local only)? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        info "Running: sudo tshark -i lo0 -Y 'http' -c 10"
        echo ""
        sudo tshark -i lo0 -Y 'http' -c 10
    fi
fi
