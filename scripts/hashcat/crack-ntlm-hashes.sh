#!/usr/bin/env bash
# hashcat/crack-ntlm-hashes.sh — Crack Windows NTLM hashes with GPU acceleration
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [hashfile] [-h|--help]"
    echo ""
    echo "Description:"
    echo "  Cracks Windows NTLM password hashes using GPU-accelerated attacks."
    echo "  NTLM is the default Windows password hash and has no salt, making"
    echo "  it extremely fast to crack. Mode 1000 = NTLM in hashcat."
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")              # Show NTLM cracking techniques"
    echo "  $(basename "$0") hashes.txt   # Show techniques for your hash file"
    echo "  $(basename "$0") --help       # Show this help message"
}

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

require_cmd hashcat "brew install hashcat"

HASHFILE="${1:-}"
WORDLIST="${PROJECT_ROOT}/wordlists/rockyou.txt"

safety_banner

info "=== NTLM Hash Cracking ==="
if [[ -n "$HASHFILE" ]]; then
    info "Hash file: ${HASHFILE}"
fi
echo ""

info "Why target NTLM hashes?"
echo "   NTLM is the default password hash in Windows Active Directory."
echo "   Unlike bcrypt or SHA-512crypt, NTLM has NO salt — identical passwords"
echo "   always produce the same hash, making precomputed attacks viable."
echo "   NTLM is just MD4(UTF-16LE(password)), so GPUs crack it extremely fast."
echo "   A modern GPU can test billions of NTLM hashes per second."
echo ""
echo "   Common sources of NTLM hashes:"
echo "   - Active Directory database (ntds.dit) extracted via secretsdump"
echo "   - SAM database from a Windows machine"
echo "   - Mimikatz output from memory dumps"
echo ""

HFILE="${HASHFILE:-hashes.txt}"

# 1. Dictionary attack on NTLM hashes
info "1) Dictionary attack on NTLM hashes"
echo "   hashcat -m 1000 -a 0 ${HFILE} ${WORDLIST}"
echo ""

# 2. Dictionary + best64 rules
info "2) Dictionary + best64 rules (smart word mutations)"
echo "   hashcat -m 1000 -a 0 ${HFILE} wordlist.txt -r /usr/share/hashcat/rules/best64.rule"
echo ""

# 3. Dictionary + dive rules (more thorough)
info "3) Dictionary + dive rules (more thorough, slower)"
echo "   hashcat -m 1000 -a 0 ${HFILE} wordlist.txt -r /usr/share/hashcat/rules/dive.rule"
echo ""

# 4. Brute force — 8 char all lowercase
info "4) Brute force — 8 character all lowercase"
echo "   hashcat -m 1000 -a 3 ${HFILE} ?l?l?l?l?l?l?l?l"
echo ""

# 5. Mask attack — common pattern Uppercase+lower+digits
info "5) Mask attack — common pattern Uppercase+lower+digits"
echo "   hashcat -m 1000 -a 3 ${HFILE} ?u?l?l?l?l?d?d?d"
echo ""

# 6. Combinator attack — two wordlists combined
info "6) Combinator attack — two wordlists combined"
echo "   hashcat -m 1000 -a 1 ${HFILE} wordlist1.txt wordlist2.txt"
echo ""

# 7. Show already-cracked results
info "7) Show already-cracked results from potfile"
echo "   hashcat -m 1000 ${HFILE} --show"
echo ""

# 8. Resume interrupted session
info "8) Resume an interrupted cracking session"
echo "   hashcat -m 1000 --restore"
echo ""

# 9. Optimize for speed (workload high)
info "9) Optimize for speed with high workload profile"
echo "   hashcat -m 1000 -a 0 -w 3 ${HFILE} wordlist.txt"
echo ""

# 10. Output cracked hashes to file
info "10) Output cracked hashes to file"
echo "    hashcat -m 1000 -a 0 ${HFILE} wordlist.txt -o cracked.txt --outfile-format=2"
echo ""

# Interactive demo (skip if non-interactive, e.g. running via make)
[[ ! -t 0 ]] && exit 0

echo ""
info "Demo: Crack a known NTLM hash"
echo "   The NTLM hash of 'password' is: a4f49c406510bdcab6824ee7c30fd852"
echo ""
read -rp "Create a temp hash file and attempt to crack it? [y/N] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    TMPFILE=$(mktemp /tmp/ntlm-demo.XXXXXX)
    echo "a4f49c406510bdcab6824ee7c30fd852" > "$TMPFILE"
    info "Hash written to: ${TMPFILE}"
    info "Running: hashcat -m 1000 -a 0 ${TMPFILE} --show (checking potfile first)"
    hashcat -m 1000 -a 0 "$TMPFILE" --show 2>/dev/null || true
    echo ""
    info "Running: hashcat -m 1000 -a 3 ${TMPFILE} ?l?l?l?l?l?l?l?l"
    hashcat -m 1000 -a 3 "$TMPFILE" '?l?l?l?l?l?l?l?l' 2>/dev/null || true
    rm -f "$TMPFILE"
fi
