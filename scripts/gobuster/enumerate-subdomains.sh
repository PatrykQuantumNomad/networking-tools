#!/usr/bin/env bash
# ============================================================================
# @description  Discover subdomains via DNS brute-forcing
# @usage        gobuster/enumerate-subdomains.sh [target] [-h|--help] [-x|--execute] [-j|--json]
# @dependencies gobuster, common.sh
# ============================================================================
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [domain] [wordlist] [-h|--help] [-x|--execute] [-j|--json]"
    echo ""
    echo "Description:"
    echo "  Enumerates subdomains for a target domain using DNS brute-forcing"
    echo "  with gobuster. Discovers hidden services, staging environments,"
    echo "  and forgotten infrastructure."
    echo "  Default target is example.com if none is provided."
    echo ""
    echo "Options:"
    echo "  -h, --help       Show this help message"
    echo "  -j, --json       Output as JSON; add -x to run and capture results (requires jq)"
    echo "  -x, --execute    Run commands instead of displaying them"
    echo "  -v, --verbose    Increase verbosity"
    echo "  -q, --quiet      Suppress informational output"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")                                   # Enumerate example.com"
    echo "  $(basename "$0") target.com                        # Enumerate target.com"
    echo "  $(basename "$0") target.com /path/to/subdomains    # Use custom wordlist"
    echo "  $(basename "$0") -x target.com                     # Execute enumeration"
    echo "  $(basename "$0") --help                            # Show this help message"
}

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

require_cmd gobuster "brew install gobuster (or: go install github.com/OJ/gobuster/v3@latest)"

TARGET="${1:-example.com}"
WORDLIST="${2:-$PROJECT_ROOT/wordlists/subdomains-top1million-5000.txt}"

if [[ ! -f "$WORDLIST" ]]; then
    warn "Wordlist not found: ${WORDLIST}"
    info "Run: make wordlists   (downloads SecLists wordlists)"
    info "Or specify your own: $(basename "$0") <domain> <wordlist>"
    exit 1
fi

json_set_meta "gobuster" "$TARGET" "web-scanner"

confirm_execute "${1:-}"
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
run_or_show "1) Basic subdomain enumeration" \
    gobuster dns -do "$TARGET" -w "$WORDLIST" -t 10

# 2. Show CNAME and A records for each discovery
run_or_show "2) Show IP addresses for discovered subdomains" \
    gobuster dns -do "$TARGET" -w "$WORDLIST" --show-ips -t 10

# 3. Show CNAME records
run_or_show "3) Show CNAME records — reveal CDN and service mappings" \
    gobuster dns -do "$TARGET" -w "$WORDLIST" --show-cname -t 10

# 4. Use custom DNS resolver
run_or_show "4) Use custom DNS resolver — bypass local caching" \
    gobuster dns -do "$TARGET" -w "$WORDLIST" -r 8.8.8.8:53 -t 10

# 5. Use multiple resolvers for reliability
run_or_show "5) Use Cloudflare resolver — alternative DNS source" \
    gobuster dns -do "$TARGET" -w "$WORDLIST" -r 1.1.1.1:53 -t 10

# 6. Wildcard detection with verbose output
run_or_show "6) Verbose output — see all attempts including failures" \
    gobuster dns -do "$TARGET" -w "$WORDLIST" -v -t 10

# 7. Enumerate with larger wordlist
info "7) Thorough enumeration with larger wordlist"
echo "   gobuster dns -do ${TARGET} -w \${PROJECT_ROOT}/wordlists/subdomains-top1million-5000.txt -t 10"
echo ""
json_add_example "Thorough enumeration with larger wordlist" \
    "gobuster dns -do ${TARGET} -w \${PROJECT_ROOT}/wordlists/subdomains-top1million-5000.txt -t 10"

# 8. Save results to file
info "8) Save results to file for later analysis"
echo "   gobuster dns -do ${TARGET} -w ${WORDLIST} -o subdomain-results.txt -t 10"
echo ""
json_add_example "Save results to file for later analysis" \
    "gobuster dns -do ${TARGET} -w ${WORDLIST} -o subdomain-results.txt -t 10"

# 9. Quiet mode — only show discoveries
run_or_show "9) Quiet mode — only show discovered subdomains" \
    gobuster dns -do "$TARGET" -w "$WORDLIST" -q -t 10

# 10. Combined — resolver, IPs, and output file
info "10) Full enumeration — custom resolver, show IPs, save results"
echo "    gobuster dns -do ${TARGET} -w ${WORDLIST} -r 8.8.8.8:53 --show-ips -o subdomains.txt -t 10"
echo ""
json_add_example "Full enumeration — custom resolver, show IPs, save results" \
    "gobuster dns -do ${TARGET} -w ${WORDLIST} -r 8.8.8.8:53 --show-ips -o subdomains.txt -t 10"

json_finalize

# Interactive demo (skip if non-interactive)
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    [[ ! -t 0 ]] && exit 0

    read -rp "Run a subdomain scan against ${TARGET}? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        info "Running: gobuster dns -do ${TARGET} -w ${WORDLIST} -t 10"
        gobuster dns -do "$TARGET" -w "$WORDLIST" -t 10 || true
    fi
fi
