# Technology Stack

**Project:** networking-tools documentation site + diagnostic scripts expansion
**Researched:** 2026-02-10

## Recommended Stack

### Documentation Site — Astro + Starlight

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| Astro | 5.17.x | Static site framework | Stable release. Astro 6 is in beta (6.0-beta-6) with breaking changes (Node 22+, Zod 4, removed APIs). Not ready for production. Astro 5 is battle-tested, well-documented, and Starlight's current target. | HIGH |
| @astrojs/starlight | 0.37.x | Documentation theme | Purpose-built for docs sites. Used by Cloudflare, Google, Microsoft, OpenAI. Includes Pagefind search, sidebar auto-generation, i18n, dark mode, Expressive Code — all built-in. No assembly required. | HIGH |
| Node.js | 22.x LTS | Runtime | Astro 5 default. The withastro/action GitHub Action defaults to Node 22. Aligns with current LTS schedule. | HIGH |
| npm | (bundled) | Package manager | Project has no existing JS toolchain. npm is simplest — zero config, lockfile works with GitHub Actions out of the box. No reason to add pnpm/yarn complexity for a docs site. | HIGH |

### Documentation Site — Built-in (No Additional Packages Needed)

These capabilities ship with Starlight. Do NOT install separate packages for them.

| Capability | Provided By | Notes |
|------------|-------------|-------|
| Full-text search | Pagefind (built-in) | Client-side search, zero config. Indexed at build time. No external service needed. |
| Syntax highlighting | Expressive Code (built-in) | Shiki-powered, 100+ languages. Supports line highlighting, file names, diff markers, copy button. Bash/shell highlighting works out of the box. |
| Dark/light mode | Starlight (built-in) | Automatic theme detection. No config needed. |
| Sidebar navigation | Starlight (built-in) | Auto-generated from filesystem structure. Customizable via frontmatter `sidebar.order` or `astro.config.mjs`. |
| Responsive layout | Starlight (built-in) | Mobile-first. Collapsible sidebar on small screens. |
| Markdown + MDX | Astro (built-in) | Write docs in `.md` or `.mdx`. MDX enables interactive components inside docs. |
| Content collections | Astro (built-in) | Type-safe frontmatter via Zod schemas. `docsSchema()` helper validates all doc frontmatter. |
| Tabs component | Starlight (built-in) | `<Tabs>` / `<TabItem>` for showing OS-specific commands (macOS vs Linux). Supports `syncKey` for synced tabs across page. |
| Code component | Starlight (built-in) | `<Code>` component for dynamic code blocks. Can import files with `?raw` suffix. |

### Deployment — GitHub Pages + GitHub Actions

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| GitHub Pages | - | Hosting | Free, already where the repo lives. Static-only which is what Astro produces. No server costs. | HIGH |
| withastro/action | v5 (5.0.2) | Build action | Official Astro GitHub Action. Auto-detects package manager from lockfile, builds, and uploads artifact. One-liner in workflow. | HIGH |
| actions/deploy-pages | v4 | Deploy action | Official GitHub Pages deployment action. Pairs with withastro/action. | HIGH |
| actions/checkout | v6 | Repo checkout | Standard checkout step. | HIGH |

### Bash Scripting — Quality Tools

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| ShellCheck | latest | Static analysis / linter | Industry standard for bash. Catches syntax errors, quoting bugs, portability issues, antipatterns. The project already uses `set -euo pipefail` in common.sh which is good — ShellCheck enforces this pattern consistently. | HIGH |
| shfmt | latest | Code formatter | Consistent formatting across all scripts. Use with `-i 4` (4-space indent) to match existing project style. Can auto-fix. | HIGH |
| bats-core | 1.13.x | Bash test framework | TAP-compliant test runner. Tests verify script behavior without actually running scans. Supports setup/teardown, assertions, parallel execution. Works with Bash 3.2+ (macOS default). | MEDIUM |

### Bash Scripting — Diagnostic Script Dependencies

These are the tools the new diagnostic scripts will wrap. They are NOT project dependencies to install — they are system tools the scripts document and require.

| Tool | Category | macOS Install | Linux Install | Notes |
|------|----------|---------------|---------------|-------|
| dig | DNS diagnostics | Built-in (macOS) | `apt install dnsutils` | Part of BIND utils. Preferred over nslookup. |
| whois | Domain intelligence | Built-in (macOS) | `apt install whois` | Domain registration lookups. |
| curl | HTTP diagnostics | Built-in (macOS) | `apt install curl` | HTTP timing, header inspection, API testing. |
| netcat (nc) | Connectivity testing | Built-in (macOS) | `apt install netcat-openbsd` | Port scanning, banner grabbing, file transfer. |
| traceroute | Path analysis | Built-in (macOS) | `apt install traceroute` | Network path tracing. |
| mtr | Path analysis (live) | `brew install mtr` | `apt install mtr` | Combines traceroute + ping. Live updating. |
| gobuster | Directory brute-force | `brew install gobuster` | `apt install gobuster` | Go-based, fast. For web directory/DNS enumeration. |
| ffuf | Web fuzzing | `brew install ffuf` | `go install github.com/ffuf/ffuf/v2@latest` | Faster than gobuster for fuzzing. Supports multiple wordlist positions. |

## Documentation Site Directory Structure

Place the Astro site in a `docs/` subdirectory of the repo. This keeps the docs separate from the bash scripts while living in the same repository.

```
networking-tools/
  docs/                          # Astro Starlight site
    astro.config.mjs
    package.json
    package-lock.json
    public/
      CNAME                      # If using custom domain (optional)
    src/
      content/
        docs/
          index.mdx              # Landing page
          getting-started/
            installation.mdx
            lab-setup.mdx
          tools/
            nmap/
              overview.mdx
              examples.mdx       # Generated or hand-written from scripts
              use-cases.mdx
            dig/
              overview.mdx
              ...
          guides/
            dns-diagnostics.mdx
            web-recon.mdx
            ...
          reference/
            common-sh.mdx
            makefile-targets.mdx
      content.config.ts
    .github/                     # NOT here — at repo root
  scripts/                       # Existing bash scripts (unchanged)
  labs/                          # Existing Docker lab (unchanged)
  .github/
    workflows/
      deploy-docs.yml            # GitHub Actions workflow
  Makefile                       # Add docs targets
```

## GitHub Actions Workflow

```yaml
# .github/workflows/deploy-docs.yml
name: Deploy docs to GitHub Pages

on:
  push:
    branches: [main]
    paths: ['docs/**']           # Only rebuild when docs change
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: pages
  cancel-in-progress: false

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v6
      - name: Build Astro site
        uses: withastro/action@v5
        with:
          path: ./docs           # Subdirectory containing the Astro project
  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

## Astro Configuration

```javascript
// docs/astro.config.mjs
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

export default defineConfig({
  site: 'https://<username>.github.io',
  base: '/networking-tools',     // Must match repo name for GitHub Pages
  integrations: [
    starlight({
      title: 'Networking Tools',
      description: 'Pentesting and network diagnostic learning lab',
      social: [
        { icon: 'github', label: 'GitHub', href: 'https://github.com/<user>/networking-tools' },
      ],
      sidebar: [
        { label: 'Getting Started', autogenerate: { directory: 'getting-started' } },
        { label: 'Tools', autogenerate: { directory: 'tools' } },
        { label: 'Guides', autogenerate: { directory: 'guides' } },
        { label: 'Reference', autogenerate: { directory: 'reference' } },
      ],
      expressiveCode: {
        themes: ['github-dark', 'github-light'],
      },
    }),
  ],
});
```

## Installation

```bash
# Initialize docs site (run once from repo root)
cd docs
npm create astro@latest -- --template starlight --yes

# After scaffolding, the package.json will include:
#   astro: ^5.17.0
#   @astrojs/starlight: ^0.37.6

# Development
cd docs && npm run dev          # http://localhost:4321

# Build (produces static HTML in docs/dist/)
cd docs && npm run build

# Preview production build locally
cd docs && npm run preview
```

```bash
# Bash quality tools (install once on dev machine)
brew install shellcheck shfmt   # macOS
# apt install shellcheck shfmt  # Debian/Ubuntu

# Optional: bash test framework
brew install bats-core          # macOS
# apt install bats              # Debian/Ubuntu
```

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Docs framework | Astro + Starlight | Docusaurus (React) | Heavier runtime, React dependency unnecessary for static docs. Astro ships zero JS by default. Starlight has equivalent features with better performance. |
| Docs framework | Astro + Starlight | MkDocs (Python) | Would add a Python dependency to a bash/Node project. Theming is less flexible. No built-in MDX component support. |
| Docs framework | Astro + Starlight | VitePress (Vue) | Good option, but Starlight has richer built-in components (tabs, code, cards, asides) and better plugin ecosystem for docs specifically. |
| Docs framework | Astro + Starlight | Jekyll (Ruby) | GitHub Pages' old default. Slow builds, Ruby dependency, limited component model. Outdated choice in 2026. |
| Search | Pagefind (built-in) | Algolia DocSearch | Requires external service, approval process, account. Pagefind is client-side, zero-config, and already bundled with Starlight. Perfect for a project this size. |
| Astro version | 5.17.x (stable) | 6.0 beta | Beta has breaking changes (Node 22+ required, removed Astro.glob(), Zod 4 migration). Starlight 0.37.x targets Astro 5. Wait for Astro 6 stable + Starlight compatibility update. |
| Hosting | GitHub Pages | Netlify / Vercel | Extra account, extra service. GitHub Pages is free, integrated with the repo, and sufficient for a static docs site. No server-side features needed. |
| Package manager | npm | pnpm / yarn | No existing JS toolchain in the project. npm is the simplest choice — comes with Node, no extra install. The docs site is a simple static build, not a complex monorepo. |
| Bash linter | ShellCheck | bashate | bashate only checks style, not logic bugs. ShellCheck catches actual bugs (unquoted variables, incorrect test syntax, useless cat, etc.). |
| Bash formatter | shfmt | manual | Consistent formatting across 40+ scripts requires automation. shfmt integrates with editors and CI. |
| Bash testing | bats-core | shunit2 | bats has cleaner syntax, better community activity, TAP output for CI integration. shunit2 is xUnit-style which feels foreign in bash. |

## What NOT to Use

| Technology | Why Not |
|------------|---------|
| Astro 6 beta | Breaking changes, Starlight not yet compatible. Revisit after stable release (likely Q2 2026). |
| React/Vue/Svelte integrations | Docs site has no interactive UI needs. Astro's zero-JS default is the right call. Adding a framework adds bundle size for zero benefit. |
| Tailwind CSS | Starlight's built-in styles are purpose-built for docs. Adding Tailwind means fighting Starlight's cascade. Customize via CSS custom properties instead. |
| MDX for every page | Use `.md` by default. Only upgrade to `.mdx` when a page needs interactive components (tabs, dynamic code). MDX adds compilation overhead. |
| Database / CMS | Content lives in git as Markdown files alongside the scripts. No Contentful, Sanity, or other CMS needed. This keeps docs versioned with the code. |
| Docker for docs | The docs site is static HTML. No Docker needed for development or deployment. `npm run dev` is sufficient. |
| Pagefind manual config | Starlight bundles and configures Pagefind automatically. Do not install `pagefind` separately or configure it manually. |

## Upgrade Path

When Astro 6 reaches stable (expected mid-2026):

1. Wait for Starlight to release a version targeting Astro 6
2. Run `npx @astrojs/upgrade` to update both packages
3. Key migration items: Node 22+ (already using it), Zod 4 (affects content schemas), removed `Astro.glob()` (unlikely to be used in Starlight)
4. The `withastro/action@v5` already defaults to Node 22, so no CI changes needed

## Makefile Integration

Add these targets to the existing Makefile:

```makefile
# Documentation
docs-dev: ## Start docs dev server
	cd docs && npm run dev

docs-build: ## Build documentation site
	cd docs && npm run build

docs-preview: ## Preview docs production build
	cd docs && npm run preview

# Quality
lint-scripts: ## Lint all bash scripts with ShellCheck
	shellcheck scripts/**/*.sh

fmt-scripts: ## Format all bash scripts with shfmt
	shfmt -w -i 4 scripts/**/*.sh

test-scripts: ## Run bash script tests
	bats tests/
```

## Sources

### HIGH Confidence (Official documentation, verified npm registry)
- Astro deployment to GitHub Pages: https://docs.astro.build/en/guides/deploy/github/
- Starlight getting started: https://starlight.astro.build/getting-started/
- Starlight sidebar configuration: https://starlight.astro.build/guides/sidebar/
- Starlight frontmatter reference: https://starlight.astro.build/reference/frontmatter/
- Starlight plugins and integrations: https://starlight.astro.build/resources/plugins/
- Expressive Code syntax highlighting: https://expressive-code.com/key-features/syntax-highlighting/
- withastro/action GitHub Action: https://github.com/withastro/action
- ShellCheck: https://github.com/koalaman/shellcheck
- bats-core: https://github.com/bats-core/bats-core
- npm registry: astro@5.17.1, @astrojs/starlight@0.37.6 (verified 2026-02-10)

### MEDIUM Confidence (Official blog posts, release announcements)
- Astro 6 Beta announcement: https://astro.build/blog/astro-6-beta/
- Astro January 2026 updates: https://astro.build/blog/whats-new-january-2026/
- Astro 2025 year in review (Starlight adoption): https://astro.build/blog/year-in-review-2025/

### LOW Confidence (Community sources, general best practices)
- shfmt: https://github.com/mvdan/sh (formatter — well-established but version not verified via official source)
