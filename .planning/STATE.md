# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-10)

**Core value:** Ready-to-run scripts and accessible documentation that eliminate the need to remember tool flags and configurations -- run one command, get what you need.
**Current focus:** Phase 7 in progress -- web enumeration tools

## Current Position

Phase: 7 of 7 (Web Enumeration Tools)
Plan: 2 of 3 in current phase (07-01 and 07-03 complete, 07-02 remaining)
Status: Executing Phase 7 -- Plan 01 (gobuster) complete
Last activity: 2026-02-11 -- Completed 07-01 gobuster scripts, check-tools integration, and site docs

Progress: [###################.] 95%

## Performance Metrics

**Velocity:**
- Total plans completed: 18
- Average duration: 4min
- Total execution time: 1.13 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01-foundations | 3 | 7min | 2min |
| 02-core-networking-tools | 3 | 11min | 4min |
| 03-diagnostic-scripts | 2 | 7min | 4min |
| 04-content-migration-and-tool-pages | 3 | 17min | 6min |
| 05-advanced-tools | 2 | 11min | 6min |
| 06-site-polish-and-learning-paths | 3 | 16min | 5min |
| 07-web-enumeration-tools | 2 | 7min | 4min |

**Recent Trend:**
- Last 5 plans: 06-01 (7min), 06-02 (6min), 06-03 (3min), 07-03 (2min), 07-01 (5min)
- Trend: stable

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- [Roadmap]: 7-phase structure derived from requirements with dependency ordering (infra -> tools -> diagnostics -> content -> advanced -> polish -> enumeration)
- [Roadmap]: REQUIREMENTS.md count discrepancy noted (stated 33 v1, actual 37 v1) -- roadmap maps all actual requirements
- [Roadmap]: INFRA-009 split across Phases 5 and 7 (traceroute/mtr targets in 5, gobuster/ffuf targets in 7)
- [01-01]: Added || true guard on empty output test in run_check to prevent set -e exit on failed checks with no output
- [01-02]: Base path /networking-tools for GitHub Pages under patrykquantumnomad.github.io
- [01-02]: Sidebar autogenerate pattern for Tools/Guides/Diagnostics categories
- [01-02]: Makefile site-* prefix convention for documentation site commands
- [01-03]: No path filtering on push trigger to prevent stale deployments
- [01-03]: actions/deploy-pages@v4 bypasses Jekyll -- no .nojekyll file needed
- [01-03]: withastro/action@v5 handles Node.js setup and package install automatically
- [02-01]: dig -v outputs to stderr; dedicated get_version case with 2>&1 redirect
- [02-01]: Use-case scripts use sensible default (example.com) instead of require_target
- [02-02]: curl uses default get_version() case -- no special handling needed (unlike dig)
- [02-02]: SSL cert script strips protocol prefix from target for clean display
- [02-02]: Zero wget references in curl scripts per PITFALL-11 (macOS has no wget)
- [02-03]: detect_nc_variant() uses exclusion-based detection -- Apple fork does not self-identify, defaults to openbsd
- [02-03]: nc -h exits non-zero on macOS/OpenBSD; added || true guard in get_version()
- [02-03]: Used nc-listener/nc-transfer Makefile target names to avoid collision with metasploit setup-listener
- [03-01]: Counter wrapper functions (count_pass/fail/warn) for clean pass/fail/warn tallying in diagnostic scripts
- [03-01]: WARN for missing AAAA/MX/TXT/PTR records, FAIL for missing A/NS/SOA -- severity-appropriate thresholds
- [03-01]: Pattern B established: preamble, require_cmd, default target, info header, report_section sections, count wrappers, summary
- [03-02]: macOS-first for get_local_ip (ifconfig on Darwin, ip on Linux) -- iproute2mac ip behaves differently
- [03-02]: WARN not FAIL for blocked ICMP -- many hosts block ping; indicates filtering, not broken connectivity
- [03-02]: Cross-platform helpers pattern: OS_TYPE=$(uname -s) with Darwin/Linux branching + || true guards for pipefail safety
- [04-03]: Used port 3030 for Juice Shop (matching docker-compose.yml) instead of plan's 3000
- [04-03]: Listed 14 tools (matching check-tools.sh TOOL_ORDER) instead of 10
- [04-02]: Tool pages assembled directly from scripts (dig, curl, netcat have no notes/*.md files)
- [04-02]: Diagnostic pages use table-based severity explanation format (check/severity/meaning columns)
- [04-01]: Sidebar ordering groups tools by function: network(1-3), web(7-9), exploit(10), cracking(11-12), wireless(13), forensics(14)
- [04-01]: Metasploit console commands use text language tag instead of bash to avoid false syntax highlighting
- [05-01]: traceroute version detection returns 'installed' (macOS BSD has no --version flag)
- [05-01]: diagnose-latency.sh warns and exits on macOS without sudo (never auto-elevates)
- [05-01]: examples.sh requires traceroute only; mtr examples print regardless with install note if missing
- [05-01]: diagnose-performance Makefile target points to scripts/diagnostics/performance.sh (created by Plan 02)
- [05-01]: macOS uses -a for AS lookups in traceroute (not -A like Linux)
- [05-02]: _run_with_timeout wrapper (30s traceroute, 60s mtr) to prevent hangs on unreachable targets
- [05-02]: 50ms threshold for latency spike detection between consecutive hops
- [05-02]: pipefail-safe grep in while loops: || true on grep pipes that may return no matches
- [06-01]: Metasploit uses 2-tab layout (nightly installer + Kali pre-installed) instead of standard 3-OS-tab pattern
- [06-01]: Skipfish uses 2-tab layout (MacPorts + Debian only) -- not in Homebrew or RHEL repos
- [06-01]: Pre-installed tools (curl, netcat, traceroute) show informational text in macOS tab instead of install commands
- [06-02]: Sidebar ordering: task-index(3), learning paths(10-12) to keep getting-started and lab-walkthrough first
- [06-02]: Learning path steps include specific make commands for immediate practice
- [06-03]: || true guard on ((errors++)) to prevent set -e exit when post-increment evaluates to 0 (falsy)
- [07-03]: No exit 1 on SecLists download failure (non-critical, unlike rockyou.txt) -- script continues if supplementary wordlist fails
- [07-03]: Updated Makefile wordlists help text to reflect expanded scope (password cracking + web enumeration)
- [07-01]: Used -d flag for gobuster DNS mode (standard documented flag) instead of plan's -do which was based on uncertain research
- [07-01]: gobuster version detection uses 'gobuster version' subcommand with head -1 pipe
- [07-01]: Wordlist-dependent scripts check file existence before demo, print 'make wordlists' instruction if missing
- [07-01]: Thread count -t 10 in all gobuster examples to keep safe for Docker lab targets

### Pending Todos

None yet.

### Blockers/Concerns

- REQUIREMENTS.md summary counts (33/16/2 = 51) do not match actual requirement table counts (37/21/2 = 60). Recommend updating REQUIREMENTS.md counts before Phase 1 planning.

## Session Continuity

Last session: 2026-02-11
Stopped at: Completed 07-01-PLAN.md -- gobuster scripts, check-tools integration, and site docs complete
Resume file: None
