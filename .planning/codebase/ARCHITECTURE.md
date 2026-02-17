# Architecture

**Analysis Date:** 2026-02-17

## Pattern Overview

**Overall:** Educational Script Collection with Shared Library Architecture

**Key Characteristics:**
- Bash-based tool demonstration framework with modular shared libraries
- Each security tool has isolated directory with examples.sh + specialized use-case scripts
- Common functionality extracted into `scripts/lib/` modules sourced via `scripts/common.sh`
- Two distinct script patterns: interactive demos (Pattern A) and diagnostic auto-reports (Pattern B)
- Makefile provides unified CLI interface across all tools

## Layers

**Tool Scripts (Presentation Layer):**
- Purpose: Demonstrate pentesting tools through educational examples and use cases
- Location: `scripts/<tool-name>/*.sh`
- Contains: Tool-specific example runners and specialized scenario scripts
- Depends on: Shared libraries via `scripts/common.sh`, external pentesting tools (nmap, tshark, etc.)
- Used by: End users via Makefile targets or direct invocation

**Shared Library (Core Utilities):**
- Purpose: Provide reusable validation, formatting, logging, and execution control
- Location: `scripts/lib/`
- Contains: Modular bash functions for common operations
- Depends on: Bash 4.0+ features (associative arrays, mapfile)
- Used by: All tool scripts via `source "$(dirname "$0")/../common.sh"`

**Common Entry Point:**
- Purpose: Orchestrate library module loading in dependency order
- Location: `scripts/common.sh`
- Contains: Source guard, Bash version check, ordered module imports
- Depends on: All `scripts/lib/*.sh` modules
- Used by: Every tool script as first sourced dependency

**Task Orchestration (Makefile):**
- Purpose: Provide user-friendly interface with tab completion and help
- Location: `Makefile`
- Contains: Targets for each tool + use case with TARGET parameter support
- Depends on: Underlying bash scripts
- Used by: End users via `make <target>`

**Lab Environment:**
- Purpose: Provide safe, isolated vulnerable targets for practice
- Location: `labs/docker-compose.yml`
- Contains: Four Docker services (DVWA, Juice Shop, WebGoat, VulnerableApp)
- Depends on: Docker/Docker Compose
- Used by: Tool scripts when targeting localhost practice environments

**Documentation Site:**
- Purpose: Host interactive documentation and guides
- Location: `site/` (Astro-based static site)
- Contains: Component-based documentation build
- Depends on: Node.js, Astro framework
- Used by: End users accessing web documentation

**Testing Framework:**
- Purpose: Validate script contracts, library functions, and integration behavior
- Location: `tests/*.bats`
- Contains: BATS test suites for CLI contracts, JSON output, lib modules
- Depends on: BATS (tests/bats/), bats-support, bats-assert, bats-file
- Used by: CI/CD via `make test`

## Data Flow

**Tool Demonstration Flow:**

1. User runs `make <target> TARGET=<value>` or `bash scripts/<tool>/examples.sh <target>`
2. Script sources `common.sh`, which loads all lib modules in order
3. `parse_common_args "$@"` extracts flags (-h, -x, -j, -v) into globals (EXECUTE_MODE, JSON_MODE)
4. `require_cmd <tool>` validates external tool exists, exits with install hint if missing
5. `require_target` validates target argument if needed
6. `safety_banner` displays legal warning (unless JSON_MODE active)
7. Script calls `run_or_show "Description" command args...` for each example
8. `run_or_show` either prints command (show mode) or executes it (execute mode with -x)
9. JSON mode captures outputs via file descriptors, formats as structured JSON at end
10. Interactive prompt offers to run demo command if stdin is terminal

**Library Module Loading:**

1. `common.sh` sets source guard to prevent double-loading
2. Bash version check ensures 4.0+ (required for associative arrays)
3. Modules loaded in dependency order:
   - `strict.sh` → set -euo pipefail
   - `colors.sh` → terminal color codes
   - `logging.sh` → info/warn/error/success functions
   - `validation.sh` → require_cmd, require_target, check_cmd
   - `cleanup.sh` → trap handlers for temp file cleanup
   - `json.sh` → JSON mode plumbing
   - `output.sh` → run_or_show, safety_banner, confirm_execute
   - `args.sh` → parse_common_args flag parser
   - `diagnostic.sh` → diagnostic-specific helpers
   - `nc_detect.sh` → detect netcat variant

**State Management:**
- Execution mode stored in `EXECUTE_MODE` global ("show" or "execute")
- JSON mode stored in `JSON_MODE` global (0 or 1)
- Remaining arguments after flag parsing stored in `REMAINING_ARGS` array
- Each module sets `_MODULE_LOADED=1` guard to prevent re-sourcing

## Key Abstractions

**Tool Script Pattern (Pattern A - Interactive Demo):**
- Purpose: Standardized structure for tool demonstration scripts
- Examples: `scripts/nmap/examples.sh`, `scripts/sqlmap/examples.sh`, `scripts/tshark/capture-http-credentials.sh`
- Pattern:
  1. Shebang + description header
  2. `source "$(dirname "$0")/../common.sh"`
  3. `show_help()` function with Usage/Description/Examples
  4. `parse_common_args "$@"` + reset positional params
  5. `require_cmd <tool> "<install-hint>"`
  6. Target extraction with default
  7. `confirm_execute` + `safety_banner`
  8. Educational context (WHY section)
  9. 10 numbered examples via `run_or_show` or `info + echo`
  10. Interactive demo with `[[ ! -t 0 ]] && exit 0` guard

**Diagnostic Script Pattern (Pattern B - Auto-Report):**
- Purpose: Non-interactive diagnostic reports
- Examples: `scripts/diagnostics/dns.sh`, `scripts/diagnostics/connectivity.sh`
- Pattern: Runs diagnostic checks automatically, outputs structured report, no safety banner

**Modular Library Function:**
- Purpose: Encapsulated, reusable bash function with documentation
- Examples: `require_cmd`, `run_or_show`, `json_add_example`
- Pattern: Function in `scripts/lib/<module>.sh` with header comment, source guard, exported for use by tool scripts

**Run-or-Show Abstraction:**
- Purpose: Dual-mode command execution (display vs. execute)
- Location: `scripts/lib/output.sh` → `run_or_show()`
- Pattern: Takes description + command, either prints it (show) or executes it (execute), accumulates JSON in JSON mode
- Used throughout all tool scripts for consistent behavior

## Entry Points

**Makefile:**
- Location: `Makefile`
- Triggers: User invokes `make <target>` with optional TARGET parameter
- Responsibilities: Maps semantic targets to underlying bash scripts, passes TARGET arg, provides help system

**Tool Examples Script:**
- Location: `scripts/<tool>/examples.sh`
- Triggers: Direct invocation or via Makefile
- Responsibilities: Display 10 generic examples for the tool, optional interactive demo

**Use-Case Scripts:**
- Location: `scripts/<tool>/<use-case>.sh`
- Triggers: Direct invocation or via Makefile specialized targets
- Responsibilities: Demonstrate specific pentesting scenario with focused examples

**Diagnostic Scripts:**
- Location: `scripts/diagnostics/<diagnostic>.sh`
- Triggers: Direct invocation or via Makefile diagnose-* targets
- Responsibilities: Run automated diagnostic checks, output structured report

**Check Tools:**
- Location: `scripts/check-tools.sh`
- Triggers: `make check`
- Responsibilities: Enumerate 18 pentesting tools, show installed versions, provide install hints for missing tools

**Lab Management:**
- Location: Docker Compose commands via Makefile
- Triggers: `make lab-up`, `make lab-down`, `make lab-status`
- Responsibilities: Start/stop vulnerable practice containers

## Error Handling

**Strategy:** Fail-fast with informative messages

**Patterns:**
- `set -euo pipefail` in `strict.sh` causes immediate exit on command failure, undefined variable, or pipe failure
- `require_cmd` exits with error message + install hint if tool missing
- `require_target` exits if mandatory target argument not provided
- `confirm_execute` refuses to run in execute mode if stdin not a terminal (prevents accidental automation)
- Library functions validate inputs before proceeding (e.g., `json_require_jq` checks for jq before JSON mode activates)
- Source guards prevent double-loading of modules
- Bash version guard in `common.sh` exits on Bash < 4.0 with clear macOS-specific guidance

## Cross-Cutting Concerns

**Logging:** Colored output via `info/warn/error/success` functions in `scripts/lib/logging.sh`, automatically suppressed in JSON mode via NO_COLOR=1

**Validation:** Centralized in `scripts/lib/validation.sh` via `require_cmd`, `require_target`, `require_root`, `check_cmd`

**Authentication:** Lab targets have default credentials (DVWA: admin/password, others require registration), documented in Makefile and README

**Cleanup:** Temp file cleanup via trap handlers in `scripts/lib/cleanup.sh`, registered automatically when sourcing common.sh

**Portability:** Detects macOS vs. Linux differences (e.g., netcat variants, Homebrew paths), provides platform-specific install hints

**Testing:** BATS framework validates CLI contracts (--help exits 0, -x rejects pipes), library functions (args.sh, json.sh, logging.sh), and integration behavior (JSON output structure)

---

*Architecture analysis: 2026-02-17*
