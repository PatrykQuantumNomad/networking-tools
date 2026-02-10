---
phase: 02-core-networking-tools
plan: 02
subsystem: tools
tags: [curl, http, ssl, tls, timing, networking, bash, web-testing]

# Dependency graph
requires:
  - phase: 01-foundations-and-site-scaffold
    provides: common.sh shared functions, check-tools.sh framework, Makefile structure
  - phase: 02-core-networking-tools/01
    provides: dig scripts established networking tool pattern, check-tools.sh has dig entry
provides:
  - curl examples.sh with 10 educational HTTP client examples (Pattern A)
  - test-http-endpoints.sh use-case for testing GET/POST/PUT/DELETE/PATCH/HEAD/OPTIONS methods
  - check-ssl-certificate.sh use-case for SSL/TLS certificate inspection and validation
  - debug-http-response.sh use-case for HTTP timing breakdown using curl -w format strings
  - curl detection in check-tools.sh with version display
  - Makefile targets: curl, test-http, check-ssl, debug-http
affects: [02-core-networking-tools, site-content]

# Tech tracking
tech-stack:
  added: [curl]
  patterns: [curl -w timing format strings, SSL cert inspection via curl -vI, HTTP method testing]

key-files:
  created:
    - scripts/curl/examples.sh
    - scripts/curl/test-http-endpoints.sh
    - scripts/curl/check-ssl-certificate.sh
    - scripts/curl/debug-http-response.sh
  modified:
    - scripts/check-tools.sh
    - Makefile

key-decisions:
  - "curl uses default get_version() case -- curl --version outputs clean version string, no special handling"
  - "SSL cert script strips https:// prefix from target for clean display but uses https:// in curl commands"
  - "Zero wget references per PITFALL-11 (macOS has no wget)"

patterns-established:
  - "HTTP tool use-case: sensible default URL (https://example.com) for web tools"
  - "SSL cert inspection: strip protocol prefix from target, add back in commands"
  - "Timing format: TIMING_FMT variable for reusable curl -w format strings"

# Metrics
duration: 3min
completed: 2026-02-10
---

# Phase 2 Plan 2: curl Tool Scripts Summary

**curl HTTP client with examples.sh (10 examples) and three use-case scripts for endpoint testing, SSL certificate inspection, and HTTP response timing debugging**

## Performance

- **Duration:** 3 min
- **Started:** 2026-02-10T18:40:24Z
- **Completed:** 2026-02-10T18:44:09Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- Created curl examples.sh following Pattern A with 10 educational HTTP client examples (GET, headers, POST, timing, SSL)
- Created three use-case scripts: test-http-endpoints (HTTP methods), check-ssl-certificate (TLS/cert inspection), debug-http-response (timing breakdown)
- Integrated curl into check-tools.sh (13th tool) using default get_version case
- Added 4 Makefile targets: curl, test-http, check-ssl, debug-http

## Task Commits

Each task was committed atomically:

1. **Task 1: Create curl examples.sh and three use-case scripts** - `d79c503` (feat)
2. **Task 2: Integrate curl into check-tools.sh and Makefile** - `7e3e6a8` (feat)

## Files Created/Modified
- `scripts/curl/examples.sh` - 10 educational curl examples (Pattern A with require_target)
- `scripts/curl/test-http-endpoints.sh` - HTTP method testing: GET, POST, PUT, DELETE, PATCH, HEAD, OPTIONS
- `scripts/curl/check-ssl-certificate.sh` - SSL/TLS certificate details, expiry, TLS versions, HSTS, OCSP
- `scripts/curl/debug-http-response.sh` - HTTP timing breakdown: DNS, TCP, TLS, TTFB, total with curl -w
- `scripts/check-tools.sh` - Added curl to TOOLS array and TOOL_ORDER
- `Makefile` - Added .PHONY entries and 4 new targets (curl, test-http, check-ssl, debug-http)

## Decisions Made
- curl uses the default `get_version()` case in check-tools.sh -- `curl --version | head -1` outputs a clean version string, so no dedicated case needed (unlike dig which required stderr redirect)
- SSL cert script strips `https://` and `http://` prefix from target argument for clean display, but uses `https://` in actual curl commands
- Maintained zero wget references throughout all curl scripts per PITFALL-11 (macOS does not ship wget)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- curl tool complete, ready for plan 03 (netcat/nc)
- HTTP-focused use-case pattern established (sensible URL defaults, method testing, SSL inspection, timing)
- check-tools.sh and Makefile ready for additional networking tools

## Self-Check: PASSED

All 4 created files verified present. Both task commits (d79c503, 7e3e6a8) verified in git log.

---
*Phase: 02-core-networking-tools*
*Completed: 2026-02-10*
