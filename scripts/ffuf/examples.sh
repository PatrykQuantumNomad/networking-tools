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

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

require_cmd ffuf "brew install ffuf (or: go install github.com/ffuf/ffuf/v2@latest)"
require_target "${1:-}"

confirm_execute "${1:-}"
safety_banner

TARGET="$1"

info "=== ffuf Examples ==="
info "Target: ${TARGET}"
echo ""

info "Note: ffuf replaces the keyword FUZZ in URLs, headers, and POST data"
info "with each entry from the wordlist. Position FUZZ wherever you want to test."
echo ""

# 1. Basic directory fuzzing
run_or_show "1) Basic directory fuzzing" \
    ffuf -u "$TARGET/FUZZ" -w wordlists/common.txt -t 10

# 2. Filter by status code — only show 200 and 301
run_or_show "2) Filter by status code — only show 200 and 301 responses" \
    ffuf -u "$TARGET/FUZZ" -w wordlists/common.txt -mc 200,301 -t 10

# 3. Filter by response size to remove noise
run_or_show "3) Filter by response size — remove false positives" \
    ffuf -u "$TARGET/FUZZ" -w wordlists/common.txt -fs 4242 -t 10

# 4. Auto-calibration to automatically filter common responses
run_or_show "4) Auto-calibration — automatically filter common responses" \
    ffuf -u "$TARGET/FUZZ" -w wordlists/common.txt -ac -t 10

# 5. GET parameter fuzzing
run_or_show "5) GET parameter fuzzing — discover hidden parameters" \
    ffuf -u "$TARGET/page.php?FUZZ=test" -w wordlists/common.txt -fs 0 -t 10

# 6. POST data fuzzing
run_or_show "6) POST data fuzzing — brute-force login passwords" \
    ffuf -u "$TARGET/login.php" -X POST -d "username=admin&password=FUZZ" -w wordlists/rockyou.txt -fc 401 -t 10

# 7. Header fuzzing for virtual host discovery
run_or_show "7) Header fuzzing — discover virtual hosts via Host header" \
    ffuf -u "$TARGET" -H "Host: FUZZ.example.com" -w wordlists/subdomains-top1million-5000.txt -fs 0 -t 10

# 8. Multiple wordlists with FUZZ and FUZ2
run_or_show "8) Multiple wordlists — combine directory and extension fuzzing" \
    ffuf -u "$TARGET/FUZZ" -w wordlists/common.txt:FUZZ -w wordlists/extensions.txt:FUZ2 -t 10

# 9. Output to file in JSON format
run_or_show "9) Output results to JSON file for later analysis" \
    ffuf -u "$TARGET/FUZZ" -w wordlists/common.txt -o results.json -of json -t 10

# 10. Rate limiting to avoid overwhelming targets
run_or_show "10) Rate limiting — limit requests per second" \
    ffuf -u "$TARGET/FUZZ" -w wordlists/common.txt -rate 50 -t 10

# Interactive demo (skip if non-interactive)
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    [[ ! -t 0 ]] && exit 0

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
fi
