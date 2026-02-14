#!/usr/bin/env bash
# ============================================================================
# @description  Discover hidden parameters and fuzz values with ffuf
# @usage        ffuf/fuzz-parameters.sh [target] [-h|--help] [-x|--execute] [-j|--json]
# @dependencies ffuf, common.sh
# ============================================================================
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [target] [wordlist] [-h|--help] [-j|--json]"
    echo ""
    echo "Description:"
    echo "  Discovers hidden GET/POST parameters and fuzzes parameter values"
    echo "  using ffuf. Useful for finding debug flags, admin toggles, IDOR"
    echo "  vulnerabilities, and undocumented API parameters."
    echo "  Default target is http://localhost:8080 (DVWA) if none is provided."
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")                                   # Fuzz DVWA with default wordlist"
    echo "  $(basename "$0") http://target.com                 # Fuzz with default wordlist"
    echo "  $(basename "$0") http://target.com /path/to/words  # Fuzz with custom wordlist"
    echo "  $(basename "$0") --help                            # Show this help message"
    echo ""
    echo "Flags:"
    echo "  -h, --help     Show this help message"
    echo "  -j, --json     Output results as JSON (requires jq)"
    echo "  -x, --execute  Execute commands instead of displaying them"
}

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

require_cmd ffuf "brew install ffuf (or: go install github.com/ffuf/ffuf/v2@latest)"

TARGET="${1:-http://localhost:8080}"
WORDLIST="${2:-$PROJECT_ROOT/wordlists/common.txt}"

if [[ ! -f "$WORDLIST" ]]; then
    warn "Wordlist not found: ${WORDLIST}"
    info "Run: make wordlists   (downloads SecLists wordlists)"
    info "Or specify your own: $(basename "$0") <target> <wordlist>"
    exit 1
fi

json_set_meta "ffuf" "$TARGET" "web-scanner"

confirm_execute "$TARGET"
safety_banner

info "=== Fuzz Parameters ==="
info "Target: ${TARGET}"
info "Wordlist: ${WORDLIST}"
echo ""

info "Why fuzz parameters?"
echo "   Web applications often have hidden parameters that are not visible in the UI:"
echo "   - Debug flags (?debug=true, ?verbose=1)"
echo "   - Admin toggles (?admin=1, ?role=admin)"
echo "   - IDOR vulnerabilities (?user_id=FUZZ, ?account=FUZZ)"
echo "   - Undocumented API parameters (?format=json, ?callback=FUZZ)"
echo "   - Legacy parameters left from development (?test=1, ?dev=true)"
echo "   Discovering these can reveal privilege escalation paths and hidden functionality."
echo ""

# 1. Discover GET parameters
run_or_show "1) Discover GET parameters — find hidden query parameters" \
    ffuf -u "$TARGET/page.php?FUZZ=test" -w "$WORDLIST" -fs 0 -t 10

# 2. Discover parameter values
run_or_show "2) Discover parameter values — fuzz a known parameter's value" \
    ffuf -u "$TARGET/page.php?id=FUZZ" -w "$WORDLIST" -fs 0 -t 10

# 3. POST parameter discovery
run_or_show "3) POST parameter discovery — find hidden form fields" \
    ffuf -u "$TARGET/login.php" -X POST -d "FUZZ=test" -w "$WORDLIST" -fs 0 -t 10

# 4. POST value fuzzing
run_or_show "4) POST value fuzzing — brute-force a known parameter" \
    ffuf -u "$TARGET/login.php" -X POST -d "username=admin&password=FUZZ" -w "$WORDLIST" -fc 401 -t 10

# 5. Filter by response code to remove redirects
run_or_show "5) Filter by response code — remove redirect noise" \
    ffuf -u "$TARGET/page.php?FUZZ=test" -w "$WORDLIST" -fc 302 -t 10

# 6. Filter by response size to remove noise
run_or_show "6) Filter by response size — remove default page responses" \
    ffuf -u "$TARGET/page.php?FUZZ=test" -w "$WORDLIST" -fs 4242 -t 10

# 7. Filter by word count for consistent responses
run_or_show "7) Filter by word count — remove pages with same word count" \
    ffuf -u "$TARGET/page.php?FUZZ=test" -w "$WORDLIST" -fw 42 -t 10

# 8. Match by response line count
run_or_show "8) Match by line count — find responses with specific line counts" \
    ffuf -u "$TARGET/page.php?FUZZ=test" -w "$WORDLIST" -ml 100 -t 10

# 9. JSON POST fuzzing
run_or_show "9) JSON POST fuzzing — discover JSON API parameters" \
    ffuf -u "$TARGET/api/endpoint" -X POST -H "Content-Type: application/json" -d '{"FUZZ":"test"}' -w "$WORDLIST" -fs 0 -t 10

# 10. Combine parameter name and value fuzzing
run_or_show "10) Combine name + value fuzzing — test parameter names and values together" \
    ffuf -u "$TARGET/page.php?FUZZ=FUZ2" -w "$WORDLIST:FUZZ" -w "$WORDLIST:FUZ2" -fs 0 -t 10

json_finalize

# Interactive demo (skip if non-interactive)
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    [[ ! -t 0 ]] && exit 0

    read -rp "Run a GET parameter discovery against ${TARGET}? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        info "Running: ffuf -u ${TARGET}/FUZZ -w ${WORDLIST} -t 10"
        ffuf -u "${TARGET}/FUZZ" -w "$WORDLIST" -t 10 || true
    fi
fi
