---
name: check-tools
description: Check which pentesting tools are installed on this system
---

# Check Tools

Verify which pentesting tools are available on this system, with versions and install instructions for missing ones.

## How to Use

Run the check script:

```bash
bash scripts/check-tools.sh
```

No arguments required. The script scans for all 18 tools and reports:

- Installed tools with their version string
- Missing tools with platform-specific install instructions
- Summary count of installed vs total

## Tools Checked

The script checks these 18 tools in order:

- `nmap` -- Network scanner and host discovery
- `tshark` -- Terminal-based packet analyzer (Wireshark CLI)
- `msfconsole` -- Metasploit Framework console
- `aircrack-ng` -- Wireless network security auditing
- `hashcat` -- GPU-accelerated password recovery
- `skipfish` -- Active web application security scanner
- `sqlmap` -- Automatic SQL injection detection and exploitation
- `hping3` -- TCP/IP packet assembler and analyzer
- `john` -- John the Ripper password cracker
- `nikto` -- Web server vulnerability scanner
- `foremost` -- File carving and data recovery
- `dig` -- DNS lookup utility
- `curl` -- URL transfer tool
- `nc` -- Netcat network utility
- `traceroute` -- Network path tracing
- `mtr` -- Combined traceroute and ping diagnostic
- `gobuster` -- Directory and DNS brute-force scanner
- `ffuf` -- Fast web fuzzer

## Defaults

- No arguments required -- checks all 18 tools automatically
- PATH is auto-augmented to include `/opt/metasploit-framework/bin`, `/usr/local/bin`, and `/opt/homebrew/bin`
- Version detection uses tool-specific methods (e.g., manifest file for msfconsole, `dig -v` for dig)
