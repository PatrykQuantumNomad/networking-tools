#!/usr/bin/env bash
# ============================================================================
# @description  Setting up netcat listeners
# @usage        netcat/setup-listener.sh [target] [-h|--help] [-x|--execute] [-j|--json]
# @dependencies nc, common.sh
# ============================================================================
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [port] [-h|--help] [-x|--execute] [-j|--json]"
    echo ""
    echo "Description:"
    echo "  Demonstrates how to set up netcat listeners for various purposes:"
    echo "  reverse shells, file transfers, debugging, and chat sessions."
    echo "  Detects the installed nc variant and labels variant-specific flags."
    echo "  Default port is 4444 if none is provided."
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")                 # Show listener examples (port 4444)"
    echo "  $(basename "$0") 8080            # Show listener examples (port 8080)"
    echo "  $(basename "$0") --help          # Show this help message"
    echo ""
    echo "Flags:"
    echo "  -h, --help     Show this help message"
    echo "  -j, --json     Output as JSON; add -x to run and capture results (requires jq)"
    echo "  -x, --execute  Execute commands instead of displaying them"
}

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

require_cmd nc "apt install netcat-openbsd (Debian/Ubuntu) | brew install netcat (macOS)"

PORT="${1:-4444}"
NC_VARIANT=$(detect_nc_variant)

json_set_meta "netcat" "$PORT" "network-scanner"

confirm_execute "${1:-}"
safety_banner

info "=== Netcat Listener Setup ==="
info "Port: ${PORT}"
info "Detected variant: ${NC_VARIANT}"
echo ""

info "Why set up a listener?"
echo "   A netcat listener waits for incoming TCP or UDP connections on a port."
echo "   Common uses: catching reverse shells during pentests, receiving file"
echo "   transfers, debugging client-server communication, and setting up ad-hoc"
echo "   chat sessions between machines. Listeners are fundamental to many"
echo "   penetration testing workflows."
echo ""

# 1. Basic listener on a port
info "1) Basic listener on port ${PORT}"
if [[ "$NC_VARIANT" == "openbsd" ]]; then
    echo "   nc -l ${PORT}"
    json_add_example "1) Basic listener on port ${PORT}" "nc -l ${PORT}"
else
    echo "   nc -l -p ${PORT}"
    json_add_example "1) Basic listener on port ${PORT}" "nc -l -p ${PORT}"
fi
echo ""

# 2. Listener with verbose output
info "2) Listener with verbose output"
if [[ "$NC_VARIANT" == "openbsd" ]]; then
    echo "   nc -lv ${PORT}"
    json_add_example "2) Listener with verbose output" "nc -lv ${PORT}"
else
    echo "   nc -lv -p ${PORT}"
    json_add_example "2) Listener with verbose output" "nc -lv -p ${PORT}"
fi
echo ""

# 3. [VARIANT] Keep-alive listener
info "3) Keep-alive listener -- stays open after client disconnects [variant: ${NC_VARIANT}]"
case "$NC_VARIANT" in
    ncat)
        echo "   ncat -k -l -p ${PORT}          # ncat: -k keeps listening"
        json_add_example "3) Keep-alive listener [${NC_VARIANT}]" "ncat -k -l -p ${PORT}"
        ;;
    openbsd)
        echo "   nc -k -l ${PORT}               # OpenBSD: -k keeps listening"
        json_add_example "3) Keep-alive listener [${NC_VARIANT}]" "nc -k -l ${PORT}"
        ;;
    gnu|traditional)
        echo "   # ${NC_VARIANT} nc does not support -k; use a while loop:"
        echo "   while true; do nc -l -p ${PORT}; done"
        json_add_example "3) Keep-alive listener [${NC_VARIANT}]" "while true; do nc -l -p ${PORT}; done"
        ;;
esac
echo ""

# 4. Listener that saves received data to a file
info "4) Listener that saves received data to a file"
if [[ "$NC_VARIANT" == "openbsd" ]]; then
    echo "   nc -l ${PORT} > received_data.txt"
    json_add_example "4) Listener that saves received data to a file" "nc -l ${PORT} > received_data.txt"
else
    echo "   nc -l -p ${PORT} > received_data.txt"
    json_add_example "4) Listener that saves received data to a file" "nc -l -p ${PORT} > received_data.txt"
fi
echo ""

# 5. UDP listener
info "5) UDP listener"
if [[ "$NC_VARIANT" == "openbsd" ]]; then
    echo "   nc -lu ${PORT}"
    json_add_example "5) UDP listener" "nc -lu ${PORT}"
else
    echo "   nc -lu -p ${PORT}"
    json_add_example "5) UDP listener" "nc -lu -p ${PORT}"
fi
echo ""

# 6. Listener with a timeout
info "6) Listener with a timeout (closes after N seconds of inactivity)"
if [[ "$NC_VARIANT" == "openbsd" ]]; then
    echo "   nc -l -w 30 ${PORT}            # Timeout after 30 seconds"
    json_add_example "6) Listener with a timeout" "nc -l -w 30 ${PORT}"
else
    echo "   nc -l -p ${PORT} -w 30          # Timeout after 30 seconds"
    json_add_example "6) Listener with a timeout" "nc -l -p ${PORT} -w 30"
fi
echo ""

# 7. [VARIANT] Execute command on connect
info "7) Execute command when a client connects [variant: ${NC_VARIANT}]"
case "$NC_VARIANT" in
    ncat)
        echo "   ncat -e /bin/bash -l -p ${PORT}    # ncat: -e executes command"
        json_add_example "7) Execute command on connect [${NC_VARIANT}]" "ncat -e /bin/bash -l -p ${PORT}"
        ;;
    traditional)
        echo "   nc -e /bin/bash -l -p ${PORT}      # traditional: -e executes command"
        json_add_example "7) Execute command on connect [${NC_VARIANT}]" "nc -e /bin/bash -l -p ${PORT}"
        ;;
    openbsd)
        echo "   # OpenBSD nc does NOT support -e; use a named pipe:"
        echo "   mkfifo /tmp/f; nc -l ${PORT} < /tmp/f | /bin/sh > /tmp/f 2>&1"
        json_add_example "7) Execute command on connect [${NC_VARIANT}]" "mkfifo /tmp/f; nc -l ${PORT} < /tmp/f | /bin/sh > /tmp/f 2>&1"
        ;;
    gnu)
        echo "   nc -c /bin/bash -l -p ${PORT}      # GNU: -c executes via /bin/sh"
        json_add_example "7) Execute command on connect [${NC_VARIANT}]" "nc -c /bin/bash -l -p ${PORT}"
        ;;
esac
echo ""

# 8. Listener that serves an HTTP-like response
info "8) Listener that serves an HTTP-like response"
if [[ "$NC_VARIANT" == "openbsd" ]]; then
    echo "   echo -e 'HTTP/1.1 200 OK\\r\\n\\r\\nHello' | nc -l ${PORT}"
    json_add_example "8) Listener that serves an HTTP-like response" "echo -e 'HTTP/1.1 200 OK\r\n\r\nHello' | nc -l ${PORT}"
else
    echo "   echo -e 'HTTP/1.1 200 OK\\r\\n\\r\\nHello' | nc -l -p ${PORT}"
    json_add_example "8) Listener that serves an HTTP-like response" "echo -e 'HTTP/1.1 200 OK\r\n\r\nHello' | nc -l -p ${PORT}"
fi
echo ""

# 9. Two-way chat setup
info "9) Two-way chat setup"
echo "   # Machine A (listener):"
if [[ "$NC_VARIANT" == "openbsd" ]]; then
    echo "   nc -l ${PORT}"
    json_add_example "9) Two-way chat setup" "nc -l ${PORT}"
else
    echo "   nc -l -p ${PORT}"
    json_add_example "9) Two-way chat setup" "nc -l -p ${PORT}"
fi
echo "   # Machine B (connector):"
echo "   nc <listener-ip> ${PORT}"
echo "   # Type messages in either terminal -- they appear on the other side"
echo ""

# 10. Listener piped to another command
info "10) Listener piped to another command (e.g., log to syslog)"
if [[ "$NC_VARIANT" == "openbsd" ]]; then
    echo "    nc -l ${PORT} | tee incoming.log"
    json_add_example "10) Listener piped to another command" "nc -l ${PORT} | tee incoming.log"
else
    echo "    nc -l -p ${PORT} | tee incoming.log"
    json_add_example "10) Listener piped to another command" "nc -l -p ${PORT} | tee incoming.log"
fi
echo ""

json_finalize

# Interactive demo (skip if non-interactive)
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    [[ ! -t 0 ]] && exit 0

    read -rp "Demo: check if port 22 is open on localhost? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        info "Running: nc -zv 127.0.0.1 22 -w 2"
        nc -zv 127.0.0.1 22 -w 2 2>&1 || true
    fi
fi
