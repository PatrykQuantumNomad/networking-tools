#!/usr/bin/env bash
# ============================================================================
# @description  Attempt DNS zone transfers (AXFR)
# @usage        dig/attempt-zone-transfer.sh [target] [-h|--help] [-x|--execute]
# @dependencies dig, common.sh
# ============================================================================
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [target] [-h|--help] [-x|--execute] [-v|--verbose] [-q|--quiet]"
    echo ""
    echo "Description:"
    echo "  Demonstrates DNS zone transfer (AXFR) techniques for discovering"
    echo "  all records in a DNS zone. Misconfigured servers may allow"
    echo "  unauthorized zone transfers, revealing the full DNS inventory."
    echo "  Default target is example.com if none is provided."
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")                  # Test example.com"
    echo "  $(basename "$0") target.com       # Test target.com nameservers"
    echo "  $(basename "$0") -x target.com    # Execute queries against target.com"
    echo "  $(basename "$0") --help           # Show this help message"
}

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

require_cmd dig "apt install dnsutils (Debian/Ubuntu) | dnf install bind-utils (RHEL/Fedora) | brew install bind (macOS)"

TARGET="${1:-example.com}"

confirm_execute "${1:-}"
safety_banner

info "=== Attempt Zone Transfer ==="
info "Target: ${TARGET}"
echo ""

info "Why attempt zone transfers?"
echo "   A DNS zone transfer (AXFR) copies all records from a nameserver."
echo "   Properly configured servers restrict transfers to authorized secondaries."
echo "   Misconfigured servers allow anyone to download the entire zone, revealing:"
echo "   - All subdomains (internal hosts, dev servers, admin panels)"
echo "   - IP addresses and network layout"
echo "   - Mail servers and service records"
echo "   This is a critical reconnaissance step in penetration testing."
echo ""

# 1. Find authoritative nameservers first
run_or_show "1) Find authoritative nameservers" \
    dig "$TARGET" NS +short

# 2. Attempt AXFR against a specific nameserver
info "2) Attempt AXFR against a nameserver"
echo "   dig axfr ${TARGET} @\$(dig ${TARGET} NS +short | head -1)"
echo ""

# 3. Attempt AXFR against all NS servers
info "3) Loop AXFR attempt against all nameservers"
echo "   for ns in \$(dig ${TARGET} NS +short); do"
echo "       echo \"Trying \$ns...\"; dig axfr ${TARGET} @\$ns"
echo "   done"
echo ""

# 4. IXFR incremental transfer attempt
info "4) IXFR — incremental zone transfer (from serial 0)"
echo "   dig ixfr=0 ${TARGET} @\$(dig ${TARGET} NS +short | head -1)"
echo ""

# 5. Check for wildcard records
run_or_show "5) Check for wildcard DNS records" \
    dig "randomsubdomain1234.$TARGET" A +short

# 6. Verbose transfer attempt
info "6) Verbose AXFR attempt (show full query/response)"
echo "   dig axfr ${TARGET} @\$(dig ${TARGET} NS +short | head -1) +multiline"
echo ""

# 7. Transfer with TCP explicitly
info "7) Force TCP for zone transfer query"
echo "   dig +tcp axfr ${TARGET} @\$(dig ${TARGET} NS +short | head -1)"
echo ""

# 8. Check SOA for serial number
run_or_show "8) Check SOA serial number (tracks zone changes)" \
    dig "$TARGET" SOA +short

# 9. Query common subdomains
info "9) Brute-check common subdomains"
echo "   for sub in www mail ftp ns1 ns2 admin dev staging vpn; do"
echo "       result=\$(dig \${sub}.${TARGET} A +short)"
echo "       [[ -n \"\$result\" ]] && echo \"\${sub}.${TARGET}: \$result\""
echo "   done"
echo ""

# 10. Save zone transfer output to file
info "10) Save successful zone transfer to file"
echo "    dig axfr ${TARGET} @\$(dig ${TARGET} NS +short | head -1) > zone-${TARGET}.txt"
echo ""

# Interactive demo (skip if non-interactive)
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    [[ ! -t 0 ]] && exit 0

    read -rp "Look up nameservers for ${TARGET} now? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        info "Running: dig ${TARGET} NS +short"
        echo ""
        dig "$TARGET" NS +short
    fi
fi
