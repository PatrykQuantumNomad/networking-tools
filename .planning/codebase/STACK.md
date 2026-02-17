# Technology Stack

**Analysis Date:** 2026-02-17

## Languages

**Primary:**
- Bash 4.0+ - All educational scripts, automation, and utilities
- TypeScript/JavaScript - Documentation site only

**Secondary:**
- Markdown - Documentation content in `site/src/content/docs/`

## Runtime

**Environment:**
- Bash 4.0+ (macOS ships Bash 3.2, requires `brew install bash`)
- Node.js (for documentation site build only)

**Package Manager:**
- npm (for site dependencies only)
- Lockfile: `site/package-lock.json` present

## Frameworks

**Core:**
- No framework for main project (pure Bash scripts)
- Astro 5.6.1 - Static site generator for documentation
- Starlight 0.37.6 - Astro documentation theme

**Testing:**
- BATS 1.13.0 - Bash Automated Testing System
- BATS extensions: bats-support, bats-assert, bats-file

**Build/Dev:**
- Make - Task runner via `Makefile`
- Docker Compose - Lab environment orchestration
- ShellCheck - Static analysis for Bash scripts (CI/CD)

## Key Dependencies

**Critical:**
- Docker Compose - Orchestrates vulnerable lab targets (`labs/docker-compose.yml`)
- External pentesting tools: nmap, tshark, metasploit, hashcat, john, sqlmap, nikto, skipfish, hping3, aircrack-ng, foremost, gobuster, ffuf, dig, curl, netcat, traceroute, mtr

**Infrastructure:**
- sharp 0.34.2 - Image processing for Astro site

## Configuration

**Environment:**
- No environment variables required for core scripts
- All configuration via command-line arguments
- Docker Compose defaults in `labs/docker-compose.yml`

**Build:**
- `Makefile` - Main task definitions for tools, lab, testing
- `site/astro.config.mjs` - Astro site configuration
- `site/tsconfig.json` - TypeScript config (extends astro/tsconfigs/strict)
- `.github/workflows/*.yml` - CI/CD workflows

## Platform Requirements

**Development:**
- Bash 4.0+ (Linux/macOS)
- Docker (for lab targets)
- npm (for documentation site)
- ShellCheck (for linting)

**Production:**
- GitHub Pages (for documentation site)
- Scripts can run on any Unix-like system with Bash 4.0+ and required pentesting tools installed

---

*Stack analysis: 2026-02-17*
