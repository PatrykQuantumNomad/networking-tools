#!/usr/bin/env bash
# colors.sh — Color variable definitions with NO_COLOR and terminal detection
# Respects NO_COLOR environment variable and disables colors when not a terminal.

# Source guard — prevent double-sourcing
[[ -n "${_COLORS_LOADED:-}" ]] && return 0
_COLORS_LOADED=1

# Define color escape sequences
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Disable colors when NO_COLOR is set (https://no-color.org/) or stdout is not a terminal
# Color variables used by sourcing scripts via common.sh
if [[ -n "${NO_COLOR:-}" ]] || [[ ! -t 1 ]]; then
    # shellcheck disable=SC2034
    RED=''
    # shellcheck disable=SC2034
    GREEN=''
    # shellcheck disable=SC2034
    YELLOW=''
    # shellcheck disable=SC2034
    BLUE=''
    # shellcheck disable=SC2034
    CYAN=''
    # shellcheck disable=SC2034
    NC=''
fi
