#!/usr/bin/env bash
# gobuster/enumerate-subdomains.sh — Discover subdomains via DNS brute-forcing
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [domain] [wordlist] [-h|--help]"
    echo ""
    echo "Description:"
    echo "  Enumerates subdomains for a target domain using DNS brute-forcing"
    echo "  with gobuster. Discovers hidden services, staging environments,"
    echo "  and forgotten infrastructure."
    echo "  Default target is example.com if none is provided."
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")                                   # Enumerate example.com"
    echo "  $(basename "$0") target.com                        # Enumerate target.com"
    echo "  $(basename "$0") target.com /path/to/subdomains    # Use custom wordlist"
    echo "  $(basename "$0") --help                            # Show this help message"
}

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

require_cmd gobuster "brew install gobuster (or: go install github.com/OJ/gobuster/v3@latest)"

TARGET="${1:-example.com}"
WORDLIST="${2:-$PROJECT_ROOT/wordlists/subdomains-top1million-5000.txt}"

if [[ ! -f "$WORDLIST" ]]; then
    warn "Wordlist not found: ${WORDLIST}"
    info "Run: make wordlists   (downloads SecLists wordlists)"
    info "Or specify your own: $(basename "$0") <domain> <wordlist>"
    exit 1
fi

safety_banner

info "=== Enumerate Subdomains ==="
info "Target: ${TARGET}"
info "Wordlist: ${WORDLIST}"
echo ""

info "Why enumerate subdomains?"
echo "   Organizations often run services on subdomains that are not publicly listed:"
echo "   - Staging/dev environments (staging.target.com, dev.target.com)"
echo "   - Internal tools (jira.target.com, jenkins.target.com)"
echo "   - Forgotten services (old.target.com, test.target.com)"
echo "   - Mail and API servers (mail.target.com, api.target.com)"
echo "   Each discovered subdomain expands the attack surface and may reveal"
echo "   less-hardened services or sensitive data."
echo ""

# 1. Basic subdomain enumeration
info "1) Basic subdomain enumeration"
echo "   gobuster dns -do ${TARGET} -w ${WORDLIST} -t 10"
echo ""

# 2. Show CNAME and A records for each discovery
info "2) Show IP addresses for discovered subdomains"
echo "   gobuster dns -do ${TARGET} -w ${WORDLIST} --show-ips -t 10"
echo ""

# 3. Show CNAME records
info "3) Show CNAME records — reveal CDN and service mappings"
echo "   gobuster dns -do ${TARGET} -w ${WORDLIST} --show-cname -t 10"
echo ""

# 4. Use custom DNS resolver
info "4) Use custom DNS resolver — bypass local caching"
echo "   gobuster dns -do ${TARGET} -w ${WORDLIST} -r 8.8.8.8:53 -t 10"
echo ""

# 5. Use multiple resolvers for reliability
info "5) Use Cloudflare resolver — alternative DNS source"
echo "   gobuster dns -do ${TARGET} -w ${WORDLIST} -r 1.1.1.1:53 -t 10"
echo ""

# 6. Wildcard detection with verbose output
info "6) Verbose output — see all attempts including failures"
echo "   gobuster dns -do ${TARGET} -w ${WORDLIST} -v -t 10"
echo ""

# 7. Enumerate with larger wordlist
info "7) Thorough enumeration with larger wordlist"
echo "   gobuster dns -do ${TARGET} -w \${PROJECT_ROOT}/wordlists/subdomains-top1million-5000.txt -t 10"
echo ""

# 8. Save results to file
info "8) Save results to file for later analysis"
echo "   gobuster dns -do ${TARGET} -w ${WORDLIST} -o subdomain-results.txt -t 10"
echo ""

# 9. Quiet mode — only show discoveries
info "9) Quiet mode — only show discovered subdomains"
echo "   gobuster dns -do ${TARGET} -w ${WORDLIST} -q -t 10"
echo ""

# 10. Combined — resolver, IPs, and output file
info "10) Full enumeration — custom resolver, show IPs, save results"
echo "    gobuster dns -do ${TARGET} -w ${WORDLIST} -r 8.8.8.8:53 --show-ips -o subdomains.txt -t 10"
echo ""

# Interactive demo
[[ -t 0 ]] || exit 0

read -rp "Run a subdomain scan against ${TARGET}? [y/N] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    info "Running: gobuster dns -do ${TARGET} -w ${WORDLIST} -t 10"
    gobuster dns -do "$TARGET" -w "$WORDLIST" -t 10 || true
fi
