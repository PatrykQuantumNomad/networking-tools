# Technology Stack: Visual Refresh

**Project:** networking-tools documentation site -- visual refresh milestone
**Researched:** 2026-02-11
**Scope:** Custom theming (dark+orange/amber), SVG logo, card-based homepage, sidebar cleanup

## Existing Stack (No Changes Required)

These are already installed and validated. Listed for context only.

| Technology | Version | Status |
|------------|---------|--------|
| Astro | 5.17.1 | Installed, stable |
| @astrojs/starlight | 0.37.6 | Installed, stable |
| sharp | 0.34.2 | Installed (image optimization) |
| Node.js | 22.x LTS | Runtime |
| GitHub Pages | - | Deployment target |

## New Additions Required

### Zero New npm Dependencies

The visual refresh requires **no new npm packages**. Everything needed ships with Astro 5.17.1 and Starlight 0.37.6.

| Capability | How | Why No Package Needed |
|------------|-----|----------------------|
| Custom color theme | CSS custom properties in `src/styles/custom.css` | Starlight exposes `--sl-color-accent-*` and `--sl-color-gray-*` variables. Override in a custom CSS file registered via `customCss` config. |
| SVG logo | Astro SVG component import (stable since 5.7) | `import Logo from './assets/logo.svg'` works natively. No `astro-icon` or other package needed. For Starlight nav, use `logo.src` config pointing to an `.svg` file in `src/assets/`. |
| Card-based homepage | Built-in `<Card>`, `<CardGrid>`, `<LinkCard>` components | Ship with `@astrojs/starlight`. Import from `@astrojs/starlight/components`. |
| Sidebar cleanup | Starlight sidebar config in `astro.config.mjs` | Supports `collapsed`, `badge`, manual items mixed with `autogenerate`, custom `label`, and frontmatter `sidebar.order`. |
| Hero customization | Override via `components.Hero` config or frontmatter `hero.image.html` | Component overrides are a first-class Starlight feature. |
| Dark mode | Already built-in | Starlight ships dark/light/auto theme switching. Custom CSS targets `:root` (dark) and `:root[data-theme='light']` separately. |

### Confidence: HIGH

All capabilities verified against installed versions:
- CSS custom properties: Verified in `node_modules/@astrojs/starlight/style/props.css` (read directly)
- SVG component imports: Stable since Astro 5.7.0, installed version is 5.17.1 (official docs confirmed)
- Card/CardGrid/LinkCard: Documented at starlight.astro.build/components/card-grids/
- Component overrides: Documented at starlight.astro.build/guides/overriding-components/
- Sidebar options: Documented at starlight.astro.build/guides/sidebar/

## New Files to Create

No packages to install, but these new files are needed:

| File | Purpose |
|------|---------|
| `site/src/styles/custom.css` | Color theme overrides (accent colors, gray scale, shadows) |
| `site/src/assets/logo.svg` | SVG logo file for nav bar |
| `site/src/components/Hero.astro` | Custom Hero component override for card-based homepage |

## Theme Implementation: CSS Custom Properties

### Color System Architecture

Starlight uses a layered CSS custom property system defined in `props.css`. The cascade layer order is:

```
starlight.base → starlight.reset → starlight.core → starlight.content → starlight.components → starlight.utils
```

Custom CSS added via `customCss` is **unlayered**, meaning it automatically takes precedence over all Starlight layers. No `!important` or `@layer` manipulation needed.

### Dark Mode Accent Colors (Orange/Amber)

Override these three variables for the primary accent (links, nav highlights, buttons):

```css
/* src/styles/custom.css */
:root {
  /* Dark mode: orange/amber accent */
  --sl-color-accent-low: hsl(30, 50%, 18%);
  --sl-color-accent: hsl(35, 95%, 55%);
  --sl-color-accent-high: hsl(38, 95%, 80%);
}
```

### Light Mode Accent Colors

```css
:root[data-theme='light'] {
  --sl-color-accent-high: hsl(30, 80%, 28%);
  --sl-color-accent: hsl(35, 90%, 50%);
  --sl-color-accent-low: hsl(38, 90%, 90%);
}
```

### Gray Scale (Darker Background)

For a Kali-inspired darker feel, shift the gray scale:

```css
:root {
  --sl-color-black: hsl(225, 15%, 8%);   /* Deeper black */
  --sl-color-gray-6: hsl(225, 14%, 13%); /* Darker nav/sidebar */
  --sl-color-gray-5: hsl(225, 12%, 19%); /* Darker inline code bg */
}
```

### Full Variable Reference

| Variable | Controls | Dark Default | Override For |
|----------|----------|-------------|-------------|
| `--sl-color-accent-low` | Badge backgrounds, subtle highlights | `hsl(224, 54%, 20%)` | Dark amber glow |
| `--sl-color-accent` | Links, primary buttons, active states | `hsl(224, 100%, 60%)` | Amber/orange primary |
| `--sl-color-accent-high` | Link text, accent text | `hsl(224, 100%, 85%)` | Light amber for readability |
| `--sl-color-black` | Page background | `hsl(224, 10%, 10%)` | Deeper dark base |
| `--sl-color-gray-6` | Nav/sidebar background | `hsl(224, 14%, 16%)` | Match darker base |
| `--sl-color-gray-5` | Inline code background | `hsl(224, 10%, 23%)` | Subtle contrast |
| `--sl-color-gray-4` | Borders, separators | `hsl(224, 7%, 36%)` | Keep or darken slightly |
| `--sl-color-gray-2` | Body text | `hsl(224, 6%, 77%)` | Keep for readability |
| `--sl-color-white` | Headings, bold text | `hsl(0, 0%, 100%)` | Keep white |
| `--sl-color-text-accent` | Accent-colored text | `var(--sl-color-accent-high)` | Auto-inherits from accent-high |
| `--sl-color-bg` | Main background | `var(--sl-color-black)` | Auto-inherits from black |
| `--sl-color-bg-nav` | Nav background | `var(--sl-color-gray-6)` | Auto-inherits from gray-6 |
| `--sl-color-bg-sidebar` | Sidebar background | `var(--sl-color-gray-6)` | Auto-inherits from gray-6 |

## Logo Implementation

### Approach: SVG File in `src/assets/`

Starlight's logo config accepts a file path. The SVG will be rendered as an `<img>` tag in the nav bar, sized to fit the nav height (`3.5rem` mobile, `4rem` desktop).

```javascript
// astro.config.mjs
starlight({
  logo: {
    src: './src/assets/logo.svg',
    alt: 'Networking Tools',
    replacesTitle: false,  // Keep text title alongside logo
  },
})
```

### SVG Design Constraints

- **Height:** Rendered at `calc(var(--sl-nav-height) - 2 * var(--sl-nav-pad-y))` = ~2rem (32px) on mobile, ~2.5rem (40px) on desktop
- **Width:** `auto` with `max-width: 100%` and `object-fit: contain`
- **Format:** SVG preferred for crispness at any size and small file size
- **Colors:** Use explicit colors in the SVG (not `currentColor`) since Starlight renders logos as `<img>` tags, not inline SVG. The logo will NOT inherit CSS custom properties.
- **Theme variants:** If the logo needs different colors for light/dark mode, use the `light`/`dark` config instead of `src`:

```javascript
logo: {
  dark: './src/assets/logo-dark.svg',
  light: './src/assets/logo-light.svg',
  alt: 'Networking Tools',
}
```

### Why NOT Inline SVG

Starlight does not currently support inline SVG logos (confirmed via GitHub Discussion #955). The logo is always rendered as an `<img>` tag. This means:
- No access to CSS custom properties from within the SVG
- No `fill: currentColor` trick
- Must bake colors into the SVG file
- For theme-aware logos, provide separate light/dark variants

## Homepage Card Components

### Available Built-in Components

| Component | Import | Purpose |
|-----------|--------|---------|
| `Card` | `@astrojs/starlight/components` | Content card with title, optional icon, body text |
| `CardGrid` | `@astrojs/starlight/components` | Responsive 2-column grid wrapper |
| `LinkCard` | `@astrojs/starlight/components` | Clickable card that links to another page |

### Card Props

```typescript
// Card
title: string;    // Required: heading text
icon?: string;    // Optional: built-in icon name

// LinkCard
title: string;    // Required: heading text
href: string;     // Required: link URL
description?: string; // Optional: subtitle text

// CardGrid
stagger?: boolean; // Optional: offset alternating cards vertically (5rem shift)
```

### Available Icons for Cards

Relevant built-in icons for a pentesting docs site:

| Icon Name | Visual | Good For |
|-----------|--------|----------|
| `rocket` | Launch | Getting started |
| `laptop` | Computer | Tools section |
| `setting` | Gear | Configuration |
| `puzzle` | Puzzle piece | Integrations |
| `open-book` | Book | Guides/learning |
| `list-format` | List | Reference/index |
| `magnifier` | Search | Discovery |
| `warning` | Alert | Security warnings |
| `terminal` | Terminal | CLI tools |
| `information` | Info | About/details |
| `approve-check-circle` | Checkmark | Status/validation |

### Homepage Pattern: MDX with Cards

The homepage can use MDX to import Card components directly. Convert `index.md` to `index.mdx`:

```mdx
---
title: Networking Tools
template: splash
hero:
  tagline: ...
  actions: [...]
---

import { Card, CardGrid, LinkCard } from '@astrojs/starlight/components';

<CardGrid>
  <Card title="17 Security Tools" icon="laptop">
    Nmap, tshark, sqlmap, nikto, and more with ready-to-run scripts.
  </Card>
  <Card title="65+ Scripts" icon="terminal">
    Task-focused scripts for real pentest scenarios.
  </Card>
</CardGrid>
```

## Sidebar Configuration

### Current Config

```javascript
sidebar: [
  { label: 'Tools', autogenerate: { directory: 'tools' } },
  { label: 'Guides', autogenerate: { directory: 'guides' } },
  { label: 'Diagnostics', autogenerate: { directory: 'diagnostics' } },
]
```

### Available Enhancements (No Packages Needed)

| Feature | Config | Purpose |
|---------|--------|---------|
| Collapsed groups | `collapsed: true` | Start groups collapsed, reduce visual noise |
| Badges | `badge: { text: 'New', variant: 'tip' }` | Highlight new or updated tools |
| Custom ordering | Frontmatter `sidebar: { order: N }` | Control tool ordering (alphabetical by default) |
| Manual items | `items: [{ label: '...', slug: '...' }]` | Mix manual items with autogenerated |
| Subgroups | Nested `items` arrays | Group tools by category within sidebar |

### Sidebar Ordering via Frontmatter

Each page can set its sidebar order:

```yaml
---
title: Nmap
sidebar:
  order: 1
  badge:
    text: Core
    variant: tip
---
```

Lower numbers appear first. Pages without `order` sort alphabetically after ordered pages.

## Expressive Code Theme

The current config uses default Starlight themes. For the orange/amber visual refresh, consider a custom code block theme that complements the palette. However, the default `starlight-dark` / `starlight-light` themes will automatically pick up the accent color changes and look fine.

If a custom code theme is desired later:

```javascript
// astro.config.mjs (optional, only if defaults don't match)
starlight({
  expressiveCode: {
    themes: ['one-dark-pro', 'github-light'],
    useStarlightDarkModeSwitch: true,
    useStarlightUiThemeColors: true,
  },
})
```

Recommendation: **Start with defaults.** The `useStarlightUiThemeColors: true` flag (default) means code blocks will inherit the custom accent colors. Only switch themes if the visual result is unsatisfactory.

## Configuration Changes Summary

### astro.config.mjs Additions

```javascript
// Complete updated config
export default defineConfig({
  site: 'https://patrykquantumnomad.github.io',
  base: '/networking-tools',
  integrations: [
    starlight({
      title: 'Networking Tools',
      description: 'Pentesting and network diagnostic learning lab',
      logo: {
        src: './src/assets/logo.svg',
        alt: 'Networking Tools',
        replacesTitle: false,
      },
      customCss: ['./src/styles/custom.css'],
      social: [
        {
          icon: 'github',
          label: 'GitHub',
          href: 'https://github.com/PatrykQuantumNomad/networking-tools',
        },
      ],
      sidebar: [
        // Refined sidebar config (details in ARCHITECTURE.md)
        { label: 'Tools', autogenerate: { directory: 'tools' } },
        { label: 'Guides', autogenerate: { directory: 'guides' } },
        { label: 'Diagnostics', autogenerate: { directory: 'diagnostics' } },
      ],
    }),
  ],
});
```

### Key Config Properties Added

| Property | Value | What It Does |
|----------|-------|-------------|
| `logo.src` | `'./src/assets/logo.svg'` | Displays logo in nav bar |
| `logo.alt` | `'Networking Tools'` | Accessibility text |
| `logo.replacesTitle` | `false` | Keep text title visible |
| `customCss` | `['./src/styles/custom.css']` | Load custom theme overrides |

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Theming | CSS custom properties override | `starlight-theme-black` plugin | Adds a dependency for what amounts to ~30 lines of CSS. The plugin is Shadcn-inspired, not security/pentesting-inspired. Custom CSS gives precise control over the Kali-like palette. |
| Theming | CSS custom properties override | Tailwind CSS integration | Starlight docs explicitly advise against Tailwind because it fights Starlight's cascade. CSS custom properties are the designed extension point. |
| Logo | SVG file in `src/assets/` | Inline SVG via component override | Starlight renders logos as `<img>` tags. Inline SVG would require overriding the `SiteTitle` component, which is fragile across Starlight upgrades. File-based is the supported path. |
| Logo | SVG file | PNG/WebP raster image | SVG stays crisp at all sizes, smaller file size, easier to edit. Perfect for a simple logo. |
| Homepage cards | Built-in Card/CardGrid | Custom Astro components | No need to rebuild what Starlight provides. Built-in cards are styled, responsive, and maintained upstream. |
| Homepage cards | Built-in Card/CardGrid + Hero override | Starlight `hero.image.html` | The `hero.image.html` frontmatter accepts raw HTML string. Cards below the hero fold are better done with MDX components for maintainability. |
| Homepage layout | Override Hero component | Keep default Hero + add cards below | Overriding Hero gives full control. But if the default hero layout (title + tagline + actions + optional image) is sufficient, just add cards below in MDX. Start with the simpler approach. |
| Sidebar | Config-based customization | Override Sidebar component | Component overrides are last-resort. The config-based approach (collapsed, badges, manual items) covers all the cleanup needs. |

## What NOT to Add

| Technology | Why Not |
|------------|---------|
| `astro-icon` | Astro 5.17.1 has native SVG imports. The `astro-icon` package is redundant. |
| Tailwind CSS | Explicitly advised against by Starlight docs. CSS custom properties are the designed theming mechanism. |
| `@fontsource/*` | No custom font planned for this milestone. System font stack is fine for a pentesting docs site. If needed later, add via `customCss` config. |
| Any CSS-in-JS solution | Starlight uses scoped CSS in Astro components. No runtime CSS needed. |
| `starlight-theme-black` | Shadcn-inspired, not aligned with the Kali/pentesting aesthetic. 30 lines of custom CSS achieves a better fit. |
| `starlight-utils` (multi-sidebar) | Current sidebar structure (3 groups) is simple enough. Multi-sidebar adds complexity for no benefit. |
| Image optimization libraries | `sharp` is already installed. Astro's `<Image>` component handles optimization. No additional packages needed. |

## Installation

```bash
# No new packages to install.
# The visual refresh is purely configuration + CSS + SVG asset.
#
# Create new files:
mkdir -p site/src/styles
touch site/src/styles/custom.css
touch site/src/assets/logo.svg
# Optionally: touch site/src/components/Hero.astro (only if overriding)
```

## Sources

### HIGH Confidence (Official docs, verified against installed packages)
- Starlight CSS & Styling: https://starlight.astro.build/guides/css-and-tailwind/
- Starlight Configuration Reference: https://starlight.astro.build/reference/configuration/
- Starlight Sidebar Guide: https://starlight.astro.build/guides/sidebar/
- Starlight Component Overrides: https://starlight.astro.build/guides/overriding-components/
- Starlight Card Grids: https://starlight.astro.build/components/card-grids/
- Starlight Link Cards: https://starlight.astro.build/components/link-cards/
- Starlight Icons Reference: https://starlight.astro.build/reference/icons/
- Starlight Overrides Reference: https://starlight.astro.build/reference/overrides/
- Starlight Frontmatter Reference: https://starlight.astro.build/reference/frontmatter/
- Astro SVG Components (stable since 5.7): https://docs.astro.build/en/reference/experimental-flags/svg/
- Starlight `props.css` (read directly from `node_modules/@astrojs/starlight/style/props.css`)
- Starlight `Hero.astro` (read directly from `node_modules/@astrojs/starlight/components/Hero.astro`)
- Starlight `SiteTitle.astro` (read directly from `node_modules/@astrojs/starlight/components/SiteTitle.astro`)

### MEDIUM Confidence (Official GitHub discussions)
- Inline SVG logos not supported: https://github.com/withastro/starlight/discussions/955
- Expressive Code themes: https://expressive-code.com/guides/themes/
