#!/usr/bin/env bash
# wordlists/download.sh — Download common wordlists for password cracking practice
source "$(dirname "$0")/../scripts/common.sh"

WORDLIST_DIR="$(cd "$(dirname "$0")" && pwd)"

info "=== Wordlist Downloader ==="
echo ""

# rockyou.txt — ~14 million real-world passwords leaked from RockYou (2009)
ROCKYOU="${WORDLIST_DIR}/rockyou.txt"
ROCKYOU_URL="https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt"

if [[ -f "$ROCKYOU" ]]; then
    info "rockyou.txt already exists ($(wc -l < "$ROCKYOU" | tr -d ' ') lines)"
else
    info "Downloading rockyou.txt (~140MB)..."
    curl -L -o "$ROCKYOU" "$ROCKYOU_URL"
    if [[ -f "$ROCKYOU" ]]; then
        success "Downloaded rockyou.txt ($(wc -l < "$ROCKYOU" | tr -d ' ') lines)"
    else
        error "Download failed — check your internet connection"
        exit 1
    fi
fi
