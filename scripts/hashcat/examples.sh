#!/usr/bin/env bash
# hashcat/examples.sh — GPU-accelerated password recovery
source "$(dirname "$0")/../common.sh"

show_help() {
    cat <<EOF
Usage: $(basename "$0")

Hashcat - GPU-accelerated password recovery examples

Displays common hashcat commands for dictionary attacks, brute force,
rule-based attacks, and GPU benchmarking workflows.

Examples:
    $(basename "$0")
    $(basename "$0") --help
EOF
}

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

require_cmd hashcat "brew install hashcat"
confirm_execute
safety_banner

SAMPLE_DIR="$PROJECT_ROOT/scripts/hashcat/samples"
mkdir -p "$SAMPLE_DIR" || { error "Cannot create $SAMPLE_DIR"; exit 1; }

info "=== Hashcat Examples ==="
echo ""

# Create sample hash files for practice
if [[ ! -f "$SAMPLE_DIR/md5.txt" ]]; then
    info "Creating sample hash files for practice..."
    # MD5 of "password123"
    echo "482c811da5d5b4bc6d497ffa98491e38" > "$SAMPLE_DIR/md5.txt"
    # SHA256 of "letmein"
    echo "1c8bfe8f801d79745c4631d09fff36c82aa37fc4cce4fc946683d7b336b63032" > "$SAMPLE_DIR/sha256.txt"
    success "Sample hashes created in $SAMPLE_DIR"
fi

# 1. Identify hash type
info "1) Identify a hash type (use online tools or hashid)"
echo "   hashcat --identify hash.txt"
echo ""

# 2. Dictionary attack on MD5
info "2) Dictionary attack (MD5 = mode 0)"
echo "   hashcat -m 0 -a 0 hash.txt wordlist.txt"
echo ""

# 3. Dictionary attack on SHA256
info "3) Dictionary attack (SHA256 = mode 1400)"
echo "   hashcat -m 1400 -a 0 hash.txt wordlist.txt"
echo ""

# 4. Brute force attack
info "4) Brute force — try all 6-char combos"
echo "   hashcat -m 0 -a 3 hash.txt '?a?a?a?a?a?a'"
echo ""

# 5. Rule-based attack (most effective)
info "5) Dictionary + rules (best for real-world passwords)"
echo "   hashcat -m 0 -a 0 hash.txt wordlist.txt -r rules/best64.rule"
echo ""

# 6. Mask attack with known pattern
info "6) Mask attack (e.g., Password + 2 digits)"
echo "   hashcat -m 0 -a 3 hash.txt 'Password?d?d'"
echo ""

# 7. Combinator attack (word1+word2)
info "7) Combinator attack"
echo "   hashcat -m 0 -a 1 hash.txt wordlist1.txt wordlist2.txt"
echo ""

# 8. Show cracked passwords
info "8) Show previously cracked results"
echo "   hashcat -m 0 hash.txt --show"
echo ""

# 9. Benchmark GPU speed
info "9) Benchmark all hash modes"
echo "   hashcat -b"
echo ""

# 10. Crack WPA handshake
info "10) Crack WPA/WPA2 (mode 22000)"
echo "    hashcat -m 22000 -a 0 handshake.hc22000 wordlist.txt"
echo ""

# Interactive demo (skip if non-interactive)
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    [[ ! -t 0 ]] && exit 0
    read -rp "Run a quick benchmark? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        info "Running: hashcat -b -m 0 (MD5 benchmark)"
        hashcat -b -m 0 2>/dev/null || warn "Hashcat benchmark may need OpenCL drivers"
    fi
fi
