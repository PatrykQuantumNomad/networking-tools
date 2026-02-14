#!/usr/bin/env bash
# ============================================================================
# @description  Crack common web application hashes
# @usage        hashcat/crack-web-hashes.sh [target] [-h|--help] [-x|--execute] [-j|--json]
# @dependencies hashcat, common.sh
# ============================================================================
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [hashfile] [-h|--help] [-j|--json]"
    echo ""
    echo "Description:"
    echo "  Cracks common web application password hashes including MD5, SHA-256,"
    echo "  bcrypt, WordPress (phpass), Django, and MySQL hashes."
    echo "  Different web frameworks use different hash types with varying security."
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")              # Show web hash cracking techniques"
    echo "  $(basename "$0") hashes.txt   # Show techniques for your hash file"
    echo "  $(basename "$0") --help       # Show this help message"
    echo ""
    echo "Flags:"
    echo "  -h, --help     Show this help message"
    echo "  -j, --json     Output results as JSON (requires jq)"
    echo "  -x, --execute  Execute commands instead of displaying them"
}

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

require_cmd hashcat "brew install hashcat"

HASHFILE="${1:-}"
WORDLIST="${PROJECT_ROOT}/wordlists/rockyou.txt"

json_set_meta "hashcat" "$HASHFILE" "password-cracker"

confirm_execute
safety_banner

info "=== Web Application Hash Cracking ==="
if [[ -n "$HASHFILE" ]]; then
    info "Hash file: ${HASHFILE}"
fi
echo ""

info "Why do web hashes matter?"
echo "   Different web frameworks store passwords differently:"
echo ""
echo "   Mode  | Type            | Speed      | Security"
echo "   ------|-----------------|------------|----------"
echo "   0     | MD5             | Very fast  | Weak"
echo "   100   | SHA-1           | Very fast  | Weak"
echo "   1400  | SHA-256         | Fast       | Weak (unsalted)"
echo "   1700  | SHA-512         | Fast       | Weak (unsalted)"
echo "   3200  | bcrypt          | Very slow  | Strong"
echo "   400   | WordPress/phpass| Slow       | Moderate"
echo "   10000 | Django PBKDF2   | Very slow  | Strong"
echo "   300   | MySQL 4.1+      | Very fast  | Weak"
echo ""
echo "   bcrypt is intentionally slow (cost factor), making GPU attacks"
echo "   much harder. MD5/SHA without salt is trivially fast to crack."
echo ""

HFILE="${HASHFILE:-hashes.txt}"

# 1. Crack MD5 hashes
info "1) Crack MD5 hashes (mode 0)"
echo "   hashcat -m 0 -a 0 ${HFILE} ${WORDLIST}"
echo ""
json_add_example "1) Crack MD5 hashes (mode 0)" \
    "hashcat -m 0 -a 0 ${HFILE} ${WORDLIST}"

# 2. Crack SHA-1 hashes
info "2) Crack SHA-1 hashes (mode 100)"
echo "   hashcat -m 100 -a 0 ${HFILE} ${WORDLIST}"
echo ""
json_add_example "2) Crack SHA-1 hashes (mode 100)" \
    "hashcat -m 100 -a 0 ${HFILE} ${WORDLIST}"

# 3. Crack SHA-256 hashes
info "3) Crack SHA-256 hashes (mode 1400)"
echo "   hashcat -m 1400 -a 0 ${HFILE} ${WORDLIST}"
echo ""
json_add_example "3) Crack SHA-256 hashes (mode 1400)" \
    "hashcat -m 1400 -a 0 ${HFILE} ${WORDLIST}"

# 4. Crack SHA-512 hashes
info "4) Crack SHA-512 hashes (mode 1700)"
echo "   hashcat -m 1700 -a 0 ${HFILE} ${WORDLIST}"
echo ""
json_add_example "4) Crack SHA-512 hashes (mode 1700)" \
    "hashcat -m 1700 -a 0 ${HFILE} ${WORDLIST}"

# 5. Crack bcrypt hashes (slow!)
info "5) Crack bcrypt hashes (mode 3200) — expect slow speed"
echo "   hashcat -m 3200 -a 0 ${HFILE} ${WORDLIST}"
echo ""
json_add_example "5) Crack bcrypt hashes (mode 3200) — expect slow speed" \
    "hashcat -m 3200 -a 0 ${HFILE} ${WORDLIST}"

# 6. Crack WordPress hashes (phpass)
info "6) Crack WordPress/phpass hashes (mode 400)"
echo "   hashcat -m 400 -a 0 ${HFILE} ${WORDLIST}"
echo ""
json_add_example "6) Crack WordPress/phpass hashes (mode 400)" \
    "hashcat -m 400 -a 0 ${HFILE} ${WORDLIST}"

# 7. Crack Django SHA-256 hashes
info "7) Crack Django PBKDF2-SHA256 hashes (mode 10000)"
echo "   hashcat -m 10000 -a 0 ${HFILE} ${WORDLIST}"
echo ""
json_add_example "7) Crack Django PBKDF2-SHA256 hashes (mode 10000)" \
    "hashcat -m 10000 -a 0 ${HFILE} ${WORDLIST}"

# 8. Crack MySQL 4.1+ hashes
info "8) Crack MySQL 4.1+ hashes (mode 300)"
echo "   hashcat -m 300 -a 0 ${HFILE} ${WORDLIST}"
echo ""
json_add_example "8) Crack MySQL 4.1+ hashes (mode 300)" \
    "hashcat -m 300 -a 0 ${HFILE} ${WORDLIST}"

# 9. Crack MD5 with salt (md5($salt.$pass))
info "9) Crack salted MD5 — md5(salt.pass) format (mode 20)"
echo "   hashcat -m 20 -a 0 ${HFILE} ${WORDLIST}"
echo ""
json_add_example "9) Crack salted MD5 — md5(salt.pass) format (mode 20)" \
    "hashcat -m 20 -a 0 ${HFILE} ${WORDLIST}"

# 10. Identify hash type by trying common modes
info "10) Identify unknown hash type"
echo "    hashcat --identify hash.txt"
echo ""
json_add_example "10) Identify unknown hash type" \
    "hashcat --identify hash.txt"

json_finalize

# Interactive demo (skip if non-interactive)
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    [[ ! -t 0 ]] && exit 0

    echo ""
    info "Demo: Crack a known MD5 hash"
    echo "   The MD5 hash of 'admin123' is: 0192023a7bbd73250516f069df18b500"
    echo ""
    read -rp "Create a temp hash file and attempt to crack it? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        TMPFILE=$(mktemp /tmp/md5-demo.XXXXXX)
        echo "0192023a7bbd73250516f069df18b500" > "$TMPFILE"
        info "Hash written to: ${TMPFILE}"
        info "Running: hashcat -m 0 -a 3 ${TMPFILE} ?l?l?l?l?l?d?d?d"
        hashcat -m 0 -a 3 "$TMPFILE" '?l?l?l?l?l?d?d?d' 2>/dev/null || warn "Crack attempt finished — check hashcat output above"
        echo ""
        info "Running: hashcat -m 0 ${TMPFILE} --show"
        hashcat -m 0 "$TMPFILE" --show 2>/dev/null || true
        rm -f "$TMPFILE"
    fi
fi
