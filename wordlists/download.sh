#!/usr/bin/env bash
# wordlists/download.sh — Download wordlists for password cracking and web enumeration
source "$(dirname "$0")/../scripts/common.sh"

WORDLIST_DIR="$(cd "$(dirname "$0")" && pwd)"
MIN_BYTES=100  # Anything smaller is a failed download (404 page, empty, etc.)

# download_wordlist <local_name> <url> <description> <expected_size>
# Downloads a file if missing or corrupt; validates the result.
download_wordlist() {
    local name="$1" url="$2" desc="$3" size_hint="$4"
    local dest="${WORDLIST_DIR}/${name}"

    if [[ -f "$dest" ]] && [[ "$(wc -c < "$dest" | tr -d ' ')" -gt "$MIN_BYTES" ]]; then
        info "${name} already exists ($(wc -l < "$dest" | tr -d ' ') entries)"
        return 0
    fi

    # Remove broken/empty file from a previous failed download
    [[ -f "$dest" ]] && rm -f "$dest"

    info "Downloading ${desc} (~${size_hint})..."
    if ! curl -fSL --retry 2 --retry-delay 3 -o "$dest" "$url"; then
        rm -f "$dest"
        error "Download failed for ${name} — check your internet connection"
        return 1
    fi

    # Validate we got a real file, not a redirect page or error
    if [[ ! -f "$dest" ]] || [[ "$(wc -c < "$dest" | tr -d ' ')" -le "$MIN_BYTES" ]]; then
        rm -f "$dest"
        error "Downloaded file for ${name} appears invalid (too small) — URL may be broken"
        return 1
    fi

    success "Downloaded ${name} ($(wc -l < "$dest" | tr -d ' ') entries)"
}

info "=== Wordlist Downloader ==="
echo ""

# ── Password Lists ──────────────────────────────────────────────

# rockyou.txt — ~14 million real-world passwords leaked from RockYou (2009)
ROCKYOU_URL="https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt"
download_wordlist "rockyou.txt" "$ROCKYOU_URL" "rockyou.txt" "140MB"

echo ""
info "--- Web Enumeration Wordlists (SecLists) ---"
echo ""

# ── Web Content Discovery ───────────────────────────────────────

# common.txt — General-purpose directory/file wordlist (~4,700 entries)
COMMON_URL="https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/common.txt"
download_wordlist "common.txt" "$COMMON_URL" "SecLists common.txt" "40KB"

# directory-list-2.3-small.txt — DirBuster-derived directory wordlist (~87,000 entries)
# Renamed upstream to DirBuster-2007_directory-list-2.3-small.txt (2025)
DIRLIST_URL="https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/DirBuster-2007_directory-list-2.3-small.txt"
download_wordlist "directory-list-2.3-small.txt" "$DIRLIST_URL" "SecLists directory-list-2.3-small.txt" "1MB"

# ── DNS Subdomain Discovery ─────────────────────────────────────

# subdomains-top1million-5000.txt — Top 5,000 most common subdomains
SUBDOMAINS_URL="https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/DNS/subdomains-top1million-5000.txt"
download_wordlist "subdomains-top1million-5000.txt" "$SUBDOMAINS_URL" "SecLists subdomains-top1million-5000.txt" "35KB"

echo ""
info "Wordlist directory: ${WORDLIST_DIR}"
info "Use with: gobuster dir -w wordlists/common.txt -u <target>"
info "     or:  ffuf -w wordlists/common.txt -u <target>/FUZZ"
