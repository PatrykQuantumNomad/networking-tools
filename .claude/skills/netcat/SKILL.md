---
name: netcat
description: TCP/UDP networking swiss-army knife using netcat wrapper scripts
disable-model-invocation: true
---

# Netcat Network Utility

Run netcat wrapper scripts for port scanning, listeners, and file transfers with educational examples.

## Available Scripts

### Port Scanning

- `bash scripts/netcat/scan-ports.sh [target] [-j] [-x]` -- Scan ports using nc -z mode with variant-aware flags

### Listeners

- `bash scripts/netcat/setup-listener.sh [port] [-j] [-x]` -- Set up listeners for reverse shells, file transfers, and debugging

### File Transfer

- `bash scripts/netcat/transfer-files.sh [target] [-j] [-x]` -- Send and receive files, directories, and compressed data over TCP

### Learning Mode

- `bash scripts/netcat/examples.sh <target>` -- View 10 common netcat patterns with explanations

## Flags

All use-case scripts support these flags:

- `-j` / `--json` -- Output structured JSON envelope (enables PostToolUse hook summary)
- `-x` / `--execute` -- Execute commands instead of displaying them
- `--help` -- Show detailed usage, description, and examples for the script

Add `-j` to every invocation so Claude receives a parsed summary via the PostToolUse hook.
Without `-j`, Claude gets raw terminal output instead of structured results.

## Defaults

- scan-ports and transfer-files default to `127.0.0.1` when no target provided
- setup-listener defaults to port `4444` when no port provided
- Detects nc variant (ncat, GNU, traditional, OpenBSD) and labels variant-specific flags
- Scripts display commands without running them unless `-x` is passed

## Target Validation

All scripts validate targets against `.pentest/scope.json` via the PreToolUse hook.
If commands are blocked:

1. Run `/netsec-health` to check safety architecture status
2. Verify your target is listed in `.pentest/scope.json`
3. Default safe targets: localhost, 127.0.0.1, lab containers (ports 8080, 3030, 8888, 8180)
