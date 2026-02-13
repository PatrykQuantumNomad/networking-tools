#!/usr/bin/env bash
# ============================================================================
# @description  Per-hop latency analysis using mtr
# @usage        traceroute/diagnose-latency.sh [target] [-h|--help] [-x|--execute]
# @dependencies mtr, common.sh
# ============================================================================
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [target] [-h|--help] [-x|--execute]"
    echo ""
    echo "Description:"
    echo "  Analyzes per-hop latency using mtr (My Traceroute). Shows loss,"
    echo "  average/best/worst latency, and jitter for every hop between you"
    echo "  and the destination. Requires sudo on macOS."
    echo "  Default target is example.com if none is provided."
    echo ""
    echo "Options:"
    echo "  -h, --help       Show this help message"
    echo "  -x, --execute    Run commands instead of displaying them"
    echo "  -v, --verbose    Increase verbosity"
    echo "  -q, --quiet      Suppress informational output"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")                       # Analyze latency to example.com"
    echo "  $(basename "$0") 8.8.8.8               # Analyze latency to Google DNS"
    echo "  sudo $(basename "$0") example.com      # Required on macOS"
    echo "  $(basename "$0") -x example.com        # Execute mtr reports"
    echo "  $(basename "$0") --help                # Show this help message"
}

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

require_cmd mtr "apt install mtr (Debian/Ubuntu) | dnf install mtr (RHEL/Fedora) | brew install mtr (macOS)"

TARGET="${1:-example.com}"
OS_TYPE="$(uname -s)"

json_set_meta "traceroute" "$TARGET" "network-analysis"

# mtr sudo detection (TOOL-018): warn and exit on macOS without sudo
if [[ "$OS_TYPE" == "Darwin" ]] && [[ $EUID -ne 0 ]]; then
    warn "mtr requires sudo on macOS (raw socket access)"
    info "Re-run with: sudo $0 ${TARGET}"
    exit 1
fi

confirm_execute "${1:-}"
safety_banner

info "=== Diagnose Latency ==="
info "Target: ${TARGET}"
echo ""

info "Why per-hop latency matters:"
echo "   High latency at a single hop can indicate congestion, routing issues,"
echo "   or geographic distance. mtr shows statistics for EVERY hop, letting"
echo "   you pinpoint exactly where delays occur. Look for sudden jumps in"
echo "   average latency or packet loss above 0%."
echo ""

# 1. Basic mtr report
run_or_show "1) Basic mtr report — 10 cycles with per-hop statistics" \
    mtr --report -c 10 "$TARGET"

# 2. Wide report with full hostnames
run_or_show "2) Wide report — show full hostnames (not truncated)" \
    mtr --report --report-wide -c 10 "$TARGET"

# 3. No DNS resolution for faster results
run_or_show "3) No DNS resolution — faster results, IP addresses only" \
    mtr --report -n -c 10 "$TARGET"

# 4. 20 cycles for more accurate stats
run_or_show "4) 20 cycles — more accurate statistics" \
    mtr --report -c 20 "$TARGET"

# 5. Limit to 20 hops
run_or_show "5) Limit to 20 hops maximum" \
    mtr --report -m 20 -c 10 "$TARGET"

# 6. UDP mode — default protocol
run_or_show "6) UDP mode — default mtr probe protocol" \
    mtr --report --udp -c 10 "$TARGET"

# 7. TCP mode on port 80
run_or_show "7) TCP mode on port 80 — test HTTP path" \
    mtr --report --tcp --port 80 -c 10 "$TARGET"

# 8. Custom report fields
run_or_show "8) Custom report fields — loss, sent, avg, worst, stdev" \
    mtr --report -o "LSAWDV" -c 10 "$TARGET"

# 9. Set packet size to 1024 bytes
run_or_show "9) Set packet size to 1024 bytes — test with larger packets" \
    mtr --report -s 1024 -c 10 "$TARGET"

# 10. Compare two destinations side by side
info "10) Compare two destinations — run reports sequentially"
echo "    mtr --report -n -c 10 ${TARGET}"
echo "    mtr --report -n -c 10 8.8.8.8"
echo "    Tip: compare loss% and avg latency at each hop"
echo ""
json_add_example "Compare two destinations — run reports sequentially" \
    "mtr --report -n -c 10 ${TARGET} && mtr --report -n -c 10 8.8.8.8"

json_finalize

# Interactive demo (skip if non-interactive)
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    [[ ! -t 0 ]] && exit 0

    read -rp "Run mtr report to ${TARGET} (5 cycles, ~5 seconds)? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        info "Running: mtr --report -n -c 5 ${TARGET}"
        mtr --report -n -c 5 "$TARGET"
    fi
fi
