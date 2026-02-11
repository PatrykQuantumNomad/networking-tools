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
}

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

require_cmd nikto "brew install nikto"
require_target "${1:-}"

confirm_execute "${1:-}"
safety_banner

TARGET="$1"

info "=== Nikto Examples ==="
info "Target: ${TARGET}"
echo ""

# 1. Basic web server scan
run_or_show "1) Basic scan" \
    nikto -h "$TARGET"

# 2. Scan specific port
run_or_show "2) Scan on a specific port" \
    nikto -h "$TARGET" -p 8080

# 3. Scan multiple ports
run_or_show "3) Scan multiple ports" \
    nikto -h "$TARGET" -p 80,443,8080

# 4. SSL/TLS scan
run_or_show "4) Force SSL mode" \
    nikto -h "$TARGET" -ssl

# 5. Save output to file
run_or_show "5) Save results in HTML format" \
    nikto -h "$TARGET" -o report.html -Format html

# 6. Use specific tuning (test types)
info "6) Scan only for specific vulnerability types"
echo "   nikto -h ${TARGET} -Tuning 1234"
echo "   # 1=Files, 2=Misconfig, 3=Info, 4=XSS"
echo "   # 5=RFI, 6=DOS, 7=RCE, 8=Injection, 9=SQLi, 0=Upload"
echo ""

# 7. Use a proxy
run_or_show "7) Scan through a proxy" \
    nikto -h "$TARGET" -useproxy http://127.0.0.1:8080

# 8. Update vulnerability database
run_or_show "8) Update Nikto databases" \
    nikto -update

# 9. Authenticated scan with cookies
run_or_show "9) Scan with authentication" \
    nikto -h "$TARGET" -id admin:password

# 10. Evasion techniques
info "10) Use evasion techniques against IDS"
echo "    nikto -h ${TARGET} -evasion 1"
echo "    # 1=Random URI, 2=Self-ref, 3=Premature end, 4=Long URL"
echo ""

# Interactive demo (skip if non-interactive)
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    [[ ! -t 0 ]] && exit 0
    read -rp "Run a basic scan against ${TARGET} now? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        info "Running: nikto -h ${TARGET}"
        nikto -h "$TARGET" || true
    fi
fi
