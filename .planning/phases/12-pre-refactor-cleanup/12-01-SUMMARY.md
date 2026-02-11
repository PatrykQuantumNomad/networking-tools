---
phase: 12-pre-refactor-cleanup
plan: 01
subsystem: scripts
tags: [shellcheck, bash-guards, interactive-guards, version-guard, code-consistency]

# Dependency graph
requires: []
provides:
  - "Consistent [[ ! -t 0 ]] && exit 0 guard syntax across all 63 scripts"
  - "Bash 4.0+ version guard in common.sh with clear macOS install hint"
  - ".shellcheckrc with source-path resolution for all script patterns"
affects: [13-library-split, 14-argument-parsing, 15-error-handling, 16-dual-mode, 17-shellcheck-cleanup]

# Tech tracking
tech-stack:
  added: [shellcheck]
  patterns: [unified-interactive-guard, bash-version-guard, shellcheckrc-source-resolution]

key-files:
  created:
    - .shellcheckrc
  modified:
    - scripts/common.sh
    - 50 scripts with guard/comment normalization

key-decisions:
  - "Single standard comment '# Interactive demo (skip if non-interactive)' chosen over longer variants"
  - "Version guard placed before set -euo pipefail so error message displays cleanly"
  - "Three source-path entries in .shellcheckrc to cover all script directory patterns plus Phase 13 lib/"

patterns-established:
  - "Interactive guard: always [[ ! -t 0 ]] && exit 0 with standard comment above"
  - "Bash version guard: BASH_VERSINFO check in common.sh before any 4.0+ syntax"
  - "ShellCheck config: project-root .shellcheckrc with source-path=SCRIPTDIR resolution"

# Metrics
duration: 6min
completed: 2026-02-11
---

# Phase 12 Plan 01: Normalize Guards Summary

**Unified interactive guard syntax, Bash 4.0+ version guard in common.sh, and ShellCheck source-path resolution via .shellcheckrc**

## Performance

- **Duration:** 6 min
- **Started:** 2026-02-11T18:24:11Z
- **Completed:** 2026-02-11T18:29:53Z
- **Tasks:** 3
- **Files modified:** 52

## Accomplishments
- Normalized all 63 interactive guards to identical `[[ ! -t 0 ]] && exit 0` syntax (19 variant B patterns replaced)
- Standardized comment above all 63 guards to single consistent format
- Added Bash 4.0+ version guard to common.sh that prints clear error with brew install hint on macOS Bash 3.2
- Created .shellcheckrc at project root eliminating SC1091 source-resolution warnings across all scripts

## Task Commits

Each task was committed atomically:

1. **Task 1: Normalize interactive guards and comments (NORM-01)** - `6fcef82` (refactor)
2. **Task 2: Add Bash 4.0+ version guard to common.sh (NORM-02)** - `4aba490` (feat)
3. **Task 3: Create .shellcheckrc for source path resolution (NORM-03)** - `0f46001` (chore)

**Plan metadata:** [pending] (docs: complete plan)

## Files Created/Modified
- `.shellcheckrc` - ShellCheck project-level source-path resolution config
- `scripts/common.sh` - Added Bash 4.0+ version guard before set -euo pipefail
- 19 scripts - Guard syntax changed from `[[ -t 0 ]] || exit 0` to `[[ ! -t 0 ]] && exit 0`
- 50 scripts total - Comment above guard normalized to standard text

## Decisions Made
- Single standard comment "# Interactive demo (skip if non-interactive)" chosen to replace 7+ variants
- Version guard placed after shebang/description comments, before set -euo pipefail, using only Bash 2.x+ syntax
- Three source-path entries in .shellcheckrc: SCRIPTDIR, SCRIPTDIR/.., SCRIPTDIR/../lib (last one pre-positioned for Phase 13)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Normalized comments in all 63 files, not just the 19 guard-changed files**
- **Found during:** Task 1 (guard normalization)
- **Issue:** Plan mentioned normalizing comments in "all 63 scripts" but the files list only had 19. Comment variants existed in all 63 files with guards.
- **Fix:** Extended comment normalization to all 63 scripts, including those that already had variant A guards but non-standard comments
- **Files modified:** 50 total (13 already had the standard comment)
- **Verification:** grep -B1 confirms zero non-standard comments above any guard
- **Committed in:** 6fcef82 (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 missing critical)
**Impact on plan:** Comment normalization was explicitly described in the plan action text -- the files list was just incomplete. No scope creep.

## Issues Encountered
None -- plan executed cleanly.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- All 63 interactive guards are now consistent, ready for bulk find/replace in Phases 13-16
- common.sh version guard prevents cryptic failures on macOS default Bash 3.2
- .shellcheckrc eliminates need for per-file ShellCheck directives in Phase 17
- ShellCheck is now installed (0.11.0) for Phase 17 cleanup work

## Self-Check: PASSED

- [x] .shellcheckrc exists at project root
- [x] scripts/common.sh has BASH_VERSINFO guard
- [x] 12-01-SUMMARY.md created
- [x] Commit 6fcef82 exists (Task 1)
- [x] Commit 4aba490 exists (Task 2)
- [x] Commit 0f46001 exists (Task 3)
- [x] 0 variant B guards remain
- [x] 63 variant A guards exist
- [x] 3 source-path entries in .shellcheckrc

---
*Phase: 12-pre-refactor-cleanup*
*Completed: 2026-02-11*
