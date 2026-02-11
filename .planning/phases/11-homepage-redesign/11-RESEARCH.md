# Phase 11: Homepage Redesign - Research

**Researched:** 2026-02-11
**Domain:** Starlight splash page customization, MDX component composition, CSS grid layout
**Confidence:** HIGH

## Summary

Phase 11 transforms the current minimal homepage into a compelling entry point that showcases the full toolkit. The existing homepage (`site/src/content/docs/index.md`) uses Starlight's `template: splash` with a basic hero (title, tagline, two action buttons) and plain markdown content below. The redesign requires: (1) hero with the project logo SVG, (2) a card grid of all tools organized by category, (3) feature highlight cards, and (4) guide/learning path links.

The entire implementation uses Starlight's built-in components (Card, CardGrid, LinkCard, Icon, Badge) composed in an MDX file. No custom Astro components, no component overrides, and no JavaScript are needed. The homepage file must be converted from `.md` to `.mdx` to enable component imports. All layout is achieved through Starlight's existing CardGrid (2-column CSS grid on desktop, single column on mobile) plus targeted CSS in the existing `custom.css` for any homepage-specific adjustments. The splash template already provides wider content (67.5rem vs 45rem for doc pages) and no sidebar, which gives ample room for card grids.

The current site has 17 tool pages (not 18 as stated in requirements -- the count should be verified) across implicit categories: Security Tools (nmap, tshark, metasploit, hashcat, john, sqlmap, nikto, hping3, aircrack-ng, skipfish, foremost, ffuf, gobuster), Networking Tools (curl, dig, netcat, traceroute), and 3 Diagnostic pages (dns, connectivity, performance). There are 6 guide pages including 3 learning paths (Reconnaissance, Web App Testing, Network Debugging).

**Primary recommendation:** Convert `index.md` to `index.mdx`, configure the hero with dark/light logo images, and compose the page body using Starlight's Card, CardGrid, and LinkCard components. Add minimal CSS to `custom.css` for homepage-specific styling (section spacing, category headers). No new dependencies needed.

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| @astrojs/starlight | 0.37.6 | Documentation framework with built-in Card, CardGrid, LinkCard, Icon components | Already installed. These components are the designed mechanism for landing pages. |
| Astro | 5.17.1 | Static site generator with MDX support | Already installed. MDX is native to Astro content collections. |

### Supporting

No new libraries needed. All layout is achieved through built-in Starlight components and CSS.

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Starlight Card/CardGrid components | Custom `.astro` components in `src/components/` | Custom components require creating a separate file, managing styles outside Starlight's design system, and importing via relative paths. Card/CardGrid already provide the exact card-grid layout needed with proper dark/light theming. |
| MDX with component imports | Hero component override (`components.Hero` in config) | Component overrides replace the Hero globally on all pages. We only need to add content below the hero on the homepage, which MDX handles perfectly. The hero frontmatter already supports image configuration. |
| CSS in `custom.css` | Tailwind CSS | Explicitly out of scope per project conventions. Starlight advises against Tailwind. |
| Static card grid | JavaScript filtering/search | Explicitly out of scope (zero-JS static site approach). 17 tools fit comfortably in a static grid. |

**Installation:**
```bash
# No new packages to install.
# Rename the homepage file from .md to .mdx:
mv site/src/content/docs/index.md site/src/content/docs/index.mdx
```

## Architecture Patterns

### Recommended Project Structure

```
site/src/
├── content/docs/
│   └── index.mdx          # Homepage (converted from .md)
├── styles/
│   └── custom.css          # Add homepage-specific CSS rules here
└── assets/
    ├── logo-dark.svg       # Existing -- used in hero
    └── logo-light.svg      # Existing -- used in hero
```

### Pattern 1: MDX Homepage with Starlight Components

**What:** Use MDX to compose the homepage from Starlight's built-in Card, CardGrid, LinkCard, and Icon components. The hero section is configured via YAML frontmatter; everything below is MDX content.

**When to use:** When building rich landing pages within Starlight that need structured layouts without custom components.

**Example:**
```mdx
---
title: Networking Tools
description: Pentesting and network diagnostic learning lab
template: splash
hero:
  tagline: "Your tagline here"
  image:
    dark: ../../assets/logo-dark.svg
    light: ../../assets/logo-light.svg
    alt: "Networking Tools terminal prompt logo"
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
  <LinkCard title="Nmap" description="Network scanning and host discovery" href="/networking-tools/tools/nmap/" />
  <LinkCard title="TShark" description="CLI packet capture and analysis" href="/networking-tools/tools/tshark/" />
</CardGrid>
```

### Pattern 2: Hero Image via Frontmatter (Dark/Light Variants)

**What:** The hero frontmatter `image` field supports `dark`/`light` file references. Starlight renders both `<Image>` elements and toggles visibility with CSS classes (`light:sl-hidden` for the dark image, `dark:sl-hidden` for the light image).

**When to use:** When the brand logo has separate dark/light variants (as this project does from Phase 9).

**Example:**
```yaml
hero:
  image:
    dark: ../../assets/logo-dark.svg
    light: ../../assets/logo-light.svg
    alt: "Networking Tools terminal prompt logo"
```

**Source:** Verified from `site/node_modules/@astrojs/starlight/schemas/hero.ts` lines 28-33 and `Hero.astro` lines 34-42.

### Pattern 3: Section Organization with Markdown Headings

**What:** Use `##` headings to create visual sections on the splash page. Starlight's markdown styles apply inside `sl-markdown-content`, so headings get proper font sizes, colors, and spacing. CardGrid components placed after each heading create categorized tool grids.

**When to use:** When organizing content into logical sections without needing custom layout components.

**Layout structure:**
```
[Hero: logo + tagline + action buttons]
[## Feature Highlights -- CardGrid with 4 Cards]
[## Security Tools -- CardGrid with LinkCards]
[## Networking Tools -- CardGrid with LinkCards]
[## Diagnostics -- CardGrid with LinkCards]
[## Guides & Learning Paths -- CardGrid with LinkCards]
```

### Pattern 4: Card vs LinkCard Selection

**What:** Starlight provides two card types with different purposes:
- `Card` -- static content card with icon, title, and body text. Best for feature highlights where you describe capabilities.
- `LinkCard` -- clickable card that navigates to a URL. Best for tool listings and guide links.

**When to use Card:** Feature highlight cards (tool count, use-case scripts, Docker lab, diagnostics) -- these describe features, not link to specific pages.
**When to use LinkCard:** Tool grid and guide links -- each card navigates to a tool or guide page.

**Card props:**
```
<Card icon="rocket" title="Card Title">Body text here</Card>
```

**LinkCard props:**
```
<LinkCard title="Page Title" description="Brief description" href="/path/" />
```

**Source:** Verified from `site/node_modules/@astrojs/starlight/user-components/Card.astro` and `LinkCard.astro`.

### Anti-Patterns to Avoid

- **Creating custom `.astro` components for cards:** Starlight's Card/CardGrid/LinkCard already handle theming, responsive layout, and accessibility. Custom components would need to replicate all of this.
- **Using `<div>` with inline styles in MDX:** MDX supports raw HTML but it bypasses Starlight's styling system. Use Starlight components instead.
- **Overriding the Hero component globally:** The `components.Hero` config option replaces the Hero on ALL pages. The homepage only needs content below the hero, which MDX provides naturally.
- **Using 3-column grids:** CardGrid is hardcoded to 2-column on desktop. Fighting this with CSS overrides risks breaking responsive behavior. Two columns work well for tool cards -- the content width (67.5rem on splash) gives each card ~33rem of width.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Card grid layout | Custom CSS grid with card styling | `<CardGrid>` + `<Card>` / `<LinkCard>` | CardGrid handles responsive breakpoints, gap spacing, and works with Starlight's design tokens. Cards auto-cycle through accent colors. |
| Clickable tool cards | `<a>` tags with custom styling | `<LinkCard>` | LinkCard provides hover states, arrow icons, proper accessibility (full-card click target via `::before` pseudo-element), and consistent styling. |
| Feature highlight icons | Custom SVG icons or external icon library | Starlight `<Icon>` via `<Card icon="...">` | Card's `icon` prop renders from Starlight's built-in icon set. Available relevant icons: `rocket`, `star`, `laptop`, `setting`, `puzzle`, `open-book`, `document`, `list-format`. |
| Dark/light image switching | CSS `prefers-color-scheme` media query or JS | Hero `image.dark`/`image.light` frontmatter | Starlight handles theme-aware image switching via CSS classes that sync with the theme toggle, not just OS preference. |
| Responsive layout | Custom media queries | Starlight's built-in responsive behavior | Splash template sets `--sl-content-width: 67.5rem`. CardGrid switches from 1-col to 2-col at `50rem`. This is already responsive for 375px/768px/1440px targets. |

**Key insight:** The entire homepage redesign requires zero custom components. Starlight's built-in components (Card, CardGrid, LinkCard) plus MDX composition provide everything needed. The only custom work is CSS refinements in `custom.css` for homepage-specific section spacing.

## Common Pitfalls

### Pitfall 1: Forgetting to Convert .md to .mdx

**What goes wrong:** Starlight component imports (`import { Card } from '...'`) only work in `.mdx` files. In `.md` files, the import statement renders as literal text.
**Why it happens:** The existing homepage is `index.md`. Renaming to `index.mdx` is a prerequisite for using component imports.
**How to avoid:** First step of implementation must be renaming `index.md` to `index.mdx`.
**Warning signs:** Import statements appearing as text on the rendered page.

### Pitfall 2: Wrong Image Path in Hero Frontmatter

**What goes wrong:** Hero image doesn't display or build fails with "Could not find image" error.
**Why it happens:** Image paths in frontmatter are relative to the file location, not the project root. From `src/content/docs/index.mdx`, the path to `src/assets/logo-dark.svg` is `../../assets/logo-dark.svg`.
**How to avoid:** Use the correct relative path: `../../assets/logo-dark.svg` (up two directories from `content/docs/` to `src/`).
**Warning signs:** Build error mentioning image not found, or empty hero image area.

### Pitfall 3: Forgetting the Base Path in LinkCard hrefs

**What goes wrong:** LinkCard links produce 404 errors.
**Why it happens:** The site uses `base: '/networking-tools'` in astro.config.mjs. All internal links must include this base path prefix.
**How to avoid:** Every `href` in LinkCard must start with `/networking-tools/`. Example: `href="/networking-tools/tools/nmap/"`.
**Warning signs:** 404 on card click. All links should match the pattern `/networking-tools/section/page/`.

### Pitfall 4: CardGrid with Odd Number of Cards

**What goes wrong:** The last card in a CardGrid stretches to full width on desktop, creating an inconsistent layout.
**Why it happens:** CardGrid uses `grid-template-columns: 1fr 1fr` on desktop. An odd number of items leaves the last item alone in its row, and CSS grid stretches it to fill the column.
**How to avoid:** Use even numbers of cards per CardGrid when possible. If a category has an odd number of tools, either split into sub-groups or accept the layout (LinkCards at full-width of one column still look acceptable since they have a defined max-width via `sl-container`).
**Warning signs:** Last card in a section looks wider than others.

### Pitfall 5: Card Icon Name Typos

**What goes wrong:** Build error or missing icon in Card component.
**Why it happens:** Card `icon` prop must be a valid Starlight icon name. The available icons are a specific set (not arbitrary strings).
**How to avoid:** Use only verified icon names. Relevant icons for this homepage: `rocket`, `star`, `laptop`, `setting`, `puzzle`, `open-book`, `document`, `list-format`, `information`, `approve-check`.
**Warning signs:** Build error referencing invalid icon name.

### Pitfall 6: Splash Page Content Width Assumptions

**What goes wrong:** Content sections appear too wide or too narrow.
**Why it happens:** Splash template (`template: splash`) disables the sidebar, which triggers `--sl-content-width: 67.5rem` (vs 45rem for doc pages). Content is centered in the viewport with `max-width: var(--sl-content-width)`.
**How to avoid:** Design content for ~67.5rem width. Two-column CardGrid at this width gives each card ~33rem. This is comfortable for tool descriptions. No custom width overrides needed.
**Warning signs:** Cards looking too wide or content not centered.

## Code Examples

Verified patterns from the installed Starlight source:

### Complete Homepage Structure (index.mdx)

```mdx
---
title: Networking Tools
description: Pentesting and network diagnostic learning lab
template: splash
hero:
  tagline: "Punchy tagline communicating project value"
  image:
    dark: ../../assets/logo-dark.svg
    light: ../../assets/logo-light.svg
    alt: "Networking Tools terminal prompt logo"
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

## At a Glance

<CardGrid>
  <Card title="17 Tools" icon="setting">
    From nmap to aircrack-ng -- security scanning, packet analysis, password cracking, and more.
  </Card>
  <Card title="28 Use-Case Scripts" icon="document">
    Task-focused scripts for common pentest scenarios. Run one command, get what you need.
  </Card>
  <Card title="Docker Lab" icon="laptop">
    DVWA, Juice Shop, WebGoat, and VulnerableApp for safe, legal practice.
  </Card>
  <Card title="Diagnostics" icon="information">
    Auto-report scripts for DNS, connectivity, and performance troubleshooting.
  </Card>
</CardGrid>

## Security Tools

<CardGrid>
  <LinkCard title="Nmap" description="Network scanning and host discovery" href="/networking-tools/tools/nmap/" />
  <LinkCard title="TShark" description="CLI packet capture and analysis" href="/networking-tools/tools/tshark/" />
  <!-- ... more tools ... -->
</CardGrid>
```

**Source:** Component APIs verified from installed `@astrojs/starlight/user-components/Card.astro`, `CardGrid.astro`, and `LinkCard.astro`.

### Hero Image Configuration (Dark/Light SVG)

```yaml
hero:
  image:
    dark: ../../assets/logo-dark.svg
    light: ../../assets/logo-light.svg
    alt: "Networking Tools terminal prompt logo"
```

Starlight renders this as:
```html
<Image src={darkImage} class="light:sl-hidden" width="400" height="400" loading="eager" />
<Image src={lightImage} class="dark:sl-hidden" width="400" height="400" loading="eager" />
```

**Source:** `Hero.astro` lines 34-42, `hero.ts` schema lines 28-33.

### CardGrid Responsive Behavior

CardGrid CSS (from source):
```css
/* Mobile: single column */
.card-grid {
  display: grid;
  grid-template-columns: 100%;
  gap: 1rem;
}

/* Desktop (50rem+): two columns */
@media (min-width: 50rem) {
  .card-grid {
    grid-template-columns: 1fr 1fr;
    gap: 1.5rem;
  }
}
```

This means:
- **375px (mobile):** Single column, full-width cards
- **768px (tablet):** Still single column (768px < 800px = 50rem)
- **800px+ (desktop):** Two-column grid
- **1440px (wide desktop):** Two columns, content max-width 67.5rem, centered

**Source:** `CardGrid.astro` lines 11-38.

### Homepage-Specific CSS in custom.css

```css
/* Homepage section spacing -- targets splash pages with hero */
[data-has-hero] .sl-markdown-content h2 {
  margin-top: 2rem;
  padding-top: 1.5rem;
  border-top: 1px solid var(--sl-color-hairline-light);
}

/* Remove border from first section heading */
[data-has-hero] .sl-markdown-content h2:first-child {
  border-top: none;
  margin-top: 0;
}
```

**Note:** This CSS uses the `[data-has-hero]` attribute that Starlight adds to the `<html>` element when a page has a hero section (verified from `Page.astro` line 44). This scopes the styles to hero/splash pages only, avoiding impact on doc pages.

### Available Tool Categories and Pages

**Security Tools (13):**
| Tool | File | Description (from frontmatter) |
|------|------|------|
| Nmap | nmap.mdx | Network scanning and host discovery |
| TShark | tshark.mdx | CLI packet capture and analysis |
| Metasploit | metasploit.mdx | Penetration testing platform |
| Hashcat | hashcat.mdx | GPU-accelerated password cracking |
| John the Ripper | john.mdx | Versatile password cracker |
| SQLMap | sqlmap.mdx | Automatic SQL injection |
| Nikto | nikto.mdx | Web server vulnerability scanner |
| hping3 | hping3.mdx | Packet crafting and network probing |
| Aircrack-ng | aircrack-ng.mdx | WiFi security auditing |
| Skipfish | skipfish.mdx | Web application security scanner |
| Foremost | foremost.mdx | File carving and recovery |
| ffuf | ffuf.mdx | Web fuzzer |
| gobuster | gobuster.mdx | Web content discovery |

**Networking Tools (4):**
| Tool | File | Description (from frontmatter) |
|------|------|------|
| curl | curl.mdx | HTTP client and endpoint testing |
| dig | dig.mdx | DNS lookup utility |
| netcat | netcat.mdx | Network Swiss Army knife |
| traceroute | traceroute.mdx | Route tracing and latency analysis |

**Diagnostics (3):**
| Page | File | Description |
|------|------|------|
| DNS | dns.md | DNS diagnostic scripts |
| Connectivity | connectivity.md | Connectivity troubleshooting |
| Performance | performance.md | Performance diagnostics |

**Guides (6, excluding index):**
| Guide | File | Type |
|------|------|------|
| Getting Started | getting-started.md | Setup guide |
| Lab Walkthrough | lab-walkthrough.md | Guided walkthrough |
| I Want To... | task-index.md | Task reference |
| Reconnaissance | learning-recon.md | Learning path |
| Web App Testing | learning-webapp.md | Learning path |
| Network Debugging | learning-network-debug.md | Learning path |

### Available Starlight Icons (Relevant Subset)

For Card `icon` prop:
- `setting` -- gear icon (tools)
- `document` -- document icon (scripts/docs)
- `add-document` -- document with + (add/create)
- `laptop` -- laptop icon (Docker lab)
- `information` -- info circle (diagnostics)
- `rocket` -- rocket (getting started)
- `star` -- star (highlights)
- `puzzle` -- puzzle piece (categories)
- `open-book` -- book (guides/learning)
- `list-format` -- list (task index)
- `approve-check` -- checkmark circle (verification)
- `magnifier` -- search (discovery tools)
- `external` -- external link
- `right-arrow` -- navigation arrow
- `pencil` -- edit/write
- `download` -- download
- `heart` -- favorite

**Source:** Verified from `site/node_modules/@astrojs/starlight/components/Icons.ts`.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Custom Hero component overrides | MDX content below built-in hero | Starlight 0.20+ | No need to override Hero globally; MDX content renders in MarkdownContent below the Hero in splash layout |
| `.md` with raw HTML | `.mdx` with component imports | Starlight 0.1+ | MDX is the standard way to use Starlight components in content pages |
| Single `logo.src` config | `logo.dark`/`logo.light` config | Starlight 0.15+ | Separate dark/light variants that sync with theme toggle, not just OS preference |

**Deprecated/outdated:**
- Using `<div class="card-grid">` raw HTML in markdown: Use `<CardGrid>` component in MDX instead
- Starlight's `houston.webp` default hero image: Still present in `src/assets/` from project scaffold, should be removed if unused

## Open Questions

1. **Tool count: 17 or 18?**
   - What we know: There are 17 `.mdx` files in `site/src/content/docs/tools/` (excluding `index.md`). The phase requirements say "18 tools."
   - What's unclear: Whether the 18th tool is planned for future addition, or whether diagnostics are being counted as tools, or if one tool is missing.
   - Recommendation: Use actual count (17) in feature highlights. The card grid should reflect what actually exists. This is purely a content question, not a technical blocker.

2. **Tagline wording**
   - What we know: Current tagline is functional but verbose: "A collection of bash scripts demonstrating 10+ open-source security tools, networking diagnostics, and a Docker-based practice environment."
   - What's unclear: What refined tagline the user wants (BRAND-03 says "refined, punchy tagline").
   - Recommendation: Plan task should include writing a shorter, punchier tagline. Example candidates: "Hands-on pentesting scripts. Ready to run." or "Security tools, demystified." The planner can propose options.

3. **Category grouping for Security Tools**
   - What we know: 13 security tools is a lot for one CardGrid (26 cards in 2-column = 13 rows).
   - What's unclear: Whether to sub-categorize security tools (e.g., Scanning, Exploitation, Cracking, Discovery) or keep them in one large grid.
   - Recommendation: Keep one "Security Tools" section for simplicity. 13 LinkCards in a 2-column grid is manageable. Sub-categorization adds complexity without strong UX benefit for 13 items.

## Sources

### Primary (HIGH confidence)
- Starlight Hero component: `site/node_modules/@astrojs/starlight/components/Hero.astro` -- hero rendering, image switching, CSS
- Starlight Hero schema: `site/node_modules/@astrojs/starlight/schemas/hero.ts` -- frontmatter options for hero image dark/light/file/html
- Starlight Card component: `site/node_modules/@astrojs/starlight/user-components/Card.astro` -- Card props (icon, title, body slot)
- Starlight CardGrid component: `site/node_modules/@astrojs/starlight/user-components/CardGrid.astro` -- responsive grid CSS
- Starlight LinkCard component: `site/node_modules/@astrojs/starlight/user-components/LinkCard.astro` -- clickable card with title, description, href
- Starlight Page component: `site/node_modules/@astrojs/starlight/components/Page.astro` -- splash layout (hero + MarkdownContent + Footer, no sidebar)
- Starlight props.css: `site/node_modules/@astrojs/starlight/style/props.css` -- CSS custom properties (content width, spacing, typography)
- Starlight components schema: `site/node_modules/@astrojs/starlight/schemas/components.ts` -- component override mechanism
- Starlight Icons: `site/node_modules/@astrojs/starlight/components/Icons.ts` -- available icon names
- Current homepage: `site/src/content/docs/index.md` -- existing frontmatter and content structure
- Current theme: `site/src/styles/custom.css` -- orange/amber accent theme
- Current logos: `site/src/assets/logo-dark.svg`, `site/src/assets/logo-light.svg` -- terminal prompt SVGs
- Astro config: `site/astro.config.mjs` -- site base path, sidebar config, logo config

### Secondary (MEDIUM confidence)
- None needed. All findings verified from installed source code.

### Tertiary (LOW confidence)
- None. No WebSearch claims made.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all components verified from installed Starlight 0.37.6 source
- Architecture: HIGH -- splash page layout, MDX composition, and component APIs verified from source code
- Pitfalls: HIGH -- all pitfalls based on verified source code behavior (image paths, base URLs, responsive breakpoints)

**Research date:** 2026-02-11
**Valid until:** 2026-03-11 (Starlight 0.37.x is stable; no breaking changes expected in 30 days)
