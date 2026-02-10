#!/usr/bin/env bash
# skipfish/quick-scan-web-app.sh — Fast, time-limited web application scan for initial recon
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

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

require_cmd skipfish "sudo port install skipfish"

TARGET="${1:-http://localhost:3030}"

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
info "1) Quick scan with depth limit"
echo "   skipfish -o output/ -d 2 ${TARGET}"
echo ""

# 2. Limit total requests
info "2) Limit total requests"
echo "   skipfish -o output/ -c 500 ${TARGET}"
echo ""

# 3. Limit max connections
info "3) Limit max connections"
echo "   skipfish -o output/ -m 10 ${TARGET}"
echo ""

# 4. Learning-only mode (passive)
info "4) Learning-only mode — passive crawl, no active tests"
echo "   skipfish -o output/ -L ${TARGET}"
echo ""

# 5. Scan specific path only
info "5) Scan specific path only"
echo "   skipfish -o output/ ${TARGET}/api/"
echo ""

# 6. Quick scan with time limit
info "6) Quick scan with time limit (5 minutes)"
echo "   skipfish -o output/ -t 300 ${TARGET}"
echo ""

# 7. Low bandwidth mode
info "7) Low bandwidth mode — minimal footprint"
echo "   skipfish -o output/ -l 5 -m 5 ${TARGET}"
echo ""

# 8. Scan without brute-force
info "8) Scan without brute-force dictionary"
echo "   skipfish -o output/ -W /dev/null ${TARGET}"
echo ""

# 9. Quick scan with request and depth limits combined
info "9) Quick scan — depth 2, max 200 requests"
echo "   skipfish -o output/ -d 2 -c 200 ${TARGET}"
echo ""

# 10. Scan multiple targets quickly
info "10) Scan multiple lab targets quickly"
echo "    for t in 8080 3030 8888; do skipfish -o \"output_\${t}/\" -d 2 -c 100 \"http://localhost:\${t}\"; done"
echo ""

# Interactive demo (skip if non-interactive)
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
