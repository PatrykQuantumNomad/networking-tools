---
phase: 20-script-integration-tests
plan: 01
subsystem: testing
tags: [bats, integration-tests, cli-contracts, dynamic-test-registration, mock-commands]

# Dependency graph
requires:
  - phase: 18-bats-infrastructure
    provides: BATS framework, shared test helper, Makefile targets
  - phase: 19-library-unit-tests
    provides: Proven library behavior (parse_common_args, confirm_execute, require_cmd)
provides:
  - CLI contract integration tests for all 67 scripts (help output)
  - Execute-mode rejection tests for 62-63 scripts (platform-dependent)
  - Mock command infrastructure for 19 pentesting tools
  - Dynamic script discovery via find (auto-grows with new scripts)
affects: [21-ci-integration, 22-script-metadata-headers]

# Tech tracking
tech-stack:
  added: []
  patterns: [bats_test_function dynamic registration, PATH-prepend mock commands, find-based test discovery]

key-files:
  created:
    - tests/intg-cli-contracts.bats
  modified: []

key-decisions:
  - "bats_test_function for per-script dynamic test registration (individual TAP lines per script)"
  - "Platform-conditional exclusion for diagnose-latency.sh on macOS non-root (requires sudo before confirm_execute)"
  - "Dummy wordlist file creation in setup_file for scripts with pre-confirm_execute checks"
  - "Conditional mock creation (only when tool missing) to prefer real binaries"

patterns-established:
  - "Dynamic test registration: bats_test_function at file-level with find-based discovery"
  - "Mock strategy: simple exit-0 scripts in BATS_FILE_TMPDIR, PATH-prepended in setup()"
  - "Integration test naming: INTG-NN prefix for requirement traceability"

# Metrics
duration: 14min
completed: 2026-02-12
---

# Phase 20 Plan 01: CLI Contract Tests Summary

**Dynamic CLI contract tests using bats_test_function for 67 help-output and 62 execute-mode-rejection tests with find-based discovery and mock command infrastructure for 19 pentesting tools**

## Performance

- **Duration:** 14 min
- **Started:** 2026-02-12T15:16:47Z
- **Completed:** 2026-02-12T15:30:47Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments
- 67 INTG-01 tests verify every script exits 0 on --help with "Usage:" in output
- 62 INTG-02 tests verify execute-mode scripts reject piped stdin (63 on Linux CI)
- 2 INTG-03 meta-tests confirm dynamic discovery finds >= 67 all-scripts and >= 62 execute-mode scripts
- Mock binaries for 19 pentesting tools created only when missing (prefer real tools)
- Total test suite grew from 55 to 186 tests, all passing
- Tests auto-grow when new scripts are added (no hardcoded script lists)

## Task Commits

Each task was committed atomically:

1. **Task 1: Create integration test file with help contracts and dynamic discovery (INTG-01, INTG-03)** - `46418dd` (feat)
2. **Task 2: Add execute-mode rejection tests with mock commands (INTG-02, INTG-04)** - `595f74d` (feat)

## Files Created/Modified
- `tests/intg-cli-contracts.bats` - 137-line integration test file with dynamic test registration, mock infrastructure, and wordlist management

## Decisions Made
- Used `bats_test_function` for dynamic per-script test registration instead of loop-in-single-test (gives individual TAP output per script)
- Conditional mock creation: `if ! command -v "$tool"` ensures real tools are preferred over mocks
- Excluded `diagnose-latency.sh` from INTG-02 on macOS non-root (script requires sudo before reaching `confirm_execute`)
- Created dummy wordlist files in `setup_file()` for scripts that check wordlist existence before `confirm_execute`, with cleanup in `teardown_file()`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Wordlist scripts exit before confirm_execute when wordlist files missing**
- **Found during:** Task 2 (INTG-02 execute-mode tests)
- **Issue:** 3 scripts (ffuf/fuzz-parameters.sh, gobuster/discover-directories.sh, gobuster/enumerate-subdomains.sh) check for wordlist files after require_cmd but before confirm_execute. Missing wordlists cause early exit, preventing the -x piped stdin test from reaching the code path under test.
- **Fix:** Create dummy wordlist files (common.txt, subdomains-top1million-5000.txt, rockyou.txt) in setup_file() if missing, clean up in teardown_file()
- **Files modified:** tests/intg-cli-contracts.bats
- **Verification:** All 3 scripts now reach confirm_execute and correctly reject piped stdin
- **Committed in:** 595f74d (Task 2 commit)

**2. [Rule 1 - Bug] diagnose-latency.sh requires sudo on macOS before confirm_execute**
- **Found during:** Task 2 (INTG-02 execute-mode tests)
- **Issue:** diagnose-latency.sh has a macOS sudo check (EUID != 0) that exits 1 before reaching confirm_execute. Cannot override EUID (readonly bash variable).
- **Fix:** Platform-conditional exclusion in _discover_execute_mode_scripts(): skip diagnose-latency.sh on macOS non-root. On Linux CI, it is included (no sudo requirement).
- **Files modified:** tests/intg-cli-contracts.bats
- **Verification:** 62 INTG-02 tests pass on macOS, expected 63 on Linux CI
- **Committed in:** 595f74d (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (2 bugs -- scripts with pre-confirm_execute preconditions)
**Impact on plan:** Both fixes necessary for correctness. Test count adjusted from 187 to 186 on macOS (187 on Linux). No scope creep.

## Issues Encountered
None beyond the deviations documented above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Integration test infrastructure complete and proven
- 186 tests passing across unit (55) and integration (131) categories
- Ready for Phase 21 (CI Integration) -- tests can be run via `make test` in GitHub Actions
- Ready for Phase 22 (Script Metadata Headers) -- new scripts with headers will be auto-discovered by tests

## Self-Check: PASSED

- FOUND: tests/intg-cli-contracts.bats (137 lines, >= 80 minimum)
- FOUND: commit 46418dd (Task 1)
- FOUND: commit 595f74d (Task 2)
- FOUND: bats_test_function in test file
- FOUND: find-based discovery pattern in test file

---
*Phase: 20-script-integration-tests*
*Completed: 2026-02-12*
