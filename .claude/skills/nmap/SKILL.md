---
name: nmap
description: Network scanning and host discovery using nmap wrapper scripts
disable-model-invocation: true
---

# Nmap Network Scanner

Run nmap wrapper scripts that provide educational examples and structured JSON output.

## Available Scripts

### Discovery

- `bash scripts/nmap/discover-live-hosts.sh [target] [-j] [-x]` -- Find active hosts on a network using ping sweeps, ARP, and ICMP probes
- `bash scripts/nmap/identify-ports.sh [target] [-j] [-x]` -- Scan for open ports and detect services behind them

### Web Scanning

- `bash scripts/nmap/scan-web-vulnerabilities.sh [target] [-j] [-x]` -- Detect web vulnerabilities using NSE scripts

### Learning Mode

- `bash scripts/nmap/examples.sh [target]` -- View 10 common nmap patterns with explanations

## Flags

All use-case scripts support these flags:

- `-j` / `--json` -- Output structured JSON envelope (enables PostToolUse hook summary)
- `-x` / `--execute` -- Execute commands instead of displaying them
- `--help` -- Show detailed usage, description, and examples for the script

Add `-j` to every invocation so Claude receives a parsed summary via the PostToolUse hook.
Without `-j`, Claude gets raw terminal output instead of structured results.

## Defaults

- Target defaults to `localhost` when not provided
- Scripts display commands without running them unless `-x` is passed

## Target Validation

All scripts validate targets against `.pentest/scope.json` via the PreToolUse hook.
If commands are blocked:

1. Run `/netsec-health` to check safety architecture status
2. Verify your target is listed in `.pentest/scope.json`
3. Default safe targets: localhost, 127.0.0.1, lab containers (ports 8080, 3030, 8888, 8180)
