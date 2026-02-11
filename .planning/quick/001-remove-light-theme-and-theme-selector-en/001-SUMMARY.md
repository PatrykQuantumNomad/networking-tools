---
phase: quick-001
plan: 01
subsystem: ui
tags: [starlight, css, theming, dark-mode, svg]

# Dependency graph
requires:
  - phase: 08-theme-foundation
    provides: Orange/amber accent theme with dark and light mode overrides
  - phase: 09-brand-identity
    provides: Logo SVGs (dark/light variants) and favicon with color-scheme detection
provides:
  - Dark-mode-only site with no theme toggle
  - Single logo source (logo-dark.svg) used everywhere
  - Amber-only favicon with no media queries
affects: [site-theme, site-config]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Force dark mode via inline head script in astro.config.mjs"
    - "Hide Starlight UI components via custom element display:none"

key-files:
  created: []
  modified:
    - site/astro.config.mjs
    - site/src/styles/custom.css
    - site/public/favicon.svg

key-decisions:
  - "Force dark theme via head script rather than Starlight config option"
  - "Hide theme toggle with CSS display:none rather than component override"

patterns-established:
  - "Dark-mode-only: all future theme work assumes dark mode; no light mode variables needed"

# Metrics
duration: 2min
completed: 2026-02-11
---

# Quick 001: Remove Light Theme and Theme Selector Summary

**Dark-mode-only enforcement via head script, CSS toggle hide, and amber-only favicon/logo**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-11T16:35:58Z
- **Completed:** 2026-02-11T16:38:38Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments
- Forced dark mode via inline head script that sets `data-theme="dark"` before Starlight renders
- Removed all light mode CSS variable overrides from custom.css
- Hidden the theme toggle widget via `starlight-theme-select { display: none !important }`
- Simplified favicon to hardcoded amber (#f5c97a) with no prefers-color-scheme media query
- Consolidated logo to single dark variant (removed dual dark/light config)

## Task Commits

Each task was committed atomically:

1. **Task 1: Force dark mode and use single logo in Astro config** - `0487d66` (feat)
2. **Task 2: Remove light theme CSS and hide theme toggle** - `610bc3b` (feat)
3. **Task 3: Simplify favicon to always use amber color** - `41a0323` (feat)

## Files Created/Modified
- `site/astro.config.mjs` - Single logo source, head script forcing dark mode
- `site/src/styles/custom.css` - Removed light mode block, added theme toggle hide rule
- `site/public/favicon.svg` - Hardcoded amber strokes, removed style/media query block

## Decisions Made
- **Force dark via head script:** Used an inline `<script>` in Starlight's `head` config to set `data-theme="dark"` on the `<html>` element before render. This prevents any flash of light mode and works regardless of localStorage state.
- **CSS hide over component override:** Used `display: none !important` on the `starlight-theme-select` custom element rather than creating a component override. Simpler, less maintenance, and appropriate for permanently removing UI.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Steps
- The `logo-light.svg` file in `site/src/assets/` is now unused and could be removed in a future cleanup task
- Site is permanently dark-mode-only; future theme work only needs to consider dark backgrounds

## Self-Check: PASSED

All 3 modified files exist on disk. All 3 task commits verified in git log.

---
*Plan: quick-001*
*Completed: 2026-02-11*
