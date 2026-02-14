---
phase: 27-documentation
plan: 01
subsystem: documentation
tags: [bash, help-text, cli-flags, json, show_help, metadata-headers]

requires:
  - phase: 25-script-migration
    provides: JSON output support in all 46 use-case scripts via -j flag
provides:
  - Updated @usage metadata headers with [-j|--json] in all 46 scripts
  - Updated show_help() with [-j|--json] on Usage line in all 46 scripts
  - Flags/Options section in show_help() documenting -j flag across all 46 scripts
affects: [27-02 documentation tests]

tech-stack:
  added: []
  patterns:
    - "3-flag Flags section (h, j, x) appended to show_help() for standard scripts"
    - "5-flag Flags section (h, j, x, v, q) for curl/dig scripts with verbose/quiet"
    - "-j line inserted into existing Options section for gobuster/traceroute scripts"

key-files:
  created: []
  modified:
    - scripts/*/[use-case].sh (all 46 use-case scripts)

key-decisions:
  - "Insert -j after -h in Options section for Pattern A scripts (alphabetical flag ordering)"
  - "Separate Flags section (not Options) for Pattern B scripts to match plan specification"
  - "5-flag variant for curl/dig scripts that already expose -v/-q on Usage line"

patterns-established:
  - "show_help() Flags section: 3 standard flags (-h, -j, -x) for all use-case scripts"

duration: 7min
completed: 2026-02-14
---

# Phase 27 Plan 01: Documentation -- Help Text and Headers Summary

**All 46 use-case scripts updated with -j/--json in @usage headers, Usage lines, and Flags/Options sections inside show_help()**

## Performance

- **Duration:** 7 min
- **Started:** 2026-02-14T12:06:23Z
- **Completed:** 2026-02-14T12:13:42Z
- **Tasks:** 1
- **Files modified:** 46

## Accomplishments

- Updated @usage metadata header in all 46 scripts to include `[-j|--json]`
- Updated `echo "Usage: ..."` line inside show_help() for all 46 scripts
- Added Flags section with `-j, --json` description to 35 standard scripts
- Added 5-flag Flags section to 6 curl/dig scripts (includes -v/-q documentation)
- Inserted `-j, --json` into existing Options section for 5 gobuster/traceroute scripts
- All 211 existing BATS tests pass (INTG-01, INTG-02, INTG-03, HDR-06)
- All 47 JSON integration tests pass

## Task Commits

Each task was committed atomically:

1. **Task 1: Update @usage headers and show_help() for all 46 use-case scripts** - `761d512` (docs)

## Files Created/Modified

All 46 use-case scripts modified (2 edits each: @usage header + show_help function):

**Pattern A** (existing Options section -- added -j line):
- `scripts/gobuster/discover-directories.sh`
- `scripts/gobuster/enumerate-subdomains.sh`
- `scripts/traceroute/compare-routes.sh`
- `scripts/traceroute/trace-network-path.sh`
- `scripts/traceroute/diagnose-latency.sh`

**Pattern B with -v/-q** (new 5-flag Flags section):
- `scripts/curl/check-ssl-certificate.sh`
- `scripts/curl/debug-http-response.sh`
- `scripts/curl/test-http-endpoints.sh`
- `scripts/dig/attempt-zone-transfer.sh`
- `scripts/dig/check-dns-propagation.sh`
- `scripts/dig/query-dns-records.sh`

**Pattern B standard** (new 3-flag Flags section -- 35 scripts):
- `scripts/aircrack-ng/*.sh` (3), `scripts/ffuf/*.sh` (1), `scripts/foremost/*.sh` (3)
- `scripts/hashcat/*.sh` (3), `scripts/hping3/*.sh` (2), `scripts/john/*.sh` (3)
- `scripts/metasploit/*.sh` (3), `scripts/netcat/*.sh` (3), `scripts/nikto/*.sh` (3)
- `scripts/nmap/*.sh` (3), `scripts/skipfish/*.sh` (2), `scripts/sqlmap/*.sh` (3)
- `scripts/tshark/*.sh` (3)

## Decisions Made

- Inserted `-j` after `-h` (before `-x`) in Pattern A Options sections for consistent alphabetical flag ordering
- Used "Flags:" label (not "Options:") for Pattern B scripts to match plan specification and distinguish from the richer Options sections in Pattern A scripts
- Included `-v, --verbose` and `-q, --quiet` in the Flags section for curl/dig scripts since those flags are already shown on their Usage lines

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Restored execute permissions on 35 scripts**
- **Found during:** Task 1 (after Flags section insertion)
- **Issue:** The awk temp-file approach (`awk ... > file.tmp && mv file.tmp file`) stripped the executable permission from 35 scripts
- **Fix:** Ran `chmod +x` on all affected scripts and amended the commit
- **Files modified:** Same 35 Pattern B standard scripts
- **Verification:** All scripts executable, BATS tests pass
- **Committed in:** 761d512 (included in task commit via amend)

---

**Total deviations:** 1 auto-fixed (Rule 1 - bug fix)
**Impact on plan:** Permission fix was necessary for script execution. No scope creep.

## Issues Encountered

None -- all edits applied cleanly across all 46 scripts.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Help text documentation complete for all 46 scripts
- Ready for 27-02: BATS verification tests for DOC-01 and DOC-02 requirements
- v1.4 milestone nearing completion (documentation is final phase)

## Self-Check: PASSED

- Commit 761d512 exists
- SUMMARY.md file exists
- 46/46 @usage headers contain [-j|--json]
- 46/46 show_help() Usage lines contain [-j|--json]
- 46/46 scripts have -j flag description in Flags/Options section
- All 46 scripts are executable

---
*Phase: 27-documentation*
*Completed: 2026-02-14*
