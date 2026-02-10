#!/usr/bin/env bash
# traceroute/diagnose-latency.sh — Per-hop latency analysis using mtr
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [target] [-h|--help]"
    echo ""
    echo "Description:"
    echo "  Analyzes per-hop latency using mtr (My Traceroute). Shows loss,"
    echo "  average/best/worst latency, and jitter for every hop between you"
    echo "  and the destination. Requires sudo on macOS."
    echo "  Default target is example.com if none is provided."
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")                       # Analyze latency to example.com"
    echo "  $(basename "$0") 8.8.8.8               # Analyze latency to Google DNS"
    echo "  sudo $(basename "$0") example.com      # Required on macOS"
    echo "  $(basename "$0") --help                # Show this help message"
}

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

require_cmd mtr "apt install mtr (Debian/Ubuntu) | dnf install mtr (RHEL/Fedora) | brew install mtr (macOS)"

TARGET="${1:-example.com}"
OS_TYPE="$(uname -s)"

# mtr sudo detection (TOOL-018): warn and exit on macOS without sudo
if [[ "$OS_TYPE" == "Darwin" ]] && [[ $EUID -ne 0 ]]; then
    warn "mtr requires sudo on macOS (raw socket access)"
    info "Re-run with: sudo $0 ${TARGET}"
    exit 1
fi

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
info "1) Basic mtr report — 10 cycles with per-hop statistics"
echo "   mtr --report -c 10 ${TARGET}"
echo ""

# 2. Wide report with full hostnames
info "2) Wide report — show full hostnames (not truncated)"
echo "   mtr --report --report-wide -c 10 ${TARGET}"
echo ""

# 3. No DNS resolution for faster results
info "3) No DNS resolution — faster results, IP addresses only"
echo "   mtr --report -n -c 10 ${TARGET}"
echo ""

# 4. 20 cycles for more accurate stats
info "4) 20 cycles — more accurate statistics"
echo "   mtr --report -c 20 ${TARGET}"
echo ""

# 5. Limit to 20 hops
info "5) Limit to 20 hops maximum"
echo "   mtr --report -m 20 -c 10 ${TARGET}"
echo ""

# 6. UDP mode — default protocol
info "6) UDP mode — default mtr probe protocol"
echo "   mtr --report --udp -c 10 ${TARGET}"
echo ""

# 7. TCP mode on port 80
info "7) TCP mode on port 80 — test HTTP path"
echo "   mtr --report --tcp --port 80 -c 10 ${TARGET}"
echo ""

# 8. Custom report fields
info "8) Custom report fields — loss, sent, avg, worst, stdev"
echo "   mtr --report -o \"LSAWDV\" -c 10 ${TARGET}"
echo "   Fields: L=Loss%, S=Sent, A=Avg, W=Worst, D=StDev, V=Best"
echo ""

# 9. Set packet size to 1024 bytes
info "9) Set packet size to 1024 bytes — test with larger packets"
echo "   mtr --report -s 1024 -c 10 ${TARGET}"
echo ""

# 10. Compare two destinations side by side
info "10) Compare two destinations — run reports sequentially"
echo "    mtr --report -n -c 10 ${TARGET}"
echo "    mtr --report -n -c 10 8.8.8.8"
echo "    Tip: compare loss% and avg latency at each hop"
echo ""

# Interactive demo
[[ -t 0 ]] || exit 0

read -rp "Run mtr report to ${TARGET} (5 cycles, ~5 seconds)? [y/N] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    info "Running: mtr --report -n -c 5 ${TARGET}"
    mtr --report -n -c 5 "$TARGET"
fi
