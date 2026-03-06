---
phase: 35-portable-safety-infrastructure
plan: 01
subsystem: infra
tags: [bash, hooks, safety, plugin, portable, bash-3.2]

# Dependency graph
requires:
  - phase: 34-plugin-scaffold-and-gsd-separation
    provides: netsec-skills/ plugin scaffold with copied hook files
provides:
  - Portable PreToolUse hook with bash 3.2 compat and dual-context resolution
  - Portable PostToolUse hook with direct tool audit logging
  - Scope auto-creation on missing scope file
  - Skill-based redirect for raw tool interception in plugin context
affects: [35-portable-safety-infrastructure, 36-dual-mode-tool-skills, 39-end-to-end-testing]

# Tech tracking
tech-stack:
  added: []
  patterns: [resolve_project_dir portable path chain, case-statement tool mapping for bash 3.2, dual-context CLAUDE_PLUGIN_ROOT branching]

key-files:
  created: []
  modified:
    - netsec-skills/hooks/netsec-pretool.sh
    - netsec-skills/hooks/netsec-posttool.sh

key-decisions:
  - "Case-statement function replaces declare -A for bash 3.2 macOS compatibility"
  - "Scope auto-creation with localhost defaults instead of hard-deny on missing scope"
  - "Plugin context redirects to /skill triggers instead of wrapper scripts"

patterns-established:
  - "resolve_project_dir(): CLAUDE_PROJECT_DIR > git root > CWD fallback chain for all portable hooks"
  - "get_tool_script_dir(): case-statement tool-to-directory mapping (bash 3.2 safe)"
  - "CLAUDE_PLUGIN_ROOT presence check for dual-context branching"
  - "direct_tool audit event for non-wrapper tool invocations"

requirements-completed: [SAFE-01, SAFE-02]

# Metrics
duration: 3min
completed: 2026-03-06
---

# Phase 35 Plan 01: Portable Safety Hooks Summary

**Bash 3.2-compatible PreToolUse and PostToolUse hooks with dual-context plugin/in-repo resolution, scope auto-creation, and direct tool audit logging**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-06T15:42:34Z
- **Completed:** 2026-03-06T15:46:20Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Replaced all bash 4.0+ features (declare -A, ${!array[@]}) with bash 3.2 compatible alternatives (case statements, plain string iteration)
- Added resolve_project_dir() portable path resolution to both hooks (CLAUDE_PROJECT_DIR > git root > CWD)
- PreToolUse hook now redirects to /skill triggers in plugin context and wrapper scripts in-repo
- Missing scope file auto-creates with localhost/127.0.0.1 defaults instead of hard-blocking
- PostToolUse hook now audits direct security tool calls (event: direct_tool) even without wrapper scripts

## Task Commits

Each task was committed atomically:

1. **Task 1: Rewrite PreToolUse hook for portable plugin operation** - `1a64b33` (feat)
2. **Task 2: Rewrite PostToolUse hook for portable plugin operation** - `7e56443` (feat)

## Files Created/Modified
- `netsec-skills/hooks/netsec-pretool.sh` - Portable PreToolUse safety hook with bash 3.2 compat, dual-context redirect, scope auto-creation
- `netsec-skills/hooks/netsec-posttool.sh` - Portable PostToolUse audit hook with direct tool logging and resolve_project_dir

## Decisions Made
- Used case-statement function instead of declare -A for bash 3.2 macOS compatibility (macOS ships bash 3.2)
- Auto-create scope file with localhost defaults instead of hard-deny (better UX for fresh plugin installs)
- Plugin context redirects to /skill triggers (e.g., /metasploit) instead of wrapper scripts (which may not exist)
- Direct tool calls get "direct_tool" audit event type distinct from "executed" wrapper script events

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Portable hooks are ready for use in both in-repo and plugin contexts
- Phase 35 Plan 02 (portable scope management and health check) can proceed
- The resolve_project_dir pattern is established for reuse in future portable scripts
- In-repo originals at .claude/hooks/ remain untouched for backward compatibility

## Self-Check: PASSED

All files and commits verified:
- netsec-skills/hooks/netsec-pretool.sh: FOUND
- netsec-skills/hooks/netsec-posttool.sh: FOUND
- Commit 1a64b33: FOUND
- Commit 7e56443: FOUND

---
*Phase: 35-portable-safety-infrastructure*
*Completed: 2026-03-06*
