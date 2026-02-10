#!/usr/bin/env bash
# john/crack-linux-passwords.sh — Extract and crack Linux /etc/shadow password hashes
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [-h|--help]"
    echo ""
    echo "Description:"
    echo "  Demonstrates how to extract and crack Linux /etc/shadow password hashes"
    echo "  using John the Ripper. Covers the unshadow workflow, common hash formats,"
    echo "  and cracking strategies."
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")        # Show Linux password cracking techniques"
    echo "  $(basename "$0") --help # Show this help message"
}

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

require_cmd john "brew install john"
WORDLIST="${PROJECT_ROOT}/wordlists/rockyou.txt"

safety_banner

info "=== Linux Password Cracking ==="
echo ""

info "How Linux stores passwords"
echo "   Linux passwords are hashed in /etc/shadow (readable only by root)."
echo "   The hash format is: \$id\$salt\$hash"
echo ""
echo "   Common hash type prefixes:"
echo "   \$6\$  = SHA-512 (most common on modern Linux)"
echo "   \$5\$  = SHA-256"
echo "   \$y\$  = yescrypt (newer distros like Debian 11+)"
echo "   \$2b\$ = bcrypt (some BSD systems)"
echo "   \$1\$  = MD5 (legacy, insecure)"
echo ""
echo "   John needs both /etc/passwd (usernames) and /etc/shadow (hashes)."
echo "   The 'unshadow' utility combines them into a crackable format."
echo ""

# 1. Combine passwd and shadow files
info "1) Combine passwd and shadow files with unshadow"
echo "   sudo unshadow /etc/passwd /etc/shadow > unshadowed.txt"
echo ""

# 2. Crack with default settings (auto-detect)
info "2) Crack with default settings — auto-detects hash type"
echo "   john unshadowed.txt"
echo ""

# 3. Crack with a wordlist
info "3) Crack with a wordlist"
echo "   john --wordlist=${WORDLIST} unshadowed.txt"
echo ""

# 4. Crack with wordlist + rules
info "4) Crack with wordlist + rules for word mutations"
echo "   john --wordlist=wordlist.txt --rules=best64 unshadowed.txt"
echo ""

# 5. Show cracked passwords
info "5) Show cracked passwords from previous sessions"
echo "   john --show unshadowed.txt"
echo ""

# 6. Target specific user only
info "6) Target a specific user only"
echo "   john --users=admin unshadowed.txt"
echo ""

# 7. Incremental (brute force) mode
info "7) Incremental (brute force) mode — tries all combinations"
echo "   john --incremental unshadowed.txt"
echo ""

# 8. Specify hash format explicitly
info "8) Specify hash format explicitly"
echo "   john --format=sha512crypt unshadowed.txt"
echo ""

# 9. Use multiple CPU cores
info "9) Use multiple CPU cores for parallel cracking"
echo "   john --fork=4 --wordlist=rockyou.txt unshadowed.txt"
echo ""

# 10. Check password strength of cracked results
info "10) Review cracked usernames and passwords"
echo "    john --show --format=sha512crypt unshadowed.txt | cut -d: -f1,2"
echo ""

# Interactive demo (skip if non-interactive, e.g. running via make)
[[ ! -t 0 ]] && exit 0

echo ""
info "Demo: Crack a sample shadow hash"
echo "   Creating a test SHA-512 hash of password 'letmein' with a known salt."
echo ""
read -rp "Create a sample hash and crack it with John? [y/N] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    TMPFILE=$(mktemp /tmp/john-demo.XXXXXX)
    # Generate a SHA-512crypt hash for "letmein" using openssl or python
    if check_cmd python3; then
        HASH=$(python3 -c "import crypt; print('testuser:' + crypt.crypt('letmein', '\$6\$rounds=5000\$testsalt\$'))" 2>/dev/null) || true
    fi
    if [[ -z "${HASH:-}" ]] && check_cmd openssl; then
        HASH="testuser:\$6\$testsalt\$$(openssl passwd -6 -salt testsalt 'letmein' 2>/dev/null)" || true
    fi
    if [[ -n "${HASH:-}" ]]; then
        echo "$HASH" > "$TMPFILE"
        info "Test hash written to: ${TMPFILE}"
        info "Running: john --wordlist --format=sha512crypt ${TMPFILE}"
        john --format=sha512crypt "$TMPFILE" 2>/dev/null || warn "John exited — check output above"
        echo ""
        info "Running: john --show ${TMPFILE}"
        john --show "$TMPFILE" 2>/dev/null || true
    else
        warn "Could not generate test hash (need python3 or openssl)"
    fi
    rm -f "$TMPFILE"
fi
