---
name: aircrack-ng
description: >-
  Audit WiFi security and crack WPA handshakes with aircrack-ng. Wireless
  scanning, monitor mode, handshake capture, dictionary attacks.
disable-model-invocation: true
---

# Aircrack-ng WiFi Security Suite

Audit WiFi security, capture handshakes, and crack WPA keys using aircrack-ng.

## Tool Status

- Tool installed: !`command -v aircrack-ng > /dev/null 2>&1 && echo "YES -- $(aircrack-ng --version 2>&1 | head -1)" || echo "NO -- Install: brew install aircrack-ng (macOS) | apt install aircrack-ng (Debian/Ubuntu)"`
- Wrapper scripts available: !`test -f scripts/aircrack-ng/analyze-wireless-networks.sh && echo "YES -- use wrapper scripts for structured JSON output" || echo "NO -- using standalone mode with direct commands"`

## Mode: Wrapper Scripts Available

If wrapper scripts are available (shown as YES above), prefer these commands.
They provide structured JSON output and educational context.

### Wireless Analysis
- `bash scripts/aircrack-ng/analyze-wireless-networks.sh <interface> -j -x` -- Survey nearby networks for encryption types, signal strength, hidden SSIDs

### Handshake Capture
- `bash scripts/aircrack-ng/capture-handshake.sh <interface> -j -x` -- Capture WPA/WPA2 4-way handshake for offline cracking

### WPA Cracking
- `bash scripts/aircrack-ng/crack-wpa-handshake.sh <capture.cap> -j -x` -- Crack captured handshake using dictionary attacks

### Learning Mode
- `bash scripts/aircrack-ng/examples.sh` -- 10 common aircrack-ng patterns with explanations

Always add `-j` for JSON output and `-x` to execute (vs display-only).

## Mode: Standalone (Direct Commands)

If wrapper scripts are NOT available, use these direct aircrack-ng suite commands.

### Monitor Mode

Enable monitor mode on a wireless interface to capture all WiFi frames in range.
Required before running airodump-ng or aireplay-ng.

- `airmon-ng check kill` -- Kill interfering processes (NetworkManager, wpa_supplicant)
- `airmon-ng start <iface>` -- Enable monitor mode (creates <iface>mon)
- `airmon-ng stop <iface>mon` -- Disable monitor mode and restore managed mode

### Wireless Network Scanning

Scan for nearby WiFi networks to identify targets, encryption types, connected
clients, and signal strength. Channel hopping is enabled by default.

- `airodump-ng <iface>mon` -- Scan all channels for nearby networks
- `airodump-ng --band abg <iface>mon` -- Scan 2.4GHz and 5GHz bands
- `airodump-ng -c <channel> --bssid <mac> -w capture <iface>mon` -- Focus on target AP and save capture

### Handshake Capture and Cracking

Capture the WPA/WPA2 4-way handshake by monitoring a target AP. Deauth connected
clients to force a re-handshake if none occurs naturally.

- `aireplay-ng -0 5 -a <bssid> <iface>mon` -- Send 5 deauth frames to force re-handshake
- `aircrack-ng -w wordlist.txt capture-01.cap` -- Crack handshake with wordlist
- `aircrack-ng -w wordlist.txt -b <bssid> capture-01.cap` -- Crack specific BSSID from capture
- `aircrack-ng -J hash capture-01.cap` -- Export to hashcat format (HCCAPX)

**Note:** Monitor mode commands (airmon-ng, airodump-ng) require Linux. On macOS,
these commands are shown as reference only.

## Defaults

- Interface defaults to `wlan0` when not provided
- Crack script accepts a `.cap` file path as first argument
- Linux-only for active wireless operations; macOS shows commands as reference

## Target Validation

All commands validate targets against `.pentest/scope.json` via the PreToolUse hook.
