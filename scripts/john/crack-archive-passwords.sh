#!/usr/bin/env bash
# john/crack-archive-passwords.sh — Crack password-protected ZIP, RAR, 7z, and other archives
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [archive] [-h|--help]"
    echo ""
    echo "Description:"
    echo "  Cracks password-protected archives (ZIP, RAR, 7z, PDF, Office docs)"
    echo "  using John the Ripper. First extracts the hash with a *2john utility,"
    echo "  then cracks the extracted hash."
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")                  # Show archive cracking techniques"
    echo "  $(basename "$0") protected.zip    # Show techniques for your archive"
    echo "  $(basename "$0") --help           # Show this help message"
}

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

require_cmd john "brew install john"

ARCHIVE="${1:-}"
WORDLIST="${PROJECT_ROOT}/wordlists/rockyou.txt"

confirm_execute
safety_banner

info "=== Archive Password Cracking ==="
if [[ -n "$ARCHIVE" ]]; then
    info "Archive: ${ARCHIVE}"
fi
echo ""

info "Why a two-step process?"
echo "   John cannot crack archives directly. You must first extract the"
echo "   password hash from the archive using a *2john utility, then crack"
echo "   the extracted hash."
echo ""
echo "   Available *2john extraction utilities:"
echo "   zip2john     — ZIP archives"
echo "   rar2john     — RAR archives"
echo "   7z2john      — 7-Zip archives"
echo "   pdf2john     — PDF files"
echo "   ssh2john     — SSH private keys"
echo "   keepass2john — KeePass databases"
echo "   office2john  — Microsoft Office documents"
echo "   gpg2john     — GPG/PGP keys"
echo "   dmg2john     — macOS disk images"
echo "   bitlocker2john — BitLocker volumes"
echo ""

# 1. Extract hash from ZIP file
info "1) Extract hash from a ZIP file"
echo "   zip2john protected.zip > zip.hash"
echo ""

# 2. Crack extracted ZIP hash
info "2) Crack the extracted ZIP hash"
echo "   john --wordlist=${WORDLIST} zip.hash"
echo ""

# 3. Extract hash from RAR file
info "3) Extract hash from a RAR file"
echo "   rar2john protected.rar > rar.hash"
echo ""

# 4. Extract hash from 7z file
info "4) Extract hash from a 7-Zip file"
echo "   7z2john protected.7z > 7z.hash"
echo ""

# 5. Extract hash from PDF
info "5) Extract hash from a PDF file"
echo "   pdf2john protected.pdf > pdf.hash"
echo ""

# 6. Extract hash from SSH private key
info "6) Extract hash from an SSH private key"
echo "   ssh2john id_rsa > ssh.hash"
echo ""

# 7. Extract hash from KeePass database
info "7) Extract hash from a KeePass database"
echo "   keepass2john database.kdbx > keepass.hash"
echo ""

# 8. Extract hash from Office document
info "8) Extract hash from a Microsoft Office document"
echo "   office2john protected.docx > office.hash"
echo ""

# 9. Show cracked archive password
info "9) Show cracked archive password"
echo "   john --show zip.hash"
echo ""

# 10. Crack with mask (if you know password pattern)
info "10) Crack with a mask if you know the password pattern"
echo "    john --mask='?d?d?d?d' zip.hash"
echo ""

# Interactive demo (skip if non-interactive)
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    [[ ! -t 0 ]] && exit 0

    echo ""
    info "Demo: Create and crack a password-protected ZIP"
    echo "   Will create a ZIP with password 'test123', extract the hash, and crack it."
    echo ""
    read -rp "Run the ZIP cracking demo? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        TMPDIR=$(mktemp -d /tmp/john-zip-demo.XXXXXX)
        echo "This is a test file for password cracking demo." > "${TMPDIR}/secret.txt"

        if check_cmd zip; then
            zip -j -P test123 "${TMPDIR}/protected.zip" "${TMPDIR}/secret.txt" 2>/dev/null
            info "Created: ${TMPDIR}/protected.zip (password: test123)"

            if check_cmd zip2john; then
                zip2john "${TMPDIR}/protected.zip" > "${TMPDIR}/zip.hash" 2>/dev/null
                info "Extracted hash to: ${TMPDIR}/zip.hash"
                info "Running: john --format=PKZIP ${TMPDIR}/zip.hash"
                john --format=PKZIP "${TMPDIR}/zip.hash" 2>/dev/null || warn "John exited — check output above"
                echo ""
                info "Running: john --show ${TMPDIR}/zip.hash"
                john --show "${TMPDIR}/zip.hash" 2>/dev/null || true
            else
                warn "zip2john not found — install john with: brew install john"
            fi
        else
            warn "zip command not found — cannot create demo archive"
        fi
        rm -rf "$TMPDIR"
    fi
fi
