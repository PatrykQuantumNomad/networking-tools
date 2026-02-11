---
phase: 16-use-case-script-migration
plan: 02
subsystem: scripts
tags: [bash, dig, curl, dual-mode, parse_common_args, run_or_show]

# Dependency graph
requires:
  - phase: 14-argument-parsing-and-dual-mode-pattern
    provides: parse_common_args, confirm_execute, run_or_show library functions
provides:
  - 6 dig/curl use-case scripts accepting -h/-v/-q/-x flags
  - query-dns-records.sh with 10 run_or_show examples
  - attempt-zone-transfer.sh with 3 run_or_show + 7 info+echo examples
  - check-dns-propagation.sh structural-only migration (all for-loops)
  - check-ssl-certificate.sh structural-only migration (all pipes/format strings)
  - debug-http-response.sh structural-only migration (all -w format strings)
  - test-http-endpoints.sh with 2 run_or_show + 8 info+echo examples
affects: [16-use-case-script-migration, 17-shellcheck-compliance]

# Tech tracking
tech-stack:
  added: []
  patterns: [pipe-commands kept as info+echo, format-string commands kept as info+echo]

key-files:
  created: []
  modified:
    - scripts/dig/query-dns-records.sh
    - scripts/dig/attempt-zone-transfer.sh
    - scripts/dig/check-dns-propagation.sh
    - scripts/curl/check-ssl-certificate.sh
    - scripts/curl/debug-http-response.sh
    - scripts/curl/test-http-endpoints.sh

key-decisions:
  - "Pipe commands (curl | grep) kept as info+echo -- run_or_show cannot handle shell pipes"
  - "curl format strings (-w '%{http_code}') kept as info+echo per Phase 15-02 precedent"
  - "check-ssl-certificate.sh is structural-only -- all 10 examples use pipes or format strings"

patterns-established:
  - "Pipe commands always stay info+echo: run_or_show executes commands directly, cannot handle shell pipes"

# Metrics
duration: 7min
completed: 2026-02-11
---

# Phase 16 Plan 02: Dig and Curl Use-Case Script Migration Summary

**6 dig/curl use-case scripts migrated to dual-mode pattern with 15 run_or_show conversions and 3 structural-only migrations**

## Performance

- **Duration:** 7 min
- **Started:** 2026-02-11T22:11:30Z
- **Completed:** 2026-02-11T22:18:43Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- 3 dig use-case scripts migrated: query-dns-records (10 run_or_show), attempt-zone-transfer (3 run_or_show), check-dns-propagation (structural-only)
- 3 curl use-case scripts migrated: check-ssl-certificate (structural-only), debug-http-response (structural-only), test-http-endpoints (2 run_or_show)
- All 6 scripts accept -h/-v/-q/-x flags, reject piped stdin in execute mode, and preserve backward-compatible output

## Task Commits

Each task was committed atomically:

1. **Task 1: Migrate dig use-case scripts** - `f273860` (feat)
2. **Task 2: Migrate curl use-case scripts** - `bd5e1c0` (feat)

## Files Created/Modified
- `scripts/dig/query-dns-records.sh` - All 10 dig examples converted to run_or_show
- `scripts/dig/attempt-zone-transfer.sh` - 3 simple dig commands converted, 7 kept as info+echo (subshells/loops/file output)
- `scripts/dig/check-dns-propagation.sh` - Structural-only: all 10 examples are for-loops
- `scripts/curl/check-ssl-certificate.sh` - Structural-only: all examples use pipes or format strings
- `scripts/curl/debug-http-response.sh` - Structural-only: all examples use -w format strings, TIMING_FMT preserved
- `scripts/curl/test-http-endpoints.sh` - Examples 7 (HEAD) and 8 (OPTIONS) converted to run_or_show

## Decisions Made
- Pipe commands (curl | grep) kept as info+echo -- run_or_show executes "$@" directly and cannot handle shell pipes
- curl format strings (-w '%{http_code}') kept as info+echo per Phase 15-02 precedent
- check-ssl-certificate.sh plan called for 5 run_or_show conversions but all 5 use pipes -- kept as info+echo (correct behavior)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] check-ssl-certificate.sh examples 1,2,5,8,10 kept as info+echo**
- **Found during:** Task 2 (curl migration)
- **Issue:** Plan specified converting examples 1,2,5,8,10 to run_or_show, but all 5 use shell pipes (curl ... | grep ...) which run_or_show cannot handle
- **Fix:** Kept all examples as info+echo, making check-ssl-certificate.sh a structural-only migration
- **Files modified:** scripts/curl/check-ssl-certificate.sh
- **Verification:** Script runs correctly in show mode, --help exits 0, -x piped stdin rejected

---

**Total deviations:** 1 auto-fixed (1 bug in plan analysis)
**Impact on plan:** Correct behavior -- pipe commands cannot be passed to run_or_show. No scope creep.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- 6 more dig/curl use-case scripts complete, ready for next wave of migrations
- Established that pipe commands and format string commands always stay as info+echo

## Self-Check: PASSED

All 6 script files verified present. Both commit hashes (f273860, bd5e1c0) verified in git log.

---
*Phase: 16-use-case-script-migration*
*Completed: 2026-02-11*
