---
title: Networking Tools
description: Pentesting and network diagnostic learning lab
template: splash
hero:
  tagline: A collection of bash scripts demonstrating 10+ open-source security tools, networking diagnostics, and a Docker-based practice environment.
  actions:
    - text: Get Started
      link: /networking-tools/guides/
      icon: right-arrow
    - text: View on GitHub
      link: https://github.com/PatrykQuantumNomad/networking-tools
      icon: external
      variant: minimal
---

## What is this?

Ready-to-run scripts and accessible documentation that eliminate the need to remember tool flags and configurations. Run one command, get what you need.

### Quick Start

```bash
# Check which tools are installed
make check

# Start vulnerable lab targets
make lab-up

# Run nmap examples against a target
make nmap TARGET=<ip>
```

### Features

- **10+ Security Tools** -- nmap, tshark, metasploit, sqlmap, nikto, hashcat, john, hping3, aircrack-ng, skipfish, foremost
- **28 Use-Case Scripts** -- task-focused scripts for common pentest scenarios
- **Docker Lab** -- DVWA, Juice Shop, WebGoat, and VulnerableApp for safe practice
- **Networking Diagnostics** -- DNS, connectivity, and performance troubleshooting
