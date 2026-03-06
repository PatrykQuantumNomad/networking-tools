---
phase: 36-dual-mode-tool-skills
plan: 01
subsystem: skills
tags: [claude-skills, dual-mode, bats, dig, curl, netcat, dynamic-injection]

requires:
  - phase: 35-portable-safety-infrastructure
    provides: Portable hooks and scope management for plugin context
provides:
  - BATS test scaffold validating TOOL-01 through TOOL-04 for all 17 tool skills
  - Dual-mode SKILL.md pattern validated on 3 pilot tools (dig, curl, netcat)
  - Template structure for remaining 14 tool skill transformations
affects: [36-02-PLAN (scales pattern to 14 tools), 36-03-PLAN (syncs plugin files)]

tech-stack:
  added: []
  patterns: [dual-mode-skill-template, dynamic-injection-detection, awk-section-extraction]

key-files:
  created: [tests/test-dual-mode-skills.bats]
  modified: [.claude/skills/dig/SKILL.md, .claude/skills/curl/SKILL.md, .claude/skills/netcat/SKILL.md]

key-decisions:
  - "Used awk helper functions in BATS tests instead of sed for macOS BSD compatibility"
  - "Used function-based binary name resolution instead of declare -A associative arrays (BATS parser limitation)"
  - "Plugin skills are hardlinks to in-repo skills (same inode) so SYNC test passes implicitly until Plan 03"

patterns-established:
  - "Dual-mode SKILL.md structure: frontmatter -> Tool Status -> Wrapper Scripts -> Standalone -> Defaults -> Target Validation"
  - "Dynamic injection pattern: command -v for tool install, test -f for wrapper detection"
  - "Section extraction via awk _section_content helper for macOS-compatible BATS testing"

requirements-completed: []

duration: 6min
completed: 2026-03-06
---

# Phase 36 Plan 01: Dual-Mode Pilot Summary

**BATS test scaffold for 17 tool skills plus 3 pilot dual-mode transformations (dig, curl, netcat) with inline commands, wrapper detection, and install guidance**

## Performance

- **Duration:** 6 min
- **Started:** 2026-03-06T17:16:40Z
- **Completed:** 2026-03-06T17:22:36Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Created BATS test scaffold that validates all 4 TOOL requirements (standalone, wrapper, install, description) across 17 tools
- Transformed dig, curl, netcat from wrapper-only pointers to dual-mode skills with inline command knowledge extracted from 9 wrapper scripts
- Validated dual-mode pattern: all 3 pilot tools pass structural tests, 14 remaining tools fail as expected
- Each pilot skill is 85-97 lines with focused inline commands organized by use-case category

## Task Commits

Each task was committed atomically:

1. **Task 1: Create BATS test scaffold for dual-mode skill validation** - `d62819b` (test)
2. **Task 2: Transform dig, curl, netcat skills to dual-mode format** - `f858b8d` (feat)

## Files Created/Modified
- `tests/test-dual-mode-skills.bats` -- 10 structural validation tests for TOOL-01 through TOOL-04 plus SYNC test
- `.claude/skills/dig/SKILL.md` -- Dual-mode with DNS records, zone transfers, propagation (89 lines)
- `.claude/skills/curl/SKILL.md` -- Dual-mode with SSL/TLS, HTTP debugging, endpoint testing (85 lines)
- `.claude/skills/netcat/SKILL.md` -- Dual-mode with port scanning, listeners, file transfer, variant notes (97 lines)

## Decisions Made
- Used awk-based helper functions in BATS tests (macOS BSD sed has incompatible multi-pattern syntax)
- Used `_binary_for()` function instead of `declare -A` associative array in BATS (parser doesn't handle file-level associative arrays correctly)
- Discovered netsec-skills plugin files are hardlinks to in-repo files (same inode); SYNC test passes implicitly until Plan 03 creates independent copies

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fixed macOS BSD sed incompatibility in BATS tests**
- **Found during:** Task 1
- **Issue:** BSD sed on macOS does not support multiple semicolons in address ranges the same way as GNU sed
- **Fix:** Replaced all sed-based section extraction with awk-based `_section_content` helper function
- **Files modified:** tests/test-dual-mode-skills.bats
- **Verification:** All BATS tests run without syntax errors
- **Committed in:** d62819b (Task 1 commit)

**2. [Rule 3 - Blocking] Fixed BATS associative array parsing**
- **Found during:** Task 1
- **Issue:** `declare -A TOOL_BINARIES` at file scope produces empty values when accessed inside @test blocks in BATS
- **Fix:** Replaced associative array with `_binary_for()` case-statement function
- **Files modified:** tests/test-dual-mode-skills.bats
- **Verification:** TOOL-03 test correctly maps metasploit->msfconsole, netcat->nc
- **Committed in:** d62819b (Task 1 commit)

---

**Total deviations:** 2 auto-fixed (2 blocking)
**Impact on plan:** Both fixes necessary for BATS test infrastructure to work on macOS. No scope creep.

## Issues Encountered
None beyond the auto-fixed deviations above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Dual-mode pattern validated and ready to scale to remaining 14 tools in Plan 02
- BATS test scaffold already covers all 17 tools -- Plan 02 just needs to make them pass
- Plugin file sync deferred to Plan 03 (hardlinks will need replacing with independent copies)

## Self-Check: PASSED

- FOUND: tests/test-dual-mode-skills.bats
- FOUND: .claude/skills/dig/SKILL.md
- FOUND: .claude/skills/curl/SKILL.md
- FOUND: .claude/skills/netcat/SKILL.md
- FOUND: 36-01-SUMMARY.md
- COMMIT: d62819b (Task 1)
- COMMIT: f858b8d (Task 2)

---
*Phase: 36-dual-mode-tool-skills*
*Completed: 2026-03-06*
