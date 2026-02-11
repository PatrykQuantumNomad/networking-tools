---
phase: 16-use-case-script-migration
plan: 07
subsystem: scripts
tags: [bash, dual-mode, parse_common_args, confirm_execute, run_or_show, metasploit, hashcat, john, aircrack-ng]

# Dependency graph
requires:
  - phase: 14-argument-parsing-and-dual-mode-pattern
    provides: "args.sh parse_common_args, output.sh confirm_execute/run_or_show"
  - phase: 15-examples-script-migration
    provides: "examples.sh migration patterns for all 10 tools"
provides:
  - "12 use-case scripts with dual-mode flag support (-h/-v/-q/-x)"
  - "9 run_or_show conversions in hashcat/benchmark-gpu.sh"
  - "11 structural-only scripts with EXECUTE_MODE interactive demo guards"
affects: [16-08, 17-shellcheck-hardening]

# Tech tracking
tech-stack:
  added: []
  patterns: ["no-target/static use-case script migration: parse_common_args + confirm_execute (no arg) + EXECUTE_MODE guard"]

key-files:
  modified:
    - scripts/metasploit/generate-reverse-shell.sh
    - scripts/metasploit/scan-network-services.sh
    - scripts/metasploit/setup-listener.sh
    - scripts/hashcat/crack-ntlm-hashes.sh
    - scripts/hashcat/benchmark-gpu.sh
    - scripts/hashcat/crack-web-hashes.sh
    - scripts/john/crack-linux-passwords.sh
    - scripts/john/crack-archive-passwords.sh
    - scripts/john/identify-hash-type.sh
    - scripts/aircrack-ng/capture-handshake.sh
    - scripts/aircrack-ng/crack-wpa-handshake.sh
    - scripts/aircrack-ng/analyze-wireless-networks.sh

key-decisions:
  - "benchmark-gpu.sh: 9 run_or_show conversions (examples 1-9), example 10 kept as info+echo (hardcoded file paths)"
  - "identify-hash-type.sh: safety_banner extra arg removed (was passing install hint as parameter)"
  - "Metasploit multi-positional (LHOST, LPORT): confirm_execute called without argument"
  - "All hashcat/john/aircrack-ng scripts: confirm_execute called without argument (no-target or optional-target pattern)"

patterns-established:
  - "Multi-positional arg scripts (LHOST, LPORT): parse_common_args first, then read $1/$2 from REMAINING_ARGS"
  - "Optional-target scripts (hashfile, archive, capfile): confirm_execute with no arg, not with empty positional"

# Metrics
duration: 8min
completed: 2026-02-11
---

# Phase 16 Plan 07: Metasploit/Hashcat/John/Aircrack-ng Use-Case Migration Summary

**Migrated 12 use-case scripts (metasploit 3, hashcat 3, john 3, aircrack-ng 3) with 9 run_or_show conversions in benchmark-gpu.sh and 11 structural-only scripts**

## Performance

- **Duration:** 8 min
- **Started:** 2026-02-11T22:13:54Z
- **Completed:** 2026-02-11T22:22:24Z
- **Tasks:** 2
- **Files modified:** 12

## Accomplishments
- Migrated all 12 scripts to parse_common_args + REMAINING_ARGS pattern
- Converted 9 hashcat benchmark examples to run_or_show for -x execution mode
- Cleaned up safety_banner extra argument in john/identify-hash-type.sh
- All 12 scripts now support -h/--help, -v/--verbose, -q/--quiet, -x/--execute flags

## Task Commits

Each task was committed atomically:

1. **Task 1: Migrate metasploit (3) and hashcat (3) scripts** - `b00fa2d` (feat)
2. **Task 2: Migrate john (3) and aircrack-ng (3) scripts** - `ec85c42` (feat)

## Files Created/Modified
- `scripts/metasploit/generate-reverse-shell.sh` - Multi-positional LHOST/LPORT, structural-only
- `scripts/metasploit/scan-network-services.sh` - Optional target, structural-only
- `scripts/metasploit/setup-listener.sh` - Multi-positional LHOST/LPORT, structural-only
- `scripts/hashcat/crack-ntlm-hashes.sh` - Optional hashfile, structural-only
- `scripts/hashcat/benchmark-gpu.sh` - No target, 9 run_or_show conversions
- `scripts/hashcat/crack-web-hashes.sh` - Optional hashfile, structural-only
- `scripts/john/crack-linux-passwords.sh` - No target, structural-only
- `scripts/john/crack-archive-passwords.sh` - Optional archive, structural-only
- `scripts/john/identify-hash-type.sh` - Optional hash, structural-only + safety_banner cleanup
- `scripts/aircrack-ng/capture-handshake.sh` - Optional interface, structural-only
- `scripts/aircrack-ng/crack-wpa-handshake.sh` - Optional capfile, structural-only
- `scripts/aircrack-ng/analyze-wireless-networks.sh` - Optional interface, structural-only

## Decisions Made
- benchmark-gpu.sh examples 1-9 are all simple `hashcat -b` commands with no file dependencies -- ideal for run_or_show conversion
- Example 10 (time-limited cracking with hardcoded hashes.txt/wordlist.txt) kept as info+echo -- consistent with Phase 15 policy
- identify-hash-type.sh had `safety_banner "brew install john"` passing install hint as argument to safety_banner which takes no parameters -- cleaned up to just `safety_banner`
- Metasploit scripts with multi-positional args (LHOST, LPORT) use confirm_execute without argument since there is no single "target"

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Cleaned up safety_banner extra argument in identify-hash-type.sh**
- **Found during:** Task 2
- **Issue:** `safety_banner "brew install john"` was passing an install hint as argument, but safety_banner() takes no parameters -- the argument was silently ignored
- **Fix:** Changed to `safety_banner` (no argument)
- **Files modified:** scripts/john/identify-hash-type.sh
- **Verification:** Script runs without warnings, safety_banner displays correctly
- **Committed in:** ec85c42 (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 bug - planned cleanup noted in task spec)
**Impact on plan:** Cleanup was explicitly called out in plan. No scope creep.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- All 12 scripts in this batch are migrated
- Plan 08 (test coverage) can verify all 28 use-case scripts together
- Ready for Phase 17 ShellCheck hardening

## Self-Check: PASSED

All 12 modified files verified present. Both task commits (b00fa2d, ec85c42) verified in git log. SUMMARY.md exists.

---
*Phase: 16-use-case-script-migration*
*Completed: 2026-02-11*
