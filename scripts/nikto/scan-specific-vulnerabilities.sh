#!/usr/bin/env bash
# ============================================================================
# @description  Target specific vulnerability types using Nikto Tuning
# @usage        nikto/scan-specific-vulnerabilities.sh [target] [-h|--help] [-x|--execute]
# @dependencies nikto, common.sh
# ============================================================================
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

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

require_cmd nikto "brew install nikto"

TARGET="${1:-http://localhost:8080}"

confirm_execute "$TARGET"
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
run_or_show "1) Scan for SQL injection only" \
    nikto -h "$TARGET" -Tuning 9

# 2. XSS only
run_or_show "2) Scan for XSS only" \
    nikto -h "$TARGET" -Tuning 4

# 3. File upload issues
run_or_show "3) Scan for file upload issues" \
    nikto -h "$TARGET" -Tuning 0

# 4. Interesting files/directories
run_or_show "4) Scan for interesting files and directories" \
    nikto -h "$TARGET" -Tuning 2

# 5. Information disclosure
run_or_show "5) Scan for information disclosure" \
    nikto -h "$TARGET" -Tuning 3

# 6. Command execution
run_or_show "6) Scan for command execution vulnerabilities" \
    nikto -h "$TARGET" -Tuning 8

# 7. Combined: SQLi + XSS + command exec
run_or_show "7) Combine: SQLi + XSS + command execution" \
    nikto -h "$TARGET" -Tuning 498

# 8. Misconfigurations
run_or_show "8) Scan for server misconfigurations" \
    nikto -h "$TARGET" -Tuning b

# 9. Remote file retrieval
run_or_show "9) Scan for remote file retrieval" \
    nikto -h "$TARGET" -Tuning 7

# 10. Full scan excluding DOS tests
run_or_show "10) Full scan excluding denial-of-service tests" \
    nikto -h "$TARGET" -Tuning x6

# Interactive demo (skip if non-interactive)
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    [[ ! -t 0 ]] && exit 0

    if [[ "$TARGET" == *"localhost"* || "$TARGET" == *"127.0.0.1"* ]]; then
        read -rp "Run a quick Tuning 2 scan (interesting files) against ${TARGET}? [y/N] " answer
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            info "Running: nikto -h ${TARGET} -Tuning 2"
            echo ""
            nikto -h "$TARGET" -Tuning 2 || true
        fi
    else
        read -rp "Run a quick Tuning 2 scan (interesting files) against ${TARGET}? [y/N] " answer
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            info "Running: nikto -h ${TARGET} -Tuning 2"
            echo ""
            nikto -h "$TARGET" -Tuning 2 || true
        fi
    fi
fi
