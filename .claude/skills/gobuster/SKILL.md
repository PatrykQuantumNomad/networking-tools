---
name: gobuster
description: >-
  Discover hidden directories and enumerate subdomains with gobuster. Directory
  brute-force, DNS enumeration, wordlist scanning.
disable-model-invocation: true
---

# Gobuster Directory Scanner

Discover hidden directories and enumerate subdomains using gobuster.

## Tool Status

- Tool installed: !`command -v gobuster > /dev/null 2>&1 && echo "YES -- $(gobuster version 2>/dev/null | head -1)" || echo "NO -- Install: brew install gobuster (macOS) | go install github.com/OJ/gobuster/v3@latest"`
- Wrapper scripts available: !`test -f scripts/gobuster/discover-directories.sh && echo "YES -- use wrapper scripts for structured JSON output" || echo "NO -- using standalone mode with direct commands"`

## Mode: Wrapper Scripts Available

If wrapper scripts are available (shown as YES above), prefer these commands.
They provide structured JSON output and educational context.

### Directory Discovery
- `bash scripts/gobuster/discover-directories.sh <target> <wordlist> -j -x` -- Discover hidden directories and files on web servers

### Subdomain Enumeration
- `bash scripts/gobuster/enumerate-subdomains.sh <domain> <wordlist> -j -x` -- Enumerate subdomains using DNS brute-forcing

### Learning Mode
- `bash scripts/gobuster/examples.sh <target>` -- 10 common gobuster patterns with explanations

Always add `-j` for JSON output and `-x` to execute (vs display-only).

## Mode: Standalone (Direct Commands)

If wrapper scripts are NOT available, use these direct gobuster commands.

### Directory Discovery

Brute-force directories and files on web servers using wordlists. Gobuster is
fast and multi-threaded. A good wordlist is essential -- SecLists recommended.

- `gobuster dir -u http://<target> -w wordlist.txt` -- Basic directory brute-force
- `gobuster dir -u http://<target> -w wordlist.txt -t 20` -- 20 concurrent threads
- `gobuster dir -u http://<target> -w wordlist.txt -x php,html,txt` -- Search for file extensions
- `gobuster dir -u http://<target> -w wordlist.txt -s 200,204,301,302` -- Filter by status codes
- `gobuster dir -u http://<target> -w wordlist.txt -b 404,403` -- Exclude status codes
- `gobuster dir -u http://<target> -w wordlist.txt -o results.txt` -- Save output to file
- `gobuster dir -u http://<target> -w wordlist.txt -c "PHPSESSID=abc123"` -- Authenticated scan with cookie

### Subdomain Enumeration

DNS brute-forcing discovers subdomains that may host different services,
staging environments, or forgotten applications.

- `gobuster dns -d <domain> -w subdomains.txt` -- Basic subdomain enumeration
- `gobuster dns -d <domain> -w subdomains.txt -t 20` -- 20 concurrent threads
- `gobuster dns -d <domain> -w subdomains.txt --show-cname` -- Show CNAME records
- `gobuster dns -d <domain> -w subdomains.txt -r 8.8.8.8` -- Use specific DNS resolver

### Recommended Wordlists

Gobuster requires wordlists. SecLists is the standard collection:
- Directories: `SecLists/Discovery/Web-Content/directory-list-2.3-medium.txt`
- Subdomains: `SecLists/Discovery/DNS/subdomains-top1million-5000.txt`
- Install: `git clone https://github.com/danielmiessler/SecLists.git`

## Defaults

- Directory mode defaults to `http://localhost:8080` (DVWA)
- Subdomain mode defaults to `example.com`
- Wordlist argument required (no built-in default)

## Target Validation

All commands validate targets against `.pentest/scope.json` via the PreToolUse hook.
