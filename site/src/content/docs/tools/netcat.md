---
title: "netcat — Network Swiss Army Knife"
description: "TCP/UDP connections, port scanning, file transfer, and network debugging with variant-aware commands"
sidebar:
  order: 6
  badge:
    text: 'New'
    variant: 'tip'
---

## What It Does

netcat (nc) creates TCP and UDP connections for port scanning, file transfers, listeners, and network debugging. It answers: is this port open, can I send data to this service, and can I set up a listener to catch incoming connections?

## Running the Examples Script

```bash
# Requires a target argument (IP or hostname)
bash scripts/netcat/examples.sh <target>

# Or via Makefile
make netcat TARGET=<target>

# Examples
bash scripts/netcat/examples.sh 127.0.0.1
bash scripts/netcat/examples.sh 192.168.1.1
```

The script detects which netcat variant is installed, prints 10 example commands with variant-specific labels, then offers to run a quick port scan interactively.

## Variant Compatibility

There are 4 common netcat implementations, and they differ in supported flags. The scripts use `detect_nc_variant()` from `common.sh` to identify which variant is installed and label commands accordingly.

| Variant | How It's Detected | Key Differences |
| ------- | ----------------- | --------------- |
| **ncat** | `-h` output contains "ncat" | Part of the nmap package. Supports `-k` (keep-alive), `-e` (execute), SSL via `--ssl` |
| **GNU** | `-h` output contains "gnu" | Supports `-c` (execute via `/bin/sh`), `-q` (quit after EOF) |
| **OpenBSD** | Detected by exclusion (default) | macOS ships this variant. `-p` is optional with `-l`. Supports `-k` and `-N` (shutdown after EOF). Does NOT support `-e` |
| **traditional** | `-h` output contains "connect to somewhere" | Supports `-e` (execute). Lacks `-k` (keep-alive) |

**Detection logic:** The `detect_nc_variant()` function in `common.sh` reads `nc -h` stderr output and checks for identifying strings. The Apple fork on macOS does not self-identify, so it falls through to the "openbsd" default.

**Flag differences by variant:**

| Operation | ncat | GNU | OpenBSD | traditional |
| --------- | ---- | --- | ------- | ----------- |
| Listen | `nc -l -p 4444` | `nc -l -p 4444` | `nc -l 4444` | `nc -l -p 4444` |
| Keep-alive | `ncat -k -l -p 4444` | `while true; do nc -l -p 4444; done` | `nc -k -l 4444` | `while true; do nc -l -p 4444; done` |
| Execute on connect | `ncat -e /bin/bash -l -p 4444` | `nc -c /bin/bash -l -p 4444` | Named pipe workaround | `nc -e /bin/bash -l -p 4444` |
| Close after EOF | Default behavior | `nc -q 0` | `nc -N` | Default behavior |

## Key Flags to Remember

| Flag | What It Does |
| ---- | ------------ |
| `-z` | Scan mode -- connect without sending data (port scanning) |
| `-v` | Verbose output -- show connection details |
| `-l` | Listen mode -- wait for incoming connections |
| `-p <port>` | Specify port (required with `-l` on most variants, optional on OpenBSD) |
| `-u` | UDP mode instead of TCP |
| `-w <secs>` | Connection timeout in seconds |
| `-k` | Keep listener open after client disconnects (ncat and OpenBSD) |
| `-n` | Skip DNS resolution (faster scanning) |
| `-e <cmd>` | Execute command on connection (ncat and traditional only) |
| `-N` | Shutdown network socket after EOF on stdin (OpenBSD only) |

## Install

| Platform | Command |
| -------- | ------- |
| macOS | Pre-installed (`nc` is the OpenBSD variant) |
| Debian / Ubuntu | `apt install netcat-openbsd` |
| ncat (via nmap) | `apt install nmap` or `brew install nmap` |

## Use-Case Scripts

### scan-ports.sh -- Port scanning with netcat

Demonstrates port scanning techniques using netcat's `-z` (scan) mode. Detects the installed nc variant and labels variant-specific flags. Useful when nmap is not available or when you need a quick check to see if a specific service is reachable.

**When to use:** Quick ad-hoc connectivity tests when nmap is not installed or you need to check a specific port.

**Key commands:**

```bash
# Scan a single port
nc -zv 127.0.0.1 80

# Scan a port range (20 to 100)
nc -zv 127.0.0.1 20-100

# Scan with a connection timeout
nc -w 2 -zv 127.0.0.1 22

# UDP port scan
nc -zuv 127.0.0.1 53

# Scan common service ports in a loop
for port in 21 22 25 53 80 110 143 443 993 995 3306 5432 8080; do
    nc -zv -w 2 127.0.0.1 $port 2>&1
done

# Scan and grep for open/succeeded ports
nc -zv 127.0.0.1 1-1024 2>&1 | grep -i 'succeeded\|open'
```

**Make target:** `make scan-ports TARGET=<ip>`

---

### setup-listener.sh -- Setting up netcat listeners

Demonstrates how to set up netcat listeners for reverse shells, file transfers, debugging, and chat sessions. All examples are variant-aware.

**When to use:** When you need to catch reverse shells during pentests, receive file transfers, or debug client-server communication.

**Key commands:**

```bash
# Basic listener (OpenBSD variant)
nc -l 4444

# Listener with verbose output
nc -lv 4444

# Keep-alive listener -- stays open after client disconnects (OpenBSD)
nc -k -l 4444

# Listener that saves received data to a file
nc -l 4444 > received_data.txt

# UDP listener
nc -lu 4444

# Two-way chat setup
# Machine A: nc -l 4444
# Machine B: nc <listener-ip> 4444
```

**Make target:** `make nc-listener`

---

### transfer-files.sh -- File transfer with netcat

Demonstrates file transfer techniques using netcat. Shows how to send and receive files, directories, and compressed data over TCP without any authentication or daemon.

**When to use:** Quick ad-hoc transfers during pentests or CTFs when SSH/SCP is not available, or in minimal environments lacking scp/rsync.

**Key commands:**

```bash
# Send a file -- receiver listens, sender connects
# Receiver: nc -l 4444 > received_file.txt
# Sender:   nc 127.0.0.1 4444 < file_to_send.txt

# Send an entire directory via tar pipe
# Receiver: nc -l 4444 | tar xvf -
# Sender:   tar cvf - /path/to/directory | nc 127.0.0.1 4444

# Transfer with gzip compression
# Receiver: nc -l 4444 | gunzip > received_file.txt
# Sender:   gzip -c file_to_send.txt | nc 127.0.0.1 4444

# Verify transfer integrity with checksums
# Sender:   sha256sum file_to_send.txt
# Receiver: sha256sum received_file.txt

# Encrypted transfer via openssl pipe
# Receiver: nc -l 4444 | openssl enc -d -aes-256-cbc -pbkdf2 -pass pass:SECRET > received_file.txt
# Sender:   openssl enc -aes-256-cbc -pbkdf2 -pass pass:SECRET < file_to_send.txt | nc 127.0.0.1 4444
```

**Make target:** `make nc-transfer`

## Practice Against Lab Targets

```bash
make lab-up

# Quick check which lab ports are open
nc -zv localhost 8080    # DVWA
nc -zv localhost 3030    # Juice Shop
nc -zv localhost 8888    # WebGoat
nc -zv localhost 8180    # VulnerableApp

# Scan all lab ports at once
for port in 8080 3030 8888 8180; do
    nc -zv -w 2 localhost $port 2>&1
done
```

## Notes

- `nc -h` exits non-zero on macOS/OpenBSD -- the scripts use `|| true` guards in variant detection
- On macOS, `nc` is the OpenBSD variant (Apple fork) -- it does not support `-e` for command execution
- Port scanning output goes to stderr on most variants -- use `2>&1` to capture it
- File transfers need two terminals (listener + sender) -- they cannot be demoed in a single session
- The `detect_nc_variant()` function uses exclusion-based detection because the Apple fork does not self-identify
- For persistent listeners with the OpenBSD or ncat variant, use `-k` to keep listening after each client disconnects
