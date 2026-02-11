---
phase: 16-use-case-script-migration
plan: 03
subsystem: scripts
tags: [nikto, skipfish, ffuf, dual-mode, run_or_show, parse_common_args]

# Dependency graph
requires:
  - phase: 14-argument-parsing-and-dual-mode-pattern
    provides: parse_common_args, run_or_show, confirm_execute library functions
provides:
  - 6 web scanning use-case scripts migrated to dual-mode pattern
  - nikto scan-specific-vulnerabilities, scan-multiple-hosts, scan-with-auth
  - skipfish scan-authenticated-app, quick-scan-web-app
  - ffuf fuzz-parameters
affects: [16-08-verification, 17-shellcheck]

# Tech tracking
tech-stack:
  added: []
  patterns: [dual-mode use-case scripts with run_or_show]

key-files:
  modified:
    - scripts/nikto/scan-specific-vulnerabilities.sh
    - scripts/nikto/scan-multiple-hosts.sh
    - scripts/nikto/scan-with-auth.sh
    - scripts/skipfish/scan-authenticated-app.sh
    - scripts/skipfish/quick-scan-web-app.sh
    - scripts/ffuf/fuzz-parameters.sh

key-decisions:
  - "scan-multiple-hosts: 0 convertible examples (all hardcoded filenames/hosts), structural-only migration"
  - "scan-with-auth: 6 of 10 converted, 4 kept as info+echo (hardcoded localhost or credentials)"
  - "scan-authenticated-app example 10: kept as info+echo (hardcoded localhost)"
  - "quick-scan-web-app example 10: kept as info+echo (for loop construct)"
  - "ffuf fuzz-parameters: all 10 converted, FUZZ keyword is ffuf marker not placeholder"

patterns-established:
  - "Static examples with hardcoded hosts/credentials kept as info+echo even when $TARGET present"
  - "For-loop and multi-command examples kept as info+echo"

# Metrics
duration: 7min
completed: 2026-02-11
---

# Phase 16 Plan 03: Web Scanning Script Migration Summary

**Migrated 6 web scanning use-case scripts (nikto/skipfish/ffuf) to dual-mode with parse_common_args and run_or_show**

## Performance

- **Duration:** 7 min
- **Started:** 2026-02-11T22:12:01Z
- **Completed:** 2026-02-11T22:19:46Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- Migrated 3 nikto scripts: scan-specific-vulnerabilities (10/10 converted), scan-multiple-hosts (structural-only), scan-with-auth (6/10 converted)
- Migrated 2 skipfish scripts: scan-authenticated-app (9/10 converted), quick-scan-web-app (9/10 converted)
- Migrated 1 ffuf script: fuzz-parameters (10/10 converted with wordlist check preserved)
- All 6 scripts pass --help exit 0, piped stdin rejection, and parse_common_args artifact checks

## Task Commits

Each task was committed atomically:

1. **Task 1: Migrate nikto scripts** - `0d15e87` (feat)
2. **Task 2: Migrate skipfish + ffuf scripts** - `0133585` (feat)

**Plan metadata:** (pending final commit)

## Files Created/Modified
- `scripts/nikto/scan-specific-vulnerabilities.sh` - All 10 examples converted to run_or_show
- `scripts/nikto/scan-multiple-hosts.sh` - Structural migration only (0 convertible examples)
- `scripts/nikto/scan-with-auth.sh` - 6 examples converted, 4 kept static (hardcoded localhost/credentials)
- `scripts/skipfish/scan-authenticated-app.sh` - 9 examples converted, 1 kept static (hardcoded localhost)
- `scripts/skipfish/quick-scan-web-app.sh` - 9 examples converted, 1 kept static (for loop)
- `scripts/ffuf/fuzz-parameters.sh` - All 10 examples converted, wordlist existence check preserved

## Decisions Made
- scan-multiple-hosts has 0 convertible examples (all use hardcoded filenames like hosts.txt, nmap_output.xml, or hardcoded localhost) -- structural-only migration with parse_common_args, confirm_execute, and EXECUTE_MODE guard
- scan-with-auth examples 4 (hardcoded localhost), 5 (hardcoded cookie values), 6 (hardcoded credentials in Tuning combo), 8 (hardcoded output filename with credentials) kept as info+echo
- ffuf FUZZ keyword is an ffuf-specific marker (not a placeholder), so all 10 examples are convertible
- Wordlist existence check in ffuf/fuzz-parameters.sh placed after parse_common_args but before confirm_execute, so --help works without a wordlist but running examples requires one

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- 6 web scanning scripts now support -h/--help, -x/--execute, -v/--verbose flags
- Ready for remaining use-case script migrations (plans 04-07)
- Ready for verification pass (plan 08)

## Self-Check: PASSED

All 6 modified files exist on disk. Both task commits (0d15e87, 0133585) found in git log. SUMMARY.md exists.

---
*Phase: 16-use-case-script-migration*
*Completed: 2026-02-11*
