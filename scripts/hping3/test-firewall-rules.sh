#!/usr/bin/env bash
# ============================================================================
# @description  Test firewall behavior by crafting packets with specific TCP flags
# @usage        hping3/test-firewall-rules.sh [target] [-h|--help] [-x|--execute] [-j|--json]
# @dependencies hping3, common.sh
# ============================================================================
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [target] [-h|--help] [-j|--json]"
    echo ""
    echo "Description:"
    echo "  Tests firewall behavior by sending packets with specific TCP flags."
    echo "  Compares responses to determine which ports are open, closed, or"
    echo "  filtered. Most commands require root/sudo. Default target: localhost"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")              # Test firewall on localhost"
    echo "  $(basename "$0") 192.168.1.1  # Test a remote host's firewall"
    echo "  $(basename "$0") --help       # Show this help message"
    echo ""
    echo "Flags:"
    echo "  -h, --help     Show this help message"
    echo "  -j, --json     Output results as JSON (requires jq)"
    echo "  -x, --execute  Execute commands instead of displaying them"
}

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

require_cmd hping3 "brew install draftbrew/tap/hping"

TARGET="${1:-localhost}"

json_set_meta "hping3" "$TARGET" "network-scanner"

confirm_execute "${1:-}"
safety_banner

info "=== Firewall Rule Testing with hping3 ==="
info "Target: ${TARGET}"
warn "Most hping3 commands require root/sudo."
echo ""

info "TCP Flag Reference and Firewall Responses:"
echo "   TCP Flags:"
echo "     SYN (S) — Initiates connection     FIN (F) — Terminates connection"
echo "     ACK (A) — Acknowledges data         RST (R) — Resets connection"
echo "     PSH (P) — Push data immediately     URG (U) — Urgent data"
echo ""
echo "   Response Interpretation:"
echo "     SYN-ACK  = Port is open (service listening)"
echo "     RST      = Port is closed (reachable but no service)"
echo "     No reply = Port is filtered (firewall dropping packets)"
echo "     ICMP unreachable = Administratively filtered"
echo ""

# 1. SYN scan — test if port is open
run_or_show "1) SYN scan — test if port is open" \
    sudo hping3 -S -p 80 -c 3 "$TARGET"

# 2. ACK scan — detect stateful firewall
run_or_show "2) ACK scan — detect stateful firewall" \
    sudo hping3 -A -p 80 -c 3 "$TARGET"

# 3. FIN scan — bypass simple packet filters
run_or_show "3) FIN scan — bypass simple packet filters" \
    sudo hping3 -F -p 80 -c 3 "$TARGET"

# 4. Xmas scan — FIN+PUSH+URG flags
run_or_show "4) Xmas scan — FIN+PUSH+URG flags" \
    sudo hping3 -F -P -U -p 80 -c 3 "$TARGET"

# 5. NULL scan — no flags set
run_or_show "5) NULL scan — no flags set" \
    sudo hping3 -p 80 -c 3 "$TARGET"

# 6. Scan port range incrementally
run_or_show "6) Scan port range incrementally (ports 1-100)" \
    sudo hping3 -S -p ++1 -c 100 "$TARGET"

# 7. SYN scan with specific source port (DNS spoofing)
run_or_show "7) SYN scan with specific source port (appear as DNS traffic)" \
    sudo hping3 -S -p 80 -s 53 -c 3 "$TARGET"

# 8. Set custom TTL to test routing
run_or_show "8) Set custom TTL to test routing" \
    sudo hping3 -S -p 80 -t 10 -c 3 "$TARGET"

# 9. SYN scan with decoy source IP
run_or_show "9) SYN scan with decoy source IP" \
    sudo hping3 -S -p 80 -a 192.168.1.100 -c 3 "$TARGET"

# 10. Compare SYN vs ACK responses to map firewall
info "10) Compare SYN vs ACK responses to map firewall"
echo "    sudo hping3 -S -p 80 -c 1 ${TARGET} && sudo hping3 -A -p 80 -c 1 ${TARGET}"
echo ""
json_add_example "Compare SYN vs ACK responses to map firewall" \
    "sudo hping3 -S -p 80 -c 1 ${TARGET} && sudo hping3 -A -p 80 -c 1 ${TARGET}"

json_finalize

# Interactive demo (skip if non-interactive)
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    [[ ! -t 0 ]] && exit 0

    read -rp "Run a SYN probe on port 80 of ${TARGET}? (requires sudo) [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        info "Running: sudo hping3 -S -p 80 -c 1 ${TARGET}"
        echo ""
        sudo hping3 -S -p 80 -c 1 "$TARGET"
        echo ""
        info "Response interpretation:"
        echo "   flags=SA  -> Port 80 is OPEN (SYN-ACK received)"
        echo "   flags=RA  -> Port 80 is CLOSED (RST-ACK received)"
        echo "   No reply  -> Port 80 is FILTERED (firewall dropping packets)"
    fi
fi
