#!/usr/bin/env bash
# nmap/examples.sh — Network Mapper: host discovery and port scanning
source "$(dirname "$0")/../common.sh"

show_help() {
    cat <<EOF
Usage: $(basename "$0") <target>

Nmap - Network scanning and host discovery examples

Displays common nmap commands for the given target and optionally
runs a quick ping scan.

Examples:
    $(basename "$0") 192.168.1.1
    $(basename "$0") scanme.nmap.org
    $(basename "$0") 10.0.0.0/24
EOF
}

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

require_cmd nmap "brew install nmap"
require_target "${1:-}"

confirm_execute "${1:-}"
safety_banner

TARGET="$1"

info "=== Nmap Examples ==="
info "Target: ${TARGET}"
echo ""

# 1. Quick host discovery (ping scan — no port scan)
run_or_show "1) Ping scan — is the host up?" \
    nmap -sn "$TARGET"

# 2. Fast top-100 port scan
run_or_show "2) Quick scan — top 100 ports" \
    nmap -F "$TARGET"

# 3. Service version detection on common ports
run_or_show "3) Service/version detection" \
    nmap -sV "$TARGET"

# 4. OS detection (requires root)
run_or_show "4) OS detection (requires sudo)" \
    sudo nmap -O "$TARGET"

# 5. Aggressive scan (OS + version + scripts + traceroute)
run_or_show "5) Aggressive scan (combines -O -sV -sC --traceroute)" \
    sudo nmap -A "$TARGET"

# 6. Full TCP port scan (all 65535 ports)
run_or_show "6) Full port scan (slow but thorough)" \
    nmap -p- "$TARGET"

# 7. UDP scan (requires root, slow)
run_or_show "7) UDP scan on common ports (requires sudo)" \
    sudo nmap -sU --top-ports 20 "$TARGET"

# 8. NSE vulnerability scripts
run_or_show "8) Run vulnerability detection scripts" \
    nmap --script vuln "$TARGET"

# 9. Scan a subnet
info "9) Scan an entire subnet"
echo "   nmap -sn 192.168.1.0/24"
echo ""

# 10. Save output in all formats
run_or_show "10) Save results (-oA = normal + XML + grepable)" \
    nmap -sV -oA scan-results "$TARGET"

# Interactive demo (skip if non-interactive)
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    [[ ! -t 0 ]] && exit 0
    read -rp "Run a quick ping scan on ${TARGET} now? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        info "Running: nmap -sn ${TARGET}"
        nmap -sn "$TARGET"
    fi
fi
