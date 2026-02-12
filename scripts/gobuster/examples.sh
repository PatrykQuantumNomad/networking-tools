#!/usr/bin/env bash
# ============================================================================
# @description  Directory and subdomain brute-force examples using gobuster
# @usage        gobuster/examples.sh <target> [-h|--help] [-v|--verbose] [-x|--execute]
# @dependencies gobuster, common.sh
# ============================================================================
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

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

require_cmd gobuster "brew install gobuster (or: go install github.com/OJ/gobuster/v3@latest)"
require_target "${1:-}"

confirm_execute "${1:-}"
safety_banner

TARGET="$1"

info "=== Gobuster Examples ==="
info "Target: ${TARGET}"
echo ""

# 1. Basic directory enumeration
run_or_show "1) Basic directory enumeration" \
    gobuster dir -u "$TARGET" -w wordlists/common.txt -t 10

# 2. Directory enumeration with file extensions
run_or_show "2) Directory enumeration with file extensions" \
    gobuster dir -u "$TARGET" -w wordlists/common.txt -x php,html,txt -t 10

# 3. Filter by status codes — only show 200 and 301
run_or_show "3) Filter by status codes — only show 200 and 301 responses" \
    gobuster dir -u "$TARGET" -w wordlists/common.txt -s 200,301 -t 10

# 4. Larger wordlist for thorough scanning
run_or_show "4) Larger wordlist for thorough scanning" \
    gobuster dir -u "$TARGET" -w wordlists/directory-list-2.3-small.txt -t 10

# 5. Hide specific status codes
run_or_show "5) Hide specific status codes — suppress 404 and 403 responses" \
    gobuster dir -u "$TARGET" -w wordlists/common.txt -b 404,403 -t 10

# 6. Add custom headers (cookies/auth)
run_or_show "6) Add custom headers — pass cookies or auth tokens" \
    gobuster dir -u "$TARGET" -w wordlists/common.txt -H "Cookie: session=abc123" -t 10

# 7. DNS subdomain enumeration
run_or_show "7) DNS subdomain enumeration" \
    gobuster dns -do example.com -w wordlists/subdomains-top1million-5000.txt -t 10

# 8. DNS with custom resolver
run_or_show "8) DNS subdomain enumeration with custom resolver" \
    gobuster dns -do example.com -w wordlists/subdomains-top1million-5000.txt -r 8.8.8.8:53 -t 10

# 9. Virtual host discovery
run_or_show "9) Virtual host discovery — find vhosts on a web server" \
    gobuster vhost -u "$TARGET" --append-domain -w wordlists/subdomains-top1million-5000.txt -t 10

# 10. Save output to file
run_or_show "10) Save output to file for later analysis" \
    gobuster dir -u "$TARGET" -w wordlists/common.txt -o gobuster-results.txt -t 10

# Interactive demo (skip if non-interactive)
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    [[ ! -t 0 ]] && exit 0

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
fi
