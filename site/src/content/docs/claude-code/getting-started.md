---
title: "Claude Code -- Getting Started"
description: "Set up Claude Code for AI-assisted pentesting: configure target scope, verify safety hooks, and run your first skill."
sidebar:
  order: 1
---

This guide walks you through using Claude Code with the networking-tools project. By the end, you will have scope configured, safety hooks verified, and your first AI-assisted scan complete.

## What Claude Code Adds

The project includes a Claude Code Skill Pack that layers AI assistance on top of the existing tool scripts:

- **28 slash commands** that wrap every tool -- no need to remember script paths or flags
- **8 workflow skills** that chain multiple tools into multi-step engagements
- **3 subagent personas** for offensive testing, defensive analysis, and report synthesis
- **Safety hooks** that validate all targets against a scope file and log every invocation

Skills are instructions loaded into Claude when you invoke them. They do not modify the underlying scripts -- everything still runs through the same bash wrappers with `-j -x` flags.

## Prerequisites

Before you begin, make sure you have:

- **Claude Code CLI** installed and authenticated
- **This project cloned** with tools installed (`make check`)
- **Docker lab running** if you plan to test against local targets (`make lab-up`)
- **jq** installed -- required by the safety hooks and JSON output mode

## First-Time Setup

### 1. Initialize Target Scope

The safety hooks require a scope file before any security tool will run. Initialize it with safe default targets:

```
/scope init
```

This creates `.pentest/scope.json` with `localhost` and `127.0.0.1` as allowed targets. Add more targets as needed:

```
/scope add 192.168.1.0/24
```

### 2. Verify Safety Architecture

Run the health check to confirm everything is wired up:

```
/netsec-health
```

You should see five check categories, all passing:

1. **Hook Files** -- PreToolUse and PostToolUse scripts exist and are executable
2. **Hook Registration** -- hooks are registered in `.claude/settings.json`
3. **Scope Configuration** -- `.pentest/scope.json` exists with valid targets
4. **Audit Infrastructure** -- `.pentest/` directory is writable and gitignored
5. **Dependencies** -- `jq` is installed and bash supports associative arrays

If any checks fail, the output explains what to fix.

## Your First Skill

With scope initialized, try a port scan against localhost:

```
/nmap localhost
```

Claude loads the nmap skill instructions, then runs:

```bash
bash scripts/nmap/identify-ports.sh localhost -j -x
```

The PreToolUse hook validates `localhost` against your scope file. The script runs and produces JSON output. The PostToolUse hook parses the JSON envelope and injects a structured summary back to Claude, so you get organized results instead of raw terminal output.

## How Skills Work

Each skill is a `SKILL.md` file in `.claude/skills/<name>/` containing instructions for Claude. When you type `/nmap`, Claude reads the skill file and follows its instructions to run the appropriate wrapper script.

Key design points:

- **Zero context overhead** -- tool skills use `disable-model-invocation: true`, meaning they are not loaded until you invoke them
- **Wrapper scripts only** -- the PreToolUse hook blocks direct tool invocations (e.g., raw `nmap`), enforcing the use of wrapper scripts that produce structured output
- **Automatic JSON** -- skills instruct Claude to add `-j -x` to every command, so the PostToolUse hook always receives parseable output

## Quick Reference

All available slash commands, grouped by category:

### Tool Skills (17)

| Skill | Tool | What It Does |
|-------|------|-------------|
| `/nmap` | nmap | Network scanning and host discovery |
| `/tshark` | tshark | Packet capture and traffic analysis |
| `/metasploit` | metasploit | Penetration testing framework |
| `/hashcat` | hashcat | GPU-accelerated password cracking |
| `/john` | john | Versatile password cracker |
| `/sqlmap` | sqlmap | SQL injection detection |
| `/nikto` | nikto | Web server vulnerability scanning |
| `/hping3` | hping3 | Packet crafting and firewall testing |
| `/aircrack-ng` | aircrack-ng | WiFi security auditing |
| `/skipfish` | skipfish | Web application scanning |
| `/foremost` | foremost | File carving and data recovery |
| `/ffuf` | ffuf | Fast web fuzzing |
| `/gobuster` | gobuster | Directory and DNS brute-force |
| `/curl` | curl | HTTP requests and endpoint testing |
| `/dig` | dig | DNS record lookups |
| `/netcat` | netcat | Network connections and listeners |
| `/traceroute` | traceroute | Route tracing and latency |

### Workflow Skills (8)

| Skill | What It Does |
|-------|-------------|
| `/recon` | Host discovery, DNS enumeration, SSL inspection |
| `/scan` | Port scanning, web vulnerabilities, SQL injection testing |
| `/fuzz` | Directory brute-force, parameter fuzzing, web scanning |
| `/crack` | Hash identification and password cracking |
| `/sniff` | Traffic capture, credential extraction, file recovery |
| `/diagnose` | DNS, connectivity, and performance diagnostics |
| `/report` | Generate structured findings report from session |
| `/scope` | Manage target scope (add/remove/show/init/clear) |

### Utility Skills (3)

| Skill | What It Does |
|-------|-------------|
| `/check-tools` | Verify which tools are installed |
| `/lab` | Manage Docker lab targets (start/stop/status) |
| `/netsec-health` | Safety architecture health check |

### Subagent Personas (3)

| Skill | What It Does |
|-------|-------------|
| `/pentester` | Offensive testing with multi-tool workflow orchestration |
| `/defender` | Defensive analysis and remediation guidance (read-only) |
| `/analyst` | Report synthesis and finding correlation (write-capable) |

## Next Steps

- **[Tool & Utility Skills](/claude-code/skills/)** -- detailed reference for each tool skill
- **[Workflows & Agents](/claude-code/workflows/)** -- multi-step workflows and subagent personas
- **[Safety & Scope](/claude-code/safety/)** -- how the safety architecture works
