#!/usr/bin/env bash
# skipfish/scan-authenticated-app.sh — Scan web applications with authentication
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [target] [-h|--help]"
    echo ""
    echo "Description:"
    echo "  Performs authenticated skipfish scans using session cookies, HTTP"
    echo "  Basic Auth, or custom headers. Authenticated scans discover far more"
    echo "  of the attack surface. Default target: http://localhost:8080"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")                          # Scan DVWA on localhost"
    echo "  $(basename "$0") http://192.168.1.1:8080  # Scan a specific target"
    echo "  $(basename "$0") --help                   # Show this help message"
}

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

require_cmd skipfish "sudo port install skipfish"

TARGET="${1:-http://localhost:8080}"

safety_banner

info "=== Skipfish Authenticated Scanning ==="
info "Target: ${TARGET}"
echo ""

info "Why authenticate before scanning?"
echo "   Unauthenticated scans miss most of the attack surface:"
echo "     - Admin panels, user dashboards, settings pages"
echo "     - File upload forms, management interfaces"
echo "     - API endpoints behind auth middleware"
echo "   Authenticated scans typically find 2-3x more vulnerabilities."
echo ""
echo "   How to get session cookies:"
echo "     1. Log in to the app in your browser"
echo "     2. Open DevTools (F12) -> Application -> Cookies"
echo "     3. Copy the session cookie value (e.g., PHPSESSID)"
echo "     4. Pass it to skipfish with -C flag"
echo ""

# 1. Scan with session cookie
info "1) Scan with session cookie"
echo "   skipfish -o output/ -C \"PHPSESSID=abc123\" ${TARGET}"
echo ""

# 2. Scan with multiple cookies
info "2) Scan with multiple cookies"
echo "   skipfish -o output/ -C \"PHPSESSID=abc123\" -C \"security=low\" ${TARGET}"
echo ""

# 3. Form-based authentication
info "3) Form-based authentication"
echo "   skipfish -o output/ --auth-form ${TARGET}/login --auth-user admin --auth-pass password ${TARGET}"
echo ""

# 4. Custom header authentication
info "4) Custom header authentication (Bearer token)"
echo "   skipfish -o output/ -H \"Authorization: Bearer token123\" ${TARGET}"
echo ""

# 5. Exclude logout pages (stay authenticated)
info "5) Exclude logout pages to stay authenticated"
echo "   skipfish -o output/ -C \"PHPSESSID=abc123\" -X /logout -X /signout ${TARGET}"
echo ""

# 6. Include only specific paths
info "6) Include only specific paths (admin/dashboard)"
echo "   skipfish -o output/ -C \"PHPSESSID=abc123\" -I /admin -I /dashboard ${TARGET}"
echo ""

# 7. Scan with authentication + depth limit
info "7) Authenticated scan with depth limit"
echo "   skipfish -o output/ -C \"PHPSESSID=abc123\" -d 3 ${TARGET}"
echo ""

# 8. Authenticated scan with custom wordlist
info "8) Authenticated scan with custom wordlist"
echo "   skipfish -o output/ -C \"PHPSESSID=abc123\" -W /path/to/wordlist.txt ${TARGET}"
echo ""

# 9. Rate-limited authenticated scan
info "9) Rate-limited authenticated scan"
echo "   skipfish -o output/ -C \"PHPSESSID=abc123\" -l 10 ${TARGET}"
echo ""

# 10. Full DVWA authenticated scan
info "10) Full DVWA authenticated scan"
echo "    skipfish -o dvwa_scan/ -C \"PHPSESSID=SESSION; security=low\" -d 3 http://localhost:8080"
echo ""

# Interactive demo (skip if non-interactive)
[[ ! -t 0 ]] && exit 0

info "To scan DVWA with authentication, follow these steps:"
echo ""
echo "   1. Start DVWA:  make lab-up"
echo "   2. Open browser: http://localhost:8080"
echo "   3. Log in with:  admin / password"
echo "   4. Open DevTools (F12) -> Application -> Cookies"
echo "   5. Copy the PHPSESSID value"
echo "   6. Run:"
echo "      skipfish -o dvwa_scan/ -C \"PHPSESSID=YOUR_SESSION; security=low\" -d 2 http://localhost:8080"
echo ""
read -rp "Would you like to see the exact command for your session cookie? [y/N] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    read -rp "Paste your PHPSESSID cookie value: " session_cookie
    if [[ -n "$session_cookie" ]]; then
        info "Run this command:"
        echo "   skipfish -o dvwa_scan/ -C \"PHPSESSID=${session_cookie}; security=low\" -d 2 ${TARGET}"
    else
        warn "No cookie provided. Log in to DVWA first and copy the PHPSESSID."
    fi
fi
