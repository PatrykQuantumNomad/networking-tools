---
phase: 24-library-unit-tests
plan: 02
subsystem: testing
tags: [bats, json, args, output, unit-tests, bash]

requires:
  - phase: 23-json-library-flag
    provides: "-j/--json flag in args.sh and JSON-mode plumbing in output.sh"
provides:
  - "BATS tests proving -j/--json flag parsing in all combinations"
  - "BATS tests proving safety_banner and confirm_execute JSON-mode suppression"
affects: [24-library-unit-tests]

tech-stack:
  added: []
  patterns: ["subprocess isolation for BATS tests that trigger exec fd redirections"]

key-files:
  created: []
  modified:
    - tests/lib-args.bats
    - tests/lib-output.bats

key-decisions:
  - "Used subprocess isolation (_run_parse_json helper) for all -j tests to prevent BATS fd3 TAP corruption from exec 3>&1"
  - "Direct-call pattern for -- -j test since JSON mode is not activated"
  - "Direct-call pattern for output.sh suppression tests since safety_banner and confirm_execute only check json_is_active without exec redirections"

patterns-established:
  - "_run_parse_json helper: reusable subprocess pattern for testing any flag that triggers exec redirections in BATS"

duration: 3min
completed: 2026-02-13
---

# Phase 24 Plan 02: Args and Output JSON-Mode Tests Summary

**10 BATS tests proving -j/--json flag parsing, color reset, flag combinations, error paths, and output suppression in JSON mode**

## Performance

- **Duration:** 3 min
- **Started:** 2026-02-13T23:09:00Z
- **Completed:** 2026-02-13T23:11:50Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- 8 new tests in lib-args.bats covering -j basic, --json long flag, color variable reset, -j -x combo, -j -v combo, -- -j positional, jq-unavailable failure, and -j -h help precedence
- 2 new tests in lib-output.bats confirming safety_banner and confirm_execute produce no output when JSON_MODE=1
- Full test suite passes at 295 tests with 0 failures and no regressions
- Established _run_parse_json subprocess helper pattern for safe BATS testing of exec-redirecting code

## Task Commits

Each task was committed atomically:

1. **Task 1: Add -j/--json flag tests to lib-args.bats** - `bad012a` (test)
2. **Task 2: Add JSON-mode suppression tests to lib-output.bats** - `dc2fe6a` (test)

## Files Created/Modified

- `tests/lib-args.bats` - Added 8 JSON flag tests with _run_parse_json subprocess helper (96 lines added)
- `tests/lib-output.bats` - Added 2 JSON-mode suppression tests (17 lines added)

## Decisions Made

- **Subprocess isolation for -j tests:** parse_common_args -j runs `exec 3>&1; exec 1>&2` which would corrupt BATS internal TAP protocol on fd3. All -j tests use `run bash -c '...'` via the _run_parse_json helper to isolate exec redirections in a child process.
- **Direct call for -- -j test:** When -j appears after --, it becomes a positional arg and JSON mode is never activated, so no exec redirections occur. Direct call is safe.
- **Direct call for output.sh tests:** safety_banner and confirm_execute only call json_is_active (a simple variable check) and return early -- no exec redirections involved.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- All -j/--json flag parsing paths are now tested
- JSON-mode output suppression is verified
- Full test suite green at 295 tests, ready for any further JSON integration work

## Self-Check: PASSED

- FOUND: tests/lib-args.bats
- FOUND: tests/lib-output.bats
- FOUND: 24-02-SUMMARY.md
- FOUND: bad012a (Task 1 commit)
- FOUND: dc2fe6a (Task 2 commit)

---
*Phase: 24-library-unit-tests*
*Completed: 2026-02-13*
