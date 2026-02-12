---
phase: 18-bats-infrastructure
plan: 01
subsystem: testing
tags: [bats, bash-testing, submodules, test-infrastructure]

# Dependency graph
requires:
  - phase: none
    provides: n/a (foundation plan)
provides:
  - BATS v1.13.0 test runner via git submodule
  - bats-support v0.3.0, bats-assert v2.2.0, bats-file v0.4.0 assertion libraries
  - Shared test helper with dual-path library loading
  - make test and make test-verbose Makefile targets
  - Smoke test proving strict mode and trap conflicts are resolved
affects: [19-common-sh-tests, 20-script-tests, 21-ci-integration]

# Tech tracking
tech-stack:
  added: [bats-core v1.13.0, bats-support v0.3.0, bats-assert v2.2.0, bats-file v0.4.0]
  patterns: [git submodules for test dependencies, shared test helper with _common_setup, submodule-first library loading]

key-files:
  created:
    - tests/test_helper/common-setup.bash
    - tests/smoke.bats
    - .gitmodules
  modified:
    - Makefile
    - .github/workflows/shellcheck.yml

key-decisions:
  - "Submodule-first library loading: check for submodule directory instead of BATS_LIB_PATH (bats sets default /usr/lib/bats internally)"
  - "Non-recursive test discovery: avoid --recursive flag to prevent bats submodule test fixtures from being picked up"
  - "Pin exact versions: bats-core v1.13.0, bats-support v0.3.0, bats-assert v2.2.0, bats-file v0.4.0"

patterns-established:
  - "BATS test pattern: setup() calls load + _common_setup, source common.sh with set +eEuo pipefail and trap - ERR after"
  - "Shared helper: load 'test_helper/common-setup' then _common_setup() in every .bats file"

# Metrics
duration: 6min
completed: 2026-02-12
---

# Phase 18 Plan 01: BATS Infrastructure Summary

**BATS v1.13.0 with git submodules, shared test helper with dual-path loading, and 5-assertion smoke test proving strict mode compatibility**

## Performance

- **Duration:** 6 min
- **Started:** 2026-02-12T11:54:02Z
- **Completed:** 2026-02-12T12:00:16Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments
- Installed BATS v1.13.0 and three assertion libraries (bats-support, bats-assert, bats-file) as git submodules pinned to exact versions
- Created shared test helper with dual-path library loading (submodules for local, bats_load_library for CI)
- Added `make test` and `make test-verbose` targets using submodule binary
- 5 smoke tests passing: basic assertions, bats-file assertions, common.sh sourcing with strict mode handled, parse_common_args functionality, run isolation
- Updated ShellCheck exclusions in both Makefile and CI workflow to skip BATS submodule files

## Task Commits

Each task was committed atomically:

1. **Task 1: Install BATS submodules, create shared test helper, add Makefile targets, update ShellCheck exclusions** - `b4ec824` (chore)
2. **Task 2: Create smoke test and verify full infrastructure with make test** - `b132774` (test)

## Files Created/Modified
- `.gitmodules` - BATS submodule declarations (4 entries)
- `tests/bats/` - bats-core v1.13.0 submodule
- `tests/test_helper/bats-support/` - bats-support v0.3.0 submodule
- `tests/test_helper/bats-assert/` - bats-assert v2.2.0 submodule
- `tests/test_helper/bats-file/` - bats-file v0.4.0 submodule
- `tests/test_helper/common-setup.bash` - Shared test helper with _common_setup function
- `tests/smoke.bats` - 5-assertion smoke test proving infrastructure works
- `Makefile` - test/test-verbose targets, ShellCheck exclusions for bats submodules
- `.github/workflows/shellcheck.yml` - ShellCheck exclusions for bats submodules

## Decisions Made
- **Submodule-first library loading:** Changed the dual-path condition from checking `BATS_LIB_PATH` to checking for the submodule directory on disk. BATS v1.13.0 internally sets `BATS_LIB_PATH=/usr/lib/bats` as a default, making the original `-n` check always true even when libraries are not installed there.
- **Non-recursive test discovery:** Removed `--recursive` flag from Makefile test targets. The flag caused BATS to descend into its own submodule test fixtures directory, picking up internal `.bats` files that expect specific environment variables.
- **Pinned versions:** bats-core v1.13.0, bats-support v0.3.0, bats-assert v2.2.0, bats-file v0.4.0 for reproducible test behavior.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed BATS_LIB_PATH dual-path loading condition**
- **Found during:** Task 2 (smoke test creation)
- **Issue:** `BATS_LIB_PATH` is set to `/usr/lib/bats` by default inside bats runtime, making the `[[ -n "${BATS_LIB_PATH:-}" ]]` check always true even when libraries aren't installed at that path
- **Fix:** Changed condition to check for submodule directory existence (`-d "${PROJECT_ROOT}/tests/test_helper/bats-support"`) instead of checking BATS_LIB_PATH
- **Files modified:** tests/test_helper/common-setup.bash
- **Verification:** All 5 tests pass with `make test`
- **Committed in:** b132774 (Task 2 commit)

**2. [Rule 1 - Bug] Removed --recursive flag from test targets**
- **Found during:** Task 2 (smoke test creation)
- **Issue:** `--recursive` caused bats to discover and run `.bats` files inside the bats-core submodule's own test fixtures, which expect internal environment variables like `MARKER_FILE`
- **Fix:** Removed `--recursive` from both `test` and `test-verbose` Makefile targets
- **Files modified:** Makefile
- **Verification:** `make test` runs only project tests, exits 0
- **Committed in:** b132774 (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (2 bugs)
**Impact on plan:** Both fixes necessary for correct test execution. No scope creep.

## Issues Encountered
None beyond the deviations documented above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- BATS infrastructure is fully operational with `make test` and `make test-verbose`
- Shared test helper establishes the pattern for all future test files
- Smoke test proves strict mode (`set -eEuo pipefail`) and ERR trap conflicts from common.sh are resolved with `set +eEuo pipefail` and `trap - ERR`
- Ready for Phase 19 (common.sh tests) and beyond

## Self-Check: PASSED

---
*Phase: 18-bats-infrastructure*
*Completed: 2026-02-12*
