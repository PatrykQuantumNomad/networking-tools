---
phase: 02-core-networking-tools
plan: 01
subsystem: tools
tags: [dig, dns, networking, bash, reconnaissance]

# Dependency graph
requires:
  - phase: 01-foundations-and-site-scaffold
    provides: common.sh shared functions, check-tools.sh framework, Makefile structure
provides:
  - dig examples.sh with 10 educational DNS query examples (Pattern A)
  - query-dns-records.sh use-case for querying A/AAAA/MX/NS/TXT/SOA/CNAME records
  - check-dns-propagation.sh use-case comparing responses across 6 public resolvers
  - attempt-zone-transfer.sh use-case for AXFR zone transfer techniques
  - dig detection in check-tools.sh with version display
  - Makefile targets: dig, query-dns, check-dns-prop, zone-transfer
affects: [02-core-networking-tools, site-content]

# Tech tracking
tech-stack:
  added: [dig/dnsutils]
  patterns: [use-case script pattern with sensible defaults, dig -v stderr version detection]

key-files:
  created:
    - scripts/dig/examples.sh
    - scripts/dig/query-dns-records.sh
    - scripts/dig/check-dns-propagation.sh
    - scripts/dig/attempt-zone-transfer.sh
  modified:
    - scripts/check-tools.sh
    - Makefile

key-decisions:
  - "dig -v outputs to stderr; added dedicated case in get_version using 2>&1 redirect"
  - "Use-case scripts use TARGET with sensible default (example.com) instead of require_target"

patterns-established:
  - "Networking tool use-case: sensible default domain (example.com) for DNS tools"
  - "dig version detection: dig -v 2>&1 | head -1 (stderr to stdout)"

# Metrics
duration: 4min
completed: 2026-02-10
---

# Phase 2 Plan 1: dig Tool Scripts Summary

**dig DNS query tool with examples.sh (10 examples) and three use-case scripts for record querying, propagation checking, and zone transfer attempts**

## Performance

- **Duration:** 4 min
- **Started:** 2026-02-10T18:33:23Z
- **Completed:** 2026-02-10T18:37:25Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- Created dig examples.sh following Pattern A with 10 educational DNS query examples
- Created three use-case scripts: query-dns-records, check-dns-propagation, attempt-zone-transfer
- Integrated dig into check-tools.sh (12th tool) with dig -v stderr version detection
- Added 4 Makefile targets: dig, query-dns, check-dns-prop, zone-transfer

## Task Commits

Each task was committed atomically:

1. **Task 1: Create dig examples.sh and three use-case scripts** - `c71b0e6` (feat)
2. **Task 2: Integrate dig into check-tools.sh and Makefile** - `e4ebd4e` (feat)

## Files Created/Modified
- `scripts/dig/examples.sh` - 10 educational dig examples (Pattern A with require_target)
- `scripts/dig/query-dns-records.sh` - Query all common DNS record types for a domain
- `scripts/dig/check-dns-propagation.sh` - Compare DNS responses across 6 public resolvers
- `scripts/dig/attempt-zone-transfer.sh` - AXFR zone transfer techniques and subdomain brute-check
- `scripts/check-tools.sh` - Added dig to TOOLS array, TOOL_ORDER, and get_version case
- `Makefile` - Added .PHONY entries and 4 new targets (dig, query-dns, check-dns-prop, zone-transfer)

## Decisions Made
- dig -v outputs version to stderr, not stdout -- added dedicated `dig)` case in `get_version()` using `2>&1` redirect rather than relying on the default `--version` path
- Use-case scripts use `TARGET="${1:-example.com}"` sensible default instead of `require_target`, consistent with use-case pattern from other tools
- Did not add dig to the hardcoded brew install hint at bottom of check-tools.sh since dig is usually pre-installed via macOS system tools

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- dig tool complete, ready for plan 02 (curl/wget) and plan 03 (netcat/nc)
- Established networking tool use-case pattern with sensible domain defaults
- check-tools.sh and Makefile ready for additional networking tools

## Self-Check: PASSED

All 4 created files verified present. Both task commits (c71b0e6, e4ebd4e) verified in git log.

---
*Phase: 02-core-networking-tools*
*Completed: 2026-02-10*
