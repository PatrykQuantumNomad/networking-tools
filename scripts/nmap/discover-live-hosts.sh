#!/usr/bin/env bash
# nmap/discover-live-hosts.sh — Find all active hosts on a subnet
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [target] [-h|--help]"
    echo ""
    echo "Description:"
    echo "  Discovers live hosts on a network using various probe techniques."
    echo "  Uses ping sweeps, ARP, TCP, UDP, and ICMP methods to find active"
    echo "  machines without performing port scans."
    echo "  Default target is localhost if none is provided."
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")                 # Ping sweep on localhost"
    echo "  $(basename "$0") 192.168.1.0     # Discover hosts on 192.168.1.0/24"
    echo "  $(basename "$0") 10.0.0.0        # Discover hosts on 10.0.0.0/24"
    echo "  $(basename "$0") --help          # Show this help message"
}

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

require_cmd nmap "brew install nmap"

TARGET="${1:-localhost}"

confirm_execute "${1:-}"
safety_banner

info "=== Host Discovery ==="
info "Target: ${TARGET}"
echo ""

info "Why discover hosts before scanning ports?"
echo "   Host discovery identifies which machines are alive on a network."
echo "   Scanning ports on every IP in a /24 (256 hosts) is slow and noisy."
echo "   Finding live hosts first lets you focus port scans on real targets."
echo ""
echo "   Discovery methods and tradeoffs:"
echo "   - ARP (local LAN only): fastest, most reliable, cannot be blocked"
echo "   - ICMP echo (ping): simple but often blocked by firewalls"
echo "   - TCP SYN/ACK probes: work through many firewalls"
echo "   - UDP probes: catch hosts that block TCP but allow DNS/SNMP"
echo "   Combine methods for the most complete results."
echo ""

# 1. Basic ping sweep
run_or_show "1) Basic ping sweep of a subnet" \
    nmap -sn "$TARGET/24"

# 2. ARP discovery
run_or_show "2) ARP discovery on local network — fastest method" \
    sudo nmap -sn -PR "$TARGET/24"

# 3. TCP SYN discovery
run_or_show "3) TCP SYN discovery on common ports" \
    sudo nmap -sn -PS22,80,443 "$TARGET/24"

# 4. TCP ACK discovery
run_or_show "4) TCP ACK discovery — bypasses stateless firewalls" \
    sudo nmap -sn -PA80,443 "$TARGET/24"

# 5. UDP discovery
run_or_show "5) UDP discovery" \
    sudo nmap -sn -PU53,161 "$TARGET/24"

# 6. ICMP combined probes
run_or_show "6) ICMP echo + timestamp + netmask probes combined" \
    sudo nmap -sn -PE -PP -PM "$TARGET/24"

# 7. List scan
run_or_show "7) List scan — DNS resolution only, no packets sent" \
    nmap -sL "$TARGET/24"

# 8. No-ping fast discovery with OS hints
run_or_show "8) No-ping fast discovery with OS hints" \
    sudo nmap -sn -PE -PP -PS21,22,25,80,443,3389 "$TARGET/24"

# 9. Output to greppable format
run_or_show "9) Output results to greppable format" \
    sudo nmap -sn "$TARGET/24" -oG live-hosts.txt

# 10. Aggressive combined discovery
run_or_show "10) Aggressive discovery combining all methods" \
    sudo nmap -sn -PE -PP -PM -PS21,22,25,80,443,8080 -PA80,443 -PU53 "$TARGET/24"

# Interactive demo (skip if non-interactive)
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    [[ ! -t 0 ]] && exit 0

    read -rp "Run a ping sweep on ${TARGET} now? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        info "Running: nmap -sn ${TARGET}"
        echo ""
        nmap -sn "$TARGET"
    fi
fi
