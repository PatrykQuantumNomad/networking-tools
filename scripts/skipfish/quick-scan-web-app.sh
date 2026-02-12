#!/usr/bin/env bash
# ============================================================================
# @description  Fast, time-limited web application scan for initial recon
# @usage        skipfish/quick-scan-web-app.sh [target] [-h|--help] [-x|--execute]
# @dependencies skipfish, common.sh
# ============================================================================
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [target] [-h|--help]"
    echo ""
    echo "Description:"
    echo "  Runs fast, time-limited skipfish scans for initial reconnaissance."
    echo "  Full scans can take hours — these settings limit depth, requests,"
    echo "  and connections for quick results. Default target: http://localhost:3030"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")                          # Quick scan Juice Shop"
    echo "  $(basename "$0") http://192.168.1.1:8080  # Quick scan a target"
    echo "  $(basename "$0") --help                   # Show this help message"
}

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

require_cmd skipfish "sudo port install skipfish"

TARGET="${1:-http://localhost:3030}"

confirm_execute "$TARGET"
safety_banner

info "=== Skipfish Quick Web App Scanning ==="
info "Target: ${TARGET}"
echo ""

info "Why use quick scan settings?"
echo "   A full skipfish scan can run for hours or even days on large apps."
echo "   For CTFs, initial recon, or demos, you want speed over thoroughness."
echo "   Quick scan strategies:"
echo "     - Limit crawl depth (-d):  Fewer levels = faster"
echo "     - Limit total requests (-c): Cap the number of probes"
echo "     - Limit connections (-m):  Fewer parallel connections"
echo "     - Skip brute-force (-W /dev/null): No dictionary attacks"
echo "     - Time limit (-t): Hard stop after N seconds"
echo ""

# 1. Quick scan with depth limit
run_or_show "1) Quick scan with depth limit" \
    skipfish -o output/ -d 2 "$TARGET"

# 2. Limit total requests
run_or_show "2) Limit total requests" \
    skipfish -o output/ -c 500 "$TARGET"

# 3. Limit max connections
run_or_show "3) Limit max connections" \
    skipfish -o output/ -m 10 "$TARGET"

# 4. Learning-only mode (passive)
run_or_show "4) Learning-only mode — passive crawl, no active tests" \
    skipfish -o output/ -L "$TARGET"

# 5. Scan specific path only
run_or_show "5) Scan specific path only" \
    skipfish -o output/ "$TARGET/api/"

# 6. Quick scan with time limit
run_or_show "6) Quick scan with time limit (5 minutes)" \
    skipfish -o output/ -t 300 "$TARGET"

# 7. Low bandwidth mode
run_or_show "7) Low bandwidth mode — minimal footprint" \
    skipfish -o output/ -l 5 -m 5 "$TARGET"

# 8. Scan without brute-force
run_or_show "8) Scan without brute-force dictionary" \
    skipfish -o output/ -W /dev/null "$TARGET"

# 9. Quick scan with request and depth limits combined
run_or_show "9) Quick scan — depth 2, max 200 requests" \
    skipfish -o output/ -d 2 -c 200 "$TARGET"

# 10. Scan multiple targets quickly
info "10) Scan multiple lab targets quickly"
echo "    for t in 8080 3030 8888; do skipfish -o \"output_\${t}/\" -d 2 -c 100 \"http://localhost:\${t}\"; done"
echo ""

# Interactive demo (skip if non-interactive)
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    [[ ! -t 0 ]] && exit 0

    read -rp "Run a very quick scan (-d 2 -c 100) against ${TARGET}? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        OUTDIR="/tmp/skipfish_quick_$(date +%s)"
        info "Running: skipfish -o ${OUTDIR} -d 2 -c 100 ${TARGET}"
        echo ""
        skipfish -o "$OUTDIR" -d 2 -c 100 "$TARGET"
        echo ""
        info "Results saved to: ${OUTDIR}"
    fi
fi
