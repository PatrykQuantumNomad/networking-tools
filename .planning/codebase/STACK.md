# Technology Stack

**Analysis Date:** 2026-02-23

## Languages

**Primary:**
- Bash 4.0+ - All pentesting scripts, shared library modules, lab utilities, and test helpers in `scripts/`, `wordlists/`, `tests/`

**Secondary:**
- JavaScript/TypeScript (ESM) - Documentation site in `site/src/`
- Makefile - Task runner for all tool and lab commands (`Makefile`)

## Runtime

**Environment:**
- Bash 4.0+ (scripts enforce this via `BASH_VERSINFO` guard in `scripts/common.sh`)
- Node.js (required for `site/` Astro build; version not pinned explicitly)

**Package Manager:**
- npm - Used in `site/` subdirectory
- Lockfile: `site/package-lock.json` present

## Frameworks

**Core:**
- None - Pure Bash scripts; no application framework

**Documentation Site:**
- Astro `^5.6.1` - Static site generator (`site/astro.config.mjs`)
- @astrojs/starlight `^0.37.6` - Docs theme plugin with sidebar, search, and dark-mode support (`site/astro.config.mjs`)
- sharp `^0.34.2` - Image processing for Astro builds (`site/package.json`)

**Testing:**
- BATS (Bash Automated Testing System) `1.13.0` - Bash script test framework (`tests/bats/`, `.github/workflows/tests.yml`)
- bats-assert - Assertion helpers (`tests/test_helper/bats-assert/`)
- bats-support - Base support library (`tests/test_helper/bats-support/`)
- bats-file - File assertion helpers (`tests/test_helper/bats-file/`)

**Build/Dev:**
- GNU Make - Task orchestration for scripts and Docker (`Makefile`)
- ShellCheck - Static analysis/linting of all `.sh` files (`Makefile` `lint` target, `.github/workflows/shellcheck.yml`)

## Key Dependencies

**Critical:**
- jq - Required at runtime only when `-j/--json` flag is used by any script (`scripts/lib/json.sh`). Not always installed; scripts detect its absence with a clear error.
- Docker / docker compose - Required for `make lab-up`; starts vulnerable lab targets via `labs/docker-compose.yml`

**External tools (not bundled; checked by `scripts/check-tools.sh`):**
- nmap - Network scanner
- tshark - Packet capture and analysis
- msfconsole (Metasploit Framework) - Exploitation framework
- aircrack-ng - Wireless security testing
- hashcat - GPU password cracking
- skipfish - Web application scanner
- sqlmap - SQL injection automation
- hping3 - Custom packet crafting
- john (john-jumbo) - CPU password cracking
- nikto - Web server vulnerability scanner
- foremost - Forensic file recovery
- dig - DNS query tool
- curl - HTTP client
- nc (netcat) - Network utility
- traceroute / mtr - Network path tracing
- gobuster - Directory/subdomain brute-forcer
- ffuf - Web fuzzer

## Configuration

**Environment:**
- No `.env` file required; scripts take all input as CLI arguments or Makefile `TARGET=` variable
- `LOG_LEVEL` environment variable controls logging verbosity (default: `info`); set to `debug` with `-v` flag
- `VERBOSE` environment variable enables timestamps in log output
- `EXECUTE_MODE` environment variable switches between show (print examples) and execute modes; set via `-x` flag
- `JSON_MODE` environment variable enables JSON output; set via `-j` flag

**Build:**
- `site/astro.config.mjs` - Astro site configuration including sidebar, SEO metadata, and social links
- `site/tsconfig.json` - TypeScript config extending `astro/tsconfigs/strict`
- `Makefile` - All developer workflows; `COMPOSE` variable points to `labs/docker-compose.yml`

## Platform Requirements

**Development:**
- macOS or Linux (scripts tested on both)
- Bash 4.0+ (macOS ships 3.2; install via `brew install bash`)
- Docker and docker compose for lab targets
- Node.js + npm for `site/` documentation site
- Individual pentesting tools installed per need (install hints in `scripts/check-tools.sh`)

**Production:**
- Documentation site deployed as static files to GitHub Pages via `withastro/action@v5` and `actions/deploy-pages@v4`
- Live at `https://networking-tools.patrykgolabek.dev`

---

*Stack analysis: 2026-02-23*
