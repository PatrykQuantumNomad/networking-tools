#!/usr/bin/env bash
# ============================================================================
# @description  Discover hidden directories and files on a web server
# @usage        gobuster/discover-directories.sh [target] [-h|--help] [-x|--execute]
# @dependencies gobuster, common.sh
# ============================================================================
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [target] [wordlist] [-h|--help] [-x|--execute]"
    echo ""
    echo "Description:"
    echo "  Discovers hidden directories, files, and backup artifacts on a web"
    echo "  server using gobuster directory enumeration mode. Useful for finding"
    echo "  admin panels, configuration files, and forgotten backups."
    echo "  Default target is http://localhost:8080 (DVWA) if none is provided."
    echo ""
    echo "Options:"
    echo "  -h, --help       Show this help message"
    echo "  -x, --execute    Run commands instead of displaying them"
    echo "  -v, --verbose    Increase verbosity"
    echo "  -q, --quiet      Suppress informational output"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")                                   # Scan DVWA with default wordlist"
    echo "  $(basename "$0") http://target.com                 # Scan with default wordlist"
    echo "  $(basename "$0") http://target.com /path/to/words  # Scan with custom wordlist"
    echo "  $(basename "$0") -x http://target.com              # Execute scan against target"
    echo "  $(basename "$0") --help                            # Show this help message"
}

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

require_cmd gobuster "brew install gobuster (or: go install github.com/OJ/gobuster/v3@latest)"

TARGET="${1:-http://localhost:8080}"
WORDLIST="${2:-$PROJECT_ROOT/wordlists/common.txt}"

if [[ ! -f "$WORDLIST" ]]; then
    warn "Wordlist not found: ${WORDLIST}"
    info "Run: make wordlists   (downloads SecLists wordlists)"
    info "Or specify your own: $(basename "$0") <target> <wordlist>"
    exit 1
fi

json_set_meta "gobuster" "$TARGET" "web-scanner"

confirm_execute "${1:-}"
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
run_or_show "1) Basic directory scan with common wordlist" \
    gobuster dir -u "$TARGET" -w "$WORDLIST" -t 10

# 2. Search for specific file extensions
run_or_show "2) Search for PHP, HTML, and text files" \
    gobuster dir -u "$TARGET" -w "$WORDLIST" -x php,html,txt -t 10

# 3. Search for backup and config files
run_or_show "3) Search for backup and configuration files" \
    gobuster dir -u "$TARGET" -w "$WORDLIST" -x bak,old,zip,conf,config -t 10

# 4. Scan with expanded status codes
run_or_show "4) Show all non-404 responses — catch redirects and forbidden pages" \
    gobuster dir -u "$TARGET" -w "$WORDLIST" -b 404 -t 10

# 5. Follow redirects to see final destination
run_or_show "5) Follow redirects — see where 301/302 responses lead" \
    gobuster dir -u "$TARGET" -w "$WORDLIST" -r -t 10

# 6. Add custom User-Agent to avoid basic WAF blocks
run_or_show "6) Custom User-Agent — avoid basic WAF blocks" \
    gobuster dir -u "$TARGET" -w "$WORDLIST" -a "Mozilla/5.0 (compatible; scanner)" -t 10

# 7. Authenticated scan with cookie
run_or_show "7) Authenticated scan — pass session cookie" \
    gobuster dir -u "$TARGET" -w "$WORDLIST" -H "Cookie: PHPSESSID=abc123" -t 10

# 8. Scan with larger wordlist for thorough coverage
info "8) Thorough scan with larger wordlist"
echo "   gobuster dir -u ${TARGET} -w \${PROJECT_ROOT}/wordlists/directory-list-2.3-small.txt -t 10"
echo ""
json_add_example "Thorough scan with larger wordlist" \
    "gobuster dir -u ${TARGET} -w \${PROJECT_ROOT}/wordlists/directory-list-2.3-small.txt -t 10"

# 9. Scan a specific subdirectory
run_or_show "9) Scan a specific subdirectory for deeper content" \
    gobuster dir -u "$TARGET/admin/" -w "$WORDLIST" -x php,html -t 10

# 10. Save results to file for later review
info "10) Save results to file and show progress"
echo "    gobuster dir -u ${TARGET} -w ${WORDLIST} -o dir-results.txt -v -t 10"
echo ""
json_add_example "Save results to file and show progress" \
    "gobuster dir -u ${TARGET} -w ${WORDLIST} -o dir-results.txt -v -t 10"

json_finalize

# Interactive demo (skip if non-interactive)
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    [[ ! -t 0 ]] && exit 0

    read -rp "Run a basic directory scan against ${TARGET}? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        info "Running: gobuster dir -u ${TARGET} -w ${WORDLIST} -t 10"
        gobuster dir -u "$TARGET" -w "$WORDLIST" -t 10 || true
    fi
fi
