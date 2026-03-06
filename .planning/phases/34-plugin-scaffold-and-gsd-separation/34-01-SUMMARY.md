---
phase: 34-plugin-scaffold-and-gsd-separation
plan: 01
subsystem: infra
tags: [plugin, scaffold, manifest, marketplace, symlinks, hooks, claude-code]

# Dependency graph
requires:
  - phase: 33-subagent-personas
    provides: agent definitions (pentester, defender, analyst) and skill pack
provides:
  - netsec-skills/ plugin directory with complete scaffold
  - plugin.json manifest loadable via claude --plugin-dir
  - hooks.json with CLAUDE_PLUGIN_ROOT portable paths
  - marketplace.json catalog (single source of truth for all plugin contents)
  - 30 skill symlinks and 3 agent symlinks resolving to .claude/ originals
  - README.md plugin documentation
affects: [35-portable-safety, 36-dual-mode-tool-skills, 37-standalone-workflows, 38-agent-personas, 39-publication]

# Tech tracking
tech-stack:
  added: []
  patterns: [claude-plugin-dir-structure, relative-symlinks-for-skills, marketplace-json-catalog]

key-files:
  created:
    - netsec-skills/.claude-plugin/plugin.json
    - netsec-skills/hooks/hooks.json
    - netsec-skills/hooks/netsec-pretool.sh
    - netsec-skills/hooks/netsec-posttool.sh
    - netsec-skills/hooks/netsec-health.sh
    - netsec-skills/marketplace.json
    - netsec-skills/README.md
  modified: []

key-decisions:
  - "Agent invoker skills (3) not listed separately in marketplace.json -- represented by agents section"
  - "Hook scripts copied as-is (not symlinked) for Phase 35 portability modifications"
  - "Excluded lab and pentest-conventions skills (repo-specific, not portable)"
  - "Excluded all 12 gsd-*.md agent files from plugin (GSD boundary)"

patterns-established:
  - "Plugin scaffold: .claude-plugin/plugin.json + skills/ + agents/ + hooks/ + scripts/"
  - "Skill symlinks use 3-level relative paths: ../../../.claude/skills/<name>"
  - "Agent symlinks use 2-level relative paths: ../../.claude/agents/<name>.md"
  - "marketplace.json as single source of truth for plugin contents (27 skills + 2 hooks + 3 agents)"

requirements-completed: [PLUG-01, PLUG-02, PLUG-03]

# Metrics
duration: 3min
completed: 2026-03-06
---

# Phase 34 Plan 01: Plugin Directory Scaffold Summary

**Complete netsec-skills/ plugin directory with manifest, 30 skill symlinks, 3 agent symlinks, hooks registration via CLAUDE_PLUGIN_ROOT, marketplace.json catalog, and README documentation**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-06T14:21:04Z
- **Completed:** 2026-03-06T14:24:12Z
- **Tasks:** 2
- **Files modified:** 40

## Accomplishments
- Created complete plugin directory scaffold loadable via `claude --plugin-dir ./netsec-skills`
- 30 skill symlinks (17 tool + 6 workflow + 3 agent invoker + 4 utility) all resolving with zero broken links
- 3 agent definition symlinks (pentester, defender, analyst) with zero GSD agent leakage
- marketplace.json with 27 skills, 2 hooks, 3 agents as single source of truth
- hooks.json using `${CLAUDE_PLUGIN_ROOT}` for portable path resolution

## Task Commits

Each task was committed atomically:

1. **Task 1: Create plugin directory structure with manifest, hooks, and all symlinks** - `e9f8033` (feat)
2. **Task 2: Create marketplace.json catalog and README.md** - `4524536` (feat)

## Files Created/Modified
- `netsec-skills/.claude-plugin/plugin.json` - Plugin manifest with identity, keywords, author, repository
- `netsec-skills/hooks/hooks.json` - Hook registration with CLAUDE_PLUGIN_ROOT command paths
- `netsec-skills/hooks/netsec-pretool.sh` - Copy of PreToolUse safety hook
- `netsec-skills/hooks/netsec-posttool.sh` - Copy of PostToolUse audit/JSON bridge hook
- `netsec-skills/hooks/netsec-health.sh` - Copy of health check script
- `netsec-skills/skills/tools/` - 17 tool skill symlinks (nmap, tshark, metasploit, etc.)
- `netsec-skills/skills/workflows/` - 6 workflow skill symlinks (recon, scan, fuzz, crack, sniff, diagnose)
- `netsec-skills/skills/agents/` - 3 agent invoker skill symlinks (pentester, defender, analyst)
- `netsec-skills/skills/utility/` - 4 utility skill symlinks (scope, netsec-health, check-tools, report)
- `netsec-skills/agents/` - 3 agent definition symlinks (pentester.md, defender.md, analyst.md)
- `netsec-skills/marketplace.json` - Plugin contents catalog (27 skills, 2 hooks, 3 agents)
- `netsec-skills/README.md` - Plugin documentation (118 lines)

## Decisions Made
- Agent invoker skills not duplicated in marketplace.json skills array -- the 3 agent invoker skills in skills/agents/ are the skill-side entry points for the agents listed in the agents section, so marketplace has 27 (not 30) skill entries
- Hook scripts copied as files (not symlinked) because Phase 35 will modify them for portability without affecting the originals
- Excluded `lab` and `pentest-conventions` skills as they are repo-specific and not portable
- Excluded all 12 `gsd-*.md` agent files to maintain clean GSD separation boundary

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Plugin scaffold complete and loadable via `claude --plugin-dir ./netsec-skills`
- Phase 34-02 can validate the boundary (no GSD leakage, correct counts)
- Phase 35 can begin hook portability work on the copied hook scripts in netsec-skills/hooks/
- All symlinks point to existing .claude/skills/ and .claude/agents/ originals

## Self-Check: PASSED

All 8 created files verified on disk. Both task commits (e9f8033, 4524536) found in git history.

---
*Phase: 34-plugin-scaffold-and-gsd-separation*
*Completed: 2026-03-06*
