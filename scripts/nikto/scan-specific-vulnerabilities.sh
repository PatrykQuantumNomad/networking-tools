#!/usr/bin/env bash
# nikto/scan-specific-vulnerabilities.sh — Target specific vulnerability types using Nikto Tuning
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [target] [-h|--help]"
    echo ""
    echo "Description:"
    echo "  Uses Nikto's Tuning flags to scan for specific vulnerability categories."
    echo "  Each tuning number targets a different vulnerability type, making scans"
    echo "  faster and less noisy than a full scan. Default target: http://localhost:8080"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")                          # Scan localhost:8080"
    echo "  $(basename "$0") http://192.168.1.1:8080  # Scan a specific target"
    echo "  $(basename "$0") --help                   # Show this help message"
}

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

require_cmd nikto "brew install nikto"

TARGET="${1:-http://localhost:8080}"

safety_banner

info "=== Nikto Targeted Vulnerability Scanning ==="
info "Target: ${TARGET}"
echo ""

info "Why use Tuning flags instead of a full scan?"
echo "   A full Nikto scan tests EVERYTHING — thousands of checks across all categories."
echo "   Tuning lets you focus on specific vulnerability types, which is:"
echo "     - Faster: Only relevant tests run"
echo "     - Quieter: Less traffic means lower detection risk"
echo "     - Focused: Useful when you already know what you're looking for"
echo ""
echo "   Nikto Tuning Reference:"
echo "     0 = File Upload           5 = Remote File Inclusion (RFI)"
echo "     1 = Interesting File      6 = Denial of Service"
echo "     2 = Misconfiguration      7 = Remote File Retrieval (server-wide)"
echo "     3 = Information Disclosure 8 = Command Execution / Injection"
echo "     4 = XSS (Cross-Site       9 = SQL Injection"
echo "         Scripting)             a = Authentication Bypass"
echo "                                b = Software Identification"
echo "                                c = Remote Source Inclusion"
echo "                                x = Reverse Tuning (exclude instead of include)"
echo ""

# 1. SQL injection only
info "1) Scan for SQL injection only"
echo "   nikto -h ${TARGET} -Tuning 9"
echo ""

# 2. XSS only
info "2) Scan for XSS only"
echo "   nikto -h ${TARGET} -Tuning 4"
echo ""

# 3. File upload issues
info "3) Scan for file upload issues"
echo "   nikto -h ${TARGET} -Tuning 0"
echo ""

# 4. Interesting files/directories
info "4) Scan for interesting files and directories"
echo "   nikto -h ${TARGET} -Tuning 2"
echo ""

# 5. Information disclosure
info "5) Scan for information disclosure"
echo "   nikto -h ${TARGET} -Tuning 3"
echo ""

# 6. Command execution
info "6) Scan for command execution vulnerabilities"
echo "   nikto -h ${TARGET} -Tuning 8"
echo ""

# 7. Combined: SQLi + XSS + command exec
info "7) Combine: SQLi + XSS + command execution"
echo "   nikto -h ${TARGET} -Tuning 498"
echo ""

# 8. Misconfigurations
info "8) Scan for server misconfigurations"
echo "   nikto -h ${TARGET} -Tuning b"
echo ""

# 9. Remote file retrieval
info "9) Scan for remote file retrieval"
echo "   nikto -h ${TARGET} -Tuning 7"
echo ""

# 10. Full scan excluding DOS tests
info "10) Full scan excluding denial-of-service tests"
echo "    nikto -h ${TARGET} -Tuning x6"
echo ""

# Interactive demo (skip if non-interactive)
[[ ! -t 0 ]] && exit 0

if [[ "$TARGET" == *"localhost"* || "$TARGET" == *"127.0.0.1"* ]]; then
    read -rp "Run a quick Tuning 2 scan (interesting files) against ${TARGET}? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        info "Running: nikto -h ${TARGET} -Tuning 2"
        echo ""
        nikto -h "$TARGET" -Tuning 2
    fi
else
    read -rp "Run a quick Tuning 2 scan (interesting files) against ${TARGET}? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        info "Running: nikto -h ${TARGET} -Tuning 2"
        echo ""
        nikto -h "$TARGET" -Tuning 2
    fi
fi
