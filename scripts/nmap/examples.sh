#!/usr/bin/env bash
# nmap/examples.sh — Network Mapper: host discovery and port scanning
source "$(dirname "$0")/../common.sh"

require_cmd nmap "brew install nmap"
require_target "${1:-}"
safety_banner

TARGET="$1"

info "=== Nmap Examples ==="
info "Target: $TARGET"
echo ""

# 1. Quick host discovery (ping scan — no port scan)
info "1) Ping scan — is the host up?"
echo "   nmap -sn $TARGET"
echo ""

# 2. Fast top-100 port scan
info "2) Quick scan — top 100 ports"
echo "   nmap -F $TARGET"
echo ""

# 3. Service version detection on common ports
info "3) Service/version detection"
echo "   nmap -sV $TARGET"
echo ""

# 4. OS detection (requires root)
info "4) OS detection (requires sudo)"
echo "   sudo nmap -O $TARGET"
echo ""

# 5. Aggressive scan (OS + version + scripts + traceroute)
info "5) Aggressive scan (combines -O -sV -sC --traceroute)"
echo "   sudo nmap -A $TARGET"
echo ""

# 6. Full TCP port scan (all 65535 ports)
info "6) Full port scan (slow but thorough)"
echo "   nmap -p- $TARGET"
echo ""

# 7. UDP scan (requires root, slow)
info "7) UDP scan on common ports (requires sudo)"
echo "   sudo nmap -sU --top-ports 20 $TARGET"
echo ""

# 8. NSE vulnerability scripts
info "8) Run vulnerability detection scripts"
echo "   nmap --script vuln $TARGET"
echo ""

# 9. Scan a subnet
info "9) Scan an entire subnet"
echo "   nmap -sn 192.168.1.0/24"
echo ""

# 10. Save output in all formats
info "10) Save results (-oA = normal + XML + grepable)"
echo "    nmap -sV -oA scan-results $TARGET"
echo ""

# Run a basic demo scan
read -rp "Run a quick ping scan on $TARGET now? [y/N] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    info "Running: nmap -sn $TARGET"
    nmap -sn "$TARGET"
fi
