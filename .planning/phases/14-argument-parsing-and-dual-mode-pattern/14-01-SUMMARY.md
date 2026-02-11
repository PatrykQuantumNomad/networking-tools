---
phase: 14-argument-parsing-and-dual-mode-pattern
plan: 01
subsystem: infra
tags: [bash, argument-parsing, dual-mode, run-or-show, cli-flags]

# Dependency graph
requires:
  - phase: 13-library-infrastructure
    provides: modular library with logging, output, and strict mode modules
provides:
  - parse_common_args() handling -h/-v/-q/-x flags with unknown flag passthrough
  - run_or_show() dual-mode function (show command or execute it)
  - confirm_execute() interactive safety gate for execute mode
  - Proven migration pattern validated on nmap/examples.sh pilot
affects: [14-02-verification, 15-examples-migration, 16-use-case-migration]

# Tech tracking
tech-stack:
  added: []
  patterns: [parse-common-args-pattern, run-or-show-dual-mode, confirm-execute-gate, remaining-args-passthrough]

key-files:
  created:
    - scripts/lib/args.sh
  modified:
    - scripts/lib/output.sh
    - scripts/common.sh
    - scripts/nmap/examples.sh

key-decisions:
  - "EXECUTE_MODE defaults to show -- all scripts are backward compatible without any code changes"
  - "Unknown flags pass through to REMAINING_ARGS (permissive, not rejecting) for per-script extensibility"
  - "confirm_execute refuses non-interactive stdin in execute mode -- prevents silent automated execution of pentesting tools"
  - "Example 9 (hardcoded subnet) kept as static info+echo -- run_or_show only for $TARGET-based commands"

patterns-established:
  - "Migration pattern: parse_common_args $@ + set -- REMAINING_ARGS replaces inline help check"
  - "run_or_show replaces 3-line info+echo+echo pattern with single function call"
  - "Interactive demo guarded by EXECUTE_MODE check -- skip in execute mode since commands already ran"
  - "Empty array safety: ${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}} for Bash 4.0-4.3 under set -u"

# Metrics
duration: 3min
completed: 2026-02-11
---

# Phase 14 Plan 01: Args Module and Pilot Migration Summary

**parse_common_args() with -h/-v/-q/-x flag extraction, run_or_show() dual-mode pattern, and confirm_execute() safety gate -- proven backward-compatible on nmap/examples.sh pilot**

## Performance

- **Duration:** 3 min
- **Started:** 2026-02-11T20:37:27Z
- **Completed:** 2026-02-11T20:40:35Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Created scripts/lib/args.sh with parse_common_args() using manual while/case/shift loop handling 4 common flags plus -- separator and unknown flag passthrough
- Added run_or_show() and confirm_execute() to scripts/lib/output.sh -- dual-mode execution that either prints commands (show) or runs them (execute)
- Wired args.sh into common.sh source chain between output.sh and diagnostic.sh
- Pilot-migrated nmap/examples.sh: 9 examples converted to run_or_show, backward-compatible output verified by diff (only 1-space indent normalization on example 10)
- All 5 success criteria verified: --help works, show mode unchanged, execute mode gates on interactive terminal, make target still works, unknown flags pass through

## Task Commits

Each task was committed atomically:

1. **Task 1: Create args.sh module and add run_or_show/confirm_execute to output.sh** - `debcc9d` (feat)
2. **Task 2: Pilot-migrate nmap/examples.sh to parse_common_args and run_or_show** - `532e2c6` (feat)

## Files Created/Modified
- `scripts/lib/args.sh` - New module: parse_common_args() with source guard, EXECUTE_MODE global, REMAINING_ARGS array
- `scripts/lib/output.sh` - Added run_or_show() and confirm_execute() functions
- `scripts/common.sh` - Added args.sh to module source chain (1 new line)
- `scripts/nmap/examples.sh` - Migrated to use parse_common_args, run_or_show, confirm_execute

## Decisions Made
- EXECUTE_MODE defaults to "show" so all scripts are backward compatible without any code changes until they explicitly opt in
- Unknown flags pass through to REMAINING_ARGS rather than being rejected -- preserves per-script extensibility (ARGS-03)
- confirm_execute exits with error on non-interactive stdin in execute mode -- prevents silent automated execution of pentesting tools via pipes
- Example 9 (hardcoded subnet scan) kept as static info+echo since it does not use $TARGET and cannot meaningfully execute
- Example 10 indent normalized from 4 spaces to 3 spaces (matching all other examples) -- acceptable minor cleanup

## Deviations from Plan

None -- plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- args.sh, run_or_show, and confirm_execute are ready for all 66 scripts via common.sh
- Migration pattern proven on nmap/examples.sh: parse_common_args + set -- REMAINING_ARGS + run_or_show conversions
- Ready for 14-02 (automated verification test script) and Phase 15 (mass examples.sh migration)
- Backward compatibility verified by diffing show-mode output before and after migration

---
*Phase: 14-argument-parsing-and-dual-mode-pattern*
*Completed: 2026-02-11*
