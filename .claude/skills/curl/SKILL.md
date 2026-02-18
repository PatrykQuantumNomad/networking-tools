---
name: curl
description: HTTP request debugging and SSL inspection using curl wrapper scripts
disable-model-invocation: true
---

# Curl HTTP Tool

Run curl wrapper scripts for SSL certificate inspection, HTTP response debugging, and endpoint testing.

## Available Scripts

### SSL/TLS Inspection

- `bash scripts/curl/check-ssl-certificate.sh [target] [-j] [-x]` -- Inspect SSL/TLS certificates for expiry, chain validity, and cipher suites

### HTTP Debugging

- `bash scripts/curl/debug-http-response.sh [target] [-j] [-x]` -- Debug HTTP responses including headers, redirects, and timing

### Endpoint Testing

- `bash scripts/curl/test-http-endpoints.sh [target] [-j] [-x]` -- Test HTTP endpoints for status codes, response times, and content validation

### Learning Mode

- `bash scripts/curl/examples.sh <target>` -- View 10 common curl patterns with explanations

## Flags

All use-case scripts support these flags:

- `-j` / `--json` -- Output structured JSON envelope (enables PostToolUse hook summary)
- `-x` / `--execute` -- Execute commands instead of displaying them
- `--help` -- Show detailed usage, description, and examples for the script

Add `-j` to every invocation so Claude receives a parsed summary via the PostToolUse hook.
Without `-j`, Claude gets raw terminal output instead of structured results.

## Defaults

- Target defaults to `example.com` (SSL) or `https://example.com` (HTTP scripts)
- Target can be a domain name or full URL
- Additional script flags: `-v`/`--verbose`, `-q`/`--quiet`
- Scripts display commands without running them unless `-x` is passed

## Target Validation

All scripts validate targets against `.pentest/scope.json` via the PreToolUse hook.
If commands are blocked:

1. Run `/netsec-health` to check safety architecture status
2. Verify your target is listed in `.pentest/scope.json`
3. Default safe targets: localhost, 127.0.0.1, lab containers (ports 8080, 3030, 8888, 8180)
