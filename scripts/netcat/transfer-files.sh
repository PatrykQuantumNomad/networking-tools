#!/usr/bin/env bash
# netcat/transfer-files.sh — File transfer with netcat
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [target] [-h|--help]"
    echo ""
    echo "Description:"
    echo "  Demonstrates file transfer techniques using netcat. Shows how to"
    echo "  send and receive files, directories, and compressed data over TCP."
    echo "  Detects the installed nc variant and labels variant-specific flags."
    echo "  Default target is 127.0.0.1 if none is provided."
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")                 # Show transfer examples (localhost)"
    echo "  $(basename "$0") 192.168.1.10    # Show transfer examples (specific host)"
    echo "  $(basename "$0") --help          # Show this help message"
}

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

require_cmd nc "apt install netcat-openbsd (Debian/Ubuntu) | brew install netcat (macOS)"

TARGET="${1:-127.0.0.1}"
NC_VARIANT=$(detect_nc_variant)

safety_banner

info "=== File Transfer with Netcat ==="
info "Target: ${TARGET}"
info "Detected variant: ${NC_VARIANT}"
echo ""

info "Why use netcat for file transfer?"
echo "   Netcat is the simplest way to transfer files between two machines when"
echo "   SSH/SCP is not available. It requires no authentication, no daemon, and"
echo "   no configuration -- just a listener on one side and a connection on the"
echo "   other. Ideal for quick ad-hoc transfers during pentests, CTFs, or when"
echo "   working with minimal environments that lack scp/rsync."
echo ""

# Helper for listener command based on variant
_listener_cmd() {
    if [[ "$NC_VARIANT" == "openbsd" ]]; then
        echo "nc -l $1"
    else
        echo "nc -l -p $1"
    fi
}

# 1. Send a file (receiver listens, sender connects)
info "1) Send a file -- receiver listens, sender connects"
echo "   # Receiver (listener):"
echo "   $(_listener_cmd 4444) > received_file.txt"
echo "   # Sender (connector):"
echo "   nc ${TARGET} 4444 < file_to_send.txt"
echo ""

# 2. Receive a file (reverse direction)
info "2) Receive a file -- listener sends, connector saves"
echo "   # Sender (listener):"
echo "   $(_listener_cmd 4444) < file_to_send.txt"
echo "   # Receiver (connector):"
echo "   nc ${TARGET} 4444 > received_file.txt"
echo ""

# 3. Transfer with progress (pipe through pv)
info "3) Transfer with progress bar (requires pv)"
echo "   # Receiver:"
echo "   $(_listener_cmd 4444) > received_file.bin"
echo "   # Sender (with progress):"
echo "   pv file_to_send.bin | nc ${TARGET} 4444"
echo ""

# 4. Send a directory via tar pipe
info "4) Send an entire directory via tar pipe"
echo "   # Receiver:"
echo "   $(_listener_cmd 4444) | tar xvf -"
echo "   # Sender:"
echo "   tar cvf - /path/to/directory | nc ${TARGET} 4444"
echo ""

# 5. [VARIANT] Use -N to close after EOF (OpenBSD)
info "5) Close connection after file transfer completes [variant: ${NC_VARIANT}]"
case "$NC_VARIANT" in
    openbsd)
        echo "   # OpenBSD nc supports -N to shutdown after EOF on stdin:"
        echo "   nc -N ${TARGET} 4444 < file_to_send.txt"
        ;;
    ncat)
        echo "   # ncat closes after EOF by default with --send-only:"
        echo "   ncat --send-only ${TARGET} 4444 < file_to_send.txt"
        ;;
    gnu|traditional)
        echo "   # ${NC_VARIANT} nc: use -q 0 to close after EOF:"
        echo "   nc -q 0 ${TARGET} 4444 < file_to_send.txt"
        ;;
esac
echo ""

# 6. Transfer with compression (gzip pipe)
info "6) Transfer with gzip compression (saves bandwidth)"
echo "   # Receiver:"
echo "   $(_listener_cmd 4444) | gunzip > received_file.txt"
echo "   # Sender:"
echo "   gzip -c file_to_send.txt | nc ${TARGET} 4444"
echo ""

# 7. Verify transfer with checksum
info "7) Verify transfer integrity with checksums"
echo "   # On sender machine:"
echo "   sha256sum file_to_send.txt"
echo "   # On receiver machine (after transfer):"
echo "   sha256sum received_file.txt"
echo "   # Compare the hashes -- they should match"
echo ""

# 8. Transfer multiple files via tar
info "8) Transfer multiple specific files via tar"
echo "   # Receiver:"
echo "   $(_listener_cmd 4444) | tar xvf -"
echo "   # Sender:"
echo "   tar cvf - file1.txt file2.txt file3.conf | nc ${TARGET} 4444"
echo ""

# 9. Set timeout for stale transfers
info "9) Set timeout for stale transfers (-w seconds)"
echo "   # Receiver with 30-second idle timeout:"
echo "   $(_listener_cmd 4444) -w 30 > received_file.txt"
echo "   # Sender:"
echo "   nc -w 30 ${TARGET} 4444 < file_to_send.txt"
echo ""

# 10. Encrypted transfer via openssl pipe
info "10) Encrypted transfer via openssl pipe"
echo "    # Receiver (decrypt):"
echo "    $(_listener_cmd 4444) | openssl enc -d -aes-256-cbc -pbkdf2 -pass pass:SECRET > received_file.txt"
echo "    # Sender (encrypt):"
echo "    openssl enc -aes-256-cbc -pbkdf2 -pass pass:SECRET < file_to_send.txt | nc ${TARGET} 4444"
echo ""

# Interactive demo -- file transfer needs two terminals, offer port scan instead
[[ ! -t 0 ]] && exit 0

echo ""
info "Note: File transfer requires two terminals (listener + sender)."
info "Instead, here is a quick connectivity demo."
echo ""
read -rp "Check if port 80 is open on ${TARGET}? [y/N] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    info "Running: nc -zv ${TARGET} 80 -w 3"
    nc -zv "$TARGET" 80 -w 3 2>&1 || true
fi
