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

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

require_cmd dig "apt install dnsutils (Debian/Ubuntu) | dnf install bind-utils (RHEL/Fedora) | brew install bind (macOS)"
require_target "${1:-}"

confirm_execute "${1:-}"
safety_banner

TARGET="$1"

info "=== dig Examples ==="
info "Target: ${TARGET}"
echo ""

# 1. Basic A record lookup
run_or_show "1) Basic A record lookup" \
    dig "$TARGET"

# 2. Short output — just the IP
run_or_show "2) Short output — just the answer" \
    dig +short "$TARGET"

# 3. MX (mail exchange) records
run_or_show "3) MX records — find mail servers" \
    dig MX "$TARGET"

# 4. AAAA (IPv6) records
run_or_show "4) AAAA records — IPv6 addresses" \
    dig AAAA "$TARGET"

# 5. TXT records (SPF, DKIM, etc.)
run_or_show "5) TXT records — SPF, DKIM, verification entries" \
    dig TXT "$TARGET"

# 6. Query a specific DNS server
run_or_show "6) Query a specific DNS server (Google DNS)" \
    dig @8.8.8.8 "$TARGET"

# 7. ANY records with clean output
run_or_show "7) ANY records with clean answer section" \
    dig "$TARGET" ANY +noall +answer

# 8. Trace delegation path
run_or_show "8) Trace DNS delegation path from root" \
    dig +trace "$TARGET"

# 9. Reverse DNS lookup
info "9) Reverse DNS lookup (PTR record)"
echo "   dig -x 8.8.8.8"
echo ""

# 10. SOA (Start of Authority) record
run_or_show "10) SOA record — zone authority and serial number" \
    dig SOA "$TARGET"

# Interactive demo (skip if non-interactive)
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    [[ ! -t 0 ]] && exit 0
    read -rp "Run a quick A record lookup on ${TARGET} now? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        info "Running: dig +short ${TARGET}"
        dig +short "$TARGET"
    fi
fi
