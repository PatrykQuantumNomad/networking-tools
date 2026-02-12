#!/usr/bin/env bash
# ============================================================================
# @description  Web application security scanner examples using skipfish
# @usage        skipfish/examples.sh <target> [-h|--help] [-v|--verbose] [-x|--execute]
# @dependencies skipfish, common.sh
# ============================================================================
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
}

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

require_cmd skipfish "brew install skipfish"
require_target "${1:-}"

confirm_execute "${1:-}"
safety_banner

TARGET="$1"

info "=== Skipfish Examples ==="
info "Target: ${TARGET}"
echo ""

# 1. Basic scan
run_or_show "1) Basic web application scan" \
    skipfish -o skipfish-output "$TARGET"

# 2. Scan with custom wordlist
run_or_show "2) Scan with a dictionary" \
    skipfish -o output -S /usr/share/skipfish/dictionaries/complete.wl "$TARGET"

# 3. Limit scan depth
run_or_show "3) Limit crawl depth" \
    skipfish -o output -d 3 "$TARGET"

# 4. Limit max requests per second
run_or_show "4) Rate-limit the scan" \
    skipfish -o output -l 10 "$TARGET"

# 5. Scan specific paths only
run_or_show "5) Restrict to specific path" \
    skipfish -o output -I /api/ "$TARGET"

# 6. Skip specific paths
run_or_show "6) Exclude paths from scan" \
    skipfish -o output -X /logout "$TARGET"

# 7. Authenticated scan with cookies
run_or_show "7) Scan with authentication cookie" \
    skipfish -o output -C 'session=abc123' "$TARGET"

# 8. Scan with custom headers
run_or_show "8) Add custom headers" \
    skipfish -o output -H 'Authorization: Bearer <token>' "$TARGET"

# 9. Timeout settings
run_or_show "9) Set connection and request timeouts" \
    skipfish -o output -t 30 "$TARGET"

# 10. View results
info "10) Results are saved as an HTML report"
echo "    open skipfish-output/index.html"
echo ""

# Interactive demo (skip if non-interactive)
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    [[ ! -t 0 ]] && exit 0
    read -rp "Run a basic scan against ${TARGET} now? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        output_dir="$PROJECT_ROOT/skipfish-output"
        info "Running: skipfish -o $output_dir -d 2 -l 5 ${TARGET}"
        skipfish -o "$output_dir" -d 2 -l 5 "$TARGET"
    fi
fi
