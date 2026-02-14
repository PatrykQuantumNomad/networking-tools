---
phase: 27-documentation
plan: 02
subsystem: testing
tags: [bats, json, documentation, ci-guardrail]

# Dependency graph
requires:
  - phase: 27-01
    provides: "--json flag documented in all 46 use-case scripts (help text and @usage headers)"
provides:
  - "DOC-01 test: verifies --help output contains --json for every use-case script"
  - "DOC-02 test: verifies @usage header contains -j|--json for every use-case script"
  - "CI guardrail preventing undocumented JSON flags in future scripts"
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Dynamic DOC test registration via _discover_use_case_scripts + bats_test_function"

key-files:
  created:
    - tests/intg-doc-json-flag.bats
  modified: []

key-decisions:
  - "No macOS/diagnose-latency exclusion needed: --help and header checks don't require sudo"
  - "Separate _discover_use_case_scripts function (not reusing _discover_json_scripts) for clean file-local scope"

patterns-established:
  - "DOC-XX naming convention for documentation verification tests"

# Metrics
duration: 3min
completed: 2026-02-14
---

# Phase 27 Plan 02: Documentation Verification Tests Summary

**93 BATS tests (DOC-01 help text + DOC-02 @usage header + meta) enforcing -j/--json documentation across all 46 use-case scripts**

## Performance

- **Duration:** 3 min
- **Started:** 2026-02-14T12:17:18Z
- **Completed:** 2026-02-14T12:20:16Z
- **Tasks:** 1
- **Files created:** 1

## Accomplishments
- 46 DOC-01 tests verify every use-case script's --help output contains --json
- 46 DOC-02 tests verify every use-case script's @usage header contains -j|--json
- 1 DOC-META test verifies discovery finds all 46 scripts
- Full test suite passes (435 tests, 0 failures)

## Task Commits

Each task was committed atomically:

1. **Task 1: Create BATS verification tests for JSON flag documentation** - `6e11374` (test)

**Plan metadata:** `56dbe32` (docs: complete plan)

## Files Created/Modified
- `tests/intg-doc-json-flag.bats` - 93 dynamically registered tests for JSON flag documentation (111 lines)

## Decisions Made
- No macOS/diagnose-latency exclusion needed for DOC tests since --help and header parsing don't require sudo
- Created file-local `_discover_use_case_scripts` function rather than importing from another test file, following the same self-contained pattern as other test files

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Phase 27 (Documentation) is now complete -- all plans executed
- v1.4 milestone (JSON Output Mode) is fully complete

## Self-Check: PASSED

- [x] tests/intg-doc-json-flag.bats exists (111 lines, >= 40 minimum)
- [x] Commit 6e11374 exists in git log
- [x] 27-02-SUMMARY.md exists

---
*Phase: 27-documentation*
*Completed: 2026-02-14*
