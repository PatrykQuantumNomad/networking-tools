#!/usr/bin/env bash
# test-arg-parsing.sh -- Verify Phase 14 argument parsing and dual-mode pattern
# Usage: bash tests/test-arg-parsing.sh
#
# Validates all 5 phase success criteria for argument parsing, plus unit tests
# for parse_common_args(). Exits 0 if all pass, 1 if any fail.

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

# Resolve project root from this test file location
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# ============================================================================
# SC1: --help and -h print usage
# ============================================================================
echo "=== SC1: --help and -h print usage ==="

help_output=$(bash "${PROJECT_ROOT}/scripts/nmap/examples.sh" --help 2>&1)
help_exit=$?
if [[ $help_exit -eq 0 ]]; then
    check_pass "--help exits 0"
else
    check_fail "--help exits $help_exit (expected 0)"
fi

if echo "$help_output" | grep -q "Usage:"; then
    check_pass "--help output contains 'Usage:'"
else
    check_fail "--help output does not contain 'Usage:'"
fi

h_output=$(bash "${PROJECT_ROOT}/scripts/nmap/examples.sh" -h 2>&1)
h_exit=$?
if [[ $h_exit -eq 0 ]]; then
    check_pass "-h exits 0"
else
    check_fail "-h exits $h_exit (expected 0)"
fi

if echo "$h_output" | grep -q "Usage:"; then
    check_pass "-h output contains 'Usage:'"
else
    check_fail "-h output does not contain 'Usage:'"
fi
echo ""

# ============================================================================
# SC2: Backward-compatible default mode (show mode)
# ============================================================================
echo "=== SC2: Backward-compatible default mode ==="

show_output=$(bash "${PROJECT_ROOT}/scripts/nmap/examples.sh" scanme.nmap.org 2>/dev/null)
show_exit=$?
if [[ $show_exit -eq 0 ]]; then
    check_pass "show mode exits 0"
else
    check_fail "show mode exits $show_exit (expected 0)"
fi

if echo "$show_output" | grep -q "1) Ping scan"; then
    check_pass "output contains '1) Ping scan' (first example)"
else
    check_fail "output does not contain '1) Ping scan'"
fi

if echo "$show_output" | grep -q "10) Save results"; then
    check_pass "output contains '10) Save results' (last example)"
else
    check_fail "output does not contain '10) Save results'"
fi

if echo "$show_output" | grep -q "nmap -sn scanme.nmap.org"; then
    check_pass "output contains 'nmap -sn scanme.nmap.org' (target expanded)"
else
    check_fail "output does not contain 'nmap -sn scanme.nmap.org'"
fi

if echo "$show_output" | grep -q "nmap -sn 192.168.1.0/24"; then
    check_pass "output contains 'nmap -sn 192.168.1.0/24' (static example 9)"
else
    check_fail "output does not contain 'nmap -sn 192.168.1.0/24'"
fi
echo ""

# ============================================================================
# SC3: -x mode requires interactive confirmation
# ============================================================================
echo "=== SC3: -x mode requires interactive terminal ==="

# Pipe empty input to simulate non-interactive stdin
exec_output=$(echo "" | bash "${PROJECT_ROOT}/scripts/nmap/examples.sh" -x scanme.nmap.org 2>&1)
exec_exit=$?
if [[ $exec_exit -ne 0 ]]; then
    check_pass "-x with piped stdin exits non-zero ($exec_exit)"
else
    check_fail "-x with piped stdin exits 0 (expected non-zero)"
fi

# warn() outputs to stdout (not stderr), so check combined output
if echo "$exec_output" | grep -qi "interactive terminal"; then
    check_pass "-x output contains 'interactive terminal' warning"
else
    check_fail "-x output does not contain 'interactive terminal' warning"
fi
echo ""

# ============================================================================
# SC4: make nmap TARGET=... works
# ============================================================================
echo "=== SC4: make nmap TARGET=... works ==="

if command -v make &>/dev/null; then
    make_output=$(make -C "${PROJECT_ROOT}" nmap TARGET=scanme.nmap.org 2>/dev/null)
    make_exit=$?
    if [[ $make_exit -eq 0 ]]; then
        check_pass "make nmap TARGET=scanme.nmap.org exits 0"
    else
        check_fail "make nmap TARGET=scanme.nmap.org exits $make_exit (expected 0)"
    fi

    if echo "$make_output" | grep -q "1) Ping scan"; then
        check_pass "make output contains '1) Ping scan'"
    else
        check_fail "make output does not contain '1) Ping scan'"
    fi
else
    echo "  SKIP: make not available"
fi
echo ""

# ============================================================================
# SC5: Unknown flags pass through without error
# ============================================================================
echo "=== SC5: Unknown flags pass through ==="

unknown_output=$(bash "${PROJECT_ROOT}/scripts/nmap/examples.sh" --custom-thing scanme.nmap.org 2>/dev/null)
unknown_exit=$?
if [[ $unknown_exit -eq 0 ]]; then
    check_pass "--custom-thing passes through, exits 0"
else
    check_fail "--custom-thing exits $unknown_exit (expected 0)"
fi

if [[ -n "$unknown_output" ]]; then
    check_pass "--custom-thing produces output (not empty)"
else
    check_fail "--custom-thing produces no output"
fi

# Flag ordering: positional arg before flag
order_output=$(bash "${PROJECT_ROOT}/scripts/nmap/examples.sh" scanme.nmap.org --custom-thing 2>/dev/null)
order_exit=$?
if [[ $order_exit -eq 0 ]]; then
    check_pass "positional then --custom-thing exits 0"
else
    check_fail "positional then --custom-thing exits $order_exit (expected 0)"
fi
echo ""

# ============================================================================
# Unit tests: parse_common_args directly
# ============================================================================
echo "=== Unit tests: parse_common_args ==="

# Source common.sh to get parse_common_args and all globals
# Define show_help first (parse_common_args calls it on -h)
show_help() { echo "help"; }
export -f show_help 2>/dev/null || true

# Source common.sh (this will set strict mode, which we then disable)
source "${PROJECT_ROOT}/scripts/common.sh"
set +eEu  # Re-disable strict mode for the test harness

# --- Test: -v sets VERBOSE and LOG_LEVEL ---
VERBOSE=0
LOG_LEVEL="info"
EXECUTE_MODE="show"
REMAINING_ARGS=()
parse_common_args -v scanme.nmap.org
if ((VERBOSE >= 1)); then
    check_pass "parse_common_args -v: VERBOSE >= 1 ($VERBOSE)"
else
    check_fail "parse_common_args -v: VERBOSE=$VERBOSE (expected >= 1)"
fi
if [[ "$LOG_LEVEL" == "debug" ]]; then
    check_pass "parse_common_args -v: LOG_LEVEL=debug"
else
    check_fail "parse_common_args -v: LOG_LEVEL=$LOG_LEVEL (expected debug)"
fi
if [[ "${REMAINING_ARGS[*]}" == "scanme.nmap.org" ]]; then
    check_pass "parse_common_args -v: REMAINING_ARGS=(scanme.nmap.org)"
else
    check_fail "parse_common_args -v: REMAINING_ARGS=(${REMAINING_ARGS[*]}) (expected scanme.nmap.org)"
fi

# --- Test: -q sets LOG_LEVEL to warn ---
VERBOSE=0
LOG_LEVEL="info"
EXECUTE_MODE="show"
REMAINING_ARGS=()
parse_common_args -q scanme.nmap.org
if [[ "$LOG_LEVEL" == "warn" ]]; then
    check_pass "parse_common_args -q: LOG_LEVEL=warn"
else
    check_fail "parse_common_args -q: LOG_LEVEL=$LOG_LEVEL (expected warn)"
fi
if [[ "${REMAINING_ARGS[*]}" == "scanme.nmap.org" ]]; then
    check_pass "parse_common_args -q: REMAINING_ARGS=(scanme.nmap.org)"
else
    check_fail "parse_common_args -q: REMAINING_ARGS=(${REMAINING_ARGS[*]}) (expected scanme.nmap.org)"
fi

# --- Test: -x sets EXECUTE_MODE to execute ---
VERBOSE=0
LOG_LEVEL="info"
EXECUTE_MODE="show"
REMAINING_ARGS=()
parse_common_args -x scanme.nmap.org
if [[ "$EXECUTE_MODE" == "execute" ]]; then
    check_pass "parse_common_args -x: EXECUTE_MODE=execute"
else
    check_fail "parse_common_args -x: EXECUTE_MODE=$EXECUTE_MODE (expected execute)"
fi
if [[ "${REMAINING_ARGS[*]}" == "scanme.nmap.org" ]]; then
    check_pass "parse_common_args -x: REMAINING_ARGS=(scanme.nmap.org)"
else
    check_fail "parse_common_args -x: REMAINING_ARGS=(${REMAINING_ARGS[*]}) (expected scanme.nmap.org)"
fi

# --- Test: unknown flag passes through to REMAINING_ARGS ---
VERBOSE=0
LOG_LEVEL="info"
EXECUTE_MODE="show"
REMAINING_ARGS=()
parse_common_args --custom-flag scanme.nmap.org
if [[ "${REMAINING_ARGS[*]}" == "--custom-flag scanme.nmap.org" ]]; then
    check_pass "parse_common_args --custom-flag: REMAINING_ARGS=(--custom-flag scanme.nmap.org)"
else
    check_fail "parse_common_args --custom-flag: REMAINING_ARGS=(${REMAINING_ARGS[*]}) (expected --custom-flag scanme.nmap.org)"
fi

# --- Test: flag after positional arg (flag ordering) ---
VERBOSE=0
LOG_LEVEL="info"
EXECUTE_MODE="show"
REMAINING_ARGS=()
parse_common_args scanme.nmap.org -x
if [[ "$EXECUTE_MODE" == "execute" ]]; then
    check_pass "parse_common_args (flag after positional): EXECUTE_MODE=execute"
else
    check_fail "parse_common_args (flag after positional): EXECUTE_MODE=$EXECUTE_MODE (expected execute)"
fi
if [[ "${REMAINING_ARGS[*]}" == "scanme.nmap.org" ]]; then
    check_pass "parse_common_args (flag after positional): REMAINING_ARGS=(scanme.nmap.org)"
else
    check_fail "parse_common_args (flag after positional): REMAINING_ARGS=(${REMAINING_ARGS[*]}) (expected scanme.nmap.org)"
fi

# --- Test: -- stops flag parsing ---
VERBOSE=0
LOG_LEVEL="info"
EXECUTE_MODE="show"
REMAINING_ARGS=()
parse_common_args -- -x scanme.nmap.org
if [[ "$EXECUTE_MODE" == "show" ]]; then
    check_pass "parse_common_args --: EXECUTE_MODE=show (unchanged)"
else
    check_fail "parse_common_args --: EXECUTE_MODE=$EXECUTE_MODE (expected show)"
fi
if [[ "${REMAINING_ARGS[*]}" == "-x scanme.nmap.org" ]]; then
    check_pass "parse_common_args --: REMAINING_ARGS=(-x scanme.nmap.org)"
else
    check_fail "parse_common_args --: REMAINING_ARGS=(${REMAINING_ARGS[*]}) (expected -x scanme.nmap.org)"
fi
echo ""

# ============================================================================
# Edge cases: empty args safety
# ============================================================================
echo "=== Edge cases: empty args under set -u ==="

VERBOSE=0
LOG_LEVEL="info"
EXECUTE_MODE="show"
REMAINING_ARGS=()
parse_common_args
if [[ ${#REMAINING_ARGS[@]} -eq 0 ]]; then
    check_pass "parse_common_args (no args): REMAINING_ARGS is empty"
else
    check_fail "parse_common_args (no args): REMAINING_ARGS has ${#REMAINING_ARGS[@]} elements (expected 0)"
fi

# Test that the empty-array expansion pattern works under set -u
set -u
empty_expand_ok=true
(set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}") 2>/dev/null || empty_expand_ok=false
set +u
if [[ "$empty_expand_ok" == "true" ]]; then
    check_pass "empty REMAINING_ARGS expansion succeeds under set -u"
else
    check_fail "empty REMAINING_ARGS expansion fails under set -u"
fi
echo ""

# ============================================================================
# Summary
# ============================================================================
TOTAL=$((PASS_COUNT + FAIL_COUNT))
echo "==============================="
echo "  Results: $PASS_COUNT/$TOTAL passed, $FAIL_COUNT failed"
echo "==============================="

if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi
