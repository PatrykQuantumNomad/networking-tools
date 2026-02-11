#!/usr/bin/env bash
# ffuf/examples.sh — Web fuzzing examples using ffuf (Fuzz Faster U Fool)
source "$(dirname "$0")/../common.sh"

show_help() {
    cat <<EOF
Usage: $(basename "$0") <target>

ffuf - Web fuzzing examples

Displays common ffuf commands for the given target URL
and optionally runs a quick directory fuzzing demo.

Examples:
    $(basename "$0") http://localhost:8080
    $(basename "$0") http://example.com
EOF
}

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

require_cmd ffuf "brew install ffuf (or: go install github.com/ffuf/ffuf/v2@latest)"
require_target "${1:-}"
safety_banner

TARGET="$1"

info "=== ffuf Examples ==="
info "Target: ${TARGET}"
echo ""

info "Note: ffuf replaces the keyword FUZZ in URLs, headers, and POST data"
info "with each entry from the wordlist. Position FUZZ wherever you want to test."
echo ""

# 1. Basic directory fuzzing
info "1) Basic directory fuzzing"
echo "   ffuf -u ${TARGET}/FUZZ -w wordlists/common.txt -t 10"
echo ""

# 2. Filter by status code — only show 200 and 301
info "2) Filter by status code — only show 200 and 301 responses"
echo "   ffuf -u ${TARGET}/FUZZ -w wordlists/common.txt -mc 200,301 -t 10"
echo ""

# 3. Filter by response size to remove noise
info "3) Filter by response size — remove false positives"
echo "   ffuf -u ${TARGET}/FUZZ -w wordlists/common.txt -fs 4242 -t 10"
echo ""

# 4. Auto-calibration to automatically filter common responses
info "4) Auto-calibration — automatically filter common responses"
echo "   ffuf -u ${TARGET}/FUZZ -w wordlists/common.txt -ac -t 10"
echo ""

# 5. GET parameter fuzzing
info "5) GET parameter fuzzing — discover hidden parameters"
echo "   ffuf -u \"${TARGET}/page.php?FUZZ=test\" -w wordlists/common.txt -fs 0 -t 10"
echo ""

# 6. POST data fuzzing
info "6) POST data fuzzing — brute-force login passwords"
echo "   ffuf -u ${TARGET}/login.php -X POST -d \"username=admin&password=FUZZ\" -w wordlists/rockyou.txt -fc 401 -t 10"
echo ""

# 7. Header fuzzing for virtual host discovery
info "7) Header fuzzing — discover virtual hosts via Host header"
echo "   ffuf -u ${TARGET} -H \"Host: FUZZ.example.com\" -w wordlists/subdomains-top1million-5000.txt -fs 0 -t 10"
echo ""

# 8. Multiple wordlists with FUZZ and FUZ2
info "8) Multiple wordlists — combine directory and extension fuzzing"
echo "   ffuf -u ${TARGET}/FUZZ -w wordlists/common.txt:FUZZ -w wordlists/extensions.txt:FUZ2 -t 10"
echo ""

# 9. Output to file in JSON format
info "9) Output results to JSON file for later analysis"
echo "   ffuf -u ${TARGET}/FUZZ -w wordlists/common.txt -o results.json -of json -t 10"
echo ""

# 10. Rate limiting to avoid overwhelming targets
info "10) Rate limiting — limit requests per second"
echo "    ffuf -u ${TARGET}/FUZZ -w wordlists/common.txt -rate 50 -t 10"
echo ""

# Interactive demo
[[ -t 0 ]] || exit 0

WORDLIST="${PROJECT_ROOT}/wordlists/common.txt"
if [[ ! -f "$WORDLIST" ]]; then
    warn "Wordlist not found: ${WORDLIST}"
    info "Run: make wordlists   (downloads SecLists wordlists)"
    exit 0
fi

read -rp "Run a basic directory fuzz against ${TARGET}? [y/N] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    info "Running: ffuf -u ${TARGET}/FUZZ -w ${WORDLIST} -t 10"
    ffuf -u "${TARGET}/FUZZ" -w "$WORDLIST" -t 10 || true
fi
