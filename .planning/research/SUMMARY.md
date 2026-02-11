# Research Summary: Visual Refresh Milestone

**Domain:** Documentation site visual refresh (Astro/Starlight)
**Researched:** 2026-02-11
**Overall confidence:** HIGH

## Executive Summary

The visual refresh for the networking-tools documentation site requires zero new npm packages. Everything needed -- custom theming, logo support, card-based homepage layout, and sidebar cleanup -- ships with the already-installed Astro 5.17.1 and @astrojs/starlight 0.37.6. The work is entirely configuration changes, one CSS file, one SVG asset, and converting one Markdown file to MDX.

Starlight provides a comprehensive CSS custom property system for theming. The orange/amber dark-mode palette requires overriding 6-10 CSS variables (accent-low/accent/accent-high for both dark and light modes, plus optional gray scale adjustments). These overrides are registered via a single `customCss` entry in `astro.config.mjs` and propagate automatically to all components -- links, sidebar highlights, buttons, badges, cards, and focus rings. No element-level CSS selectors needed. No cascade specificity battles. Unlayered custom CSS automatically wins over Starlight's cascade layers by design.

For the logo, Starlight accepts an SVG file via the `logo.src` configuration option and renders it as an `<img>` tag in the nav bar. This means SVGs cannot use `currentColor` to inherit theme colors -- explicit colors must be baked in. If different colors are needed for dark and light modes, Starlight supports separate `light`/`dark` SVG variants. For the card-based homepage, Starlight ships built-in `Card`, `CardGrid`, and `LinkCard` components that handle responsive layout, theme integration, and accessibility. Converting the existing `index.md` to `index.mdx` enables importing these components. The sidebar cleanup uses `sidebar: { hidden: true }` frontmatter to remove redundant section index entries, and `sidebar: { order: N }` for custom ordering.

The primary risks are: (1) CSS selector scope errors causing cascade layer conflicts with Starlight's built-in components, (2) forgetting to define light mode accent colors alongside dark mode (orange/amber on white has poor contrast without adjustment), (3) MDX component `href` props not auto-prepending the `/networking-tools/` base path, and (4) the logo SVG using `currentColor` and rendering as invisible. All are preventable with awareness and testing.

## Key Findings

**Stack:** Zero new dependencies. CSS custom properties for theming, built-in Card/CardGrid/LinkCard for homepage, SVG file for logo. All verified against installed Starlight 0.37.6 and Astro 5.17.1.

**Architecture:** Three new files (custom.css, logo.svg, index.mdx replacing index.md), one modified config (astro.config.mjs), three modified frontmatter files (section index pages). No component overrides needed.

**Critical pitfall:** CSS overrides must target only custom properties (`:root` / `:root[data-theme='light']`), never bare element selectors. Unlayered CSS unconditionally wins over Starlight's layered CSS, so a bare `a {}` would break navigation, sidebar, cards, and tabs across all 30 pages simultaneously.

## Implications for Roadmap

Based on research, the visual refresh should be structured as a single milestone with parallel-capable phases. The total scope is small (under 10 files changed) but the CSS theme must be validated against all 30 existing pages before other changes build on top.

1. **Phase: CSS Theme** - Foundation for everything visual
   - Addresses: Custom accent colors (orange/amber), darker gray scale, dark and light mode support
   - Avoids: Cascade layer conflicts (Pitfall 1), light mode contrast failures (Pitfall 2)
   - Creates: `site/src/styles/custom.css`, modifies `astro.config.mjs`
   - Validation: Check existing tool MDX pages with Tabs components, sidebar navigation, code blocks

2. **Phase: Logo and Favicon** - Brand identity (parallelizable with Phase 1)
   - Addresses: SVG logo in header, matching favicon
   - Avoids: currentColor on `<img>` tags (Pitfall: logo invisible), base path favicon 404
   - Creates: `site/src/assets/logo.svg`, replaces `site/public/favicon.svg`, modifies `astro.config.mjs`
   - Validation: Test at 32px and 40px heights, verify both dark and light mode visibility

3. **Phase: Sidebar Cleanup** - Navigation polish (parallelizable with Phases 1-2)
   - Addresses: Hidden section index pages, custom ordering, optional badges
   - Avoids: Duplicate sidebar entries, mixed explicit/alphabetical ordering confusion
   - Modifies: 3 index.md frontmatter files, optionally tool page frontmatter for ordering
   - Validation: Sidebar no longer shows redundant entries, tools in logical order

4. **Phase: Homepage Redesign** - The payoff (depends on Phase 1 for visual evaluation)
   - Addresses: Card-based layout with tool grid, feature highlights, refined hero
   - Avoids: Splash template width issues (Pitfall 4), base path in href props (Pitfall 3)
   - Creates: `site/src/content/docs/index.mdx` (replacing `index.md`)
   - Deletes: `site/src/assets/houston.webp` (unused placeholder)
   - Validation: Test at mobile (375px), tablet (768px), desktop (1440px), ultra-wide (2560px)

**Phase ordering rationale:**
- CSS theme is foundational because every subsequent visual change is evaluated against the theme. A blue-accented card grid cannot be properly assessed for an orange/amber site.
- Logo and sidebar are independent of each other and can parallel the theme work.
- Homepage redesign depends on the theme being in place to evaluate card styling, and benefits from having the logo ready for the hero image.
- All phases can be completed in a single milestone. No phase requires deep research during execution -- all patterns are documented and verified.

**Research flags for phases:**
- Phase 1 (CSS Theme): Standard pattern, no research needed. Reference the `props.css` variable list in STACK.md.
- Phase 2 (Logo): Logo design is a creative task, not a technical research task. SVG constraints documented in STACK.md.
- Phase 3 (Sidebar): Standard Starlight configuration. No research needed.
- Phase 4 (Homepage): Standard MDX with built-in components. The only subtlety is base path in href props.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Zero new packages. All capabilities verified against installed `node_modules/` source code and official Starlight docs. |
| Features | HIGH | Built-in Card/CardGrid/LinkCard components verified in official docs. Icon names verified. Sidebar options verified. |
| Architecture | HIGH | CSS cascade layer system verified by reading `props.css` and `layers.css` directly. Component override mechanism verified in Starlight source. |
| Pitfalls | HIGH | Critical pitfalls verified by reading Starlight source code (SiteTitle.astro renders `<img>`, props.css selector structure). Cascade layer behavior confirmed by CSS specification. |

## Gaps to Address

- **Exact orange/amber HSL values:** The research provides example values and the variable system, but the final palette requires visual tuning during implementation. Use Starlight's interactive color theme editor on their docs site to generate precise values.
- **Logo design:** The research documents all technical constraints (rendered as `<img>`, height 32-40px, explicit colors needed) but the actual logo design is a creative task outside research scope.
- **Expressive Code theme interaction:** Default code block themes should work with the new accent colors via `useStarlightUiThemeColors`. But the exact visual result needs validation during implementation. If code blocks look off, the `expressiveCode.styleOverrides` config is documented in STACK.md as a fallback.
- **Section index page strategy:** Should the hidden index pages be repurposed as card-based section landing pages (converting to MDX with CardGrid)? This is a content/UX decision, not a technical one. The research documents both approaches (hide vs. repurpose with distinct label).
