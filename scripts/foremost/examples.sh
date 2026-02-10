#!/usr/bin/env bash
# foremost/examples.sh — File carving and recovery from disk images
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [disk-image] [-h|--help]"
    echo ""
    echo "Description:"
    echo "  Foremost recovers deleted and embedded files from disk images,"
    echo "  memory dumps, and raw data by matching known file header and"
    echo "  footer signatures (magic bytes)."
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")                  # Show examples only"
    echo "  $(basename "$0") image.dd         # Show examples with target image"
    echo "  $(basename "$0") --help           # Show this help message"
}

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

require_cmd foremost "brew install foremost"

TARGET="${1:-}"

safety_banner

info "=== Foremost Examples ==="
[[ -n "$TARGET" ]] && info "Input: ${TARGET}"
echo ""

# 1. Basic file recovery from disk image
info "1) Basic file recovery from disk image"
echo "   foremost -i image.dd"
echo ""

# 2. Specify output directory
info "2) Specify output directory"
echo "   foremost -i image.dd -o recovered/"
echo ""

# 3. Recover only JPEG images
info "3) Recover only JPEG images"
echo "   foremost -i image.dd -t jpg -o recovered_jpgs/"
echo ""

# 4. Recover multiple file types
info "4) Recover multiple file types"
echo "   foremost -i image.dd -t jpg,pdf,doc -o recovered/"
echo ""

# 5. Recover all supported file types
info "5) Recover all supported file types"
echo "   foremost -i image.dd -t all -o recovered/"
echo ""

# 6. Verbose mode with detailed logging
info "6) Verbose mode with detailed logging"
echo "   foremost -v -i image.dd -o recovered/"
echo ""

# 7. Quick mode (process faster)
info "7) Quick mode (process faster)"
echo "   foremost -q -i image.dd -o recovered/"
echo ""

# 8. Use timestamped output directory
info "8) Use timestamped output directory"
echo "   foremost -T -i image.dd -o recovered/"
echo ""

# 9. Indirect block detection for ext2/3
info "9) Indirect block detection for ext2/3 filesystems"
echo "   foremost -d -i image.dd -o recovered/"
echo ""

# 10. Use custom configuration file
info "10) Use custom configuration file"
echo "    foremost -c /usr/local/etc/foremost.conf -i image.dd -o recovered/"
echo ""

# Non-interactive exit guard
[[ ! -t 0 ]] && exit 0

# Interactive demo
if [[ -n "$TARGET" && -f "$TARGET" ]]; then
    read -rp "Run foremost on ${TARGET}? This will carve files to ./foremost_demo/ [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        info "Running: foremost -v -i ${TARGET} -o foremost_demo/"
        foremost -v -i "$TARGET" -o foremost_demo/
    fi
else
    read -rp "Show foremost version? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        info "Running: foremost -V"
        foremost -V
    fi
fi
