#!/usr/bin/env bats
# tests/intg-doc-json-flag.bats -- Verify -j/--json flag is documented
# DOC-01: --help output contains --json flag with description
# DOC-02: @usage metadata header contains [-j|--json]

# --- File-Level Setup (runs at parse time, before setup/setup_file) ---
PROJECT_ROOT="$(git rev-parse --show-toplevel)"

# Discover use-case scripts (exclude lib/, diagnostics/, examples, common, check-*)
_discover_use_case_scripts() {
    find "${PROJECT_ROOT}/scripts" -name '*.sh' \
        -not -path '*/lib/*' \
        -not -name 'common.sh' \
        -not -name 'check-docs-completeness.sh' \
        -not -path '*/diagnostics/*' \
        -not -name 'check-tools.sh' \
        -not -name 'examples.sh' \
        | sort
}

# --- Test Functions ---

# DOC-01: --help output mentions --json flag
_test_help_documents_json() {
    local script="$1"
    run env NO_COLOR=1 bash "$script" --help
    assert_success
    assert_output --partial "--json"
}

# DOC-02: @usage header line contains -j|--json
_test_usage_header_has_json() {
    local script="$1"
    run bash -c "head -10 \"$script\" | grep '# @usage' | grep -c '\\-j|--json'"
    assert_success
    assert [ "$output" -ge 1 ]
}

# --- Dynamic Test Registration (DOC-01) ---
while IFS= read -r script; do
    local_path="${script#"${PROJECT_ROOT}"/}"
    bats_test_function \
        --description "DOC-01 ${local_path}: --help documents --json flag" \
        -- _test_help_documents_json "$script"
done < <(_discover_use_case_scripts)

# --- Dynamic Test Registration (DOC-02) ---
while IFS= read -r script; do
    local_path="${script#"${PROJECT_ROOT}"/}"
    bats_test_function \
        --description "DOC-02 ${local_path}: @usage header includes -j|--json" \
        -- _test_usage_header_has_json "$script"
done < <(_discover_use_case_scripts)

# --- Static Meta-Test ---

@test "DOC-META: discovery finds all 46 use-case scripts" {
    local count
    count=$(_discover_use_case_scripts | wc -l | tr -d ' ')
    assert [ "$count" -ge 46 ]
}

# --- File-Level Lifecycle ---

# Create mock binaries and dummy wordlist files
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
