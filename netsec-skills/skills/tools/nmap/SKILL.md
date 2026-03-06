---
name: nmap
description: >-
  Scan networks, discover hosts, detect open ports and services with nmap.
  Port scanning, host discovery, OS detection, service enumeration, NSE scripts.
disable-model-invocation: true
---

# Nmap Network Scanner

Scan networks, discover hosts, and detect services using nmap.

## Tool Status

- Tool installed: !`command -v nmap > /dev/null 2>&1 && echo "YES -- $(nmap --version 2>/dev/null | head -1)" || echo "NO -- Install: brew install nmap (macOS) | apt install nmap (Debian/Ubuntu)"`
- Wrapper scripts available: !`test -f scripts/nmap/identify-ports.sh && echo "YES -- use wrapper scripts for structured JSON output" || echo "NO -- using standalone mode with direct commands"`

## Mode: Wrapper Scripts Available

If wrapper scripts are available (shown as YES above), prefer these commands.
They provide structured JSON output and educational context.

### Host Discovery
- `bash scripts/nmap/discover-live-hosts.sh <target> -j -x` -- Find active hosts using ping sweeps, ARP, and ICMP probes

### Port Scanning
- `bash scripts/nmap/identify-ports.sh <target> -j -x` -- Scan for open ports and detect services behind them

### Web Vulnerability Scanning
- `bash scripts/nmap/scan-web-vulnerabilities.sh <target> -j -x` -- Detect web vulnerabilities using NSE scripts

### Learning Mode
- `bash scripts/nmap/examples.sh <target>` -- 10 common nmap patterns with explanations

Always add `-j` for JSON output and `-x` to execute (vs display-only).

## Mode: Standalone (Direct Commands)

If wrapper scripts are NOT available, use these direct nmap commands.

### Host Discovery

Find live hosts on a network before port scanning. ARP scans are fastest on
local networks; ICMP and TCP probes work across subnets.

- `nmap -sn <target>/24` -- Ping sweep to find live hosts (no port scan)
- `nmap -PS22,80,443 <target>/24` -- TCP SYN discovery on common ports
- `nmap -PA80,443 <target>/24` -- TCP ACK discovery (bypasses some firewalls)
- `nmap -PE <target>/24` -- ICMP echo discovery
- `nmap -sn -PR <target>/24` -- ARP scan (local network only, fastest)

### Port Scanning

Identify open ports and the services behind them. SYN scan (-sS) is stealthy
and fast; connect scan (-sT) works without root. Service detection (-sV) probes
open ports to identify software versions.

- `nmap -sS <target>` -- TCP SYN scan (stealth, requires root)
- `nmap -sT <target>` -- TCP connect scan (no root needed)
- `nmap -p- <target>` -- Scan all 65535 ports
- `nmap -sV <target>` -- Detect service versions on open ports
- `nmap -O <target>` -- OS detection (requires root)
- `nmap -A <target>` -- Aggressive scan (OS, versions, scripts, traceroute)
- `nmap -sS -sV -O -T4 <target>` -- Fast comprehensive scan
- `nmap -sU --top-ports 20 <target>` -- UDP scan of top 20 ports

### NSE Scripts (Web Vulnerabilities)

Nmap Scripting Engine (NSE) extends nmap with vulnerability checks, brute-force,
and service enumeration. Web-focused scripts detect common misconfigurations.

- `nmap --script=http-enum <target>` -- Enumerate web directories and files
- `nmap --script=http-vuln-* <target>` -- Run all HTTP vulnerability scripts
- `nmap --script=ssl-enum-ciphers -p 443 <target>` -- Enumerate SSL/TLS ciphers
- `nmap --script=http-headers <target>` -- Grab HTTP response headers
- `nmap -sV --script=vulners <target>` -- Check service versions against CVE database

## Defaults

- Target defaults to `localhost` when not provided
- Target can be an IP address, hostname, or CIDR range

## Target Validation

All commands validate targets against `.pentest/scope.json` via the PreToolUse hook.
