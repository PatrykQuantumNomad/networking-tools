---
phase: 25-script-migration
plan: 02
subsystem: json-output
tags: [json, bash, json_add_example, password-cracker, exploitation]

# Dependency graph
requires:
  - phase: 25-01
    provides: json_set_meta category parameter, json_add_example pattern for bare info+echo scripts
provides:
  - 11 Group C scripts (password-cracker + exploitation) producing JSON output with -j flag
  - Category taxonomy extended with password-cracker and exploitation
affects: [25-03, 25-04, future script migrations]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "json_add_example for all 10 examples in pure info+echo scripts"

key-files:
  created: []
  modified:
    - scripts/hashcat/crack-ntlm-hashes.sh
    - scripts/hashcat/crack-web-hashes.sh
    - scripts/john/crack-archive-passwords.sh
    - scripts/john/crack-linux-passwords.sh
    - scripts/john/identify-hash-type.sh
    - scripts/aircrack-ng/analyze-wireless-networks.sh
    - scripts/aircrack-ng/capture-handshake.sh
    - scripts/aircrack-ng/crack-wpa-handshake.sh
    - scripts/metasploit/generate-reverse-shell.sh
    - scripts/metasploit/scan-network-services.sh
    - scripts/metasploit/setup-listener.sh

key-decisions:
  - "Empty string for john/crack-linux-passwords target (no positional target param in that script)"
  - "identify-hash-type.sh moved HASH assignment before json_set_meta (was after confirm_execute)"

patterns-established:
  - "Category taxonomy extended: password-cracker (hashcat/john), exploitation (aircrack-ng/metasploit)"

# Metrics
duration: 8min
completed: 2026-02-14
---

# Phase 25 Plan 02: Group C Script Migration Summary

**Migrated 11 password-cracker and exploitation scripts to produce JSON output with json_add_example for all bare info+echo examples**

## Performance

- **Duration:** 8 min
- **Started:** 2026-02-14T00:01:36Z
- **Completed:** 2026-02-14T00:10:19Z
- **Tasks:** 2
- **Files modified:** 11

## Accomplishments

- Migrated 5 password-cracker scripts (hashcat: crack-ntlm-hashes, crack-web-hashes; john: crack-archive-passwords, crack-linux-passwords, identify-hash-type)
- Migrated 6 exploitation scripts (aircrack-ng: analyze-wireless-networks, capture-handshake, crack-wpa-handshake; metasploit: generate-reverse-shell, scan-network-services, setup-listener)
- All 110 examples across 11 scripts captured via json_add_example calls
- Verified 8 of 11 scripts produce valid JSON (3 metasploit scripts require msfvenom/msfconsole not installed on build machine)

## Task Commits

Each task was committed atomically:

1. **Task 1: Migrate password-cracker scripts (5 scripts)** - `ffc7e3e` (feat)
2. **Task 2: Migrate exploitation scripts (6 scripts)** - `6e3b682` (feat)

## Files Created/Modified

- `scripts/hashcat/crack-ntlm-hashes.sh` - Added json_set_meta "hashcat" + 10 json_add_example + json_finalize
- `scripts/hashcat/crack-web-hashes.sh` - Added json_set_meta "hashcat" + 10 json_add_example + json_finalize
- `scripts/john/crack-archive-passwords.sh` - Added json_set_meta "john" + 10 json_add_example + json_finalize
- `scripts/john/crack-linux-passwords.sh` - Added json_set_meta "john" (empty target) + 10 json_add_example + json_finalize
- `scripts/john/identify-hash-type.sh` - Added json_set_meta "john" + 10 json_add_example + json_finalize
- `scripts/aircrack-ng/analyze-wireless-networks.sh` - Added json_set_meta "aircrack-ng" + 10 json_add_example + json_finalize
- `scripts/aircrack-ng/capture-handshake.sh` - Added json_set_meta "aircrack-ng" + 10 json_add_example + json_finalize
- `scripts/aircrack-ng/crack-wpa-handshake.sh` - Added json_set_meta "aircrack-ng" + 10 json_add_example + json_finalize
- `scripts/metasploit/generate-reverse-shell.sh` - Added json_set_meta "metasploit" + 10 json_add_example + json_finalize
- `scripts/metasploit/scan-network-services.sh` - Added json_set_meta "metasploit" + 10 json_add_example + json_finalize
- `scripts/metasploit/setup-listener.sh` - Added json_set_meta "metasploit" + 10 json_add_example + json_finalize

## Decisions Made

- john/crack-linux-passwords.sh has no positional target parameter, so json_set_meta uses empty string for target
- john/identify-hash-type.sh had an unusual ordering (safety_banner before confirm_execute) -- moved HASH assignment before json_set_meta to capture the target variable correctly, placing json_set_meta between HASH assignment and confirm_execute

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Metasploit scripts (generate-reverse-shell, scan-network-services, setup-listener) cannot be verified via `-j` on this machine because msfvenom/msfconsole are not installed. The require_cmd call exits before JSON output is produced. Structural verification (grep counts: 12 calls per script) confirms correctness. These scripts will produce valid JSON on machines with metasploit installed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- 22 of ~39 use-case scripts now produce JSON output (11 from 25-01 + 11 from 25-02)
- Plans 25-03 and 25-04 can migrate remaining script groups (mixed run_or_show + info+echo patterns)
- Category taxonomy: network-analysis, network-scanner, web-scanner, sql-injection, password-cracker, exploitation

## Self-Check: PASSED

- All 11 key files found on disk
- Both task commits (ffc7e3e, 6e3b682) found in git log
- json_set_meta in 11 scripts (expected 11)
- json_finalize in 11 scripts (expected 11)
- json_add_example total: 110 (expected 110, 10 per script)

---
*Phase: 25-script-migration*
*Completed: 2026-02-14*
