#!/usr/bin/env bash
# netcat/scan-ports.sh — Port scanning with netcat (nc -z)
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [target] [-h|--help]"
    echo ""
    echo "Description:"
    echo "  Demonstrates port scanning techniques using netcat's -z (scan) mode."
    echo "  Detects the installed nc variant and labels variant-specific flags."
    echo "  Default target is 127.0.0.1 if none is provided."
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")                 # Scan localhost"
    echo "  $(basename "$0") 192.168.1.1     # Scan specific host"
    echo "  $(basename "$0") 10.0.0.1        # Scan gateway"
    echo "  $(basename "$0") --help          # Show this help message"
}

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

require_cmd nc "apt install netcat-openbsd (Debian/Ubuntu) | brew install netcat (macOS)"

TARGET="${1:-127.0.0.1}"
NC_VARIANT=$(detect_nc_variant)

safety_banner

info "=== Port Scanning with Netcat ==="
info "Target: ${TARGET}"
info "Detected variant: ${NC_VARIANT}"
echo ""

info "Why use netcat for port scanning?"
echo "   Netcat's -z flag performs a lightweight port scan without sending data."
echo "   It's useful when nmap is not available or when you need a quick check"
echo "   to see if a specific service is reachable. It's pre-installed on most"
echo "   Unix systems, making it the go-to tool for ad-hoc connectivity tests."
echo ""

# 1. Scan a single port
info "1) Scan a single port"
echo "   nc -zv ${TARGET} 80"
echo ""

# 2. Scan a port range
info "2) Scan a port range (20 to 100)"
echo "   nc -zv ${TARGET} 20-100"
echo ""

# 3. Scan common web ports
info "3) Scan common web ports (80 and 443)"
echo "   nc -zv ${TARGET} 80; nc -zv ${TARGET} 443"
echo ""

# 4. Scan with a connection timeout
info "4) Scan with a connection timeout (-w seconds)"
echo "   nc -w 2 -zv ${TARGET} 22"
echo ""

# 5. UDP port scan
info "5) UDP port scan (-u flag)"
echo "   nc -zuv ${TARGET} 53"
echo ""

# 6. Verbose scan showing connection details
info "6) Verbose scan showing connection details"
echo "   nc -zv ${TARGET} 443"
echo ""

# 7. Scan top service ports one-by-one in a loop
info "7) Scan common service ports in a loop"
echo "   for port in 21 22 25 53 80 110 143 443 993 995 3306 5432 8080; do"
echo "       nc -zv -w 2 ${TARGET} \$port 2>&1"
echo "   done"
echo ""

# 8. Suppress DNS resolution for speed
info "8) Suppress DNS resolution for faster scanning (-n flag)"
echo "   nc -znv ${TARGET} 1-1024"
echo ""

# 9. Scan and filter for open ports
info "9) Scan and grep for open/succeeded ports"
echo "   nc -zv ${TARGET} 1-1024 2>&1 | grep -i 'succeeded\\|open'"
echo ""

# 10. Quick check if a specific service is running
info "10) Quick check if SSH (22), HTTP (80), HTTPS (443) are open"
echo "    for port in 22 80 443; do"
echo "        nc -zv -w 2 ${TARGET} \$port 2>&1 && echo \"Port \$port: OPEN\" || echo \"Port \$port: CLOSED\""
echo "    done"
echo ""

# Interactive demo (skip if non-interactive)
[[ ! -t 0 ]] && exit 0

read -rp "Run a quick port scan on ${TARGET} port 80? [y/N] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    info "Running: nc -zv ${TARGET} 80 -w 3"
    nc -zv "$TARGET" 80 -w 3 2>&1 || true
fi
