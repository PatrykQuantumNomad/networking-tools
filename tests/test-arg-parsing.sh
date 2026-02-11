#!/usr/bin/env bash
# test-arg-parsing.sh -- Verify argument parsing and dual-mode pattern across all scripts
# Usage: bash tests/test-arg-parsing.sh
#
# Validates Phase 14 success criteria (nmap pilot), Phase 15 success criteria
# (all 17 examples.sh scripts), and Phase 16 success criteria (all 46 use-case
# scripts). Exits 0 if all pass, 1 if any fail.

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
_order_output=$(bash "${PROJECT_ROOT}/scripts/nmap/examples.sh" scanme.nmap.org --custom-thing 2>/dev/null)
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
set +eEuo pipefail  # Re-disable strict mode for the test harness
trap - ERR          # Clear ERR trap so subshells don't print stack traces

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
# All 17 scripts: --help exits 0
# ============================================================================
echo "=== All scripts: --help exits 0 ==="

for tool_dir in "${PROJECT_ROOT}/scripts"/*/; do
    script="${tool_dir}examples.sh"
    [[ -f "$script" ]] || continue
    tool=$(basename "$tool_dir")

    if bash "$script" --help &>/dev/null; then
        check_pass "${tool}: --help exits 0"
    else
        check_fail "${tool}: --help exits non-zero"
    fi
done
echo ""

# ============================================================================
# All 17 scripts: -x rejects non-interactive stdin
# ============================================================================
echo "=== All scripts: -x rejects non-interactive stdin ==="

declare -A TOOL_TARGETS=(
    [nmap]="scanme.nmap.org"
    [dig]="example.com"
    [curl]="example.com"
    [hping3]="example.com"
    [gobuster]="http://example.com"
    [ffuf]="http://example.com"
    [nikto]="http://example.com"
    [sqlmap]="http://example.com"
    [skipfish]="http://example.com"
    [traceroute]="example.com"
    [netcat]="127.0.0.1"
    [foremost]=""
    [tshark]=""
    [metasploit]=""
    [hashcat]=""
    [john]=""
    [aircrack-ng]=""
)

for tool_dir in "${PROJECT_ROOT}/scripts"/*/; do
    script="${tool_dir}examples.sh"
    [[ -f "$script" ]] || continue
    tool=$(basename "$tool_dir")
    target="${TOOL_TARGETS[$tool]:-}"

    exec_output=$(echo "" | bash "$script" -x $target 2>&1)
    exec_exit=$?
    if [[ $exec_exit -ne 0 ]]; then
        check_pass "${tool}: -x rejects non-interactive ($exec_exit)"
    else
        check_fail "${tool}: -x does not reject non-interactive"
    fi
done
echo ""

# ============================================================================
# Makefile backward compatibility: 12 targets with examples.sh
# ============================================================================
echo "=== Makefile backward compatibility: 12 targets ==="

if command -v make &>/dev/null; then
    declare -A MAKE_TARGETS=(
        [nmap]="scanme.nmap.org"
        [tshark]=""
        [sqlmap]="http://example.com"
        [nikto]="http://example.com"
        [hping3]="example.com"
        [foremost]=""
        [dig]="example.com"
        [curl]="example.com"
        [netcat]="127.0.0.1"
        [traceroute]="example.com"
        [gobuster]="http://example.com"
        [ffuf]="http://example.com"
    )

    # Map tool names to their actual command names for availability check
    declare -A TOOL_CMDS=(
        [netcat]="nc"
    )

    for make_tool in "${!MAKE_TARGETS[@]}"; do
        # Check if the tool command is available (skip if not installed)
        cmd="${TOOL_CMDS[$make_tool]:-$make_tool}"
        if ! command -v "$cmd" &>/dev/null; then
            echo "  SKIP: make ${make_tool} (${cmd} not installed)"
            continue
        fi

        target="${MAKE_TARGETS[$make_tool]}"
        if [[ -n "$target" ]]; then
            make_output=$(make -C "${PROJECT_ROOT}" "$make_tool" TARGET="$target" 2>/dev/null)
        else
            make_output=$(make -C "${PROJECT_ROOT}" "$make_tool" 2>/dev/null)
        fi
        make_exit=$?

        if [[ $make_exit -eq 0 ]]; then
            check_pass "make ${make_tool}: exits 0"
        else
            check_fail "make ${make_tool}: exits $make_exit (expected 0)"
        fi

        if echo "$make_output" | grep -q "1)"; then
            check_pass "make ${make_tool}: output contains '1)'"
        else
            check_fail "make ${make_tool}: output does not contain '1)'"
        fi
    done
else
    echo "  SKIP: make not available"
fi
echo ""

# ============================================================================
# Use-case scripts: define all 46 script paths
# ============================================================================

USE_CASE_SCRIPTS=(
    scripts/nmap/discover-live-hosts.sh
    scripts/nmap/scan-web-vulnerabilities.sh
    scripts/nmap/identify-ports.sh
    scripts/hping3/test-firewall-rules.sh
    scripts/hping3/detect-firewall.sh
    scripts/dig/query-dns-records.sh
    scripts/dig/attempt-zone-transfer.sh
    scripts/dig/check-dns-propagation.sh
    scripts/curl/check-ssl-certificate.sh
    scripts/curl/debug-http-response.sh
    scripts/curl/test-http-endpoints.sh
    scripts/nikto/scan-specific-vulnerabilities.sh
    scripts/nikto/scan-multiple-hosts.sh
    scripts/nikto/scan-with-auth.sh
    scripts/skipfish/scan-authenticated-app.sh
    scripts/skipfish/quick-scan-web-app.sh
    scripts/ffuf/fuzz-parameters.sh
    scripts/gobuster/discover-directories.sh
    scripts/gobuster/enumerate-subdomains.sh
    scripts/traceroute/trace-network-path.sh
    scripts/traceroute/diagnose-latency.sh
    scripts/traceroute/compare-routes.sh
    scripts/sqlmap/dump-database.sh
    scripts/sqlmap/test-all-parameters.sh
    scripts/sqlmap/bypass-waf.sh
    scripts/netcat/scan-ports.sh
    scripts/netcat/setup-listener.sh
    scripts/netcat/transfer-files.sh
    scripts/foremost/analyze-forensic-image.sh
    scripts/foremost/carve-specific-filetypes.sh
    scripts/foremost/recover-deleted-files.sh
    scripts/tshark/capture-http-credentials.sh
    scripts/tshark/analyze-dns-queries.sh
    scripts/tshark/extract-files-from-capture.sh
    scripts/metasploit/generate-reverse-shell.sh
    scripts/metasploit/scan-network-services.sh
    scripts/metasploit/setup-listener.sh
    scripts/hashcat/crack-ntlm-hashes.sh
    scripts/hashcat/benchmark-gpu.sh
    scripts/hashcat/crack-web-hashes.sh
    scripts/john/crack-linux-passwords.sh
    scripts/john/crack-archive-passwords.sh
    scripts/john/identify-hash-type.sh
    scripts/aircrack-ng/capture-handshake.sh
    scripts/aircrack-ng/crack-wpa-handshake.sh
    scripts/aircrack-ng/analyze-wireless-networks.sh
)

# ============================================================================
# Use-case scripts: --help exits 0 for all 46
# ============================================================================
echo "=== Use-case scripts: --help exits 0 ==="

for script_rel in "${USE_CASE_SCRIPTS[@]}"; do
    script="${PROJECT_ROOT}/${script_rel}"
    label=$(echo "$script_rel" | sed 's|scripts/||')

    help_output=$(bash "$script" --help 2>&1)
    help_exit=$?
    if [[ $help_exit -eq 0 ]]; then
        check_pass "${label}: --help exits 0"
    else
        check_fail "${label}: --help exits $help_exit (expected 0)"
    fi

    if echo "$help_output" | grep -q "Usage:"; then
        check_pass "${label}: --help contains 'Usage:'"
    else
        check_fail "${label}: --help does not contain 'Usage:'"
    fi
done
echo ""

# ============================================================================
# Use-case scripts: -x rejects non-interactive stdin for all 46
# ============================================================================
echo "=== Use-case scripts: -x rejects non-interactive stdin ==="

for script_rel in "${USE_CASE_SCRIPTS[@]}"; do
    script="${PROJECT_ROOT}/${script_rel}"
    label=$(echo "$script_rel" | sed 's|scripts/||')

    # All use-case scripts have sensible defaults (no require_target), so no
    # extra target arg needed. In -x mode they will hit confirm_execute (rejects
    # non-interactive) or require_cmd (tool not installed) -- both exit non-zero.
    exec_output=$(echo "" | bash "$script" -x 2>&1)
    exec_exit=$?
    if [[ $exec_exit -ne 0 ]]; then
        check_pass "${label}: -x rejects non-interactive ($exec_exit)"
    else
        check_fail "${label}: -x does not reject non-interactive"
    fi
done
echo ""

# ============================================================================
# Use-case scripts: parse_common_args present in all 46
# ============================================================================
echo "=== Use-case scripts: parse_common_args present ==="

for script_rel in "${USE_CASE_SCRIPTS[@]}"; do
    script="${PROJECT_ROOT}/${script_rel}"
    label=$(echo "$script_rel" | sed 's|scripts/||')

    if grep -q 'parse_common_args' "$script"; then
        check_pass "${label}: contains parse_common_args"
    else
        check_fail "${label}: missing parse_common_args"
    fi
done
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
