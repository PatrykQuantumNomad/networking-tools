#!/usr/bin/env bash
# gobuster/discover-directories.sh — Discover hidden directories and files on a web server
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [target] [wordlist] [-h|--help]"
    echo ""
    echo "Description:"
    echo "  Discovers hidden directories, files, and backup artifacts on a web"
    echo "  server using gobuster directory enumeration mode. Useful for finding"
    echo "  admin panels, configuration files, and forgotten backups."
    echo "  Default target is http://localhost:8080 (DVWA) if none is provided."
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")                                   # Scan DVWA with default wordlist"
    echo "  $(basename "$0") http://target.com                 # Scan with default wordlist"
    echo "  $(basename "$0") http://target.com /path/to/words  # Scan with custom wordlist"
    echo "  $(basename "$0") --help                            # Show this help message"
}

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

require_cmd gobuster "brew install gobuster (or: go install github.com/OJ/gobuster/v3@latest)"

TARGET="${1:-http://localhost:8080}"
WORDLIST="${2:-$PROJECT_ROOT/wordlists/common.txt}"

if [[ ! -f "$WORDLIST" ]]; then
    warn "Wordlist not found: ${WORDLIST}"
    info "Run: make wordlists   (downloads SecLists wordlists)"
    info "Or specify your own: $(basename "$0") <target> <wordlist>"
    exit 1
fi

safety_banner

info "=== Discover Directories ==="
info "Target: ${TARGET}"
info "Wordlist: ${WORDLIST}"
echo ""

info "Why enumerate directories?"
echo "   Web servers often host files and directories that are not linked from the"
echo "   main site but are still publicly accessible. These can include:"
echo "   - Admin panels (/admin, /manager, /dashboard)"
echo "   - Backup files (.bak, .old, .zip)"
echo "   - Configuration files (web.config, .env, .htaccess)"
echo "   - Development artifacts (/debug, /test, /staging)"
echo "   - API documentation (/swagger, /api-docs)"
echo "   Finding these is often the first step in web application testing."
echo ""

# 1. Basic directory scan
info "1) Basic directory scan with common wordlist"
echo "   gobuster dir -u ${TARGET} -w ${WORDLIST} -t 10"
echo ""

# 2. Search for specific file extensions
info "2) Search for PHP, HTML, and text files"
echo "   gobuster dir -u ${TARGET} -w ${WORDLIST} -x php,html,txt -t 10"
echo ""

# 3. Search for backup and config files
info "3) Search for backup and configuration files"
echo "   gobuster dir -u ${TARGET} -w ${WORDLIST} -x bak,old,zip,conf,config -t 10"
echo ""

# 4. Scan with expanded status codes
info "4) Show all non-404 responses — catch redirects and forbidden pages"
echo "   gobuster dir -u ${TARGET} -w ${WORDLIST} -b 404 -t 10"
echo ""

# 5. Follow redirects to see final destination
info "5) Follow redirects — see where 301/302 responses lead"
echo "   gobuster dir -u ${TARGET} -w ${WORDLIST} -r -t 10"
echo ""

# 6. Add custom User-Agent to avoid basic WAF blocks
info "6) Custom User-Agent — avoid basic WAF blocks"
echo "   gobuster dir -u ${TARGET} -w ${WORDLIST} -a \"Mozilla/5.0 (compatible; scanner)\" -t 10"
echo ""

# 7. Authenticated scan with cookie
info "7) Authenticated scan — pass session cookie"
echo "   gobuster dir -u ${TARGET} -w ${WORDLIST} -H \"Cookie: PHPSESSID=abc123\" -t 10"
echo ""

# 8. Scan with larger wordlist for thorough coverage
info "8) Thorough scan with larger wordlist"
echo "   gobuster dir -u ${TARGET} -w \${PROJECT_ROOT}/wordlists/directory-list-2.3-small.txt -t 10"
echo ""

# 9. Scan a specific subdirectory
info "9) Scan a specific subdirectory for deeper content"
echo "   gobuster dir -u ${TARGET}/admin/ -w ${WORDLIST} -x php,html -t 10"
echo ""

# 10. Save results to file for later review
info "10) Save results to file and show progress"
echo "    gobuster dir -u ${TARGET} -w ${WORDLIST} -o dir-results.txt -v -t 10"
echo ""

# Interactive demo
[[ -t 0 ]] || exit 0

read -rp "Run a basic directory scan against ${TARGET}? [y/N] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    info "Running: gobuster dir -u ${TARGET} -w ${WORDLIST} -t 10"
    gobuster dir -u "$TARGET" -w "$WORDLIST" -t 10 || true
fi
