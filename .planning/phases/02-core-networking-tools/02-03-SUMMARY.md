---
phase: 02-core-networking-tools
plan: 03
subsystem: tools
tags: [netcat, nc, ncat, openbsd, tcp, udp, port-scanning, listeners, file-transfer, variant-detection, bash]

# Dependency graph
requires:
  - phase: 01-foundations-and-site-scaffold
    provides: common.sh shared functions, check-tools.sh framework, Makefile structure
  - phase: 02-core-networking-tools/01
    provides: dig scripts established networking tool pattern
  - phase: 02-core-networking-tools/02
    provides: curl scripts, check-tools.sh has dig and curl entries
provides:
  - detect_nc_variant() function in common.sh for identifying ncat/gnu/traditional/openbsd variants
  - netcat examples.sh with 10 variant-aware educational examples (Pattern A)
  - scan-ports.sh use-case for TCP/UDP port scanning with nc -z
  - setup-listener.sh use-case for setting up netcat listeners
  - transfer-files.sh use-case for file transfer over TCP
  - nc detection in check-tools.sh (14th tool) with nc -h version display
  - Makefile targets: netcat, scan-ports, nc-listener, nc-transfer
affects: [02-core-networking-tools, site-content]

# Tech tracking
tech-stack:
  added: [netcat/nc]
  patterns: [variant detection via nc -h output parsing, variant-conditional example labeling, helper function for listener command syntax]

key-files:
  created:
    - scripts/netcat/examples.sh
    - scripts/netcat/scan-ports.sh
    - scripts/netcat/setup-listener.sh
    - scripts/netcat/transfer-files.sh
  modified:
    - scripts/common.sh
    - scripts/check-tools.sh
    - Makefile

key-decisions:
  - "detect_nc_variant() uses exclusion-based detection: ncat first, GNU, traditional, then OpenBSD by default (Apple fork does not self-identify)"
  - "nc -h exits non-zero on macOS/OpenBSD -- added || true guard in get_version() case"
  - "Used nc-listener and nc-transfer Makefile target names to avoid collision with metasploit setup-listener"
  - "Interactive demos use nc -zv port scan (bounded, safe) -- never blocking listeners (PITFALL-6)"

patterns-established:
  - "Variant detection: detect_nc_variant() in common.sh returns string, scripts use case statements for variant-specific flags"
  - "Variant labeling: info lines include [variant: ${NC_VARIANT}] for variant-specific examples"
  - "Helper function pattern: _listener_cmd() in transfer-files.sh for DRY variant-aware listener syntax"

# Metrics
duration: 4min
completed: 2026-02-10
---

# Phase 2 Plan 3: Netcat Tool Scripts Summary

**Variant-aware netcat (nc) scripts with detect_nc_variant() in common.sh, examples.sh (10 examples), and three use-case scripts for port scanning, listener setup, and file transfer**

## Performance

- **Duration:** 4 min
- **Started:** 2026-02-10T18:49:03Z
- **Completed:** 2026-02-10T18:54:00Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments
- Added detect_nc_variant() to common.sh that identifies ncat/gnu/traditional/openbsd variants via nc -h output parsing
- Created examples.sh with 10 variant-aware netcat examples, including 3 with variant-conditional logic (keep-alive, execute, file transfer)
- Created three use-case scripts: scan-ports.sh (port scanning with nc -z), setup-listener.sh (listener setup), transfer-files.sh (file transfer techniques)
- Integrated nc into check-tools.sh (14th tool) and Makefile (4 new targets: netcat, scan-ports, nc-listener, nc-transfer)

## Task Commits

Each task was committed atomically:

1. **Task 1: Add detect_nc_variant() and netcat scripts** - `aff3529` (feat)
2. **Task 2: Integrate nc into check-tools and Makefile** - `9f1d89d` (feat)

## Files Created/Modified
- `scripts/common.sh` - Added detect_nc_variant() function before Diagnostic Report Functions section
- `scripts/netcat/examples.sh` - 10 variant-aware netcat examples (Pattern A with require_target)
- `scripts/netcat/scan-ports.sh` - Port scanning use-case with nc -z, educational context, 10 examples
- `scripts/netcat/setup-listener.sh` - Listener setup use-case with variant-specific flags, 10 examples
- `scripts/netcat/transfer-files.sh` - File transfer use-case with _listener_cmd() helper, 10 examples
- `scripts/check-tools.sh` - Added nc to TOOLS array, TOOL_ORDER, and get_version() with || true guard
- `Makefile` - Added .PHONY entries and 4 new targets (netcat, scan-ports, nc-listener, nc-transfer)

## Decisions Made
- detect_nc_variant() uses exclusion-based detection: checks for ncat first (most specific), then GNU, then traditional ("connect to somewhere" banner), then defaults to OpenBSD (Apple fork does not self-identify)
- nc -h exits with non-zero status on macOS/OpenBSD variant, so added `|| true` guard in get_version() nc case to prevent set -e from aborting check-tools.sh
- Used `nc-listener` and `nc-transfer` as Makefile target names to avoid collision with the existing metasploit `setup-listener` target
- All interactive demos use `nc -zv` port scans with `-w` timeout (bounded, completes quickly) -- never blocking listeners per PITFALL-6

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed nc -h non-zero exit in get_version()**
- **Found during:** Task 2 (check-tools.sh integration)
- **Issue:** `nc -h` exits with status 1 on macOS/OpenBSD variant, causing check-tools.sh to abort under set -euo pipefail before displaying nc
- **Fix:** Added `|| true` to the `nc -h 2>&1 | head -1` command in get_version()
- **Files modified:** scripts/check-tools.sh
- **Verification:** `bash scripts/check-tools.sh` now shows nc and reports 14/14 tools
- **Committed in:** 9f1d89d (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 bug fix)
**Impact on plan:** Essential fix for nc detection to work on macOS. No scope creep.

## Issues Encountered

None beyond the nc -h exit code issue documented above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Phase 2 (Core Networking Tools) complete: dig, curl, and netcat all implemented
- detect_nc_variant() available in common.sh for any future scripts that interact with netcat variants
- check-tools.sh now tracks 14 tools total
- All patterns established and consistent across dig/curl/netcat

## Self-Check: PASSED

All 4 created files verified present. Both task commits (aff3529, 9f1d89d) verified in git log.

---
*Phase: 02-core-networking-tools*
*Completed: 2026-02-10*
