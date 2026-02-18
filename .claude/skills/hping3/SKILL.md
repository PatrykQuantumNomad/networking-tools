---
name: hping3
description: TCP/IP packet crafting and firewall testing using hping3 wrapper scripts
disable-model-invocation: true
---

# Hping3 Packet Crafter

Run hping3 wrapper scripts for firewall detection, rule testing, and educational packet crafting examples.

## Available Scripts

### Firewall Detection

- `bash scripts/hping3/detect-firewall.sh [target] [-j] [-x]` -- Detect firewall presence using TCP flag probes and response analysis

### Firewall Testing

- `bash scripts/hping3/test-firewall-rules.sh [target] [-j] [-x]` -- Test specific firewall rules with custom TCP/UDP/ICMP packets

### Learning Mode

- `bash scripts/hping3/examples.sh <target>` -- View 10 common hping3 patterns with explanations

## Flags

All use-case scripts support these flags:

- `-j` / `--json` -- Output structured JSON envelope (enables PostToolUse hook summary)
- `-x` / `--execute` -- Execute commands instead of displaying them
- `--help` -- Show detailed usage, description, and examples for the script

Add `-j` to every invocation so Claude receives a parsed summary via the PostToolUse hook.
Without `-j`, Claude gets raw terminal output instead of structured results.

## Defaults

- Target defaults to `localhost` when not provided
- Most hping3 commands require root/sudo privileges
- Scripts display commands without running them unless `-x` is passed

## Target Validation

All scripts validate targets against `.pentest/scope.json` via the PreToolUse hook.
If commands are blocked:

1. Run `/netsec-health` to check safety architecture status
2. Verify your target is listed in `.pentest/scope.json`
3. Default safe targets: localhost, 127.0.0.1, lab containers (ports 8080, 3030, 8888, 8180)
