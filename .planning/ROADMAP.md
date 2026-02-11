# Roadmap: Networking Tools

## Milestones

- [x] **v1.0 Networking Tools Expansion** - Phases 1-7 (shipped 2026-02-11)
- [ ] **v1.1 Site Visual Refresh** - Phases 8-11 (in progress)

## Phases

<details>
<summary>v1.0 Networking Tools Expansion (Phases 1-7) - SHIPPED 2026-02-11</summary>

Archived to `.planning/milestones/v1.0-ROADMAP.md`

7 phases, 19 plans, 47 tasks completed in 2 days.

</details>

### v1.1 Site Visual Refresh

**Milestone Goal:** Transform the documentation site from default Starlight into a polished, branded pentesting toolkit with a dark + orange/amber theme, custom logo, redesigned homepage, and cleaned-up navigation.

**Phase Numbering:**
- Integer phases (8, 9, 10, 11): Planned milestone work
- Decimal phases (e.g., 9.1): Urgent insertions (marked with INSERTED)

- [x] **Phase 8: Theme Foundation** - Dark + orange/amber accent palette with light mode support (completed 2026-02-11)
- [x] **Phase 9: Brand Identity** - Custom SVG logo and matching favicon (completed 2026-02-11)
- [x] **Phase 10: Navigation Cleanup** - Remove redundant sidebar index entries (completed 2026-02-11)
- [ ] **Phase 11: Homepage Redesign** - Hero section, tool card grid, feature highlights, and guide links

## Phase Details

### Phase 8: Theme Foundation
**Goal**: Site displays a cohesive dark + orange/amber visual identity across all pages and components
**Depends on**: Nothing (foundation for all visual work)
**Requirements**: THEME-01, THEME-02, THEME-03
**Success Criteria** (what must be TRUE):
  1. All UI accent elements (links, sidebar highlights, buttons, focus rings, badges) render in orange/amber tones in dark mode
  2. Light mode accent colors are visible and readable against white/light backgrounds (no invisible orange-on-white links)
  3. Code blocks on tool documentation pages remain readable -- syntax highlighting has adequate contrast against the themed background
  4. Existing pages with Tabs components (tool install instructions) render correctly with the new palette
**Plans**: 1 plan

Plans:
- [x] 08-01-PLAN.md -- Orange/amber CSS custom property overrides and config registration

### Phase 9: Brand Identity
**Goal**: Site header and browser tab display a recognizable project-specific brand instead of generic Starlight defaults
**Depends on**: Phase 8 (logo colors must work against the themed header)
**Requirements**: BRAND-01, BRAND-02
**Success Criteria** (what must be TRUE):
  1. Site header displays a custom SVG logo that reflects a technical/hacker aesthetic (not generic placeholder)
  2. Logo renders correctly at nav bar height (32-40px) in both dark and light modes without becoming invisible
  3. Browser tab shows a project-specific favicon that matches the logo identity (not the default Starlight rocket)
**Plans**: 1 plan

Plans:
- [x] 09-01-PLAN.md -- Terminal-prompt SVG logo, favicon, and Astro config registration

### Phase 10: Navigation Cleanup
**Goal**: Sidebar navigation shows only meaningful page links without redundant section headers
**Depends on**: Phase 8 (sidebar styling affected by theme)
**Requirements**: NAV-01
**Success Criteria** (what must be TRUE):
  1. Sidebar groups for Tools, Guides, and Diagnostics no longer show a redundant index entry within their own group
  2. All existing documentation pages remain reachable from the sidebar (no pages lost by cleanup)
**Plans**: 1 plan

Plans:
- [x] 10-01-PLAN.md -- Add sidebar.hidden frontmatter to section index pages

### Phase 11: Homepage Redesign
**Goal**: Homepage serves as a compelling entry point that showcases the full toolkit and guides visitors to what they need
**Depends on**: Phase 8 (card styling requires theme), Phase 9 (hero uses logo image)
**Requirements**: BRAND-03, HOME-01, HOME-02, HOME-03
**Success Criteria** (what must be TRUE):
  1. Homepage hero section displays the project logo with a refined tagline that communicates the project's value proposition
  2. Homepage shows a card grid of all 18 tools organized by category (Security Tools, Networking Tools, Diagnostics)
  3. Homepage displays feature highlight cards (tool count, use-case scripts, Docker lab, diagnostics) that convey project scope at a glance
  4. Homepage includes clickable links to guides and learning paths below the tool grid
  5. Homepage layout is responsive -- usable on mobile (375px), tablet (768px), and desktop (1440px+)
**Plans**: 1 plan

Plans:
- [ ] 11-01-PLAN.md -- Homepage MDX rewrite with hero, feature cards, tool grids, and guide links

## Progress

**Execution Order:**
Phases execute in numeric order: 8 -> 9 -> 10 -> 11

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 8. Theme Foundation | v1.1 | 1/1 | Complete | 2026-02-11 |
| 9. Brand Identity | v1.1 | 1/1 | Complete | 2026-02-11 |
| 10. Navigation Cleanup | v1.1 | 1/1 | Complete | 2026-02-11 |
| 11. Homepage Redesign | v1.1 | 0/1 | Not started | - |
