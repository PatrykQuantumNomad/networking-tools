#!/usr/bin/env bash
# output.sh — Safety banner, interactivity check, and project root
# Provides safety_banner(), is_interactive(), PROJECT_ROOT.

# Source guard — prevent double-sourcing
[[ -n "${_OUTPUT_LOADED:-}" ]] && return 0
_OUTPUT_LOADED=1

# Safety banner — displayed before any active scanning
safety_banner() {
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}  AUTHORIZED USE ONLY${NC}"
    echo -e "${RED}  Only scan targets you own or have${NC}"
    echo -e "${RED}  explicit written permission to test.${NC}"
    echo -e "${RED}========================================${NC}"
    echo ""
}

# Check if running in an interactive terminal
is_interactive() {
    [[ -t 0 ]]
}

# Project root directory (lib/ is two levels below project root)
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
