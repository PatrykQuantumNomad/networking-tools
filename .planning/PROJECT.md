# Networking Tools — Expansion & Documentation

## What This Is

A pentesting and network debugging learning lab built on bash scripts, covering 17 security and networking tools with 65+ scripts, 3 diagnostic auto-reports, an Astro/Starlight documentation site with learning paths, and Docker-based vulnerable targets for safe practice.

## Core Value

Ready-to-run scripts and accessible documentation that eliminate the need to remember tool flags and configurations — run one command, get what you need.

## Requirements

### Validated

- ✓ 11 pentesting tools with examples.sh scripts (nmap, tshark, metasploit, aircrack-ng, hashcat, skipfish, sqlmap, hping3, john, nikto, foremost) — existing
- ✓ 28 use-case scripts covering common pentest scenarios — existing
- ✓ Shared utility layer (common.sh) with logging, validation, safety checks — existing
- ✓ Makefile orchestration for all tools and lab management — existing
- ✓ Docker-based vulnerable lab targets (DVWA, Juice Shop, WebGoat, VulnerableApp) — existing
- ✓ Documentation: README, CLAUDE.md, USECASES.md, per-tool notes — existing
- ✓ Tool installation checker (check-tools.sh) — existing
- ✓ 8-phase lab walkthrough simulating realistic pentest engagement — existing
- ✓ Astro/Starlight documentation site with 29+ pages, learning paths, and CI deployment — v1.0
- ✓ 6 new networking tools (dig, curl, netcat, traceroute/mtr, gobuster, ffuf) with examples and use-case scripts — v1.0
- ✓ Diagnostic auto-report scripts for DNS, connectivity, and performance debugging — v1.0
- ✓ OS-specific install tabs and cross-references across all tool documentation pages — v1.0
- ✓ Wordlist infrastructure for SecLists web enumeration files — v1.0
- ✓ CI docs-completeness validation ensuring every tool has documentation — v1.0
- ✓ Cross-platform support with netcat variant detection, mtr sudo gating, BSD/GNU compatibility — v1.0

### Active

(None — next milestone requirements TBD via `/gsd:new-milestone`)

### Out of Scope

- Web application frontend (the site is static docs, not an interactive app) — complexity vs value
- Windows support — Unix-only project, WSL is sufficient
- Automated vulnerability remediation — this is a learning and detection tool, not a fixer
- Cloud infrastructure tools (AWS CLI, terraform) — different domain
- Real-time monitoring/alerting — scripts are run-once diagnostic, not daemons
- Offline mode — scripts require network access by nature

## Context

Shipped v1.0 with 13,585 LOC (8,180 bash + 5,405 site docs) across 124 files.
Tech stack: Bash scripts + Astro 5.x/Starlight + GitHub Actions + Docker Compose.
17 tools integrated into check-tools.sh with Makefile targets for each.
3 diagnostic scripts following Pattern B (structured auto-reports with pass/fail/warn).
Documentation site deployed to GitHub Pages with CI validation.

## Constraints

- **Tech Stack**: Bash for all scripts — consistency with existing codebase
- **Site Framework**: Astro for GitHub Pages — user preference
- **Platform**: macOS primary, Linux compatible — existing constraint
- **Script Pattern**: New tools must follow established pattern (examples.sh + use-case scripts) — architectural consistency
- **Diagnostic Scripts**: Must be diagnostic (auto-report), not interactive step-by-step — user preference
- **Dependencies**: Prefer tools available via Homebrew or pre-installed on macOS/Linux

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Astro over Jekyll/Hugo for GitHub Pages | Modern component islands, great markdown + interactive mixing | ✓ Good — 29+ pages, Tabs component, smooth DX |
| Diagnostic scripts as auto-report (not interactive) | User wants run-one-command results, not guided walkthroughs | ✓ Good — Pattern B established and reused 3x |
| GitHub Pages site is top priority | Makes project accessible/shareable, highest impact | ✓ Good — site with learning paths and CI deploy |
| Separate diagnostic pattern from pentest pattern | Debugging scripts serve different workflow than pentest education | ✓ Good — Pattern A (educational) vs Pattern B (auto-report) clear |
| detect_nc_variant() exclusion-based detection | Apple nc fork does not self-identify; eliminates false GNU detection | ✓ Good — works on macOS, Linux, and ncat |
| Counter wrapper functions for diagnostic tallying | Clean pass/fail/warn counts without polluting global state | ✓ Good — reused in all 3 diagnostics |
| -t 10 thread limit for gobuster/ffuf | Docker lab targets can't handle default 40 threads | ✓ Good — safe default for lab environment |
| || true guards on pipefail-sensitive patterns | set -e exits on grep no-match, arithmetic zero, nc -h | ✓ Good — prevents silent script failures |

---
*Last updated: 2026-02-11 after v1.0 milestone*
