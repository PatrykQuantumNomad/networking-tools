# Architecture Patterns

**Domain:** Starlight site visual refresh (custom theme, logo, homepage redesign, sidebar cleanup)
**Researched:** 2026-02-11
**Confidence:** HIGH (all findings verified against official Starlight documentation)

## Existing Site Architecture (Baseline)

```
site/
  astro.config.mjs           # Starlight integration config (title, social, sidebar)
  package.json                # astro ^5.6.1, @astrojs/starlight ^0.37.6, sharp
  public/
    favicon.svg               # Generic starburst SVG (default Starlight icon)
  src/
    content.config.ts          # Standard docsLoader + docsSchema
    assets/
      houston.webp             # Unused placeholder image
    content/docs/
      index.md                 # Homepage (template: splash, hero, markdown body)
      tools/
        index.md               # Section index ("Tools" description)
        nmap.mdx               # 17 .mdx tool pages using Tabs component
        ...
      guides/
        index.md               # Section index ("Guides" description)
        getting-started.md     # 5 .md guide pages
        ...
      diagnostics/
        index.md               # Section index ("Diagnostics" description)
        dns.md                 # 3 .md diagnostic pages
        ...
```

**Key architectural observations:**

1. **No custom CSS exists.** The site uses 100% default Starlight styling (blue accent, standard grays).
2. **No `src/styles/` directory.** Needs to be created.
3. **No `src/components/` directory.** Needs to be created for any custom Astro components.
4. **Homepage is `.md` not `.mdx`.** Cannot import components in its current form. Must be converted to `.mdx` to use Card/CardGrid/LinkCard.
5. **Section index pages appear in sidebar.** Each `tools/index.md`, `guides/index.md`, `diagnostics/index.md` shows up as a sidebar entry alongside the actual content pages. These are redundant because the sidebar group label already serves as the section header.
6. **Sidebar uses autogenerate only.** No manual entries, no badges, no custom ordering beyond per-page `sidebar.order` frontmatter.
7. **Favicon is a generic starburst.** Needs replacement with a project-specific SVG.
8. **Logo is not configured.** Only the text title "Networking Tools" appears in the header.

## Target Architecture (After Visual Refresh)

```
site/
  astro.config.mjs            # MODIFIED: +logo, +customCss, sidebar tweaks
  public/
    favicon.svg                # REPLACED: new project-specific SVG
  src/
    styles/                    # NEW DIRECTORY
      custom.css               # NEW: CSS custom properties for dark+orange theme
    assets/
      logo.svg                 # NEW: SVG logo for site header
    components/                # NEW DIRECTORY (only if Hero override needed)
      ToolGrid.astro           # NEW: custom component for homepage tool cards
    content/docs/
      index.mdx                # RENAMED .md -> .mdx: uses CardGrid, LinkCard
      tools/
        index.md               # MODIFIED: +sidebar.hidden frontmatter
        ...
      guides/
        index.md               # MODIFIED: +sidebar.hidden frontmatter
        ...
      diagnostics/
        index.md               # MODIFIED: +sidebar.hidden frontmatter
        ...
```

## Component Boundaries

| Component | Responsibility | Integration Point |
|-----------|---------------|-------------------|
| `astro.config.mjs` | Central configuration hub | Starlight integration options |
| `src/styles/custom.css` | Color theme (accent, grays, dark mode) | `customCss` array in config |
| `src/assets/logo.svg` | Site header branding | `logo.src` in config |
| `public/favicon.svg` | Browser tab icon | `favicon` in config (default path) |
| `src/content/docs/index.mdx` | Homepage content + component imports | Starlight content pipeline |
| Section `index.md` files | Hidden from sidebar, still serve as landing pages | `sidebar.hidden` frontmatter |

## Integration Point 1: Custom CSS Theme

**Mechanism:** Starlight's `customCss` configuration option.

**How it works:** Starlight uses CSS custom properties (design tokens) for all colors. Custom CSS files registered in `customCss` are loaded after Starlight's defaults. Any unlayered CSS overrides Starlight's styles without needing `!important` because Starlight uses cascade layers internally.

**File:** `site/src/styles/custom.css`

**Config change in `astro.config.mjs`:**

```javascript
starlight({
  // ... existing options
  customCss: [
    './src/styles/custom.css',
  ],
})
```

**CSS custom properties to override (dark + orange/amber theme):**

```css
/* Dark theme (Starlight default is already dark-first) */
:root {
  /* Accent: orange/amber palette */
  --sl-color-accent-low: hsl(25, 60%, 15%);      /* dark orange bg */
  --sl-color-accent: hsl(30, 90%, 55%);           /* primary orange */
  --sl-color-accent-high: hsl(35, 95%, 80%);      /* light orange text */

  /* Gray scale: customize for darker background */
  --sl-color-gray-1: hsl(220, 10%, 90%);
  --sl-color-gray-2: hsl(220, 10%, 72%);
  --sl-color-gray-3: hsl(220, 8%, 50%);
  --sl-color-gray-4: hsl(220, 10%, 28%);
  --sl-color-gray-5: hsl(220, 14%, 16%);
  --sl-color-gray-6: hsl(220, 20%, 10%);

  /* Semantic (derived from above but can be set directly) */
  --sl-color-white: hsl(0, 0%, 95%);
  --sl-color-black: hsl(220, 20%, 6%);
}

/* Light theme overrides if needed */
:root[data-theme='light'] {
  --sl-color-accent-low: hsl(35, 80%, 88%);
  --sl-color-accent: hsl(30, 85%, 45%);
  --sl-color-accent-high: hsl(25, 70%, 20%);

  --sl-color-gray-1: hsl(220, 10%, 18%);
  --sl-color-gray-2: hsl(220, 8%, 30%);
  --sl-color-gray-3: hsl(220, 6%, 50%);
  --sl-color-gray-4: hsl(220, 8%, 72%);
  --sl-color-gray-5: hsl(220, 10%, 88%);
  --sl-color-gray-6: hsl(220, 12%, 95%);

  --sl-color-white: hsl(220, 14%, 10%);
  --sl-color-black: hsl(0, 0%, 98%);
}
```

**Confidence:** HIGH. The `customCss` config option and CSS custom property names are documented in official Starlight docs. The cascade layer behavior (unlayered CSS overrides Starlight layers) is explicitly stated.

**Source:** [CSS & Styling - Astro Starlight](https://starlight.astro.build/guides/css-and-tailwind/)

## Integration Point 2: SVG Logo

**Mechanism:** Starlight's `logo` configuration option.

**How it works:** The `logo` config accepts a `src` path pointing to an image file in `src/assets/`. The image is processed by Astro's image pipeline. Setting `replacesTitle: false` (default) shows both logo and text title. Setting `replacesTitle: true` hides the text title visually but keeps it for screen readers.

For an SVG that should look correct in both dark and light modes, use the `light` and `dark` variant properties instead of `src`, OR design a single SVG with colors that work on both backgrounds.

**File:** `site/src/assets/logo.svg` (new file)

**Config change in `astro.config.mjs`:**

```javascript
starlight({
  title: 'Networking Tools',
  logo: {
    src: './src/assets/logo.svg',
    // replacesTitle: true,  // uncomment if logo includes text
  },
  // ... rest of config
})
```

**Alternative for dark/light variants:**

```javascript
logo: {
  light: './src/assets/logo-light.svg',
  dark: './src/assets/logo-dark.svg',
  alt: 'Networking Tools',
},
```

**Favicon:** Replace `site/public/favicon.svg` with the new SVG. No config change needed because the default `favicon` config already points to `/favicon.svg`.

**Confidence:** HIGH. Logo config documented in [Customizing Starlight](https://starlight.astro.build/guides/customization/) and [Configuration Reference](https://starlight.astro.build/reference/configuration/).

## Integration Point 3: Homepage Redesign

**Mechanism:** Convert `index.md` to `index.mdx` and import Starlight's built-in Card/CardGrid/LinkCard components.

**Why `.mdx` is required:** Standard `.md` files cannot import or render components. MDX enables JSX-like component usage within markdown content. This is Starlight's official approach for rich content pages.

**File:** `site/src/content/docs/index.mdx` (rename from `index.md`)

**Approach A (Recommended): Built-in components only**

Use Starlight's `Card`, `CardGrid`, and `LinkCard` components. No custom components needed. This is the simplest approach and stays within Starlight's supported patterns.

```mdx
---
title: Networking Tools
description: Pentesting and network diagnostic learning lab
template: splash
hero:
  tagline: Ready-to-run scripts and documentation for 17+ security and networking tools.
  image:
    file: ~/assets/logo.svg
  actions:
    - text: Get Started
      link: /networking-tools/guides/getting-started/
      icon: right-arrow
    - text: View on GitHub
      link: https://github.com/PatrykQuantumNomad/networking-tools
      icon: external
      variant: minimal
---

import { Card, CardGrid, LinkCard } from '@astrojs/starlight/components';

## Security Tools

<CardGrid>
  <LinkCard title="Nmap" description="Network discovery and port scanning" href="/networking-tools/tools/nmap/" />
  <LinkCard title="SQLMap" description="SQL injection detection and exploitation" href="/networking-tools/tools/sqlmap/" />
  <LinkCard title="Nikto" description="Web server vulnerability scanning" href="/networking-tools/tools/nikto/" />
  <LinkCard title="Metasploit" description="Penetration testing framework" href="/networking-tools/tools/metasploit/" />
</CardGrid>

## Features

<CardGrid stagger>
  <Card title="17 Tool References" icon="open-book">
    Comprehensive docs for each tool with flags, examples, and use-case scripts.
  </Card>
  <Card title="28 Use-Case Scripts" icon="rocket">
    Task-focused scripts for common pentest scenarios -- just run and learn.
  </Card>
  <Card title="Docker Practice Lab" icon="laptop">
    DVWA, Juice Shop, WebGoat, and VulnerableApp for safe hands-on practice.
  </Card>
  <Card title="Network Diagnostics" icon="setting">
    Auto-report scripts for DNS, connectivity, and performance troubleshooting.
  </Card>
</CardGrid>
```

**Approach B (If more control needed): Custom Astro component**

Create a custom component at `site/src/components/ToolGrid.astro` and import it in the MDX. This gives full control over HTML/CSS but adds maintenance surface.

```astro
---
// site/src/components/ToolGrid.astro
const tools = [
  { name: 'Nmap', desc: 'Network discovery', href: '/networking-tools/tools/nmap/', category: 'recon' },
  // ...
];
---
<div class="tool-grid">
  {tools.map(tool => (
    <a href={tool.href} class={`tool-card ${tool.category}`}>
      <h3>{tool.name}</h3>
      <p>{tool.desc}</p>
    </a>
  ))}
</div>
<style>
  .tool-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 1rem; }
  .tool-card { /* custom styles */ }
</style>
```

**Recommendation:** Use Approach A (built-in components). It requires zero custom component code, integrates with the theme automatically, and is maintainable. Only move to Approach B if the built-in cards are visually insufficient after theming.

**Hero image:** The `hero.image.file` frontmatter accepts a path like `~/assets/logo.svg` (Starlight's alias for `src/assets/`). This renders the logo large on the splash page alongside the tagline. Alternatively, `hero.image.html` accepts raw HTML/SVG for inline rendering.

**Confidence:** HIGH. Built-in component imports documented at [Card Grids](https://starlight.astro.build/components/card-grids/), [Cards](https://starlight.astro.build/components/cards/), [Link Cards](https://starlight.astro.build/components/link-cards/). MDX requirement documented at [Pages](https://starlight.astro.build/guides/pages/).

## Integration Point 4: Sidebar Cleanup (Hide Section Index Pages)

**Mechanism:** Starlight's `sidebar.hidden` frontmatter property.

**How it works:** Setting `sidebar: { hidden: true }` in a page's frontmatter prevents it from appearing in autogenerated sidebar groups. The page still exists and is accessible via direct URL, but it does not clutter the sidebar.

**Files to modify:**

1. `site/src/content/docs/tools/index.md`
2. `site/src/content/docs/guides/index.md`
3. `site/src/content/docs/diagnostics/index.md`

**Change for each:**

```yaml
---
title: Tools
description: Security and networking tool references
sidebar:
  hidden: true
---
```

**Current behavior:** The `index.md` in each directory appears as a sidebar entry labeled "Tools" (or "Guides", "Diagnostics") within its own group. This is redundant because the autogenerated sidebar group already has a label.

**After change:** The sidebar group header "Tools" remains (from `astro.config.mjs` sidebar config), but the `index.md` page no longer appears as a clickable entry within the group. Users see only the actual tool/guide/diagnostic pages.

**Alternative considered:** Delete the index files entirely. Rejected because they serve as valid landing pages when users click the group label or navigate directly, and they provide section-level descriptions.

**Confidence:** HIGH. The `sidebar.hidden` frontmatter is documented in [Frontmatter Reference](https://starlight.astro.build/reference/frontmatter/) and [Sidebar Navigation](https://starlight.astro.build/guides/sidebar/).

## Integration Point 5: Component Overrides (Optional, Future)

**Mechanism:** Starlight's `components` configuration option.

**When to use:** Only if the built-in Hero component or other components need structural changes beyond CSS theming. For this visual refresh, component overrides are likely unnecessary.

**Available overrides relevant to this project:**

| Component | Purpose | When to Override |
|-----------|---------|-----------------|
| `Hero` | Splash page hero section | If hero needs custom layout beyond frontmatter options |
| `SiteTitle` | Header site title/logo area | If logo needs complex rendering (unlikely) |
| `Header` | Full header bar | If header needs structural changes |
| `Footer` | Page footer | If adding custom footer content |
| `ContentPanel` | Main content wrapper | Unlikely for visual refresh |

**How to override (if needed):**

```javascript
// astro.config.mjs
starlight({
  components: {
    Hero: './src/components/CustomHero.astro',
  },
})
```

**Custom component pattern:**

```astro
---
// src/components/CustomHero.astro
// Access page data via Astro.locals.starlightRoute
const { data } = Astro.locals.starlightRoute.entry;
const isHomepage = Astro.locals.starlightRoute.id === '';

// Import default to use on non-homepage pages
import DefaultHero from '@astrojs/starlight/components/Hero.astro';
---
{isHomepage ? (
  <div class="custom-hero">
    <!-- custom homepage hero HTML -->
  </div>
) : (
  <DefaultHero><slot /></DefaultHero>
)}
```

**Recommendation:** Do NOT override components for the initial visual refresh. CSS theming + built-in components + MDX homepage should achieve the desired result. Reserve component overrides for a future iteration if specific structural changes are needed.

**Confidence:** HIGH. Component override mechanism documented at [Overriding Components](https://starlight.astro.build/guides/overriding-components/) and [Overrides Reference](https://starlight.astro.build/reference/overrides/).

## Data Flow

```
astro.config.mjs
  |
  +-- logo.src ---------> src/assets/logo.svg -----> Header component (automatic)
  |
  +-- customCss --------> src/styles/custom.css ---> Applied to all pages (cascade layer override)
  |
  +-- sidebar config ---> Autogenerate from dirs --> sidebar.hidden filters index pages
  |
  +-- favicon ----------> public/favicon.svg ------> Browser tab (default path, no config needed)

src/content/docs/index.mdx
  |
  +-- frontmatter ------> hero config (image, tagline, actions)
  |
  +-- MDX body ---------> imports Card, CardGrid, LinkCard from @astrojs/starlight/components
                           Renders tool cards and feature highlights
```

## Patterns to Follow

### Pattern 1: CSS Custom Properties for Theming

**What:** Override Starlight's design tokens via CSS custom properties rather than writing new CSS rules.

**When:** Any time you want to change colors, spacing, or typography site-wide.

**Why:** Starlight's components all reference these tokens. Changing one property propagates everywhere. No selector specificity battles. Works with dark/light theme switching automatically.

```css
/* DO: Override the token */
:root {
  --sl-color-accent: hsl(30, 90%, 55%);
}

/* DON'T: Target specific selectors */
.starlight-aside a {
  color: orange !important;
}
```

### Pattern 2: Built-in Components Over Custom

**What:** Use `Card`, `CardGrid`, `LinkCard`, `Tabs`, `TabItem` from `@astrojs/starlight/components` before creating custom components.

**When:** Any time you need structured content (grids, cards, tabs, asides).

**Why:** Built-in components inherit the theme automatically, are responsive, and are maintained by the Starlight team. Custom components require manual theme integration and maintenance.

### Pattern 3: Single SVG for Logo and Favicon

**What:** Design one SVG that works at both large (header logo) and small (favicon) sizes. Use `currentColor` for theme-adaptive coloring.

**When:** Creating the project logo.

**Why:** Reduces design surface. `currentColor` inherits the text color from Starlight's theme, so the logo automatically adapts to dark/light mode without needing separate `light`/`dark` variants.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
  <path fill="currentColor" d="..." />
</svg>
```

**Caveat:** Favicons loaded from `public/` are not processed by Astro's image pipeline and do not inherit CSS `currentColor`. The favicon SVG should use a `<style>` block with `prefers-color-scheme` media query (like the current starburst favicon does) or use a fixed color that works on both light and dark browser chrome.

## Anti-Patterns to Avoid

### Anti-Pattern 1: Overriding Components for Cosmetic Changes

**What:** Using Starlight's `components` config to override `Hero`, `Header`, etc. just to change colors or spacing.

**Why bad:** Component overrides are powerful but create maintenance burden. When Starlight updates, your override may break. CSS custom properties handle 90% of visual changes without this risk.

**Instead:** Use `customCss` and CSS custom properties. Only override components when you need structural HTML changes.

### Anti-Pattern 2: Writing CSS Against Starlight's Internal Class Names

**What:** Targeting `.sl-markdown-content h2`, `.starlight-aside`, or other internal selectors.

**Why bad:** Internal class names can change between Starlight versions. These selectors are not part of the public API.

**Instead:** Use CSS custom properties for theming. For truly custom styling on specific pages, use scoped styles in custom `.astro` components or MDX-imported components.

### Anti-Pattern 3: Deleting Section Index Pages

**What:** Removing `tools/index.md`, `guides/index.md`, `diagnostics/index.md` to clean up the sidebar.

**Why bad:** These pages serve as landing pages for each section. Removing them means clicking the sidebar group heading leads nowhere (or 404s if linked externally).

**Instead:** Add `sidebar: { hidden: true }` to hide them from the sidebar while keeping them as valid, accessible pages.

### Anti-Pattern 4: Using `!important` in Custom CSS

**What:** Adding `!important` to override Starlight styles.

**Why bad:** Starlight uses cascade layers. Unlayered custom CSS already wins over layered Starlight CSS by default. Using `!important` is unnecessary and makes future overrides harder.

**Instead:** Just write normal CSS in your `customCss` file. It will override Starlight automatically.

## File Modification Summary

### New Files to Create

| File | Purpose | Dependencies |
|------|---------|-------------|
| `site/src/styles/custom.css` | Orange/amber color theme via CSS custom properties | None |
| `site/src/assets/logo.svg` | Site header logo (SVG) | None (design task) |

### Existing Files to Modify

| File | Change | Dependencies |
|------|--------|-------------|
| `site/astro.config.mjs` | Add `customCss`, `logo` config options | `custom.css` and `logo.svg` must exist |
| `site/public/favicon.svg` | Replace with project-specific SVG | None (design task) |
| `site/src/content/docs/index.md` | Rename to `index.mdx`, add component imports and CardGrid | `custom.css` for themed cards |
| `site/src/content/docs/tools/index.md` | Add `sidebar: { hidden: true }` frontmatter | None |
| `site/src/content/docs/guides/index.md` | Add `sidebar: { hidden: true }` frontmatter | None |
| `site/src/content/docs/diagnostics/index.md` | Add `sidebar: { hidden: true }` frontmatter | None |

### Files to Delete

| File | Reason |
|------|--------|
| `site/src/assets/houston.webp` | Unused placeholder, adds clutter |

## Suggested Build Order

The build order is driven by dependencies between the integration points.

```
Phase 1: CSS Theme (no dependencies)
  Create src/styles/custom.css
  Add customCss to astro.config.mjs
  Verify: dev server shows orange/amber theme

Phase 2: Logo + Favicon (no dependencies, can parallel Phase 1)
  Create src/assets/logo.svg
  Replace public/favicon.svg
  Add logo config to astro.config.mjs
  Verify: header shows logo, browser tab shows new icon

Phase 3: Sidebar Cleanup (no dependencies, can parallel Phase 1-2)
  Add sidebar.hidden to 3 index.md files
  Verify: sidebar no longer shows redundant index entries

Phase 4: Homepage Redesign (depends on Phase 1 for themed cards)
  Rename index.md -> index.mdx
  Add hero.image, CardGrid, LinkCard components
  Restructure content for visual browsing
  Delete unused houston.webp
  Verify: homepage shows hero image, tool grid, feature cards
```

**Why this order:**
- CSS theme is foundational -- every subsequent change looks better with the theme active, and you need it to evaluate whether built-in cards are visually sufficient.
- Logo and sidebar are independent of each other and the theme, so they can be done in parallel.
- Homepage redesign depends on the theme being in place to evaluate the visual result of Card/CardGrid components, and benefits from having the logo ready for the hero image.

## Scalability Considerations

| Concern | Current (17 tools) | At 30 tools | At 50+ tools |
|---------|--------------------|-----------|-----------|
| Homepage card grid | Manual LinkCard list in MDX | Still manageable | Consider generating from collection query |
| Sidebar length | Flat autogenerate works | May need subcategories | Need nested groups (recon, web, wireless, etc.) |
| CSS custom properties | Simple color override | Same approach | Same approach |
| Build time | Negligible (<5s) | Still fast | Astro handles hundreds of pages efficiently |

For now, manual LinkCard entries on the homepage are fine for 17 tools. If the tool count grows significantly, consider using Astro's `getCollection()` API to dynamically generate the tool grid from the content collection, eliminating the need to manually update the homepage when tools are added.

## Sources

- [CSS & Styling - Astro Starlight](https://starlight.astro.build/guides/css-and-tailwind/) -- customCss, CSS custom properties, cascade layers
- [Customizing Starlight](https://starlight.astro.build/guides/customization/) -- logo config, visual options
- [Configuration Reference](https://starlight.astro.build/reference/configuration/) -- all config options with types
- [Frontmatter Reference](https://starlight.astro.build/reference/frontmatter/) -- sidebar.hidden, template, hero config
- [Overriding Components](https://starlight.astro.build/guides/overriding-components/) -- component override mechanism
- [Overrides Reference](https://starlight.astro.build/reference/overrides/) -- full list of overridable components
- [Sidebar Navigation](https://starlight.astro.build/guides/sidebar/) -- autogenerate, hidden pages
- [Card Grids](https://starlight.astro.build/components/card-grids/) -- CardGrid component
- [Cards](https://starlight.astro.build/components/cards/) -- Card component with icons
- [Link Cards](https://starlight.astro.build/components/link-cards/) -- LinkCard component
- [Pages](https://starlight.astro.build/guides/pages/) -- .md vs .mdx, splash template
