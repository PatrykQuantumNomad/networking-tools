#!/usr/bin/env bash
# ============================================================================
# @description  Scan web servers for known vulnerabilities using NSE
# @usage        nmap/scan-web-vulnerabilities.sh [target] [-h|--help] [-x|--execute] [-j|--json]
# @dependencies nmap, common.sh
# ============================================================================
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [target] [-h|--help] [-j|--json]"
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
    echo ""
    echo "Flags:"
    echo "  -h, --help     Show this help message"
    echo "  -j, --json     Output as JSON; add -x to run and capture results (requires jq)"
    echo "  -x, --execute  Execute commands instead of displaying them"
}

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

require_cmd nmap "brew install nmap"

TARGET="${1:-localhost}"

json_set_meta "nmap" "$TARGET" "network-scanner"

confirm_execute "${1:-}"
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
run_or_show "1) Run all vulnerability scripts on web ports" \
    nmap -p80,443 --script vuln "$TARGET"

# 2. Directory enumeration
run_or_show "2) Enumerate web directories and files" \
    nmap -p80,8080 --script http-enum "$TARGET"

# 3. HTTP methods
run_or_show "3) Check allowed HTTP methods" \
    nmap -p80 --script http-methods "$TARGET"

# 4. WAF detection
run_or_show "4) Detect web app firewalls" \
    nmap -p80 --script http-waf-detect "$TARGET"

# 5. Shellshock
run_or_show "5) Check for Shellshock vulnerability" \
    nmap -p80 --script http-shellshock "$TARGET"

# 6. SQL injection
run_or_show "6) Find SQL injection points" \
    nmap -p80 --script http-sql-injection "$TARGET"

# 7. Heartbleed
run_or_show "7) Detect heartbleed on HTTPS" \
    nmap -p443 --script ssl-heartbleed "$TARGET"

# 8. Security headers
run_or_show "8) Full HTTP security header check" \
    nmap -p80 --script http-security-headers "$TARGET"

# 9. Server info
run_or_show "9) Enumerate web server info + headers" \
    nmap -sV -p80,443,8080 --script http-headers,http-title "$TARGET"

# 10. Comprehensive scan
run_or_show "10) Comprehensive: all web vuln scripts + service detection" \
    sudo nmap -sV -p80,443,8080,8443 --script "http-vuln-* or http-enum or http-methods" "$TARGET"

json_finalize

# Interactive demo (skip if non-interactive)
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
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
fi
