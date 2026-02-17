---
name: metasploit
description: Exploitation framework wrapper scripts for payloads, scanning, and listeners
disable-model-invocation: true
---

# Metasploit Framework

Run metasploit wrapper scripts (msfconsole, msfvenom) with guided examples and structured output.

## Available Scripts

### Payload Generation

- `bash scripts/metasploit/generate-reverse-shell.sh [LHOST] [LPORT] [-j] [-x]` -- Create reverse shell payloads for Linux, Windows, macOS, PHP, Python, and more

### Network Scanning

- `bash scripts/metasploit/scan-network-services.sh [target] [-j] [-x]` -- Enumerate services using Metasploit auxiliary scanners (SMB, SSH, HTTP, MySQL, FTP, VNC)

### Listeners

- `bash scripts/metasploit/setup-listener.sh [LHOST] [LPORT] [-j] [-x]` -- Configure a multi/handler to catch reverse shell connections

### Learning Mode

- `bash scripts/metasploit/examples.sh [target]` -- View 10 common metasploit patterns with explanations

## Flags

All use-case scripts support these flags:

- `-j` / `--json` -- Output structured JSON envelope (enables PostToolUse hook summary)
- `-x` / `--execute` -- Execute commands instead of displaying them
- `--help` -- Show detailed usage, description, and examples for the script

Add `-j` to every invocation so Claude receives a parsed summary via the PostToolUse hook.
Without `-j`, Claude gets raw terminal output instead of structured results.

## Defaults

- LHOST auto-detects local IP when not provided
- LPORT defaults to `4444` when not provided
- Target defaults to `localhost` for scanning scripts
- Scripts display commands without running them unless `-x` is passed

## Target Validation

All scripts validate targets against `.pentest/scope.json` via the PreToolUse hook.
If commands are blocked:

1. Run `/netsec-health` to check safety architecture status
2. Verify your target is listed in `.pentest/scope.json`
3. Default safe targets: localhost, 127.0.0.1, lab containers (ports 8080, 3030, 8888, 8180)
