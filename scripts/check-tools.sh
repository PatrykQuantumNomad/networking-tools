#!/usr/bin/env bash
# check-tools.sh — Verify which pentesting tools are installed
source "$(dirname "$0")/common.sh"

show_help() {
    echo "Usage: $(basename "$0") [-h|--help]"
    echo ""
    echo "Description:"
    echo "  Checks which pentesting tools are installed on this system and"
    echo "  reports their versions. Shows install instructions for any missing tools."
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")          # Check all tools"
    echo "  $(basename "$0") --help   # Show this help message"
}

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

# Include common install paths not always in PATH
for p in /opt/metasploit-framework/bin /usr/local/bin /opt/homebrew/bin; do
    [[ -d "$p" ]] && [[ ":$PATH:" != *":$p:"* ]] && export PATH="$p:$PATH"
done

echo -e "${CYAN}=== Pentesting Tools Installation Check ===${NC}"
echo ""

declare -A TOOLS=(
    [nmap]="brew install nmap"
    [tshark]="brew install wireshark (includes tshark CLI)"
    [msfconsole]="https://docs.metasploit.com/docs/using-metasploit/getting-started/nightly-installers.html"
    [aircrack-ng]="brew install aircrack-ng"
    [hashcat]="brew install hashcat"
    [skipfish]="sudo port install skipfish"
    [sqlmap]="brew install sqlmap"
    [hping3]="brew install draftbrew/tap/hping"
    [john]="brew install john"
    [nikto]="brew install nikto"
    [foremost]="brew install foremost"
    [dig]="apt install dnsutils (Debian/Ubuntu) | brew install bind (macOS)"
    [curl]="apt install curl (Debian/Ubuntu) | brew install curl (macOS)"
    [nc]="apt install netcat-openbsd (Debian/Ubuntu) | brew install netcat (macOS)"
    [traceroute]="apt install traceroute (Debian/Ubuntu) | dnf install traceroute (RHEL/Fedora) | pre-installed on macOS"
    [mtr]="apt install mtr (Debian/Ubuntu) | dnf install mtr (RHEL/Fedora) | brew install mtr (macOS)"
    [gobuster]="brew install gobuster (or: go install github.com/OJ/gobuster/v3@latest)"
)

# Ordered list for display
TOOL_ORDER=(nmap tshark msfconsole aircrack-ng hashcat skipfish sqlmap hping3 john nikto foremost dig curl nc traceroute mtr gobuster)

installed=0
total=${#TOOL_ORDER[@]}

get_version() {
    local tool="$1"
    case "$tool" in
        msfconsole)
            # msfconsole --version starts the full console; read from manifest instead
            if [[ -f /opt/metasploit-framework/version-manifest.txt ]]; then
                grep '^metasploit-framework' /opt/metasploit-framework/version-manifest.txt | head -1
            else
                echo "installed"
            fi
            ;;
        dig)
            dig -v 2>&1 | head -1
            ;;
        nc)
            # nc -h exits non-zero on some variants (e.g., macOS/OpenBSD)
            nc -h 2>&1 | head -1 || true
            ;;
        traceroute)
            # macOS BSD traceroute has no --version flag
            echo "installed"
            ;;
        gobuster)
            gobuster version 2>/dev/null | head -1
            ;;
        *)
            timeout 5 "$tool" --version 2>/dev/null | head -1 || echo "installed"
            ;;
    esac
}

for tool in "${TOOL_ORDER[@]}"; do
    if check_cmd "$tool"; then
        version=$(get_version "$tool")
        success "$tool — $version"
        ((installed++)) || true
    else
        warn "$tool — NOT INSTALLED"
        info "  Install: ${TOOLS[$tool]}"
    fi
done

echo ""
echo -e "${CYAN}$installed/$total tools installed${NC}"

if [[ $installed -lt $total ]]; then
    echo ""
    info "Install all missing tools on macOS with:"
    echo "  brew install nmap wireshark aircrack-ng hashcat skipfish sqlmap hping nikto john foremost"
    echo "  # Metasploit: see install link above"
fi
