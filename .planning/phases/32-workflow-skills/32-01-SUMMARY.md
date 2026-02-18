---
phase: 32-workflow-skills
plan: 01
subsystem: skills
tags: [claude-skills, workflow, recon, scan, diagnose, nmap, dig, curl, gobuster, nikto, sqlmap, traceroute]

# Dependency graph
requires:
  - phase: 31-remaining-tool-skills
    provides: tool wrapper scripts with -j/-x flag support (nmap, dig, curl, gobuster, nikto, sqlmap, traceroute)
  - phase: 28-safety-hooks
    provides: PreToolUse/PostToolUse hooks that validate commands and parse JSON output
provides:
  - /recon workflow skill: 6-step reconnaissance orchestrating nmap x2, dig x2, curl, gobuster
  - /scan workflow skill: 5-step vulnerability scanning orchestrating nmap x2, nikto, sqlmap, curl
  - /diagnose workflow skill: 5-step diagnostics with Pattern B handling for diagnostics/ scripts
affects:
  - 32-02 (fuzz, crack, sniff workflows -- same SKILL.md pattern)
  - 32-03 (report, scope workflows)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Workflow skill pattern: numbered steps with bash script invocations, -j -x flags, scope validation, empty-arg guard"
    - "Pattern B diagnostics handling: diagnostics/ scripts invoked without -j -x, documented clearly in skill body"
    - "disable-model-invocation: true on workflow skills -- user must invoke explicitly, no auto-triggering"

key-files:
  created:
    - .claude/skills/recon/SKILL.md
    - .claude/skills/scan/SKILL.md
    - .claude/skills/diagnose/SKILL.md
  modified: []

key-decisions:
  - "Used disable-model-invocation: true on all 3 workflow skills -- prevents auto-triggering, workflows run only when user explicitly invokes /recon, /scan, /diagnose"
  - "Pattern B distinction documented in /diagnose -- diagnostics/ scripts have no -j/-x support; tool wrapper scripts use standard -j -x flags"
  - "Scope validation uses same pattern across all 3 skills: check .pentest/scope.json, ask user to /scope add if target missing"

patterns-established:
  - "Workflow SKILL.md structure: frontmatter -> Purpose -> Target (with scope guard) -> numbered Steps -> After Each Step -> Summary"
  - "/diagnose two-tier step handling: steps 1-3 are Pattern B (text output, no -j -x), steps 4-5 are tool wrappers (-j -x, JSON output)"

# Metrics
duration: 2min
completed: 2026-02-18
---

# Phase 32 Plan 01: Network Workflow Skills Summary

**Three network-oriented workflow skills (/recon, /scan, /diagnose) orchestrating 13 total script invocations across nmap, dig, curl, gobuster, nikto, sqlmap, traceroute, and diagnostics scripts**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-18T03:10:25Z
- **Completed:** 2026-02-18T03:12:39Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- /recon skill: 6-step workflow covering host discovery, port scanning, DNS records, zone transfer, SSL inspection, and subdomain enumeration
- /scan skill: 5-step workflow covering port/service scanning, nmap NSE web vulns, nikto analysis, SQL injection testing, and HTTP endpoint testing
- /diagnose skill: 5-step workflow with explicit Pattern B handling -- diagnostics scripts without -j -x, tool wrappers with -j -x, and clear inline documentation

## Task Commits

Each task was committed atomically:

1. **Task 1: Create /recon and /scan workflow skills** - `8f11520` (feat)
2. **Task 2: Create /diagnose workflow skill** - `5b234f2` (feat)

**Plan metadata:** (docs commit -- next)

## Files Created/Modified

- `.claude/skills/recon/SKILL.md` - 6-step reconnaissance workflow (94 lines)
- `.claude/skills/scan/SKILL.md` - 5-step vulnerability scanning workflow (85 lines)
- `.claude/skills/diagnose/SKILL.md` - 5-step diagnostics workflow with Pattern B handling (91 lines)

## Decisions Made

- Used `disable-model-invocation: true` on all 3 workflow skills. These are explicit user actions (like /recon, /scan) that should never auto-trigger. Consistent with the research recommendation to prioritize safety over context-budget savings from having descriptions auto-load.
- /diagnose Pattern B section added before steps to clearly separate the two script invocation styles. Each Pattern B step also includes an inline "Do NOT add -j or -x" reminder to reinforce the distinction at point-of-use.
- Scope validation pattern is identical across all 3 skills (check scope.json, ask user to /scope add), establishing a reusable template for the remaining 5 workflow skills in Plans 02 and 03.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Pattern established for workflow SKILL.md files -- Plans 32-02 and 32-03 follow the same structure
- /diagnose Pattern B handling documented and ready to reference for any future scripts that don't support -j -x
- Ready for 32-02 (fuzz, crack, sniff workflow skills)

---
*Phase: 32-workflow-skills*
*Completed: 2026-02-18*

## Self-Check: PASSED

Files verified on disk:
- `.claude/skills/recon/SKILL.md`: FOUND
- `.claude/skills/scan/SKILL.md`: FOUND
- `.claude/skills/diagnose/SKILL.md`: FOUND

Commits verified:
- `8f11520`: FOUND (feat(32-01): create /recon and /scan workflow skills)
- `5b234f2`: FOUND (feat(32-01): create /diagnose workflow skill)
