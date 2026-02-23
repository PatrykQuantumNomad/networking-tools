# Architecture

**Analysis Date:** 2026-02-23

## Pattern Overview

**Overall:** Modular Bash script library with two script patterns (Pattern A: educational, Pattern B: diagnostic), a Claude Code safety hook layer, and a static documentation site.

**Key Characteristics:**
- Single shared library (`scripts/lib/`) sourced via a single entry point (`scripts/common.sh`)
- Two distinct script patterns: educational examples (`examples.sh`) and executable use-case scripts (`<use-case>.sh`)
- Claude Code hooks enforce a safety architecture: PreToolUse blocks raw tool calls and out-of-scope targets, PostToolUse parses JSON output for structured summaries
- Dual output mode: human-readable colored text (default) or structured JSON envelope (`-j` flag)
- Dual execution mode: display-only (default) or live execution (`-x` flag)

## Layers

**Shared Library Layer:**
- Purpose: Provides all shared utilities loaded by every script
- Location: `scripts/lib/`
- Contains: 10 focused modules — `strict.sh`, `colors.sh`, `logging.sh`, `validation.sh`, `cleanup.sh`, `json.sh`, `output.sh`, `args.sh`, `diagnostic.sh`, `nc_detect.sh`
- Depends on: Nothing external; loaded in dependency order by `scripts/common.sh`
- Used by: Every `examples.sh` and use-case script via `source "$(dirname "$0")/../common.sh"`

**Script Entry Point:**
- Purpose: Aggregates all lib modules in correct dependency order, enforces Bash 4.0+ requirement, and prevents double-sourcing
- Location: `scripts/common.sh`
- Contains: Source guard, Bash version guard, ordered `source` calls for all lib modules
- Depends on: `scripts/lib/`
- Used by: All scripts under `scripts/<tool>/` and `scripts/diagnostics/`

**Pattern A — Educational Scripts (`examples.sh`):**
- Purpose: Display 10 numbered example commands with explanations; offer optional interactive demo
- Location: `scripts/<tool>/examples.sh` (one per tool directory)
- Contains: `show_help()`, `parse_common_args`, `require_cmd`, optional `require_target`, `safety_banner`, 10 `run_or_show` calls, interactive demo block
- Depends on: `common.sh`
- Used by: Users learning tools and by the Makefile convenience targets

**Pattern B — Diagnostic Scripts:**
- Purpose: Auto-run checks and report pass/fail/warn results; non-interactive, no safety_banner
- Location: `scripts/diagnostics/connectivity.sh`, `scripts/diagnostics/dns.sh`, `scripts/diagnostics/performance.sh`
- Contains: Uses `run_check()` and `report_pass/fail/warn/skip` from `lib/diagnostic.sh`
- Depends on: `common.sh`
- Used by: Direct invocation for connectivity and DNS troubleshooting

**Pattern A — Use-Case Scripts:**
- Purpose: Task-focused scripts that support `-j` (JSON output) and `-x` (execute) flags; consumed by Claude skill workflows
- Location: `scripts/<tool>/<use-case>.sh` (e.g., `scripts/nmap/discover-live-hosts.sh`)
- Contains: `json_set_meta`, `parse_common_args`, `require_cmd`, `run_or_show` calls, `json_finalize`
- Depends on: `common.sh`
- Used by: Claude Code skills, direct invocation, CI integration

**Claude Safety Hook Layer:**
- Purpose: Enforce target scope allowlist, block raw tool usage, audit all invocations, inject parsed JSON into Claude context
- Location: `.claude/hooks/netsec-pretool.sh`, `.claude/hooks/netsec-posttool.sh`
- Contains: PreToolUse hook (blocks, allows, audits) and PostToolUse hook (parses JSON envelope, emits `additionalContext`)
- Depends on: `.pentest/scope.json`, `jq`
- Used by: Claude Code automatically on every Bash tool call

**Skill Layer:**
- Purpose: Provide Claude Code with tool-specific instructions, workflow scripts, and subagent persona definitions
- Location: `.claude/skills/<skill-name>/SKILL.md`
- Contains: Skill metadata (YAML frontmatter), available scripts, flag descriptions, usage guidance
- Depends on: Script layer
- Used by: Claude Code when skill is activated

**Documentation Site Layer:**
- Purpose: Static Astro/Starlight documentation site for human learners
- Location: `site/`
- Contains: MDX tool pages under `site/src/content/docs/tools/`, guides under `site/src/content/docs/guides/`, Astro components, Starlight theme
- Depends on: Nothing from the script layer at build time; documents what the scripts do
- Used by: End users browsing the documentation

**Lab Environment:**
- Purpose: Provides intentionally vulnerable Docker targets for safe practice
- Location: `labs/docker-compose.yml`
- Contains: DVWA, Juice Shop, WebGoat, VulnerableApp service definitions
- Depends on: Docker
- Used by: Learners running `make lab-up` to get practice targets

## Data Flow

**Show Mode (Default) — Human Text Output:**

1. User runs `bash scripts/<tool>/examples.sh <target>` or `make <tool> TARGET=<ip>`
2. Script sources `common.sh` → loads all lib modules in order
3. `parse_common_args` processes flags; `EXECUTE_MODE=show`, `JSON_MODE=0`
4. `require_cmd` validates the tool is installed
5. `safety_banner` prints authorization warning
6. Each `run_or_show "N) Description" command [args...]` prints colored description + indented command string to stdout
7. Interactive demo block checks `[[ -t 0 ]]` and optionally prompts to run one command

**Execute Mode (`-x` flag) — Live Execution:**

1. User runs `bash scripts/<tool>/<use-case>.sh <target> -x`
2. PreToolUse hook intercepts if invoked by Claude Code; validates target against `.pentest/scope.json`; writes audit log
3. `confirm_execute` prompts for confirmation if interactive
4. Each `run_or_show` call executes the command directly and prints output
5. PostToolUse hook records exit code in audit log

**JSON Mode (`-j` flag) — Structured Output for Claude:**

1. Claude Code invokes `bash scripts/<tool>/<use-case>.sh <target> -j -x`
2. PreToolUse hook validates scope, writes audit entry
3. `parse_common_args` detects `-j`: redirects stdout to stderr, saves original stdout as fd3, sets `NO_COLOR=1`
4. `json_set_meta` records tool/target/category metadata
5. Each `run_or_show` in execute mode: captures stdout/stderr to temp files via `make_temp`, calls `json_add_result`
6. `json_finalize` assembles JSON envelope with `meta`, `results`, `summary` and writes to fd3 (original stdout)
7. PostToolUse hook reads stdout, detects JSON envelope, parses summary, emits `additionalContext` to Claude context

**Error Handling Flow:**

1. `set -eEuo pipefail` (from `lib/strict.sh`) causes any unhandled error to trigger the ERR trap
2. ERR trap (`_strict_error_handler`) prints command, line number, and full call stack to stderr
3. EXIT trap (`_cleanup_handler`) removes all temp files under `$_CLEANUP_BASE_DIR` and runs registered cleanup commands

**State Management:**
- No persistent state between script runs; all state is in-process shell variables
- Scope file `.pentest/scope.json` is the only persistent configuration read at runtime
- Audit log `.pentest/audit-<date>.jsonl` is append-only; written by hooks

## Key Abstractions

**`run_or_show`:**
- Purpose: Single function that conditionally prints or executes a command, and conditionally accumulates JSON results
- Examples: Used in every `examples.sh` and use-case script in `scripts/`
- Pattern: `run_or_show "N) Description" command [args...]` — branches on `EXECUTE_MODE` and `JSON_MODE`

**`parse_common_args`:**
- Purpose: Strips common flags (`-h`, `-v`, `-q`, `-x`, `-j`, `--`) from `$@`, sets global mode variables, leaves tool-specific args in `REMAINING_ARGS`
- Examples: `scripts/lib/args.sh`
- Pattern: Called at top of every script; tool-specific args accessed via `"${REMAINING_ARGS[@]}"`

**JSON Envelope:**
- Purpose: Structured output format allowing Claude to parse scan results programmatically
- Examples: `scripts/lib/json.sh` builds the envelope; PostToolUse hook parses it
- Pattern: `{ meta: {...}, results: [...], summary: { total, succeeded, failed } }`

**Source Guard:**
- Purpose: Every lib module starts with `[[ -n "${_MODULE_LOADED:-}" ]] && return 0` to prevent double-sourcing
- Examples: All files in `scripts/lib/`
- Pattern: `_STRICT_LOADED`, `_ARGS_LOADED`, `_JSON_LOADED`, etc.

**`make_temp`:**
- Purpose: Create temp files/dirs under a session-scoped base dir that is auto-cleaned on EXIT
- Examples: `scripts/lib/cleanup.sh`
- Pattern: All temp files created via `make_temp`; EXIT trap removes `$_CLEANUP_BASE_DIR` entirely

## Entry Points

**Makefile:**
- Location: `Makefile`
- Triggers: `make check`, `make lab-up/down/status`, `make <tool> TARGET=<value>`, `make site-dev`, `make test`
- Responsibilities: Convenience wrapper over `bash scripts/...`, `docker compose`, and `cd site && npm run ...`

**Tool Examples Script:**
- Location: `scripts/<tool>/examples.sh`
- Triggers: Direct invocation or Makefile target
- Responsibilities: Source common.sh, validate tool installed, display 10 examples, offer interactive demo

**Use-Case Script:**
- Location: `scripts/<tool>/<use-case>.sh`
- Triggers: Direct invocation, Claude Code skill workflows, CI
- Responsibilities: Source common.sh, validate tool, accept `-j`/`-x` flags, execute or display task-specific commands, emit JSON envelope

**check-tools.sh:**
- Location: `scripts/check-tools.sh`
- Triggers: `make check`
- Responsibilities: Iterates `TOOL_ORDER` array, checks 18 tools, prints install status and hints

**PreToolUse Hook:**
- Location: `.claude/hooks/netsec-pretool.sh`
- Triggers: Every Bash tool call from Claude Code
- Responsibilities: Fast-exit for non-security commands; block raw tool calls; validate target against scope; write audit log; deny with JSON reason

**PostToolUse Hook:**
- Location: `.claude/hooks/netsec-posttool.sh`
- Triggers: After every Bash tool call from Claude Code that invoked a wrapper script
- Responsibilities: Parse JSON envelope from stdout; write audit log; emit `additionalContext` to Claude context

## Error Handling

**Strategy:** Fail fast with informative messages; strict mode at library level; ERR trap provides stack traces; EXIT trap always cleans temp files.

**Patterns:**
- `lib/strict.sh` enables `set -eEuo pipefail` and installs ERR trap with stack trace printer
- `require_cmd` and `require_target` in `lib/validation.sh` exit with `error` messages before execution begins
- `run_or_show` in execute+JSON mode captures stderr to a temp file and stores it in the JSON result; never aborts on individual command failures
- `retry_with_backoff` in `lib/cleanup.sh` handles transient command failures with exponential backoff

## Cross-Cutting Concerns

**Logging:** `lib/logging.sh` provides `debug/info/success/warn/error` with `LOG_LEVEL` filtering and optional timestamps (`VERBOSE >= 1`). Errors always print to stderr.

**Color:** `lib/colors.sh` defines ANSI color vars; auto-disables when `NO_COLOR` is set or stdout is not a terminal. JSON mode also resets colors to empty.

**Validation:** `lib/validation.sh` provides `require_cmd`, `require_target`, `check_cmd`, `require_root`, `setup_john_path`. Called at top of each script before any work.

**Temp file cleanup:** `lib/cleanup.sh` registers EXIT trap; all temp files go through `make_temp` into a session-scoped directory automatically removed on exit.

**Audit:** PreToolUse and PostToolUse hooks write JSONL audit entries to `.pentest/audit-<date>.jsonl` for every security tool invocation.

**Scope enforcement:** `.pentest/scope.json` is the single source of truth for allowed targets. PreToolUse hook reads it before allowing any wrapper script invocation.

---

*Architecture analysis: 2026-02-23*
