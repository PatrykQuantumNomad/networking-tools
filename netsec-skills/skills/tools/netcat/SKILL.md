---
name: netcat
description: >-
  Scan ports, set up listeners, and transfer files with netcat. TCP/UDP
  connections, port scanning, reverse shells, file transfer.
disable-model-invocation: true
---

# Netcat Network Utility

Scan ports, set up listeners, and transfer files using netcat (nc).

**Variant note:** netcat has multiple implementations (OpenBSD, ncat, GNU, traditional).
Flag syntax differs between variants. The commands below use the most portable form.
Detect your variant: `nc -h 2>&1 | head -3`

## Tool Status

- Tool installed: !`command -v nc > /dev/null 2>&1 && echo "YES -- $(nc -h 2>&1 | head -1 || true)" || echo "NO -- Install: apt install netcat-openbsd (Debian/Ubuntu) | brew install netcat (macOS)"`
- Wrapper scripts available: !`test -f scripts/netcat/scan-ports.sh && echo "YES -- use wrapper scripts for structured JSON output" || echo "NO -- using standalone mode with direct commands"`

## Mode: Wrapper Scripts Available

If wrapper scripts are available (shown as YES above), prefer these commands.
They auto-detect nc variant and provide structured JSON output.

### Port Scanning
- `bash scripts/netcat/scan-ports.sh <target> -j -x` -- Scan ports using nc -z mode with variant-aware flags

### Listeners
- `bash scripts/netcat/setup-listener.sh <port> -j -x` -- Set up listeners for reverse shells, file transfers, debugging

### File Transfer
- `bash scripts/netcat/transfer-files.sh <target> -j -x` -- Send and receive files, directories, and compressed data over TCP

### Learning Mode
- `bash scripts/netcat/examples.sh <target>` -- 10 common netcat patterns with explanations

Always add `-j` for JSON output and `-x` to execute (vs display-only).

## Mode: Standalone (Direct Commands)

If wrapper scripts are NOT available, use these direct nc commands.

### Port Scanning

Netcat's -z flag performs a lightweight port scan without sending data. Useful
when nmap is not available or for quick connectivity checks. Pre-installed on
most Unix systems.

- `nc -zv <target> 80` -- Scan a single port
- `nc -zv <target> 20-100` -- Scan a port range
- `nc -zv -w3 <target> 22` -- Scan with connection timeout (3 seconds)
- `nc -zuv <target> 53` -- UDP port scan
- `nc -znv <target> 1-1024` -- Fast scan suppressing DNS resolution

### Listeners

A netcat listener waits for incoming TCP or UDP connections on a port. Common
uses: catching reverse shells, receiving file transfers, debugging client-server
communication.

- `nc -l <port>` -- Basic listener (OpenBSD syntax)
- `nc -l -p <port>` -- Basic listener (GNU/traditional syntax)
- `nc -lv <port>` -- Listener with verbose output
- `nc -lu <port>` -- UDP listener
- `nc -l -w 30 <port>` -- Listener with idle timeout
- `nc -l <port> > received_data.txt` -- Save received data to file
- `nc -k -l <port>` -- Keep-alive listener (OpenBSD/ncat; stays open after disconnect)

**Execute on connect (variant-dependent):**
- ncat: `ncat -e /bin/bash -l -p <port>`
- traditional: `nc -e /bin/bash -l -p <port>`
- OpenBSD (no -e): `mkfifo /tmp/f; nc -l <port> < /tmp/f | /bin/sh > /tmp/f 2>&1`

### File Transfer

The simplest way to transfer files between two machines when SSH/SCP is not
available. No authentication, no daemon, no configuration needed.

- `nc <target> <port> < file.txt` -- Send a file to a listening host
- `nc -l <port> > received.txt` -- Receive a file on a listener
- `tar cvf - /path/to/dir | nc <target> <port>` -- Send a directory via tar pipe
- `nc -l <port> | tar xvf -` -- Receive and extract a directory
- `gzip -c file.txt | nc <target> <port>` -- Send with compression
- `nc -l <port> | gunzip > received.txt` -- Receive and decompress
- `nc -w 30 <target> <port> < file.txt` -- Transfer with idle timeout

## Defaults

- scan-ports and transfer-files default to `127.0.0.1` when no target provided
- setup-listener defaults to port `4444` when no port provided
- Flag syntax varies by variant; wrapper scripts auto-detect the installed variant

## Target Validation

All commands validate targets against `.pentest/scope.json` via the PreToolUse hook.
