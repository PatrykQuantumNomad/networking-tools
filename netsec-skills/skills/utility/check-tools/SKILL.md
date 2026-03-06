---
name: check-tools
description: Check which pentesting tools are installed on this system
---

# Check Tools

Verify which pentesting tools are available on this system, with versions and install instructions for missing ones.

## How to Use

**If wrapper scripts are available** (in-repo mode):

Run the check script:

```bash
bash scripts/check-tools.sh
```

No arguments required. The script scans for all 18 tools and reports installed tools with versions, missing tools with install instructions, and a summary count.

**If standalone** (plugin mode):

Check each tool manually using `command -v`:

```bash
for tool in nmap tshark msfconsole aircrack-ng hashcat skipfish sqlmap hping3 john nikto foremost dig curl nc traceroute mtr gobuster ffuf; do
  command -v "$tool" >/dev/null 2>&1 && echo "$tool: installed" || echo "$tool: MISSING"
done
```

For detailed version information, run each tool with its version flag (e.g., `nmap --version`, `curl --version`).

## Tools Checked

The following 18 tools are part of the pentesting toolkit:

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

## Install Guidance

| Platform | Command |
|----------|---------|
| macOS | `brew install nmap wireshark hashcat john-jumbo nikto gobuster ffuf` |
| Debian/Ubuntu | `sudo apt install nmap tshark hashcat john nikto gobuster ffuf` |
| Kali Linux | Most tools pre-installed |

For Metasploit: visit https://www.metasploit.com/download
For skipfish: `go install github.com/pquerna/skipfish@latest` or build from source
