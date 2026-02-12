#!/usr/bin/env bats
# tests/lib-cleanup.bats — Unit tests for make_temp and EXIT trap cleanup (UNIT-04)
# Covers make_temp file/dir creation, custom prefix, default type,
# and EXIT trap cleanup for both files and directories.

setup() {
    load 'test_helper/common-setup'
    _common_setup

    # Required by parse_common_args (sourced via common.sh)
    show_help() { echo "test help"; }

    source "${PROJECT_ROOT}/scripts/common.sh"

    # Disable strict mode and clear traps for BATS compatibility
    set +eEuo pipefail
    trap - ERR
}

@test "make_temp creates a regular file" {
    local tmpfile
    tmpfile=$(make_temp file)
    assert_file_exists "$tmpfile"
    [[ -f "$tmpfile" ]]
}

@test "make_temp creates a directory when type is dir" {
    local tmpdir
    tmpdir=$(make_temp dir)
    assert_dir_exists "$tmpdir"
}

@test "make_temp with custom prefix uses prefix in filename" {
    local tmpfile
    tmpfile=$(make_temp file "myprefix")
    [[ "$(basename "$tmpfile")" == myprefix.* ]]
}

@test "make_temp default type is file" {
    local tmpfile
    tmpfile=$(make_temp)
    assert_file_exists "$tmpfile"
    [[ -f "$tmpfile" ]]
}

@test "EXIT trap cleans up temp files when process exits" {
    local tmpfile
    tmpfile=$(bash -c "
        show_help() { echo 'test help'; }
        source '${PROJECT_ROOT}/scripts/common.sh'
        set +eEuo pipefail
        trap - ERR
        make_temp file
    ")
    # After the subprocess exits, its EXIT trap should have cleaned up
    assert_file_not_exists "$tmpfile"
}

@test "EXIT trap cleans up temp directories when process exits" {
    local tmpdir
    tmpdir=$(bash -c "
        show_help() { echo 'test help'; }
        source '${PROJECT_ROOT}/scripts/common.sh'
        set +eEuo pipefail
        trap - ERR
        make_temp dir
    ")
    # After the subprocess exits, its EXIT trap should have cleaned up
    assert_dir_not_exists "$tmpdir"
}
