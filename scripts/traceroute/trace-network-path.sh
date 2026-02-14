#!/usr/bin/env bash
# ============================================================================
# @description  Trace the network path to a host
# @usage        traceroute/trace-network-path.sh [target] [-h|--help] [-x|--execute] [-j|--json]
# @dependencies traceroute, common.sh
# ============================================================================
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [target] [-h|--help] [-x|--execute] [-j|--json]"
    echo ""
    echo "Description:"
    echo "  Traces the network path to a target host, showing every hop"
    echo "  (router) between you and the destination. Useful for"
    echo "  understanding network topology and diagnosing routing issues."
    echo "  Default target is example.com if none is provided."
    echo ""
    echo "Options:"
    echo "  -h, --help       Show this help message"
    echo "  -j, --json       Output as JSON; add -x to run and capture results (requires jq)"
    echo "  -x, --execute    Run commands instead of displaying them"
    echo "  -v, --verbose    Increase verbosity"
    echo "  -q, --quiet      Suppress informational output"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")                  # Trace to example.com"
    echo "  $(basename "$0") 8.8.8.8          # Trace to Google DNS"
    echo "  $(basename "$0") target.local     # Trace to internal host"
    echo "  $(basename "$0") -x 8.8.8.8       # Execute trace to Google DNS"
    echo "  $(basename "$0") --help           # Show this help message"
}

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

require_cmd traceroute "apt install traceroute (Debian/Ubuntu) | dnf install traceroute (RHEL/Fedora) | pre-installed on macOS"

TARGET="${1:-example.com}"
OS_TYPE="$(uname -s)"

json_set_meta "traceroute" "$TARGET" "network-analysis"

confirm_execute "${1:-}"
safety_banner

info "=== Trace Network Path ==="
info "Target: ${TARGET}"
echo ""

info "How traceroute works:"
echo "   Traceroute sends packets with incrementing TTL (Time To Live) values."
echo "   Each router along the path decrements the TTL by 1. When TTL reaches 0,"
echo "   the router sends back an ICMP Time Exceeded message, revealing its address."
echo "   By starting at TTL=1 and incrementing, traceroute discovers every hop."
echo ""

# 1. Basic path trace
run_or_show "1) Basic path trace" \
    traceroute "$TARGET"

# 2. Numeric — skip DNS for speed
run_or_show "2) Numeric output — skip DNS resolution for speed" \
    traceroute -n "$TARGET"

# 3. Set max hops to 20
run_or_show "3) Set max hops to 20" \
    traceroute -m 20 "$TARGET"

# 4. Single probe per hop for faster results
run_or_show "4) Single probe per hop — faster results" \
    traceroute -q 1 "$TARGET"

# 5. Set wait timeout to 2 seconds
run_or_show "5) Set wait timeout to 2 seconds per probe" \
    traceroute -w 2 "$TARGET"

# 6. Start from hop 5 — skip known local hops
run_or_show "6) Start from hop 5 — skip known local network hops" \
    traceroute -f 5 "$TARGET"

# 7. ICMP mode — requires sudo
run_or_show "7) ICMP mode — use ICMP ECHO instead of UDP (requires sudo)" \
    sudo traceroute -I "$TARGET"

# 8. TCP mode — platform-detect
if [[ "$OS_TYPE" == "Darwin" ]]; then
    run_or_show "8) TCP mode — bypasses firewalls that block ICMP/UDP (requires sudo)" \
        sudo traceroute -P tcp "$TARGET"
else
    run_or_show "8) TCP mode — bypasses firewalls that block ICMP/UDP (requires sudo)" \
        sudo traceroute -T "$TARGET"
fi

# 9. Trace to port 443 — TCP to specific port
if [[ "$OS_TYPE" == "Darwin" ]]; then
    run_or_show "9) TCP trace to port 443 — test HTTPS path (requires sudo)" \
        sudo traceroute -P tcp -p 443 "$TARGET"
else
    run_or_show "9) TCP trace to port 443 — test HTTPS path (requires sudo)" \
        sudo traceroute -T -p 443 "$TARGET"
fi

# 10. Trace with AS number lookups
info "10) Trace with AS number lookups — show autonomous system for each hop"
if [[ "$OS_TYPE" == "Darwin" ]]; then
    echo "    traceroute -a ${TARGET}"
    echo "    Note: macOS uses -a for AS lookups"
else
    echo "    traceroute -A ${TARGET}"
    echo "    Note: Linux uses -A for AS lookups (macOS does not support -A)"
fi
echo ""
if [[ "$OS_TYPE" == "Darwin" ]]; then
    json_add_example "Trace with AS number lookups — show autonomous system for each hop" \
        "traceroute -a ${TARGET}"
else
    json_add_example "Trace with AS number lookups — show autonomous system for each hop" \
        "traceroute -A ${TARGET}"
fi

json_finalize

# Interactive demo (skip if non-interactive)
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    [[ ! -t 0 ]] && exit 0

    read -rp "Run a basic traceroute to ${TARGET}? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        info "Running: traceroute -n -q 1 -m 15 ${TARGET}"
        traceroute -n -q 1 -m 15 "$TARGET"
    fi
fi
