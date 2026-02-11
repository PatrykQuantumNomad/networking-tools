---
phase: 16-use-case-script-migration
plan: 06
subsystem: scripts
tags: [foremost, tshark, dual-mode, parse_common_args, run_or_show, use-case-scripts]

# Dependency graph
requires:
  - phase: 14-argument-parsing-and-dual-mode-pattern
    provides: parse_common_args, run_or_show, confirm_execute, EXECUTE_MODE infrastructure
  - phase: 15-examples-script-migration
    provides: migration patterns for optional-target and interface-based scripts
provides:
  - 6 use-case scripts migrated to dual-mode pattern (foremost x3, tshark x3)
  - 15 run_or_show conversions across tshark interface scripts
affects: [16-use-case-script-migration, 17-shellcheck-compliance]

# Tech tracking
tech-stack:
  added: []
  patterns: [tshark interface scripts use run_or_show with sudo tshark -i TARGET, foremost optional-target structural-only migration]

key-files:
  created: []
  modified:
    - scripts/foremost/analyze-forensic-image.sh
    - scripts/foremost/carve-specific-filetypes.sh
    - scripts/foremost/recover-deleted-files.sh
    - scripts/tshark/capture-http-credentials.sh
    - scripts/tshark/analyze-dns-queries.sh
    - scripts/tshark/extract-files-from-capture.sh

key-decisions:
  - "tshark interface examples (using $TARGET) converted to run_or_show; hardcoded lo0/pcap examples kept as info+echo"
  - "extract-files-from-capture uses FILE variable (not TARGET) -- confirm_execute called with empty arg for optional pcap"
  - "Piped commands (sort | uniq -c) kept as info+echo -- run_or_show cannot handle shell pipes"

patterns-established:
  - "tshark interface scripts: run_or_show with sudo tshark -i $TARGET for live capture examples"
  - "Optional-target scripts: confirm_execute with ${1:-} (may be empty)"

# Metrics
duration: 6min
completed: 2026-02-11
---

# Phase 16 Plan 06: Foremost and tshark Use-Case Script Migration Summary

**Migrated 6 foremost/tshark use-case scripts to dual-mode pattern with 15 run_or_show conversions for interface-based capture commands**

## Performance

- **Duration:** 6 min
- **Started:** 2026-02-11T22:13:02Z
- **Completed:** 2026-02-11T22:19:18Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- Migrated 3 foremost scripts (analyze-forensic-image, carve-specific-filetypes, recover-deleted-files) -- all structural-only with 0 run_or_show (30 examples use hardcoded filenames)
- Migrated 3 tshark scripts with 15 total run_or_show conversions: capture-http-credentials (8), analyze-dns-queries (7), extract-files-from-capture (0 -- all hardcoded pcap files)
- All 6 scripts now support --help, -x execute mode, and piped-stdin rejection

## Task Commits

Each task was committed atomically:

1. **Task 1: Migrate foremost scripts** - `7d6adf6` (feat)
2. **Task 2: Migrate tshark scripts** - `95c4c73` (feat)

## Files Created/Modified
- `scripts/foremost/analyze-forensic-image.sh` - Added parse_common_args, confirm_execute, EXECUTE_MODE guard
- `scripts/foremost/carve-specific-filetypes.sh` - Added parse_common_args, confirm_execute, EXECUTE_MODE guard
- `scripts/foremost/recover-deleted-files.sh` - Added parse_common_args, confirm_execute, EXECUTE_MODE guard
- `scripts/tshark/capture-http-credentials.sh` - Added parse_common_args, 8 run_or_show for interface capture commands
- `scripts/tshark/analyze-dns-queries.sh` - Added parse_common_args, 7 run_or_show for interface capture commands
- `scripts/tshark/extract-files-from-capture.sh` - Added parse_common_args, structural-only (all pcap examples)

## Decisions Made
- tshark interface examples using `$TARGET` converted to run_or_show; hardcoded lo0 and capture.pcap examples kept as static info+echo
- extract-files-from-capture uses `FILE` variable (not `TARGET`) -- `confirm_execute` called with `${1:-}` for optional pcap argument
- Piped commands (e.g., `sort | uniq -c | sort -rn`) kept as info+echo since run_or_show cannot handle shell pipes

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- 6 scripts fully migrated, ready for remaining use-case script migration plans
- All foremost and tshark use-case scripts now have consistent dual-mode support

## Self-Check: PASSED

- All 6 modified files exist on disk
- Both task commits verified (7d6adf6, 95c4c73)
- All 6 scripts contain parse_common_args

---
*Phase: 16-use-case-script-migration*
*Completed: 2026-02-11*
