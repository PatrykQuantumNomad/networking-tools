#!/usr/bin/env bash
# tests/test_helper/common-setup.bash — Shared BATS test helper
# Loaded by every .bats file via: load 'test_helper/common-setup'

# Resolve PROJECT_ROOT reliably regardless of test file depth
PROJECT_ROOT="$(git rev-parse --show-toplevel)"
export PROJECT_ROOT

_common_setup() {
    # Load assertion libraries
    # Dual-path: BATS_LIB_PATH (CI via bats-action) or submodules (local)
    if [[ -n "${BATS_LIB_PATH:-}" ]]; then
        bats_load_library bats-support
        bats_load_library bats-assert
        bats_load_library bats-file
    else
        load "${PROJECT_ROOT}/tests/test_helper/bats-support/load"
        load "${PROJECT_ROOT}/tests/test_helper/bats-assert/load"
        load "${PROJECT_ROOT}/tests/test_helper/bats-file/load"
    fi

    # Disable colors for predictable assertion matching
    export NO_COLOR=1
}
