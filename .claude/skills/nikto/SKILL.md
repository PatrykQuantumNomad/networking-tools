---
name: nikto
description: >-
  Scan web servers for vulnerabilities with nikto. CGI checks, outdated
  software, misconfigurations, authenticated scanning.
disable-model-invocation: true
---

# Nikto Web Scanner

Scan web servers for vulnerabilities and misconfigurations using nikto.

## Tool Status

- Tool installed: !`command -v nikto > /dev/null 2>&1 && echo "YES -- $(nikto -Version 2>/dev/null | head -1)" || echo "NO -- Install: brew install nikto (macOS) | apt install nikto (Debian/Ubuntu)"`
- Wrapper scripts available: !`test -f scripts/nikto/scan-specific-vulnerabilities.sh && echo "YES -- use wrapper scripts for structured JSON output" || echo "NO -- using standalone mode with direct commands"`

## Mode: Wrapper Scripts Available

If wrapper scripts are available (shown as YES above), prefer these commands.
They provide structured JSON output and educational context.

### Vulnerability Scanning
- `bash scripts/nikto/scan-specific-vulnerabilities.sh <target> -j -x` -- Scan for specific vulnerability types using tuning flags

### Multi-Target Scanning
- `bash scripts/nikto/scan-multiple-hosts.sh <hostfile> -j -x` -- Scan multiple web servers from a host list or nmap output

### Authenticated Scanning
- `bash scripts/nikto/scan-with-auth.sh <target> -j -x` -- Perform authenticated scans using credentials or cookies

### Learning Mode
- `bash scripts/nikto/examples.sh <target>` -- 10 common nikto patterns with explanations

Always add `-j` for JSON output and `-x` to execute (vs display-only).

## Mode: Standalone (Direct Commands)

If wrapper scripts are NOT available, use these direct nikto commands.

### Basic Scanning

Nikto checks web servers for dangerous files, outdated software, and
misconfigurations. Output is verbose by default with findings categorized.

- `nikto -h http://<target>` -- Basic web server scan
- `nikto -h http://<target> -p 8080` -- Scan specific port
- `nikto -h http://<target> -ssl` -- Force SSL/TLS connection
- `nikto -h http://<target> -o report.html -Format html` -- Save HTML report
- `nikto -h http://<target> -o report.csv -Format csv` -- Save CSV report

### Tuning and Specific Vulnerability Types

Tuning flags (-Tuning) focus the scan on specific vulnerability categories.
Use these to reduce scan time or target known weakness areas.

- `nikto -h http://<target> -Tuning 1` -- Interesting files / seen in logs
- `nikto -h http://<target> -Tuning 2` -- Misconfiguration / default files
- `nikto -h http://<target> -Tuning 4` -- Injection (XSS/Script/HTML)
- `nikto -h http://<target> -Tuning 9` -- SQL injection
- `nikto -h http://<target> -Tuning 123` -- Combined: files + misconfig + info disclosure

### Multi-Target and Authenticated Scanning

Scan multiple hosts from a file, or authenticate to reach protected areas.
Without auth, nikto only tests the public surface.

- `nikto -h hosts.txt` -- Scan multiple hosts from file (one host:port per line)
- `nikto -h http://<target> -id user:pass` -- HTTP Basic Auth credentials
- `nikto -h http://<target> -C "PHPSESSID=abc123"` -- Scan with session cookie
- `nikto -h http://<target> -useproxy http://proxy:8080` -- Route through proxy

### Evasion

Encoding techniques to avoid IDS/WAF detection during scanning.

- `nikto -h http://<target> -evasion 1` -- Random URI encoding
- `nikto -h http://<target> -evasion 2` -- Directory self-reference (/./
- `nikto -h http://<target> -evasion 4` -- Prepend long random string

## Defaults

- Target defaults to `http://localhost:8080` when not provided
- Nikto is noisy by design -- it checks thousands of paths

## Target Validation

All commands validate targets against `.pentest/scope.json` via the PreToolUse hook.
