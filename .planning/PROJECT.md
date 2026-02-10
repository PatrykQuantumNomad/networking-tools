# Networking Tools — Expansion & Documentation

## What This Is

A pentesting and network debugging learning lab built on bash scripts, covering 11 security tools with 28 use-case scripts and Docker-based vulnerable targets. This project is expanding to include everyday networking diagnostic tools, additional security enumeration tools, and an Astro-powered GitHub Pages site that makes all documentation searchable and interactive.

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

### Active

- [ ] Astro-powered GitHub Pages site with reference docs and guided learning paths
- [ ] Diagnostic scripts for DNS debugging (resolution failures, record queries, propagation)
- [ ] Diagnostic scripts for connectivity debugging (reachability, port checks, routing)
- [ ] Diagnostic scripts for performance debugging (latency, packet loss, throughput)
- [ ] New tool: dig/nslookup/whois — DNS lookup, domain info, record queries
- [ ] New tool: curl/wget — HTTP testing, API debugging, file transfer
- [ ] New tool: netcat — raw TCP/UDP connections, port scanning, file transfer
- [ ] New tool: traceroute/mtr — path analysis, latency measurement, hop-by-hop diagnosis
- [ ] New tool: gobuster/ffuf — directory brute-forcing, web fuzzing, content discovery
- [ ] Updated Makefile and check-tools.sh to cover new tools
- [ ] Updated USECASES.md with new "I want to..." entries for networking diagnostics

### Out of Scope

- Web application frontend (the site is static docs, not an interactive app) — complexity vs value
- Windows support — Unix-only project, WSL is sufficient
- Automated vulnerability remediation — this is a learning and detection tool, not a fixer
- Cloud infrastructure tools (AWS CLI, terraform) — different domain
- Real-time monitoring/alerting — scripts are run-once diagnostic, not daemons

## Context

- Project is bash-only with a well-established script pattern (source common.sh, require_cmd, safety_banner, 10 examples, interactive demo)
- macOS is the primary platform with known limitations (aircrack-ng monitor mode Linux-only, skipfish via MacPorts, hping3 requires sudo)
- The diagnostic scripts introduce a new pattern: run-one-command-get-a-report (vs. the existing educational-examples pattern)
- Astro chosen for the site — modern component islands, good markdown support, interactive elements
- The site will be deployed via GitHub Pages with a CI build step
- New tools (dig, curl, traceroute, etc.) are already installed on most systems — no complex install requirements
- gobuster/ffuf are security-specific and may need Homebrew/Go installation

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
| Astro over Jekyll/Hugo for GitHub Pages | Modern component islands, great markdown + interactive mixing | — Pending |
| Diagnostic scripts as auto-report (not interactive) | User wants run-one-command results, not guided walkthroughs | — Pending |
| GitHub Pages site is top priority | Makes project accessible/shareable, highest impact | — Pending |
| Separate diagnostic pattern from pentest pattern | Debugging scripts serve different workflow than pentest education | — Pending |

---
*Last updated: 2026-02-10 after initialization*
