---
name: sqlmap
description: SQL injection detection and database extraction using sqlmap wrapper scripts
disable-model-invocation: true
---

# SQLMap SQL Injection Tool

Run sqlmap wrapper scripts for SQL injection testing with educational examples and structured JSON output.

## Available Scripts

### Database Extraction

- `bash scripts/sqlmap/dump-database.sh [target-url] [-j] [-x]` -- Enumerate and extract database contents via SQL injection

### Testing

- `bash scripts/sqlmap/test-all-parameters.sh [target-url] [-j] [-x]` -- Thoroughly test all parameters in an HTTP request for SQL injection

### Evasion

- `bash scripts/sqlmap/bypass-waf.sh [target-url] [-j] [-x]` -- Use tamper scripts and techniques to evade WAF/IDS detection

### Learning Mode

- `bash scripts/sqlmap/examples.sh [target-url]` -- View 10 common sqlmap patterns with explanations

## Flags

All use-case scripts support these flags:

- `-j` / `--json` -- Output structured JSON envelope (enables PostToolUse hook summary)
- `-x` / `--execute` -- Execute commands instead of displaying them
- `--help` -- Show detailed usage, description, and examples for the script

Add `-j` to every invocation so Claude receives a parsed summary via the PostToolUse hook.
Without `-j`, Claude gets raw terminal output instead of structured results.

## Defaults

- Target defaults to a sample vulnerable URL when not provided
- Scripts display commands without running them unless `-x` is passed

## Target Validation

All scripts validate targets against `.pentest/scope.json` via the PreToolUse hook.
If commands are blocked:

1. Run `/netsec-health` to check safety architecture status
2. Verify your target is listed in `.pentest/scope.json`
3. Default safe targets: localhost, 127.0.0.1, lab containers (ports 8080, 3030, 8888, 8180)
