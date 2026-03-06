---
phase: 35-portable-safety-infrastructure
plan: 02
subsystem: infra
tags: [bash, jq, scope, health-check, plugin, portability]

requires:
  - phase: 34-plugin-scaffold
    provides: netsec-skills scaffold with symlinked skills and copied hooks
provides:
  - Portable netsec-scope.sh CLI for scope management without Makefile or repo paths
  - Dual-context health check detecting plugin vs in-repo installation
  - Portable scope and netsec-health skill files (no longer symlinks)
affects: [36-portable-hooks, 37-plugin-metadata, 38-agent-skills, 39-publication]

tech-stack:
  added: []
  patterns: [resolve_project_dir for CWD-relative paths, CLAUDE_PLUGIN_ROOT context detection, bash 3.2 safe arithmetic]

key-files:
  created:
    - netsec-skills/scripts/netsec-scope.sh
    - netsec-skills/skills/utility/scope/SKILL.md
    - netsec-skills/skills/utility/netsec-health/SKILL.md
  modified:
    - netsec-skills/hooks/netsec-health.sh

key-decisions:
  - "resolve_project_dir pattern shared across scope script and health check for consistent project directory resolution"
  - "Bash 3.2 safe arithmetic (POSIX $((var + 1))) replaces bash 4.0 ((var++)) to support macOS default bash"
  - "Health check reports bash version informationally rather than requiring 4.0+"
  - "Plugin context skips guided hook permission repair (managed by plugin system)"

patterns-established:
  - "CLAUDE_PLUGIN_ROOT detection: check env var to select plugin vs in-repo paths"
  - "Portable skill files: real directories with SKILL.md instead of symlinks to in-repo originals"

requirements-completed: [SAFE-03, SAFE-04]

duration: 5min
completed: 2026-03-06
---

# Phase 35 Plan 02: Portable Scope and Health Check Summary

**Standalone netsec-scope.sh CLI with init/add/remove/show/clear operations and dual-context health check adapting to plugin vs in-repo installation**

## Performance

- **Duration:** 5 min
- **Started:** 2026-03-06T15:44:16Z
- **Completed:** 2026-03-06T15:49:25Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Created portable netsec-scope.sh script that manages .pentest/scope.json from any directory via resolve_project_dir
- Rewrote health check to detect CLAUDE_PLUGIN_ROOT for plugin context, adapting hook file and registration checks
- Eliminated bash 4.0+ requirement by replacing ((var++)) with POSIX arithmetic and removing associative array dependency check
- Replaced both skill symlinks (scope, netsec-health) with real directories containing portable SKILL.md files

## Task Commits

Each task was committed atomically:

1. **Task 1: Create portable netsec-scope.sh script and update scope skill** - `f993a1d` (feat)
2. **Task 2: Rewrite health check for dual-context plugin/in-repo awareness** - `94d1c82` (feat)

## Files Created/Modified

- `netsec-skills/scripts/netsec-scope.sh` - Portable scope management CLI (init/add/remove/show/clear)
- `netsec-skills/hooks/netsec-health.sh` - Dual-context health check with CLAUDE_PLUGIN_ROOT detection
- `netsec-skills/skills/utility/scope/SKILL.md` - Portable scope skill referencing netsec-scope.sh
- `netsec-skills/skills/utility/netsec-health/SKILL.md` - Portable health skill for both contexts

## Decisions Made

- Used resolve_project_dir() pattern (CLAUDE_PROJECT_DIR > git root > CWD) consistently across both scripts
- Replaced bash 4.0+ arithmetic ((var++)) with POSIX $((var + 1)) for macOS default bash compatibility
- Health check reports bash version informationally without failing on < 4.0
- Plugin context guided repair skips hook file permission fixes (managed by plugin system)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Portable scope script ready for use by other plugins and downstream phases
- Health check ready for both plugin and in-repo contexts
- Phase 36 (portable hooks) can proceed -- hooks at netsec-skills/hooks/ need same dual-context treatment

## Self-Check: PASSED

---
*Phase: 35-portable-safety-infrastructure*
*Completed: 2026-03-06*
