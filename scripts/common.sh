#!/usr/bin/env bash
# ============================================================================
# @description  Shared utility entry point sourcing all lib modules in order
# @usage        source "$(dirname "$0")/../common.sh"
# @dependencies lib/strict.sh, lib/colors.sh, lib/logging.sh, lib/validation.sh, lib/cleanup.sh, lib/json.sh, lib/output.sh, lib/args.sh, lib/diagnostic.sh, lib/nc_detect.sh
# ============================================================================

# --- Bash Version Guard ---
# Require Bash 4.0+ (associative arrays, mapfile, etc.)
# Uses only Bash 2.x+ syntax so it prints a clear error on old bash.
if [[ -z "${BASH_VERSINFO:-}" ]] || ((BASH_VERSINFO[0] < 4)); then
    echo "[ERROR] Bash 4.0+ required (found: ${BASH_VERSION:-unknown})" >&2
    echo "[ERROR] macOS ships Bash 3.2 -- install modern bash: brew install bash" >&2
    exit 1
fi

# Source guard — prevent double-sourcing
[[ -n "${_COMMON_LOADED:-}" ]] && return 0
_COMMON_LOADED=1

# Resolve library directory
_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/lib" && pwd)"

# Source modules in dependency order
source "${_LIB_DIR}/strict.sh"
source "${_LIB_DIR}/colors.sh"
source "${_LIB_DIR}/logging.sh"
source "${_LIB_DIR}/validation.sh"
source "${_LIB_DIR}/cleanup.sh"
source "${_LIB_DIR}/json.sh"
source "${_LIB_DIR}/output.sh"
source "${_LIB_DIR}/args.sh"
source "${_LIB_DIR}/diagnostic.sh"
source "${_LIB_DIR}/nc_detect.sh"
