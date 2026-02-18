---
name: dig
description: DNS record querying and zone transfer testing using dig wrapper scripts
disable-model-invocation: true
---

# Dig DNS Tool

Run dig wrapper scripts for DNS record queries, zone transfer testing, and propagation checks.

## Available Scripts

### DNS Records

- `bash scripts/dig/query-dns-records.sh [domain] [-j] [-x]` -- Query A, AAAA, MX, NS, TXT, SOA, and CNAME records for a domain

### Zone Transfers

- `bash scripts/dig/attempt-zone-transfer.sh [domain] [-j] [-x]` -- Attempt AXFR zone transfer against a domain's nameservers

### Propagation Checks

- `bash scripts/dig/check-dns-propagation.sh [domain] [-j] [-x]` -- Check DNS propagation across multiple public resolvers

### Learning Mode

- `bash scripts/dig/examples.sh <target>` -- View 10 common dig patterns with explanations

## Flags

All use-case scripts support these flags:

- `-j` / `--json` -- Output structured JSON envelope (enables PostToolUse hook summary)
- `-x` / `--execute` -- Execute commands instead of displaying them
- `--help` -- Show detailed usage, description, and examples for the script

Add `-j` to every invocation so Claude receives a parsed summary via the PostToolUse hook.
Without `-j`, Claude gets raw terminal output instead of structured results.

## Defaults

- Domain defaults to `example.com` when not provided
- Argument is a domain name (not IP address or URL)
- Additional script flags: `-v`/`--verbose`, `-q`/`--quiet`
- Scripts display commands without running them unless `-x` is passed

## Target Validation

All scripts validate targets against `.pentest/scope.json` via the PreToolUse hook.
If commands are blocked:

1. Run `/netsec-health` to check safety architecture status
2. Verify your target is listed in `.pentest/scope.json`
3. Default safe targets: localhost, 127.0.0.1, lab containers (ports 8080, 3030, 8888, 8180)
