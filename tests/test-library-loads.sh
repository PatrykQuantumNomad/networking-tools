#!/usr/bin/env bash
# test-library-loads.sh — Smoke test verifying all library functions load correctly
# Usage: bash tests/test-library-loads.sh
#
# Sources common.sh and validates that every expected function, variable,
# and source guard is defined. Exits 0 if all pass, 1 if any fail.

set +eEu  # Disable strict mode for the test harness itself

# Track pass/fail counts
PASS_COUNT=0
FAIL_COUNT=0

check_pass() {
    PASS_COUNT=$((PASS_COUNT + 1))
    echo "  PASS: $1"
}

check_fail() {
    FAIL_COUNT=$((FAIL_COUNT + 1))
    echo "  FAIL: $1"
}

# --- Source common.sh ---
echo "=== Sourcing common.sh ==="
# shellcheck source=../scripts/common.sh
source "$(dirname "$0")/../scripts/common.sh"
echo ""

# --- Check 1: Functions from logging.sh ---
echo "=== Check 1: logging.sh functions ==="
for fn in info success warn error debug; do
    if declare -F "$fn" > /dev/null 2>&1; then
        check_pass "$fn() is defined"
    else
        check_fail "$fn() is NOT defined"
    fi
done
echo ""

# --- Check 2: Functions from validation.sh ---
echo "=== Check 2: validation.sh functions ==="
for fn in require_root check_cmd require_cmd require_target; do
    if declare -F "$fn" > /dev/null 2>&1; then
        check_pass "$fn() is defined"
    else
        check_fail "$fn() is NOT defined"
    fi
done
echo ""

# --- Check 3: Functions from cleanup.sh ---
echo "=== Check 3: cleanup.sh functions ==="
for fn in make_temp register_cleanup retry_with_backoff; do
    if declare -F "$fn" > /dev/null 2>&1; then
        check_pass "$fn() is defined"
    else
        check_fail "$fn() is NOT defined"
    fi
done
echo ""

# --- Check 4: Functions from output.sh ---
echo "=== Check 4: output.sh functions ==="
for fn in safety_banner is_interactive; do
    if declare -F "$fn" > /dev/null 2>&1; then
        check_pass "$fn() is defined"
    else
        check_fail "$fn() is NOT defined"
    fi
done
echo ""

# --- Check 5: Functions from diagnostic.sh ---
echo "=== Check 5: diagnostic.sh functions ==="
for fn in report_pass report_fail report_warn report_skip report_section run_check; do
    if declare -F "$fn" > /dev/null 2>&1; then
        check_pass "$fn() is defined"
    else
        check_fail "$fn() is NOT defined"
    fi
done
echo ""

# --- Check 6: Functions from nc_detect.sh ---
echo "=== Check 6: nc_detect.sh functions ==="
for fn in detect_nc_variant; do
    if declare -F "$fn" > /dev/null 2>&1; then
        check_pass "$fn() is defined"
    else
        check_fail "$fn() is NOT defined"
    fi
done
echo ""

# --- Check 7: Source guards ---
echo "=== Check 7: Source guards ==="
for guard in _STRICT_LOADED _COLORS_LOADED _LOGGING_LOADED _VALIDATION_LOADED _CLEANUP_LOADED _OUTPUT_LOADED _DIAGNOSTIC_LOADED _NC_DETECT_LOADED _COMMON_LOADED; do
    if [[ -n "${!guard:-}" ]]; then
        check_pass "$guard is set (=${!guard})"
    else
        check_fail "$guard is NOT set"
    fi
done
echo ""

# --- Check 8: PROJECT_ROOT ---
echo "=== Check 8: PROJECT_ROOT ==="
if [[ -n "${PROJECT_ROOT:-}" ]]; then
    check_pass "PROJECT_ROOT is set ($PROJECT_ROOT)"
    if [[ -d "$PROJECT_ROOT" ]]; then
        check_pass "PROJECT_ROOT is a directory"
    else
        check_fail "PROJECT_ROOT is not a directory"
    fi
    if [[ -f "$PROJECT_ROOT/Makefile" ]]; then
        check_pass "PROJECT_ROOT contains a Makefile"
    else
        check_fail "PROJECT_ROOT does not contain a Makefile"
    fi
else
    check_fail "PROJECT_ROOT is NOT set"
fi
echo ""

# --- Check 9: Color variables ---
echo "=== Check 9: Color variables ==="
for color in RED GREEN YELLOW BLUE CYAN NC; do
    if declare -p "$color" > /dev/null 2>&1; then
        check_pass "$color is declared"
    else
        check_fail "$color is NOT declared"
    fi
done
echo ""

# --- Summary ---
TOTAL=$((PASS_COUNT + FAIL_COUNT))
echo "==============================="
echo "  Results: $PASS_COUNT/$TOTAL passed, $FAIL_COUNT failed"
echo "==============================="

if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi
