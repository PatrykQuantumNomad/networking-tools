#!/usr/bin/env bash
# ============================================================================
# @description  Export files transferred over HTTP/SMB from packet captures
# @usage        tshark/extract-files-from-capture.sh [target] [-h|--help] [-x|--execute]
# @dependencies tshark, common.sh
# ============================================================================
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [capture.pcap] [-h|--help]"
    echo ""
    echo "Description:"
    echo "  Exports files transferred over HTTP, SMB, and other protocols from"
    echo "  packet capture files. Useful for incident response and forensics."
    echo "  Provide a .pcap file as argument, or run without one to see examples."
    echo ""
    echo "Examples:"
    echo "  $(basename "$0") traffic.pcap     # Extract files from traffic.pcap"
    echo "  $(basename "$0")                  # Show example commands"
    echo "  $(basename "$0") --help           # Show this help message"
}

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

require_cmd tshark "brew install wireshark"

FILE="${1:-}"

json_set_meta "tshark" "$FILE" "network-analysis"

confirm_execute "${1:-}"
safety_banner

info "=== File Extraction from Packet Captures ==="
if [[ -n "$FILE" ]]; then
    info "Capture file: ${FILE}"
else
    info "No capture file provided — showing example commands"
fi
echo ""

info "Why extract files from network captures?"
echo "   Files in transit — malware, documents, images — can be reconstructed"
echo "   from packet captures. This is critical for:"
echo "   - Incident response: What files were exfiltrated?"
echo "   - Malware analysis: What was downloaded?"
echo "   - Forensics: Reconstruct attacker activity"
echo ""
echo "   tshark can export HTTP objects (files served by web servers),"
echo "   SMB/CIFS shares, DICOM medical images, and more."
echo "   For live capture, first save traffic to a .pcap file, then extract."
echo ""

# 1. Export HTTP objects
info "1) Export all HTTP objects (files) from pcap"
echo "   tshark -r capture.pcap --export-objects http,exported_files/"
json_add_example "1) Export all HTTP objects (files) from pcap" \
    "tshark -r capture.pcap --export-objects http,exported_files/"
echo ""

# 2. List HTTP transfers
info "2) List HTTP file transfers without extracting"
echo "   tshark -r capture.pcap -Y 'http.content_type' -T fields -e http.host -e http.request.uri -e http.content_type"
json_add_example "2) List HTTP file transfers without extracting" \
    "tshark -r capture.pcap -Y 'http.content_type' -T fields -e http.host -e http.request.uri -e http.content_type"
echo ""

# 3. Export SMB files
info "3) Export SMB/CIFS file transfers"
echo "   tshark -r capture.pcap --export-objects smb,smb_files/"
json_add_example "3) Export SMB/CIFS file transfers" \
    "tshark -r capture.pcap --export-objects smb,smb_files/"
echo ""

# 4. HTTP download URLs
info "4) Show HTTP download URLs"
echo "   tshark -r capture.pcap -Y 'http.request.method==GET' -T fields -e http.host -e http.request.uri"
json_add_example "4) Show HTTP download URLs" \
    "tshark -r capture.pcap -Y 'http.request.method==GET' -T fields -e http.host -e http.request.uri"
echo ""

# 5. Filter file types
info "5) Filter for specific file types"
echo "   tshark -r capture.pcap -Y 'http.content_type contains \"pdf\"' -T fields -e http.request.uri"
json_add_example "5) Filter for specific file types" \
    "tshark -r capture.pcap -Y 'http.content_type contains \"pdf\"' -T fields -e http.request.uri"
echo ""

# 6. HTTP transfer stats
info "6) HTTP transfer statistics"
echo "   tshark -r capture.pcap -q -z http,tree"
json_add_example "6) HTTP transfer statistics" \
    "tshark -r capture.pcap -q -z http,tree"
echo ""

# 7. DICOM images
info "7) Export DICOM medical images"
echo "   tshark -r capture.pcap --export-objects dicom,dicom_files/"
json_add_example "7) Export DICOM medical images" \
    "tshark -r capture.pcap --export-objects dicom,dicom_files/"
echo ""

# 8. File sizes
info "8) Show file sizes transferred"
echo "   tshark -r capture.pcap -Y 'http.content_length' -T fields -e http.host -e http.request.uri -e http.content_length"
json_add_example "8) Show file sizes transferred" \
    "tshark -r capture.pcap -Y 'http.content_length' -T fields -e http.host -e http.request.uri -e http.content_length"
echo ""

# 9. FTP data
info "9) Extract FTP data transfers"
echo "   tshark -r capture.pcap -Y 'ftp-data' -T fields -e frame.number -e data.len"
json_add_example "9) Extract FTP data transfers" \
    "tshark -r capture.pcap -Y 'ftp-data' -T fields -e frame.number -e data.len"
echo ""

# 10. Complete workflow
info "10) Complete export workflow — capture then extract"
echo "    sudo tshark -i en0 -f 'port 80' -w traffic.pcap -c 500 && tshark -r traffic.pcap --export-objects http,extracted/"
json_add_example "10) Complete export workflow — capture then extract" \
    "sudo tshark -i en0 -f 'port 80' -w traffic.pcap -c 500 && tshark -r traffic.pcap --export-objects http,extracted/"
echo ""

json_finalize

# Interactive demo (skip if non-interactive)
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    [[ ! -t 0 ]] && exit 0
    if [[ -n "$FILE" && -f "$FILE" ]]; then
        read -rp "Run HTTP transfer statistics on ${FILE}? [y/N] " answer
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            info "Running: tshark -r ${FILE} -q -z http,tree"
            echo ""
            tshark -r "$FILE" -q -z http,tree
        fi
    else
        echo ""
        info "To extract files, provide a .pcap file as argument:"
        echo "   $(basename "$0") /path/to/capture.pcap"
        echo ""
        info "To create a capture file first:"
        echo "   sudo tshark -i en0 -f 'port 80' -w traffic.pcap -c 500"
    fi
fi
