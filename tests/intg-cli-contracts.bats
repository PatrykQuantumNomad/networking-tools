#!/usr/bin/env bats
# tests/intg-cli-contracts.bats -- CLI contract tests for all scripts
# INTG-01: --help exits 0 and output contains "Usage:"
# INTG-02: -x rejects piped (non-interactive) stdin
# INTG-03: Scripts discovered dynamically (no hardcoded lists)
# INTG-04: Tests pass on CI without pentesting tools (via mock commands)

# --- File-Level Setup (runs at parse time, before setup/setup_file) ---
PROJECT_ROOT="$(git rev-parse --show-toplevel)"

# Discover all testable scripts (excludes lib/, common.sh, check-docs-completeness.sh)
_discover_all_scripts() {
    find "${PROJECT_ROOT}/scripts" -name '*.sh' \
        -not -path '*/lib/*' \
        -not -name 'common.sh' \
        -not -name 'check-docs-completeness.sh' \
        | sort
}

# Discover scripts that support -x execute mode
# Excludes diagnostics/ and check-tools.sh (no parse_common_args / no -x support)
# Excludes diagnose-latency.sh on macOS non-root (requires sudo before confirm_execute)
_discover_execute_mode_scripts() {
    local exclude_latency=""
    if [[ "$(uname -s)" == "Darwin" ]] && [[ $EUID -ne 0 ]]; then
        exclude_latency="-not -name diagnose-latency.sh"
    fi
    find "${PROJECT_ROOT}/scripts" -name '*.sh' \
        -not -path '*/lib/*' \
        -not -name 'common.sh' \
        -not -name 'check-docs-completeness.sh' \
        -not -path '*/diagnostics/*' \
        -not -name 'check-tools.sh' \
        ${exclude_latency} \
        | sort
}

# --- Test Functions ---

# INTG-01: Help contract -- every script exits 0 on --help with "Usage:" in output
_test_help_contract() {
    local script="$1"
    run env NO_COLOR=1 bash "$script" --help
    assert_success
    assert_output --partial "Usage:"
}

# INTG-02: Execute mode rejects piped (non-interactive) stdin
_test_execute_mode_rejects_pipe() {
    local script="$1"
    # Pipe stdin to make it non-interactive; pass -x and dummy target
    run bash -c "echo '' | NO_COLOR=1 bash '$script' -x dummy_target 2>&1"
    assert_failure
    assert_output --partial "interactive terminal"
}

# --- Dynamic Test Registration (INTG-01) ---
while IFS= read -r script; do
    local_path="${script#"${PROJECT_ROOT}"/}"
    bats_test_function \
        --description "INTG-01 ${local_path}: --help exits 0 with Usage" \
        -- _test_help_contract "$script"
done < <(_discover_all_scripts)

# --- Dynamic Test Registration (INTG-02) ---
while IFS= read -r script; do
    local_path="${script#"${PROJECT_ROOT}"/}"
    bats_test_function \
        --description "INTG-02 ${local_path}: -x rejects piped stdin" \
        -- _test_execute_mode_rejects_pipe "$script"
done < <(_discover_execute_mode_scripts)

# --- Static Meta-Tests (INTG-03) ---

# @test functions use standard BATS registration -- position doesn't matter
@test "INTG-03: discovery finds all testable scripts" {
    local count
    count=$(_discover_all_scripts | wc -l | tr -d ' ')
    assert [ "$count" -ge 67 ]
}

@test "INTG-03: execute-mode discovery excludes diagnostics and check-tools" {
    local count
    count=$(_discover_execute_mode_scripts | wc -l | tr -d ' ')
    # 63 on Linux, 62 on macOS non-root (diagnose-latency.sh requires sudo on macOS)
    assert [ "$count" -ge 62 ]
}

# --- File-Level Lifecycle ---

# Create mock binaries and dummy wordlist files (INTG-04)
setup_file() {
    MOCK_BIN="${BATS_FILE_TMPDIR}/mock-bin"
    mkdir -p "$MOCK_BIN"
    export MOCK_BIN

    # Mock binaries for tools not installed on this system
    local tools=(
        nmap tshark msfconsole msfvenom aircrack-ng hashcat skipfish
        sqlmap hping3 john nikto foremost dig curl nc traceroute mtr
        gobuster ffuf
    )
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            printf '#!/bin/sh\nexit 0\n' > "${MOCK_BIN}/${tool}"
            chmod +x "${MOCK_BIN}/${tool}"
        fi
    done

    # Create dummy wordlist files if missing (some scripts check before confirm_execute)
    local wordlist_dir="${PROJECT_ROOT}/wordlists"
    mkdir -p "$wordlist_dir"
    local wordlists=(common.txt subdomains-top1million-5000.txt rockyou.txt)
    for wl in "${wordlists[@]}"; do
        if [[ ! -f "${wordlist_dir}/${wl}" ]]; then
            echo "dummy" > "${wordlist_dir}/${wl}"
            # Track for cleanup in teardown_file
            echo "${wordlist_dir}/${wl}" >> "${BATS_FILE_TMPDIR}/created-wordlists"
        fi
    done
}

# Clean up dummy wordlist files created during setup_file
teardown_file() {
    if [[ -f "${BATS_FILE_TMPDIR}/created-wordlists" ]]; then
        while IFS= read -r wl; do
            rm -f "$wl"
        done < "${BATS_FILE_TMPDIR}/created-wordlists"
    fi
}

# Per-test setup: load assertions and prepend mock bin to PATH
setup() {
    load 'test_helper/common-setup'
    _common_setup
    export PATH="${MOCK_BIN}:${PATH}"
}
