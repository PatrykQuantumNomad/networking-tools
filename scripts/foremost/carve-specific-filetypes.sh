#!/usr/bin/env bash
# foremost/carve-specific-filetypes.sh — Carve specific file types from disk images
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [disk-image] [-h|--help]"
    echo ""
    echo "Description:"
    echo "  Demonstrates how to use foremost's -t flag to target specific"
    echo "  file types during recovery. Covers images, documents, archives,"
    echo "  executables, and media files."
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")                  # Show file type carving examples"
    echo "  $(basename "$0") disk.img         # Show examples with target image"
    echo "  $(basename "$0") --help           # Show this help message"
}

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

require_cmd foremost "brew install foremost"

TARGET="${1:-}"

safety_banner

info "=== Carving Specific File Types with Foremost ==="
[[ -n "$TARGET" ]] && info "Input: ${TARGET}"
echo ""

info "File signatures (magic bytes):"
echo "   Every file type has a unique header pattern that identifies it."
echo "   Foremost matches these signatures in raw binary data to carve"
echo "   out complete files, even without a filesystem."
echo ""
echo "   Common signatures:"
echo "   - JPEG:  FF D8 FF (start) / FF D9 (end)"
echo "   - PDF:   %PDF- (start) / %%EOF (end)"
echo "   - ZIP:   PK (50 4B 03 04)"
echo "   - PNG:   89 50 4E 47 0D 0A 1A 0A"
echo "   - GIF:   GIF89a or GIF87a"
echo "   - EXE:   MZ (4D 5A)"
echo ""
echo "   Supported types:"
echo "   jpg gif png bmp pdf doc xls ppt"
echo "   ole zip rar htm cpp exe mp4 wav"
echo "   mov wmv avi"
echo ""

# 1. Extract only JPEG images
info "1) Extract only JPEG images"
echo "   foremost -t jpg -i disk.img -o recovered_jpg/"
echo ""

# 2. Extract only PDF documents
info "2) Extract only PDF documents"
echo "   foremost -t pdf -i disk.img -o recovered_pdf/"
echo ""

# 3. Extract Microsoft Office documents
info "3) Extract Microsoft Office documents"
echo "   foremost -t doc,xls,ppt -i disk.img -o recovered_office/"
echo ""

# 4. Extract executables
info "4) Extract executables"
echo "   foremost -t exe -i disk.img -o recovered_exe/"
echo ""

# 5. Extract archives (ZIP, RAR)
info "5) Extract archives (ZIP, RAR)"
echo "   foremost -t zip,rar -i disk.img -o recovered_archives/"
echo ""

# 6. Extract all image types
info "6) Extract all image types"
echo "   foremost -t jpg,gif,png,bmp -i disk.img -o recovered_images/"
echo ""

# 7. Extract all supported types
info "7) Extract all supported types"
echo "   foremost -t all -i disk.img -o recovered_all/"
echo ""

# 8. Verbose extraction with specific types
info "8) Verbose extraction with specific types"
echo "   foremost -v -t jpg,pdf -i disk.img -o recovered/"
echo ""

# 9. Extract media files
info "9) Extract media files"
echo "   foremost -t mov,mp4,avi,wav,wmv -i disk.img -o recovered_media/"
echo ""

# 10. Compare specific vs all recovery
info "10) Compare specific vs all recovery"
echo "    foremost -t jpg -i disk.img -o jpg_only/ && foremost -t all -i disk.img -o everything/"
echo ""

# Interactive demo (skip if non-interactive)
[[ ! -t 0 ]] && exit 0

# Interactive demo
if [[ -n "$TARGET" && -f "$TARGET" ]]; then
    read -rp "Run foremost to carve JPEGs from ${TARGET}? Output to ./carved_jpgs/ [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        info "Running: foremost -v -t jpg -i ${TARGET} -o carved_jpgs/"
        foremost -v -t jpg -i "$TARGET" -o carved_jpgs/
    fi
else
    read -rp "Show foremost version? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        info "Running: foremost -V"
        foremost -V
    fi
fi
