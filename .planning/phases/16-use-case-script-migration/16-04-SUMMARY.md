---
phase: 16-use-case-script-migration
plan: 04
subsystem: scripts
tags: [gobuster, traceroute, mtr, dual-mode, platform-conditional, multi-positional-args]

# Dependency graph
requires:
  - phase: 14-argument-parsing-and-dual-mode-pattern
    provides: parse_common_args, run_or_show, confirm_execute infrastructure
  - phase: 15-examples-script-migration
    provides: platform conditional wrapping pattern (15-02)
provides:
  - 5 gobuster and traceroute use-case scripts with dual-mode -x support
  - Multi-positional arg handling pattern ($1 TARGET, $2 WORDLIST)
  - HAS_MTR conditional wrapping run_or_show pattern
affects: [16-08-testing]

# Tech tracking
tech-stack:
  added: []
  patterns: [multi-positional-arg-dual-mode, platform-conditional-run_or_show, optional-tool-conditional-run_or_show]

key-files:
  created: []
  modified:
    - scripts/gobuster/discover-directories.sh
    - scripts/gobuster/enumerate-subdomains.sh
    - scripts/traceroute/trace-network-path.sh
    - scripts/traceroute/diagnose-latency.sh
    - scripts/traceroute/compare-routes.sh

key-decisions:
  - "Example 8 (PROJECT_ROOT literal) and 10 (file output) in gobuster scripts kept as info+echo"
  - "diagnose-latency.sh converts 9 of 10 examples since require_cmd mtr ensures mtr is installed"
  - "compare-routes.sh HAS_MTR conditional wraps run_or_show (mtr branch) with info+echo fallback"
  - "Example 10 in trace-network-path.sh kept as info+echo due to multi-line annotation with platform conditional"

patterns-established:
  - "Multi-positional args: parse_common_args + set -- restores $1 and $2 for TARGET and WORDLIST"
  - "HAS_MTR conditional: run_or_show in true branch, info+echo in false branch with install hint"

# Metrics
duration: 8min
completed: 2026-02-11
---

# Phase 16 Plan 04: Gobuster + Traceroute Use-Case Script Migration Summary

**5 scripts migrated to dual-mode with multi-positional args (gobuster WORDLIST), platform conditionals (traceroute Darwin/Linux), and HAS_MTR optional-tool gating**

## Performance

- **Duration:** 8 min
- **Started:** 2026-02-11T22:12:25Z
- **Completed:** 2026-02-11T22:20:28Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- Migrated 2 gobuster scripts with multi-positional arg support ($1 TARGET, $2 WORDLIST) preserved through parse_common_args
- Migrated 3 traceroute scripts with platform conditionals wrapping run_or_show per 15-02 pattern
- 39 of 50 examples converted to run_or_show across all 5 scripts (8 + 7 + 9 + 9 + 6 = 39)
- Preserved all edge cases: wordlist existence checks, macOS mtr sudo detection, HAS_MTR optional tool gating

## Task Commits

Each task was committed atomically:

1. **Task 1: Migrate gobuster scripts** - `530a670` (feat)
2. **Task 2: Migrate traceroute scripts** - `e40b80a` (feat)

## Files Created/Modified
- `scripts/gobuster/discover-directories.sh` - 8 run_or_show, multi-positional args (TARGET + WORDLIST)
- `scripts/gobuster/enumerate-subdomains.sh` - 7 run_or_show, multi-positional args (TARGET + WORDLIST)
- `scripts/traceroute/trace-network-path.sh` - 9 run_or_show (2 with platform conditionals), 1 info+echo
- `scripts/traceroute/diagnose-latency.sh` - 9 run_or_show, macOS sudo check preserved
- `scripts/traceroute/compare-routes.sh` - 6 run_or_show (2 platform, 2 HAS_MTR), 4 info+echo (multi-command)

## Decisions Made
- Gobuster example 8 (PROJECT_ROOT literal path) kept as info+echo since the variable is not interpolated at runtime
- Gobuster examples writing to file (-o flag) kept as info+echo to avoid side-effect files in execute mode
- diagnose-latency.sh: all 9 single-command examples converted since require_cmd ensures mtr is available
- compare-routes.sh: HAS_MTR wraps run_or_show for mtr examples, with info+echo fallback showing install hint
- trace-network-path.sh example 10 (AS number lookups) kept as info+echo due to multi-line annotation per platform

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- 5 more use-case scripts migrated, continuing Phase 16 wave 1
- Platform conditional and multi-positional arg patterns working correctly
- Remaining Phase 16 plans can proceed in parallel

## Self-Check: PASSED

All 5 modified files exist. Both task commits verified (530a670, e40b80a).

---
*Phase: 16-use-case-script-migration*
*Completed: 2026-02-11*
