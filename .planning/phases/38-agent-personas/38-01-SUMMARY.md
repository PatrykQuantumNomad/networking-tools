---
phase: 38-agent-personas
plan: 01
subsystem: skills
tags: [claude-skills, agent-personas, dual-mode, bats, pentester, pentest-conventions, plugin]

requires:
  - phase: 37-standalone-workflow-skills
    provides: Dual-mode workflow skill pattern, BATS test scaffold pattern, symlink replacement precedent
provides:
  - BATS test scaffold validating AGEN-01 and AGEN-02 for all 3 agents and 3 invokers
  - Dual-mode pentester agent body with test -f environment detection
  - Dual-mode pentest-conventions skill with conditional wrapper/standalone language
  - Pentester agent, invoker, and pentest-conventions as real files in plugin (not symlinks)
affects: [38-02-PLAN (scales pattern to defender and analyst)]

tech-stack:
  added: []
  patterns: [dual-mode-agent-body, test-f-environment-detection-in-agents, in-repo-only-markers]

key-files:
  created: [tests/test-agent-personas.bats, netsec-skills/skills/utility/pentest-conventions/SKILL.md, netsec-skills/skills/agents/pentester/SKILL.md]
  modified: [.claude/agents/pentester.md, .claude/skills/pentest-conventions/SKILL.md, netsec-skills/agents/pentester.md]

key-decisions:
  - "Pentester agent dual-mode uses test -f scripts/nmap/identify-ports.sh for environment detection (same test -f pattern as workflow skills)"
  - "pentest-conventions uses conditional language with [in-repo only] markers on path references for portability"
  - "Pentester agent frontmatter unchanged -- skills: field references resolve by name: field matching in plugin"
  - "pentest-conventions is user-invocable: false and NOT added to marketplace.json"

patterns-established:
  - "Dual-mode agent body: detect wrapper scripts with test -f, branch to wrapper -j -x or direct tool commands"
  - "[in-repo only] markers on project structure paths that do not exist in standalone context"

requirements-completed: []

duration: 3min
completed: 2026-03-06
---

# Phase 38 Plan 01: BATS Scaffold and Pentester Pilot Summary

**14-test BATS scaffold for agent persona validation plus pentester agent and pentest-conventions dual-mode transformation with real file plugin distribution**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-06T20:13:26Z
- **Completed:** 2026-03-06T20:16:28Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments
- Created BATS test scaffold with 14 tests covering AGEN-01 (agent files, skill references, dual-mode body), AGEN-02 (invoker files, context/agent fields, pentest-conventions), SYNC (agent sync, invoker sync, conventions sync, report sync, no symlinks)
- Transformed pentester agent body to dual-mode: test -f detection replaces hard-coded "Always use wrapper" / "Never invoke raw" instructions
- Transformed pentest-conventions to dual-mode: conditional language for wrapper scripts vs standalone, [in-repo only] markers on project paths
- Replaced pentester agent symlink with real file, pentester invoker symlink with real directory, and created pentest-conventions as new real file in plugin

## Task Commits

Each task was committed atomically:

1. **Task 1: Create BATS test scaffold for agent persona validation** - `81c41d1` (test)
2. **Task 2: Pilot pentester agent + pentest-conventions dual-mode transformation** - `72a3367` (feat)

## Files Created/Modified
- `tests/test-agent-personas.bats` -- 14 structural tests covering AGEN-01, AGEN-02, SYNC for all 3 agents (296 lines)
- `.claude/agents/pentester.md` -- Dual-mode execution rules with test -f wrapper detection
- `.claude/skills/pentest-conventions/SKILL.md` -- Dual-mode conventions with conditional wrapper/standalone language
- `netsec-skills/agents/pentester.md` -- Plugin copy of pentester agent (real file, not symlink)
- `netsec-skills/skills/agents/pentester/SKILL.md` -- Plugin copy of pentester invoker (real file, not symlink)
- `netsec-skills/skills/utility/pentest-conventions/SKILL.md` -- New plugin file for pentest-conventions (was completely missing)

## Decisions Made
- Pentester agent dual-mode uses `test -f scripts/nmap/identify-ports.sh` for environment detection, consistent with the workflow skills pattern from Phase 37
- pentest-conventions uses conditional language ("If wrapper scripts are available" / "If standalone") plus [in-repo only] markers on path references for clear portability signaling
- Agent frontmatter left unchanged -- skills: field references resolve by `name:` field matching in plugin skills
- pentest-conventions kept as `user-invocable: false` and not added to marketplace.json (background context only)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Dual-mode agent body pattern validated on pentester (the most complex agent with 5 workflow skill preloads)
- BATS test scaffold already covers all 3 agents -- Plan 02 just needs to transform defender and analyst, replace remaining symlinks
- 5 remaining failures are all Plan 02 scope: defender symlinks, analyst symlinks, report symlink, check-tools symlink
- pentest-conventions now exists in plugin for the first time, unblocking all 3 agents' skill references

## Self-Check: PASSED

- FOUND: tests/test-agent-personas.bats
- FOUND: .claude/agents/pentester.md
- FOUND: .claude/skills/pentest-conventions/SKILL.md
- FOUND: netsec-skills/agents/pentester.md
- FOUND: netsec-skills/skills/agents/pentester/SKILL.md
- FOUND: netsec-skills/skills/utility/pentest-conventions/SKILL.md
- COMMIT: 81c41d1 (Task 1)
- COMMIT: 72a3367 (Task 2)

---
*Phase: 38-agent-personas*
*Completed: 2026-03-06*
