# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A pentesting learning lab with bash scripts demonstrating 10 open-source security tools, plus a Docker-based practice environment with vulnerable targets. All scripts are educational — they print example commands with explanations and optionally run demos interactively.

## Common Commands

```bash
make check          # Verify which of the 10 tools are installed
make lab-up         # Start Docker vulnerable targets (DVWA, Juice Shop, WebGoat, Metasploitable)
make lab-down       # Stop lab targets
make lab-status     # Show running lab containers
make help           # List all Makefile targets

# Run a specific tool's examples
bash scripts/nmap/examples.sh <target>
bash scripts/nikto/examples.sh <target>
make nmap TARGET=<ip>
make sqlmap TARGET=<url>
```

## Architecture

```
scripts/
  common.sh              # Shared bash functions (colors, safety_banner, require_cmd, require_target)
  check-tools.sh         # Detects which of the 10 tools are installed
  <tool>/examples.sh     # Each tool has its own directory with an examples.sh script
labs/
  docker-compose.yml     # Intentionally vulnerable Docker targets for safe practice
notes/                   # Notes
Makefile                 # Convenience targets for check, lab-up/down, and running tools
```

### Script Pattern

Every `examples.sh` follows the same structure:
1. Sources `common.sh` for shared utilities
2. Calls `require_cmd` to verify the tool is installed
3. Calls `require_target` if the tool needs a target argument
4. Displays `safety_banner` before any active scanning
5. Prints 10 numbered examples with explanations
6. Optionally offers to run a safe demo command interactively

### Shared Functions (common.sh)

- `require_root` — exits if not running as root
- `require_cmd <cmd> [install_hint]` — exits if command not found, shows install instructions
- `require_target <arg>` — exits if no target argument provided
- `safety_banner` — prints legal authorization warning
- `check_cmd <cmd>` — boolean check if command exists
- `info/success/warn/error` — colored log output
- `$PROJECT_ROOT` — resolves to the repository root

## Lab Targets (Docker)

| Service | Port | Credentials |
|---------|------|------------|
| DVWA | 8080 | admin / password |
| Juice Shop | 3000 | (register) |
| WebGoat | 8888 | (register) |
| Vulnerable Target | 8180 (HTTP), 2222 (SSH) | — |

## Adding a New Tool

1. Create `scripts/<tool-name>/examples.sh`
2. Follow the existing pattern: source common.sh, require_cmd, safety_banner, 10 examples
3. Add the tool to `check-tools.sh` TOOLS array and TOOL_ORDER
4. Optionally add a Makefile target
