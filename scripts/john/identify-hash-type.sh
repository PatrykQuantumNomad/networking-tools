#!/usr/bin/env bash
# john/identify-hash-type.sh — Identify unknown hash types and find the correct John format
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [hash] [-h|--help]"
    echo ""
    echo "Description:"
    echo "  Helps identify unknown hash types by pattern, length, and prefix."
    echo "  Shows how to find the correct John the Ripper format for cracking."
    echo "  Optionally pass a hash string as argument for pattern analysis."
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")                                       # Show hash ID techniques"
    echo "  $(basename "$0") '5f4dcc3b5aa765d61d8327deb882cf99'    # Analyze a hash"
    echo "  $(basename "$0") --help                                # Show this help message"
}

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

require_cmd john "brew install john"

safety_banner

HASH="${1:-}"

info "=== Hash Type Identification ==="
if [[ -n "$HASH" ]]; then
    info "Hash: ${HASH}"
fi
echo ""

info "How to identify hash types"
echo "   Hash type can often be identified by length, character set, and prefix:"
echo ""
echo "   Length | Characters | Likely Type"
echo "   -------|------------|-------------------"
echo "   32     | hex        | MD5, NTLM"
echo "   40     | hex        | SHA-1, MySQL 4.1+"
echo "   64     | hex        | SHA-256"
echo "   128    | hex        | SHA-512"
echo ""
echo "   Common prefixes:"
echo "   \$1\$        — MD5crypt (Linux)"
echo "   \$2a\$/\$2b\$ — bcrypt"
echo "   \$5\$        — SHA-256crypt (Linux)"
echo "   \$6\$        — SHA-512crypt (Linux)"
echo "   \$y\$        — yescrypt (newer Linux)"
echo "   \$P\$/\$H\$   — WordPress/phpBB (phpass)"
echo "   \$apr1\$     — Apache MD5"
echo ""

# 1. List all supported John formats
info "1) List all supported John formats"
echo "   john --list=formats"
echo ""

# 2. List formats matching "md5"
info "2) List formats matching 'md5'"
echo "   john --list=formats | grep -i md5"
echo ""

# 3. List formats matching "sha"
info "3) List formats matching 'sha'"
echo "   john --list=formats | grep -i sha"
echo ""

# 4. Test with raw-md5 format
info "4) Test a hash with raw-md5 format"
echo "   john --format=raw-md5 hash.txt"
echo ""

# 5. Test with raw-sha256 format
info "5) Test a hash with raw-sha256 format"
echo "   john --format=raw-sha256 hash.txt"
echo ""

# 6. Test with bcrypt format
info "6) Test a hash with bcrypt format"
echo "   john --format=bcrypt hash.txt"
echo ""

# 7. Test with NTLM format
info "7) Test a hash with NTLM format"
echo "   john --format=nt hash.txt"
echo ""

# 8. Test with sha512crypt (Linux $6$)
info "8) Test a hash with sha512crypt (Linux \$6\$)"
echo "   john --format=sha512crypt hash.txt"
echo ""

# 9. Show format details and test vectors
info "9) Show format details and test vectors"
echo "   john --list=format-details --format=raw-md5"
echo ""

# 10. Auto-detect format by running John directly
info "10) Auto-detect format by running John directly"
echo "    john hash.txt"
echo ""

# Interactive demo (skip if non-interactive)
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    [[ ! -t 0 ]] && exit 0

    if [[ -n "$HASH" ]]; then
        echo ""
        info "Analyzing provided hash: ${HASH}"
        HLEN=${#HASH}
        echo "   Length: ${HLEN} characters"

        # Pattern matching for common hash types
        if [[ "$HASH" =~ ^\$6\$ ]]; then
            echo "   Prefix: \$6\$ — SHA-512crypt (Linux)"
            echo "   John format: --format=sha512crypt"
        elif [[ "$HASH" =~ ^\$5\$ ]]; then
            echo "   Prefix: \$5\$ — SHA-256crypt (Linux)"
            echo "   John format: --format=sha256crypt"
        elif [[ "$HASH" =~ ^\$1\$ ]]; then
            echo "   Prefix: \$1\$ — MD5crypt (Linux)"
            echo "   John format: --format=md5crypt"
        elif [[ "$HASH" =~ ^\$2[aby]\$ ]]; then
            echo "   Prefix: \$2b\$ — bcrypt"
            echo "   John format: --format=bcrypt"
        elif [[ "$HASH" =~ ^\$y\$ ]]; then
            echo "   Prefix: \$y\$ — yescrypt"
            echo "   John format: --format=crypt"
        elif [[ "$HASH" =~ ^\$P\$|^\$H\$ ]]; then
            echo "   Prefix: \$P\$/\$H\$ — phpass (WordPress/phpBB)"
            echo "   John format: --format=phpass"
        elif [[ $HLEN -eq 32 ]] && [[ "$HASH" =~ ^[0-9a-fA-F]+$ ]]; then
            echo "   32 hex chars — likely MD5 or NTLM"
            echo "   John format: --format=raw-md5 or --format=nt"
        elif [[ $HLEN -eq 40 ]] && [[ "$HASH" =~ ^[0-9a-fA-F]+$ ]]; then
            echo "   40 hex chars — likely SHA-1"
            echo "   John format: --format=raw-sha1"
        elif [[ $HLEN -eq 64 ]] && [[ "$HASH" =~ ^[0-9a-fA-F]+$ ]]; then
            echo "   64 hex chars — likely SHA-256"
            echo "   John format: --format=raw-sha256"
        elif [[ $HLEN -eq 128 ]] && [[ "$HASH" =~ ^[0-9a-fA-F]+$ ]]; then
            echo "   128 hex chars — likely SHA-512"
            echo "   John format: --format=raw-sha512"
        else
            echo "   Could not auto-identify — try: john --list=formats | grep -i <keyword>"
        fi
        echo ""
    else
        echo ""
        info "Tip: Pass a hash as an argument for automatic pattern analysis."
        echo "   $(basename "$0") '5f4dcc3b5aa765d61d8327deb882cf99'"
        echo ""
    fi
fi
