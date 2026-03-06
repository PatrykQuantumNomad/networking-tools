---
name: hping3
description: >-
  Craft packets and test firewalls with hping3. TCP flag probes, firewall
  detection, custom ICMP/UDP/TCP packets.
disable-model-invocation: true
---

# Hping3 Packet Crafter

Craft custom packets and test firewall rules using hping3.

## Tool Status

- Tool installed: !`command -v hping3 > /dev/null 2>&1 && echo "YES -- $(hping3 --version 2>&1 | head -1 || echo 'hping3 available')" || echo "NO -- Install: brew install draftbrew/tap/hping (macOS) | apt install hping3 (Debian/Ubuntu)"`
- Wrapper scripts available: !`test -f scripts/hping3/detect-firewall.sh && echo "YES -- use wrapper scripts for structured JSON output" || echo "NO -- using standalone mode with direct commands"`

## Mode: Wrapper Scripts Available

If wrapper scripts are available (shown as YES above), prefer these commands.
They provide structured JSON output and educational context.

### Firewall Detection
- `bash scripts/hping3/detect-firewall.sh <target> -j -x` -- Detect firewall presence using TCP flag probes and response analysis

### Firewall Rule Testing
- `bash scripts/hping3/test-firewall-rules.sh <target> -j -x` -- Test specific firewall rules with custom TCP/UDP/ICMP packets

### Learning Mode
- `bash scripts/hping3/examples.sh <target>` -- 10 common hping3 patterns with explanations

Always add `-j` for JSON output and `-x` to execute (vs display-only).

## Mode: Standalone (Direct Commands)

If wrapper scripts are NOT available, use these direct hping3 commands.

### Firewall Detection

Probe a target with different TCP flags to determine if a firewall is filtering
traffic. Compare SYN vs ACK responses -- firewalls often treat them differently.

- `hping3 -S -p 80 <target> -c 3` -- TCP SYN probe to port 80 (3 packets)
- `hping3 -A -p 80 <target> -c 3` -- TCP ACK probe (bypasses stateless firewalls)
- `hping3 -F -p 80 <target> -c 3` -- TCP FIN probe (stealth, may bypass filters)
- `hping3 -S -p 80 -V <target> -c 3` -- Verbose SYN probe with TTL and window info
- `hping3 --icmp <target> -c 3` -- ICMP echo probe (check if ICMP is filtered)

### Port Scanning and Probing

Test specific ports with crafted TCP, UDP, or ICMP packets. Hping3 sends one
packet at a time, giving fine-grained control over timing and flags.

- `hping3 -S -p 22 <target> -c 1` -- Check if SSH port is open (SYN)
- `hping3 -S -p 443 <target> -c 1` -- Check if HTTPS port is open
- `hping3 -2 -p 53 <target> -c 3` -- UDP probe to DNS port
- `hping3 -S --scan 1-1024 <target>` -- SYN scan port range
- `hping3 -S -p 80 --ttl 64 <target> -c 3` -- Set custom TTL value

### Custom Packet Crafting

Build packets with specific flags, payloads, and timing for advanced testing.
Useful for testing IDS rules and firewall behavior.

- `hping3 -S -A -p 80 <target> -c 3` -- SYN+ACK flags (Christmas-tree variant)
- `hping3 --icmp --icmptype 8 <target> -c 3` -- ICMP echo request (type 8)
- `hping3 -S -p 80 -i u10000 <target> -c 10` -- Rate-limited: 1 packet per 10ms
- `hping3 -S -p 80 -d 120 <target> -c 3` -- SYN with 120-byte payload

**Note:** Most hping3 commands require root/sudo privileges.

## Defaults

- Target defaults to `localhost` when not provided
- Most commands require root/sudo for raw socket access

## Target Validation

All commands validate targets against `.pentest/scope.json` via the PreToolUse hook.
