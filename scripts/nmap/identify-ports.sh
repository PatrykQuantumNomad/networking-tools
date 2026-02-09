#!/usr/bin/env bash
# nmap/identify-ports.sh — Identify what's behind open ports
source "$(dirname "$0")/../common.sh"

TARGET="${1:-localhost}"

info "=== Port Identification ==="
info "Target: $TARGET"
echo ""

info "Why does nmap show 'unknown' for many ports?"
echo "   A SYN scan (-sS) only checks if ports are open/closed."
echo "   It does NOT probe the service. Add -sV to identify services."
echo ""

# 1. Local process lookup (single port)
info "1) Identify which process owns a specific port"
echo "   lsof -i :8080 -P -n"
echo ""

# 2. All listening ports with process names
info "2) List ALL listening ports with their process"
echo "   lsof -i -P -n | grep LISTEN"
echo ""

# 3. Filter by TCP only
info "3) TCP listening ports only"
echo "   lsof -iTCP -P -n | grep LISTEN"
echo ""

# 4. Show connections for a specific process
info "4) Show all ports owned by a specific process"
echo "   lsof -i -P -n | grep <process-name>"
echo ""

# 5. macOS netstat alternative
info "5) netstat — show listening ports with PIDs (macOS)"
echo "   netstat -an -p tcp | grep LISTEN"
echo ""

# 6. Nmap service version detection
info "6) Nmap service probing (remote — works on any target)"
echo "   nmap -sV $TARGET"
echo ""

# 7. Nmap version detection on specific ports
info "7) Probe specific ports only"
echo "   nmap -sV -p 8080,3030,8888 $TARGET"
echo ""

# 8. Aggressive nmap version detection
info "8) Maximum version detection effort (slow)"
echo "   nmap -sV --version-all $TARGET"
echo ""

# 9. Nmap with default scripts for more detail
info "9) Service detection + default scripts"
echo "   nmap -sV -sC $TARGET"
echo ""

# 10. Combined: nmap scan then local lookup
info "10) Full workflow: scan then identify"
echo "    sudo nmap -sV -p- $TARGET -oG - | grep open"
echo "    lsof -i -P -n | grep LISTEN"
echo ""

# Interactive demo (skip if non-interactive, e.g. running via make)
[[ ! -t 0 ]] && exit 0

if [[ "$TARGET" == "localhost" || "$TARGET" == "127.0.0.1" ]]; then
    read -rp "Show all listening ports on this machine now? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        info "Running: lsof -iTCP -P -n | grep LISTEN"
        echo ""
        printf "%-20s %-8s %-10s %s\n" "COMMAND" "PID" "USER" "ADDRESS"
        printf "%-20s %-8s %-10s %s\n" "-------" "---" "----" "-------"
        lsof -iTCP -P -n 2>/dev/null | grep LISTEN | awk '{printf "%-20s %-8s %-10s %s\n", $1, $2, $3, $9}'
    fi
else
    read -rp "Run service detection on $TARGET now? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        info "Running: nmap -sV --top-ports 100 $TARGET"
        nmap -sV --top-ports 100 "$TARGET"
    fi
fi
