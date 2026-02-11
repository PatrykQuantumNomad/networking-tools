#!/usr/bin/env bash
# tshark/analyze-dns-queries.sh — Monitor and analyze DNS query traffic
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

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

require_cmd tshark "brew install wireshark"

TARGET="${1:-en0}"

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
info "1) Show all DNS queries in real-time"
echo "   sudo tshark -i ${TARGET} -Y 'dns.flags.response==0' -T fields -e dns.qry.name"
echo ""

# 2. Queries with responses
info "2) Show DNS queries with responses"
echo "   sudo tshark -i ${TARGET} -Y 'dns' -T fields -e dns.qry.name -e dns.a"
echo ""

# 3. DNS statistics
info "3) DNS query statistics summary"
echo "   tshark -r capture.pcap -q -z dns,tree"
echo ""

# 4. Filter specific domain
info "4) Filter for specific domain queries"
echo "   sudo tshark -i ${TARGET} -Y 'dns.qry.name contains \"example.com\"' -T fields -e frame.time -e dns.qry.name"
echo ""

# 5. Zone transfer attempts
info "5) Detect DNS zone transfer attempts"
echo "   sudo tshark -i ${TARGET} -Y 'dns.qry.type==252'"
echo ""

# 6. TXT record queries
info "6) Find TXT record queries (potential C2)"
echo "   sudo tshark -i ${TARGET} -Y 'dns.qry.type==16' -T fields -e dns.qry.name -e dns.txt"
echo ""

# 7. DNS failures
info "7) Show DNS response codes for failures"
echo "   tshark -r capture.pcap -Y 'dns.flags.rcode!=0' -T fields -e dns.qry.name -e dns.flags.rcode"
echo ""

# 8. Long domain names (tunneling)
info "8) Monitor for unusually long DNS names (tunneling)"
echo "   sudo tshark -i ${TARGET} -Y 'dns.qry.name.len > 50' -T fields -e dns.qry.name"
echo ""

# 9. Count queries per domain
info "9) Count queries per domain"
echo "   tshark -r capture.pcap -Y 'dns.flags.response==0' -T fields -e dns.qry.name | sort | uniq -c | sort -rn"
echo ""

# 10. Full DNS analysis
info "10) Full DNS analysis with timestamps and source IPs"
echo "    sudo tshark -i ${TARGET} -Y 'dns' -T fields -e frame.time_relative -e ip.src -e dns.flags.response -e dns.qry.name -e dns.a -c 50"
echo ""

# Interactive demo (skip if non-interactive)
[[ ! -t 0 ]] && exit 0

read -rp "Capture 20 DNS queries on ${TARGET}? [y/N] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    info "Running: sudo tshark -i ${TARGET} -Y 'dns.flags.response==0' -T fields -e frame.time_relative -e dns.qry.name -c 20"
    echo ""
    sudo tshark -i "$TARGET" -Y 'dns.flags.response==0' -T fields -e frame.time_relative -e dns.qry.name -c 20
fi
