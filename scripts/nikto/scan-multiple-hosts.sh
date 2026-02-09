#!/usr/bin/env bash
# nikto/scan-multiple-hosts.sh — Scan multiple web servers from a host list or nmap output
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [hostfile] [-h|--help]"
    echo ""
    echo "Description:"
    echo "  Scans multiple web servers discovered by nmap or listed in a file."
    echo "  More efficient than running nikto one host at a time. Accepts host"
    echo "  files, nmap output, or scans all lab targets by default."
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")              # Scan all lab targets on localhost"
    echo "  $(basename "$0") hosts.txt    # Scan hosts listed in a file"
    echo "  $(basename "$0") --help       # Show this help message"
}

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

require_cmd nikto "brew install nikto"

HOSTFILE="${1:-}"

safety_banner

info "=== Nikto Multi-Host Scanning ==="
if [[ -n "$HOSTFILE" ]]; then
    info "Host file: ${HOSTFILE}"
else
    info "No host file provided — showing examples with default targets"
fi
echo ""

info "Why scan multiple hosts at once?"
echo "   After network discovery (nmap), you often have dozens of web servers."
echo "   Scanning them one at a time is slow and tedious. Nikto can:"
echo "     - Read hosts from a file (one per line)"
echo "     - Accept nmap greppable output directly via pipe"
echo "     - Scan multiple ports on each host"
echo "   This is the standard workflow: nmap finds targets, nikto probes them."
echo ""

# 1. Scan multiple ports on one host
info "1) Scan multiple ports on one host"
echo "   nikto -h localhost -p 80,8080,3030,8888"
echo ""

# 2. Scan from a host list file
info "2) Scan from a host list file"
echo "   nikto -h hosts.txt"
echo ""

# 3. Pipe nmap greppable output to nikto
info "3) Pipe nmap greppable output to nikto"
echo "   nmap -p80,443,8080 -oG - 192.168.1.0/24 | nikto -h -"
echo ""

# 4. Scan all lab targets at once
info "4) Scan all lab targets at once"
echo "   nikto -h localhost -p 8080,3030,8888,8180"
echo ""

# 5. Save results per host
info "5) Save results per host in HTML format"
echo "   nikto -h hosts.txt -output results/ -Format htm"
echo ""

# 6. Scan with timeout per host
info "6) Scan with timeout per host"
echo "   nikto -h hosts.txt -timeout 300"
echo ""

# 7. Generate CSV report for all hosts
info "7) Generate CSV report for all hosts"
echo "   nikto -h hosts.txt -Format csv -output scan_results.csv"
echo ""

# 8. Scan hosts from nmap XML output
info "8) Scan hosts from nmap XML output"
echo "   nikto -h nmap_output.xml"
echo ""

# 9. Quick scan mode for many hosts
info "9) Quick scan mode for many hosts"
echo "   nikto -h hosts.txt -Tuning 2 -maxtime 120s"
echo ""

# 10. Create host list from nmap discovery, then scan
info "10) Create host list from nmap discovery, then scan"
echo "    nmap -sn 192.168.1.0/24 -oG - | awk '/Up/{print \$2}' > hosts.txt && nikto -h hosts.txt -p 80"
echo ""

# Interactive demo (skip if non-interactive)
[[ ! -t 0 ]] && exit 0

if [[ -z "$HOSTFILE" ]]; then
    read -rp "Scan localhost on all lab ports (8080,3030,8888,8180) with quick tuning? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        info "Running: nikto -h localhost -p 8080,3030,8888,8180 -Tuning 2 -maxtime 60s"
        echo ""
        nikto -h localhost -p 8080,3030,8888,8180 -Tuning 2 -maxtime 60s
    fi
else
    if [[ -f "$HOSTFILE" ]]; then
        read -rp "Run a quick scan against hosts in ${HOSTFILE}? [y/N] " answer
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            info "Running: nikto -h ${HOSTFILE} -Tuning 2 -maxtime 120s"
            echo ""
            nikto -h "$HOSTFILE" -Tuning 2 -maxtime 120s
        fi
    else
        error "File not found: ${HOSTFILE}"
        info "Create a host file with one target per line, e.g.:"
        echo "   echo 'http://192.168.1.10' > hosts.txt"
        echo "   echo 'http://192.168.1.20:8080' >> hosts.txt"
    fi
fi
