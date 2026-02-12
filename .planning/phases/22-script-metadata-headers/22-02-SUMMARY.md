---
phase: 22-script-metadata-headers
plan: 02
subsystem: scripts
tags: [bash, metadata, headers, use-case-scripts]

# Dependency graph
requires:
  - phase: 22-01
    provides: header format definition and examples.sh/lib/utility headers as reference
provides:
  - structured @description/@usage/@dependencies headers on all 46 use-case scripts
affects: [22-03-header-validation-test]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Bordered metadata block between shebang and source line for use-case scripts"

key-files:
  created: []
  modified:
    - scripts/aircrack-ng/analyze-wireless-networks.sh
    - scripts/aircrack-ng/capture-handshake.sh
    - scripts/aircrack-ng/crack-wpa-handshake.sh
    - scripts/curl/check-ssl-certificate.sh
    - scripts/curl/debug-http-response.sh
    - scripts/curl/test-http-endpoints.sh
    - scripts/dig/attempt-zone-transfer.sh
    - scripts/dig/check-dns-propagation.sh
    - scripts/dig/query-dns-records.sh
    - scripts/ffuf/fuzz-parameters.sh
    - scripts/foremost/analyze-forensic-image.sh
    - scripts/foremost/carve-specific-filetypes.sh
    - scripts/foremost/recover-deleted-files.sh
    - scripts/gobuster/discover-directories.sh
    - scripts/gobuster/enumerate-subdomains.sh
    - scripts/hashcat/benchmark-gpu.sh
    - scripts/hashcat/crack-ntlm-hashes.sh
    - scripts/hashcat/crack-web-hashes.sh
    - scripts/hping3/detect-firewall.sh
    - scripts/hping3/test-firewall-rules.sh
    - scripts/john/crack-archive-passwords.sh
    - scripts/john/crack-linux-passwords.sh
    - scripts/john/identify-hash-type.sh
    - scripts/metasploit/generate-reverse-shell.sh
    - scripts/metasploit/scan-network-services.sh
    - scripts/metasploit/setup-listener.sh
    - scripts/netcat/scan-ports.sh
    - scripts/netcat/setup-listener.sh
    - scripts/netcat/transfer-files.sh
    - scripts/nikto/scan-multiple-hosts.sh
    - scripts/nikto/scan-specific-vulnerabilities.sh
    - scripts/nikto/scan-with-auth.sh
    - scripts/nmap/discover-live-hosts.sh
    - scripts/nmap/identify-ports.sh
    - scripts/nmap/scan-web-vulnerabilities.sh
    - scripts/skipfish/quick-scan-web-app.sh
    - scripts/skipfish/scan-authenticated-app.sh
    - scripts/sqlmap/bypass-waf.sh
    - scripts/sqlmap/dump-database.sh
    - scripts/sqlmap/test-all-parameters.sh
    - scripts/traceroute/compare-routes.sh
    - scripts/traceroute/diagnose-latency.sh
    - scripts/traceroute/trace-network-path.sh
    - scripts/tshark/analyze-dns-queries.sh
    - scripts/tshark/capture-http-credentials.sh
    - scripts/tshark/extract-files-from-capture.sh

key-decisions:
  - "diagnose-latency.sh dependency is mtr (not traceroute) matching its require_cmd"

patterns-established:
  - "Use-case script header: bordered block with @description, @usage, @dependencies between shebang and source line"

# Metrics
duration: 4min
completed: 2026-02-12
---

# Phase 22 Plan 02: Use-Case Script Headers Summary

**Bordered @description/@usage/@dependencies metadata headers added to all 46 use-case scripts across 16 tool directories**

## Performance

- **Duration:** 4 min
- **Started:** 2026-02-12T17:57:24Z
- **Completed:** 2026-02-12T18:01:59Z
- **Tasks:** 2
- **Files modified:** 46

## Accomplishments
- All 46 use-case scripts now have machine-parseable @description, @usage, and @dependencies headers within first 10 lines
- Descriptions extracted from existing line-2 comments (no invented content)
- Zero behavioral change -- headers are pure comments, all 186 BATS tests pass

## Task Commits

Each task was committed atomically:

1. **Task 1: Add headers to aircrack-ng through john (23 files)** - `9e2acd2` (feat)
2. **Task 2: Add headers to metasploit through tshark (23 files)** - `1bf3432` (feat)

## Files Created/Modified
- 46 use-case scripts across 16 tool directories (aircrack-ng, curl, dig, ffuf, foremost, gobuster, hashcat, hping3, john, metasploit, netcat, nikto, nmap, skipfish, sqlmap, traceroute, traceroute, tshark)
- Each file: replaced single-line comment header with 5-line bordered metadata block

## Decisions Made
- `diagnose-latency.sh` uses `@dependencies mtr, common.sh` (not traceroute) because the script's `require_cmd` checks for mtr

## Deviations from Plan

None -- plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None -- no external service configuration required.

## Next Phase Readiness
- All 46 use-case scripts have conformant headers, ready for 22-03 validation test
- Combined with 22-01 (examples.sh, lib, utilities), this covers the bulk of header additions

---
*Phase: 22-script-metadata-headers*
*Completed: 2026-02-12*
