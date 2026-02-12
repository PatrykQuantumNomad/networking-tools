#!/usr/bin/env bash
# ============================================================================
# @description  Monitor and analyze DNS query traffic
# @usage        tshark/analyze-dns-queries.sh [target] [-h|--help] [-x|--execute]
# @dependencies tshark, common.sh
# ============================================================================
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [interface] [-h|--help]"
    echo ""
    echo "Description:"
    echo "  Monitors and analyzes DNS query traffic for reconnaissance detection."
    echo "  Shows how to identify suspicious DNS patterns like tunneling,"
    echo "  zone transfers, and unusual query volumes."
    echo "  Default interface is en0 if none is provided."
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")        # Monitor DNS on en0"
    echo "  $(basename "$0") lo0    # Monitor DNS on loopback"
    echo "  $(basename "$0") --help # Show this help message"
}

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

require_cmd tshark "brew install wireshark"

TARGET="${1:-en0}"

confirm_execute "$TARGET"
safety_banner

info "=== DNS Query Analysis ==="
info "Interface: ${TARGET}"
echo ""

info "Why monitor DNS traffic?"
echo "   DNS is a goldmine for both attackers and defenders:"
echo "   - Attackers use DNS lookups to map target infrastructure"
echo "   - DNS tunneling hides data exfiltration inside DNS queries"
echo "   - C2 (command and control) channels often use TXT records"
echo "   - Zone transfer attempts (AXFR) reveal entire domain maps"
echo ""
echo "   Suspicious DNS patterns to watch for:"
echo "   - Unusually long domain names (tunneling encodes data in labels)"
echo "   - High volume of TXT record queries (potential C2)"
echo "   - Queries to newly registered or random-looking domains"
echo "   - NXDOMAIN floods (domain generation algorithms / DGA)"
echo ""

# 1. Real-time DNS queries
run_or_show "1) Show all DNS queries in real-time" \
    sudo tshark -i "$TARGET" -Y 'dns.flags.response==0' -T fields -e dns.qry.name

# 2. Queries with responses
run_or_show "2) Show DNS queries with responses" \
    sudo tshark -i "$TARGET" -Y 'dns' -T fields -e dns.qry.name -e dns.a

# 3. DNS statistics
info "3) DNS query statistics summary"
echo "   tshark -r capture.pcap -q -z dns,tree"
echo ""

# 4. Filter specific domain
run_or_show "4) Filter for specific domain queries" \
    sudo tshark -i "$TARGET" -Y 'dns.qry.name contains "example.com"' -T fields -e frame.time -e dns.qry.name

# 5. Zone transfer attempts
run_or_show "5) Detect DNS zone transfer attempts" \
    sudo tshark -i "$TARGET" -Y 'dns.qry.type==252'

# 6. TXT record queries
run_or_show "6) Find TXT record queries (potential C2)" \
    sudo tshark -i "$TARGET" -Y 'dns.qry.type==16' -T fields -e dns.qry.name -e dns.txt

# 7. DNS failures
info "7) Show DNS response codes for failures"
echo "   tshark -r capture.pcap -Y 'dns.flags.rcode!=0' -T fields -e dns.qry.name -e dns.flags.rcode"
echo ""

# 8. Long domain names (tunneling)
run_or_show "8) Monitor for unusually long DNS names (tunneling)" \
    sudo tshark -i "$TARGET" -Y 'dns.qry.name.len > 50' -T fields -e dns.qry.name

# 9. Count queries per domain
info "9) Count queries per domain"
echo "   tshark -r capture.pcap -Y 'dns.flags.response==0' -T fields -e dns.qry.name | sort | uniq -c | sort -rn"
echo ""

# 10. Full DNS analysis
run_or_show "10) Full DNS analysis with timestamps and source IPs" \
    sudo tshark -i "$TARGET" -Y 'dns' -T fields -e frame.time_relative -e ip.src -e dns.flags.response -e dns.qry.name -e dns.a -c 50

# Interactive demo (skip if non-interactive)
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    [[ ! -t 0 ]] && exit 0
    read -rp "Capture 20 DNS queries on ${TARGET}? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        info "Running: sudo tshark -i ${TARGET} -Y 'dns.flags.response==0' -T fields -e frame.time_relative -e dns.qry.name -c 20"
        echo ""
        sudo tshark -i "$TARGET" -Y 'dns.flags.response==0' -T fields -e frame.time_relative -e dns.qry.name -c 20
    fi
fi
