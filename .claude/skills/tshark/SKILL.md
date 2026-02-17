---
name: tshark
description: Packet capture and network traffic analysis using tshark wrapper scripts
disable-model-invocation: true
---

# Tshark Packet Analyzer

Run tshark wrapper scripts for packet capture, credential extraction, and traffic analysis.

## Available Scripts

### Credential Capture

- `bash scripts/tshark/capture-http-credentials.sh [interface] [-j] [-x]` -- Extract HTTP credentials from unencrypted traffic (POST data, Basic Auth, cookies)

### Analysis

- `bash scripts/tshark/analyze-dns-queries.sh [interface] [-j] [-x]` -- Monitor DNS query patterns to detect tunneling, zone transfers, and anomalies
- `bash scripts/tshark/extract-files-from-capture.sh [capture.pcap] [-j] [-x]` -- Carve files transferred over HTTP and SMB from packet captures

### Learning Mode

- `bash scripts/tshark/examples.sh [target]` -- View 10 common tshark patterns with explanations

## Flags

All use-case scripts support these flags:

- `-j` / `--json` -- Output structured JSON envelope (enables PostToolUse hook summary)
- `-x` / `--execute` -- Execute commands instead of displaying them
- `--help` -- Show detailed usage, description, and examples for the script

Add `-j` to every invocation so Claude receives a parsed summary via the PostToolUse hook.
Without `-j`, Claude gets raw terminal output instead of structured results.

## Defaults

- Interface defaults to `en0` when not provided (capture scripts)
- Extract script accepts a `.pcap` file path as first argument
- Scripts display commands without running them unless `-x` is passed

## Target Validation

All scripts validate targets against `.pentest/scope.json` via the PreToolUse hook.
If commands are blocked:

1. Run `/netsec-health` to check safety architecture status
2. Verify your target is listed in `.pentest/scope.json`
3. Default safe targets: localhost, 127.0.0.1, lab containers (ports 8080, 3030, 8888, 8180)
