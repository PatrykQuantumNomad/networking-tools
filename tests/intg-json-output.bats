#!/usr/bin/env bats
# tests/intg-json-output.bats -- Integration tests for JSON output
# JSON-01: Every use-case script produces valid JSON with -j flag
# JSON-02: JSON envelope has correct structure (meta, results, summary)
# JSON-META: Test infrastructure verification (discovery count, jq availability)

# --- File-Level Setup (runs at parse time, before setup/setup_file) ---
PROJECT_ROOT="$(git rev-parse --show-toplevel)"

# Discover use-case scripts (exclude lib/, diagnostics/, examples, common, check-*)
# Excludes diagnose-latency.sh on macOS non-root (requires sudo before JSON output)
_discover_json_scripts() {
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
        -not -name 'examples.sh' \
        ${exclude_latency} \
        | sort
}

# --- Test Functions ---

# Combined JSON-01 + JSON-02: Valid JSON with correct envelope structure
_test_json_output() {
    local script="$1"
    # Capture JSON output (stdout only); stderr discarded inside bash -c wrapper.
    # The -j flag causes exec 3>&1 + exec 1>&2 inside the script, so human-readable
    # output goes to stderr while JSON goes to fd3 (original stdout). The bash -c
    # wrapper with 2>/dev/null ensures BATS $output receives only the JSON.
    run bash -c "bash '$script' -j dummy_target 2>/dev/null"
    assert_success

    # JSON-01: Valid JSON (passes jq .)
    echo "$output" | jq -e '.' > /dev/null

    # JSON-02: Envelope has required top-level keys
    echo "$output" | jq -e 'has("meta") and has("results") and has("summary")' > /dev/null

    # JSON-02: meta has required fields
    echo "$output" | jq -e '.meta | has("tool") and has("script") and has("started")' > /dev/null
    echo "$output" | jq -e '.meta.tool | type == "string" and length > 0' > /dev/null
    echo "$output" | jq -e '.meta.script | type == "string" and length > 0' > /dev/null

    # JSON-02: results is an array
    echo "$output" | jq -e '.results | type == "array"' > /dev/null

    # JSON-02: summary has required fields
    echo "$output" | jq -e '.summary | has("total") and has("succeeded") and has("failed")' > /dev/null
    echo "$output" | jq -e '.summary.total | type == "number"' > /dev/null
}

# --- Dynamic Test Registration ---
while IFS= read -r script; do
    local_path="${script#"${PROJECT_ROOT}"/}"
    bats_test_function \
        --description "JSON-01 ${local_path}: -j produces valid JSON with correct envelope" \
        -- _test_json_output "$script"
done < <(_discover_json_scripts)

# --- Static Meta-Tests ---

@test "JSON-META: discovery finds at least 45 use-case scripts" {
    local count
    count=$(_discover_json_scripts | wc -l | tr -d ' ')
    # 46 on Linux/root, 45 on macOS non-root (diagnose-latency.sh requires sudo on macOS)
    assert [ "$count" -ge 45 ]
}

@test "JSON-META: jq is available for JSON validation" {
    run command -v jq
    assert_success
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
