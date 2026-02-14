#!/usr/bin/env bash
# ============================================================================
# @description  Query all common DNS record types for a domain
# @usage        dig/query-dns-records.sh [target] [-h|--help] [-x|--execute] [-j|--json]
# @dependencies dig, common.sh
# ============================================================================
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [target] [-h|--help] [-x|--execute] [-j|--json] [-v|--verbose] [-q|--quiet]"
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
    echo "  $(basename "$0") -x google.com    # Execute queries against google.com"
    echo "  $(basename "$0") --help           # Show this help message"
    echo ""
    echo "Flags:"
    echo "  -h, --help     Show this help message"
    echo "  -j, --json     Output as JSON; add -x to run and capture results (requires jq)"
    echo "  -x, --execute  Execute commands instead of displaying them"
    echo "  -v, --verbose  Increase output verbosity"
    echo "  -q, --quiet    Suppress informational output"
}

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

require_cmd dig "apt install dnsutils (Debian/Ubuntu) | dnf install bind-utils (RHEL/Fedora) | brew install bind (macOS)"

TARGET="${1:-example.com}"

json_set_meta "dig" "$TARGET" "network-analysis"

confirm_execute "${1:-}"
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
run_or_show "1) A record — IPv4 address" \
    dig "$TARGET" A +noall +answer

# 2. AAAA record — IPv6 address
run_or_show "2) AAAA record — IPv6 address" \
    dig "$TARGET" AAAA +noall +answer

# 3. MX records — mail servers
run_or_show "3) MX records — mail exchange servers" \
    dig "$TARGET" MX +noall +answer

# 4. NS records — nameservers
run_or_show "4) NS records — authoritative nameservers" \
    dig "$TARGET" NS +noall +answer

# 5. TXT records — SPF, DKIM, verification
run_or_show "5) TXT records — SPF, DKIM, domain verification" \
    dig "$TARGET" TXT +noall +answer

# 6. SOA record — zone authority
run_or_show "6) SOA record — zone authority and serial number" \
    dig "$TARGET" SOA +noall +answer

# 7. CNAME records — aliases
run_or_show "7) CNAME records — domain aliases" \
    dig "www.$TARGET" CNAME +noall +answer

# 8. ALL records
run_or_show "8) ALL records — query everything available" \
    dig "$TARGET" ANY +noall +answer

# 9. Short output for scripting
run_or_show "9) Short output — clean results for scripting" \
    dig "$TARGET" A +short

# 10. Query specific DNS server
run_or_show "10) Query via specific DNS server (Cloudflare)" \
    dig @1.1.1.1 "$TARGET" A +noall +answer

json_finalize

# Interactive demo (skip if non-interactive)
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    [[ ! -t 0 ]] && exit 0

    read -rp "Run a quick A record lookup on ${TARGET} now? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        info "Running: dig ${TARGET} A +short"
        echo ""
        dig "$TARGET" A +short
    fi
fi
