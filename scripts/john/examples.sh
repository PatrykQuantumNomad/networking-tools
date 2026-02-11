#!/usr/bin/env bash
# john/examples.sh — John the Ripper: password cracking
source "$(dirname "$0")/../common.sh"

show_help() {
    cat <<EOF
Usage: $(basename "$0")

John the Ripper - Password cracking examples

Displays common John the Ripper commands for dictionary attacks,
brute force, hash extraction, and session management workflows.

Examples:
    $(basename "$0")
    $(basename "$0") --help
EOF
}

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

require_cmd john "brew install john"
confirm_execute
safety_banner

SAMPLE_DIR="$PROJECT_ROOT/scripts/john/samples"
mkdir -p "$SAMPLE_DIR" || { error "Cannot create $SAMPLE_DIR"; exit 1; }

info "=== John the Ripper Examples ==="
echo ""

# Create sample password file for practice
if [[ ! -f "$SAMPLE_DIR/hashes.txt" ]]; then
    info "Creating sample hash file..."
    # These are safe practice hashes (MD5 crypt format)
    cat > "$SAMPLE_DIR/hashes.txt" <<'HASHES'
user1:$1$abc$5MkftMgJsJpJx3g1tSAtD1
user2:$1$xyz$RhST5gdTixBcEXjcYbXW71
HASHES
    success "Sample hashes created in $SAMPLE_DIR/hashes.txt"
fi

# 1. Basic dictionary attack
info "1) Dictionary attack with default wordlist"
echo "   john hashes.txt"
echo ""

# 2. Use a specific wordlist
info "2) Attack with a custom wordlist"
echo "   john --wordlist=/path/to/rockyou.txt hashes.txt"
echo ""

# 3. Show cracked passwords
info "3) Display cracked passwords"
echo "   john --show hashes.txt"
echo ""

# 4. Incremental (brute force) mode
info "4) Brute force mode"
echo "   john --incremental hashes.txt"
echo ""

# 5. Specify hash format
info "5) Specify hash type explicitly"
echo "   john --format=raw-md5 hashes.txt"
echo "   john --format=raw-sha256 hashes.txt"
echo ""

# 6. Rules-based attack
info "6) Apply mangling rules to wordlist"
echo "   john --wordlist=words.txt --rules hashes.txt"
echo ""

# 7. Crack /etc/shadow (Linux)
info "7) Crack Linux password hashes"
echo "   sudo unshadow /etc/passwd /etc/shadow > unshadowed.txt"
echo "   john unshadowed.txt"
echo ""

# 8. Crack ZIP file password
info "8) Extract and crack ZIP hash"
echo "   zip2john protected.zip > zip.hash"
echo "   john zip.hash"
echo ""

# 9. Crack SSH private key passphrase
info "9) Crack SSH key passphrase"
echo "   ssh2john id_rsa > ssh.hash"
echo "   john --wordlist=wordlist.txt ssh.hash"
echo ""

# 10. Session management
info "10) Restore interrupted session"
echo "    john --restore=session_name"
echo ""

info "Supported formats: john --list=formats | wc -l"
# Interactive demo (skip if non-interactive)
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    [[ ! -t 0 ]] && exit 0
    read -rp "Show all supported hash formats? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        john --list=formats 2>/dev/null | head -20
        echo "... (use 'john --list=formats' for full list)"
    fi
fi
