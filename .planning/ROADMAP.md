# Roadmap: Networking Tools Expansion

## Overview

This roadmap transforms a bash-first pentesting learning lab into a comprehensive networking toolkit with an Astro/Starlight documentation site, diagnostic auto-report scripts, and five new networking tools. The 7 phases follow dependency order: infrastructure extensions first (common.sh, site scaffold, CI), then tool onboarding (dig, curl, netcat), then diagnostic scripts that depend on those tools, then content migration into the live site, then advanced tools (traceroute/mtr), site polish, and finally web enumeration tools (gobuster/ffuf). Every phase delivers a coherent, verifiable capability.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Foundations and Site Scaffold** - common.sh extensions + Astro site scaffold + GitHub Actions deploy
- [x] **Phase 2: Core Networking Tools** - dig, curl, netcat examples.sh and use-case scripts
- [x] **Phase 3: Diagnostic Scripts** - DNS and connectivity auto-report scripts (Pattern B)
- [x] **Phase 4: Content Migration and Tool Pages** - Migrate notes/*.md to site, add new tool and diagnostic docs
- [x] **Phase 5: Advanced Tools** - traceroute/mtr examples.sh, use-case scripts, and performance diagnostic
- [x] **Phase 6: Site Polish and Learning Paths** - Task index, learning paths, cross-references, lab walkthrough
- [ ] **Phase 7: Web Enumeration Tools** - gobuster/ffuf examples.sh, use-case scripts, wordlist infrastructure

## Phase Details

### Phase 1: Foundations and Site Scaffold
**Goal**: The infrastructure that all subsequent phases build on is in place -- common.sh supports diagnostic reports, the Astro site deploys to GitHub Pages with correct base path, and Makefile conventions are established for new targets.
**Depends on**: Nothing (first phase)
**Size**: M
**Requirements**: INFRA-001, INFRA-002, INFRA-003, INFRA-007, INFRA-011, SITE-001, SITE-002, SITE-004, SITE-006, SITE-009
**Pitfalls**: PITFALL-1 (Astro base path), PITFALL-2 (Jekyll processing), PITFALL-9 (site complexity), PITFALL-12 (Makefile collisions), PITFALL-13 (workflow triggers)
**Success Criteria** (what must be TRUE):
  1. Running `make site-dev` starts the Astro dev server and the landing page renders at localhost with working sidebar navigation
  2. Running `make site-build` produces a static build in `site/dist/` with `_astro/` assets intact
  3. Pushing to main triggers the GitHub Actions workflow and the site deploys to `https://<user>.github.io/networking-tools/` with working CSS, navigation, and search
  4. The `report_pass`, `report_fail`, `report_warn`, `report_skip`, `report_section`, and `run_check` functions exist in common.sh and produce colored output when called from a test script
  5. The Makefile uses a consistent namespacing convention for new targets (site-dev, site-build, site-preview) and `make help` groups targets by category
**Plans**: 3 plans

Plans:
- [x] 01-01-PLAN.md — common.sh diagnostic extensions (report_pass/fail/warn/skip, report_section, run_check)
- [x] 01-02-PLAN.md — Astro Starlight site scaffold with correct base path, landing page, sidebar, and Makefile targets
- [x] 01-03-PLAN.md — GitHub Actions workflow deploying to GitHub Pages via withastro/action

---

### Phase 2: Core Networking Tools
**Goal**: Users can learn and reference dig, curl, and netcat through the established 10-example pattern with task-focused use-case scripts, and the project tooling (check-tools.sh, Makefile) recognizes all three new tools.
**Depends on**: Phase 1 (Makefile conventions, common.sh)
**Size**: L
**Requirements**: TOOL-001, TOOL-002, TOOL-003, TOOL-004, TOOL-005, TOOL-006, TOOL-007, TOOL-008, TOOL-009, TOOL-010, TOOL-011, TOOL-012, TOOL-013, INFRA-004, INFRA-005
**Pitfalls**: PITFALL-3 (netcat variant incompatibility), PITFALL-11 (wget not on macOS), PITFALL-14 (dig missing on minimal Linux)
**Success Criteria** (what must be TRUE):
  1. Running `bash scripts/dig/examples.sh example.com` prints 10 numbered educational examples for dig with explanations
  2. Running `bash scripts/curl/examples.sh https://example.com` prints 10 numbered educational examples for curl with explanations
  3. Running `bash scripts/netcat/examples.sh 127.0.0.1` prints 10 numbered educational examples that identify the local netcat variant (OpenBSD/GNU/ncat) and label variant-specific flags
  4. Each tool has 3 working use-case scripts: dig (query-dns-records, check-dns-propagation, attempt-zone-transfer), curl (test-http-endpoints, check-ssl-certificate, debug-http-response), netcat (scan-ports, setup-listener, transfer-files)
  5. Running `make check` detects dig, curl, and nc as installed/missing alongside the existing 11 tools
**Plans**: 3 plans

Plans:
- [x] 02-01-PLAN.md — dig examples.sh + 3 use-case scripts + check-tools.sh and Makefile integration
- [x] 02-02-PLAN.md — curl examples.sh + 3 use-case scripts + check-tools.sh and Makefile integration
- [x] 02-03-PLAN.md — netcat examples.sh with variant detection + 3 use-case scripts + check-tools.sh and Makefile integration

---

### Phase 3: Diagnostic Scripts
**Goal**: Users can run a single command to get a structured DNS or connectivity diagnostic report with pass/fail/warn indicators, establishing the Pattern B auto-report approach for all future diagnostic scripts.
**Depends on**: Phase 1 (common.sh report_* functions), Phase 2 (dig, curl, nc available for testing)
**Size**: M
**Requirements**: DIAG-001, DIAG-002, DIAG-003, DIAG-004, DIAG-005, DIAG-006, INFRA-006, INFRA-010
**Pitfalls**: PITFALL-4 (deprecated Linux commands), PITFALL-6 (BSD vs GNU output parsing), PITFALL-7 (pattern divergence)
**Success Criteria** (what must be TRUE):
  1. Running `make diagnose-dns TARGET=example.com` produces a structured report with sections for resolution, record types, propagation, and reverse lookup, each with pass/fail/warn indicators
  2. Running `make diagnose-connectivity TARGET=example.com` produces a structured report walking DNS to IP to TCP to HTTP to TLS layers, each with pass/fail/warn indicators
  3. Both diagnostic scripts run non-interactively (no prompts, no user input required) and complete within a reasonable timeout
  4. Both diagnostic scripts work on macOS and Linux, using modern commands (ip/ss) with automatic fallback to legacy (ifconfig/netstat) when modern commands are unavailable
  5. USECASES.md includes new "I want to..." entries for DNS and connectivity diagnostics
**Plans**: 2 plans

Plans:
- [x] 03-01-PLAN.md — DNS diagnostic script (scripts/diagnostics/dns.sh) establishing Pattern B + diagnose-dns Makefile target
- [x] 03-02-PLAN.md — Connectivity diagnostic script (scripts/diagnostics/connectivity.sh) + diagnose-connectivity Makefile target + USECASES.md diagnostic entries

---

### Phase 4: Content Migration and Tool Pages
**Goal**: The Astro site contains documentation for all existing and new tools plus diagnostic scripts, making the site the authoritative reference for the project with a getting-started guide for new users.
**Depends on**: Phase 1 (site scaffold), Phase 2 (new tool scripts exist), Phase 3 (diagnostic scripts exist)
**Size**: L
**Requirements**: SITE-003, SITE-005, SITE-007, SITE-008
**Pitfalls**: PITFALL-5 (documentation-code drift), PITFALL-9 (site complexity)
**Success Criteria** (what must be TRUE):
  1. All 11 existing tool pages from notes/*.md are available at `/networking-tools/tools/<tool>/` on the deployed site with correct Starlight frontmatter, syntax highlighting, and copy buttons
  2. New tool pages for dig, curl, and netcat exist on the site with examples, use-case descriptions, and install instructions
  3. Diagnostic script documentation pages for DNS and connectivity exist on the site explaining what each diagnostic checks and how to interpret results
  4. A getting-started guide exists on the site covering installation, first run (`make check`), and lab setup (`make lab-up`)
  5. The site sidebar correctly groups content under Tools, Guides, and Diagnostics categories
**Plans**: 3 plans

Plans:
- [x] 04-01-PLAN.md — Migrate 11 existing tool pages and lab walkthrough from notes/*.md to site with Starlight frontmatter
- [x] 04-02-PLAN.md — Create new tool pages (dig, curl, netcat) and diagnostic docs (DNS, connectivity)
- [x] 04-03-PLAN.md — Getting-started guide

---

### Phase 5: Advanced Tools
**Goal**: Users can learn traceroute/mtr through educational examples and use-case scripts, and can run a performance diagnostic that identifies where latency occurs hop-by-hop.
**Depends on**: Phase 1 (common.sh), Phase 3 (diagnostic pattern established)
**Size**: M
**Requirements**: TOOL-014, TOOL-015, TOOL-016, TOOL-017, TOOL-018, DIAG-007, INFRA-009 (partial: traceroute/mtr targets), SITE-015
**Pitfalls**: PITFALL-10 (mtr requires sudo on macOS)
**Success Criteria** (what must be TRUE):
  1. Running `bash scripts/traceroute/examples.sh 8.8.8.8` prints 10 numbered educational examples for traceroute and mtr
  2. Use-case scripts trace-network-path, diagnose-latency, and compare-routes each work and produce clear output
  3. On macOS, mtr-dependent scripts detect the sudo requirement and either prompt for elevation or warn clearly rather than failing silently
  4. Running `make diagnose-performance TARGET=example.com` produces a structured latency report with per-hop statistics
  5. The traceroute/mtr tool page exists on the Astro site
**Plans**: 2 plans

Plans:
- [x] 05-01-PLAN.md — traceroute/mtr examples.sh + 3 use-case scripts + check-tools.sh/Makefile/USECASES.md integration
- [x] 05-02-PLAN.md — Performance diagnostic script (scripts/diagnostics/performance.sh) + site pages (traceroute.md, performance.md)

---

### Phase 6: Site Polish and Learning Paths
**Goal**: The site goes beyond reference documentation to become a guided learning resource with task-organized navigation, structured learning paths, and cross-referenced tool pages.
**Depends on**: Phase 4 (all core content migrated), Phase 5 (traceroute/mtr content)
**Size**: M
**Requirements**: SITE-010, SITE-011, SITE-012, SITE-013, SITE-014, SITE-016
**Pitfalls**: PITFALL-5 (documentation-code drift -- CI validation)
**Success Criteria** (what must be TRUE):
  1. An "I want to..." task index page exists on the site, linking diagnostic and tool pages by task rather than by tool name
  2. At least 3 guided learning paths exist (Recon, Web App Testing, Network Debugging) with ordered sequences of tool pages
  3. Tool pages include OS-specific install tabs (macOS Homebrew vs Linux apt) using Starlight Tabs component
  4. The lab walkthrough is formatted as Starlight pages with asides and callouts for tips and warnings
  5. CI validates that every `scripts/*/examples.sh` has a corresponding documentation page on the site
**Plans**: 3 plans

Plans:
- [x] 06-01-PLAN.md — Rename tool pages to .mdx, add OS-specific install tabs, add cross-reference sections
- [x] 06-02-PLAN.md — Task index page, three learning path pages, lab walkthrough asides
- [x] 06-03-PLAN.md — CI docs-completeness validation script and workflow integration

---

### Phase 7: Web Enumeration Tools
**Goal**: Users can learn gobuster and ffuf for web content discovery and fuzzing, with wordlist infrastructure that makes the tools immediately usable against lab targets.
**Depends on**: Phase 2 (tool pattern established), Phase 4 (site ready for new tool pages)
**Size**: M
**Requirements**: TOOL-019, TOOL-020, TOOL-021, TOOL-022, TOOL-023, TOOL-024, INFRA-008, INFRA-009 (partial: gobuster/ffuf targets)
**Pitfalls**: PITFALL-8 (gobuster/ffuf require Go or binary install)
**Success Criteria** (what must be TRUE):
  1. Running `bash scripts/gobuster/examples.sh http://localhost:8080` prints 10 numbered educational examples for gobuster
  2. Running `bash scripts/ffuf/examples.sh http://localhost:8080` prints 10 numbered educational examples for ffuf
  3. Use-case scripts discover-directories, enumerate-subdomains (gobuster) and fuzz-parameters (ffuf) work against lab targets
  4. A wordlist download helper fetches SecLists common directories and subdomains wordlists for use with both tools
  5. `make check` detects gobuster and ffuf with clear install hints (Homebrew, Go install, binary download)
**Plans**: 3 plans

Plans:
- [ ] 07-01-PLAN.md — gobuster examples.sh + 2 use-case scripts + check-tools.sh/Makefile integration + gobuster.mdx site page
- [ ] 07-02-PLAN.md — ffuf examples.sh + 1 use-case script + check-tools.sh/Makefile integration + ffuf.mdx site page
- [ ] 07-03-PLAN.md — Wordlist download extension for SecLists directories/subdomains + USECASES.md web enumeration entries

---

## Coverage

### v1 Requirements (37 mapped)

| REQ-ID | Phase | Description |
|--------|-------|-------------|
| INFRA-001 | 1 | common.sh: report_pass function |
| INFRA-002 | 1 | common.sh: report_section function |
| INFRA-003 | 1 | common.sh: run_check function |
| INFRA-007 | 1 | Makefile: site targets |
| INFRA-011 | 1 | Makefile: namespaced targets |
| SITE-001 | 1 | Astro 5.x + Starlight scaffold |
| SITE-002 | 1 | GitHub Actions deploy workflow |
| SITE-004 | 1 | Landing page |
| SITE-006 | 1 | Sidebar navigation |
| SITE-009 | 1 | Makefile site targets |
| TOOL-001 | 2 | dig examples.sh |
| TOOL-002 | 2 | dig: query-dns-records.sh |
| TOOL-003 | 2 | dig: check-dns-propagation.sh |
| TOOL-004 | 2 | dig: attempt-zone-transfer.sh |
| TOOL-005 | 2 | curl examples.sh |
| TOOL-006 | 2 | curl: test-http-endpoints.sh |
| TOOL-007 | 2 | curl: check-ssl-certificate.sh |
| TOOL-008 | 2 | curl: debug-http-response.sh |
| TOOL-009 | 2 | netcat examples.sh |
| TOOL-010 | 2 | netcat: scan-ports.sh |
| TOOL-011 | 2 | netcat: setup-listener.sh |
| TOOL-012 | 2 | netcat: transfer-files.sh |
| TOOL-013 | 2 | netcat variant detection |
| INFRA-004 | 2 | check-tools.sh: dig, curl, nc |
| INFRA-005 | 2 | Makefile: new tool targets |
| DIAG-001 | 3 | DNS diagnostic script |
| DIAG-002 | 3 | Connectivity diagnostic script |
| DIAG-003 | 3 | Modern commands with fallback |
| DIAG-004 | 3 | Structured report with indicators |
| DIAG-005 | 3 | Non-interactive diagnostics |
| DIAG-006 | 3 | macOS + Linux compatibility |
| INFRA-006 | 3 | Makefile: diagnostic targets |
| INFRA-010 | 3 | USECASES.md diagnostic entries |
| SITE-003 | 4 | Migrate 11 tool pages |
| SITE-005 | 4 | Getting-started guide |
| SITE-007 | 4 | New tool pages (dig, curl, netcat) |
| SITE-008 | 4 | Diagnostic documentation pages |

### v1.x Requirements (21 mapped to Phases 5-7)

| REQ-ID | Phase | Description |
|--------|-------|-------------|
| TOOL-014 | 5 | traceroute examples.sh |
| TOOL-015 | 5 | traceroute: trace-network-path.sh |
| TOOL-016 | 5 | traceroute: diagnose-latency.sh |
| TOOL-017 | 5 | traceroute: compare-routes.sh |
| TOOL-018 | 5 | mtr sudo detection |
| DIAG-007 | 5 | Performance diagnostic script |
| INFRA-009 | 5 | Makefile: traceroute/mtr targets (partial) |
| SITE-015 | 5 | Traceroute/mtr site page |
| SITE-010 | 6 | Task index page |
| SITE-011 | 6 | OS-specific install tabs |
| SITE-012 | 6 | Lab walkthrough as Starlight pages |
| SITE-013 | 6 | Guided learning paths |
| SITE-014 | 6 | Cross-references between tool pages |
| SITE-016 | 6 | CI docs-completeness check |
| TOOL-019 | 7 | gobuster examples.sh |
| TOOL-020 | 7 | gobuster: discover-directories.sh |
| TOOL-021 | 7 | gobuster: enumerate-subdomains.sh |
| TOOL-022 | 7 | ffuf examples.sh |
| TOOL-023 | 7 | ffuf: fuzz-parameters.sh |
| TOOL-024 | 7 | Wordlist download extension |
| INFRA-008 | 7 | check-tools.sh: gobuster, ffuf |
| INFRA-009 | 7 | Makefile: gobuster/ffuf targets (partial) |

### v2+ Requirements (deferred)

| REQ-ID | Description |
|--------|-------------|
| DIAG-008 | DNS comparison mode (multi-resolver) |
| DIAG-009 | Machine-parseable output (--json) |

### Coverage Summary

- **v1 requirements**: 37/37 mapped (Phases 1-4)
- **v1.x requirements**: 22/21 mapped (Phases 5-7; INFRA-009 split across 5 and 7)
- **v2+ requirements**: 2 deferred
- **Orphaned requirements**: 0

Note: REQUIREMENTS.md states 33 v1 / 16 v1.x / 2 v2+ = 51 total. Actual count from the requirement tables is 37 v1 / 21 v1.x / 2 v2+ = 60 total. This roadmap maps from the actual requirements listed, not the summary counts.

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7

| Phase | Plans Complete | Status | Completed |
|-------|---------------|--------|-----------|
| 1. Foundations and Site Scaffold | 3/3 | Complete | 2026-02-10 |
| 2. Core Networking Tools | 3/3 | Complete | 2026-02-10 |
| 3. Diagnostic Scripts | 2/2 | Complete | 2026-02-10 |
| 4. Content Migration and Tool Pages | 3/3 | Complete | 2026-02-10 |
| 5. Advanced Tools | 2/2 | Complete | 2026-02-10 |
| 6. Site Polish and Learning Paths | 3/3 | Complete | 2026-02-10 |
| 7. Web Enumeration Tools | 0/3 | Not started | - |

---
*Roadmap created: 2026-02-10*
*Depth: comprehensive*
*v1 milestone: Phases 1-4 (37 requirements)*
*v1.x milestone: Phases 5-7 (21 requirements)*
