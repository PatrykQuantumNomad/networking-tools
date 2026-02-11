# Feature Landscape: Bash Script Hardening & Dual-Mode CLI

**Domain:** Production-grade bash script infrastructure
**Researched:** 2026-02-11

## Table Stakes

Features users expect from production-grade CLI tools. Missing = scripts feel amateur or fragile.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| `--help` on every script | Standard CLI convention | Low | Already present on all scripts via `show_help()` + `[[ "${1:-}" =~ ^(-h\|--help)$ ]]` |
| Non-zero exit on failure | Allows composition (`script.sh && next.sh`) | Low | Already present via `set -euo pipefail` in common.sh |
| Clean exit on Ctrl+C | No orphaned processes or temp files | Medium | Requires EXIT trap + cleanup function in `lib/strict.sh` |
| No color in pipes | ANSI codes in piped output is a bug | Low | Add NO_COLOR + terminal detection to common.sh color initialization |
| `-v`/`--verbose` flag | Standard CLI convention for debugging | Low | New: sets `VERBOSE=1`, enables timestamps and debug output |
| `-q`/`--quiet` flag | Suppress non-essential output | Low | New: sets `LOG_LEVEL=error` |
| Long option support | `--help`, `--verbose`, `--execute` | Medium | Manual `while/case` parser in `lib/args.sh` |
| Consistent error messages | Users expect clear diagnostics | Low | Already present via `error()` in common.sh; upgrade adds line numbers on ERR trap |
| Bash version gate | Clear error if Bash too old | Low | One-time check in common.sh: `[[ ${BASH_VERSINFO[0]} -lt 4 ]]` |

## Differentiators

Features that set this toolkit apart. Not expected, but noticeably professional.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Dual-mode execution (`-x`) | Same script teaches AND executes. No other pentesting script collection does this. Default shows examples (backward compatible), `-x` runs them. | Medium | Core differentiator. `run_or_show()` wrapper replaces current 3-line pattern with 1-line call. |
| Stack traces on error | Instant debugging -- shows exact failing line and full call chain | Low | ERR trap with `BASH_LINENO`/`FUNCNAME`/`BASH_SOURCE`. ~15 lines in `lib/strict.sh`. |
| `LOG_LEVEL` environment variable | Filter verbosity without modifying scripts: `LOG_LEVEL=debug ./script.sh` | Low | Integrates with upgraded `_log()` core function. |
| `debug()` function | Invisible by default, visible when `VERBOSE=1` or `LOG_LEVEL=debug` | Low | New function alongside existing info/warn/error. |
| Retry with exponential backoff | Network tools survive DNS timeouts, rate limiting, connection resets | Low | 15-line `retry_with_backoff()` function in common.sh. |
| Automatic temp cleanup | Zero leaked temp files on any exit path (normal, error, Ctrl+C) | Low | EXIT trap + mktemp directory pattern in `lib/strict.sh`. |
| Confirmation gate in execute mode | Safety: warns and prompts before running active scans | Low | `read -rp` with safety_banner before execution in `-x` mode. |
| Consistent flags across all tools | Learn `-x`, `-v`, `-q`, `--help` once, use everywhere | Medium | `parse_common_args()` in `lib/args.sh`, adopted per-script. |
| Execution timer | Shows elapsed time after execute mode completes | Low | Bash `$SECONDS` builtin. Print at EXIT trap. |

## Anti-Features

Features to explicitly NOT build. Each has a reason specific to this codebase.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| JSON logging | Scripts are interactive CLI tools for human operators, not services feeding log aggregators. JSON adds jq dependency and complexity for zero user benefit. | Keep human-readable colored output. Upgrade with level filtering and NO_COLOR support. |
| Configuration files (`.rc` files) | Adds file discovery, merge semantics, error handling for malformed config. Overkill for scripts that take 1-3 arguments. | Use environment variables: `LOG_LEVEL`, `VERBOSE`, `NO_COLOR`, `MODE`. |
| Plugin/extension system | 17 tools with established patterns. Plugin architecture adds discovery, registration, and documentation overhead. | Keep "copy the pattern" approach documented in CLAUDE.md. |
| Automatic dependency installation | Running `sudo` or `brew install` without explicit user consent is unacceptable for security tools. | Keep `require_cmd` with clear install hints. Already implemented. |
| Interactive menus / TUI | Breaks scriptability. Users must be able to pipe, redirect, and compose. | Use flags (`-x`, `-v`) and positional arguments. |
| `IFS=$'\n\t'` global override | Breaks space-separated command construction used in every script for building tool commands like `nmap -sV --top-ports 100 "$TARGET"`. | Keep default IFS (space/tab/newline). |
| `FORCE_COLOR` environment variable | Low adoption standard compared to NO_COLOR. Adds complexity for minimal benefit. | Support NO_COLOR only. |
| `getopts` or `getopt` for arg parsing | `getopts` has no long options. macOS BSD `getopt` is broken (no long options, broken space handling). GNU `getopt` requires Homebrew. | Manual `while/case` loop per Greg's Wiki BashFAQ/035. |
| Rewriting in Python/Go | The educational value IS the bash. Users learning pentesting need bash -- every exploit PoC, CTF writeup, and pentest report uses it. | Stay in bash. Split complex logic into smaller focused scripts. |
| Comprehensive unit testing (bats/shunit2) | External test framework dependency. Scripts are thin wrappers -- testing "nmap gets called with right flags" is low-value. | ShellCheck for static analysis. Smoke tests for function existence. Manual testing against lab targets. |
| Per-tool state files | Statefulness in security tools is a liability. Scan results become stale. History files can leak sensitive information about authorized targets. | Scripts remain stateless. Each invocation is independent. |
| Bash completion scripts | High maintenance (one per tool). Defer until tool interfaces are fully stable after dual-mode migration. | Document flag patterns in `--help` output. |

## Feature Dependencies

```
Strict mode framework (lib/strict.sh)
  |-> set -eEuo pipefail (error propagation)
  |-> ERR trap (stack traces)
  |-> EXIT trap (temp cleanup)
  |-> shopt -s inherit_errexit (Bash 4.4+ gated)
  |-> Bash 4.0+ version gate

Logging upgrade (common.sh)
  |-> _log() core function with level filtering
  |-> debug() function (new)
  |-> NO_COLOR / terminal detection
  |-> VERBOSE timestamps
  Depends on: Strict mode (colors defined in common.sh which sources strict.sh)

Argument parsing (lib/args.sh)
  |-> parse_common_args()
  |-> -x/--execute -> MODE=execute
  |-> -v/--verbose -> VERBOSE++
  |-> -q/--quiet -> LOG_LEVEL=error
  |-> REMAINING_ARGS for positional args
  Depends on: Logging upgrade (uses error() for invalid args)

Dual-mode execution (common.sh)
  |-> run_or_show() function
  |-> Confirmation gate for execute mode
  Depends on: Argument parsing (MODE variable), Logging (debug/info)

Retry with backoff (common.sh)
  |-> retry_with_backoff() function
  Depends on: Logging (warn/error for retry messages)

ShellCheck compliance
  |-> .shellcheckrc project config
  |-> SC2155 fixes (local+assign split)
  |-> SC2086 fixes (quote variables)
  |-> SC2034 fixes (export/disable for color vars)
  |-> CI workflow
  Depends on: All behavioral code changes complete (lint after behavior)
```

## MVP Recommendation

Prioritize:
1. **Strict mode framework** -- Prevents bugs. Zero visible behavior change for users. Foundation for everything else. Includes Bash 4.0+ gate, ERR trap with stack traces, EXIT trap with temp cleanup.
2. **Logging upgrade** -- Adds debug(), NO_COLOR, LOG_LEVEL filtering, terminal detection. Backward compatible: existing info/warn/error signatures preserved.
3. **Argument parsing + dual-mode** -- The headline feature. `parse_common_args()` and `run_or_show()`. Transforms educational scripts into executable tools.

Defer:
- **Retry with backoff:** Useful but not blocking. Can be added to specific scripts incrementally.
- **Full ShellCheck compliance:** Important but large scope. Better as a dedicated cleanup phase.
- **Execution timer:** Polish feature, trivial to add after core execution mode works.
- **Script metadata headers:** Nice for automation but not needed for the hardening milestone.

## Sources

- Codebase analysis: direct reading of all script patterns in `/Users/patrykattc/work/git/networking-tools/scripts/`
- Greg's Wiki BashFAQ/035 (argument parsing): https://mywiki.wooledge.org/BashFAQ/035
- Greg's Wiki BashFAQ/105 (set -e pitfalls): https://mywiki.wooledge.org/BashFAQ/105
- NO_COLOR convention: https://no-color.org/
- ShellCheck wiki: https://www.shellcheck.net/wiki/
