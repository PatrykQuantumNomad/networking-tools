#!/usr/bin/env bash
# nc_detect.sh — Netcat variant detection
# Identifies which netcat implementation is installed (ncat, gnu, traditional, openbsd).

# Source guard — prevent double-sourcing
[[ -n "${_NC_DETECT_LOADED:-}" ]] && return 0
_NC_DETECT_LOADED=1

# --- Netcat Variant Detection ---
# Identifies which netcat implementation is installed (ncat, gnu, traditional, openbsd)
# Used by scripts/netcat/ scripts to label variant-specific flags

detect_nc_variant() {
    local help_text
    help_text=$(nc -h 2>&1 || true)
    if echo "$help_text" | grep -qi 'ncat'; then
        echo "ncat"
    elif echo "$help_text" | grep -qi 'gnu'; then
        echo "gnu"
    elif echo "$help_text" | grep -qi 'connect to somewhere'; then
        echo "traditional"
    else
        # OpenBSD nc (including macOS Apple fork) -- detected by exclusion
        echo "openbsd"
    fi
}
