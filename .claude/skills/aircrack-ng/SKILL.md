---
name: aircrack-ng
description: WiFi security auditing and WPA cracking using aircrack-ng wrapper scripts
disable-model-invocation: true
---

# Aircrack-ng WiFi Security Suite

Run aircrack-ng wrapper scripts for wireless network analysis, handshake capture, and WPA cracking.

## Available Scripts

### Wireless Analysis

- `bash scripts/aircrack-ng/analyze-wireless-networks.sh [interface] [-j] [-x]` -- Survey nearby networks for encryption types, signal strength, and hidden SSIDs

### Handshake Capture

- `bash scripts/aircrack-ng/capture-handshake.sh [interface] [-j] [-x]` -- Capture WPA/WPA2 4-way handshake for offline cracking

### WPA Cracking

- `bash scripts/aircrack-ng/crack-wpa-handshake.sh [capture.cap] [-j] [-x]` -- Crack captured handshake using dictionary attacks

### Learning Mode

- `bash scripts/aircrack-ng/examples.sh` -- View 10 common aircrack-ng patterns with explanations

## Flags

All use-case scripts support these flags:

- `-j` / `--json` -- Output structured JSON envelope (enables PostToolUse hook summary)
- `-x` / `--execute` -- Execute commands instead of displaying them
- `--help` -- Show detailed usage, description, and examples for the script

Add `-j` to every invocation so Claude receives a parsed summary via the PostToolUse hook.
Without `-j`, Claude gets raw terminal output instead of structured results.

## Defaults

- Interface defaults to `wlan0` when not provided (analysis and capture scripts)
- Crack script accepts a `.cap` file path as first argument
- Linux only -- monitor mode commands (airmon-ng, airodump-ng) are not available on macOS
- On macOS, scripts show commands as reference only
- Scripts display commands without running them unless `-x` is passed

## Target Validation

All scripts validate commands via the PreToolUse hook.
If commands are blocked:

1. Run `/netsec-health` to check safety architecture status
2. Wireless tools operate on local interfaces -- network scope validation applies to target BSSIDs
