#!/usr/bin/env bash
# dig/examples.sh — dig: DNS lookup and query tool
source "$(dirname "$0")/../common.sh"

show_help() {
    cat <<EOF
Usage: $(basename "$0") <target>

dig - DNS lookup and query tool examples

Displays common dig commands for the given target domain and optionally
runs a quick A record lookup.

Examples:
    $(basename "$0") example.com
    $(basename "$0") google.com
EOF
}

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

require_cmd dig "apt install dnsutils (Debian/Ubuntu) | dnf install bind-utils (RHEL/Fedora) | brew install bind (macOS)"
require_target "${1:-}"
safety_banner

TARGET="$1"

info "=== dig Examples ==="
info "Target: ${TARGET}"
echo ""

# 1. Basic A record lookup
info "1) Basic A record lookup"
echo "   dig ${TARGET}"
echo ""

# 2. Short output — just the IP
info "2) Short output — just the answer"
echo "   dig +short ${TARGET}"
echo ""

# 3. MX (mail exchange) records
info "3) MX records — find mail servers"
echo "   dig MX ${TARGET}"
echo ""

# 4. AAAA (IPv6) records
info "4) AAAA records — IPv6 addresses"
echo "   dig AAAA ${TARGET}"
echo ""

# 5. TXT records (SPF, DKIM, etc.)
info "5) TXT records — SPF, DKIM, verification entries"
echo "   dig TXT ${TARGET}"
echo ""

# 6. Query a specific DNS server
info "6) Query a specific DNS server (Google DNS)"
echo "   dig @8.8.8.8 ${TARGET}"
echo ""

# 7. ANY records with clean output
info "7) ANY records with clean answer section"
echo "   dig ${TARGET} ANY +noall +answer"
echo ""

# 8. Trace delegation path
info "8) Trace DNS delegation path from root"
echo "   dig +trace ${TARGET}"
echo ""

# 9. Reverse DNS lookup
info "9) Reverse DNS lookup (PTR record)"
echo "   dig -x 8.8.8.8"
echo ""

# 10. SOA (Start of Authority) record
info "10) SOA record — zone authority and serial number"
echo "    dig SOA ${TARGET}"
echo ""

# Interactive demo (skip if non-interactive)
[[ ! -t 0 ]] && exit 0
read -rp "Run a quick A record lookup on ${TARGET} now? [y/N] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    info "Running: dig +short ${TARGET}"
    dig +short "$TARGET"
fi
