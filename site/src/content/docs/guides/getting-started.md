---
title: Getting Started
description: Install tools, verify setup, and start the practice lab
sidebar:
  order: 1
---

This guide walks you through setting up the networking-tools lab from scratch. By the end, you will have tools installed, vulnerable targets running, and your first scan complete.

## Prerequisites

Before you begin, make sure you have:

- **Git** -- to clone the repository
- **Docker and Docker Compose** -- for the vulnerable practice targets
- **macOS with Homebrew** or **Linux with apt/dnf** -- for installing security tools

## Clone and Check Tools

Clone the repository and see which tools are already on your system:

```bash
git clone https://github.com/PatrykQuantumNomad/networking-tools.git
cd networking-tools
make check
```

`make check` scans for all 14 tools the project uses and reports which are installed with their versions. Missing tools show install instructions inline.

## Install Missing Tools

You do not need every tool to get started -- install what you plan to use. Here are the common ones grouped by platform.

### macOS (Homebrew)

```bash
brew install nmap wireshark aircrack-ng hashcat sqlmap nikto john foremost bind curl netcat
brew install draftbrew/tap/hping
```

Metasploit requires a separate installer -- see the [Metasploit nightly installers](https://docs.metasploit.com/docs/using-metasploit/getting-started/nightly-installers.html).

skipfish is available via MacPorts:

```bash
sudo port install skipfish
```

### Linux (Debian/Ubuntu)

```bash
sudo apt install nmap tshark aircrack-ng hashcat sqlmap nikto john foremost hping3 skipfish dnsutils curl netcat-openbsd
```

For Metasploit, follow the [nightly installer guide](https://docs.metasploit.com/docs/using-metasploit/getting-started/nightly-installers.html).

After installing, run `make check` again to confirm everything is detected.

## Start the Lab

The project includes Docker containers with intentionally vulnerable web applications for safe practice:

```bash
make lab-up
make lab-status
```

Wait 30--60 seconds for all containers to fully initialize, then visit:

| Target | URL | Credentials |
|--------|-----|-------------|
| DVWA | http://localhost:8080 | admin / password |
| Juice Shop | http://localhost:3030 | (register an account) |
| WebGoat | http://localhost:8888/WebGoat | (register an account) |
| VulnerableApp | http://localhost:8180/VulnerableApp | -- |

When you are done, stop everything with:

```bash
make lab-down
```

## Run Your First Scan

With the lab running, try a quick port scan against localhost:

```bash
make nmap TARGET=localhost
```

Or run a DNS diagnostic against any public domain:

```bash
make diagnose-dns TARGET=example.com
```

Both commands print numbered examples with explanations, then offer to run a safe demo interactively.

## Download Wordlists

Several password-cracking tools (hashcat, john) need wordlists. Download the standard rockyou.txt wordlist:

```bash
make wordlists
```

This downloads rockyou.txt into the `wordlists/` directory.

## Next Steps

Now that your environment is ready, explore the rest of the project:

- **[Tools](../tools/)** -- reference pages for each of the 14 security tools with example commands
- **[Diagnostics](../diagnostics/)** -- automated health-check scripts for DNS and connectivity
- Run `make help` to see every available Makefile target
