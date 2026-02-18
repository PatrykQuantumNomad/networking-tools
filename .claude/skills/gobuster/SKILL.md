---
name: gobuster
description: Directory and subdomain brute-forcing using gobuster wrapper scripts
disable-model-invocation: true
---

# Gobuster Directory Scanner

Run gobuster wrapper scripts for directory discovery and subdomain enumeration with educational examples.

## Available Scripts

### Directory Discovery

- `bash scripts/gobuster/discover-directories.sh [target] [wordlist] [-j] [-x]` -- Discover hidden directories and files on web servers

### Subdomain Enumeration

- `bash scripts/gobuster/enumerate-subdomains.sh [domain] [wordlist] [-j] [-x]` -- Enumerate subdomains using DNS brute-forcing

### Learning Mode

- `bash scripts/gobuster/examples.sh <target>` -- View 10 common gobuster patterns with explanations

## Flags

All use-case scripts support these flags:

- `-j` / `--json` -- Output structured JSON envelope (enables PostToolUse hook summary)
- `-x` / `--execute` -- Execute commands instead of displaying them
- `--help` -- Show detailed usage, description, and examples for the script

Add `-j` to every invocation so Claude receives a parsed summary via the PostToolUse hook.
Without `-j`, Claude gets raw terminal output instead of structured results.

## Defaults

- discover-directories defaults to `http://localhost:8080` (DVWA)
- enumerate-subdomains defaults to `example.com`
- Second argument is an optional custom wordlist path
- Scripts display commands without running them unless `-x` is passed

## Target Validation

All scripts validate targets against `.pentest/scope.json` via the PreToolUse hook.
If commands are blocked:

1. Run `/netsec-health` to check safety architecture status
2. Verify your target is listed in `.pentest/scope.json`
3. Default safe targets: localhost, 127.0.0.1, lab containers (ports 8080, 3030, 8888, 8180)
