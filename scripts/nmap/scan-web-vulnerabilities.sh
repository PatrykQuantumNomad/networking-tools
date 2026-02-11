#!/usr/bin/env bash
# nmap/scan-web-vulnerabilities.sh — Scan web servers for known vulnerabilities using NSE
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [target] [-h|--help]"
    echo ""
    echo "Description:"
    echo "  Scans web servers for known vulnerabilities using Nmap Scripting Engine (NSE)."
    echo "  Covers directory enumeration, HTTP methods, WAF detection, and specific CVEs."
    echo "  Default target is localhost if none is provided."
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")              # Scan localhost web ports"
    echo "  $(basename "$0") 192.168.1.1  # Scan a remote web server"
    echo "  $(basename "$0") --help       # Show this help message"
}

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

require_cmd nmap "brew install nmap"

TARGET="${1:-localhost}"

safety_banner

info "=== Web Vulnerability Scanning with NSE ==="
info "Target: ${TARGET}"
echo ""

info "What is the Nmap Scripting Engine (NSE)?"
echo "   NSE extends nmap with Lua scripts for vulnerability detection."
echo "   Scripts are organized into categories:"
echo "   - vuln:      Check for known vulnerabilities (CVEs)"
echo "   - exploit:   Attempt to exploit vulnerabilities"
echo "   - auth:      Test authentication and credentials"
echo "   - discovery: Enumerate services, directories, and info"
echo ""
echo "   --script vuln runs ALL vulnerability detection scripts."
echo "   You can also target specific scripts by name."
echo ""

# 1. All vulnerability scripts
info "1) Run all vulnerability scripts on web ports"
echo "   nmap -p80,443 --script vuln ${TARGET}"
echo ""

# 2. Directory enumeration
info "2) Enumerate web directories and files"
echo "   nmap -p80,8080 --script http-enum ${TARGET}"
echo ""

# 3. HTTP methods
info "3) Check allowed HTTP methods"
echo "   nmap -p80 --script http-methods ${TARGET}"
echo ""

# 4. WAF detection
info "4) Detect web app firewalls"
echo "   nmap -p80 --script http-waf-detect ${TARGET}"
echo ""

# 5. Shellshock
info "5) Check for Shellshock vulnerability"
echo "   nmap -p80 --script http-shellshock ${TARGET}"
echo ""

# 6. SQL injection
info "6) Find SQL injection points"
echo "   nmap -p80 --script http-sql-injection ${TARGET}"
echo ""

# 7. Heartbleed
info "7) Detect heartbleed on HTTPS"
echo "   nmap -p443 --script ssl-heartbleed ${TARGET}"
echo ""

# 8. Security headers
info "8) Full HTTP security header check"
echo "   nmap -p80 --script http-security-headers ${TARGET}"
echo ""

# 9. Server info
info "9) Enumerate web server info + headers"
echo "   nmap -sV -p80,443,8080 --script http-headers,http-title ${TARGET}"
echo ""

# 10. Comprehensive scan
info "10) Comprehensive: all web vuln scripts + service detection"
echo "    sudo nmap -sV -p80,443,8080,8443 --script \"http-vuln-* or http-enum or http-methods\" ${TARGET}"
echo ""

# Interactive demo (skip if non-interactive)
[[ ! -t 0 ]] && exit 0

if [[ "$TARGET" == "localhost" || "$TARGET" == "127.0.0.1" ]]; then
    read -rp "Scan lab ports (8080,3000,8888,8180) with http-enum? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        info "Running: nmap -p8080,3000,8888,8180 --script http-enum ${TARGET}"
        echo ""
        nmap -p8080,3000,8888,8180 --script http-enum "$TARGET"
    fi
else
    read -rp "Scan ${TARGET} port 80 with http-enum? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        info "Running: nmap -p80 --script http-enum ${TARGET}"
        echo ""
        nmap -p80 --script http-enum "$TARGET"
    fi
fi
