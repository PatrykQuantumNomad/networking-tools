#!/usr/bin/env bash
# sqlmap/test-all-parameters.sh — Thoroughly test all parameters for SQL injection
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [target-url] [-h|--help]"
    echo ""
    echo "Description:"
    echo "  Demonstrates how to thoroughly test all parameters in an HTTP request"
    echo "  for SQL injection using sqlmap. Covers level/risk tuning, POST data,"
    echo "  cookies, headers, and saved request files."
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")                                                    # Show testing techniques"
    echo "  $(basename "$0") 'http://localhost:8080/vuln.php?id=1'              # Target a URL"
    echo "  $(basename "$0") --help                                             # Show this help message"
}

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

require_cmd sqlmap "brew install sqlmap"

TARGET="${1:-}"

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
info "1) Basic test with default level/risk"
echo "   sqlmap -u ${URL} --batch"
echo ""

# 2. Test all parameters with high level
info "2) Test all parameters with maximum level and risk"
echo "   sqlmap -u ${URL} --batch --level=5 --risk=3"
echo ""

# 3. Test POST request data
info "3) Test POST request data"
echo "   sqlmap -u ${URL} --data=\"user=test&pass=test\" --batch"
echo ""

# 4. Test from saved HTTP request file
info "4) Test from a saved HTTP request file"
echo "   sqlmap -r request.txt --batch"
echo ""

# 5. Test specific parameter only
info "5) Test a specific parameter only"
echo "   sqlmap -u ${URL} --batch -p id"
echo ""

# 6. Test cookies for SQLi
info "6) Test cookies for SQL injection (requires level 2+)"
echo "   sqlmap -u ${URL} --cookie=\"PHPSESSID=abc123\" --batch --level=2"
echo ""

# 7. Test HTTP headers for SQLi
info "7) Test HTTP headers for SQL injection (level 5)"
echo "   sqlmap -u ${URL} --batch --level=5 --headers=\"X-Forwarded-For: 1*\""
echo ""

# 8. Test with authentication
info "8) Test with authentication cookies"
echo "   sqlmap -u ${URL} --cookie=\"security=low; PHPSESSID=abc123\" --batch"
echo ""

# 9. Use specific DBMS to speed up testing
info "9) Specify DBMS to skip fingerprinting and speed up testing"
echo "   sqlmap -u ${URL} --batch --dbms=mysql"
echo ""

# 10. Verbose output for debugging
info "10) Verbose output for debugging failed detections"
echo "    sqlmap -u ${URL} --batch -v 3 --level=3"
echo ""

# Interactive demo (skip if non-interactive, e.g. running via make)
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
