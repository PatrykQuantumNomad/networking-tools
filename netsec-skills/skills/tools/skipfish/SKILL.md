---
name: skipfish
description: >-
  Scan web applications for vulnerabilities with skipfish. Web crawler,
  authenticated scanning, security assessment.
disable-model-invocation: true
---

# Skipfish Web Scanner

Scan web applications for vulnerabilities using skipfish.

## Tool Status

- Tool installed: !`command -v skipfish > /dev/null 2>&1 && echo "YES -- $(skipfish -h 2>&1 | head -1)" || echo "NO -- Install: sudo port install skipfish (macOS) | apt install skipfish (Debian/Ubuntu)"`
- Wrapper scripts available: !`test -f scripts/skipfish/quick-scan-web-app.sh && echo "YES -- use wrapper scripts for structured JSON output" || echo "NO -- using standalone mode with direct commands"`

## Mode: Wrapper Scripts Available

If wrapper scripts are available (shown as YES above), prefer these commands.
They provide structured JSON output and educational context.

### Quick Scanning
- `bash scripts/skipfish/quick-scan-web-app.sh <target> -j -x` -- Run a fast web application scan with default settings

### Authenticated Scanning
- `bash scripts/skipfish/scan-authenticated-app.sh <target> -j -x` -- Scan web applications behind login pages using cookies or credentials

### Learning Mode
- `bash scripts/skipfish/examples.sh <target>` -- 10 common skipfish patterns with explanations

Always add `-j` for JSON output and `-x` to execute (vs display-only).

## Mode: Standalone (Direct Commands)

If wrapper scripts are NOT available, use these direct skipfish commands.

### Basic Scanning

Skipfish crawls a web application and tests for common vulnerabilities. Output
goes to a directory containing an interactive HTML report.

- `skipfish -o output_dir http://<target>` -- Basic web application scan
- `skipfish -o output_dir -m 5 http://<target>` -- Limit crawl depth to 5 levels
- `skipfish -o output_dir -g 5 -r 500 http://<target>` -- Limit max connections and requests per second
- `skipfish -o output_dir -W wordlist.txt http://<target>` -- Use custom wordlist for path discovery

### Authenticated Scanning

Scan behind login pages by providing session cookies or form-based credentials.
Without authentication, skipfish only tests the public-facing surface.

- `skipfish -o output_dir -C "PHPSESSID=abc123" http://<target>` -- Scan with session cookie
- `skipfish -o output_dir -C "security=low" -C "PHPSESSID=abc123" http://<target>` -- Multiple cookies
- `skipfish -o output_dir -A user:pass http://<target>` -- HTTP Basic Auth

### Scope Control

Restrict scanning to specific paths or domains to avoid crawling external
links or overwhelming the target.

- `skipfish -o output_dir -I /app/ http://<target>` -- Only scan URLs matching /app/
- `skipfish -o output_dir -X /logout http://<target>` -- Exclude logout path (prevent session kill)
- `skipfish -o output_dir -d 3 http://<target>` -- Limit crawl depth

## Defaults

- Quick scan defaults to `http://localhost:3030` (Juice Shop) when no target provided
- Authenticated scan defaults to `http://localhost:8080` (DVWA)
- Output goes to a timestamped directory

## Target Validation

All commands validate targets against `.pentest/scope.json` via the PreToolUse hook.
