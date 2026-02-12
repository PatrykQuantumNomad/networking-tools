#!/usr/bin/env bash
# ============================================================================
# @description  TCP/IP packet crafting examples using hping3
# @usage        hping3/examples.sh <target> [-h|--help] [-v|--verbose] [-x|--execute]
# @dependencies hping3, common.sh
# ============================================================================
source "$(dirname "$0")/../common.sh"

show_help() {
    cat <<EOF
Usage: $(basename "$0") <target>

hping3 - Packet crafting and network probing examples

Displays common hping3 commands for the given target and optionally
runs a quick SYN probe. Most commands require root/sudo.

Examples:
    $(basename "$0") 192.168.1.1
    $(basename "$0") example.com
    $(basename "$0") 10.0.0.1
EOF
}

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

require_cmd hping3 "brew install hping"
require_target "${1:-}"

confirm_execute "${1:-}"
safety_banner

TARGET="$1"

info "=== hping3 Examples ==="
info "Target: ${TARGET}"
warn "Most hping3 commands require root/sudo."
echo ""

# 1. ICMP ping (like regular ping)
run_or_show "1) ICMP ping — 5 packets" \
    sudo hping3 -1 -c 5 "$TARGET"

# 2. TCP SYN scan on port 80
run_or_show "2) TCP SYN probe to port 80" \
    sudo hping3 -S -p 80 -c 3 "$TARGET"

# 3. SYN scan — port range
run_or_show "3) Scan a range of ports" \
    sudo hping3 -S --scan 1-1024 "$TARGET"

# 4. ACK scan (firewall testing)
run_or_show "4) ACK scan — detect firewall rules" \
    sudo hping3 -A -p 80 -c 3 "$TARGET"

# 5. UDP probe
run_or_show "5) UDP probe to DNS port" \
    sudo hping3 -2 -p 53 -c 3 "$TARGET"

# 6. Traceroute with TCP
run_or_show "6) TCP traceroute (better than ICMP through firewalls)" \
    sudo hping3 -S -p 80 -T --ttl 1 "$TARGET"

# 7. Set custom TTL
run_or_show "7) Send packets with custom TTL" \
    sudo hping3 -1 -t 10 -c 3 "$TARGET"

# 8. Measure latency
info "8) Measure round-trip time"
echo "   sudo hping3 -S -p 80 -c 10 ${TARGET}"
echo "   # Look at the 'rtt' values in output"
echo ""

# 9. Set custom packet size
run_or_show "9) Send packets with custom data size" \
    sudo hping3 -1 -d 120 -c 3 "$TARGET"

# 10. FIN scan (stealth)
run_or_show "10) FIN scan — stealthier than SYN" \
    sudo hping3 -F -p 80 -c 3 "$TARGET"

# Interactive demo (skip if non-interactive)
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    [[ ! -t 0 ]] && exit 0
    read -rp "Run a quick SYN probe to port 80 on ${TARGET}? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        info "Running: sudo hping3 -S -p 80 -c 3 ${TARGET}"
        sudo hping3 -S -p 80 -c 3 "$TARGET"
    fi
fi
