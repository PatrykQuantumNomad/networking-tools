#!/usr/bin/env bash
# ============================================================================
# @description  Recover deleted files from disk images
# @usage        foremost/recover-deleted-files.sh [target] [-h|--help] [-x|--execute] [-j|--json]
# @dependencies foremost, common.sh
# ============================================================================
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [disk-image] [-h|--help] [-j|--json]"
    echo ""
    echo "Description:"
    echo "  Demonstrates how to recover deleted files from disk images,"
    echo "  partition dumps, USB drive images, and memory dumps using"
    echo "  foremost's header/footer signature matching."
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")                  # Show recovery examples"
    echo "  $(basename "$0") disk.img         # Show examples with target image"
    echo "  $(basename "$0") --help           # Show this help message"
    echo ""
    echo "Flags:"
    echo "  -h, --help     Show this help message"
    echo "  -j, --json     Output results as JSON (requires jq)"
    echo "  -x, --execute  Execute commands instead of displaying them"
}

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

require_cmd foremost "brew install foremost"

TARGET="${1:-}"

json_set_meta "foremost" "$TARGET" "forensics"

confirm_execute "${1:-}"
safety_banner

info "=== Recovering Deleted Files with Foremost ==="
[[ -n "$TARGET" ]] && info "Input: ${TARGET}"
echo ""

info "Why deleted files are recoverable:"
echo "   When you delete a file, the OS removes the directory entry (the"
echo "   pointer to the file) but the actual data blocks remain on disk"
echo "   until they are overwritten by new data. Foremost scans raw binary"
echo "   data for known file headers (magic bytes) and footers to"
echo "   reconstruct complete files -- no filesystem required."
echo ""
echo "   This is why secure deletion tools overwrite data multiple times,"
echo "   and why full-disk encryption is important for sensitive data."
echo ""

# 1. Recover all files from disk image
info "1) Recover all files from disk image"
echo "   foremost -i disk.img -o recovered/"
json_add_example "1) Recover all files from disk image" \
    "foremost -i disk.img -o recovered/"
echo ""

# 2. Recover from raw partition dump
info "2) Recover from raw partition dump"
echo "   foremost -i /dev/sda1 -o recovered/"
json_add_example "2) Recover from raw partition dump" \
    "foremost -i /dev/sda1 -o recovered/"
echo ""

# 3. Recover from USB drive image
info "3) Recover from USB drive image"
echo "   foremost -i usb_backup.dd -o usb_recovered/"
json_add_example "3) Recover from USB drive image" \
    "foremost -i usb_backup.dd -o usb_recovered/"
echo ""

# 4. Verbose recovery with progress
info "4) Verbose recovery with progress"
echo "   foremost -v -i disk.img -o recovered/"
json_add_example "4) Verbose recovery with progress" \
    "foremost -v -i disk.img -o recovered/"
echo ""

# 5. Recovery with timestamped output
info "5) Recovery with timestamped output"
echo "   foremost -T -i disk.img -o recovered/"
json_add_example "5) Recovery with timestamped output" \
    "foremost -T -i disk.img -o recovered/"
echo ""

# 6. Skip first N blocks (skip partition table)
info "6) Skip first N blocks (skip partition table)"
echo "   foremost -s 63 -i disk.img -o recovered/"
json_add_example "6) Skip first N blocks (skip partition table)" \
    "foremost -s 63 -i disk.img -o recovered/"
echo ""

# 7. Quick recovery (no footer validation)
info "7) Quick recovery (no footer validation)"
echo "   foremost -q -i disk.img -o recovered/"
json_add_example "7) Quick recovery (no footer validation)" \
    "foremost -q -i disk.img -o recovered/"
echo ""

# 8. Recover from memory dump
info "8) Recover from memory dump"
echo "   foremost -i memdump.raw -o mem_recovered/"
json_add_example "8) Recover from memory dump" \
    "foremost -i memdump.raw -o mem_recovered/"
echo ""

# 9. Create disk image then recover
info "9) Create disk image then recover"
echo "   dd if=/dev/sda of=disk.img bs=4k && foremost -i disk.img -o recovered/"
json_add_example "9) Create disk image then recover" \
    "dd if=/dev/sda of=disk.img bs=4k && foremost -i disk.img -o recovered/"
echo ""

# 10. Full recovery pipeline with audit
info "10) Full recovery pipeline with audit"
echo "    foremost -v -T -i disk.img -o recovered/ && ls -lR recovered/"
json_add_example "10) Full recovery pipeline with audit" \
    "foremost -v -T -i disk.img -o recovered/ && ls -lR recovered/"
echo ""

json_finalize

# Interactive demo (skip if non-interactive)
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    [[ ! -t 0 ]] && exit 0
    if [[ -n "$TARGET" && -f "$TARGET" ]]; then
        read -rp "Run foremost on ${TARGET}? This will recover files to ./recovered_demo/ [y/N] " answer
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            info "Running: foremost -v -i ${TARGET} -o recovered_demo/"
            foremost -v -i "$TARGET" -o recovered_demo/
        fi
    else
        read -rp "Show foremost version? [y/N] " answer
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            info "Running: foremost -V"
            foremost -V
        fi
    fi
fi
