# Phase 8: Theme Foundation - Research

**Researched:** 2026-02-11
**Domain:** Starlight CSS custom property theming (dark + orange/amber accent palette)
**Confidence:** HIGH

## Summary

Phase 8 requires overriding Starlight's CSS custom properties to replace the default blue accent palette with orange/amber tones, while ensuring both dark and light modes maintain adequate contrast. The entire implementation is a single CSS file (`site/src/styles/custom.css`) registered via `customCss` in `astro.config.mjs`. No new npm packages are needed. No component overrides are needed. The scope is approximately 20-30 CSS variable declarations.

Starlight 0.37.6 (installed) uses a cascade layer system (`@layer starlight.base, starlight.reset, starlight.core, starlight.content, starlight.components, starlight.utils`). Custom CSS added via `customCss` is unlayered and automatically takes precedence over all Starlight layers per the CSS cascade specification. This means only CSS custom property overrides on `:root` and `:root[data-theme='light']` should be written -- never bare element selectors, which would unintentionally override all Starlight component styles across the entire site.

The site currently has 18 tool pages (MDX with `<Tabs>` components for install instructions), 6 guide pages, 3 diagnostic pages, and a splash-template homepage. All components -- Tabs, LinkCard, Card, badges, sidebar highlights, search, focus rings -- consume `--sl-color-accent-*` and `--sl-color-gray-*` variables. Changing these variables propagates automatically to every component on every page. The critical validation is that code blocks remain readable (Expressive Code uses Night Owl theme for syntax tokens, but UI chrome syncs with Starlight CSS vars by default) and that light mode orange/amber accent colors have adequate contrast against white/light backgrounds.

**Primary recommendation:** Create a single `custom.css` file with accent and gray-scale variable overrides for both `:root` (dark) and `:root[data-theme='light']` selectors. Register it in `astro.config.mjs`. Validate against tool pages with Tabs, code blocks, and sidebar navigation in both themes.

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| @astrojs/starlight | 0.37.6 | Documentation framework with built-in theming | Already installed. CSS custom properties are the designed extension point for visual customization. |
| Astro | 5.17.1 | Static site generator | Already installed. Hosts the Starlight integration. |

### Supporting

No new libraries needed. This phase uses zero additional dependencies.

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| CSS custom properties override | `starlight-theme-black` plugin | Plugin adds a dependency for ~30 lines of CSS. It implements a Shadcn aesthetic, not a security/pentesting amber theme. Custom CSS gives exact control. |
| CSS custom properties override | Tailwind CSS integration | Starlight docs explicitly advise against Tailwind -- it fights Starlight's cascade layer system. CSS custom properties are the designed theming mechanism. |
| Manual HSL values | Starlight color theme editor | The interactive editor on the Starlight docs site (starlight.astro.build/guides/css-and-tailwind/) generates correct HSL values for both dark/light modes with WCAG compliance checks. Use it as a starting point, then fine-tune. |

**Installation:**
```bash
# No new packages to install.
# Create the styles directory and CSS file:
mkdir -p site/src/styles
touch site/src/styles/custom.css
```

## Architecture Patterns

### Recommended Project Structure

```
site/src/
  styles/
    custom.css           # Theme overrides (accent + gray scale variables)
  content/
    docs/                # Existing content (unchanged)
  assets/                # Existing assets (unchanged)
  content.config.ts      # Existing config (unchanged)
```

### Pattern 1: CSS Custom Property Override (Variable-Only Theming)

**What:** Override Starlight's CSS custom properties on `:root` and `:root[data-theme='light']` to change the accent color palette site-wide. Never write element or class selectors in the custom CSS file.

**When to use:** Always. This is the only safe way to theme Starlight.

**Example:**
```css
/* Source: Starlight props.css (verified in node_modules/@astrojs/starlight/style/props.css) */
/* Dark mode accent colors (orange/amber) */
:root {
  --sl-color-accent-low: hsl(30, 50%, 18%);     /* Subtle accent backgrounds */
  --sl-color-accent: hsl(35, 95%, 55%);           /* Links, active states, primary buttons */
  --sl-color-accent-high: hsl(38, 95%, 80%);      /* Accent text (link text in dark mode) */
}

/* Light mode accent colors (darker for contrast against white) */
:root[data-theme='light'] {
  --sl-color-accent-low: hsl(38, 90%, 90%);       /* Subtle accent backgrounds */
  --sl-color-accent: hsl(35, 90%, 48%);            /* Links, active states */
  --sl-color-accent-high: hsl(30, 80%, 25%);       /* Accent text (must be dark enough for WCAG AA) */
}
```

### Pattern 2: Gray Scale Adjustment for Deeper Dark Mode

**What:** Override the gray scale variables to make the dark theme darker, creating a more Kali-like aesthetic.

**When to use:** Optionally, if the default dark gray tones feel too light for a pentesting/hacker aesthetic.

**Example:**
```css
/* Source: Starlight props.css gray scale defaults at hue 224 */
:root {
  --sl-color-black: hsl(225, 15%, 8%);     /* Deeper page background */
  --sl-color-gray-6: hsl(225, 14%, 13%);   /* Darker nav/sidebar */
  --sl-color-gray-5: hsl(225, 12%, 19%);   /* Darker inline code bg */
}
```

### Pattern 3: Config Registration

**What:** Register the custom CSS file in `astro.config.mjs`.

**Example:**
```javascript
// Source: Starlight CSS & Styling docs (https://starlight.astro.build/guides/css-and-tailwind/)
starlight({
  title: 'Networking Tools',
  customCss: ['./src/styles/custom.css'],
  // ... rest of config unchanged
})
```

### Anti-Patterns to Avoid

- **Bare element selectors in customCss:** Writing `a { color: orange; }` in the custom CSS file will override ALL links across every Starlight component (sidebar, nav, cards, tabs, breadcrumbs). Unlayered CSS beats all Starlight layers unconditionally. Only use CSS custom property overrides on `:root`.
- **`!important` declarations:** Never needed. Unlayered custom CSS already wins over Starlight's layered CSS. Adding `!important` makes future overrides impossible.
- **Forgetting the light mode selector:** Defining accent colors only on `:root` (dark mode) leaves light mode with inherited dark mode values, producing unreadable orange-on-white text.
- **Overriding `--sl-color-text-accent` directly:** This variable auto-inherits from `--sl-color-accent-high` in dark mode and `--sl-color-accent` in light mode. Override the source variables, not the derived ones.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Accent color propagation to links, buttons, sidebar, tabs, focus rings | Manual CSS selectors for each UI element | `--sl-color-accent-low/accent/accent-high` CSS custom properties | Starlight's components all consume these three variables. Setting them once propagates everywhere automatically. |
| Dark/light mode switching | Custom JavaScript theme toggle logic | Starlight's built-in ThemeSelect component + `data-theme` attribute system | Already works. The CSS selector `:root[data-theme='light']` is the designed extension point. |
| Code block UI theming | Custom Expressive Code configuration | Default `useStarlightUiThemeColors: true` behavior | Default behavior syncs code block frame colors (backgrounds, buttons, borders) with Starlight CSS vars. Syntax token colors stay from Night Owl theme, which has good contrast. |
| WCAG contrast validation | Manual RGB/HSL calculation | Starlight's interactive color theme editor at starlight.astro.build/guides/css-and-tailwind/ | The editor has built-in WCAG AA/AAA compliance checking with live preview in both dark and light modes. |

**Key insight:** The entire theme change is CSS custom property overrides. Starlight's component system handles propagation. There is zero JavaScript, zero component overrides, and zero build configuration changes beyond adding one line to `customCss`.

## Common Pitfalls

### Pitfall 1: Cascade Layer Override Breaks Existing Components

**What goes wrong:** Adding bare element selectors (`a {}`, `button {}`, `code {}`) in `custom.css` silently overrides Starlight's component styles across all 30 pages. The homepage may look fine while tool pages with Tabs, Cards, and code blocks break in subtle ways.

**Why it happens:** Starlight uses `@layer starlight.*` for all its styles. Custom CSS from `customCss` is unlayered. Per CSS cascade spec, unlayered CSS always beats layered CSS regardless of specificity.

**How to avoid:** Only write CSS custom property overrides on `:root` and `:root[data-theme='light']`. No element selectors, no class selectors, no component-level styles.

**Warning signs:** Any CSS rule in `custom.css` that does not start with `:root` is a red flag.

### Pitfall 2: Light Mode Contrast Failure (Orange on White)

**What goes wrong:** Amber/orange (#f59e0b, hsl(38, 95%, 55%)) on white has only a 2.7:1 contrast ratio -- fails WCAG AA (requires 4.5:1 for normal text). Light mode links become invisible or very hard to read.

**Why it happens:** The `--sl-color-accent-high` meaning flips between modes. In dark mode, "high" means bright (for visibility against dark backgrounds). In light mode, "high" means dark (for visibility against light backgrounds). If you set the same bright amber for both modes, light mode fails.

**How to avoid:** Define separate values for `:root[data-theme='light']`. Use a darker shade for light mode accent-high (hsl ~25-30% lightness, not 80%). Use Starlight's color theme editor to verify WCAG compliance.

**Warning signs:** Toggle the theme picker in the Starlight header. If accent text (links, sidebar active item) becomes hard to read against the light background, contrast is insufficient.

### Pitfall 3: Dev Server Requires Restart After Config Changes

**What goes wrong:** You add `customCss: ['./src/styles/custom.css']` to `astro.config.mjs` and nothing happens. The dev server does not pick up config changes via hot reload.

**Why it happens:** Standard Astro behavior -- `astro.config.mjs` changes require a server restart. CSS file content changes within an already-registered file do hot-reload.

**How to avoid:** Restart the dev server after modifying `astro.config.mjs`. Subsequent edits to `custom.css` will hot-reload.

**Warning signs:** Changes to `custom.css` are not reflected even though the file is saved. Check whether `customCss` was recently added to config -- if so, restart.

### Pitfall 4: Expressive Code Syntax Token Contrast

**What goes wrong:** After changing the gray scale to a deeper dark, some syntax highlighting token colors (designed for the default Starlight dark gray) may lose contrast against the darker background.

**Why it happens:** Expressive Code's Night Owl theme tokens were designed for a specific background luminance. Making the background significantly darker can reduce contrast for some token types.

**How to avoid:** After applying gray scale changes, visually inspect code blocks on tool pages with multiple languages (bash, JSON, YAML). If any token types become hard to read, use `expressiveCode.styleOverrides.codeBackground` to set a specific code block background, or revert the gray scale to less aggressive values.

**Warning signs:** Code blocks look "washed out" or certain syntax colors (especially muted greens and grays) become hard to distinguish from the background.

## Code Examples

### Complete custom.css Template

```css
/* Source: Starlight props.css variable system (verified in installed node_modules) */
/* Theme: Dark + orange/amber accent for pentesting toolkit */

/* ===== DARK MODE (default) ===== */
:root {
  /* Orange/amber accent palette */
  --sl-color-accent-low: hsl(30, 50%, 18%);
  --sl-color-accent: hsl(35, 95%, 55%);
  --sl-color-accent-high: hsl(38, 95%, 80%);

  /* Optional: Deeper dark background for hacker aesthetic */
  /* Uncomment and tune these if default grays feel too light */
  /* --sl-color-black: hsl(225, 15%, 8%); */
  /* --sl-color-gray-6: hsl(225, 14%, 13%); */
  /* --sl-color-gray-5: hsl(225, 12%, 19%); */
}

/* ===== LIGHT MODE ===== */
:root[data-theme='light'] {
  /* Darker amber for contrast against white backgrounds */
  --sl-color-accent-low: hsl(38, 90%, 90%);
  --sl-color-accent: hsl(35, 90%, 48%);
  --sl-color-accent-high: hsl(30, 80%, 25%);
}
```

### astro.config.mjs Change

```javascript
// Source: Starlight CSS & Styling docs
// Only change: add customCss array
starlight({
  title: 'Networking Tools',
  description: 'Pentesting and network diagnostic learning lab',
  customCss: ['./src/styles/custom.css'],
  social: [
    {
      icon: 'github',
      label: 'GitHub',
      href: 'https://github.com/PatrykQuantumNomad/networking-tools',
    },
  ],
  sidebar: [
    { label: 'Tools', autogenerate: { directory: 'tools' } },
    { label: 'Guides', autogenerate: { directory: 'guides' } },
    { label: 'Diagnostics', autogenerate: { directory: 'diagnostics' } },
  ],
}),
```

### Verification Commands

```bash
# Start dev server (restart required after config change)
cd site && npx astro dev

# Build and preview (respects base path, closer to production)
cd site && npx astro build && npx astro preview
```

## Variable Propagation Map

How the three accent variables propagate through Starlight components (verified by reading component source code):

| Variable | Dark Mode Role | Light Mode Role | Components That Consume It |
|----------|---------------|-----------------|---------------------------|
| `--sl-color-accent-low` | Subtle accent backgrounds, badge BGs | Subtle accent backgrounds | Search results highlight, badge backgrounds, `--sl-color-text-invert` (dark), `--sl-color-bg-accent` (light) |
| `--sl-color-accent` | Links, primary buttons, active states, borders | Links, primary buttons, `--sl-color-text-accent` (light) | Search border, mobile TOC border, link buttons, reset accent-color, tab active border (via text-accent) |
| `--sl-color-accent-high` | Accent text, link text, `--sl-color-text-accent` (dark) | Dark accent for emphasis on white | Tab active border (dark), sidebar active item, heading links, all inline accent text |

**Critical derived variables:**
- `--sl-color-text-accent`: Set to `var(--sl-color-accent-high)` in dark, `var(--sl-color-accent)` in light
- `--sl-color-bg-accent`: Set to `var(--sl-color-accent-high)` in dark, `var(--sl-color-accent)` in light
- `--sl-color-text-invert`: Set to `var(--sl-color-accent-low)` in dark, `var(--sl-color-black)` in light

These derived variables auto-update when you override the three source accent variables. Do not override derived variables directly.

## Existing Components That Must Be Validated

| Component | Used Where | What to Check |
|-----------|-----------|---------------|
| `<Tabs>` | 18 tool MDX pages (install instructions) | Active tab border color (uses `--sl-color-text-accent`), inactive tab text contrast |
| Sidebar navigation | All pages | Active item highlight, hover states, group labels |
| Code blocks (Expressive Code) | All tool and guide pages | Frame background matches theme, syntax token contrast against potentially darker background |
| Links (inline) | All pages | Accent-colored link text readable in both dark and light mode |
| Focus rings | Interactive elements (keyboard navigation) | `accent-color` CSS property uses `--sl-color-accent` |
| Search (Pagefind) | Modal overlay, accessible via Ctrl+K | Border and highlight colors use accent variables |
| Badges | Some tool pages | Badge backgrounds use semantic colors (orange, green, etc.) -- these are separate from accent |
| Hero buttons | Homepage (splash template) | Primary button uses `--sl-color-text-accent` for background |

## Starlight's Built-in Orange Variables

Starlight already defines `--sl-color-orange-*` variables (hue 41) for semantic use in badges, asides, and card variants. These are SEPARATE from the `--sl-color-accent-*` variables that control the site-wide UI accent. This phase overrides `--sl-color-accent-*` only. The existing orange semantic colors will continue to work independently.

| Variable | Purpose | Phase 8 Action |
|----------|---------|----------------|
| `--sl-color-orange-low/orange/orange-high` | Badge/aside/card semantic colors | No change needed |
| `--sl-color-accent-low/accent/accent-high` | Site-wide UI accent (links, sidebar, buttons, tabs) | Override with orange/amber values |

Note: Because the accent will now be orange/amber and the semantic `orange` color is also orange, the "orange" badge variant will blend with the accent color rather than contrasting against it. This is cosmetically fine for a pentesting toolkit -- no badges currently use the orange variant in the existing content.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Element selector overrides in customCss | CSS custom property overrides only | Starlight ~0.20+ (cascade layers adopted) | Bare element selectors in customCss now unconditionally override Starlight components. Only variable overrides are safe. |
| Single `:root` color definitions | Separate `:root` (dark) and `:root[data-theme='light']` definitions | Starlight design | Must define both selectors or light mode inherits dark mode values |
| Manual color picking | Starlight interactive color theme editor | Starlight 0.7 | Editor generates CSS with WCAG compliance checks |

**Deprecated/outdated:**
- **`@import` in customCss:** Not needed. Starlight loads CSS files directly from the `customCss` array.
- **`!important` for overrides:** Never needed. Unlayered custom CSS already beats layered Starlight CSS.
- **Expressive Code manual theme configuration:** Not needed for this phase. Default `useStarlightUiThemeColors: true` handles UI chrome. Syntax tokens use Night Owl which has good contrast.

## Open Questions

1. **Exact HSL values for final palette**
   - What we know: The variable system and selector patterns are fully verified. Example values provided in this research.
   - What's unclear: The exact hue/saturation/lightness that looks best requires visual tuning during implementation.
   - Recommendation: Use Starlight's interactive color theme editor (starlight.astro.build/guides/css-and-tailwind/) to generate initial values with WCAG compliance, then fine-tune in the browser.

2. **Gray scale depth preference**
   - What we know: Default Starlight grays use hue 224. Deeper values (lower lightness %) create a more Kali-like aesthetic.
   - What's unclear: How deep to go without making the site feel too dark or reducing code block contrast.
   - Recommendation: Start with accent-only overrides. If the default grays feel right, leave them. Only override gray scale if the visual result is unsatisfying.

3. **Expressive Code background alignment**
   - What we know: `useStarlightUiThemeColors: true` (default) syncs code block UI chrome. Syntax tokens use Night Owl and are independent.
   - What's unclear: Whether Night Owl tokens have adequate contrast against a potentially darker custom gray scale.
   - Recommendation: Implement accent overrides first, evaluate visually. If code blocks need adjustment, use `expressiveCode.styleOverrides.codeBackground` as a targeted fix.

## Sources

### Primary (HIGH confidence)
- Starlight `props.css` -- read directly from `site/node_modules/@astrojs/starlight/style/props.css`. Contains all CSS custom property definitions for dark and light mode, including accent, gray scale, and semantic color variables.
- Starlight `layers.css` -- read directly from `site/node_modules/@astrojs/starlight/style/layers.css`. Confirms cascade layer order: `starlight.base, starlight.reset, starlight.core, starlight.content, starlight.components, starlight.utils`.
- Starlight Tabs component source -- read `user-components/Tabs.astro`. Confirms active tab uses `--sl-color-text-accent`.
- Starlight Card component source -- read `user-components/Card.astro`. Confirms cards use `--sl-color-gray-*` and semantic color variables.
- Starlight Expressive Code integration -- read `integrations/expressive-code/index.ts`. Confirms `useStarlightUiThemeColors` defaults to `true` with default themes, syncing UI chrome with CSS vars.
- [Starlight CSS & Styling guide](https://starlight.astro.build/guides/css-and-tailwind/) -- Official documentation for customCss, color theme editor, cascade layer behavior.
- [Starlight Configuration Reference](https://starlight.astro.build/reference/configuration/) -- Official `customCss` config documentation.

### Secondary (MEDIUM confidence)
- [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/) -- WCAG AA requires 4.5:1 for normal text, 3:1 for large text. Orange (#f59e0b) on white is 2.7:1 (fails). Darker amber (#d97706) on white is ~3.5:1 (still fails normal text). Need ~hsl(30, 80%, 25%) for light mode accent-high to pass AA.
- Prior milestone research -- `.planning/research/SUMMARY.md`, `STACK.md`, `PITFALLS.md`, `FEATURES.md` -- Extensive prior research on Starlight theming verified against installed source code.

### Tertiary (LOW confidence)
- None. All findings are verified against installed source code or official documentation.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- Zero new dependencies. Verified against installed `node_modules/` source code.
- Architecture: HIGH -- CSS custom property override pattern verified by reading `props.css`, `layers.css`, and multiple component source files.
- Pitfalls: HIGH -- Cascade layer behavior verified by reading Starlight source. Light mode contrast failure risk verified with WCAG contrast requirements.
- Code examples: HIGH -- Variable names, selectors, and propagation chains verified by reading installed Starlight source.

**Research date:** 2026-02-11
**Valid until:** 2026-03-11 (Starlight 0.37.6 is stable; CSS custom property system is fundamental and unlikely to change in minor versions)
