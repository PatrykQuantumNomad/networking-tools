# Architecture

**Analysis Date:** 2026-02-10

## Pattern Overview

**Overall:** Modular educational CLI tool orchestration framework with shared utility layer

**Key Characteristics:**
- Tool-agnostic command-line interface paired with educational scripts
- Layered architecture: shared utilities → individual tool scripts → interactive demos
- Heavy reliance on bash sourcing for code reuse across 11 different security tools
- Comprehensive safety checks and legal guardrails baked into every execution path
- Docker-based vulnerable lab targets for safe, isolated practice

## Layers

**Shared Utilities Layer:**
- Purpose: Provide common functions for prerequisites, logging, safety checks, and project paths
- Location: `scripts/common.sh`
- Contains: Color definitions, privilege checks (require_root), command verification (check_cmd, require_cmd), target validation (require_target), safety banners, logging functions (info, success, warn, error), interactive terminal detection
- Depends on: None (foundational)
- Used by: Every tool script in the framework

**Tool Scripts Layer:**
- Purpose: Provide generic tool demonstrations with 10 numbered examples plus optional interactive demo
- Location: `scripts/<tool>/examples.sh` (11 tools: nmap, tshark, metasploit, aircrack-ng, hashcat, skipfish, sqlmap, hping3, john, nikto, foremost)
- Contains: help functions, tool validation, target validation, safety banners, 10 numbered example commands with explanations, interactive demo prompts
- Depends on: Shared utilities layer
- Used by: Makefile targets, direct bash invocations, user learning workflow

**Use-Case Scripts Layer:**
- Purpose: Implement specific task-focused workflows combining multiple commands for real security operations
- Location: `scripts/<tool>/<use-case>.sh` (28 total across tools)
- Contains: Task-specific help, prerequisite validation, educational context (WHY), numbered command examples, interactive execution demos
- Depends on: Shared utilities layer, tool installation
- Used by: Makefile convenience targets, advanced workflow execution

**Orchestration Layer:**
- Purpose: Provide convenient entry points and make targets for all tool operations
- Location: `Makefile`
- Contains: Help system, tool runners, use-case invokers, lab environment controls
- Depends on: Tool scripts
- Used by: End users, educational workflows

**Lab Environment Layer:**
- Purpose: Provide intentionally vulnerable targets for safe isolated practice
- Location: `labs/docker-compose.yml`
- Contains: Docker services (DVWA, Juice Shop, WebGoat, VulnerableApp), port bindings, credentials, vulnerability scope documentation
- Depends on: Docker, Docker Compose
- Used by: All web-focused and application security testing scripts

**Documentation Layer:**
- Purpose: Provide context, learning paths, quick reference, and detailed tool guidance
- Location: `README.md`, `CLAUDE.md`, `USECASES.md`, `notes/<tool>.md`
- Contains: Quick start guides, tool purposes, legal disclaimers, use-case mappings, detailed command progressions
- Depends on: None
- Used by: New users, educators, script developers

## Data Flow

**Tool Discovery Flow:**

1. User runs `make check`
2. Makefile invokes `scripts/check-tools.sh`
3. check-tools.sh sources `common.sh` (loads utilities and PATH augmentation)
4. check-tools.sh iterates through TOOL_ORDER array with TOOLS mapping
5. Uses `check_cmd` utility to verify each tool exists in PATH (including custom paths like `/opt/metasploit-framework/bin`)
6. Calls `get_version` helper (tool-specific version extraction)
7. Uses logging functions (success/warn) to report installed/missing status
8. Outputs installation hints for missing tools

**Typical Learning/Execution Flow:**

1. User runs `make discover-hosts TARGET=192.168.1.0/24`
2. Makefile maps to `scripts/nmap/discover-live-hosts.sh`
3. Script sources `common.sh` (utilities, color setup, PROJECT_ROOT resolution)
4. Script runs `require_cmd nmap "brew install nmap"` (exits if missing)
5. Script validates TARGET argument (from parameter or default)
6. Script displays `safety_banner` (legal authorization warning)
7. Script prints educational context explaining WHY this matters
8. Script prints 10 numbered examples with actual commands to run
9. If interactive, script offers to run a demo command
10. Script exits (does not execute commands by default - educational only)

**Interactive Execution Flow:**

1. User interactively agrees to run a demo
2. Script executes actual command(s) via bash/eval
3. Output returned to user
4. Script exits

**Lab Environment Setup Flow:**

1. User runs `make lab-up`
2. Makefile calls `docker compose -f labs/docker-compose.yml up -d`
3. Docker Compose starts 4 intentionally vulnerable services in background
4. Each service maps to local port (8080, 3030, 8888, 8180)
5. Services have restart policy (unless-stopped)
6. Makefile prints service URLs and credentials to console
7. Users can now run tool scripts against lab targets
8. `make lab-down` stops all services

**Use-Case Specific Flow (example: SQLi testing):**

1. User runs `make dump-db TARGET=http://localhost:8180/VulnerableApp`
2. Makefile invokes `scripts/sqlmap/dump-database.sh`
3. Script validates sqlmap installed, target provided, gets authorization confirmation
4. Script displays how SQL injection works and why dumping databases matters
5. Script prints 10+ specific sqlmap commands for progressively sophisticated database enumeration
6. Script offers to run safe demo (e.g., basic SQLi detection)
7. User can follow along with printed commands or let script demo

**State Management:**

- No persistent state beyond command outputs
- Each script execution is independent (stateless)
- Lab environment managed via Docker Compose (persistent containers until `make lab-down`)
- All tool state managed by the external tools themselves (nmap, sqlmap, etc.)
- No database or configuration persistence within scripts

## Key Abstractions

**Requirement Validation Abstraction:**
- Purpose: Normalize prerequisites across all 11 tools and ensure safety
- Examples: `require_root`, `require_cmd`, `require_target`, `check_cmd`
- Pattern: Functions return exit code 0 (success) or exit script with error message and optional install hint

**Logging Abstraction:**
- Purpose: Consistent colored output across all scripts and tool output
- Examples: `info`, `success`, `warn`, `error` functions
- Pattern: Functions echo with color prefixes to stdout/stderr; ANSI color codes defined once, reused everywhere

**Target Handling Abstraction:**
- Purpose: Normalize how different tool scripts receive and validate targets
- Examples: `require_target` validates argument exists; scripts support `--help` flag; defaults where sensible
- Pattern: Each tool accepts target as `$1` or uses sensible default (localhost); `require_target` exits with usage if missing

**Tool Invocation Abstraction:**
- Purpose: Provide consistent interface across vastly different tools (nmap, sqlmap, tshark, hashcat, etc.)
- Examples: Each tool gets `<tool>/examples.sh`, `<tool>/<use-case>.sh` scripts
- Pattern: 10 example format, help function, safety checks, same execution flow

**Project Path Abstraction:**
- Purpose: Allow scripts to resolve repository root from any location
- Examples: `PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"`
- Pattern: Defined once in common.sh, used by any script needing project resources

## Entry Points

**Command-Line Entry Point (Makefile):**
- Location: `Makefile`
- Triggers: `make <target>`, `make help`, `make check`, `make nmap`, `make lab-up/down`, etc.
- Responsibilities: Parse user intent, pass arguments to appropriate script, display help, control lab environment

**Tool Examples Entry Point:**
- Location: `scripts/<tool>/examples.sh`
- Triggers: `bash scripts/<tool>/examples.sh <target>`, `make <tool> TARGET=<value>`
- Responsibilities: Validate tool installed, validate target, display safety warning, print 10 examples, optionally run demo

**Use-Case Entry Points:**
- Location: `scripts/<tool>/<use-case>.sh`
- Triggers: `bash scripts/<tool>/<use-case>.sh <args>`, `make <make-target> TARGET=<value>`
- Responsibilities: Task-specific setup, context explanation, progressive examples, interactive demo

**Lab Environment Entry Point:**
- Location: `labs/docker-compose.yml`
- Triggers: `make lab-up`, `make lab-down`, `make lab-status`
- Responsibilities: Manage Docker services, control intentionally vulnerable targets

**Tool Discovery Entry Point:**
- Location: `scripts/check-tools.sh`
- Triggers: `make check`, `bash scripts/check-tools.sh`
- Responsibilities: Detect installed tools, report versions, suggest installations

## Error Handling

**Strategy:** Fail early with clear error messages, minimal recovery

**Patterns:**

- **Missing Tool:** `require_cmd <tool> "install hint"` exits with colored error message and installation command
- **Missing Target:** `require_target` exits with usage example and legal warning
- **Requires Root:** `require_root` checks EUID and exits if not running as root
- **Invalid Arguments:** Help function called with `--help` or `-h` flag; script sources help and exits cleanly
- **Interactive vs Non-Interactive:** `[[ ! -t 0 ]] && exit 0` skips interactive demos when piped/cron'd

**Exit Codes:**
- 0 = success (displayed examples or ran demo without error)
- 1 = failure (missing tool, missing target, wrong privileges, invalid args)

## Cross-Cutting Concerns

**Logging:** All scripts use color-coded logging functions (info, success, warn, error) sourced from `scripts/common.sh` to ensure consistent output across tools

**Validation:** Every script validates prerequisites (tool installed, target provided, root if needed) before displaying examples or executing code

**Authorization:** Every script displays `safety_banner` (legal warning) before suggesting active scanning/exploitation

**Interactivity:** Scripts detect terminal (`is_interactive` function) and skip interactive prompts when piped/cron'd, allowing safe automation

**Extensibility:** New tools added by: (1) creating `scripts/<tool>/examples.sh` following pattern, (2) adding to `check-tools.sh` TOOLS array and TOOL_ORDER, (3) optionally adding Makefile target

---

*Architecture analysis: 2026-02-10*
