# Requirements: Networking Tools — Site Visual Refresh

**Defined:** 2026-02-11
**Core Value:** Ready-to-run scripts and accessible documentation that eliminate the need to remember tool flags and configurations — run one command, get what you need.

## v1.1 Requirements

Requirements for site visual refresh. Each maps to roadmap phases.

### Branding

- [ ] **BRAND-01**: Site displays a custom SVG logo in the header that reflects the project's technical/hacker identity
- [ ] **BRAND-02**: Browser tab shows a project-specific favicon matching the logo identity
- [ ] **BRAND-03**: Homepage hero section displays the logo image with a refined, punchy tagline

### Theme

- [ ] **THEME-01**: Site uses a dark + orange/amber accent color palette across all UI elements (links, sidebar, buttons, focus rings)
- [ ] **THEME-02**: Light mode accent colors are defined with adequate contrast (not just dark mode)
- [ ] **THEME-03**: Code blocks remain readable with adequate syntax highlighting contrast against the new theme

### Homepage

- [ ] **HOME-01**: Homepage displays a card grid of all 18 tools organized by category (Security Tools, Networking Tools, etc.)
- [ ] **HOME-02**: Homepage shows feature highlight cards (tool count, use-case scripts, Docker lab, diagnostics)
- [ ] **HOME-03**: Homepage includes guide and learning path links below the tool grid

### Navigation

- [ ] **NAV-01**: Sidebar no longer shows redundant "Tools", "Guides", and "Diagnostics" index entries within their respective groups

## Future Requirements

Deferred to future milestone. Tracked but not in current roadmap.

### Visual Polish

- **VPOL-01**: Dark-mode-only enforcement (remove light/dark toggle)
- **VPOL-02**: Section overview cards on tools/guides/diagnostics index pages
- **VPOL-03**: Sidebar group icons (terminal, open-book, setting)
- **VPOL-04**: Category badges on tool cards (Offensive/Defensive/Networking)

## Out of Scope

| Feature | Reason |
|---------|--------|
| Custom React/Svelte interactive components | Zero-JS static site — Starlight built-in components cover needs |
| Tailwind CSS integration | Starlight's CSS custom properties handle theming; Tailwind adds unnecessary complexity |
| Custom search UI | Starlight's Pagefind search works well out of the box |
| Animated backgrounds or particle effects | Accessibility issues, performance cost, distracts from content |
| Custom font loading | System font stack is fast and readable; web fonts add FOUT |
| Multi-page homepage | Single splash template is sufficient; two entry points confuse navigation |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| BRAND-01 | — | Pending |
| BRAND-02 | — | Pending |
| BRAND-03 | — | Pending |
| THEME-01 | — | Pending |
| THEME-02 | — | Pending |
| THEME-03 | — | Pending |
| HOME-01 | — | Pending |
| HOME-02 | — | Pending |
| HOME-03 | — | Pending |
| NAV-01 | — | Pending |

**Coverage:**
- v1.1 requirements: 10 total
- Mapped to phases: 0
- Unmapped: 10 ⚠️

---
*Requirements defined: 2026-02-11*
*Last updated: 2026-02-11 after initial definition*
