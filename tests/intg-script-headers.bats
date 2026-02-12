#!/usr/bin/env bats
# tests/intg-script-headers.bats -- Metadata header validation for all scripts
# HDR-06: Every .sh file in scripts/ must have @description, @usage, and
#         @dependencies in the first 10 lines of the file.
# Tests are registered dynamically -- adding a new .sh file automatically
# includes it in the validation suite.

# --- File-Level Setup (runs at parse time, before setup/setup_file) ---
PROJECT_ROOT="$(git rev-parse --show-toplevel)"

# Required metadata fields (must appear as comments in lines 1-10)
REQUIRED_FIELDS=('# @description' '# @usage' '# @dependencies')

# Discover every .sh file under scripts/ (no exclusions -- headers are universal)
_discover_all_sh_files() {
    find "${PROJECT_ROOT}/scripts" -name '*.sh' | sort
}

# --- Test Function ---

# Validate that a single script contains all required header fields in lines 1-10
_test_header_fields() {
    local script="$1"
    local field
    for field in "${REQUIRED_FIELDS[@]}"; do
        run bash -c "head -10 \"$script\" | grep -c \"$field\""
        assert_success
        assert [ "$output" -ge 1 ]
    done
}

# --- Dynamic Test Registration (HDR-06 per-file) ---
while IFS= read -r script; do
    local_path="${script#"${PROJECT_ROOT}"/}"
    bats_test_function \
        --description "HDR-06 ${local_path}: has required header fields" \
        -- _test_header_fields "$script"
done < <(_discover_all_sh_files)

# --- Static Meta-Test ---

@test "HDR-06: discovery finds all script files" {
    local count
    count=$(_discover_all_sh_files | wc -l | tr -d ' ')
    assert [ "$count" -ge 78 ]
}

# --- Per-Test Setup ---
setup() {
    load 'test_helper/common-setup'
    _common_setup
}
