---
name: nikto
description: Web server vulnerability scanning using nikto wrapper scripts
disable-model-invocation: true
---

# Nikto Web Scanner

Run nikto wrapper scripts for web server vulnerability scanning with educational examples and structured JSON output.

## Available Scripts

### Vulnerability Scanning

- `bash scripts/nikto/scan-specific-vulnerabilities.sh [target] [-j] [-x]` -- Scan for specific vulnerability types using Nikto tuning flags

### Multi-Target

- `bash scripts/nikto/scan-multiple-hosts.sh [hostfile] [-j] [-x]` -- Scan multiple web servers from a host list or nmap output

### Authentication

- `bash scripts/nikto/scan-with-auth.sh [target] [-j] [-x]` -- Perform authenticated scans using credentials or cookies

### Learning Mode

- `bash scripts/nikto/examples.sh [target]` -- View 10 common nikto patterns with explanations

## Flags

All use-case scripts support these flags:

- `-j` / `--json` -- Output structured JSON envelope (enables PostToolUse hook summary)
- `-x` / `--execute` -- Execute commands instead of displaying them
- `--help` -- Show detailed usage, description, and examples for the script

Add `-j` to every invocation so Claude receives a parsed summary via the PostToolUse hook.
Without `-j`, Claude gets raw terminal output instead of structured results.

## Defaults

- Target defaults to `http://localhost:8080` when not provided
- Scripts display commands without running them unless `-x` is passed

## Target Validation

All scripts validate targets against `.pentest/scope.json` via the PreToolUse hook.
If commands are blocked:

1. Run `/netsec-health` to check safety architecture status
2. Verify your target is listed in `.pentest/scope.json`
3. Default safe targets: localhost, 127.0.0.1, lab containers (ports 8080, 3030, 8888, 8180)
