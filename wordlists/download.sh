#!/usr/bin/env bash
# wordlists/download.sh — Download wordlists for password cracking and web enumeration
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

echo ""
info "--- Web Enumeration Wordlists (SecLists) ---"
echo ""

# common.txt — General-purpose directory/file wordlist (~4,700 entries)
COMMON_URL="https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/common.txt"
COMMON="${WORDLIST_DIR}/common.txt"

if [[ -f "$COMMON" ]]; then
    info "common.txt already exists ($(wc -l < "$COMMON" | tr -d ' ') entries)"
else
    info "Downloading SecLists common.txt (~40KB)..."
    curl -L -o "$COMMON" "$COMMON_URL"
    if [[ -f "$COMMON" ]]; then
        success "Downloaded common.txt ($(wc -l < "$COMMON" | tr -d ' ') entries)"
    else
        error "Download failed — check your internet connection"
    fi
fi

# directory-list-2.3-small.txt — DirBuster-derived directory wordlist (~87,000 entries)
DIRLIST_URL="https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/directory-list-2.3-small.txt"
DIRLIST="${WORDLIST_DIR}/directory-list-2.3-small.txt"

if [[ -f "$DIRLIST" ]]; then
    info "directory-list-2.3-small.txt already exists ($(wc -l < "$DIRLIST" | tr -d ' ') entries)"
else
    info "Downloading SecLists directory-list-2.3-small.txt (~1MB)..."
    curl -L -o "$DIRLIST" "$DIRLIST_URL"
    if [[ -f "$DIRLIST" ]]; then
        success "Downloaded directory-list-2.3-small.txt ($(wc -l < "$DIRLIST" | tr -d ' ') entries)"
    else
        error "Download failed — check your internet connection"
    fi
fi

# subdomains-top1million-5000.txt — Top 5,000 most common subdomains
SUBDOMAINS_URL="https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/DNS/subdomains-top1million-5000.txt"
SUBDOMAINS="${WORDLIST_DIR}/subdomains-top1million-5000.txt"

if [[ -f "$SUBDOMAINS" ]]; then
    info "subdomains-top1million-5000.txt already exists ($(wc -l < "$SUBDOMAINS" | tr -d ' ') entries)"
else
    info "Downloading SecLists subdomains-top1million-5000.txt (~35KB)..."
    curl -L -o "$SUBDOMAINS" "$SUBDOMAINS_URL"
    if [[ -f "$SUBDOMAINS" ]]; then
        success "Downloaded subdomains-top1million-5000.txt ($(wc -l < "$SUBDOMAINS" | tr -d ' ') entries)"
    else
        error "Download failed — check your internet connection"
    fi
fi

echo ""
info "Wordlist directory: ${WORDLIST_DIR}"
info "Use with: gobuster dir -w wordlists/common.txt -u <target>"
info "     or:  ffuf -w wordlists/common.txt -u <target>/FUZZ"
