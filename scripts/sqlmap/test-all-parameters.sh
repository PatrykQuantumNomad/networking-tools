#!/usr/bin/env bash
# ============================================================================
# @description  Thoroughly test all parameters for SQL injection
# @usage        sqlmap/test-all-parameters.sh [target] [-h|--help] [-x|--execute]
# @dependencies sqlmap, common.sh
# ============================================================================
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [target-url] [-h|--help] [-x|--execute]"
    echo ""
    echo "Description:"
    echo "  Demonstrates how to thoroughly test all parameters in an HTTP request"
    echo "  for SQL injection using sqlmap. Covers level/risk tuning, POST data,"
    echo "  cookies, headers, and saved request files."
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")                                                    # Show testing techniques"
    echo "  $(basename "$0") 'http://localhost:8080/vuln.php?id=1'              # Target a URL"
    echo "  $(basename "$0") -x 'http://localhost:8080/vuln.php?id=1'           # Execute against target"
    echo "  $(basename "$0") --help                                             # Show this help message"
}

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

require_cmd sqlmap "brew install sqlmap"

TARGET="${1:-}"

json_set_meta "sqlmap" "$TARGET" "sql-injection"

confirm_execute "${1:-}"
safety_banner

info "=== Parameter Testing for SQL Injection ==="
if [[ -n "$TARGET" ]]; then
    info "Target: ${TARGET}"
fi
echo ""

info "Understanding --level and --risk"
echo "   --level (1-5) controls WHICH parameters sqlmap tests:"
echo "   Level 1: Default — GET and POST parameters only"
echo "   Level 2: + Cookie parameters"
echo "   Level 3: + User-Agent and Referer headers"
echo "   Level 4: + more payload variations"
echo "   Level 5: + all HTTP headers, maximum payloads"
echo ""
echo "   --risk (1-3) controls WHAT payloads sqlmap sends:"
echo "   Risk 1: Default — safe, no modifications to data"
echo "   Risk 2: + time-based blind payloads (heavy queries)"
echo "   Risk 3: + OR-based payloads (can modify data!)"
echo ""
echo "   Higher level = more thorough but slower."
echo "   Higher risk = more payloads but may alter data."
echo ""

URL="${TARGET:-'http://target/page.php?id=1'}"

# 1. Basic test (default level/risk)
run_or_show "1) Basic test with default level/risk" \
    sqlmap -u "$URL" --batch

# 2. Test all parameters with high level
run_or_show "2) Test all parameters with maximum level and risk" \
    sqlmap -u "$URL" --batch --level=5 --risk=3

# 3. Test POST request data
run_or_show "3) Test POST request data" \
    sqlmap -u "$URL" --data="user=test&pass=test" --batch

# 4. Test from saved HTTP request file
info "4) Test from a saved HTTP request file"
echo "   sqlmap -r request.txt --batch"
echo ""
json_add_example "Test from a saved HTTP request file" \
    "sqlmap -r request.txt --batch"

# 5. Test specific parameter only
run_or_show "5) Test a specific parameter only" \
    sqlmap -u "$URL" --batch -p id

# 6. Test cookies for SQLi
run_or_show "6) Test cookies for SQL injection (requires level 2+)" \
    sqlmap -u "$URL" --cookie="PHPSESSID=abc123" --batch --level=2

# 7. Test HTTP headers for SQLi
run_or_show "7) Test HTTP headers for SQL injection (level 5)" \
    sqlmap -u "$URL" --batch --level=5 --headers="X-Forwarded-For: 1*"

# 8. Test with authentication
run_or_show "8) Test with authentication cookies" \
    sqlmap -u "$URL" --cookie="security=low; PHPSESSID=abc123" --batch

# 9. Use specific DBMS to speed up testing
run_or_show "9) Specify DBMS to skip fingerprinting and speed up testing" \
    sqlmap -u "$URL" --batch --dbms=mysql

# 10. Verbose output for debugging
run_or_show "10) Verbose output for debugging failed detections" \
    sqlmap -u "$URL" --batch -v 3 --level=3

json_finalize

# Interactive demo (skip if non-interactive)
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    [[ ! -t 0 ]] && exit 0

    echo ""
    info "How to capture a request for sqlmap from your browser:"
    echo ""
    echo "   1. Open browser DevTools (F12 or Cmd+Option+I)"
    echo "   2. Go to the Network tab"
    echo "   3. Submit the form or click the link you want to test"
    echo "   4. Right-click the request > Copy > Copy as cURL"
    echo "   5. Or: Right-click > Copy > Copy request headers"
    echo ""
    echo "   To save as a request file for sqlmap -r:"
    echo "   1. In DevTools Network tab, click the request"
    echo "   2. Copy the raw request (method, URL, headers, body)"
    echo "   3. Save to a .txt file in this format:"
    echo ""
    echo "   GET /vuln.php?id=1 HTTP/1.1"
    echo "   Host: target.com"
    echo "   Cookie: PHPSESSID=abc123; security=low"
    echo ""
fi
