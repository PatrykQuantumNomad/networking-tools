---
phase: quick-001
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - site/astro.config.mjs
  - site/src/styles/custom.css
  - site/public/favicon.svg
autonomous: true
must_haves:
  truths:
    - "Site always renders in dark mode regardless of OS preference"
    - "Theme toggle is not visible in the header"
    - "Logo displays the amber-on-dark variant at all times"
    - "Favicon always uses amber color (#f5c97a)"
  artifacts:
    - path: "site/astro.config.mjs"
      provides: "Single dark logo config and head script forcing dark theme"
      contains: "src: './src/assets/logo-dark.svg'"
    - path: "site/src/styles/custom.css"
      provides: "Dark-only accent variables, hidden theme toggle"
      contains: "starlight-theme-select"
    - path: "site/public/favicon.svg"
      provides: "Single-color amber favicon"
      contains: "#f5c97a"
  key_links:
    - from: "site/astro.config.mjs"
      to: "html[data-theme]"
      via: "inline head script setting data-theme=dark"
      pattern: "data-theme.*dark"
---

<objective>
Remove light theme support and the theme selector from the Starlight site, enforcing dark mode as the only theme.

Purpose: The site has a hacker/terminal aesthetic that only works well in dark mode. The light theme is unused and the toggle is unnecessary UI clutter.
Output: All four files updated so the site is permanently dark-mode-only with no visible theme switcher.
</objective>

<execution_context>
@./.claude/get-shit-done/workflows/execute-plan.md
@./.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@site/astro.config.mjs
@site/src/styles/custom.css
@site/public/favicon.svg
@site/src/assets/logo-dark.svg
</context>

<tasks>

<task type="auto">
  <name>Task 1: Force dark mode and use single logo in Astro config</name>
  <files>site/astro.config.mjs</files>
  <action>
    In `site/astro.config.mjs`, make two changes:

    1. **Logo:** Change the `logo` config from `{ dark, light }` dual format to single-source format:
       ```js
       logo: {
         src: './src/assets/logo-dark.svg',
         alt: 'Networking Tools',
       },
       ```

    2. **Force dark theme via head script:** Add a `head` property to the starlight config (after `customCss`) that injects an inline script to force dark mode before render. This prevents any flash of light mode:
       ```js
       head: [
         {
           tag: 'script',
           content: `document.documentElement.setAttribute('data-theme', 'dark');`,
         },
       ],
       ```
       This runs early in the page load, setting `data-theme="dark"` on `<html>` before Starlight's ThemeProvider reads localStorage. Starlight respects whatever `data-theme` is set, so this effectively locks dark mode.
  </action>
  <verify>Run `cd /Users/patrykattc/work/git/networking-tools/site && npx astro check 2>&1 || true` to confirm no config syntax errors. Visually confirm the config has `src:` instead of `dark:/light:` for logo and the `head` array with the inline script.</verify>
  <done>astro.config.mjs uses single logo source (logo-dark.svg) and injects a head script that forces data-theme="dark".</done>
</task>

<task type="auto">
  <name>Task 2: Remove light theme CSS and hide theme toggle</name>
  <files>site/src/styles/custom.css</files>
  <action>
    In `site/src/styles/custom.css`:

    1. **Delete the entire light mode block** (lines 41-51): Remove the `:root[data-theme='light']` rule and its comment header. This includes the `--sl-color-accent-low`, `--sl-color-accent`, and `--sl-color-accent-high` overrides for light mode.

    2. **Update the file header comment:** Remove references to "Both dark and light mode MUST be overridden separately" and the explanation of light mode inversion. Simplify to note this is dark-mode-only.

    3. **Add a rule to hide the theme selector** at the end of the file (before the homepage section spacing block):
       ```css
       /* ============================================================
        * HIDE THEME TOGGLE
        * Site is dark-mode-only; the toggle is unnecessary.
        * ============================================================ */
       starlight-theme-select {
         display: none !important;
       }
       ```
       The `!important` is needed here because we are intentionally overriding Starlight's layered display styles for this custom element. This is one of the rare cases where `!important` is appropriate -- we are removing a UI element entirely, not tweaking its appearance.

    Keep the dark mode `:root` block and the homepage section spacing block unchanged.
  </action>
  <verify>Confirm the file no longer contains `data-theme='light'` by searching for it. Confirm `starlight-theme-select` display:none rule exists.</verify>
  <done>custom.css has no light mode overrides, and the theme toggle is hidden via CSS.</done>
</task>

<task type="auto">
  <name>Task 3: Simplify favicon to always use amber color</name>
  <files>site/public/favicon.svg</files>
  <action>
    Replace `site/public/favicon.svg` with a simplified version that always uses the amber color `#f5c97a`. Remove the `<style>` block with the `.primary` class and `prefers-color-scheme` media query entirely. Instead, apply `stroke="#f5c97a"` directly to each element (matching the pattern already used in `logo-dark.svg`):

    ```svg
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32" fill="none">
      <!-- Terminal window outline -->
      <rect x="2" y="4" width="28" height="24" rx="3" stroke="#f5c97a" stroke-width="2" fill="none"/>
      <!-- Chevron > -->
      <polyline points="8,12 14,16 8,20" stroke="#f5c97a" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
      <!-- Underscore cursor _ -->
      <line x1="17" y1="20" x2="24" y2="20" stroke="#f5c97a" stroke-width="2.5" stroke-linecap="round"/>
    </svg>
    ```

    This is effectively identical to `logo-dark.svg` and removes all theme-switching logic from the favicon.
  </action>
  <verify>Confirm the file no longer contains `prefers-color-scheme` or `style` tags. Confirm all strokes use `#f5c97a`.</verify>
  <done>Favicon always renders in amber (#f5c97a) with no color scheme detection.</done>
</task>

</tasks>

<verification>
After all three tasks:
1. `cd /Users/patrykattc/work/git/networking-tools/site && npx astro build` completes without errors
2. `grep -r "data-theme.*light" site/src/` returns no results
3. `grep -r "prefers-color-scheme" site/public/` returns no results
4. `grep "starlight-theme-select" site/src/styles/custom.css` shows the display:none rule
5. `grep "src: './src/assets/logo-dark.svg'" site/astro.config.mjs` confirms single logo
</verification>

<success_criteria>
- Site builds successfully with no config errors
- No light theme CSS variables remain in custom.css
- Theme toggle is hidden via CSS
- Dark mode is forced via inline head script in astro.config.mjs
- Logo uses only the dark variant (logo-dark.svg)
- Favicon uses hardcoded amber color with no media queries
</success_criteria>

<output>
After completion, create `.planning/quick/001-remove-light-theme-and-theme-selector-en/001-SUMMARY.md`
</output>
