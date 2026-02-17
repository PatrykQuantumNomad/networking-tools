# Networking Tools — Expansion & Documentation

## What This Is

A pentesting and network debugging learning lab built on bash scripts, covering 17 security and networking tools with 81 dual-mode scripts, an 8-module library infrastructure with structured JSON output via `-j`/`--json` flag, 435-test BATS regression suite with CI enforcement, structured metadata headers on all 78 scripts, 3 diagnostic auto-reports, a branded Astro/Starlight documentation site with dark orange/amber theme, custom homepage, learning paths, and Docker-based vulnerable targets for safe practice.

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
- ✓ Dark + orange/amber accent color palette across all UI elements with WCAG AA light mode contrast — v1.1
- ✓ Custom terminal-prompt SVG logo with dual dark/light variants and adaptive favicon — v1.1
- ✓ Sidebar navigation cleanup removing redundant section index entries — v1.1
- ✓ Homepage redesign with branded hero, tool card grids by category, feature highlights, and guide links — v1.1
- ✓ 8-module library infrastructure (strict mode, stack traces, logging, cleanup, retry, args) behind backward-compatible common.sh — v1.2
- ✓ Dual-mode execution pattern: educational output by default, executable with -x flag across all 63 scripts — v1.2
- ✓ parse_common_args with -h/-v/-q/-x flags on all 63 scripts with unknown-flag passthrough — v1.2
- ✓ Zero ShellCheck warnings across 81 scripts with CI gate via GitHub Actions — v1.2
- ✓ 268-test regression suite for argument parsing, help output, and execute-mode safety — v1.2
- ✓ Bash 4.0+ version guard with macOS install hints and normalized interactive guards — v1.2
- ✓ BATS v1.13.0 test framework with git submodules, shared test helper, and strict mode compatibility — v1.3
- ✓ 50 library unit tests covering all public functions in scripts/lib/ (args, validation, logging, cleanup, output, retry) — v1.3
- ✓ 131 dynamic CLI contract tests with find-based auto-discovery and mock command infrastructure — v1.3
- ✓ GitHub Actions BATS CI pipeline with JUnit reporting and PR annotations — v1.3
- ✓ Structured @description/@usage/@dependencies metadata headers on all 78 scripts — v1.3
- ✓ 265-test BATS regression suite (smoke + unit + integration + header validation) — v1.3
- ✓ lib/json.sh module with fd3 redirect for structured JSON envelope output ({meta, results, summary}) — v1.4
- ✓ -j/--json flag in parse_common_args with lazy jq dependency and NO_COLOR auto-set — v1.4
- ✓ All 46 use-case scripts produce structured JSON output with 7-category taxonomy — v1.4
- ✓ 170 new BATS tests (json unit + args/output + JSON integration + doc verification) — v1.4
- ✓ Help text and @usage headers document -j/--json flag across all 46 scripts — v1.4
- ✓ 435-test BATS regression suite (smoke + unit + integration + JSON + doc verification) — v1.4

### Active

## Current Milestone: v1.5 Claude Skill Pack

**Goal:** Package the 17-tool, 81-script pentesting toolkit as a self-contained Claude Code skill pack with task-level and tool-level slash commands, safety/feedback hooks, and audit logging.

**Target features:**
- Task-oriented slash commands (`/pentest:discover-hosts`, `/pentest:diagnose-dns`, etc.)
- Tool-specific slash commands (`/nmap:scan-ports`, `/sqlmap:test`, etc.)
- Pre-execution safety hooks (target scoping, authorization checks)
- Post-execution feedback hooks (parse `-j` JSON output, suggest next steps)
- Audit trail logging for all commands and results
- Bundled scripts (self-contained skill, no separate repo clone needed)
- Tiered autonomy: diagnostics auto-run, active scans require confirmation

### Out of Scope

- Web application frontend (the site is static docs, not an interactive app) — complexity vs value
- Windows support — Unix-only project, WSL is sufficient
- Automated vulnerability remediation — this is a learning and detection tool, not a fixer
- Cloud infrastructure tools (AWS CLI, terraform) — different domain
- Real-time monitoring/alerting — scripts are run-once diagnostic, not daemons
- Offline mode — scripts require network access by nature
- Custom React/Svelte interactive components — Starlight built-in components cover needs
- Tailwind CSS integration — Starlight CSS custom properties handle theming
- Animated backgrounds or particle effects — accessibility issues, performance cost

## Context

Shipped v1.4 with JSON output mode. Total codebase: 9,963 LOC bash across 81 scripts, plus Astro docs site.
All 63 scripts (17 examples.sh + 46 use-case) support dual-mode execution with -h/-v/-q/-x/-j flags.
9-module library (scripts/lib/) provides strict mode, stack traces, log-level filtering, trap handlers, temp cleanup, retry logic, argument parsing, and JSON output.
435-test BATS regression suite: 5 smoke + 69 unit + 131 integration + 137 JSON + 93 doc verification — all enforced in CI.
BATS v1.13.0 with git submodules (bats-support, bats-assert, bats-file) at pinned versions.
Two GitHub Actions CI pipelines: ShellCheck linting + BATS tests with JUnit PR annotations (independent jobs).
All 78 scripts have structured @description/@usage/@dependencies metadata headers enforced by BATS validation test.
Tech stack: Bash scripts + Astro 5.x/Starlight 0.37.x + GitHub Actions + Docker Compose.
17 tools integrated into check-tools.sh with Makefile targets for each.
3 diagnostic scripts following Pattern B (structured auto-reports with pass/fail/warn).
Documentation site deployed to GitHub Pages with CI validation, dark orange/amber theme, terminal-prompt logo, and redesigned homepage.

## Constraints

- **Tech Stack**: Bash for all scripts — consistency with existing codebase
- **Site Framework**: Astro for GitHub Pages — user preference
- **Platform**: macOS primary, Linux compatible — existing constraint
- **Script Pattern**: New tools must follow established pattern (examples.sh + use-case scripts) — architectural consistency
- **Diagnostic Scripts**: Must be diagnostic (auto-report), not interactive step-by-step — user preference
- **Dependencies**: Prefer tools available via Homebrew or pre-installed on macOS/Linux
- **Site Theming**: Use CSS custom property overrides only (no element/class selectors) — safe Starlight cascade override

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
| \|\| true guards on pipefail-sensitive patterns | set -e exits on grep no-match, arithmetic zero, nc -h | ✓ Good — prevents silent script failures |
| :root-only CSS variable overrides for Starlight theming | Unlayered CSS beats @layer without !important; no selector conflicts | ✓ Good — clean theme override, no side effects |
| Terminal prompt >_ motif as brand icon | Simple geometric shape readable at 16px; evokes CLI/terminal tools | ✓ Good — recognizable at all sizes |
| sidebar.hidden frontmatter over config excludes | Keeps configuration local to each page; no config-level changes | ✓ Good — clean, maintainable |
| MDX homepage with Starlight Card/CardGrid/LinkCard | Built-in components; zero custom JS; consistent with site patterns | ✓ Good — 17 tools + guides + diagnostics on one page |
| [data-has-hero] CSS scoping for splash pages | Splash-page-only styles don't leak to content pages | ✓ Good — homepage spacing isolated |
| 8-file library split (not 2-file) | Maintainability over simplicity; each module has single responsibility | ✓ Good — clean separation, source guards prevent double-loading |
| Manual while/case arg parsing (not getopts/getopt) | getopts lacks long options; macOS BSD getopt is broken | ✓ Good — consistent cross-platform, unknown flags pass through |
| EXECUTE_MODE defaults to "show" | All scripts backward compatible without code changes | ✓ Good — zero behavioral regressions |
| Base temp directory for make_temp | Avoids subshell array loss in command substitution | ✓ Good — fixed critical bug, simpler cleanup |
| Inline SC2034 directives per-assignment | Visible, minimal suppressions over global disables | ✓ Good — easy to audit, no hidden suppressions |
| BATS submodule-first library loading | BATS sets default BATS_LIB_PATH; check directory existence instead | ✓ Good — works locally and in CI |
| Non-recursive BATS test discovery | Recursive flag picks up bats-core internal fixtures | ✓ Good — clean test runs |
| Pin exact BATS versions (1.13.0, etc.) | Reproducible test behavior across environments | ✓ Good — no surprise breakage |
| bats_test_function for dynamic test registration | Individual TAP lines per script vs single loop test | ✓ Good — clear failure identification |
| Mock sleep via export -f | Prevent real delays in retry unit tests | ✓ Good — instant test execution |
| Platform-conditional test exclusion (diagnose-latency.sh) | macOS non-root requires sudo before confirm_execute | ✓ Good — 62 on macOS, 63 on Linux CI |
| head -10 \| grep -c for header validation | Enforce field position in header block, not just presence anywhere | ✓ Good — catches misplaced fields |
| Bordered 76 = char header format | Visual consistency across all scripts | ✓ Good — machine-parseable, human-readable |
| fd3 for JSON output (exec 3>&1/exec 1>&2) | Keeps JSON clean on stdout while all human output goes to stderr | ✓ Good — clean separation, jq-pipeable |
| Lazy jq dependency | Check at source time, require only when -j parsed | ✓ Good — scripts without -j never need jq |
| json_add_example for bare info+echo | run_or_show captured automatically; bare examples need explicit accumulation | ✓ Good — all 10 results in every script |
| Category parameter optional in json_set_meta | Empty string default for backward compatibility | ✓ Good — no test breakage |
| bash -c wrapper for BATS fd3 JSON capture | BATS run mixes stdout+stderr; bash -c with 2>/dev/null isolates JSON | ✓ Good — clean test output |
| 3-pattern show_help documentation | Pattern A (Options), Pattern B (3-flag Flags), Pattern B+vq (5-flag Flags) | ✓ Good — consistent per-script-type |

---
*Last updated: 2026-02-17 after v1.5 milestone started*
