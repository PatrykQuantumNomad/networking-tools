---
phase: 26-integration-tests
plan: 01
subsystem: tests
tags: [bats, json, integration-tests, dynamic-registration]
dependency-graph:
  requires: [lib/json.sh, lib/args.sh, 46 use-case scripts]
  provides: [automated JSON output regression tests]
  affects: [CI pipeline (bats tests/)]
tech-stack:
  added: []
  patterns: [bash-c-wrapper-for-fd3-capture, dynamic-bats-test-registration]
key-files:
  created:
    - tests/intg-json-output.bats
  modified: []
key-decisions:
  - "bash -c wrapper for JSON capture: BATS run mixes stdout+stderr; wrapping with bash -c and 2>/dev/null inside isolates JSON on stdout"
  - "Exclude diagnose-latency.sh on macOS non-root: requires sudo before JSON output, same exclusion pattern as intg-cli-contracts.bats"
  - "Use -ge 45 for meta-test count: 46 on Linux/root, 45 on macOS non-root due to diagnose-latency.sh exclusion"
metrics:
  duration: 6min
  completed: 2026-02-14
---

# Phase 26 Plan 01: JSON Integration Tests Summary

BATS integration tests validating all 46 use-case scripts produce parseable JSON with correct envelope structure via `-j` flag, using dynamic test registration and bash -c wrapper for fd3 stdout isolation.

## Performance

- **Duration:** 6min (started 2026-02-14T11:17:43Z, completed 2026-02-14T11:23:41Z)
- **Tasks:** 2/2 completed
- **Files modified:** 1 (tests/intg-json-output.bats created)
- **Test count:** 47 new tests (45 dynamic JSON tests + 2 static meta-tests on macOS; 48 on Linux)
- **Total suite:** 342 tests (295 existing + 47 new), all passing

## Accomplishments

1. **Created `tests/intg-json-output.bats`** with dynamic test registration that discovers all use-case scripts via `find` with exclusion filters (lib/, diagnostics/, common.sh, check-tools.sh, examples.sh, check-docs-completeness.sh)

2. **Each script's `-j` output validated** for 9 structural assertions: valid JSON, top-level keys (meta/results/summary), meta fields (tool/script/started), meta field types (non-empty strings), results type (array), summary fields (total/succeeded/failed), summary.total type (number)

3. **Full test suite passes** with zero failures: 342 tests total (295 existing + 47 new)

## Task Commits

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create intg-json-output.bats with dynamic JSON output tests | c5841a4 | tests/intg-json-output.bats |
| 2 | Verify full test suite passes with new integration tests | (verification only, no changes) | - |

## Files Created

- `tests/intg-json-output.bats` (129 lines) -- Dynamic integration tests for JSON output of all 46 use-case scripts

## Decisions Made

1. **bash -c wrapper for JSON capture:** BATS `run` captures both stdout and stderr into `$output`. Since `-j` mode redirects stdout to stderr (`exec 1>&2`) and writes JSON to fd3 (original stdout), the `$output` contained mixed human-readable + JSON text. Solution: `run bash -c "bash '$script' -j dummy_target 2>/dev/null"` -- the inner `2>/dev/null` discards stderr before BATS captures, leaving only JSON in `$output`.

2. **diagnose-latency.sh exclusion on macOS non-root:** Same pattern as `intg-cli-contracts.bats` `_discover_execute_mode_scripts()`. The script requires sudo on macOS (raw socket access for mtr) and exits before producing JSON. Excluded from discovery on macOS non-root; included on Linux/root.

3. **Meta-test threshold -ge 45:** Accounts for macOS non-root (45 scripts) vs Linux/root (46 scripts). Uses `-ge` not `-eq` to allow future script additions without test breakage.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed BATS stdout/stderr capture for fd3 JSON output**
- **Found during:** Task 1 initial test run
- **Issue:** Plan specified `run bash "$script" -j dummy_target 2>/dev/null` but BATS `run` captures both stdout and stderr into `$output`, so the `2>/dev/null` only affected BATS-level stderr, not the inner command's stderr. All 46 tests failed with "jq parse error: Invalid numeric literal" because `$output` contained `[INFO]` text mixed with JSON.
- **Fix:** Changed to `run bash -c "bash '$script' -j dummy_target 2>/dev/null"` so stderr is discarded inside the `bash -c` subprocess before BATS captures output.
- **Files modified:** tests/intg-json-output.bats
- **Commit:** c5841a4

**2. [Rule 1 - Bug] Excluded diagnose-latency.sh on macOS non-root**
- **Found during:** Task 1 initial test run
- **Issue:** `diagnose-latency.sh` exits with code 1 on macOS non-root (mtr requires sudo) before producing any JSON output. Test 42 failed with `assert_success`.
- **Fix:** Added macOS non-root exclusion in `_discover_json_scripts()`, matching the existing pattern in `intg-cli-contracts.bats` `_discover_execute_mode_scripts()`. Adjusted meta-test threshold from `-ge 46` to `-ge 45`.
- **Files modified:** tests/intg-json-output.bats
- **Commit:** c5841a4

## Issues Encountered

None beyond the deviations documented above (both resolved automatically).

## Next Phase Readiness

Phase 26 (Integration Tests) is complete. Phase 27 (Documentation) can proceed. No blockers, no pending items. The 342-test suite provides full regression coverage for JSON output across all scripts.

## Self-Check: PASSED

- [x] tests/intg-json-output.bats exists on disk
- [x] Commit c5841a4 found in git log (grep "26-01")
