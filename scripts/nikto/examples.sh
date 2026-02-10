#!/usr/bin/env bash
# nikto/examples.sh — Web server vulnerability scanner
source "$(dirname "$0")/../common.sh"

show_help() {
    cat <<'EOF'
Usage: examples.sh <target>

Description:
  Nikto - Web server vulnerability scanner examples.
  Displays common nikto commands and optionally runs a basic scan.

Examples:
  examples.sh http://example.com
  examples.sh https://10.0.0.1:8443
EOF
    exit 0
}

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help

require_cmd nikto "brew install nikto"
require_target "${1:-}"
safety_banner

TARGET="$1"

info "=== Nikto Examples ==="
info "Target: ${TARGET}"
echo ""

# 1. Basic web server scan
info "1) Basic scan"
echo "   nikto -h ${TARGET}"
echo ""

# 2. Scan specific port
info "2) Scan on a specific port"
echo "   nikto -h ${TARGET} -p 8080"
echo ""

# 3. Scan multiple ports
info "3) Scan multiple ports"
echo "   nikto -h ${TARGET} -p 80,443,8080"
echo ""

# 4. SSL/TLS scan
info "4) Force SSL mode"
echo "   nikto -h ${TARGET} -ssl"
echo ""

# 5. Save output to file
info "5) Save results in HTML format"
echo "   nikto -h ${TARGET} -o report.html -Format html"
echo ""

# 6. Use specific tuning (test types)
info "6) Scan only for specific vulnerability types"
echo "   nikto -h ${TARGET} -Tuning 1234"
echo "   # 1=Files, 2=Misconfig, 3=Info, 4=XSS"
echo "   # 5=RFI, 6=DOS, 7=RCE, 8=Injection, 9=SQLi, 0=Upload"
echo ""

# 7. Use a proxy
info "7) Scan through a proxy"
echo "   nikto -h ${TARGET} -useproxy http://127.0.0.1:8080"
echo ""

# 8. Update vulnerability database
info "8) Update Nikto databases"
echo "   nikto -update"
echo ""

# 9. Authenticated scan with cookies
info "9) Scan with authentication"
echo "   nikto -h ${TARGET} -id admin:password"
echo ""

# 10. Evasion techniques
info "10) Use evasion techniques against IDS"
echo "    nikto -h ${TARGET} -evasion 1"
echo "    # 1=Random URI, 2=Self-ref, 3=Premature end, 4=Long URL"
echo ""

[[ -t 0 ]] || exit 0
read -rp "Run a basic scan against ${TARGET} now? [y/N] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    info "Running: nikto -h ${TARGET}"
    nikto -h "$TARGET" || true
fi
