---
phase: 07-web-enumeration-tools
plan: 02
subsystem: scripts
tags: [ffuf, web-fuzzer, parameter-fuzzing, fuzz, wordlist]

# Dependency graph
requires:
  - phase: 07-web-enumeration-tools
    provides: "gobuster scripts, check-tools/Makefile patterns, wordlist infrastructure"
provides:
  - "ffuf examples.sh with 10 educational web fuzzing examples"
  - "fuzz-parameters.sh use-case for parameter discovery and value fuzzing"
  - "ffuf check-tools.sh integration with version detection via ffuf -V"
  - "ffuf and fuzz-params Makefile targets"
  - "ffuf.mdx site documentation with install tabs and FUZZ keyword guide"
affects: []

# Tech tracking
tech-stack:
  added: [ffuf]
  patterns: [FUZZ-keyword-positioning, multi-wordlist-fuzzing]

key-files:
  created:
    - scripts/ffuf/examples.sh
    - scripts/ffuf/fuzz-parameters.sh
    - site/src/content/docs/tools/ffuf.mdx
  modified:
    - scripts/check-tools.sh
    - Makefile

key-decisions:
  - "ffuf version detection uses 'ffuf -V' flag with 2>&1 pipe"
  - "All examples use -t 10 (not ffuf's default 40) for Docker lab safety"
  - "ffuf.mdx sidebar order 18 (after gobuster at 17)"

patterns-established:
  - "FUZZ keyword position guide: URL path, query param name, query param value, POST data, headers"

# Metrics
duration: 3min
completed: 2026-02-11
---

# Phase 7 Plan 2: ffuf Web Fuzzer Summary

**ffuf examples.sh with 10 fuzzing examples, parameter discovery use-case, check-tools/Makefile integration, and site docs with FUZZ keyword guide**

## Performance

- **Duration:** 3 min
- **Started:** 2026-02-11T02:09:55Z
- **Completed:** 2026-02-11T02:13:30Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- Created ffuf examples.sh with 10 educational examples covering directory fuzzing, parameter discovery, POST data, headers, auto-calibration, rate limiting, and multi-wordlist fuzzing
- Created fuzz-parameters.sh use-case with 10 parameter-focused examples covering GET/POST discovery, value fuzzing, JSON API fuzzing, and filtering techniques
- Integrated ffuf into check-tools.sh (TOOLS array, TOOL_ORDER, get_version with ffuf -V) and Makefile (ffuf and fuzz-params targets)
- Created ffuf.mdx site documentation with install tabs, comprehensive key flags table, FUZZ keyword positioning guide, and wordlists section

## Task Commits

Each task was committed atomically:

1. **Task 1: Create ffuf examples.sh and fuzz-parameters use-case script** - `390cffe` (feat)
2. **Task 2: Integrate ffuf into check-tools.sh, Makefile, and create site page** - `1e8fc84` (feat)

## Files Created/Modified
- `scripts/ffuf/examples.sh` - 10 educational ffuf examples with interactive demo and wordlist check
- `scripts/ffuf/fuzz-parameters.sh` - Parameter discovery and value fuzzing use-case with 10 examples
- `site/src/content/docs/tools/ffuf.mdx` - Site documentation with install tabs, FUZZ keyword guide, key flags
- `scripts/check-tools.sh` - Added ffuf to TOOLS array, TOOL_ORDER, and get_version()
- `Makefile` - Added ffuf and fuzz-params targets

## Decisions Made
- ffuf version detection uses `ffuf -V` flag (outputs version to stdout with 2>&1 pipe)
- All examples consistently use `-t 10` (not ffuf's default 40 threads) for Docker lab safety
- ffuf.mdx sidebar order 18 (immediately after gobuster at 17, keeping web enumeration tools grouped)
- Debian/Ubuntu install shows binary download from GitHub releases since ffuf is not in apt repos

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- ffuf completes the web enumeration tools alongside gobuster
- All 17 tools now have scripts, check-tools integration, and documentation pages
- Phase 7 (final phase) is complete -- all 3 plans (07-01 gobuster, 07-02 ffuf, 07-03 wordlists) delivered

## Self-Check: PASSED

All key files verified on disk. All commit hashes verified in git log.

---
*Phase: 07-web-enumeration-tools*
*Completed: 2026-02-11*
