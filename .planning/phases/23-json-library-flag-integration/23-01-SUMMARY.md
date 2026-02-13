---
phase: 23-json-library-flag-integration
plan: 01
subsystem: infra
tags: [json, jq, bash, fd3, structured-output]

# Dependency graph
requires: []
provides:
  - "lib/json.sh with 5 public functions for JSON state, accumulation, finalization"
  - "-j/--json flag parsing in args.sh with fd3 redirect and NO_COLOR"
  - "4-path run_or_show in output.sh (show+text, execute+text, show+JSON, execute+JSON)"
  - "safety_banner and confirm_execute suppression in JSON mode"
affects: [24-json-testing, 25-script-migration, 26-cli-wrapper, 27-docs-polish]

# Tech tracking
tech-stack:
  added: [jq]
  patterns: [fd3-envelope-output, json-accumulation-array, module-source-guard]

key-files:
  created:
    - scripts/lib/json.sh
  modified:
    - scripts/common.sh
    - scripts/lib/args.sh
    - scripts/lib/output.sh

key-decisions:
  - "fd3 for JSON output: exec 3>&1 saves original stdout, exec 1>&2 redirects script output to stderr"
  - "Lazy jq dependency: _json_check_jq at source time, _json_require_jq only when -j is parsed"
  - "Color reset in args.sh after parse: colors.sh evaluates at source time, so -j must reset vars at runtime"
  - "BASH_SOURCE[1] fallback: use ${BASH_SOURCE[1]:-unknown} to handle shallow call stacks under set -u"

patterns-established:
  - "JSON envelope schema: {meta, results, summary} with tool/script/target/started/finished/mode metadata"
  - "json_is_active guard pattern: all JSON functions no-op when JSON_MODE != 1"
  - "4-path run_or_show: show+text, execute+text, show+JSON, execute+JSON"

# Metrics
duration: 22min
completed: 2026-02-13
---

# Phase 23 Plan 01: JSON Library & Flag Integration Summary

**lib/json.sh with 5 public functions (accumulate/finalize JSON envelope to fd3), -j flag parsing with fd3 redirect, and 4-path run_or_show for structured output**

## Performance

- **Duration:** 22 min
- **Started:** 2026-02-13T22:06:27Z
- **Completed:** 2026-02-13T22:28:17Z
- **Tasks:** 2
- **Files modified:** 4 (1 created, 3 modified)

## Accomplishments
- Created `scripts/lib/json.sh` with complete JSON output infrastructure: state management, result accumulation via jq --arg escaping, and envelope finalization to fd3
- Integrated `-j`/`--json` flag into `parse_common_args` with fd3 redirect, NO_COLOR, and color var reset
- Added 4-path `run_or_show` to output.sh: show+text (existing), execute+text (existing), show+JSON (accumulate examples), execute+JSON (capture stdout/stderr/exit_code)
- Suppressed safety_banner and confirm_execute in JSON mode

## Task Commits

Each task was committed atomically:

1. **Task 1: Create lib/json.sh and wire into common.sh** - `c018e92` (feat)
2. **Task 2: Add -j flag parsing to args.sh and JSON branches to output.sh** - `e6ac6f8` (feat)

## Files Created/Modified
- `scripts/lib/json.sh` - New: JSON state management, 5 public functions (json_is_active, json_set_meta, json_add_result, json_add_example, json_finalize), 2 internal (_json_check_jq, _json_require_jq), 146 lines
- `scripts/common.sh` - Modified: sources json.sh at position 6 (after cleanup.sh, before output.sh), updated @dependencies header
- `scripts/lib/args.sh` - Modified: added -j/--json case to parse_common_args, JSON activation block with fd3 redirect and color reset
- `scripts/lib/output.sh` - Modified: 4-path run_or_show, safety_banner skip, confirm_execute skip in JSON mode

## Decisions Made
- **fd3 for JSON output:** `exec 3>&1` in parse_common_args saves original stdout as fd3, `exec 1>&2` redirects all script output to stderr. JSON envelope writes to fd3. Falls back to stdout when fd3 is not open (unit testing).
- **Lazy jq dependency:** `_json_check_jq` runs at source time (sets `_JSON_JQ_AVAILABLE`), but `_json_require_jq` only runs when `-j` is actually parsed. Scripts without `-j` never require jq.
- **Color reset at parse time:** Since `colors.sh` evaluates at source time, the `-j` activation block in args.sh must explicitly reset `RED='' GREEN='' ...` at runtime.
- **BASH_SOURCE[1] fallback:** Used `${BASH_SOURCE[1]:-unknown}` to handle bash -c invocations where the call stack is shallow (prevents unbound variable error under `set -u`).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed BASH_SOURCE[1] unbound variable in json_set_meta**
- **Found during:** Task 2 verification (integration test)
- **Issue:** `set -u` (strict mode) caused `BASH_SOURCE[1]: unbound variable` when `json_set_meta` was called from a `bash -c` invocation where the call stack was too shallow
- **Fix:** Changed `${BASH_SOURCE[1]}` to `${BASH_SOURCE[1]:-unknown}` with fallback
- **Files modified:** scripts/lib/json.sh
- **Verification:** Integration test passes without error
- **Committed in:** e6ac6f8 (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Essential fix for strict mode compatibility. No scope creep.

## Issues Encountered
- **bash 5.3 fd3 pipeline quirk:** When using `bash -c '...' 3>&1 | jq .` (without subshell grouping), the JSON output appears doubled. This is a bash 5.3 redirect scoping behavior where `3>&1` interacts with the pipeline. The fix is to use `(bash -c '...' 3>&1) | jq .` with parentheses, or redirect fd3 to a file. This is a testing ergonomics issue, not a code bug -- real-world consumers will use proper redirect patterns.

## User Setup Required

None - no external service configuration required. jq is the only dependency and is only needed when `-j` is used.

## Next Phase Readiness
- JSON infrastructure is complete and ready for Phase 24 (testing)
- Phase 24 should test: show+JSON, execute+JSON, no-jq graceful error, fd3 output, RFC 8259 escaping
- Phase 25 (script migration) can add `json_set_meta`/`json_finalize` calls to each use-case script
- Known: BATS tests for fd3 output may need `run --separate-stderr` (BATS 1.5+ feature, already flagged in STATE.md)

## Self-Check: PASSED

- [x] scripts/lib/json.sh exists on disk
- [x] scripts/common.sh exists on disk
- [x] scripts/lib/args.sh exists on disk
- [x] scripts/lib/output.sh exists on disk
- [x] Commit c018e92 found (Task 1)
- [x] Commit e6ac6f8 found (Task 2)
- [x] 266 BATS tests pass (0 failures)

---
*Phase: 23-json-library-flag-integration*
*Completed: 2026-02-13*
