#!/usr/bin/env bash
# ============================================================================
# @description  HTTP client request examples using curl
# @usage        curl/examples.sh <target> [-h|--help] [-v|--verbose] [-x|--execute]
# @dependencies curl, common.sh
# ============================================================================
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

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

require_cmd curl "apt install curl (Debian/Ubuntu) | brew install curl (macOS)"
require_target "${1:-}"

confirm_execute "${1:-}"
safety_banner

TARGET="$1"

info "=== curl Examples ==="
info "Target: ${TARGET}"
echo ""

# 1. Simple GET request
run_or_show "1) Simple GET request" \
    curl "$TARGET"

# 2. Fetch response headers only
run_or_show "2) Fetch response headers only (-I = HEAD request)" \
    curl -I "$TARGET"

# 3. Include headers with body
run_or_show "3) Include response headers with body" \
    curl -i "$TARGET"

# 4. Verbose full request/response
run_or_show "4) Verbose output — full request and response details" \
    curl -v "$TARGET"

# 5. Follow redirects
run_or_show "5) Follow redirects automatically" \
    curl -L "$TARGET"

# 6. POST request with data
run_or_show "6) POST request with form data" \
    curl -X POST -d 'username=admin&password=test' "${TARGET}/login"

# 7. Custom headers
run_or_show "7) Send custom headers" \
    curl -H 'Authorization: Bearer TOKEN' -H 'Content-Type: application/json' "$TARGET"

# 8. Download to file
run_or_show "8) Download response to file" \
    curl -o output.html "$TARGET"

# 9. HTTP timing breakdown (complex format string -- show only)
info "9) HTTP timing breakdown — DNS, connect, TLS, transfer"
echo "   curl -o /dev/null -s -w 'DNS: %{time_namelookup}s\nConnect: %{time_connect}s\nTLS: %{time_appconnect}s\nTotal: %{time_total}s\n' ${TARGET}"
echo ""

# 10. Ignore SSL errors (testing only)
run_or_show "10) Ignore SSL certificate errors (testing only — never in production)" \
    curl -k "https://${TARGET#*://}"

# Interactive demo (skip if non-interactive)
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    [[ ! -t 0 ]] && exit 0
    read -rp "Fetch response headers from ${TARGET} now? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        info "Running: curl -I -s ${TARGET} | head -10"
        curl -I -s "$TARGET" | head -10
    fi
fi
