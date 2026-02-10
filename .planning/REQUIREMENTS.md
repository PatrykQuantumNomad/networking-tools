# Requirements

**Project:** networking-tools expansion
**Generated:** 2026-02-10
**Source:** Research (SUMMARY.md, FEATURES.md, ARCHITECTURE.md, PITFALLS.md)

## Scope Legend

- **v1** — Must ship in first milestone
- **v1.x** — Add after core is validated
- **v2+** — Future consideration

---

## Category: Documentation Site (SITE)

| REQ-ID | Requirement | Scope | Source |
|--------|------------|-------|--------|
| SITE-001 | Astro 5.x + Starlight site scaffold in `site/` subdirectory with correct `base: '/networking-tools'` | v1 | ARCH, PITFALL-1 |
| SITE-002 | GitHub Actions workflow deploying to GitHub Pages via `withastro/action` | v1 | STACK, PITFALL-2 |
| SITE-003 | Migrate existing 11 tool pages from `notes/*.md` to `site/src/content/docs/tools/` with Starlight frontmatter | v1 | FEATURES, ARCH |
| SITE-004 | Landing page with project overview and quick links | v1 | FEATURES |
| SITE-005 | Getting-started guide (installation, first run, lab setup) | v1 | FEATURES |
| SITE-006 | Sidebar navigation organized by category (Tools, Guides, Diagnostics) using autogenerate | v1 | FEATURES, ARCH |
| SITE-007 | New tool pages for dig, curl, netcat added to site | v1 | FEATURES |
| SITE-008 | Diagnostic script documentation pages (DNS, connectivity) | v1 | FEATURES |
| SITE-009 | Makefile targets: `site-dev`, `site-build`, `site-preview` | v1 | ARCH |
| SITE-010 | "I want to..." task index page migrated from USECASES.md | v1.x | FEATURES |
| SITE-011 | OS-specific install tabs (macOS Homebrew vs Linux apt) using Starlight Tabs | v1.x | FEATURES |
| SITE-012 | Lab walkthrough formatted as Starlight pages with asides/callouts | v1.x | FEATURES |
| SITE-013 | Guided learning paths (Recon, Web App, Network Debugging) | v1.x | FEATURES |
| SITE-014 | Cross-references between tool pages | v1.x | FEATURES |
| SITE-015 | New tool pages for traceroute/mtr added to site | v1.x | FEATURES |
| SITE-016 | CI check: every `scripts/*/examples.sh` has corresponding docs page | v1.x | PITFALL-5 |

## Category: New Tool Scripts (TOOL)

| REQ-ID | Requirement | Scope | Source |
|--------|------------|-------|--------|
| TOOL-001 | `scripts/dig/examples.sh` — 10 educational examples following Pattern A | v1 | FEATURES |
| TOOL-002 | dig use-case: `query-dns-records.sh` (A, AAAA, MX, NS, TXT, SOA) | v1 | FEATURES |
| TOOL-003 | dig use-case: `check-dns-propagation.sh` (multi-resolver comparison) | v1 | FEATURES |
| TOOL-004 | dig use-case: `attempt-zone-transfer.sh` (AXFR) | v1 | FEATURES |
| TOOL-005 | `scripts/curl/examples.sh` — 10 educational examples following Pattern A | v1 | FEATURES |
| TOOL-006 | curl use-case: `test-http-endpoints.sh` (GET/POST/PUT/DELETE) | v1 | FEATURES |
| TOOL-007 | curl use-case: `check-ssl-certificate.sh` (cert validity, expiry, chain) | v1 | FEATURES |
| TOOL-008 | curl use-case: `debug-http-response.sh` (timing breakdown, verbose) | v1 | FEATURES |
| TOOL-009 | `scripts/netcat/examples.sh` — 10 educational examples with variant detection | v1 | FEATURES, PITFALL-3 |
| TOOL-010 | netcat use-case: `scan-ports.sh` (basic port scanning) | v1 | FEATURES |
| TOOL-011 | netcat use-case: `setup-listener.sh` (listen for connections) | v1 | FEATURES |
| TOOL-012 | netcat use-case: `transfer-files.sh` (send/receive over TCP) | v1 | FEATURES |
| TOOL-013 | Netcat variant detection helper in common.sh or netcat scripts | v1 | PITFALL-3 |
| TOOL-014 | `scripts/traceroute/examples.sh` — 10 examples for traceroute/mtr | v1.x | FEATURES |
| TOOL-015 | traceroute use-case: `trace-network-path.sh` | v1.x | FEATURES |
| TOOL-016 | traceroute use-case: `diagnose-latency.sh` (mtr with per-hop stats) | v1.x | FEATURES |
| TOOL-017 | traceroute use-case: `compare-routes.sh` (TCP vs ICMP vs UDP) | v1.x | FEATURES |
| TOOL-018 | mtr sudo detection and warning on macOS | v1.x | PITFALL-10 |
| TOOL-019 | `scripts/gobuster/examples.sh` — 10 examples | v1.x | FEATURES |
| TOOL-020 | gobuster use-case: `discover-directories.sh` | v1.x | FEATURES |
| TOOL-021 | gobuster use-case: `enumerate-subdomains.sh` | v1.x | FEATURES |
| TOOL-022 | `scripts/ffuf/examples.sh` — 10 examples | v1.x | FEATURES |
| TOOL-023 | ffuf use-case: `fuzz-parameters.sh` | v1.x | FEATURES |
| TOOL-024 | Wordlist download extension for SecLists directories/subdomains | v1.x | FEATURES |

## Category: Diagnostic Scripts (DIAG)

| REQ-ID | Requirement | Scope | Source |
|--------|------------|-------|--------|
| DIAG-001 | `scripts/diagnostics/dns.sh` — auto-report for DNS issues (resolution, records, propagation, reverse) | v1 | FEATURES |
| DIAG-002 | `scripts/diagnostics/connectivity.sh` — auto-report for connectivity (ping, port, HTTP, SSL) | v1 | FEATURES |
| DIAG-003 | Diagnostic scripts use modern commands (ip/ss) with fallback to legacy (ifconfig/netstat) | v1 | PITFALL-4 |
| DIAG-004 | Diagnostic scripts produce structured report with pass/fail/warn indicators | v1 | FEATURES, ARCH |
| DIAG-005 | Diagnostic scripts are non-interactive (run once, get report) | v1 | PROJECT.md |
| DIAG-006 | Diagnostic scripts work on both macOS and Linux | v1 | PITFALL-4, PITFALL-6 |
| DIAG-007 | `scripts/diagnostics/performance.sh` — latency diagnostic (traceroute/mtr per-hop) | v1.x | FEATURES |
| DIAG-008 | DNS comparison mode: test against multiple resolvers | v2+ | FEATURES |
| DIAG-009 | Machine-parseable output (--json flag) | v2+ | FEATURES |

## Category: Infrastructure (INFRA)

| REQ-ID | Requirement | Scope | Source |
|--------|------------|-------|--------|
| INFRA-001 | common.sh: add `report_pass`, `report_fail`, `report_warn`, `report_skip` functions | v1 | ARCH |
| INFRA-002 | common.sh: add `report_section` function | v1 | ARCH |
| INFRA-003 | common.sh: add `run_check` function (execute with timeout, report result) | v1 | ARCH |
| INFRA-004 | `check-tools.sh`: add dig, curl, nc, traceroute, mtr to tool detection | v1 | FEATURES |
| INFRA-005 | Makefile: add targets for new tools (make dig, make curl, make netcat) | v1 | FEATURES |
| INFRA-006 | Makefile: add diagnostic targets (make diagnose-dns, make diagnose-connectivity) | v1 | FEATURES |
| INFRA-007 | Makefile: add site targets (make site-dev, make site-build) | v1 | ARCH |
| INFRA-008 | `check-tools.sh`: add gobuster, ffuf to tool detection | v1.x | FEATURES |
| INFRA-009 | Makefile: add traceroute/mtr and gobuster/ffuf targets | v1.x | FEATURES |
| INFRA-010 | Updated USECASES.md with diagnostic "I want to..." entries | v1 | FEATURES |
| INFRA-011 | Makefile: namespaced targets to avoid collision at scale | v1 | PITFALL-12 |

---

## Requirement Counts

| Scope | Count |
|-------|-------|
| v1 | 33 |
| v1.x | 16 |
| v2+ | 2 |
| **Total** | **51** |

## Coverage Matrix (Requirements → Research)

| Research Source | Requirements Derived |
|---------------|---------------------|
| FEATURES.md | SITE-003–008, SITE-010–015, TOOL-001–024, DIAG-001–002, DIAG-007–009, INFRA-004–006, INFRA-008–010 |
| ARCHITECTURE.md | SITE-001, SITE-006, SITE-009, DIAG-004, INFRA-001–003, INFRA-007, INFRA-011 |
| PITFALLS.md | SITE-001 (P1), SITE-002 (P2), SITE-016 (P5), TOOL-009/013 (P3), TOOL-018 (P10), DIAG-003/006 (P4/P6), INFRA-011 (P12) |
| STACK.md | SITE-001–002 |
| PROJECT.md | DIAG-005 |

---
*Requirements generated: 2026-02-10*
*Ready for roadmap: yes*
