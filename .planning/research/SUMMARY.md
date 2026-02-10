# Project Research Summary

**Project:** networking-tools expansion (Astro docs site, diagnostic scripts, new tool scripts)
**Domain:** Pentesting and network diagnostic learning lab
**Researched:** 2026-02-10
**Confidence:** HIGH

## Executive Summary

This project is a bash-first pentesting learning lab that combines educational scripts with vulnerable Docker targets. The expansion adds three parallel tracks: (1) an Astro/Starlight documentation site hosted on GitHub Pages, (2) diagnostic auto-report scripts for DNS/connectivity/performance troubleshooting, and (3) onboarding 5 new networking tools (dig, curl, netcat, traceroute/mtr, gobuster/ffuf) using the established pattern of examples.sh + use-case scripts.

The recommended approach treats the documentation site as a new layer rather than a replacement for existing bash scripts. Use Astro 5 with Starlight theme (not Astro 6 beta) for zero-config search, dark mode, and component library. Place the site in a `site/` subdirectory to preserve the bash-first project identity. For diagnostic scripts, establish a new Pattern B (auto-report with pass/fail indicators) distinct from the existing Pattern A (10 educational examples). Onboard dig/curl/netcat first since diagnostic scripts depend on them; defer gobuster/ffuf until later since they require additional wordlist infrastructure.

The key risks are (1) Astro base path misconfiguration breaking all links and assets on GitHub Pages, (2) netcat variant incompatibility across macOS/Linux causing silent failures, (3) documentation-code drift making the site inaccurate, and (4) diagnostic scripts using deprecated Linux commands (ifconfig/netstat) that fail on modern systems. Mitigate by setting `site` + `base` in astro.config.mjs from day one, detecting netcat variants and showing examples for all, implementing docs validation tooling alongside the site, and using modern commands (ip/ss) with fallbacks to legacy.

## Key Findings

### Recommended Stack

The technology stack splits into three domains: static site generation, bash quality tooling, and system utilities. For the documentation site, Astro 5.17.x with Starlight 0.37.x is the clear choice — Astro 6 beta has breaking changes and Starlight hasn't yet released a compatible version. Node 22 LTS aligns with the official GitHub Action defaults. Deploy via GitHub Pages using the official withastro/action which handles the `.nojekyll` file automatically (critical to prevent Jekyll from eating `_astro/` build output). For bash scripting, add ShellCheck for linting and shfmt for formatting to maintain consistency across 40+ scripts. Consider bats-core for testing but defer to v2 — it's useful but not essential for launch.

**Core technologies:**
- **Astro 5.17.x + Starlight 0.37.x:** Static site with built-in search, syntax highlighting, dark mode, responsive layout — zero custom components needed
- **GitHub Pages + withastro/action:** Free hosting integrated with the repo, official action handles .nojekyll and build artifacts automatically
- **Node 22 LTS:** Runtime for Astro, aligns with GitHub Action defaults and current LTS schedule
- **ShellCheck + shfmt:** Linter and formatter for bash scripts, enforces consistency and catches common bugs
- **dig, curl, nc, traceroute, mtr, gobuster, ffuf:** New system tools the scripts will wrap (not project dependencies to install)

**Critical stack decisions:**
- Use Astro 5, NOT Astro 6 beta — breaking changes and Starlight compatibility not ready
- Do NOT install Pagefind separately — Starlight bundles it automatically
- Do NOT add React/Vue/Svelte — docs site needs zero client-side JavaScript
- Do NOT use Tailwind — Starlight's built-in styles are purpose-built for docs
- Place site in `site/` subdirectory, NOT at repository root — preserves bash-first identity

### Expected Features

Features split across three expansion areas. For the documentation site, table stakes are search, copy-to-clipboard on code blocks, per-tool reference pages, syntax highlighting, mobile responsiveness, dark mode, and sidebar navigation. These are all provided by Starlight out of the box. Differentiators include runnable scripts (not just static docs), task-organized index ("I want to..." rather than tool-first), lab walkthrough integration, OS-specific install tabs using Starlight Tabs component, and cross-references between tools. For diagnostic scripts, table stakes are DNS/connectivity/latency diagnostics with structured text output, macOS+Linux compatibility, no external dependencies beyond standard tools, and non-destructive read-only operation. Differentiators include single-command full reports, layer-by-layer diagnosis (DNS → IP → TCP → HTTP → TLS), and comparison mode for testing against multiple resolvers. For new tool onboarding, every tool MUST have examples.sh (10 examples), 2-3 use-case scripts, notes/<tool>.md, and Makefile targets to match the existing pattern.

**Must have (table stakes):**
- Astro/Starlight site with existing 11 tools migrated, search, copy buttons, dark mode, mobile-responsive
- DNS diagnostic script (resolution, record types, propagation, reverse lookup)
- Connectivity diagnostic script (ping, port check, HTTP response, SSL certificate validity)
- dig, curl, netcat examples.sh + use-case scripts following established pattern
- check-tools.sh and Makefile updates for new tools and diagnostics
- GitHub Actions workflow deploying to GitHub Pages with base path correctly set

**Should have (competitive):**
- Task-organized "I want to..." index page on docs site
- OS-specific install tabs (macOS Homebrew vs Linux apt) using Starlight Tabs
- Lab walkthrough formatted as Starlight pages with asides/callouts
- Latency diagnostic script (traceroute/mtr with per-hop stats)
- traceroute/mtr examples.sh + use-case scripts
- Guided learning paths (Recon Path, Web App Path, Network Debugging Path)

**Defer (v2+):**
- gobuster/ffuf onboarding (requires wordlist expansion, add after pattern is validated)
- Machine-parseable diagnostic output (--json flag)
- Cross-tool workflow scripts (chain multiple tools in realistic sequences)
- bats-core test framework (useful but not essential for launch)
- Docs site search analytics

### Architecture Approach

The current architecture has four clean layers (Orchestration/Utility/Script/Lab) with strong boundaries. The expansion adds two components: a Site Layer (Astro/Starlight consuming markdown content) and a new script pattern for diagnostics. Place the Astro site in `site/` at repository root to keep it separate from bash scripts while avoiding confusion with GitHub Pages' special `docs/` directory. Migrate content from `notes/*.md` INTO `site/src/content/docs/` rather than symlinking — Starlight's custom content path support is "mostly functional but not fully supported" as of early 2026. Introduce Pattern B (diagnostic auto-report) distinct from Pattern A (educational examples). Pattern B scripts execute checks, collect output, and print structured reports with pass/fail/warn indicators. Extend common.sh with `report_pass()`, `report_fail()`, `report_warn()`, `report_section()` functions to support Pattern B without breaking Pattern A scripts. Place diagnostic scripts in `scripts/diagnostics/` since they are cross-tool (a DNS diagnostic uses dig + nslookup + host + whois, not just dig).

**Major components:**
1. **Site Layer (NEW):** Astro/Starlight project in `site/` subdirectory — consumes markdown from `site/src/content/docs/`, builds to static HTML, deployed via GitHub Actions
2. **Diagnostic Scripts (NEW Pattern B):** Auto-report scripts in `scripts/diagnostics/` — execute checks, collect results, print structured reports with status indicators
3. **common.sh Extensions (NEW utilities):** Add `report_pass/fail/warn/section` functions for diagnostic reports — extends utility layer without breaking existing scripts
4. **New Tool Scripts (Existing Pattern A):** dig, curl, netcat, traceroute, gobuster in `scripts/<tool>/` — follow established pattern of examples.sh + use-case scripts
5. **GitHub Actions (NEW):** Workflow in `.github/workflows/deploy-docs.yml` — builds Astro site and deploys to GitHub Pages using official withastro/action

### Critical Pitfalls

The research identified 14 pitfalls across critical/moderate/minor severity. The top 5 that will cause the most pain if not addressed are: (1) Astro base path misconfiguration — every link, image, and asset 404s on GitHub Pages because URLs point to `/` instead of `/networking-tools/`. Prevention: set both `site` and `base` in astro.config.mjs from day one. (2) Netcat variant incompatibility — scripts using `-e` flag work on GNU netcat but fail silently on macOS OpenBSD nc. Prevention: detect variant with helper function, show examples for all variants, recommend ncat. (3) Documentation-code drift — site launches accurate but falls behind as scripts change, actively misleading users. Prevention: build docs validation tooling alongside the site, reference scripts rather than duplicating content. (4) Diagnostic scripts using deprecated commands — ifconfig/netstat fail on modern Linux that only ships iproute2. Prevention: use `ip`/`ss` as primary with fallback to legacy, test in minimal Linux containers. (5) GitHub Pages Jekyll processing — `_astro/` directory with hashed assets silently disappears during deployment. Prevention: use official withastro/action which adds `.nojekyll` automatically.

1. **Astro base path misconfiguration** — Set both `site` and `base` in config from day one, test with `astro preview` after build
2. **Netcat variant incompatibility** — Detect variant (OpenBSD/GNU/ncat), show examples for all, recommend ncat since project already requires nmap package
3. **Documentation-code drift** — Build validation tooling alongside site, implement CI check for docs completeness, reference scripts rather than copying content
4. **Diagnostic scripts using deprecated Linux commands** — Prefer `ip`/`ss` with fallback to `ifconfig`/`netstat`, test all diagnostics on both macOS and minimal Linux container
5. **Jekyll processing eating build output** — Use official withastro/action which handles `.nojekyll` automatically, verify `dist/_astro/` exists after build

## Implications for Roadmap

Based on research, the expansion should be structured around three parallel tracks that converge: (1) foundational utility extensions, (2) new tool onboarding in dependency order, and (3) site infrastructure. The diagnostic scripts depend on dig/curl/netcat being available, so those tools must be onboarded before diagnostic development. The site can be scaffolded in parallel with script work but content migration benefits from having tool docs written first. gobuster/ffuf should come last since they require wordlist infrastructure and are less critical for launch validation.

### Phase 1: Foundations and Site Scaffold
**Rationale:** Establish the architectural extensions (common.sh utilities, diagnostic script pattern) and site infrastructure early so subsequent phases can build on stable patterns. No dependencies — these changes are additive and non-breaking.
**Delivers:** common.sh with report_* functions, diagnostic script template/pattern definition, Astro site scaffold with correct base path, GitHub Actions workflow, Makefile targets for site-dev/site-build
**Addresses:** Architecture pattern definitions, Astro base path pitfall (#1), Jekyll processing pitfall (#2), site maintenance pitfall (#9)
**Avoids:** Building diagnostic scripts without a defined pattern (pitfall #7), discovering base path issues after deployment
**Research flags:** No research needed — standard patterns and well-documented Starlight setup

### Phase 2: Core Networking Tools (dig, curl, netcat)
**Rationale:** These three tools are pre-installed on most systems, universally needed, and have no complex dependencies. They enable the diagnostic scripts in Phase 3. Follow the established Pattern A exactly — proven template with 28 existing use-case scripts as reference.
**Delivers:** scripts/dig/examples.sh + 3 use-cases (query-dns-records, check-dns-propagation, attempt-zone-transfer), scripts/curl/examples.sh + 3 use-cases (test-http-endpoints, check-ssl-certificate, debug-http-response), scripts/netcat/examples.sh + 3 use-cases (scan-ports, setup-listener, transfer-files), check-tools.sh updates, Makefile targets
**Addresses:** Tool onboarding table stakes, netcat variant pitfall (#3), dig availability pitfall (#14)
**Uses:** common.sh utilities, require_cmd, safety_banner, existing script template
**Research flags:** No research needed for dig/curl patterns — standard tools with abundant documentation. Moderate complexity for netcat due to variant fragmentation — reference research on variant detection.

### Phase 3: Diagnostic Scripts (DNS, Connectivity)
**Rationale:** With dig/curl/netcat available, build the two most valuable diagnostic scripts. These demonstrate Pattern B and validate the auto-report approach before building more. Start with DNS (single most common networking issue) and connectivity (layer-by-layer debugging).
**Delivers:** scripts/diagnostics/dns.sh (resolution, record types, propagation, reverse lookup), scripts/diagnostics/connectivity.sh (ping, port check, HTTP, SSL certificate), Makefile targets (make diagnose-dns, make diagnose-connectivity)
**Implements:** Pattern B architecture — auto-report with structured output, uses report_pass/fail/warn from common.sh
**Addresses:** Diagnostic script table stakes, deprecated commands pitfall (#4), BSD vs GNU parsing pitfall (#6)
**Avoids:** Pattern divergence — these establish the diagnostic template for future scripts
**Research flags:** Moderate — each diagnostic script needs design decisions for what checks to run and how to structure output. Reference PITFALLS.md for command compatibility issues.

### Phase 4: Content Migration and Tool Pages
**Rationale:** With tools onboarded and diagnostic scripts proven, migrate existing content into the site and add new tool documentation. This phase is content-heavy but low technical risk since the site scaffold already exists.
**Delivers:** Existing 11 tool pages migrated to site/src/content/docs/tools/ with Starlight frontmatter, new tool pages for dig/curl/netcat, diagnostic script documentation pages, getting-started guide, lab-setup guide
**Addresses:** Content migration pattern (notes/ → site/), docs-code drift mitigation (pitfall #5), table stakes for site launch
**Uses:** Starlight autogenerated sidebars, Tabs component for OS-specific installs, Expressive Code for syntax highlighting
**Research flags:** No research needed — content already exists in notes/ and just needs frontmatter + formatting

### Phase 5: Advanced Tools (traceroute/mtr)
**Rationale:** Add the path analysis tools once the core diagnostic pattern is validated. These are pre-installed (traceroute) or easily available (mtr via Homebrew/apt) but have platform quirks (mtr requires sudo on macOS).
**Delivers:** scripts/traceroute/examples.sh + 3 use-cases (trace-network-path, diagnose-latency, compare-routes), scripts/diagnostics/performance.sh (latency diagnostic using traceroute/mtr), Makefile targets
**Addresses:** Latency diagnostic feature, traceroute/mtr onboarding, root permission pitfall (#10)
**Avoids:** Sudo requirement surprises — detect platform and warn clearly
**Research flags:** Low — traceroute/mtr are standard tools with well-documented behavior, but need careful handling of sudo requirements

### Phase 6: Site Polish and Learning Paths
**Rationale:** With all core content in place, add the differentiator features that set this docs site apart from static cheatsheets. These are lower-risk enhancements that don't block functionality.
**Delivers:** "I want to..." task index page (migrated from USECASES.md), lab walkthrough as Starlight pages with asides/callouts, learning path pages (Recon Path, Web App Path, Network Debugging Path), cross-references between tool pages
**Addresses:** Site differentiators, guided learning features, competitive advantages identified in FEATURES.md
**Uses:** Starlight asides, internal markdown links, sidebar ordering
**Research flags:** No research needed — content organization and linking

### Phase 7: Web Enumeration Tools (gobuster/ffuf) [Defer to v1.x]
**Rationale:** These tools require Go installation or binary downloads (unlike other tools) and need wordlist infrastructure. They are pentest-specific (not general networking diagnostics). Add after core expansion is validated.
**Delivers:** scripts/gobuster/examples.sh + use-cases, scripts/ffuf/examples.sh + use-cases, wordlists/download.sh extension for SecLists directories/subdomains
**Addresses:** Web enumeration tool onboarding, gobuster/ffuf installation complexity pitfall (#8)
**Avoids:** Breaking the "just clone and run" experience by making these clearly marked as requiring installation
**Research flags:** Low — both tools have excellent official documentation, but wordlist management needs design decisions

### Phase Ordering Rationale

- **Foundations first:** common.sh extensions and site scaffold have no dependencies and enable all subsequent work. Getting the Astro base path right from the start prevents a painful debugging session after first deployment.
- **Tools before diagnostics:** Diagnostic scripts call dig, curl, nc, and traceroute. Building diagnostics before tools would require stubbing or would be untestable. The dependency chain is clear: common.sh → new tools → diagnostic scripts.
- **Site scaffold before content:** Scaffolding the site early (Phase 1) allows incremental content addition as tools are built (Phases 2-3) and a focused content migration phase (Phase 4) once the pattern is proven.
- **Core tools before advanced:** dig/curl/netcat are universally available and dependency-free. traceroute/mtr have sudo quirks. gobuster/ffuf require installation. Onboard in order of increasing friction.
- **Polish after functionality:** Learning paths and task index add value but don't block anything. Build them after core docs are in place and stable.

This ordering minimizes rework: if diagnostic pattern needs changes, we find out after 2 scripts (Phase 3) not after 5. If site migration strategy is wrong, we find out during Phase 4 with a small batch, not after migrating everything. If netcat variant detection doesn't work, we fix it in Phase 2 before building diagnostic scripts that depend on nc in Phase 3.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 3 (Diagnostic Scripts):** Moderate complexity — need design decisions for what checks each diagnostic runs, how to structure reports, which commands to use per platform. Reference PITFALLS.md #4 and #6 for command compatibility issues.
- **Phase 7 (gobuster/ffuf):** Low-moderate complexity — wordlist management strategy needs decisions (which lists, where stored, how updated). Installation complexity documented but may need a helper script pattern defined.

Phases with standard patterns (skip research-phase):
- **Phase 1:** Standard Astro/Starlight scaffold with official documentation, common.sh extension is simple additive change
- **Phase 2:** Follow existing Pattern A exactly — 28 use-case scripts provide clear template
- **Phase 4:** Content migration is mechanical, Starlight documentation is comprehensive
- **Phase 5:** traceroute/mtr are standard networking tools with abundant documentation
- **Phase 6:** Content organization and linking — no technical unknowns

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Astro/Starlight official docs verified, npm registry versions checked, GitHub Actions workflow is standard pattern |
| Features | HIGH | Competitor analysis (HackTricks, ired.team) establishes table stakes, existing project patterns define requirements, Starlight feature list verified |
| Architecture | HIGH | Existing codebase analysis provides clear patterns, Starlight project structure is well-documented, content migration path tested by community |
| Pitfalls | HIGH | Critical pitfalls verified via official docs and GitHub issues, platform-specific issues documented by tool maintainers, netcat variants researched thoroughly |

**Overall confidence:** HIGH

The research is grounded in official documentation (Astro, Starlight, tool man pages), verified npm package versions, existing codebase patterns, and community consensus on pitfalls. The bash scripting patterns are already established with 11 tools and 28 use-case scripts as reference. The Astro/Starlight stack is purpose-built for documentation sites and used by major tech companies. The critical pitfalls are well-documented with clear prevention strategies.

### Gaps to Address

- **Diagnostic script report format:** The research establishes Pattern B conceptually but the exact report structure (sections, status indicators, verbosity levels) needs design decisions during Phase 3. The common.sh functions (report_pass/fail/warn) are defined but how they compose into a full report needs a concrete example. RECOMMENDATION: Build a single diagnostic script template in Phase 3 that establishes the pattern before building multiple diagnostics.

- **Content migration mechanics:** The research recommends copying notes/*.md into site/src/content/docs/ rather than symlinking, and making site/ the authoritative location going forward. But the mechanics of keeping notes/ as a legacy reference (remove? symlink backward? deprecation notice?) need a decision during Phase 4. RECOMMENDATION: Migrate content, add a README.md in notes/ pointing to the site as the new location, keep the files as-is for backward compatibility but mark them stale.

- **Netcat variant recommendation:** Research identifies the variant fragmentation and recommends ncat (from nmap package) as the preferred variant since the project already requires nmap. But whether to make ncat a hard requirement or support all variants needs a decision in Phase 2. RECOMMENDATION: Soft preference for ncat with examples showing all variants — detect variant and show which examples apply.

- **CI validation for docs-code drift:** Research identifies the risk but doesn't specify the validation mechanism. Needs design: should validation extract content from scripts and compare? Check for file existence? Parse script output? RECOMMENDATION: Start simple in Phase 4 — CI checks that every scripts/*/examples.sh has a corresponding site/src/content/docs/tools/*.md file. Defer content verification to v2.

## Sources

### Primary (HIGH confidence)
- Astro Official Documentation — deployment, configuration, content collections
- Starlight Official Documentation — project structure, sidebar configuration, frontmatter reference, components
- npm registry — astro@5.17.1, @astrojs/starlight@0.37.6 (verified 2026-02-10)
- withastro/action GitHub Action — official build/deploy action for Astro sites
- ShellCheck GitHub — bash linting tool documentation
- Existing codebase — common.sh, examples.sh pattern, notes/*.md, USECASES.md (analyzed directly)

### Secondary (MEDIUM confidence)
- HackTricks Wiki, ired.team, highon.coffee — pentesting reference sites for competitor feature analysis
- Netcat variant comparison (grahamhelton.com, Baeldung) — variant fragmentation documentation
- Deprecated Linux networking commands guide (thelinuxcode.com, Red Hat) — iproute2 migration
- Astro GitHub issues #4229, #6504 — base path problems verified by maintainers
- Starlight GitHub discussions #1257 — custom content path limitations confirmed by maintainers

### Tertiary (LOW confidence)
- None — research used official sources and community consensus, no single-source or unverified claims

---
*Research completed: 2026-02-10*
*Ready for roadmap: yes*
