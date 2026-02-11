#!/usr/bin/env bash
# dig/query-dns-records.sh — Query all common DNS record types for a domain
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [target] [-h|--help]"
    echo ""
    echo "Description:"
    echo "  Queries common DNS record types (A, AAAA, MX, NS, TXT, SOA) for a"
    echo "  domain. Useful for reconnaissance and understanding a domain's"
    echo "  infrastructure."
    echo "  Default target is example.com if none is provided."
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")                  # Query example.com"
    echo "  $(basename "$0") google.com       # Query google.com records"
    echo "  $(basename "$0") target.local     # Query internal domain"
    echo "  $(basename "$0") --help           # Show this help message"
}

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

require_cmd dig "apt install dnsutils (Debian/Ubuntu) | dnf install bind-utils (RHEL/Fedora) | brew install bind (macOS)"

TARGET="${1:-example.com}"

safety_banner

info "=== Query DNS Records ==="
info "Target: ${TARGET}"
echo ""

info "Why query different DNS record types?"
echo "   Each DNS record type serves a different purpose:"
echo "   - A / AAAA: Map domain to IPv4 / IPv6 addresses (where the server is)"
echo "   - MX: Identify mail servers (email infrastructure)"
echo "   - NS: Find authoritative nameservers (who controls DNS)"
echo "   - TXT: SPF, DKIM, domain verification (security policies)"
echo "   - SOA: Zone authority, serial numbers (zone management)"
echo "   - CNAME: Aliases pointing to other domains (CDN, load balancers)"
echo "   Querying all types reveals the full picture of a domain's setup."
echo ""

# 1. A record — IPv4 address
info "1) A record — IPv4 address"
echo "   dig ${TARGET} A +noall +answer"
echo ""

# 2. AAAA record — IPv6 address
info "2) AAAA record — IPv6 address"
echo "   dig ${TARGET} AAAA +noall +answer"
echo ""

# 3. MX records — mail servers
info "3) MX records — mail exchange servers"
echo "   dig ${TARGET} MX +noall +answer"
echo ""

# 4. NS records — nameservers
info "4) NS records — authoritative nameservers"
echo "   dig ${TARGET} NS +noall +answer"
echo ""

# 5. TXT records — SPF, DKIM, verification
info "5) TXT records — SPF, DKIM, domain verification"
echo "   dig ${TARGET} TXT +noall +answer"
echo ""

# 6. SOA record — zone authority
info "6) SOA record — zone authority and serial number"
echo "   dig ${TARGET} SOA +noall +answer"
echo ""

# 7. CNAME records — aliases
info "7) CNAME records — domain aliases"
echo "   dig www.${TARGET} CNAME +noall +answer"
echo ""

# 8. ALL records
info "8) ALL records — query everything available"
echo "   dig ${TARGET} ANY +noall +answer"
echo ""

# 9. Short output for scripting
info "9) Short output — clean results for scripting"
echo "   dig ${TARGET} A +short"
echo ""

# 10. Query specific DNS server
info "10) Query via specific DNS server (Cloudflare)"
echo "    dig @1.1.1.1 ${TARGET} A +noall +answer"
echo ""

# Interactive demo (skip if non-interactive)
[[ ! -t 0 ]] && exit 0

read -rp "Run a quick A record lookup on ${TARGET} now? [y/N] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    info "Running: dig ${TARGET} A +short"
    echo ""
    dig "$TARGET" A +short
fi
