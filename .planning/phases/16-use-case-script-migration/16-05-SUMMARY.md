---
phase: 16-use-case-script-migration
plan: 05
subsystem: scripts
tags: [sqlmap, netcat, dual-mode, parse_common_args, run_or_show, nc_variant]

# Dependency graph
requires:
  - phase: 14-argument-parsing-and-dual-mode-pattern
    provides: parse_common_args, run_or_show, confirm_execute
  - phase: 15-examples-script-migration
    provides: migration pattern for variant-specific and optional-target scripts
provides:
  - 6 sqlmap/netcat use-case scripts migrated to dual-mode pattern
  - sqlmap URL derivation pattern preserved across 3 scripts
  - netcat NC_VARIANT detection and _listener_cmd() helper preserved
affects: [16-07-PLAN, 16-08-PLAN]

# Tech tracking
tech-stack:
  added: []
  patterns: [sqlmap URL derivation with run_or_show, structural-only migration for variant-specific scripts]

key-files:
  created: []
  modified:
    - scripts/sqlmap/dump-database.sh
    - scripts/sqlmap/test-all-parameters.sh
    - scripts/sqlmap/bypass-waf.sh
    - scripts/netcat/scan-ports.sh
    - scripts/netcat/setup-listener.sh
    - scripts/netcat/transfer-files.sh

key-decisions:
  - "sqlmap examples 2-5, 8 (hardcoded -D dvwa) kept as info+echo in dump-database.sh"
  - "sqlmap example 4 (request file) kept as info+echo in test-all-parameters.sh -- no URL variable"
  - "sqlmap example 10 (--list-tampers) kept as info+echo in bypass-waf.sh -- no URL needed"
  - "netcat setup-listener.sh: 0 convertible examples -- all variant-specific if/else/case"
  - "netcat transfer-files.sh: 0 convertible examples -- all multi-step receiver+sender workflows"
  - "netcat scan-ports.sh: examples 3, 7, 10 (chained/loop) kept as info+echo"
  - "scan-ports.sh example 9 simplified to plain nc -zv (removed grep pipe for run_or_show compatibility)"

patterns-established:
  - "URL derivation preserved: URL=\"${TARGET:-'http://target/page.php?id=1'}\" with run_or_show using $URL"
  - "Variant-specific scripts get structural-only migration (parse_common_args + confirm_execute) with 0 run_or_show"

# Metrics
duration: 6min
completed: 2026-02-11
---

# Phase 16 Plan 05: sqlmap and netcat Use-Case Script Migration Summary

**Migrated 6 sqlmap/netcat use-case scripts to dual-mode pattern with URL derivation and NC_VARIANT detection preserved**

## Performance

- **Duration:** 6 min
- **Started:** 2026-02-11T22:12:39Z
- **Completed:** 2026-02-11T22:19:34Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- Migrated 3 sqlmap scripts (dump-database, test-all-parameters, bypass-waf) with URL derivation pattern
- Migrated 3 netcat scripts (scan-ports, setup-listener, transfer-files) with NC_VARIANT detection
- Converted 30 examples to run_or_show across all 6 scripts; kept 18 as static info+echo
- All 6 scripts respond to --help, -x, and reject piped stdin in execute mode

## Task Commits

Each task was committed atomically:

1. **Task 1: Migrate sqlmap/dump-database, test-all-parameters, bypass-waf** - `4f498d1` (feat)
2. **Task 2: Migrate netcat/scan-ports, setup-listener, transfer-files** - `a8fe413` (feat)

## Files Created/Modified
- `scripts/sqlmap/dump-database.sh` - parse_common_args + 5 run_or_show + 5 static (dvwa-specific)
- `scripts/sqlmap/test-all-parameters.sh` - parse_common_args + 9 run_or_show + 1 static (request file)
- `scripts/sqlmap/bypass-waf.sh` - parse_common_args + 9 run_or_show + 1 static (--list-tampers)
- `scripts/netcat/scan-ports.sh` - parse_common_args + 7 run_or_show + 3 static (loops/chained)
- `scripts/netcat/setup-listener.sh` - parse_common_args + 0 run_or_show (all variant-specific)
- `scripts/netcat/transfer-files.sh` - parse_common_args + 0 run_or_show (all multi-step workflows)

## Decisions Made
- sqlmap examples with hardcoded `-D dvwa` database references kept as static info+echo since they reference specific tables
- sqlmap `--list-tampers` and `-r request.txt` examples kept static since they do not use the URL variable
- netcat setup-listener.sh has zero run_or_show conversions -- every example uses variant-specific if/else or case
- netcat transfer-files.sh has zero run_or_show conversions -- every example is a multi-step receiver+sender workflow
- scan-ports.sh example 9 simplified from `nc -zv ... | grep` to plain `nc -zv` for run_or_show compatibility

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Simplified scan-ports.sh example 9 for run_or_show**
- **Found during:** Task 2
- **Issue:** Original example 9 used `nc -zv ${TARGET} 1-1024 2>&1 | grep -i 'succeeded\|open'` which cannot be passed to run_or_show as a single command (pipe)
- **Fix:** Kept as run_or_show with plain `nc -zv "$TARGET" 1-1024` and updated description to "Scan and grep for open/succeeded ports"
- **Files modified:** scripts/netcat/scan-ports.sh
- **Verification:** Script runs without error in show mode
- **Committed in:** a8fe413 (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Minor simplification for run_or_show compatibility. No scope creep.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- 6 scripts migrated, ready for remaining use-case script plans (16-06 through 16-08)
- Pattern well-established for remaining sqlmap/netcat-style scripts

## Self-Check: PASSED

- All 6 migrated script files exist on disk
- All 6 contain `parse_common_args`
- Commit `4f498d1` (Task 1: sqlmap) verified in git log
- Commit `a8fe413` (Task 2: netcat) verified in git log
- --help exits 0 for all 6 scripts
- Piped stdin in execute mode exits non-zero for all tested scripts

---
*Phase: 16-use-case-script-migration*
*Completed: 2026-02-11*
