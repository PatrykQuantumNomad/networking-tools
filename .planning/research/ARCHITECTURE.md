# Architecture Patterns

**Domain:** Pentesting learning lab expansion (Astro docs site, diagnostic scripts, new tool scripts)
**Researched:** 2026-02-10

## Existing Architecture (Baseline)

The current system has four well-defined layers with clear boundaries:

```
Orchestration Layer        Makefile (convenience targets, lab lifecycle)
                               |
Utility Layer              scripts/common.sh (logging, validation, safety checks)
                               |
Script Layer               scripts/<tool>/examples.sh    (educational, 10 numbered examples)
                           scripts/<tool>/<use-case>.sh  (task-focused, same pattern)
                               |
Lab Environment            labs/docker-compose.yml (4 vulnerable Docker targets)
                               |
Documentation Layer        notes/<tool>.md, README.md, USECASES.md, CLAUDE.md
```

**Key architectural properties:**
- Every script sources `common.sh` for shared utilities -- single dependency, no nesting
- Scripts are stateless: they print examples and optionally run one demo interactively
- No script imports another script (only `common.sh` is shared)
- Makefile acts as the user-facing CLI layer, delegating to bash scripts
- Documentation (notes/) is human-written markdown, disconnected from the scripts

## Recommended Architecture (Expanded)

```
+------------------------------------------------------------------+
|                    ORCHESTRATION LAYER                            |
|  Makefile                                                        |
|  - Tool runners (make nmap, make dig, ...)                       |
|  - Lab lifecycle (make lab-up/down/status)                       |
|  - Diagnostics (make diagnose-dns, make diagnose-connectivity)   |
|  - Site (make site-dev, make site-build)                         |
+------------------------------------------------------------------+
        |                    |                    |
        v                    v                    v
+----------------+  +------------------+  +------------------+
| UTILITY LAYER  |  | SITE LAYER       |  | CI/CD LAYER      |
| common.sh      |  | site/            |  | .github/workflows|
| - info/warn/   |  | - Astro+Starlight|  | - build & deploy |
|   error/success|  | - src/content/   |  |   to GH Pages    |
| - require_cmd  |  |   docs/          |  +------------------+
| - require_target| | - consumes       |
| - safety_banner|  |   notes/*.md     |
| - report_*     |  |   via content    |
|   (NEW)        |  |   collections    |
+----------------+  +------------------+
        |                    ^
        v                    | (markdown content flows up)
+------------------------------------------------------------------+
|                      SCRIPT LAYER                                |
|                                                                  |
|  Pattern A: Educational Examples (existing)                      |
|  scripts/<tool>/examples.sh       -- 10 numbered examples       |
|  scripts/<tool>/<use-case>.sh     -- task-focused education      |
|                                                                  |
|  Pattern B: Diagnostic Auto-Report (NEW)                         |
|  scripts/diagnostics/dns.sh       -- run, collect, report        |
|  scripts/diagnostics/connectivity.sh                             |
|  scripts/diagnostics/performance.sh                              |
|                                                                  |
|  Pattern C: New Tool Examples (follows Pattern A)                |
|  scripts/dig/examples.sh                                         |
|  scripts/curl/examples.sh                                        |
|  scripts/netcat/examples.sh                                      |
|  scripts/traceroute/examples.sh                                  |
|  scripts/gobuster/examples.sh                                    |
+------------------------------------------------------------------+
        |
        v
+------------------------------------------------------------------+
|                   LAB ENVIRONMENT                                |
|  labs/docker-compose.yml (DVWA, Juice Shop, WebGoat, VulnApp)   |
+------------------------------------------------------------------+
        |
        v
+------------------------------------------------------------------+
|                   DOCUMENTATION LAYER                            |
|  notes/<tool>.md            -- per-tool reference (human-written)|
|  notes/lab-walkthrough.md   -- guided engagement flow            |
|  README.md, USECASES.md    -- project-level docs                 |
+------------------------------------------------------------------+
```

## Component Boundaries

| Component | Responsibility | Communicates With | Does NOT |
|-----------|---------------|-------------------|----------|
| `scripts/common.sh` | Shared bash utilities: logging, validation, safety | All scripts source it | Import other scripts; contain tool-specific logic |
| `scripts/<tool>/examples.sh` | Educational examples for one tool (Pattern A) | Sources `common.sh`; invoked by Makefile | Call other tool scripts; produce structured output |
| `scripts/<tool>/<use-case>.sh` | Task-focused examples for one tool (Pattern A) | Sources `common.sh`; invoked by Makefile | Differ structurally from examples.sh |
| `scripts/diagnostics/*.sh` | Auto-report diagnostics (Pattern B) | Sources `common.sh`; invoked by Makefile | Require user interaction; show educational examples |
| `site/` | Astro Starlight docs site | Reads `notes/*.md` and curated content in `site/src/content/docs/` | Modify scripts; depend on script execution |
| `Makefile` | CLI entry point for all operations | Invokes scripts, docker compose, npm/astro | Contain business logic beyond delegation |
| `.github/workflows/` | CI/CD for site deployment | Builds `site/`, deploys to GitHub Pages | Run scripts against targets |
| `labs/docker-compose.yml` | Vulnerable practice targets | Started/stopped by Makefile | Know about scripts |

## Data Flow

### Flow 1: Script Content to Docs Site

This is the central integration question. The data flows in one direction: existing content feeds the site at build time.

```
notes/<tool>.md  ──(copy/symlink at build)──>  site/src/content/docs/tools/<tool>.md
                                                        |
USECASES.md      ──(curated rewrite)──────>  site/src/content/docs/guides/use-cases.md
                                                        |
lab-walkthrough  ──(curated rewrite)──────>  site/src/content/docs/guides/walkthrough.md
                                                        |
                                              Astro build (npm run build)
                                                        |
                                                   dist/ (static HTML)
                                                        |
                                              GitHub Pages deployment
```

**Recommendation: Copy, do not symlink.** Symlinks create cross-platform problems (Windows/WSL), confuse git, and create fragile build dependencies. Instead:

1. **Primary content lives in `site/src/content/docs/`.** The Astro site is the authoritative documentation location going forward.
2. **Existing `notes/*.md` files get migrated** into `site/src/content/docs/tools/` with Starlight-compatible frontmatter added.
3. **After migration, `notes/` becomes a legacy directory** that can be removed or symlinked backward for anyone still using it directly.

This is cleaner than trying to load external content because Starlight's `docsLoader` has known limitations with custom paths outside `src/content/docs/` (autogenerated sidebars break, last-updated dates fail). As of early 2026, custom content paths in Starlight are "mostly functional but not fully supported" per the maintainers.

**Confidence: HIGH** -- verified via [Starlight discussion #1257](https://github.com/withastro/starlight/discussions/1257) and [Starlight manual setup docs](https://starlight.astro.build/manual-setup/).

### Flow 2: User Runs Diagnostic Script

```
User runs: make diagnose-dns
         |
         v
Makefile invokes: bash scripts/diagnostics/dns.sh [target]
         |
         v
dns.sh:
  1. source common.sh
  2. require_cmd dig
  3. Run checks (resolution, record types, propagation)
  4. Collect results into variables
  5. Print formatted report to stdout
  6. Optionally write markdown report to file
```

### Flow 3: User Runs Educational Script (unchanged)

```
User runs: make dig TARGET=example.com
         |
         v
Makefile invokes: bash scripts/dig/examples.sh example.com
         |
         v
examples.sh:
  1. source common.sh
  2. require_cmd dig
  3. require_target
  4. safety_banner (if applicable -- may skip for non-scanning tools)
  5. Print 10 numbered examples
  6. Offer interactive demo
```

## Where the Astro Site Lives

**Recommendation: `site/` at the repository root.**

```
networking-tools/
  site/                          # Astro Starlight project
    astro.config.mjs
    package.json
    src/
      content/
        docs/
          index.md               # Homepage
          tools/
            nmap.md              # Migrated from notes/nmap.md
            tshark.md
            dig.md               # New tool docs
            curl.md
            ...
          guides/
            getting-started.md   # Quick start guide
            use-cases.md         # Migrated/curated from USECASES.md
            walkthrough.md       # Migrated from lab-walkthrough.md
            lab-setup.md         # Docker lab setup guide
          diagnostics/
            dns.md               # How to use DNS diagnostics
            connectivity.md
            performance.md
      content.config.ts
    public/
      favicon.svg
    tsconfig.json
  scripts/                       # Unchanged
  labs/                          # Unchanged
  notes/                         # Legacy (content migrated to site/)
  Makefile                       # Updated with site targets
  README.md                      # Updated to point to site
```

**Why `site/` and not `docs/`:** GitHub Pages can serve from `docs/` as a special directory, which creates confusion -- is `docs/` the source or the build output? Using `site/` makes it unambiguous that this is source code for the Astro project, and the build output goes to `dist/` inside it (or is deployed directly via GitHub Actions).

**Why not root-level Astro:** The project is primarily a bash scripting learning lab. Making Astro the root would reframe the project around the site rather than the scripts. Nesting the site preserves the bash-first identity and keeps `package.json` / `node_modules` out of the root directory.

**Confidence: HIGH** -- this is a standard pattern for adding documentation sites to non-JS projects.

## How Diagnostic Scripts Differ Architecturally

### Pattern A: Educational Examples (existing)

```
Purpose:     Teach the user what commands exist and what they do
Input:       Target IP/hostname
Output:      Numbered list of example commands printed to stdout
Interaction: Print examples, then optionally run ONE safe demo
State:       Stateless -- nothing persisted
Key trait:   "Here are 10 things you can do with this tool"
```

### Pattern B: Diagnostic Auto-Report (new)

```
Purpose:     Diagnose a specific problem and report findings
Input:       Target (domain, IP, URL) or no target (auto-detect)
Output:      Structured report with results, status indicators, recommendations
Interaction: None -- run once, get a complete report
State:       Optionally writes report to file
Key trait:   "Here is what is wrong and what to check next"
```

### Architectural Differences

| Aspect | Pattern A (Educational) | Pattern B (Diagnostic) |
|--------|------------------------|----------------------|
| **Runs commands** | Prints them for the user to run | Executes them and collects output |
| **Output format** | Numbered list with explanations | Structured report with pass/fail/warn |
| **Interactivity** | Optional demo at end | Non-interactive by default |
| **Safety banner** | Always shown (active scanning tools) | Only for network-touching diagnostics |
| **Target required** | Usually yes (`require_target`) | Often has smart defaults (localhost, current DNS) |
| **File output** | Never | Optional `--output report.md` flag |
| **Duration** | Instant (just prints text) | Takes time (running actual checks) |

### common.sh Extensions for Pattern B

The existing `common.sh` needs a few new utilities to support diagnostic scripts:

```bash
# New functions needed in common.sh:

# Status indicators for diagnostic reports
report_pass()  { echo -e "${GREEN}[PASS]${NC} $*"; }
report_fail()  { echo -e "${RED}[FAIL]${NC} $*"; }
report_warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
report_skip()  { echo -e "${CYAN}[SKIP]${NC} $*"; }

# Section headers for structured reports
report_section() { echo -e "\n${CYAN}=== $* ===${NC}\n"; }

# Optional: capture command output with timeout
run_check() {
    local description="$1"
    shift
    local output
    if output=$(timeout 10 "$@" 2>&1); then
        report_pass "$description"
        echo "$output" | sed 's/^/   /'
    else
        report_fail "$description"
        echo "$output" | sed 's/^/   /'
    fi
}
```

This extends the utility layer without breaking existing scripts. Pattern A scripts continue using `info()` for numbered examples; Pattern B scripts use `report_pass/fail/warn` for diagnostic results.

**Confidence: HIGH** -- this follows the existing pattern of common.sh providing shared primitives.

## Diagnostic Script Directory: `scripts/diagnostics/` vs `scripts/<tool>/`

**Recommendation: `scripts/diagnostics/` as a separate directory.**

Diagnostic scripts are cross-tool. A DNS diagnostic might use `dig`, `nslookup`, `host`, and `curl` in a single script. Placing it under `scripts/dig/` would be misleading -- it is not a dig-specific script.

```
scripts/
  diagnostics/
    dns.sh              # Uses: dig, nslookup, host, whois
    connectivity.sh     # Uses: ping, curl, nc, traceroute
    performance.sh      # Uses: ping, mtr, curl, traceroute
  dig/
    examples.sh         # Pattern A: educational dig examples
    query-records.sh    # Pattern A: use-case for querying specific records
  curl/
    examples.sh         # Pattern A: educational curl examples
    test-api.sh         # Pattern A: use-case for API testing
  ...
```

This separation keeps the architecture honest: `scripts/<tool>/` is always about learning one tool; `scripts/diagnostics/` is about solving a problem using multiple tools.

**Confidence: HIGH** -- aligns with the existing architectural principle that each tool directory is single-tool-focused.

## Starlight Site Architecture

### Content Structure (Sidebar Maps to Directory)

```
site/src/content/docs/
  index.md                        # Landing page (hero, quick links)
  getting-started.md              # Installation, first run, lab setup
  tools/                          # Auto-generated sidebar group
    index.md                      # Tools overview
    nmap.md                       # Per-tool reference pages
    tshark.md                     # (migrated from notes/)
    dig.md
    curl.md
    netcat.md
    traceroute.md
    gobuster.md
    ...
  guides/                         # Auto-generated sidebar group
    index.md                      # Guides overview
    use-cases.md                  # "I want to..." reference
    walkthrough.md                # 8-phase lab walkthrough
    lab-setup.md                  # Docker targets setup
    engagement-flow.md            # Typical pentest workflow
  diagnostics/                    # Auto-generated sidebar group
    index.md                      # Diagnostics overview
    dns.md                        # DNS debugging guide + script reference
    connectivity.md               # Connectivity debugging guide
    performance.md                # Performance debugging guide
```

### Starlight Configuration

```javascript
// site/astro.config.mjs
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

export default defineConfig({
  site: 'https://<username>.github.io',
  base: '/networking-tools',
  integrations: [
    starlight({
      title: 'Networking Tools',
      social: [
        { icon: 'github', label: 'GitHub', href: 'https://github.com/<user>/networking-tools' }
      ],
      sidebar: [
        { label: 'Getting Started', link: '/getting-started/' },
        {
          label: 'Tools',
          autogenerate: { directory: 'tools' },
        },
        {
          label: 'Guides',
          autogenerate: { directory: 'guides' },
        },
        {
          label: 'Diagnostics',
          autogenerate: { directory: 'diagnostics' },
        },
      ],
      editLink: {
        baseUrl: 'https://github.com/<user>/networking-tools/edit/main/site/',
      },
    }),
  ],
});
```

**Confidence: HIGH** -- Starlight's `autogenerate` sidebar is the recommended approach per [official docs](https://starlight.astro.build/guides/sidebar/). The `base` path is needed for GitHub Pages project sites.

### Content Migration: notes/ to site/

Each `notes/<tool>.md` needs frontmatter added for Starlight:

```markdown
---
title: Nmap - Network Mapper
description: Network scanning and host discovery
---

# Nmap -- Network Mapper
...rest of existing content...
```

The existing notes are well-structured markdown with headers, tables, and code blocks. They will render cleanly in Starlight with minimal changes beyond adding the frontmatter block.

## Patterns to Follow

### Pattern 1: Single Responsibility per Directory

**What:** Each directory under `scripts/` owns exactly one concern.
**When:** Always. This is the foundational architectural rule.

```
scripts/nmap/       --> nmap-specific education
scripts/dig/        --> dig-specific education
scripts/diagnostics/ --> cross-tool problem diagnosis
```

A diagnostic script that uses dig, ping, and curl lives in `diagnostics/`, not in any single tool directory.

### Pattern 2: common.sh as the Only Shared Dependency

**What:** All scripts source `common.sh` and nothing else. No script-to-script imports.
**When:** Always. This keeps the dependency graph flat and every script independently runnable.

```bash
# Every script starts with:
source "$(dirname "$0")/../common.sh"

# For diagnostics/ (one level deeper if needed, but same depth works):
source "$(dirname "$0")/../common.sh"
```

Since `scripts/diagnostics/` is at the same level as `scripts/nmap/`, the relative path to `common.sh` is identical. No changes needed.

### Pattern 3: Makefile as the Only User-Facing Interface

**What:** Users interact through `make <target>`, never by knowing internal paths.
**When:** For all common operations. Power users can still run scripts directly.

```makefile
# New Makefile targets:
diagnose-dns: ## Diagnose DNS issues (usage: make diagnose-dns TARGET=<domain>)
	@bash scripts/diagnostics/dns.sh $(or $(TARGET),example.com)

site-dev: ## Start docs site dev server
	cd site && npm run dev

site-build: ## Build docs site for production
	cd site && npm run build
```

### Pattern 4: Content Ownership is Unambiguous

**What:** Each piece of content has exactly one authoritative location.
**When:** After migration, documentation lives in `site/src/content/docs/`. The `notes/` directory becomes read-only legacy.

```
BEFORE: notes/nmap.md is the authoritative nmap reference
AFTER:  site/src/content/docs/tools/nmap.md is authoritative
        notes/nmap.md is either removed or kept as a convenience symlink
```

## Anti-Patterns to Avoid

### Anti-Pattern 1: Bidirectional Content Sync

**What:** Keeping `notes/` and `site/src/content/docs/` as two authoritative copies that must stay in sync.
**Why bad:** Inevitable drift. Someone edits one, forgets the other. Merge conflicts on content. No single source of truth.
**Instead:** Migrate once. One authoritative location. Remove or symlink the legacy.

### Anti-Pattern 2: Scripts Generating Site Content at Build Time

**What:** Running bash scripts during `npm run build` to extract docs from script comments or generate markdown from script output.
**Why bad:** Couples the site build to having tools installed. CI needs nmap, dig, etc. installed to build docs. Fragile, slow, hard to debug.
**Instead:** Documentation is manually authored markdown. Scripts and docs evolve independently. The docs describe what scripts do; they do not extract from them.

### Anti-Pattern 3: Diagnostic Scripts Under Tool Directories

**What:** Putting `dns-diagnostic.sh` under `scripts/dig/` because dig is the primary tool.
**Why bad:** Breaks the single-tool-per-directory rule. Creates confusion about whether it is educational (Pattern A) or diagnostic (Pattern B). DNS diagnostics use multiple tools.
**Instead:** `scripts/diagnostics/dns.sh` -- cross-tool scripts get their own directory.

### Anti-Pattern 4: Astro at Root Level

**What:** Making the repository root an Astro project with `package.json` at the top level.
**Why bad:** Reframes the project identity from "bash learning lab" to "JavaScript documentation site." Pollutes root with `node_modules/`, `tsconfig.json`, etc. Makes `git clone && make check` feel like an afterthought.
**Instead:** Astro project lives in `site/`. The root remains bash-focused.

### Anti-Pattern 5: Complex Content Loaders for External Paths

**What:** Writing custom Astro content loaders to read from `notes/` at build time instead of migrating content.
**Why bad:** Starlight's custom path support is "mostly functional but not fully supported" as of early 2026. Autogenerated sidebars break. Last-updated dates fail. You are fighting the framework.
**Instead:** Migrate content into `site/src/content/docs/` where Starlight expects it. Simple, reliable, fully supported.

## Suggested Build Order (Dependencies)

The components have clear dependency relationships that dictate build order:

```
Phase 1: common.sh extensions (report_pass/fail/warn)
    |     No dependencies. Small, testable change.
    |     Enables: diagnostic scripts
    |
Phase 2: New tool scripts (dig, curl, netcat, traceroute, gobuster)
    |     Depends on: common.sh (existing, no extensions needed)
    |     Follows Pattern A exactly. Proven template.
    |     Enables: documentation content for these tools
    |
Phase 3: Diagnostic scripts
    |     Depends on: common.sh extensions (Phase 1)
    |     Depends on: new tools being available for testing
    |     New pattern -- needs design decisions resolved
    |
Phase 4: Astro Starlight site scaffold
    |     No code dependencies on scripts
    |     Can be done in parallel with Phase 2/3
    |     But benefits from having content to migrate
    |
Phase 5: Content migration (notes/ --> site/src/content/docs/)
    |     Depends on: site scaffold (Phase 4)
    |     Depends on: new tool docs existing (Phase 2)
    |
Phase 6: CI/CD (GitHub Actions --> GitHub Pages)
    |     Depends on: site scaffold (Phase 4)
    |     Depends on: content being in place (Phase 5)
    |
Phase 7: Makefile + check-tools.sh updates
          Depends on: new tools (Phase 2), diagnostics (Phase 3), site (Phase 4)
          Integrates everything into the CLI layer
```

**Key insight:** The Astro site (Phase 4) has no runtime dependency on the scripts. It can be scaffolded in parallel with script work. But content migration (Phase 5) benefits from having the new tool docs written first, so you are not migrating content that will immediately change.

**Recommendation for the roadmap:** Interleave script work and site work. Do not do all scripts first then all site work. Start the site scaffold early so you can incrementally add content as tools are written.

## Scalability Considerations

| Concern | Current (11 tools) | At 20 tools | At 50+ tools |
|---------|---------------------|-------------|--------------|
| Script discovery | `check-tools.sh` lists all | Still works, array grows | Consider auto-discovery from directory listing |
| Sidebar navigation | Manual/autogenerate | Autogenerate handles it | May need subcategories (recon, web, network, forensics) |
| Makefile targets | ~45 targets | ~80 targets | `make help` output becomes unwieldy; add categories |
| common.sh size | 70 lines | ~120 lines with diagnostics | Still fine; split only if it exceeds ~300 lines |
| Build time (Astro) | < 5 seconds | < 10 seconds | Still fast -- Starlight handles hundreds of pages |

## Sources

- [Starlight Project Structure](https://starlight.astro.build/guides/project-structure/) -- HIGH confidence
- [Starlight Manual Setup](https://starlight.astro.build/manual-setup/) -- HIGH confidence
- [Starlight Configuration Reference](https://starlight.astro.build/reference/configuration/) -- HIGH confidence
- [Starlight Sidebar Navigation](https://starlight.astro.build/guides/sidebar/) -- HIGH confidence
- [Starlight Custom Content Paths Discussion #1257](https://github.com/withastro/starlight/discussions/1257) -- HIGH confidence (maintainer responses)
- [Astro Content Collections Documentation](https://docs.astro.build/en/guides/content-collections/) -- HIGH confidence
- [Astro GitHub Pages Deployment](https://docs.astro.build/en/guides/deploy/github/) -- HIGH confidence
- Existing codebase analysis (common.sh, examples.sh, identify-ports.sh, Makefile, notes/*.md) -- HIGH confidence
