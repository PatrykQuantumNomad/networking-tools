#!/usr/bin/env bash
# skipfish/examples.sh — Web application security scanner
source "$(dirname "$0")/../common.sh"

show_help() {
    cat <<'EOF'
Usage: examples.sh <target>

Description:
  Skipfish - Web application security scanner examples.
  Displays common skipfish commands and optionally runs a basic scan.

Examples:
  examples.sh http://example.com
  examples.sh http://10.0.0.1:8080/app
EOF
    exit 0
}

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help

require_cmd skipfish "brew install skipfish"
require_target "${1:-}"
safety_banner

TARGET="$1"

info "=== Skipfish Examples ==="
info "Target: ${TARGET}"
echo ""

# 1. Basic scan
info "1) Basic web application scan"
echo "   skipfish -o skipfish-output ${TARGET}"
echo ""

# 2. Scan with custom wordlist
info "2) Scan with a dictionary"
echo "   skipfish -o output -S /usr/share/skipfish/dictionaries/complete.wl ${TARGET}"
echo ""

# 3. Limit scan depth
info "3) Limit crawl depth"
echo "   skipfish -o output -d 3 ${TARGET}"
echo ""

# 4. Limit max requests per second
info "4) Rate-limit the scan"
echo "   skipfish -o output -l 10 ${TARGET}"
echo ""

# 5. Scan specific paths only
info "5) Restrict to specific path"
echo "   skipfish -o output -I /api/ ${TARGET}"
echo ""

# 6. Skip specific paths
info "6) Exclude paths from scan"
echo "   skipfish -o output -X /logout ${TARGET}"
echo ""

# 7. Authenticated scan with cookies
info "7) Scan with authentication cookie"
echo "   skipfish -o output -C 'session=abc123' ${TARGET}"
echo ""

# 8. Scan with custom headers
info "8) Add custom headers"
echo "   skipfish -o output -H 'Authorization: Bearer <token>' ${TARGET}"
echo ""

# 9. Timeout settings
info "9) Set connection and request timeouts"
echo "   skipfish -o output -t 30 ${TARGET}"
echo ""

# 10. View results
info "10) Results are saved as an HTML report"
echo "    open skipfish-output/index.html"
echo ""

[[ -t 0 ]] || exit 0
read -rp "Run a basic scan against ${TARGET} now? [y/N] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    output_dir="$PROJECT_ROOT/skipfish-output"
    info "Running: skipfish -o $output_dir -d 2 -l 5 ${TARGET}"
    skipfish -o "$output_dir" -d 2 -l 5 "$TARGET"
fi
