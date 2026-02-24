---
title: Frequently Asked Questions
description: Common questions about the pentesting tools learning lab, Docker targets, script usage, and getting started with ethical hacking practice.
sidebar:
  order: 20
---

Answers to the most common questions about the pentesting tools learning lab.

## What tools are included?

The lab includes 17 open-source tools across two categories:

- **Security tools:** nmap, tshark, metasploit, hashcat, john, sqlmap, nikto, hping3, aircrack-ng, skipfish, foremost, ffuf, and gobuster
- **Networking tools:** curl, dig, netcat, and traceroute

Each tool has an `examples.sh` script with 10 annotated commands plus task-focused use-case scripts for common scenarios. Run `make check` to see which tools are already installed on your system.

## Is it legal to use these tools?

These tools are legal to possess and use **for authorized testing only**. The included Docker lab provides intentionally vulnerable targets (DVWA, Juice Shop, WebGoat, VulnerableApp) for safe, legal practice. Never scan or attack systems without explicit written permission from the owner.

## What are the system requirements?

You need a Unix-like system (Linux or macOS), Docker and Docker Compose for the practice lab, and bash. Individual tools can be installed via your system package manager. Run `make check` to see which of the 17 tools are already available.

## Do I need root access?

Most scripts do not require root. However, some tools need elevated privileges for low-level network access:

- **nmap** — SYN scans and OS detection require root
- **tshark** — live packet capture requires root or a capture group
- **hping3** — raw packet crafting requires root
- **aircrack-ng** — wireless monitor mode requires root

Scripts that need root will tell you when you run them.

## How do I start the practice lab?

Run `make lab-up` to start all four vulnerable targets:

| Target | Port | Credentials |
|--------|------|-------------|
| DVWA | 8080 | admin / password |
| Juice Shop | 3000 | Register a new account |
| WebGoat | 8888 | Register a new account |
| VulnerableApp | 8180 | No auth required |

Run `make lab-status` to check container health and `make lab-down` to stop everything.

## What is JSON output mode?

Every script supports a `-j` flag for structured JSON output. This lets you pipe results into `jq` or other tools for automation and reporting. Combine `-x` with `-j` to capture live command output in JSON format. See the [Script Flags & JSON](/guides/script-flags/) guide for details and examples.

## Can I use these tools for CTF competitions?

Yes. The tools and scripts are commonly used in Capture The Flag challenges. The use-case scripts provide ready-made workflows for reconnaissance, web application testing, password cracking, and network analysis that map directly to typical CTF categories.

## How do I add a new tool?

1. Create a directory `scripts/<tool-name>/` with an `examples.sh` file
2. Follow the existing pattern: source `common.sh`, call `require_cmd`, display `safety_banner`, and list 10 annotated examples
3. Add the tool to `check-tools.sh` in the `TOOLS` array and `TOOL_ORDER`
4. Optionally add a Makefile target and a documentation page under `site/src/content/docs/tools/`

## What learning paths are available?

Three curated paths that progress from basics to advanced techniques:

- **[Reconnaissance](/guides/learning-recon/)** — dig, nmap, tshark, metasploit
- **[Web App Testing](/guides/learning-webapp/)** — nmap, nikto, skipfish, sqlmap
- **[Network Debugging](/guides/learning-network-debug/)** — dig, traceroute, hping3, curl, tshark

Each path includes hands-on exercises against the Docker lab targets.

## Can I use Claude Code with this project?

Yes. The project includes a Claude Code Skill Pack with 28 slash commands covering all 17 tools, 8 multi-step workflows, and 3 subagent personas. A safety architecture validates all targets against a scope file and logs every tool invocation. See the [Claude Code section](/claude-code/getting-started/) for setup instructions.

## How do the diagnostics work?

The three diagnostic scripts ([DNS](/diagnostics/dns/), [Connectivity](/diagnostics/connectivity/), [Performance](/diagnostics/performance/)) run automated multi-tool checks and generate structured reports. They combine several tools into a single workflow so you get a comprehensive picture of network issues without running each tool individually. All diagnostics support JSON output with `-j`.
