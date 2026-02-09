#!/usr/bin/env bash
# metasploit/scan-network-services.sh — Enumerate network services using Metasploit scanners
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [target] [-h|--help]"
    echo ""
    echo "Description:"
    echo "  Enumerates network services using Metasploit auxiliary scanners."
    echo "  Covers SMB, SSH, HTTP, MySQL, FTP, VNC, and more."
    echo "  Default target is localhost if none is provided."
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")              # Scan localhost services"
    echo "  $(basename "$0") 192.168.1.1  # Scan a remote host"
    echo "  $(basename "$0") --help       # Show this help message"
}

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

require_cmd msfconsole "https://docs.metasploit.com/docs/using-metasploit/getting-started/nightly-installers.html"

TARGET="${1:-localhost}"

safety_banner

info "=== Metasploit Service Scanning ==="
info "Target: ${TARGET}"
echo ""

info "Why use Metasploit scanners after nmap?"
echo "   Metasploit's auxiliary scanners go beyond basic port detection:"
echo "   - Protocol-specific fingerprinting (exact SMB version, SSH algorithms)"
echo "   - Built-in brute force modules with smart wordlists"
echo "   - Version-specific vulnerability checks"
echo "   - Seamless transition from scanning to exploitation"
echo ""
echo "   Workflow: nmap for broad discovery, then MSF for targeted enumeration."
echo "   Each scanner runs as: use auxiliary/scanner/...; set RHOSTS; run"
echo ""

# 1. SMB version
info "1) SMB version detection"
echo "   msfconsole -q -x \"use auxiliary/scanner/smb/smb_version; set RHOSTS ${TARGET}; run; exit\""
echo ""

# 2. SSH version
info "2) SSH version detection"
echo "   msfconsole -q -x \"use auxiliary/scanner/ssh/ssh_version; set RHOSTS ${TARGET}; run; exit\""
echo ""

# 3. HTTP version
info "3) HTTP version detection"
echo "   msfconsole -q -x \"use auxiliary/scanner/http/http_version; set RHOSTS ${TARGET}; set RPORT 8080; run; exit\""
echo ""

# 4. MySQL enumeration
info "4) MySQL enumeration"
echo "   msfconsole -q -x \"use auxiliary/scanner/mysql/mysql_version; set RHOSTS ${TARGET}; run; exit\""
echo ""

# 5. FTP version
info "5) FTP version scan"
echo "   msfconsole -q -x \"use auxiliary/scanner/ftp/ftp_version; set RHOSTS ${TARGET}; run; exit\""
echo ""

# 6. SMB share enumeration
info "6) SMB share enumeration"
echo "   msfconsole -q -x \"use auxiliary/scanner/smb/smb_enumshares; set RHOSTS ${TARGET}; run; exit\""
echo ""

# 7. SSH brute force
info "7) SSH login brute force (with wordlist)"
echo "   msfconsole -q -x \"use auxiliary/scanner/ssh/ssh_login; set RHOSTS ${TARGET}; set USERNAME root; set PASS_FILE /path/to/passwords.txt; run; exit\""
echo ""

# 8. HTTP directory scanner
info "8) HTTP directory scanner"
echo "   msfconsole -q -x \"use auxiliary/scanner/http/dir_scanner; set RHOSTS ${TARGET}; set RPORT 8080; run; exit\""
echo ""

# 9. VNC auth check
info "9) VNC authentication check"
echo "   msfconsole -q -x \"use auxiliary/scanner/vnc/vnc_none_auth; set RHOSTS ${TARGET}; run; exit\""
echo ""

# 10. Subnet port scan
info "10) Scan a subnet for all open services"
echo "    msfconsole -q -x \"use auxiliary/scanner/portscan/tcp; set RHOSTS ${TARGET}/24; set PORTS 22,80,443,8080; run; exit\""
echo ""

# Interactive demo (skip if non-interactive, e.g. running via make)
[[ ! -t 0 ]] && exit 0

if [[ "$TARGET" == "localhost" || "$TARGET" == "127.0.0.1" ]]; then
    read -rp "Run HTTP version scanner against lab ports (8080)? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        info "Running: msfconsole -q -x \"use auxiliary/scanner/http/http_version; set RHOSTS ${TARGET}; set RPORT 8080; run; exit\""
        echo ""
        msfconsole -q -x "use auxiliary/scanner/http/http_version; set RHOSTS ${TARGET}; set RPORT 8080; run; exit"
    fi
else
    read -rp "Run SSH version scanner against ${TARGET}? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        info "Running: msfconsole -q -x \"use auxiliary/scanner/ssh/ssh_version; set RHOSTS ${TARGET}; run; exit\""
        echo ""
        msfconsole -q -x "use auxiliary/scanner/ssh/ssh_version; set RHOSTS ${TARGET}; run; exit"
    fi
fi
