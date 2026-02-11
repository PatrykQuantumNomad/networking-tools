---
phase: 11-homepage-redesign
plan: 01
subsystem: ui
tags: [starlight, mdx, homepage, hero, cards, linkcard, css]

# Dependency graph
requires:
  - phase: 09-brand-identity
    provides: logo-dark.svg and logo-light.svg assets for hero image
  - phase: 04-content-migration-and-tool-pages
    provides: all tool pages (17) with correct slugs
  - phase: 06-site-polish-and-learning-paths
    provides: guide and learning path pages (6)
  - phase: 03-diagnostic-scripts
    provides: diagnostic pages (3) with correct slugs
provides:
  - Redesigned homepage with branded hero, feature highlights, and categorized card grids
  - Homepage section spacing CSS for splash pages with hero frontmatter
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Starlight Card/CardGrid/LinkCard components for structured landing pages"
    - "MDX for homepage to enable component imports"
    - "[data-has-hero] CSS selector for splash-page-specific styling"

key-files:
  created: []
  modified:
    - site/src/content/docs/index.mdx
    - site/src/styles/custom.css

key-decisions:
  - "Converted index.md to index.mdx to enable Starlight component imports"
  - "Used git mv for file rename to preserve git history"
  - "Section separator CSS uses [data-has-hero] scoping to avoid affecting non-splash pages"

patterns-established:
  - "Homepage card grid pattern: h2 section heading followed by CardGrid with LinkCards"
  - "[data-has-hero] as CSS scope for splash-page-only styles"

# Metrics
duration: 2min
completed: 2026-02-11
---

# Phase 11 Plan 01: Homepage Redesign Summary

**Starlight component-based homepage with branded hero, 4 feature cards, 17 tool LinkCards, 3 diagnostic LinkCards, and 6 guide LinkCards**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-11T15:52:53Z
- **Completed:** 2026-02-11T15:55:21Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Replaced minimal markdown homepage with full MDX landing page using Starlight Card/CardGrid/LinkCard components
- Hero section displays project logo (dark/light variants) with punchy tagline "Pentesting scripts and diagnostics. Ready to run."
- All 17 tools organized into Security Tools (13) and Networking Tools (4) card grids with correct base-path-prefixed hrefs
- 3 diagnostic pages and 6 guide/learning path pages linked via dedicated card grid sections
- Homepage section spacing CSS scoped to splash pages via [data-has-hero] selector

## Task Commits

Each task was committed atomically:

1. **Task 1: Convert homepage to MDX and build full landing page content** - `4d79c0e` (feat)
2. **Task 2: Add homepage section spacing CSS and verify full build** - `ad0bcb6` (style)

## Files Created/Modified

- `site/src/content/docs/index.mdx` - Full homepage with hero, feature highlights, tool/diagnostic/guide card grids (renamed from index.md)
- `site/src/styles/custom.css` - Added [data-has-hero] section spacing rules for splash pages

## Decisions Made

- Converted index.md to index.mdx using `git mv` to preserve history while enabling JSX component imports
- Used [data-has-hero] CSS selector (set by Starlight on splash pages) to scope section spacing rules, avoiding impact on regular content pages
- First h2 after hero has no border-top for clean visual flow from hero to content

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Homepage redesign complete with all planned sections
- All links verified working via successful Astro build (31 pages, 0 errors)
- Ready for visual verification in browser

## Self-Check: PASSED

- [x] `site/src/content/docs/index.mdx` exists
- [x] `site/src/styles/custom.css` exists
- [x] `11-01-SUMMARY.md` exists
- [x] Commit `4d79c0e` (Task 1) found
- [x] Commit `ad0bcb6` (Task 2) found

---
*Phase: 11-homepage-redesign*
*Completed: 2026-02-11*
