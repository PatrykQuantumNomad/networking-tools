#!/usr/bin/env bash
# gobuster/examples.sh — Web content discovery and enumeration examples
source "$(dirname "$0")/../common.sh"

show_help() {
    cat <<EOF
Usage: $(basename "$0") <target>

gobuster - Web content discovery and enumeration examples

Displays common gobuster commands for the given target URL
and optionally runs a quick directory scan demo.

Examples:
    $(basename "$0") http://localhost:8080
    $(basename "$0") http://example.com
EOF
}

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

require_cmd gobuster "brew install gobuster (or: go install github.com/OJ/gobuster/v3@latest)"
require_target "${1:-}"
safety_banner

TARGET="$1"

info "=== Gobuster Examples ==="
info "Target: ${TARGET}"
echo ""

# 1. Basic directory enumeration
info "1) Basic directory enumeration"
echo "   gobuster dir -u ${TARGET} -w wordlists/common.txt -t 10"
echo ""

# 2. Directory enumeration with file extensions
info "2) Directory enumeration with file extensions"
echo "   gobuster dir -u ${TARGET} -w wordlists/common.txt -x php,html,txt -t 10"
echo ""

# 3. Filter by status codes — only show 200 and 301
info "3) Filter by status codes — only show 200 and 301 responses"
echo "   gobuster dir -u ${TARGET} -w wordlists/common.txt -s 200,301 -t 10"
echo ""

# 4. Larger wordlist for thorough scanning
info "4) Larger wordlist for thorough scanning"
echo "   gobuster dir -u ${TARGET} -w wordlists/directory-list-2.3-small.txt -t 10"
echo ""

# 5. Hide specific status codes
info "5) Hide specific status codes — suppress 404 and 403 responses"
echo "   gobuster dir -u ${TARGET} -w wordlists/common.txt -b 404,403 -t 10"
echo ""

# 6. Add custom headers (cookies/auth)
info "6) Add custom headers — pass cookies or auth tokens"
echo "   gobuster dir -u ${TARGET} -w wordlists/common.txt -H \"Cookie: session=abc123\" -t 10"
echo ""

# 7. DNS subdomain enumeration
info "7) DNS subdomain enumeration"
echo "   gobuster dns -d example.com -w wordlists/subdomains-top1million-5000.txt -t 10"
echo ""

# 8. DNS with custom resolver
info "8) DNS subdomain enumeration with custom resolver"
echo "   gobuster dns -d example.com -w wordlists/subdomains-top1million-5000.txt -r 8.8.8.8:53 -t 10"
echo ""

# 9. Virtual host discovery
info "9) Virtual host discovery — find vhosts on a web server"
echo "   gobuster vhost -u ${TARGET} --append-domain -w wordlists/subdomains-top1million-5000.txt -t 10"
echo ""

# 10. Save output to file
info "10) Save output to file for later analysis"
echo "    gobuster dir -u ${TARGET} -w wordlists/common.txt -o gobuster-results.txt -t 10"
echo ""

# Interactive demo
[[ -t 0 ]] || exit 0

WORDLIST="${PROJECT_ROOT}/wordlists/common.txt"
if [[ ! -f "$WORDLIST" ]]; then
    warn "Wordlist not found: ${WORDLIST}"
    info "Run: make wordlists   (downloads SecLists wordlists)"
    exit 0
fi

read -rp "Run a basic directory scan against ${TARGET}? [y/N] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    info "Running: gobuster dir -u ${TARGET} -w ${WORDLIST} -t 10"
    gobuster dir -u "$TARGET" -w "$WORDLIST" -t 10 || true
fi
