# Domain Pitfalls

**Domain:** Starlight site visual refresh (custom theme, SVG logo, homepage redesign, sidebar cleanup)
**Researched:** 2026-02-11

## Critical Pitfalls

Mistakes that cause broken builds, invisible regressions across 30+ existing pages, or deployment failures.

### Pitfall 1: Custom CSS overrides Starlight's cascade layers, breaking existing component styles

**What goes wrong:** You add a `custom.css` file via the `customCss` config option and write CSS that targets base element selectors (e.g., `a {}`, `button {}`, `table {}`, `code {}`). Because Starlight puts its own styles inside `@layer starlight` while your custom CSS is unlayered, CSS cascade rules give unlayered CSS higher priority than any layered CSS -- regardless of specificity. Your innocent `a { color: var(--sl-color-accent); }` nukes the styling of navigation links, sidebar links, breadcrumbs, and Starlight's built-in Card/LinkCard/Tabs components simultaneously.

**Why it happens:** Starlight adopted CSS cascade layers internally. Unlayered CSS always beats layered CSS per the CSS spec. This is the opposite of how most developers expect CSS specificity to work. The Starlight docs explain this, but it is easy to miss. Prior to Starlight's cascade layer adoption, the same CSS would have been overridden by Starlight. Now it wins unconditionally.

**Consequences:** Existing content pages with Tabs, Cards, code blocks, and navigation all break in subtle ways. The homepage might look perfect while the 17 tool MDX pages with `<Tabs>` components render with wrong link colors, broken tab borders, or misaligned elements. These regressions are invisible unless you check every page.

**Prevention:**
1. Only override CSS custom properties (variables), not element selectors. Target `:root` and `[data-theme='light']:root` to set `--sl-color-*` variables. This is the intended customization path.
2. If you must write selector-based CSS, wrap it in an explicit layer:
   ```css
   @layer my-overrides {
     .hero-card { /* safe: scoped to your own class */ }
   }
   ```
   And declare layer order at the top of your file:
   ```css
   @layer starlight, my-overrides;
   ```
3. Never use bare element selectors (`a`, `table`, `p`) in customCss files. Always scope to a class or Starlight's data attributes.
4. After adding custom CSS, visually check at least: one tool MDX page with Tabs, the homepage, and the sidebar navigation.

**Detection:** Homepage looks fine. Open any tool page -- Tabs component has wrong colors, navigation links have unexpected styles, code blocks have wrong backgrounds.

**Phase mapping:** Address first, before any other visual work. Establish the custom CSS file with only variable overrides, test against existing pages, then build on top.

**Confidence:** HIGH -- verified via [Starlight CSS docs](https://starlight.astro.build/guides/css-and-tailwind/), [cascade layer issue #3162](https://github.com/withastro/starlight/issues/3162), and [customCss reset issue #2237](https://github.com/withastro/starlight/issues/2237).

---

### Pitfall 2: Dark/light mode color overrides applied to wrong selector, invisible in one theme

**What goes wrong:** You override `--sl-color-accent` and the gray scale variables in `:root` only. The site looks great in dark mode (the default). You never toggle to light mode during development. In light mode, the accent color has insufficient contrast against the white background, text becomes unreadable, or the orange/amber theme makes links invisible on light backgrounds.

**Why it happens:** Starlight defines dark mode variables on `:root` and overrides them for light mode on `:root[data-theme='light']`. The gray scale is fully inverted between themes -- `--sl-color-gray-1` is near-white in dark mode but near-black in light mode. If you only set variables on `:root`, your light mode inherits dark mode values, producing wrong contrast. If you forget the light mode selector entirely, every color that works in dark mode may fail in light mode.

The CSS variable naming is counterintuitive: `--sl-color-white` becomes the background in dark mode (it is actually a very dark color) and `--sl-color-black` becomes the background in light mode (it is actually white). The names refer to semantic roles, not actual colors. `--sl-color-gray-1` through `--sl-color-gray-7` are a scale where 1 is lightest in dark mode but darkest in light mode.

**Consequences:** Half your users (those preferring light mode) see an unusable site. With an orange/amber accent, light mode is especially prone to contrast failures -- amber on white is notoriously hard to read.

**Prevention:**
1. Always define theme colors for BOTH selectors:
   ```css
   :root {
     --sl-color-accent-low: hsl(30, 80%, 15%);
     --sl-color-accent: hsl(30, 90%, 55%);
     --sl-color-accent-high: hsl(30, 80%, 85%);
   }
   :root[data-theme='light'] {
     --sl-color-accent-low: hsl(30, 80%, 90%);
     --sl-color-accent: hsl(30, 90%, 40%);
     --sl-color-accent-high: hsl(30, 80%, 20%);
   }
   ```
   Note: accent-low/high meanings flip between themes. In dark mode, "high" means bright (for emphasis). In light mode, "high" means dark (for emphasis).
2. Test BOTH themes before committing. Toggle the theme picker in the Starlight header.
3. For orange/amber themes specifically, check WCAG contrast ratios. Amber (#f59e0b) on white fails AA. You need a darker shade (closer to #d97706 or #b45309) for light mode text-accent.
4. Use Starlight's built-in color theme picker tool on the Starlight docs site to generate correct HSL values for both modes.

**Detection:** Dark mode looks perfect. Toggle theme picker to light -- accent text vanishes, links unreadable, sidebar highlight invisible.

**Phase mapping:** Theme colors must be implemented and tested in both modes from the start. Do not defer light mode testing.

**Confidence:** HIGH -- verified via [Starlight props.css source](https://github.com/withastro/starlight/blob/main/packages/starlight/style/props.css), [Starlight customization docs](https://starlight.astro.build/guides/customization/), and [dark mode discussion #1829](https://github.com/withastro/starlight/discussions/1829).

---

### Pitfall 3: Logo and favicon paths break on GitHub Pages subpath deployment

**What goes wrong:** You add an SVG logo via `logo: { src: './src/assets/logo.svg' }` and a custom favicon to `public/favicon.svg`. The logo works in dev and on GitHub Pages because Starlight handles the `src/assets/` import path correctly through Astro's asset pipeline. But the favicon fails in production -- it resolves to `/favicon.svg` instead of `/networking-tools/favicon.svg` on GitHub Pages.

Additionally, if you add a separate dark-mode favicon via `<link>` tags in the `head` config, the `head` config does not automatically prepend the base path. You must manually include it.

**Why it happens:** Two different asset systems are at play:
- `logo.src` uses Astro's import system, which respects `base` automatically.
- `favicon` in Starlight config expects a path relative to `public/`, and Starlight does handle prefixing the base path for the default favicon config.
- But custom `head` entries are raw HTML -- they are NOT processed by Astro's asset pipeline and do NOT get the base path prepended. The Starlight docs explicitly state: "Entries in head are converted directly to HTML elements and do not pass through Astro's script or style processing."

**Consequences:** Logo appears correctly but favicon shows the default Starlight icon or a broken image on GitHub Pages. If you add extra link tags via `head` config for favicon variants, those are 404s in production.

**Prevention:**
1. For the logo, use `logo: { src: './src/assets/logo.svg' }` -- this goes through Astro's asset pipeline and handles base path automatically.
2. For the favicon, use the `favicon` config option -- Starlight handles the base path for this: `favicon: '/favicon.svg'` (file lives in `public/favicon.svg`).
3. For any custom `head` entries, manually prepend the base path:
   ```js
   head: [
     {
       tag: 'link',
       attrs: {
         rel: 'icon',
         href: '/networking-tools/favicon-32x32.png',
         sizes: '32x32',
       },
     },
   ],
   ```
4. After deployment, verify favicon loads by checking browser dev tools Network tab for 404s on icon resources.

**Detection:** Logo appears correctly everywhere. Favicon shows correctly in dev (`localhost:4321`) but shows default icon or broken on `github.io/networking-tools/`.

**Phase mapping:** Address during logo and favicon implementation. Test by running `astro build && astro preview` (which respects base path) before pushing.

**Confidence:** HIGH -- verified via [Starlight configuration reference](https://starlight.astro.build/reference/configuration/), [favicon discussion #1058](https://github.com/withastro/starlight/discussions/1058), [favicon base path issue #2647](https://github.com/withastro/starlight/issues/2647), and [Astro base path issue #4229](https://github.com/withastro/astro/issues/4229).

---

### Pitfall 4: Homepage redesign breaks existing content styling when moving from Markdown to MDX/Astro

**What goes wrong:** You redesign the homepage `index.md` to a richer layout with card grids, custom sections, and styled hero content. In doing so, you either (a) convert to MDX and add custom Astro components that introduce scoped styles conflicting with the splash template, or (b) add extensive inline HTML/CSS that works for the homepage but bleeds into the splash template's built-in styling.

The splash template has specific CSS expectations. Content placed below the hero in a splash page has no max-width constraint (unlike doc pages which have `--sl-content-width`). If you add cards or grids assuming a constrained width, they stretch full-viewport on large screens. If you constrain them manually with `max-width`, the value you pick may not match Starlight's content width, creating visual inconsistency.

**Why it happens:** The `splash` template intentionally removes sidebar and content-width constraints to allow full-width hero layouts. But most card-based content still needs horizontal constraints to be readable. There is no built-in mechanism in Starlight for "full-width hero, constrained content below hero" within the splash template. You must handle this yourself.

**Consequences:** Homepage looks fine on your monitor width but is broken on ultra-wide displays (cards stretched across 2560px) or narrow mobile (cards overflow). Existing pages are unaffected but the homepage becomes the worst-looking page on the site.

**Prevention:**
1. Use Starlight's built-in `<CardGrid>` and `<Card>` components from `@astrojs/starlight/components` rather than custom HTML. These are already responsive and theme-aware.
2. If you need custom sections below the hero, wrap them in a container with explicit max-width matching Starlight's content width:
   ```css
   .homepage-content {
     max-width: var(--sl-content-width);
     margin: 0 auto;
     padding: 0 1rem;
   }
   ```
3. Test the homepage at viewport widths: 375px (mobile), 768px (tablet), 1440px (laptop), and 2560px (ultra-wide).
4. Keep the homepage as `.mdx` (not a custom `.astro` page) to inherit Starlight's page shell, fonts, and theme integration automatically.

**Detection:** Homepage looks great at 1440px. Open on mobile -- cards overflow. Open on ultra-wide -- cards are stretched with huge gaps.

**Phase mapping:** Homepage redesign phase. Build with Starlight's built-in Card/CardGrid components first, only add custom styling if those are insufficient.

**Confidence:** MEDIUM -- inferred from splash template behavior documented in [Starlight frontmatter reference](https://starlight.astro.build/reference/frontmatter/) and [Starlight pages guide](https://starlight.astro.build/guides/pages/). No direct community reports of this exact issue, but the splash template's full-width behavior is documented.

## Moderate Pitfalls

### Pitfall 5: Sidebar autogenerate creates duplicate entries for index.md pages

**What goes wrong:** The project currently has `index.md` files in `tools/`, `guides/`, and `diagnostics/` directories. With autogenerated sidebars, these index pages appear as sidebar entries alongside the group label, creating confusing duplication. For example, the "Tools" sidebar group shows both the "Tools" group heading and a "Tools" link underneath it that points to the index page.

**Why it happens:** Starlight's autogenerate treats every `.md`/`.mdx` file in the directory as a sidebar entry, including `index.md`. The group label comes from the `label` property in the sidebar config, and the index page title comes from its frontmatter. When both exist with similar names, users see apparent duplicates. This is tracked as a known limitation in [issue #370](https://github.com/withastro/starlight/issues/370).

**Consequences:** The sidebar shows redundant "Tools" entries. Users do not know which one to click. It looks unprofessional, especially after a visual refresh meant to improve the site's appearance.

**Prevention:**
1. Use `sidebar: { hidden: true }` in the frontmatter of each `index.md` to hide it from the autogenerated sidebar:
   ```yaml
   ---
   title: Tools
   sidebar:
     hidden: true
   ---
   ```
2. The index page is still accessible via direct URL, but does not appear in the sidebar navigation.
3. Alternatively, if the index page has unique overview content that belongs in the sidebar, give it a distinct label via frontmatter: `sidebar: { label: 'Overview' }` and set `order: 0` to place it first.

**Detection:** After sidebar cleanup, check that no sidebar group has an entry with the same name as the group heading.

**Phase mapping:** Address during sidebar cleanup phase. Simple frontmatter change.

**Confidence:** HIGH -- verified via [Starlight sidebar docs](https://starlight.astro.build/guides/sidebar/) and [index page issue #370](https://github.com/withastro/starlight/issues/370).

---

### Pitfall 6: Expressive Code (code block) styling desynchronizes from custom theme

**What goes wrong:** You set a custom orange/amber accent color for the site. Code blocks still use Starlight's default blue-tinted syntax highlighting theme (`starlight-dark` / `starlight-light`). The code blocks look visually disconnected from the rest of the site. Or worse, you try to customize Expressive Code's theme and inadvertently break syntax highlighting contrast.

**Why it happens:** Starlight uses Expressive Code for code blocks, which has its own theming system separate from CSS custom properties. By default, Starlight syncs some UI colors (frame backgrounds, borders) with CSS variables via the `useStarlightUiThemeColors` option. But the actual syntax token colors (strings, keywords, functions) are determined by the Expressive Code theme, not by your CSS variables.

This project has 17 MDX tool pages, each with multiple code blocks. Code blocks are the primary content type. If they look wrong, the entire site looks wrong.

**Consequences:** Two visual outcomes, both bad: (1) code block frames match your theme but syntax colors feel "off" because they were designed for Starlight's default blue palette, or (2) you override Expressive Code theme colors and some token types become unreadable against the modified background.

**Prevention:**
1. For a visual refresh that changes accent colors but keeps the default code theme, this works out of the box. Starlight's `useStarlightUiThemeColors` (default: true) syncs code block UI chrome with your accent color. Token colors remain the same, which is fine.
2. Do NOT override Expressive Code themes unless you have a specific visual need. The default `starlight-dark`/`starlight-light` themes are designed for broad readability.
3. If you want to customize code block backgrounds to match your dark theme more closely, use `expressiveCode.styleOverrides`:
   ```js
   starlight({
     expressiveCode: {
       styleOverrides: {
         codeBackground: 'var(--sl-color-bg)',
       },
     },
   }),
   ```
4. Test code blocks with multiple languages (bash, js, json) after any theme change. Different token types have different colors; one that is readable for bash may be unreadable for JSON.

**Detection:** After theme change, open a tool page with code blocks. If syntax highlighting looks washed out, low contrast, or uses colors that clash with the page background, the Expressive Code theme needs attention.

**Phase mapping:** Address after establishing the main color theme. Code block theming is a polish step, not a foundation step.

**Confidence:** MEDIUM -- verified via [Expressive Code configuration docs](https://expressive-code.com/reference/configuration/) and [Starlight configuration reference](https://starlight.astro.build/reference/configuration/). The interaction between Starlight CSS variables and Expressive Code is documented but the specific visual mismatch risk is inferred.

---

### Pitfall 7: SVG logo not accounting for dark and light mode variants

**What goes wrong:** You create an SVG logo with dark text (for display on light backgrounds) and set it as the single logo. In dark mode (Starlight's default), the dark logo text is invisible or barely visible against the dark header background. Or conversely, you design for dark mode and the logo vanishes in light mode.

**Why it happens:** Starlight renders the logo in the header, which has a dark background in dark mode and a light background in light mode. A single SVG with hardcoded fill colors can only be optimized for one theme. Unlike CSS-styled elements, SVG fill colors embedded in the logo file are not affected by Starlight's CSS custom properties.

**Consequences:** The logo, the most prominent branding element, is invisible or illegible in one of the two themes. Users switching themes see the logo vanish.

**Prevention:**
1. Use Starlight's built-in dark/light logo variant support:
   ```js
   logo: {
     light: './src/assets/logo-light.svg',
     dark: './src/assets/logo-dark.svg',
   },
   ```
2. Alternatively, design a single SVG using `currentColor` for fills/strokes. Starlight sets the text color via CSS, and `currentColor` inherits it, making the logo automatically adapt to both themes.
3. If using the `currentColor` approach, verify it works for complex logos with multiple colors. `currentColor` only provides one color -- if your logo has multiple colors, you need the two-file approach.
4. Set `replacesTitle: true` if the logo includes the site name, to avoid displaying both the logo and a text title.

**Detection:** Toggle the theme picker. If the logo becomes invisible, unreadable, or looks wrong in one mode, you need variants.

**Phase mapping:** Address during logo implementation. Decide on single-SVG (`currentColor`) or dual-SVG (light/dark variants) before creating the logo file(s).

**Confidence:** HIGH -- verified via [Starlight customization docs](https://starlight.astro.build/guides/customization/) and [Starlight configuration reference](https://starlight.astro.build/reference/configuration/).

---

### Pitfall 8: Custom homepage content loses Starlight styling when using raw HTML in MDX

**What goes wrong:** You add custom HTML sections to the homepage MDX (card grids, feature lists, badges) using raw HTML tags (`<div>`, `<section>`, `<span>`) with inline styles or CSS classes. The raw HTML does not inherit Starlight's typography styles, spacing, or responsive behavior. Text inside raw HTML blocks uses browser defaults rather than Starlight's font stack and sizing. The homepage looks inconsistent with the rest of the documentation.

**Why it happens:** Starlight applies its typography and spacing styles to Markdown-rendered content via CSS selectors targeting `.sl-markdown-content`. Raw HTML inserted into MDX is technically inside this container but may not use the same semantic elements (e.g., `<div>` instead of `<p>`). Additionally, if you use CSS classes, those classes are not part of Starlight's design system and need explicit styling.

**Consequences:** The homepage has inconsistent font sizes, line heights, and spacing compared to documentation pages. Cards have different text sizing than the rest of the site. The visual refresh looks unfinished.

**Prevention:**
1. Use Starlight's built-in components (`Card`, `CardGrid`, `LinkCard`) for structured content. These inherit theme styling.
2. For custom HTML, reference Starlight's CSS variables for consistency:
   ```css
   .custom-section {
     font-family: var(--sl-font);
     font-size: var(--sl-text-body);
     line-height: var(--sl-line-height);
     color: var(--sl-color-text);
   }
   ```
3. Avoid inline styles. Put all custom styling in the `customCss` file using Starlight variables.
4. Compare your custom homepage content with a standard doc page side-by-side at the same viewport width. Font sizes and spacing should feel consistent.

**Detection:** Open the homepage next to a tool page. If fonts, spacing, or colors look different in the content areas, the raw HTML is not inheriting Starlight's styles.

**Phase mapping:** Address during homepage redesign. Prefer Starlight built-in components; only drop to raw HTML for layouts not supported by built-ins.

**Confidence:** MEDIUM -- inferred from [Starlight CSS architecture](https://starlight.astro.build/guides/css-and-tailwind/) and how MDX renders raw HTML outside Starlight's content selectors.

## Minor Pitfalls

### Pitfall 9: Content links in MDX files do not auto-prepend base path

**What goes wrong:** Existing MDX files contain hardcoded links like `[tshark](/networking-tools/tools/tshark/)` with the base path already included (correct for this project). When adding new links during the visual refresh (e.g., homepage cards linking to tool pages), you might forget to include `/networking-tools/` or inconsistently use root-relative paths like `/tools/tshark/`.

**Prevention:**
1. All internal links in MDX content must include the base path: `/networking-tools/guides/getting-started/`, not `/guides/getting-started/`.
2. Starlight's sidebar navigation handles this automatically, but content links (in MDX body text, in Card `href` attributes, in LinkCard links) do not.
3. After the visual refresh, grep all MDX files for `href=` and `link:` patterns that lack the `/networking-tools/` prefix.

**Detection:** Links work in dev (where base is handled differently) but 404 on GitHub Pages.

**Confidence:** HIGH -- verified via [Starlight base path discussion #2158](https://github.com/withastro/starlight/discussions/2158) and confirmed by examining existing MDX files which already use the base path.

---

### Pitfall 10: Component override complexity exceeds what is needed for a visual refresh

**What goes wrong:** The temptation to override Starlight components (Hero, Header, Footer, PageFrame) for visual customization leads to creating custom `.astro` component files. These overrides must correctly handle Astro slots, named slots, prop drilling, and stay compatible across Starlight updates. For a visual refresh, this is almost always unnecessary.

**Prevention:**
1. Do NOT override components for visual changes. CSS custom properties and the `customCss` option handle 95% of visual refresh needs.
2. The only component override that might be justified for this project is the Hero component if the homepage needs a radically different layout. Even then, try CSS-only approaches first.
3. If you must override a component, keep the override minimal -- import and re-render the original component with modified props rather than rebuilding from scratch.

**Detection:** You are creating files in `src/components/` that override Starlight internals. This is a signal you are overengineering the visual refresh.

**Confidence:** HIGH -- verified via [Starlight component override docs](https://starlight.astro.build/guides/overriding-components/) which explicitly recommend exhausting CSS options before component overrides.

---

### Pitfall 11: Sidebar ordering confusion when mixing frontmatter `order` with autogenerate

**What goes wrong:** Some tool pages already have `sidebar: { order: N }` in their frontmatter (e.g., nmap has `order: 1`). When cleaning up the sidebar, you might change some orders, add orders to previously unordered pages, or remove them. Pages without an explicit `order` sort alphabetically, while pages with `order` sort numerically. Mixing the two creates unpredictable ordering where some pages appear "out of place."

**Prevention:**
1. Either give ALL pages in a group an explicit `order` value, or give NONE of them explicit ordering (use alphabetical).
2. If using explicit ordering, use increments of 10 (10, 20, 30...) to leave room for future insertions.
3. After sidebar changes, run the dev server and verify sidebar order in the browser. The build output does not show sidebar order.

**Detection:** Sidebar shows nmap at position 1 (explicit order), then aircrack-ng (alphabetical), then curl (alphabetical), then hashcat (alphabetical) -- but ffuf somehow appears between curl and hashcat because it has an explicit order that happens to sort it there.

**Confidence:** HIGH -- verified via [Starlight sidebar docs](https://starlight.astro.build/guides/sidebar/).

---

### Pitfall 12: Dev server hot reload does not reflect astro.config.mjs changes

**What goes wrong:** You edit `astro.config.mjs` to add `customCss`, change the `logo`, modify `favicon`, or update sidebar configuration. The dev server does not pick up the changes. The old configuration persists. You think your changes are not working and start debugging the wrong thing.

**Prevention:**
1. After any change to `astro.config.mjs`, restart the dev server. Changes to this file are NOT hot-reloaded.
2. CSS file changes (the files referenced by `customCss`) ARE hot-reloaded after the initial config is loaded.
3. If you add a new file to `customCss`, you need a restart. If you edit an already-referenced CSS file, hot reload works.

**Detection:** You added `customCss: ['./src/styles/custom.css']` to the config and nothing happens. Or you changed the logo path and the old logo still shows.

**Confidence:** HIGH -- standard Astro behavior, not Starlight-specific.

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Custom CSS theme setup | Cascade layer override breaks Tabs/Cards on existing pages (Pitfall 1) | Only override CSS custom properties, not element selectors |
| Dark/light theme colors | Orange/amber accent unreadable in light mode (Pitfall 2) | Define both `:root` and `[data-theme='light']:root` overrides; test both themes |
| SVG logo addition | Logo invisible in one theme (Pitfall 7) | Use dark/light variants or `currentColor` fill |
| Favicon configuration | Favicon 404 on GitHub Pages due to base path (Pitfall 3) | Use Starlight's `favicon` config option; test with `astro preview` |
| Homepage card layout | Cards stretch on wide screens / overflow on mobile (Pitfall 4) | Use built-in `CardGrid`/`Card` components; constrain max-width |
| Homepage custom HTML | Raw HTML loses Starlight typography (Pitfall 8) | Reference Starlight CSS variables; prefer built-in components |
| Homepage internal links | Links missing `/networking-tools/` prefix (Pitfall 9) | Include base path in all MDX content links |
| Sidebar cleanup | Duplicate index entries in autogenerated groups (Pitfall 5) | Use `sidebar: { hidden: true }` in index.md frontmatter |
| Sidebar reordering | Mixed explicit/alphabetical ordering (Pitfall 11) | Use consistent ordering strategy: all explicit or all alphabetical |
| Code block appearance | Syntax highlighting clashes with new theme (Pitfall 6) | Keep default Expressive Code themes; only adjust frame colors if needed |
| Config changes | Dev server not reflecting config edits (Pitfall 12) | Restart dev server after astro.config.mjs changes |
| Overall approach | Over-engineering with component overrides (Pitfall 10) | CSS variables first; component overrides as absolute last resort |

## Sources

- [Starlight CSS & Styling guide](https://starlight.astro.build/guides/css-and-tailwind/) -- cascade layer system, customCss usage
- [Starlight cascade layer issue #3162](https://github.com/withastro/starlight/issues/3162) -- layer ordering bugs and workarounds
- [Starlight customCss reset issue #2237](https://github.com/withastro/starlight/issues/2237) -- element selectors override Starlight
- [Starlight customization guide](https://starlight.astro.build/guides/customization/) -- logo configuration, dark/light variants
- [Starlight configuration reference](https://starlight.astro.build/reference/configuration/) -- favicon, logo, head, customCss options
- [Starlight frontmatter reference](https://starlight.astro.build/reference/frontmatter/) -- sidebar.hidden, template, hero
- [Starlight sidebar guide](https://starlight.astro.build/guides/sidebar/) -- autogenerate, ordering, hidden pages
- [Starlight component overrides guide](https://starlight.astro.build/guides/overriding-components/) -- when and how to override components
- [Starlight overrides reference](https://starlight.astro.build/reference/overrides/) -- slot transfer requirements
- [Starlight props.css source](https://github.com/withastro/starlight/blob/main/packages/starlight/style/props.css) -- complete CSS custom property list
- [Starlight index page issue #370](https://github.com/withastro/starlight/issues/370) -- duplicate sidebar entries for index.md
- [Starlight dark mode discussion #1829](https://github.com/withastro/starlight/discussions/1829) -- dark/light theme handling
- [Starlight favicon discussion #1058](https://github.com/withastro/starlight/discussions/1058) -- favicon configuration gotchas
- [Starlight favicon base path issue #2647](https://github.com/withastro/starlight/issues/2647) -- favicon with absolute URL prefix
- [Starlight base path discussion #2158](https://github.com/withastro/starlight/discussions/2158) -- base path and content links
- [Astro base path issue #4229](https://github.com/withastro/astro/issues/4229) -- asset paths with base option
- [Expressive Code configuration](https://expressive-code.com/reference/configuration/) -- code block theming options
- [Starlight Card Grid docs](https://starlight.astro.build/components/card-grids/) -- built-in card layout components
- [Starlight Pages guide](https://starlight.astro.build/guides/pages/) -- splash template behavior
