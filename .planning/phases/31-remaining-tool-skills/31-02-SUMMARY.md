---
phase: 31-remaining-tool-skills
plan: 02
subsystem: skills
tags: [hping3, skipfish, netcat, traceroute, claude-skills, disable-model-invocation]

requires:
  - phase: 29-tool-skills
    provides: validated SKILL.md pattern (nmap reference template)
provides:
  - hping3 skill with root/sudo requirement documentation
  - skipfish skill with per-script lab target defaults
  - netcat skill with nc variant detection documentation
  - traceroute skill with mtr dependency and macOS sudo notes
affects: [33-agent-memory]

tech-stack:
  added: []
  patterns: [tool-specific defaults per skill, variant-aware documentation]

key-files:
  created:
    - .claude/skills/hping3/SKILL.md
    - .claude/skills/skipfish/SKILL.md
    - .claude/skills/netcat/SKILL.md
    - .claude/skills/traceroute/SKILL.md
  modified: []

key-decisions:
  - "Documented per-script default targets for skipfish (Juice Shop 3030, DVWA 8080) rather than a single tool default"
  - "Documented netcat variant detection as a Defaults bullet rather than a separate section"
  - "Used [port] argument notation for setup-listener to distinguish from [target] used by other netcat scripts"

patterns-established:
  - "Tool-specific defaults section: each skill documents unique behaviors (root requirements, variant detection, external dependencies)"

requirements-completed: [TOOL-08, TOOL-09, TOOL-13, TOOL-14]

duration: 3min
completed: 2026-02-18
---

# Phase 31 Plan 02: Network Tools Skills Summary

**4 network tool skills (hping3, skipfish, netcat, traceroute) with tool-specific defaults: root requirements, lab targets, variant detection, and mtr dependency**

## Performance

- **Duration:** 3 min
- **Started:** 2026-02-18T02:00:11Z
- **Completed:** 2026-02-18T02:02:50Z
- **Tasks:** 2
- **Files created:** 4

## Accomplishments

- Created hping3 skill documenting root/sudo requirement for packet crafting
- Created skipfish skill with per-script lab target defaults (Juice Shop, DVWA)
- Created netcat skill documenting nc variant detection (ncat, GNU, traditional, OpenBSD) and per-script argument differences (target vs port)
- Created traceroute skill documenting mtr dependency for diagnose-latency and macOS sudo requirement

## Task Commits

Each task was committed atomically:

1. **Task 1: Create hping3 and skipfish skills** - `3f66ded` (feat)
2. **Task 2: Create netcat and traceroute skills** - `1b0aa23` (feat)

## Files Created/Modified

- `.claude/skills/hping3/SKILL.md` - Packet crafting skill with root/sudo requirement, 3 scripts (detect-firewall, test-firewall-rules, examples)
- `.claude/skills/skipfish/SKILL.md` - Web scanner skill with per-script lab target defaults, 3 scripts (quick-scan, authenticated-scan, examples)
- `.claude/skills/netcat/SKILL.md` - Network utility skill with variant detection, 4 scripts (scan-ports, setup-listener, transfer-files, examples)
- `.claude/skills/traceroute/SKILL.md` - Path analyzer skill with mtr dependency note, 4 scripts (trace-network-path, compare-routes, diagnose-latency, examples)

## Decisions Made

- Documented per-script default targets for skipfish (Juice Shop on 3030, DVWA on 8080) rather than a single generic default
- Documented netcat variant detection as a Defaults bullet rather than a separate section to stay under 55 lines
- Used `[port]` argument notation for setup-listener to distinguish from `[target]` used by other netcat scripts

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- 4 network tool skills complete, ready for Phase 31-03 (remaining tools)
- All skills follow the validated nmap SKILL.md pattern from Phase 29
- All use `disable-model-invocation: true` for zero context overhead

## Self-Check: PASSED

- All 4 SKILL.md files exist at expected paths
- Both task commits verified in git log (3f66ded, 1b0aa23)
- All frontmatter includes disable-model-invocation: true
- Tool-specific defaults verified: root/sudo (hping3), lab targets (skipfish), variant detection (netcat), mtr requirement (traceroute)

---
*Phase: 31-remaining-tool-skills*
*Completed: 2026-02-18*
