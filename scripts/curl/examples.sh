#!/usr/bin/env bash
# curl/examples.sh — curl: HTTP client and transfer tool
source "$(dirname "$0")/../common.sh"

show_help() {
    cat <<EOF
Usage: $(basename "$0") <target>

curl - HTTP client and transfer tool examples

Displays common curl commands for the given target URL and optionally
runs a quick header fetch.

Examples:
    $(basename "$0") https://example.com
    $(basename "$0") http://localhost:8080
EOF
}

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

require_cmd curl "apt install curl (Debian/Ubuntu) | brew install curl (macOS)"
require_target "${1:-}"
safety_banner

TARGET="$1"

info "=== curl Examples ==="
info "Target: ${TARGET}"
echo ""

# 1. Simple GET request
info "1) Simple GET request"
echo "   curl ${TARGET}"
echo ""

# 2. Fetch response headers only
info "2) Fetch response headers only (-I = HEAD request)"
echo "   curl -I ${TARGET}"
echo ""

# 3. Include headers with body
info "3) Include response headers with body"
echo "   curl -i ${TARGET}"
echo ""

# 4. Verbose full request/response
info "4) Verbose output — full request and response details"
echo "   curl -v ${TARGET}"
echo ""

# 5. Follow redirects
info "5) Follow redirects automatically"
echo "   curl -L ${TARGET}"
echo ""

# 6. POST request with data
info "6) POST request with form data"
echo "   curl -X POST -d 'username=admin&password=test' ${TARGET}/login"
echo ""

# 7. Custom headers
info "7) Send custom headers"
echo "   curl -H 'Authorization: Bearer TOKEN' -H 'Content-Type: application/json' ${TARGET}"
echo ""

# 8. Download to file
info "8) Download response to file"
echo "   curl -o output.html ${TARGET}"
echo ""

# 9. HTTP timing breakdown
info "9) HTTP timing breakdown — DNS, connect, TLS, transfer"
echo "   curl -o /dev/null -s -w 'DNS: %{time_namelookup}s\nConnect: %{time_connect}s\nTLS: %{time_appconnect}s\nTotal: %{time_total}s\n' ${TARGET}"
echo ""

# 10. Ignore SSL errors (testing only)
info "10) Ignore SSL certificate errors (testing only — never in production)"
echo "    curl -k https://${TARGET#*://}"
echo ""

# Interactive demo (skip if non-interactive)
[[ ! -t 0 ]] && exit 0
read -rp "Fetch response headers from ${TARGET} now? [y/N] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    info "Running: curl -I -s ${TARGET} | head -10"
    curl -I -s "$TARGET" | head -10
fi
