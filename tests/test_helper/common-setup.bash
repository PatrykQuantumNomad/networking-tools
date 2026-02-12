#!/usr/bin/env bash
# tests/test_helper/common-setup.bash — Shared BATS test helper
# Loaded by every .bats file via: load 'test_helper/common-setup'

# Resolve PROJECT_ROOT reliably regardless of test file depth
PROJECT_ROOT="$(git rev-parse --show-toplevel)"
export PROJECT_ROOT

_common_setup() {
    # Load assertion libraries
    # Prefer submodules (always available), fall back to bats_load_library for
    # CI environments that install libraries globally (e.g., bats-action).
    # Note: BATS sets BATS_LIB_PATH=/usr/lib/bats by default, so we check
    # for the actual submodule directory instead of relying on that variable.
    if [[ -d "${PROJECT_ROOT}/tests/test_helper/bats-support" ]]; then
        load "${PROJECT_ROOT}/tests/test_helper/bats-support/load"
        load "${PROJECT_ROOT}/tests/test_helper/bats-assert/load"
        load "${PROJECT_ROOT}/tests/test_helper/bats-file/load"
    else
        bats_load_library bats-support
        bats_load_library bats-assert
        bats_load_library bats-file
    fi

    # Disable colors for predictable assertion matching
    export NO_COLOR=1
}
