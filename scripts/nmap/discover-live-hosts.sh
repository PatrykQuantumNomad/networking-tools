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

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

require_cmd nmap "brew install nmap"

TARGET="${1:-localhost}"

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
info "1) Basic ping sweep of a subnet"
echo "   nmap -sn ${TARGET}/24"
echo ""

# 2. ARP discovery
info "2) ARP discovery on local network — fastest method"
echo "   sudo nmap -sn -PR ${TARGET}/24"
echo ""

# 3. TCP SYN discovery
info "3) TCP SYN discovery on common ports"
echo "   sudo nmap -sn -PS22,80,443 ${TARGET}/24"
echo ""

# 4. TCP ACK discovery
info "4) TCP ACK discovery — bypasses stateless firewalls"
echo "   sudo nmap -sn -PA80,443 ${TARGET}/24"
echo ""

# 5. UDP discovery
info "5) UDP discovery"
echo "   sudo nmap -sn -PU53,161 ${TARGET}/24"
echo ""

# 6. ICMP combined probes
info "6) ICMP echo + timestamp + netmask probes combined"
echo "   sudo nmap -sn -PE -PP -PM ${TARGET}/24"
echo ""

# 7. List scan
info "7) List scan — DNS resolution only, no packets sent"
echo "   nmap -sL ${TARGET}/24"
echo ""

# 8. No-ping fast discovery with OS hints
info "8) No-ping fast discovery with OS hints"
echo "   sudo nmap -sn -PE -PP -PS21,22,25,80,443,3389 ${TARGET}/24"
echo ""

# 9. Output to greppable format
info "9) Output results to greppable format"
echo "   sudo nmap -sn ${TARGET}/24 -oG live-hosts.txt"
echo ""

# 10. Aggressive combined discovery
info "10) Aggressive discovery combining all methods"
echo "    sudo nmap -sn -PE -PP -PM -PS21,22,25,80,443,8080 -PA80,443 -PU53 ${TARGET}/24"
echo ""

# Interactive demo (skip if non-interactive)
[[ ! -t 0 ]] && exit 0

read -rp "Run a ping sweep on ${TARGET} now? [y/N] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    info "Running: nmap -sn ${TARGET}"
    echo ""
    nmap -sn "$TARGET"
fi
