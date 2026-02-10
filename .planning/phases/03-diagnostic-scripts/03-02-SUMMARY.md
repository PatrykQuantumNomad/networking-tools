---
phase: 03-diagnostic-scripts
plan: 02
subsystem: diagnostics
tags: [connectivity, ping, curl, nc, tls, diagnostic-report, pattern-b, cross-platform]

requires:
  - phase: 01-foundations
    provides: "common.sh report_pass/fail/warn/skip, report_section, run_check, check_cmd functions"
  - phase: 03-diagnostic-scripts
    plan: 01
    provides: "Pattern B template (dns.sh) -- counter wrappers, section flow, header format"
provides:
  - "Connectivity diagnostic auto-report script (scripts/diagnostics/connectivity.sh)"
  - "diagnose-connectivity Makefile target"
  - "Network Diagnostics section in USECASES.md"
affects: [04-documentation-site, 05-advanced-scripts]

tech-stack:
  added: []
  patterns:
    - "Cross-platform helpers: OS_TYPE detection for ping flags, ifconfig/ip fallbacks, route command variants"
    - "Protocol stripping: strip_protocol() for handling URL inputs in non-HTTP commands"
    - "TLS cert expiry checking via curl verbose output with date arithmetic fallbacks"

key-files:
  created:
    - scripts/diagnostics/connectivity.sh
  modified:
    - Makefile
    - USECASES.md

key-decisions:
  - "macOS-first for get_local_ip: use ifconfig on Darwin (ip exists via iproute2mac but behaves differently), ip on Linux"
  - "WARN not FAIL for blocked ICMP: many production hosts block ping, so unreachable ICMP is a warning not a failure"
  - "curl fallback for TCP port checks when nc unavailable"
  - "TLS cert expiry: parse curl verbose output expire date, with openssl date arithmetic where available"

patterns-established:
  - "Cross-platform network helpers: OS_TYPE=$(uname -s) with Darwin/Linux branching for ping, ip/ifconfig, route"
  - "Protocol stripping pattern: strip_protocol() for accepting both raw domains and URLs as input"

duration: 4min
completed: 2026-02-10
---

# Phase 3 Plan 2: Connectivity Diagnostic Script Summary

**Layered connectivity diagnostic (DNS->ICMP->TCP->HTTP->TLS->Timing) with cross-platform helpers for macOS/Linux and [PASS]/[FAIL]/[WARN] structured output**

## Performance

- **Duration:** 4 min
- **Started:** 2026-02-10T20:09:23Z
- **Completed:** 2026-02-10T20:13:30Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Connectivity diagnostic script (343 lines) walking 7 network layers with structured pass/fail/warn output
- Cross-platform helpers: portable ping (macOS -t vs Linux -w), ifconfig/ip detection, route command variants
- Protocol stripping so users can pass `https://domain.com` or `domain.com` interchangeably
- TLS certificate expiry checking with date arithmetic
- Connection timing breakdown (DNS, TCP connect, TLS handshake, first byte, total)
- Makefile target and USECASES.md entries for both diagnostic scripts

## Task Commits

Each task was committed atomically:

1. **Task 1: Create connectivity diagnostic script** - `e1ef885` (feat)
2. **Task 2: Add Makefile target and USECASES.md entries** - `1fb2ef4` (feat)

## Files Created/Modified
- `scripts/diagnostics/connectivity.sh` - 7-section layered connectivity diagnostic with cross-platform helpers
- `Makefile` - Added diagnose-connectivity target in diagnostic section
- `USECASES.md` - Added "Network Diagnostics" section with DNS and connectivity entries, diagnostics step in engagement flow

## Decisions Made
- macOS-first for get_local_ip: ifconfig on Darwin since `ip` from iproute2mac behaves differently than Linux `ip`
- WARN (not FAIL) for ICMP unreachable -- many hosts block ping; it indicates possible filtering, not broken connectivity
- curl fallback when `nc` unavailable for TCP port checks (nc not guaranteed on all systems)
- TLS cert expiry parsed from curl verbose output; date arithmetic uses macOS `date -j` or GNU `date -d` with graceful fallback

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed pipefail crash in get_local_ip and get_default_gateway**
- **Found during:** Task 1 (initial test run)
- **Issue:** `ip -4 addr show scope global` returns empty/error on macOS (iproute2mac) causing pipefail to exit the script. `set -euo pipefail` from common.sh propagates pipeline failures.
- **Fix:** Added `|| true` guards on all pipeline commands in helper functions. Changed get_local_ip to use ifconfig first on Darwin (OS_TYPE check) instead of checking for `ip` command existence.
- **Files modified:** scripts/diagnostics/connectivity.sh
- **Verification:** Script completes successfully on macOS, all sections render
- **Committed in:** e1ef885 (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Essential fix for macOS compatibility. No scope creep.

## Issues Encountered
None beyond the auto-fixed deviation above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Phase 3 (Diagnostic Scripts) is now complete: both dns.sh and connectivity.sh are operational
- Pattern B is established and proven across two scripts with cross-platform concerns handled
- Ready for Phase 4 (Documentation Site) or Phase 5 (Advanced Scripts)

## Self-Check: PASSED

- FOUND: scripts/diagnostics/connectivity.sh (343 lines, executable)
- FOUND: commit e1ef885 (Task 1)
- FOUND: commit 1fb2ef4 (Task 2)
- FOUND: 03-02-SUMMARY.md

---
*Phase: 03-diagnostic-scripts*
*Completed: 2026-02-10*
