# Project Research Summary

**Project:** networking-tools v1.2 -- Script Hardening Milestone
**Domain:** Production-grade bash script infrastructure for 66 educational security scripts
**Researched:** 2026-02-11
**Confidence:** HIGH

## Executive Summary

The v1.2 Script Hardening milestone transforms 66 educational bash scripts into production-grade dual-mode CLI tools. All four research tracks converge on the same conclusion: this is achievable with zero new runtime dependencies. The entire upgrade is pure bash -- two new library files (`scripts/lib/strict.sh`, `scripts/lib/args.sh`), targeted upgrades to the existing `scripts/common.sh`, a `.shellcheckrc` project config, and ShellCheck 0.11.0 as a development-only linter. No frameworks, no external binaries, no build steps.

The headline feature is dual-mode execution via a `run_or_show()` function. Today, every script prints 10 numbered examples with explanations. After hardening, the same scripts default to that educational behavior (backward compatible) but accept a `-x`/`--execute` flag to actually run the commands. This is a 1-line change per example: the current 3-line pattern (`info` + `echo` + `echo`) collapses into a single `run_or_show` call. The architecture research confirms this integrates cleanly with all three existing script patterns (Pattern A: educational examples, Pattern B: diagnostic auto-reports, Pattern C: tool checkers).

The primary risk is `set -e` fragility during refactoring. The pitfalls research identified 5 critical issues -- all already partially mitigated in the codebase but exposed during structural changes. The most dangerous: `local var=$(cmd)` silently masks command failures (affects 50+ call sites), `grep` returns exit 1 on no match which kills pipelines under `pipefail` (40+ existing `|| true` guards prove this is a known issue), and `((counter++))` from zero kills scripts under `set -e` (already guarded with `|| true` in 2 scripts). These are well-understood bash pitfalls with documented workarounds from Greg's Wiki, and the codebase already handles most of them -- the risk is regression during refactoring, not discovery of new problems.

## Key Findings

### Recommended Stack

From [STACK.md](./STACK.md): Pure bash with no external runtime dependencies. The only addition is ShellCheck 0.11.0 as a dev-only linter.

**Core technologies:**
- **Bash 4.0+ minimum** (already implicit -- codebase uses `declare -A`). Guard with version check in `common.sh`. macOS system bash is 3.2.57; `#!/usr/bin/env bash` picks up Homebrew's 5.3.9.
- **`set -eEuo pipefail`** with ERR trap: The `-E` flag ensures ERR traps propagate into functions and subshells. Without it, functions that fail produce no diagnostic context.
- **`shopt -s inherit_errexit`** (Bash 4.4+ gated): Makes `set -e` apply inside command substitutions. Version-gated since minimum is 4.0.
- **Manual `while/case` argument parsing**: Not `getopts` (no long options), not `getopt` (macOS BSD version is broken). Recommended by Greg's Wiki BashFAQ/035.
- **ShellCheck 0.11.0**: Static analysis with `.shellcheckrc` project config. Start at `--severity=warning`, tighten later.

**Critical version constraint:** Do NOT use Bash 5.0+ features (`${var@Q}`, `EPOCHSECONDS`). Do NOT use `IFS=$'\n\t'` (breaks all space-separated command construction throughout the codebase).

### Expected Features

From [FEATURES.md](./FEATURES.md): Clear separation into must-have, differentiators, and anti-features.

**Must have (table stakes):**
- `--help` on every script (already present)
- Non-zero exit on failure (already present via `set -euo pipefail`)
- Clean exit on Ctrl+C with temp file cleanup (needs EXIT trap)
- No ANSI color codes in piped output (needs NO_COLOR + terminal detection)
- `-v`/`--verbose` and `-q`/`--quiet` flags (new)
- Long option support (`--help`, `--verbose`, `--execute`) (new)
- Bash 4.0+ version gate with clear error message (new)

**Should have (differentiators):**
- Dual-mode execution (`-x`/`--execute`) -- the headline feature
- Stack traces on error via ERR trap
- `LOG_LEVEL` environment variable for filtering
- `debug()` function (invisible by default)
- Retry with exponential backoff for network operations
- Automatic temp file cleanup on any exit path
- Confirmation gate before executing active scans
- Consistent flags across all 66 scripts

**Defer (v2+):**
- Bash completion scripts (high maintenance, defer until interfaces stabilize)
- JSON output mode (no consumer exists today)
- Execution timer (trivial to add after core execution mode works)
- Script metadata headers (nice for automation, not needed now)

**Anti-features (explicitly do NOT build):**
- JSON logging (no consumer, adds `jq` dependency)
- Configuration files (overkill, use environment variables)
- Plugin/extension system (copy-the-pattern is sufficient)
- Automatic dependency installation (`sudo`/`brew` without consent is unacceptable for security tools)
- Interactive TUI menus (breaks scriptability and piping)
- Rewriting in Python/Go (the educational value IS the bash)
- Comprehensive unit testing with bats/shunit2 (use ShellCheck + smoke tests instead)

### Architecture Approach

From [ARCHITECTURE.md](./ARCHITECTURE.md): Split `common.sh` into focused modules behind a backward-compatible entry point.

**Major components:**
1. **`common.sh`** (preserved entry point) -- Sources all `lib/*.sh` modules. All 66 scripts keep their existing `source "$(dirname "$0")/../common.sh"` line unchanged.
2. **`lib/core.sh`** -- Colors, `PROJECT_ROOT`, `is_interactive()`, `set -euo pipefail`, ERR trap. No dependencies (foundational).
3. **`lib/logging.sh`** -- Upgraded `info/warn/error/success` + new `debug()`, `_log()` core with level filtering, NO_COLOR support, `VERBOSE` timestamps. Depends on `core.sh`.
4. **`lib/validation.sh`** -- `require_root`, `check_cmd`, `require_cmd`, `require_target`. Depends on `logging.sh`.
5. **`lib/args.sh`** -- `parse_common_args()` with `-x`, `-v`, `-q`, `--help`, `REMAINING_ARGS[]`. Depends on `logging.sh`.
6. **`lib/output.sh`** -- `run_or_show()`, `safety_banner` (quiet-mode aware), dual-mode output functions. Depends on `core.sh`.
7. **`lib/cleanup.sh`** -- EXIT trap, `make_temp()`, `register_cleanup()`. Depends on `logging.sh`.
8. **`lib/diagnostic.sh`** -- `report_pass/fail/warn/skip`, `run_check`, counters. Used only by Pattern B scripts.
9. **`lib/nc_detect.sh`** -- `detect_nc_variant()`. Used only by netcat scripts.

**Source order matters:** `core.sh` first, `logging.sh` second, then everything else. The dependency graph is strictly one-way (no circular dependencies). Source guards (`_MODULE_LOADED=1` pattern) prevent double-sourcing.

**Key architectural pattern:** Additive functions, not modified functions. Add `log_info()` alongside `info()`, do not change `info()`. This is zero-risk for existing scripts.

### Critical Pitfalls

From [PITFALLS.md](./PITFALLS.md): 15 pitfalls identified (5 critical, 5 moderate, 5 minor). Top 5 with prevention strategies:

1. **`local var=$(cmd)` masks exit status** (Critical, 50+ sites) -- Split into two statements: `local var; var=$(cmd)`. ShellCheck SC2155 catches this automatically.
2. **`grep` returns exit 1 on no match under `pipefail`** (Critical, 40+ sites) -- Every `grep` that may legitimately find nothing must have `|| true` or be inside an `if` conditional. The codebase already guards 40+ instances but not all.
3. **`((counter++))` from zero kills script under `set -e`** (Critical, 6 sites) -- Use `var=$((var + 1))` instead, or `((var++)) || true`. Already handled in `check-tools.sh`.
4. **Two inconsistent interactive guard patterns** (Moderate, 63 scripts) -- `[[ -t 0 ]] || exit 0` (19 scripts) vs `[[ ! -t 0 ]] && exit 0` (44 scripts). Normalize to one pattern before any other refactoring.
5. **`set -e` suspended inside conditional contexts** (Critical for dual-mode) -- `main()` called from `if main; then` silently swallows errors. Always call `main` unconditionally: `[[ "${BASH_SOURCE[0]}" == "$0" ]] && main "$@"`.

## Consensus Decisions

All four research tracks independently arrived at the same conclusions on these points:

| Decision | Agreement | Rationale |
|----------|-----------|-----------|
| Pure bash, zero runtime deps | STACK + FEATURES + ARCHITECTURE + PITFALLS | External deps contradict the project's "run one command" value proposition. Security tools should not require `jq`, `yq`, or Go binaries. |
| Manual `while/case` for arg parsing | STACK + FEATURES + PITFALLS | `getopts` lacks long options. macOS BSD `getopt` is broken. GNU `getopt` requires Homebrew. All three sources cite Greg's Wiki BashFAQ/035. |
| Do NOT change `IFS` globally | STACK + FEATURES + PITFALLS | `IFS=$'\n\t'` breaks space-separated command construction used in every script for building tool invocations like `nmap -sV --top-ports 100 "$TARGET"`. |
| Backward-compatible entry point | STACK + ARCHITECTURE | Keep `common.sh` as the single source line for all 66 scripts. Splitting into `lib/*.sh` happens behind this entry point. |
| `info/warn/error` signatures preserved | STACK + FEATURES + ARCHITECTURE | All 66 scripts call these functions. Changing signatures is unacceptable churn. Add new functions alongside, never modify existing ones. |
| NO_COLOR standard over FORCE_COLOR | STACK + FEATURES | NO_COLOR (no-color.org) is widely adopted. FORCE_COLOR is not. Check `[[ -t 2 ]]` for stderr since all logging goes to stderr. |
| ShellCheck as only external dev tool | STACK + FEATURES + PITFALLS | Only widely-adopted bash-specific linter. Catches real bugs (SC2155, SC2086). `.shellcheckrc` with `source-path` and `external-sources=true` handles the project's source pattern. |
| Incremental migration, not big-bang | ARCHITECTURE + PITFALLS | 66 scripts must keep working at every step. Each change verified independently. No "flag day." |
| Educational content is NOT logging | FEATURES + PITFALLS + ARCHITECTURE | The numbered examples ARE the product, not log noise. `info "1) Ping scan"` + `echo "   nmap ..."` is educational output, not operational logging. Structured logging applies only to operational messages. |
| Do not rewrite in Python/Go | FEATURES | The educational value IS the bash. Every exploit PoC, CTF writeup, and pentest report uses bash. |

## Conflicts and Tensions

### Tension 1: Architecture Granularity of Library Split

**STACK.md** recommends two new files: `lib/strict.sh` (strict mode + traps + temp files) and `lib/args.sh` (argument parsing). Simple, minimal.

**ARCHITECTURE.md** recommends eight files: `lib/core.sh`, `lib/logging.sh`, `lib/validation.sh`, `lib/args.sh`, `lib/output.sh`, `lib/cleanup.sh`, `lib/diagnostic.sh`, `lib/nc_detect.sh`. Highly modular.

**Resolution:** Go with ARCHITECTURE.md's split but treat it as an internal refactor, not a public API. Scripts only see `common.sh`. The 8-file split is better for maintainability (a 400+ line monolithic common.sh is hard to reason about), and the source guards prevent any issues from the added complexity. The STACK.md 2-file approach underestimates how much code the logging upgrade, output mode, and cleanup framework add.

### Tension 2: Dual-Mode Implementation Detail

**STACK.md** proposes `run_or_show()` that takes a description string + command args. Clean, simple.

**ARCHITECTURE.md** proposes `example()`, `teach()`, `result()` as separate output functions with an `OUTPUT_MODE` variable controlling behavior. More expressive but more complex.

**Resolution:** Implement both. `run_or_show()` is the core mechanism for the `-x`/`--execute` toggle (STACK's approach). `example()` and `teach()` are syntactic sugar for the educational content suppression in quiet mode (ARCHITECTURE's approach). They serve different purposes: `run_or_show` answers "should I run this or show it?" while `example`/`teach` answer "should I show this educational text at all?"

### Tension 3: ERR Trap Behavior

**STACK.md** recommends an ERR trap that prints a full stack trace to stderr on every error. Always visible.

**ARCHITECTURE.md** recommends an ERR trap that only logs to a file (if `LOG_FILE` is set). Silent by default.

**Resolution:** Use STACK.md's approach (always print to stderr). The purpose of the ERR trap is developer/user diagnostics. A stack trace that only appears in an opt-in log file defeats the purpose. Users running scripts interactively need to see which line failed and why. The output goes to stderr, so it does not pollute piped stdout.

### Tension 4: How Unknown Flags Are Handled in Arg Parser

**STACK.md** proposes: unknown flags (`-*`) trigger `error "Unknown option"` + `exit 1`. Strict.

**ARCHITECTURE.md** proposes: unknown flags pass through to `REMAINING_ARGS`. Permissive. Lets scripts define their own flags.

**Resolution:** Use ARCHITECTURE.md's permissive approach for `parse_common_args()`. The common parser handles global flags (`-h`, `-v`, `-q`, `-x`). Per-tool flags (if any emerge later) should not be blocked by the common parser. A script can add a second `case` statement for its own flags after `parse_common_args` returns.

### Tension 5: Logging Upgrade vs. Parallel log_*() Functions

**STACK.md** upgrades the existing `info/warn/error` functions in-place to add level filtering and NO_COLOR support. Same function names, enhanced internals.

**ARCHITECTURE.md** keeps `info/warn/error` identical and adds parallel `log_info/log_warn/log_error` functions for dual (terminal + file) output.

**Resolution:** Use STACK.md's approach for the core upgrade (enhance `info/warn/error` with level filtering and NO_COLOR -- this is backward compatible since the function signatures do not change). Add ARCHITECTURE.md's `log_*()` functions as an optional layer only if `LOG_FILE` is set. Most scripts will never need `log_info()`; the enhanced `info()` is sufficient.

## Implications for Roadmap

Based on combined research, the dependency graph dictates phase ordering. Each phase builds on the previous one and must be completed before the next begins.

### Phase 1: Pre-Refactor Cleanup
**Rationale:** Normalize inconsistencies before any structural changes. Doing this first prevents mistakes from propagating through all subsequent phases. PITFALLS.md explicitly warns that two interactive-guard patterns make search-and-replace unreliable.
**Delivers:** Consistent codebase ready for structural changes.
**Addresses features:** None directly. This is prep work.
**Avoids pitfalls:** Pitfall 9 (two interactive guard patterns), Pitfall 15 (bash version gate).
**Scope:** Small. Normalize 63 `[[ -t 0 ]]` guards to one pattern. Add Bash 4.0+ version check to `common.sh`. Create `.shellcheckrc` with `source-path` and `external-sources=true`.
**Estimated effort:** 1-2 hours.

### Phase 2: Foundation -- Library Split + Strict Mode + Logging
**Rationale:** Every subsequent phase depends on the library infrastructure being correct. ARCHITECTURE.md's dependency graph shows `core.sh` -> `logging.sh` -> everything else. STACK.md confirms strict mode must be the first behavioral change. FEATURES.md dependency tree shows logging upgrade depends on strict mode (colors defined in core, sourced by logging).
**Delivers:** `scripts/lib/` directory with 8 module files. Enhanced `common.sh` entry point. ERR trap with stack traces. Enhanced `info/warn/error` with level filtering and NO_COLOR. New `debug()` function. EXIT trap with temp file cleanup. `retry_with_backoff()`. Bash 4.0+ gate. Source guards on all modules.
**Addresses features:** Clean exit on Ctrl+C, no color in pipes, `-v`/`--verbose`, `-q`/`--quiet`, `LOG_LEVEL`, stack traces on error, auto temp cleanup.
**Avoids pitfalls:** Pitfall 1 (read -rp under set -e -- create canonical `run_interactive_demo()` wrapper), Pitfall 2 (counter arithmetic -- standardize pattern), Pitfall 3 (grep without guards -- audit), Pitfall 4 (stderr tools -- document), Pitfall 10 (awk float comparison -- add validation).
**Uses stack:** `set -eEuo pipefail`, `shopt -s inherit_errexit` (gated), `mktemp` + EXIT trap, NO_COLOR standard.
**Verification:** Source `common.sh` in a test script. Verify all expected functions exist. Run all 66 scripts and confirm identical output. Run smoke test: `echo "" | bash scripts/nmap/examples.sh scanme.nmap.org` exits 0.

### Phase 3: Argument Parsing + Dual-Mode Pattern
**Rationale:** The parser and `run_or_show()` must be defined and tested before any script migration. FEATURES.md dependency tree shows dual-mode depends on argument parsing (MODE variable) which depends on logging (error messages for invalid args).
**Delivers:** `lib/args.sh` with `parse_common_args()`. `run_or_show()` in `lib/output.sh`. Confirmation gate for execute mode. The complete dual-mode pattern ready for adoption.
**Addresses features:** Long option support, consistent flags (`-x`, `-v`, `-q`, `--help`), dual-mode execution mechanism.
**Avoids pitfalls:** Pitfall 6 (set -u after shift -- check `$#` in parse loop), Pitfall 8 (getopt not portable -- manual while/case), Pitfall 12 (Makefile backward compat -- positional `$1` still works as target).
**Verification:** Migrate one tool directory (nmap) as proof of concept. Test: `./examples.sh scanme.nmap.org` (shows examples, backward compatible), `./examples.sh -x scanme.nmap.org` (executes with confirmation), `make nmap TARGET=scanme.nmap.org` (still works).

### Phase 4: Script Migration -- Pattern A (17 examples.sh)
**Rationale:** Pattern A scripts are the most uniform (all follow the same 10-example structure). Migrating them as a batch validates the pattern at scale. ARCHITECTURE.md confirms all 17 share identical structure.
**Delivers:** All 17 `examples.sh` scripts upgraded to dual-mode with consistent flags.
**Addresses features:** Dual-mode on all primary educational scripts.
**Avoids pitfalls:** Pitfall 5 (set -e in sourced vs executed -- do not add dual-mode to common.sh itself), Pitfall 14 (main() hides errors -- call unconditionally).
**Verification:** Each migrated script tested in both modes. All Makefile targets still work.

### Phase 5: Script Migration -- Pattern A (28 use-case scripts)
**Rationale:** Use-case scripts are more varied than examples.sh. Some have default targets, some parse additional arguments, some run multi-step workflows. Migrating after examples.sh means the pattern is proven.
**Delivers:** All 28 use-case scripts upgraded with argument parsing and dual-mode support.
**Addresses features:** Full dual-mode coverage, retry logic integration for network operations.
**Avoids pitfalls:** Pitfall 7 (structured logging obscures educational content -- separate operations from educational output).

### Phase 6: ShellCheck Compliance + CI
**Rationale:** ShellCheck is a cross-cutting cleanup that touches every file. FEATURES.md explicitly recommends deferring it to a dedicated phase. Mixing lint fixes with behavioral changes creates conflated diffs that are harder to review and harder to bisect when debugging.
**Delivers:** Zero ShellCheck warnings at `--severity=warning`. CI workflow gating PRs. Clean `.shellcheckrc` config.
**Addresses features:** SC2155 fixes (50+ sites), SC2086 fixes (quoting), SC2034 fixes (unused color vars).
**Avoids pitfalls:** Pitfall 13 (over-engineering -- ShellCheck only, no other linters).
**Verification:** `shellcheck --severity=warning scripts/**/*.sh scripts/common.sh` returns exit 0.

### Phase Ordering Rationale

- **Phase 1 before everything:** Normalize the codebase before making structural changes. The two interactive guard patterns would cause missed scripts during migration.
- **Phase 2 before 3:** Argument parsing uses `error()` for invalid args. Logging must be upgraded first. Strict mode must be stable before building on top of it.
- **Phase 3 before 4-5:** Define and validate the migration pattern once, then apply it 45 times. Prevents 45 different interpretations of how dual-mode should work.
- **Phase 4 before 5:** examples.sh scripts are uniform and serve as the template. Use-case scripts are varied and benefit from a proven pattern.
- **Phase 6 last:** Lint cleanup should not be mixed with behavioral changes. Clean git history where each commit does one thing.

### Research Flags

**Phases likely needing deeper research during planning:**
- **Phase 3:** Per-tool investigation needed. Which nmap examples are safe to execute without root? Which sqlmap examples are destructive? The confirmation gate helps, but the phase plan needs a safety classification per example.
- **Phase 5:** Use-case scripts have varied structures. Some (like `crack-wpa-handshake.sh`) require hardware (wireless adapter). Need to decide how execute mode handles impossible-to-run commands.
- **Phase 6:** Need to run `shellcheck --severity=warning` to get actual warning count before scoping. Could be 50 or 500 warnings.

**Phases with standard patterns (skip deeper research):**
- **Phase 1:** Pure mechanical normalization. No design decisions.
- **Phase 2:** All patterns are well-documented bash idioms from canonical references (Greg's Wiki, Bash Reference Manual). Stack research provides exact code.
- **Phase 4:** Migration is mechanical once Phase 3 establishes the pattern.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Zero external dependencies. All patterns verified against canonical references (Greg's Wiki BashFAQ/035, BashFAQ/105, BashFAQ/062, Bash Reference Manual, ShellCheck Wiki). ShellCheck 0.11.0 release confirmed. |
| Features | HIGH | Feature landscape derived from codebase analysis (66 scripts read directly) + CLI UX standards (clig.dev, no-color.org). Anti-features grounded in project's educational purpose per CLAUDE.md. |
| Architecture | HIGH | Module split based on actual function analysis of 138-line common.sh. Dependency graph verified by source-order testing. Backward compatibility guaranteed by preserving entry point. |
| Pitfalls | HIGH | All 5 critical pitfalls verified against Greg's Wiki BashFAQ/105 (the canonical `set -e` reference). Each pitfall mapped to specific file + line number in the codebase. The 40+ existing `\|\| true` guards prove the team already knows about grep/pipefail issues. |

**Overall confidence: HIGH**

The research is unusually well-grounded because the domain (bash scripting) has decades of canonical documentation and the codebase is small enough to analyze exhaustively. There are no API integrations, no third-party services, no version compatibility unknowns. Every recommendation maps to a specific line of code in the existing codebase.

### Gaps to Address

- **Exact ShellCheck warning count:** Must run `shellcheck --severity=warning scripts/**/*.sh` before scoping Phase 6. Install ShellCheck as first action.
- **Per-tool execute safety classification:** Need to categorize each of the 170 examples (17 scripts x 10 examples) as safe-to-execute, needs-root, needs-target-consent, or display-only. This classification drives Phase 4 implementation.
- **Retry idempotency per tool:** `retry_with_backoff()` is safe for idempotent commands (DNS lookups, port scans) but dangerous for non-idempotent ones (SQL injection tests, brute force attempts). Need per-tool analysis during Phase 5.
- **Diagnostic scripts (Pattern B) migration path unclear:** ARCHITECTURE.md describes three patterns but the migration strategy focuses on Pattern A. Pattern B scripts (3 diagnostic scripts) already execute commands and produce structured output -- they may not need dual-mode at all, or they may need a different treatment. Clarify during Phase 5 planning.
- **`lib/` directory impact on ShellCheck source resolution:** The `.shellcheckrc` `source-path=SCRIPTDIR/..` pattern resolves `common.sh` relative to each script. After the library split, ShellCheck must also resolve `lib/*.sh` files sourced by `common.sh`. Verify during Phase 2 that `external-sources=true` + `source-path=SCRIPTDIR/../lib` handles this.

## Sources

### Primary (HIGH confidence -- canonical references, official documentation)
- Greg's Wiki BashFAQ/035 (argument parsing): https://mywiki.wooledge.org/BashFAQ/035
- Greg's Wiki BashFAQ/105 (set -e pitfalls): https://mywiki.wooledge.org/BashFAQ/105
- Greg's Wiki BashFAQ/062 (temp files): https://mywiki.wooledge.org/BashFAQ/062
- Greg's Wiki SignalTrap (trap patterns): https://mywiki.wooledge.org/SignalTrap
- Greg's Wiki BashGuide/Practices: https://mywiki.wooledge.org/BashGuide/Practices
- Bash Reference Manual (set builtin): https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
- ShellCheck Wiki (SC codes, directives, .shellcheckrc): https://www.shellcheck.net/wiki/
- ShellCheck v0.11.0 Release: https://github.com/koalaman/shellcheck/releases
- NO_COLOR Standard: https://no-color.org/
- Command Line Interface Guidelines: https://clig.dev/

### Secondary (MEDIUM confidence -- community best practices, multiple sources agree)
- Unofficial Bash Strict Mode: http://redsymbol.net/articles/unofficial-bash-strict-mode/
- Exit Traps in Bash: http://redsymbol.net/articles/bash-exit-traps/
- Safer Bash Scripts: https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/
- Designing Modular Bash: https://www.lost-in-it.com/posts/designing-modular-bash-functions-namespaces-library-patterns/
- Unix Interface Design Patterns: https://homepage.cs.uri.edu/~thenry/resources/unix_art/ch11s06.html

### Codebase Analysis (direct observation)
- `scripts/common.sh` (138 lines) -- all functions inventoried
- 66 consumer scripts across 18 tool directories -- all patterns cataloged
- 40+ `|| true` guards, 63 `read -rp` locations, 2 `((counter++)) || true` sites verified

---
*Research completed: 2026-02-11*
*Ready for roadmap: yes*
