---
phase: 15-examples-script-migration
plan: 02
subsystem: scripts
tags: [bash, dual-mode, curl, traceroute, netcat, foremost, edge-cases]

# Dependency graph
requires:
  - phase: 14-argument-parsing-and-dual-mode-pattern
    provides: parse_common_args, run_or_show, confirm_execute in lib modules
provides:
  - curl/examples.sh with dual-mode flags and 9 run_or_show examples
  - traceroute/examples.sh with dual-mode flags and platform-conditional run_or_show
  - netcat/examples.sh with dual-mode flags and variant-specific info+echo preserved
  - foremost/examples.sh with dual-mode flags and optional target handling
affects: [15-04-PLAN, 16-use-case-script-migration]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Complex format strings (curl timing) kept as info+echo rather than run_or_show"
    - "Platform conditionals (traceroute) can wrap run_or_show calls"
    - "Variant-specific case statements kept as info+echo (show-only patterns)"
    - "Optional target scripts use confirm_execute with empty arg"
    - "All-hardcoded-example scripts (foremost) keep info+echo for all 10 examples"

key-files:
  created: []
  modified:
    - scripts/curl/examples.sh
    - scripts/traceroute/examples.sh
    - scripts/netcat/examples.sh
    - scripts/foremost/examples.sh

key-decisions:
  - "curl example 9 (timing format string with embedded single quotes) kept as info+echo for output fidelity"
  - "traceroute examples 6-10 (mtr commands) kept as info+echo since mtr may not be installed"
  - "netcat examples 3,7,8,9,10 (variant-specific case/if logic) kept as info+echo -- inherently show-only"
  - "foremost all 10 examples kept as info+echo -- hardcoded image.dd, no $TARGET usage"

patterns-established:
  - "Edge-case classification: format strings, missing tools, variant logic, optional target all use info+echo"
  - "Platform conditionals wrap run_or_show (not the other way around)"

# Metrics
duration: 7min
completed: 2026-02-11
---

# Phase 15 Plan 02: Edge-Case Target Scripts Summary

**Migrated curl, traceroute, netcat, foremost to dual-mode with preserved edge cases: platform conditionals, variant case statements, optional targets, complex format strings**

## Performance

- **Duration:** 7 min
- **Started:** 2026-02-11T21:15:54Z
- **Completed:** 2026-02-11T21:22:56Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Migrated 4 scripts with non-trivial edge cases to dual-mode parse_common_args pattern
- Preserved platform-conditional (traceroute example 5) and variant-specific (netcat case statements) logic
- Handled optional target pattern (foremost) correctly with confirm_execute on empty arg
- Correctly classified 20+ examples into run_or_show vs info+echo based on executability

## Task Commits

Each task was committed atomically:

1. **Task 1: Migrate curl and traceroute** - `c9dabf1` (feat)
2. **Task 2: Migrate netcat and foremost** - `07e384a` (feat)

## Files Created/Modified
- `scripts/curl/examples.sh` - 9 examples as run_or_show, example 9 (timing) as info+echo, pipe demo in EXECUTE_MODE guard
- `scripts/traceroute/examples.sh` - Examples 1-4 as run_or_show, example 5 platform-conditional run_or_show, mtr examples 6-10 as info+echo
- `scripts/netcat/examples.sh` - Examples 1,2,4,5,6 as run_or_show, variant-specific 3,7,8,9,10 as info+echo
- `scripts/foremost/examples.sh` - All 10 as info+echo (hardcoded paths), optional target with confirm_execute

## Decisions Made
- curl example 9 has complex format string with `%{time_namelookup}` and embedded single quotes -- kept as info+echo for exact output fidelity
- traceroute mtr examples (6-10) kept as info+echo because mtr may not be installed and would error in -x mode
- netcat variant-specific examples (3,7,8,9,10) are inherently show-only patterns (listeners, multi-step workflows) -- kept as info+echo
- foremost uses all hardcoded `image.dd` filenames with no `$TARGET` -- all 10 examples kept as info+echo since executing would fail

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- 12 of 17 examples.sh scripts now migrated to dual-mode (nmap from Phase 14 + 7 from Plan 01 + 4 from this plan)
- Plan 03 (5 no-target static scripts) already completed
- Plan 04 (test suite extension) ready to verify all 17 scripts

---
*Phase: 15-examples-script-migration*
*Completed: 2026-02-11*
