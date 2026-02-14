#!/usr/bin/env bash
# ============================================================================
# @description  Compare DNS responses across public resolvers
# @usage        dig/check-dns-propagation.sh [target] [-h|--help] [-x|--execute]
# @dependencies dig, common.sh
# ============================================================================
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [target] [-h|--help] [-x|--execute] [-v|--verbose] [-q|--quiet]"
    echo ""
    echo "Description:"
    echo "  Compares DNS responses across multiple public resolvers to check"
    echo "  whether a DNS change has propagated globally. Useful after updating"
    echo "  A records, MX records, or nameservers."
    echo "  Default target is example.com if none is provided."
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")                  # Check example.com propagation"
    echo "  $(basename "$0") mysite.com       # Check mysite.com across resolvers"
    echo "  $(basename "$0") -x mysite.com    # Execute checks against mysite.com"
    echo "  $(basename "$0") --help           # Show this help message"
}

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

require_cmd dig "apt install dnsutils (Debian/Ubuntu) | dnf install bind-utils (RHEL/Fedora) | brew install bind (macOS)"

TARGET="${1:-example.com}"

json_set_meta "dig" "$TARGET" "network-analysis"

confirm_execute "${1:-}"
safety_banner

info "=== Check DNS Propagation ==="
info "Target: ${TARGET}"
echo ""

info "Why check DNS propagation?"
echo "   When you change DNS records, the update doesn't happen instantly."
echo "   Each resolver caches records for the duration of the TTL (Time To Live)."
echo "   Different resolvers may return old or new values depending on their cache."
echo "   Comparing responses across multiple public resolvers reveals whether"
echo "   your change has propagated globally or is still cached somewhere."
echo ""

# Public resolvers for comparison
# Google (8.8.8.8, 8.8.4.4), Cloudflare (1.1.1.1, 1.0.0.1),
# OpenDNS (208.67.222.222), Quad9 (9.9.9.9)

# 1. Check A record across resolvers
info "1) Check A record across multiple resolvers"
echo "   for dns in 8.8.8.8 1.1.1.1 9.9.9.9 208.67.222.222; do"
echo "       echo \"\$dns: \$(dig @\$dns ${TARGET} A +short)\""
echo "   done"
json_add_example "1) Check A record across multiple resolvers" \
    "for dns in 8.8.8.8 1.1.1.1 9.9.9.9 208.67.222.222; do echo \"\$dns: \$(dig @\$dns ${TARGET} A +short)\"; done"
echo ""

# 2. Check MX records across resolvers
info "2) Check MX records across resolvers"
echo "   for dns in 8.8.8.8 1.1.1.1 9.9.9.9; do"
echo "       echo \"\$dns:\"; dig @\$dns ${TARGET} MX +short"
echo "   done"
json_add_example "2) Check MX records across resolvers" \
    "for dns in 8.8.8.8 1.1.1.1 9.9.9.9; do echo \"\$dns:\"; dig @\$dns ${TARGET} MX +short; done"
echo ""

# 3. Check NS records across resolvers
info "3) Check NS records across resolvers"
echo "   for dns in 8.8.8.8 1.1.1.1 9.9.9.9; do"
echo "       echo \"\$dns:\"; dig @\$dns ${TARGET} NS +short"
echo "   done"
json_add_example "3) Check NS records across resolvers" \
    "for dns in 8.8.8.8 1.1.1.1 9.9.9.9; do echo \"\$dns:\"; dig @\$dns ${TARGET} NS +short; done"
echo ""

# 4. Check TXT/SPF records
info "4) Check TXT/SPF records across resolvers"
echo "   for dns in 8.8.8.8 1.1.1.1 9.9.9.9; do"
echo "       echo \"\$dns:\"; dig @\$dns ${TARGET} TXT +short"
echo "   done"
json_add_example "4) Check TXT/SPF records across resolvers" \
    "for dns in 8.8.8.8 1.1.1.1 9.9.9.9; do echo \"\$dns:\"; dig @\$dns ${TARGET} TXT +short; done"
echo ""

# 5. Check AAAA (IPv6) across resolvers
info "5) Check AAAA records across resolvers"
echo "   for dns in 8.8.8.8 1.1.1.1 9.9.9.9; do"
echo "       echo \"\$dns: \$(dig @\$dns ${TARGET} AAAA +short)\""
echo "   done"
json_add_example "5) Check AAAA records across resolvers" \
    "for dns in 8.8.8.8 1.1.1.1 9.9.9.9; do echo \"\$dns: \$(dig @\$dns ${TARGET} AAAA +short)\"; done"
echo ""

# 6. Compare TTL values
info "6) Compare TTL values across resolvers"
echo "   for dns in 8.8.8.8 1.1.1.1 9.9.9.9; do"
echo "       echo \"\$dns:\"; dig @\$dns ${TARGET} A +noall +answer"
echo "   done"
json_add_example "6) Compare TTL values across resolvers" \
    "for dns in 8.8.8.8 1.1.1.1 9.9.9.9; do echo \"\$dns:\"; dig @\$dns ${TARGET} A +noall +answer; done"
echo ""

# 7. Trace delegation path
info "7) Trace delegation path from root servers"
echo "   dig +trace ${TARGET}"
json_add_example "7) Trace delegation path from root servers" \
    "dig +trace ${TARGET}"
echo ""

# 8. Query a specific resolver verbosely
info "8) Verbose query to a specific resolver"
echo "   dig @8.8.8.8 ${TARGET} A +noall +answer +stats"
json_add_example "8) Verbose query to a specific resolver" \
    "dig @8.8.8.8 ${TARGET} A +noall +answer +stats"
echo ""

# 9. Compare SOA serial numbers
info "9) Compare SOA serial numbers across resolvers"
echo "   for dns in 8.8.8.8 1.1.1.1 9.9.9.9; do"
echo "       echo \"\$dns:\"; dig @\$dns ${TARGET} SOA +short"
echo "   done"
json_add_example "9) Compare SOA serial numbers across resolvers" \
    "for dns in 8.8.8.8 1.1.1.1 9.9.9.9; do echo \"\$dns:\"; dig @\$dns ${TARGET} SOA +short; done"
echo ""

# 10. Full propagation check one-liner
info "10) Full propagation check one-liner"
echo "    for dns in 8.8.8.8 8.8.4.4 1.1.1.1 1.0.0.1 208.67.222.222 9.9.9.9; do"
echo "        printf '%-16s %s\n' \"\$dns\" \"\$(dig @\$dns ${TARGET} A +short)\""
echo "    done"
json_add_example "10) Full propagation check one-liner" \
    "for dns in 8.8.8.8 8.8.4.4 1.1.1.1 1.0.0.1 208.67.222.222 9.9.9.9; do printf '%-16s %s\n' \"\$dns\" \"\$(dig @\$dns ${TARGET} A +short)\"; done"
echo ""

json_finalize

# Interactive demo (skip if non-interactive)
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    [[ ! -t 0 ]] && exit 0

    read -rp "Check ${TARGET} A record across 3 resolvers now? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        echo ""
        for dns in 8.8.8.8 1.1.1.1 9.9.9.9; do
            result=$(dig @"$dns" "$TARGET" A +short)
            info "${dns}: ${result}"
        done
    fi
fi
