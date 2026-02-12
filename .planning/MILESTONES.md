# Project Milestones: Networking Tools

## v1.2 Script Hardening (Shipped: 2026-02-11)

**Delivered:** Transformed 63 educational bash scripts into production-grade dual-mode CLI tools backed by an 8-module library with strict mode, stack traces, structured logging, argument parsing, and ShellCheck compliance with CI enforcement.

**Phases completed:** 12-17 (18 plans total)

**Key accomplishments:**
- Built 8-module library (scripts/lib/) with strict mode, stack traces, log-level filtering, trap handlers, temp cleanup, and retry logic — all behind backward-compatible common.sh entry point
- Created dual-mode execution pattern (run_or_show/confirm_execute) — educational output by default, executable with -x flag
- Migrated all 63 scripts (17 examples.sh + 46 use-case) to dual-mode with consistent -h/-v/-q/-x flags
- Achieved zero ShellCheck warnings across 81 scripts with CI gate via GitHub Actions
- Built 268-test regression suite validating argument parsing, help output, and execute-mode safety gates
- Normalized all interactive guards and added Bash 4.0+ version guard with macOS install hints

**Stats:**
- 126 files created/modified
- +12,160 / -1,833 lines changed (8,486 LOC bash total)
- 6 phases, 18 plans
- 3 days (Feb 9 → Feb 11, 2026), ~1.3 hours execution

**Git range:** `feat(12-01)` → `docs(phase-17)`

**What's next:** TBD — next milestone via `/gsd:new-milestone`

---

## v1.1 Site Visual Refresh (Shipped: 2026-02-11)

**Delivered:** Transformed the documentation site from default Starlight into a polished, branded pentesting toolkit with a dark + orange/amber theme, custom terminal-prompt logo, redesigned homepage with tool card grids, and cleaned-up navigation.

**Phases completed:** 8-11 (4 plans total)

**Key accomplishments:**
- Applied dark + orange/amber accent palette with WCAG AA-compliant light mode contrast across all UI elements
- Created terminal-prompt (>_) SVG logo with dual dark/light variants and adaptive favicon
- Removed redundant sidebar index entries using Starlight's sidebar.hidden frontmatter
- Built full MDX homepage with branded hero, 17 tool cards organized by category, diagnostic links, and guide links

**Stats:**
- 36 files created/modified
- +4,670 / -1,388 lines changed (CSS, MDX, SVG, config)
- 4 phases, 4 plans, 7 tasks
- Same day ship (2026-02-11, ~4.5 hours)

**Git range:** `feat(08-01)` → `docs(phase-11)`

**What's next:** TBD — next milestone via `/gsd:new-milestone`

---

## v1.0 Networking Tools Expansion (Shipped: 2026-02-11)

**Delivered:** Transformed a bash-first pentesting learning lab into a comprehensive 17-tool networking toolkit with an Astro/Starlight documentation site, diagnostic auto-report scripts, and six new networking tools.

**Phases completed:** 1-7 (19 plans total)

**Key accomplishments:**
- Built Astro/Starlight documentation site with 29+ pages, OS-specific install tabs, learning paths, and CI-automated GitHub Pages deployment
- Added 6 new networking tools (dig, curl, netcat, traceroute/mtr, gobuster, ffuf) with 37+ scripts following established patterns
- Created Pattern B diagnostic framework with DNS, connectivity, and performance auto-reports using structured pass/fail/warn indicators
- Implemented wordlist infrastructure and web enumeration toolkit for directory brute-forcing and parameter fuzzing
- Extended CI with docs-completeness validation ensuring every tool script has a corresponding documentation page
- Achieved cross-platform support with netcat variant detection, mtr sudo gating, and BSD/GNU command compatibility

**Stats:**
- 124 files created/modified
- 13,585 lines of code (8,180 bash + 5,405 site docs)
- 7 phases, 19 plans, 47 tasks
- 2 days from start to ship (Feb 9 → Feb 11, 2026)

**Git range:** `feat(01-01)` → `docs(phase-7)`

**What's next:** TBD — consider v2.0 with JSON output mode, DNS multi-resolver comparison, or interactive web UI

---
