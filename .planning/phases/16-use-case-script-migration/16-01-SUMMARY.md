---
phase: 16-use-case-script-migration
plan: 01
subsystem: scripts
tags: [bash, dual-mode, run_or_show, parse_common_args, migration, nmap, hping3]

# Dependency graph
requires:
  - phase: 14-argument-parsing-and-dual-mode-pattern
    provides: "args.sh (parse_common_args), output.sh (run_or_show, confirm_execute)"
  - phase: 15-examples-script-migration
    provides: "Proven migration pattern across all 17 examples.sh scripts"
provides:
  - "5 nmap/hping3 use-case scripts migrated to dual-mode (discover-live-hosts, scan-web-vulnerabilities, identify-ports, test-firewall-rules, detect-firewall)"
  - "42 run_or_show examples across 5 scripts"
affects: [16-08-PLAN, 17-shellcheck-hardening]

# Tech tracking
tech-stack:
  added: []
  patterns: [dual-mode-migration-for-use-case-scripts, no-safety-banner-for-local-introspection-scripts]

key-files:
  created: []
  modified:
    - scripts/nmap/discover-live-hosts.sh
    - scripts/nmap/scan-web-vulnerabilities.sh
    - scripts/nmap/identify-ports.sh
    - scripts/hping3/test-firewall-rules.sh
    - scripts/hping3/detect-firewall.sh

key-decisions:
  - "identify-ports.sh: examples 1-5 kept as info+echo (local lsof/netstat, no $TARGET)"
  - "identify-ports.sh: example 10 kept as info+echo (multi-command pipeline)"
  - "identify-ports.sh: no safety_banner added (local introspection, not active scanning)"
  - "test-firewall-rules.sh: example 10 kept as info+echo (two commands chained with &&)"
  - "detect-firewall.sh: example 10 kept as info+echo (three commands chained with ;)"

patterns-established:
  - "Use-case scripts follow identical migration pattern as examples.sh"
  - "Multi-command examples (&&, ;, |) kept as info+echo -- run_or_show only for single commands"

# Metrics
duration: 5min
completed: 2026-02-11
---

# Phase 16 Plan 01: nmap + hping3 Use-Case Script Migration Summary

**5 nmap and hping3 use-case scripts migrated to dual-mode with 42 run_or_show examples, preserving local-only and multi-command examples as info+echo**

## Performance

- **Duration:** 5 min
- **Started:** 2026-02-11T22:11:14Z
- **Completed:** 2026-02-11T22:16:51Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- Migrated 5 target-required use-case scripts to the dual-mode pattern
- All scripts accept -h/--help, -v/--verbose, -q/--quiet, -x/--execute flags via parse_common_args
- 42 examples converted to run_or_show across all 5 scripts (10+10+4+9+9)
- 8 examples preserved as info+echo (local commands, placeholders, multi-command chains)
- Interactive demos wrapped in EXECUTE_MODE guard for all scripts
- identify-ports.sh correctly omits safety_banner (local introspection script)

## Task Commits

Each task was committed atomically:

1. **Task 1: Migrate nmap/discover-live-hosts, scan-web-vulnerabilities, identify-ports** - `20e1414` (feat)
2. **Task 2: Migrate hping3/test-firewall-rules, detect-firewall** - `7d6adf6` (feat)

## Files Created/Modified
- `scripts/nmap/discover-live-hosts.sh` - Dual-mode with 10 run_or_show examples (all use $TARGET/24)
- `scripts/nmap/scan-web-vulnerabilities.sh` - Dual-mode with 10 run_or_show examples (all use $TARGET)
- `scripts/nmap/identify-ports.sh` - Dual-mode with 4 run_or_show examples (examples 1-5 local lsof, example 10 pipeline)
- `scripts/hping3/test-firewall-rules.sh` - Dual-mode with 9 run_or_show examples (example 10 has && chain)
- `scripts/hping3/detect-firewall.sh` - Dual-mode with 9 run_or_show examples (example 10 has ; chain)

## Decisions Made
- identify-ports.sh examples 1-5 kept as info+echo: local lsof/netstat commands without $TARGET, plus example 4 has `<process-name>` placeholder
- identify-ports.sh example 10 kept as info+echo: multi-command pipeline with `|` and two commands
- identify-ports.sh preserves no-safety_banner design: script does local port introspection, not active network scanning
- test-firewall-rules.sh example 10 kept as info+echo: two `sudo hping3` commands chained with `&&`
- detect-firewall.sh example 10 kept as info+echo: three `sudo hping3` commands chained with `;`

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- 5 of 46 use-case scripts now migrated
- Migration pattern confirmed to work identically for use-case scripts as for examples.sh
- Remaining plans (16-02 through 16-07) cover remaining 41 scripts
- Plan 16-08 extends test suite to cover all 46 scripts

## Self-Check: PASSED

All 5 script files verified present. Both task commits (20e1414, 7d6adf6) verified in git log. 30/30 verification checks passed (5 scripts x 6 checks: --help, -h, parse_common_args, confirm_execute, EXECUTE_MODE, -x rejection).

---
*Phase: 16-use-case-script-migration*
*Completed: 2026-02-11*
