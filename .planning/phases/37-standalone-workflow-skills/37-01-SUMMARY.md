---
phase: 37-standalone-workflow-skills
plan: 01
subsystem: skills
tags: [claude-skills, dual-mode, bats, workflow, recon, crack, standalone]

requires:
  - phase: 36-dual-mode-tool-skills
    provides: Dual-mode tool skill pattern, BATS test scaffold pattern, standalone command knowledge
provides:
  - BATS test scaffold validating WORK-01 and WORK-02 for all 6 workflow skills
  - Dual-mode recon workflow with 6 steps covering nmap, dig, curl, gobuster
  - Dual-mode crack workflow with 5 steps covering john, hashcat with decision routing
  - Per-step branching template validated for workflow skill transformation
affects: [37-02-PLAN (scales pattern to 4 remaining workflows)]

tech-stack:
  added: []
  patterns: [per-step-dual-mode-branching, environment-detection-workflow, mode-aware-after-each-step]

key-files:
  created: [tests/test-workflow-skills.bats]
  modified: [.claude/skills/recon/SKILL.md, .claude/skills/crack/SKILL.md, netsec-skills/skills/workflows/recon/SKILL.md, netsec-skills/skills/workflows/crack/SKILL.md]

key-decisions:
  - "Workflow dual-mode uses per-step 'If wrapper / If standalone' branching (not per-section Mode headers like tool skills)"
  - "Single Environment Detection point per workflow with test -f on one representative script"
  - "After Each Step section is mode-aware: PostToolUse for wrapper, direct review for standalone"
  - "Plugin symlinks replaced with real file copies for recon and crack (remaining 4 deferred to Plan 02)"

patterns-established:
  - "Per-step dual-mode branching: educational context + wrapper branch + standalone branch per workflow step"
  - "Environment Detection section with test -f dynamic injection at workflow top (not per step)"
  - "Mode-aware After Each Step with PostToolUse for wrapper, direct output review for standalone"

requirements-completed: []

duration: 4min
completed: 2026-03-06
---

# Phase 37 Plan 01: Workflow Dual-Mode Pilot Summary

**BATS test scaffold for 6 workflow skills plus recon (6 steps with nmap/dig/curl/gobuster) and crack (5 steps with john/hashcat decision routing) dual-mode transformation**

## Performance

- **Duration:** 4 min
- **Started:** 2026-03-06T18:24:04Z
- **Completed:** 2026-03-06T18:27:58Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- Created BATS test scaffold with 8 tests validating WORK-01 (standalone), WORK-02 (dual-mode branching), SYNC (plugin parity), and description requirements across all 6 workflows
- Transformed recon workflow to dual-mode: 6 steps with standalone nmap, dig, curl, gobuster commands drawn from Phase 36 tool skills
- Transformed crack workflow to dual-mode: 5 steps with standalone john and hashcat commands, preserved Decision Guidance table for hash-type routing
- Replaced plugin symlinks with real file copies for recon and crack (verified identical with cmp -s)

## Task Commits

Each task was committed atomically:

1. **Task 1: Create BATS test scaffold for workflow skill validation** - `85e8dcc` (test)
2. **Task 2: Transform recon and crack workflows to dual-mode** - `6a71d1d` (feat)

## Files Created/Modified
- `tests/test-workflow-skills.bats` -- 8 structural tests covering WORK-01, WORK-02, SYNC, and description (252 lines)
- `.claude/skills/recon/SKILL.md` -- 6-step recon workflow with dual-mode branching (148 lines)
- `.claude/skills/crack/SKILL.md` -- 5-step crack workflow with dual-mode branching and decision table (147 lines)
- `netsec-skills/skills/workflows/recon/SKILL.md` -- Plugin copy of recon (real file, not symlink)
- `netsec-skills/skills/workflows/crack/SKILL.md` -- Plugin copy of crack (real file, not symlink)

## Decisions Made
- Workflow dual-mode uses per-step "If wrapper / If standalone" branching rather than per-section Mode headers used by tool skills, keeping workflow step flow coherent
- Single Environment Detection point per workflow: `test -f` on one representative wrapper script determines mode for all steps
- After Each Step section made mode-aware: wrapper branch references PostToolUse hook, standalone branch says "review command output directly"
- Plugin symlinks for recon and crack replaced with real file copies; remaining 4 workflow symlinks deferred to Plan 02

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Per-step dual-mode branching pattern validated on the two hardest workflows (recon: multi-tool, crack: conditional routing)
- BATS test scaffold already covers all 6 workflows -- Plan 02 just needs to transform scan, fuzz, sniff, diagnose to make remaining tests pass
- 4 remaining plugin symlinks need replacement with real files (Plan 02 scope)

## Self-Check: PASSED

- FOUND: tests/test-workflow-skills.bats
- FOUND: .claude/skills/recon/SKILL.md
- FOUND: .claude/skills/crack/SKILL.md
- FOUND: netsec-skills/skills/workflows/recon/SKILL.md
- FOUND: netsec-skills/skills/workflows/crack/SKILL.md
- COMMIT: 85e8dcc (Task 1)
- COMMIT: 6a71d1d (Task 2)

---
*Phase: 37-standalone-workflow-skills*
*Completed: 2026-03-06*
