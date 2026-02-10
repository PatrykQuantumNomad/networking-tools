#!/usr/bin/env bash
# nikto/scan-with-auth.sh — Perform authenticated Nikto scans using credentials or cookies
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [target] [-h|--help]"
    echo ""
    echo "Description:"
    echo "  Performs authenticated Nikto scans using HTTP Basic Auth, cookies,"
    echo "  or custom headers. Authenticated scans find more vulnerabilities by"
    echo "  accessing restricted pages. Default target: http://localhost:8080"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")                          # Scan DVWA on localhost"
    echo "  $(basename "$0") http://192.168.1.1:8080  # Scan a specific target"
    echo "  $(basename "$0") --help                   # Show this help message"
}

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

require_cmd nikto "brew install nikto"

TARGET="${1:-http://localhost:8080}"

safety_banner

info "=== Nikto Authenticated Scanning ==="
info "Target: ${TARGET}"
echo ""

info "Why authenticate before scanning?"
echo "   An unauthenticated scan only sees the login page and public content."
echo "   Authenticated scans access:"
echo "     - Admin panels and settings pages"
echo "     - User dashboards and profile pages"
echo "     - File upload forms and management interfaces"
echo "     - API endpoints requiring auth tokens"
echo "   This typically doubles or triples the attack surface found."
echo ""

# 1. HTTP Basic Authentication
info "1) HTTP Basic Authentication"
echo "   nikto -h ${TARGET} -id admin:password"
echo ""

# 2. Cookie-based authentication
info "2) Cookie-based authentication"
echo "   nikto -h ${TARGET} -C \"PHPSESSID=abc123; security=low\""
echo ""

# 3. Custom header authentication
info "3) Custom header authentication (Bearer token)"
echo "   nikto -h ${TARGET} -H \"Authorization: Bearer token123\""
echo ""

# 4. Scan DVWA with low security
info "4) Scan DVWA with low security setting"
echo "   nikto -h http://localhost:8080 -C \"security=low; PHPSESSID=SESSION\""
echo ""

# 5. Multiple cookies combined
info "5) Multiple cookies combined"
echo "   nikto -h ${TARGET} -C \"session=abc; role=admin; csrf_token=xyz\""
echo ""

# 6. Authenticated scan with specific tuning
info "6) Authenticated scan with specific tuning (SQLi + XSS + Injection)"
echo "   nikto -h ${TARGET} -id admin:password -Tuning 249"
echo ""

# 7. Follow redirects during auth scan
info "7) Follow redirects during authenticated scan"
echo "   nikto -h ${TARGET} -id admin:password -followredirects"
echo ""

# 8. Authenticated scan saving output
info "8) Authenticated scan saving HTML report"
echo "   nikto -h ${TARGET} -id admin:password -output auth_scan.html -Format htm"
echo ""

# 9. Use a proxy to capture authenticated traffic
info "9) Use a proxy to capture authenticated traffic (e.g., Burp Suite)"
echo "   nikto -h ${TARGET} -id admin:password -useproxy http://127.0.0.1:8080"
echo ""

# 10. Digest authentication
info "10) Digest authentication"
echo "    nikto -h ${TARGET} -id admin:password -authtype digest"
echo ""

# Interactive demo (skip if non-interactive)
[[ ! -t 0 ]] && exit 0

if [[ "$TARGET" == *"localhost:8080"* || "$TARGET" == *"127.0.0.1:8080"* ]]; then
    read -rp "Run a quick authenticated scan against DVWA (admin:password)? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        info "Running: nikto -h ${TARGET} -id admin:password -Tuning 2 -maxtime 60s"
        echo ""
        nikto -h "$TARGET" -id admin:password -Tuning 2 -maxtime 60s || true
    fi
else
    read -rp "Run a quick authenticated scan against ${TARGET}? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        info "Running: nikto -h ${TARGET} -id admin:password -Tuning 2 -maxtime 60s"
        echo ""
        nikto -h "$TARGET" -id admin:password -Tuning 2 -maxtime 60s || true
    fi
fi
