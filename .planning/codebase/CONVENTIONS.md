# Coding Conventions

**Analysis Date:** 2026-02-10

## Language & Environment

**Primary Language:** Bash (shell scripting)

**Shebang:**
- All scripts use `#!/usr/bin/env bash` for portability across systems

**Shell Settings:**
- All shared utilities and core scripts use `set -euo pipefail` to enforce strict error handling
  - `-e`: Exit immediately if any command fails
  - `-u`: Exit if undefined variables are used
  - `-o pipefail`: Pipeline fails if any command in pipe fails
- Example from `scripts/common.sh` (line 5):
  ```bash
  set -euo pipefail
  ```

## Naming Patterns

**Files:**
- Script files: `lowercase-with-hyphens.sh` (e.g., `discover-live-hosts.sh`, `crack-ntlm-hashes.sh`)
- Configuration files: `docker-compose.yml`, `Makefile`
- Documentation: `UPPERCASE.md` (e.g., `README.md`, `USECASES.md`)

**Functions:**
- Function names: `lowercase_with_underscores` (e.g., `require_cmd`, `check_cmd`, `safety_banner`)
- Private helper functions: No prefix convention, but used within `common.sh`
- Functions defined in `scripts/common.sh` include:
  - `require_root` — Verify running as root
  - `check_cmd` — Boolean check if command exists
  - `require_cmd` — Exit with error if command not found
  - `require_target` — Exit with error if target argument missing
  - `safety_banner` — Print authorization warning
  - `is_interactive` — Check if running in terminal
  - Logging functions: `info`, `success`, `warn`, `error`

**Variables:**
- Global constants: `UPPERCASE` (e.g., `RED`, `GREEN`, `BLUE`, `PROJECT_ROOT`, `TARGET`, `WORDLIST`)
- Local variables: `lowercase` (e.g., `target`, `answer`, `tmpfile`)
- Environment variables from `common.sh`:
  - `RED`, `GREEN`, `YELLOW`, `BLUE`, `CYAN`, `NC` (colors)
  - `PROJECT_ROOT` — Base directory of repository, resolved from script location
- Variables with defaults use parameter expansion: `"${1:-default_value}"`

**Directory Variables:**
- `PROJECT_ROOT` is calculated from script location and made available to all sourcing scripts:
  ```bash
  PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  ```
- Used to reference wordlists: `"${PROJECT_ROOT}/wordlists/rockyou.txt"`

## Code Style

**Formatting:**
- Indentation: 4 spaces (not tabs)
- Line length: No strict limit, but lines generally under 100 characters
- Comments use `#` with space after
- Multiple statements per line: Not used (one statement per line)

**Linting:**
- No automated linting tool configured (ShellCheck not required)
- Follows common bash best practices manually

**Quoting:**
- Variables always quoted when used: `"$variable"` or `"${variable}"`
- Exception: arithmetic expansions like `[[ $EUID -ne 0 ]]`
- Array variables quoted: `"${TOOL_ORDER[@]}"`
- Command substitution uses `$()` not backticks: `TMPFILE=$(mktemp /tmp/xxx)`

## Import Organization

**Sourcing Pattern:**
All scripts start by sourcing `common.sh` from relative path:
```bash
source "$(dirname "$0")/../common.sh"
```

**Structure:**
- Every script imports common.sh first (within 3 lines of shebang)
- Shared utilities from `common.sh` are then available

**Project Root Access:**
- After sourcing `common.sh`, scripts can use `$PROJECT_ROOT` to access wordlists or other resources
- Example from `scripts/john/crack-linux-passwords.sh`:
  ```bash
  WORDLIST="${PROJECT_ROOT}/wordlists/rockyou.txt"
  ```

## Error Handling

**Patterns:**
- **Exit on command failure:** Enforced by `set -e` at script level
- **Explicit validation:** Use `require_cmd`, `require_target`, `require_root` before operations
- **Conditional execution:** Use short-circuit operators `&&` and `||`
  ```bash
  [[ -f "$file" ]] && cat "$file" || warn "File not found"
  ```
- **Subshell error suppression:** Only when appropriate
  ```bash
  version=$(timeout 5 "$tool" --version 2>/dev/null | head -1) || echo "installed"
  ```
- **Temporary file cleanup:** Use `mktemp` with explicit `rm -f` in cleanup blocks

**Exit codes:**
- Exit 0: Success
- Exit 1: Command not found, target not provided, not running as root, or command failure
- No custom exit codes used

**Error messages:**
- Printed to stderr via `error()` function (which adds `>&2`)
- Format: `[ERROR] message`
- Example from `common.sh`:
  ```bash
  error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
  ```

## Logging

**Framework:** Manual logging with colored functions (no external logging library)

**Logging Functions (defined in `common.sh`):**
- `info` — Blue `[INFO]` prefix, general informational messages
- `success` — Green `[OK]` prefix, successful operations
- `warn` — Yellow `[WARN]` prefix, warnings
- `error` — Red `[ERROR]` prefix, errors (output to stderr)

**Patterns:**
- All numbered examples (1-10) use `info "N) Title"` prefix
- Command display uses plain `echo` with indentation
- Explanatory text between examples uses `echo` with indentation
- Empty lines between examples use bare `echo ""`
- Safety banner printed before active scanning via `safety_banner` function

**Example from `scripts/nmap/examples.sh` (lines 33-36):**
```bash
# 1. Quick host discovery (ping scan — no port scan)
info "1) Ping scan — is the host up?"
echo "   nmap -sn ${TARGET}"
echo ""
```

## Comments

**When to Comment:**
- Script purpose: Required in file header with path and description
- Function definitions: Brief inline comment explaining purpose
- Complex logic: Inline comments for algorithm explanation
- Command explanations: Descriptions in numbered sections

**Format:**
- File header: `# <tool>/<script>.sh — Description` (line 1-2)
- Inline comments: `# Comment` with space after hash
- Section dividers: Not used

**Example from `scripts/nmap/discover-live-hosts.sh` (lines 1-3):**
```bash
#!/usr/bin/env bash
# nmap/discover-live-hosts.sh — Find all active hosts on a subnet
source "$(dirname "$0")/../common.sh"
```

## Function Design

**Size:** Functions are typically 5-15 lines
- `check_cmd` (4 lines): Single conditional
- `require_cmd` (7 lines): Check and conditional error handling
- `require_target` (6 lines): Validation with error messages
- `safety_banner` (8 lines): Formatted output

**Parameters:**
- Functions take positional arguments: `require_cmd "$1" "$2"`
- Optional second parameter with default: `local install_hint="${2:-}"`
- No function-specific validation beyond what shared functions provide

**Return Values:**
- No explicit `return` statements used
- Functions produce side effects (logging, exiting)
- `check_cmd` returns exit code: `command -v "$1" &>/dev/null` (implicit)

**Scope:**
- Global variables in caps: `RED`, `GREEN`, `PROJECTROOT`
- Local variables scoped with `local` in functions
- No global mutable state (beyond colors and paths)

## Module Design

**Exports:**
- `common.sh` defines functions, color variables, and `PROJECT_ROOT`
- All scripts that source `common.sh` get access to all functions and variables
- No explicit export mechanism (bash doesn't require it for sourced scripts)

**Main Script Pattern (every `examples.sh` and use-case script):**
1. Shebang
2. File header comment
3. Source `common.sh`
4. Define `show_help()` function
5. Parse help flag and exit
6. Call validation functions (`require_cmd`, `require_target`)
7. Call `safety_banner` before active scanning
8. Set local variables (`TARGET`, `WORDLIST`, etc.)
9. Display title and context
10. Print 10 numbered examples
11. Interactive demo (conditional on terminal detection)

**Barrel Files:** Not used (no aggregating re-export files)

## Conditional Execution

**Test Syntax:**
- Use `[[ ... ]]` for bash conditionals (preferred over `[ ... ]`)
- Use `if [[ ... ]]; then ... fi` for multi-line conditionals
- Use `[[ condition ]] && action` for single-line conditionals
- Negation: `[[ ! -t 0 ]]` (not interactive)

**Examples:**
```bash
# Help flag check
[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

# File existence
[[ -f "$file" ]] && ...

# Non-empty string
[[ -n "$var" ]] && ...

# Interactive terminal
[[ -t 0 ]]
```

## Argument Parsing

**Pattern:**
- First positional arg for main parameter: `$1`
- Second positional for optional: `$2`
- Default values via parameter expansion: `"${1:-default}"`
- Help flag: `[[ "${1:-}" =~ ^(-h|--help)$ ]]`
- No getopt/getopts used

**Example from `generate-reverse-shell.sh` (lines 24-25):**
```bash
LHOST="${1:-$(ipconfig getifaddr en0 2>/dev/null || echo '10.0.0.1')}"
LPORT="${2:-4444}"
```

## Path Handling

**Absolute Paths:**
- `PROJECT_ROOT` resolved at script source time: `"$(dirname "${BASH_SOURCE[0]}")/..")`
- Temp files: `$(mktemp /tmp/name.XXXXXX)`
- No relative path assumptions

**Variable Reference:**
- Quotes always around paths: `"$PROJECT_ROOT"`, `"$TMPFILE"`, `"$output_dir"`

---

*Convention analysis: 2026-02-10*
