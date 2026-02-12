#!/usr/bin/env bash
# ============================================================================
# @description  Diagnostic report functions for Pattern B scripts
# @usage        Sourced via common.sh (not invoked directly)
# @dependencies colors.sh, logging.sh
# ============================================================================

# Source guard — prevent double-sourcing
[[ -n "${_DIAGNOSTIC_LOADED:-}" ]] && return 0
_DIAGNOSTIC_LOADED=1

# --- Diagnostic Report Functions ---
# Used by Pattern B (diagnostic scripts), not Pattern A (educational examples)

report_pass()    { echo -e "${GREEN}[PASS]${NC} $*"; }
report_fail()    { echo -e "${RED}[FAIL]${NC} $*"; }
report_warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
report_skip()    { echo -e "${CYAN}[SKIP]${NC} $*"; }

report_section() { echo -e "\n${CYAN}=== $* ===${NC}\n"; }

# Portable timeout wrapper (macOS lacks GNU timeout)
_run_with_timeout() {
    local seconds="$1"
    shift
    if command -v timeout &>/dev/null; then
        timeout "$seconds" "$@"
    else
        # POSIX fallback: run in background, kill after timeout
        "$@" &
        local pid=$!
        ( sleep "$seconds" && kill "$pid" 2>/dev/null ) &
        local watchdog=$!
        wait "$pid" 2>/dev/null
        local exit_code=$?
        kill "$watchdog" 2>/dev/null
        wait "$watchdog" 2>/dev/null
        return $exit_code
    fi
}

# Execute a command with timeout and report pass/fail
# Usage: run_check "Description of check" command arg1 arg2
run_check() {
    local description="$1"
    shift
    local output
    if output=$(_run_with_timeout 10 "$@" 2>&1); then
        report_pass "$description"
        echo "$output" | sed 's/^/   /'
    else
        local exit_code=$?
        if [[ $exit_code -eq 124 ]]; then
            report_warn "$description (timed out)"
        else
            report_fail "$description"
        fi
        [[ -n "$output" ]] && echo "$output" | sed 's/^/   /' || true
    fi
}
