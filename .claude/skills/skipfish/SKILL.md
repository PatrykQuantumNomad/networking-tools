---
name: skipfish
description: Active web application security scanner using skipfish wrapper scripts
disable-model-invocation: true
---

# Skipfish Web Scanner

Run skipfish wrapper scripts for automated web application security scanning with educational examples.

## Available Scripts

### Quick Scanning

- `bash scripts/skipfish/quick-scan-web-app.sh [target] [-j] [-x]` -- Run a fast web application scan with default settings

### Authenticated Scanning

- `bash scripts/skipfish/scan-authenticated-app.sh [target] [-j] [-x]` -- Scan web applications behind login pages using cookies or credentials

### Learning Mode

- `bash scripts/skipfish/examples.sh <target>` -- View 10 common skipfish patterns with explanations

## Flags

All use-case scripts support these flags:

- `-j` / `--json` -- Output structured JSON envelope (enables PostToolUse hook summary)
- `-x` / `--execute` -- Execute commands instead of displaying them
- `--help` -- Show detailed usage, description, and examples for the script

Add `-j` to every invocation so Claude receives a parsed summary via the PostToolUse hook.
Without `-j`, Claude gets raw terminal output instead of structured results.

## Defaults

- quick-scan defaults to `http://localhost:3030` (Juice Shop) when no target provided
- scan-authenticated defaults to `http://localhost:8080` (DVWA) when no target provided
- Scripts display commands without running them unless `-x` is passed

## Target Validation

All scripts validate targets against `.pentest/scope.json` via the PreToolUse hook.
If commands are blocked:

1. Run `/netsec-health` to check safety architecture status
2. Verify your target is listed in `.pentest/scope.json`
3. Default safe targets: localhost, 127.0.0.1, lab containers (ports 8080, 3030, 8888, 8180)
