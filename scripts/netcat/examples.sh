#!/usr/bin/env bash
# netcat/examples.sh -- netcat (nc): TCP/UDP networking swiss-army knife
source "$(dirname "$0")/../common.sh"

show_help() {
    cat <<EOF
Usage: $(basename "$0") <target>

netcat (nc) - TCP/UDP networking swiss-army knife

Displays common netcat commands for the given target, detects which nc
variant is installed (ncat, GNU, traditional, OpenBSD), and labels
variant-specific flags accordingly.

Examples:
    $(basename "$0") 127.0.0.1
    $(basename "$0") 192.168.1.1
EOF
}

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

require_cmd nc "apt install netcat-openbsd (Debian/Ubuntu) | brew install netcat (macOS)"
require_target "${1:-}"
safety_banner

TARGET="$1"
NC_VARIANT=$(detect_nc_variant)

info "=== Netcat Examples ==="
info "Target: ${TARGET}"
info "Detected variant: ${NC_VARIANT}"
echo ""

# 1. Test if a port is open
info "1) Test if a port is open (-z = scan without sending data)"
echo "   nc -zv ${TARGET} 80"
echo ""

# 2. Scan a range of ports
info "2) Scan a range of ports"
echo "   nc -zv ${TARGET} 20-100"
echo ""

# 3. Start a simple listener
info "3) Start a simple listener on port 4444"
if [[ "$NC_VARIANT" == "openbsd" ]]; then
    echo "   nc -l 4444                  # OpenBSD: -p is optional with -l"
else
    echo "   nc -l -p 4444"
fi
echo ""

# 4. Connect to a remote port
info "4) Connect to a remote port (verbose)"
echo "   nc -v ${TARGET} 80"
echo ""

# 5. Send UDP packet
info "5) Send a UDP packet to a port"
echo "   nc -u ${TARGET} 53"
echo ""

# 6. Set connection timeout
info "6) Set connection timeout (-w seconds)"
echo "   nc -w 3 -zv ${TARGET} 80"
echo ""

# 7. Simple chat between two machines
info "7) Simple chat between two machines"
echo "   # Machine A (listener):"
if [[ "$NC_VARIANT" == "openbsd" ]]; then
    echo "   nc -l 4444"
else
    echo "   nc -l -p 4444"
fi
echo "   # Machine B (connector):"
echo "   nc ${TARGET} 4444"
echo "   # Type messages -- they appear on the other side"
echo ""

# 8. [VARIANT-SPECIFIC] Keep listener open for multiple connections
info "8) Keep listener open for multiple connections [variant: ${NC_VARIANT}]"
case "$NC_VARIANT" in
    ncat)
        echo "   ncat -k -l -p 4444         # ncat: -k keeps listening after client disconnects"
        ;;
    openbsd)
        echo "   nc -k -l 4444              # OpenBSD: -k keeps listening after client disconnects"
        ;;
    gnu|traditional)
        echo "   # ${NC_VARIANT} nc does not support -k; use a while loop instead:"
        echo "   while true; do nc -l -p 4444; done"
        ;;
esac
echo ""

# 9. [VARIANT-SPECIFIC] Execute command on connection
info "9) Execute command on connection [variant: ${NC_VARIANT}]"
case "$NC_VARIANT" in
    ncat)
        echo "   ncat -e /bin/bash -l -p 4444   # ncat: -e executes command"
        ;;
    traditional)
        echo "   nc -e /bin/bash -l -p 4444     # traditional: -e executes command"
        ;;
    openbsd)
        echo "   # OpenBSD nc does NOT support -e; use a named pipe instead:"
        echo "   mkfifo /tmp/f; nc -l 4444 < /tmp/f | /bin/sh > /tmp/f 2>&1"
        ;;
    gnu)
        echo "   nc -c /bin/bash -l -p 4444     # GNU nc: -c executes command via /bin/sh"
        ;;
esac
echo ""

# 10. Transfer a file over TCP
info "10) Transfer a file over TCP"
echo "    # Receiver (listener):"
if [[ "$NC_VARIANT" == "openbsd" ]]; then
    echo "    nc -l 4444 > received_file"
else
    echo "    nc -l -p 4444 > received_file"
fi
echo "    # Sender (connector):"
echo "    nc ${TARGET} 4444 < file_to_send"
echo ""

# Interactive demo
[[ -t 0 ]] || exit 0
read -rp "Run a quick port scan on ${TARGET} port 80? [y/N] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    info "Running: nc -zv ${TARGET} 80 -w 3"
    nc -zv "$TARGET" 80 -w 3 2>&1 || true
fi
