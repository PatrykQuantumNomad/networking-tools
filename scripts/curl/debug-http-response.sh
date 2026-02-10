#!/usr/bin/env bash
# curl/debug-http-response.sh — Debug HTTP response timing and details
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [target] [-h|--help]"
    echo ""
    echo "Description:"
    echo "  Diagnoses HTTP response behavior using curl's timing and debug"
    echo "  features. Measures DNS lookup, TCP connect, TLS handshake, and"
    echo "  time-to-first-byte to pinpoint latency sources."
    echo "  Default target is https://example.com if none is provided."
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")                           # Debug example.com"
    echo "  $(basename "$0") http://localhost:8080      # Debug local server"
    echo "  $(basename "$0") https://api.example.com    # Debug API endpoint"
    echo "  $(basename "$0") --help                     # Show this help message"
}

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

require_cmd curl "apt install curl (Debian/Ubuntu) | brew install curl (macOS)"

TARGET="${1:-https://example.com}"

safety_banner

info "=== Debug HTTP Response ==="
info "Target: ${TARGET}"
echo ""

info "Why debug HTTP responses?"
echo "   Slow web requests can have many causes:"
echo "   - DNS lookup delay (misconfigured resolver, propagation)"
echo "   - TCP connect latency (network hops, firewall rules)"
echo "   - TLS handshake overhead (certificate chain, OCSP)"
echo "   - Server processing time (backend, database queries)"
echo "   - Transfer time (response size, bandwidth limits)"
echo "   curl's -w (write-out) format string breaks down each phase"
echo "   so you can pinpoint exactly where time is spent."
echo ""

# Define timing format variable
TIMING_FMT='DNS Lookup:   %{time_namelookup}s\nTCP Connect:  %{time_connect}s\nTLS Handshake: %{time_appconnect}s\nPre-Transfer:  %{time_pretransfer}s\nRedirect:      %{time_redirect}s\nFirst Byte:    %{time_starttransfer}s\nTotal:         %{time_total}s\n'

# 1. Full timing breakdown
info "1) Full HTTP timing breakdown"
echo "   curl -o /dev/null -s -w '${TIMING_FMT}' ${TARGET}"
echo ""

# 2. Just total time
info "2) Quick total request time"
echo "   curl -o /dev/null -s -w 'Total: %{time_total}s\n' ${TARGET}"
echo ""

# 3. Verbose headers and body
info "3) Verbose output — full request/response headers"
echo "   curl -v ${TARGET} 2>&1 | head -30"
echo ""

# 4. Show only response headers
info "4) Show only response headers (no body)"
echo "   curl -sI ${TARGET}"
echo ""

# 5. Show response size
info "5) Show response size in bytes"
echo "   curl -o /dev/null -s -w 'Download size: %{size_download} bytes\nHeader size: %{size_header} bytes\n' ${TARGET}"
echo ""

# 6. Compare HTTP/1.1 vs HTTP/2
info "6) Compare HTTP/1.1 vs HTTP/2 response"
echo "   curl --http1.1 -o /dev/null -s -w 'HTTP/1.1 total: %{time_total}s\n' ${TARGET}"
echo "   curl --http2 -o /dev/null -s -w 'HTTP/2   total: %{time_total}s\n' ${TARGET}"
echo ""

# 7. Test with different DNS resolution
info "7) Test with custom DNS resolution (bypass local DNS)"
echo "   curl --resolve ${TARGET#*://}:443:93.184.216.34 -o /dev/null -s -w 'Custom DNS total: %{time_total}s\n' ${TARGET}"
echo ""

# 8. Show redirect timing chain
info "8) Show redirect timing chain"
echo "   curl -L -o /dev/null -s -w 'Redirects: %{num_redirects}\nRedirect time: %{time_redirect}s\nTotal: %{time_total}s\n' ${TARGET}"
echo ""

# 9. Measure time-to-first-byte specifically
info "9) Measure time-to-first-byte (TTFB)"
echo "   curl -o /dev/null -s -w 'TTFB: %{time_starttransfer}s\n' ${TARGET}"
echo ""

# 10. Save full debug trace to file
info "10) Save full debug trace to file for analysis"
echo "    curl --trace curl-trace.log --trace-time ${TARGET} -o /dev/null"
echo ""

# Interactive demo
[[ ! -t 0 ]] && exit 0

read -rp "Run timing breakdown on ${TARGET} now? [y/N] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    info "Running: curl -o /dev/null -s -w <timing-format> ${TARGET}"
    echo ""
    curl -o /dev/null -s -w "DNS Lookup:    %{time_namelookup}s\nTCP Connect:   %{time_connect}s\nTLS Handshake: %{time_appconnect}s\nFirst Byte:    %{time_starttransfer}s\nTotal:         %{time_total}s\n" "$TARGET"
fi
