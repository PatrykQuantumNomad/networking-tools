#!/usr/bin/env bash
# ffuf/fuzz-parameters.sh — Discover hidden parameters and fuzz values with ffuf
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [target] [wordlist] [-h|--help]"
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
}

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

require_cmd ffuf "brew install ffuf (or: go install github.com/ffuf/ffuf/v2@latest)"

TARGET="${1:-http://localhost:8080}"
WORDLIST="${2:-$PROJECT_ROOT/wordlists/common.txt}"

if [[ ! -f "$WORDLIST" ]]; then
    warn "Wordlist not found: ${WORDLIST}"
    info "Run: make wordlists   (downloads SecLists wordlists)"
    info "Or specify your own: $(basename "$0") <target> <wordlist>"
    exit 1
fi

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
info "1) Discover GET parameters — find hidden query parameters"
echo "   ffuf -u \"${TARGET}/page.php?FUZZ=test\" -w ${WORDLIST} -fs 0 -t 10"
echo ""

# 2. Discover parameter values
info "2) Discover parameter values — fuzz a known parameter's value"
echo "   ffuf -u \"${TARGET}/page.php?id=FUZZ\" -w ${WORDLIST} -fs 0 -t 10"
echo ""

# 3. POST parameter discovery
info "3) POST parameter discovery — find hidden form fields"
echo "   ffuf -u ${TARGET}/login.php -X POST -d \"FUZZ=test\" -w ${WORDLIST} -fs 0 -t 10"
echo ""

# 4. POST value fuzzing
info "4) POST value fuzzing — brute-force a known parameter"
echo "   ffuf -u ${TARGET}/login.php -X POST -d \"username=admin&password=FUZZ\" -w ${WORDLIST} -fc 401 -t 10"
echo ""

# 5. Filter by response code to remove redirects
info "5) Filter by response code — remove redirect noise"
echo "   ffuf -u \"${TARGET}/page.php?FUZZ=test\" -w ${WORDLIST} -fc 302 -t 10"
echo ""

# 6. Filter by response size to remove noise
info "6) Filter by response size — remove default page responses"
echo "   ffuf -u \"${TARGET}/page.php?FUZZ=test\" -w ${WORDLIST} -fs 4242 -t 10"
echo ""

# 7. Filter by word count for consistent responses
info "7) Filter by word count — remove pages with same word count"
echo "   ffuf -u \"${TARGET}/page.php?FUZZ=test\" -w ${WORDLIST} -fw 42 -t 10"
echo ""

# 8. Match by response line count
info "8) Match by line count — find responses with specific line counts"
echo "   ffuf -u \"${TARGET}/page.php?FUZZ=test\" -w ${WORDLIST} -ml 100 -t 10"
echo ""

# 9. JSON POST fuzzing
info "9) JSON POST fuzzing — discover JSON API parameters"
echo "   ffuf -u ${TARGET}/api/endpoint -X POST -H \"Content-Type: application/json\" -d '{\"FUZZ\":\"test\"}' -w ${WORDLIST} -fs 0 -t 10"
echo ""

# 10. Combine parameter name and value fuzzing
info "10) Combine name + value fuzzing — test parameter names and values together"
echo "    ffuf -u \"${TARGET}/page.php?FUZZ=FUZ2\" -w ${WORDLIST}:FUZZ -w ${WORDLIST}:FUZ2 -fs 0 -t 10"
echo ""

# Interactive demo
[[ -t 0 ]] || exit 0

read -rp "Run a GET parameter discovery against ${TARGET}? [y/N] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    info "Running: ffuf -u ${TARGET}/FUZZ -w ${WORDLIST} -t 10"
    ffuf -u "${TARGET}/FUZZ" -w "$WORDLIST" -t 10 || true
fi
