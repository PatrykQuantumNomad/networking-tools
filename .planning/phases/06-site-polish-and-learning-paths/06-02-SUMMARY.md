---
phase: 06-site-polish-and-learning-paths
plan: 02
subsystem: site
tags: [starlight, learning-paths, task-index, asides, navigation]

# Dependency graph
requires:
  - phase: 04-content-migration-and-tool-pages
    provides: "Tool pages, diagnostic pages, getting-started guide, lab walkthrough"
  - phase: 05-advanced-tools
    provides: "Traceroute/mtr tool page and performance diagnostic page"
provides:
  - "Task index page organizing all use cases by task with tool links"
  - "Three learning path pages (Recon, Web App, Network Debugging) with ordered step sequences"
  - "Lab walkthrough enhanced with Starlight asides (tip, caution, note, danger)"
affects: [06-site-polish-and-learning-paths]

# Tech tracking
tech-stack:
  added: []
  patterns: ["Starlight aside syntax (:::tip, :::caution, :::note, :::danger) for contextual callouts"]

key-files:
  created:
    - "site/src/content/docs/guides/task-index.md"
    - "site/src/content/docs/guides/learning-recon.md"
    - "site/src/content/docs/guides/learning-webapp.md"
    - "site/src/content/docs/guides/learning-network-debug.md"
  modified:
    - "site/src/content/docs/guides/lab-walkthrough.md"
    - "USECASES.md"

key-decisions:
  - "Sidebar ordering: task-index(3), learning paths(10-12) to keep getting-started and lab-walkthrough first"
  - "Learning path steps include specific make commands for immediate practice"

patterns-established:
  - "Starlight aside pattern: :::type[title] for contextual callouts in guide pages"
  - "Learning path structure: overview, prerequisites, numbered steps with tool links and practice commands, next steps"

# Metrics
duration: 6min
completed: 2026-02-10
---

# Phase 6 Plan 2: Task Index, Learning Paths, and Walkthrough Asides Summary

**Task-organized navigation page with 10 category tables, three guided learning paths (Recon, Web App, Network Debugging), and 10 Starlight asides enhancing the lab walkthrough**

## Performance

- **Duration:** 6 min
- **Started:** 2026-02-10T22:44:41Z
- **Completed:** 2026-02-10T22:50:52Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- Created "I Want To..." task index page migrating all USECASES.md categories with 41 tool documentation links
- Built three learning paths with ordered step sequences: Recon (5 steps), Web App Testing (5 steps), Network Debugging (6 steps)
- Enhanced lab walkthrough with 10 Starlight asides covering tips, cautions, notes, and a danger warning
- All new pages correctly ordered in sidebar (task-index at 3, learning paths at 10-12)

## Task Commits

Each task was committed atomically:

1. **Task 1: Create task index page and three learning path pages** - `e58c99f` (feat)
2. **Task 2: Enhance lab walkthrough with Starlight asides** - `7aff342` (feat)

## Files Created/Modified
- `site/src/content/docs/guides/task-index.md` - "I Want To..." page with all use-case categories and tool links
- `site/src/content/docs/guides/learning-recon.md` - Reconnaissance learning path (dig -> nmap -> tshark -> metasploit)
- `site/src/content/docs/guides/learning-webapp.md` - Web App Testing learning path (nmap -> nikto -> skipfish -> sqlmap -> hashcat/john)
- `site/src/content/docs/guides/learning-network-debug.md` - Network Debugging learning path (dig -> connectivity -> traceroute -> hping3 -> curl -> tshark)
- `site/src/content/docs/guides/lab-walkthrough.md` - Enhanced with 10 Starlight asides (3 tips, 2 cautions, 3 notes, 1 danger, 1 tip with title)
- `USECASES.md` - Added note linking to documentation site task index page

## Decisions Made
- Sidebar ordering places task-index at 3 (after getting-started and lab-walkthrough) and learning paths at 10-12 (grouped together but after core guides)
- Learning path steps include specific `make` commands for immediate hands-on practice rather than generic instructions
- Each learning path step explains WHY it comes in that position in the sequence, not just WHAT the tool does

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- All guide pages in place for Phase 6 Plan 3 (CI docs-completeness validation)
- Site builds successfully with 29 pages including all new content
- Sidebar navigation correctly groups and orders all guide pages
- Cross-references between learning paths, tool pages, and diagnostic pages are complete

## Self-Check: PASSED

- FOUND: site/src/content/docs/guides/task-index.md
- FOUND: site/src/content/docs/guides/learning-recon.md
- FOUND: site/src/content/docs/guides/learning-webapp.md
- FOUND: site/src/content/docs/guides/learning-network-debug.md
- FOUND: .planning/phases/06-site-polish-and-learning-paths/06-02-SUMMARY.md
- FOUND: commit e58c99f (Task 1)
- FOUND: commit 7aff342 (Task 2)

---
*Phase: 06-site-polish-and-learning-paths*
*Completed: 2026-02-10*
