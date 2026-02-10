#!/usr/bin/env bash
# foremost/analyze-forensic-image.sh — Forensic file carving from evidence images
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [evidence-image] [-h|--help]"
    echo ""
    echo "Description:"
    echo "  Demonstrates forensic file carving workflows. Covers evidence"
    echo "  preservation, audit trails, memory dump analysis, and batch"
    echo "  processing of forensic images."
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")                  # Show forensic analysis examples"
    echo "  $(basename "$0") evidence.dd      # Show examples with evidence image"
    echo "  $(basename "$0") --help           # Show this help message"
}

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

require_cmd foremost "brew install foremost"

TARGET="${1:-}"

safety_banner

info "=== Forensic Image Analysis with Foremost ==="
[[ -n "$TARGET" ]] && info "Input: ${TARGET}"
echo ""

info "Forensic analysis principles:"
echo "   Forensic analysis requires preserving evidence integrity. Always"
echo "   work on copies, never the original media. Use write-blockers when"
echo "   creating disk images. Document every step for chain of custody."
echo ""
echo "   Foremost is forensically sound because:"
echo "   - It reads input as a stream (read-only by default)"
echo "   - It never modifies the source image"
echo "   - It generates an audit.txt log of all recovered files"
echo "   - Timestamped output (-T) supports evidence tracking"
echo ""
echo "   Key principle: the tool never modifies the source image."
echo ""

# 1. Analyze forensic image (basic)
info "1) Analyze forensic image (basic)"
echo "   foremost -i evidence.dd -o case001/"
echo ""

# 2. Verbose analysis with audit trail
info "2) Verbose analysis with audit trail"
echo "   foremost -v -i evidence.dd -o case001/ 2>&1 | tee foremost_log.txt"
echo ""

# 3. Timestamped evidence extraction
info "3) Timestamped evidence extraction"
echo "   foremost -T -i evidence.dd -o case001/"
echo ""

# 4. Indirect block detection on ext2/3
info "4) Indirect block detection on ext2/3 filesystems"
echo "   foremost -d -i evidence.dd -o case001/"
echo ""

# 5. Custom block size for non-standard images
info "5) Custom block size for non-standard images"
echo "   foremost -b 4096 -i evidence.dd -o case001/"
echo ""

# 6. Recover from memory dump
info "6) Recover artifacts from memory dump"
echo "   foremost -i memory.raw -t jpg,pdf,doc -o mem_artifacts/"
echo ""

# 7. Custom foremost config for new signatures
info "7) Custom foremost config for new signatures"
echo "   foremost -c custom_foremost.conf -i evidence.dd -o case001/"
echo ""

# 8. Process NTFS image
info "8) Process NTFS image for documents and images"
echo "   foremost -i ntfs_partition.dd -t doc,xls,pdf,jpg -o ntfs_recovered/"
echo ""

# 9. Batch process multiple images
info "9) Batch process multiple evidence images"
echo "   for img in evidence_*.dd; do foremost -T -i \"\$img\" -o \"case_\${img%.dd}/\"; done"
echo ""

# 10. Full forensic workflow
info "10) Full forensic workflow (image, hash, carve)"
echo "    dd if=/dev/sdb of=evidence.dd bs=4k status=progress && sha256sum evidence.dd > evidence.sha256 && foremost -v -T -i evidence.dd -o case001/"
echo ""

# Non-interactive exit guard
[[ ! -t 0 ]] && exit 0

# Interactive demo
read -rp "Check foremost installation and show version? [y/N] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    info "Running: foremost -V"
    foremost -V
fi
