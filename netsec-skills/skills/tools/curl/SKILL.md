---
name: curl
description: >-
  Debug HTTP requests and inspect SSL certificates with curl. TLS versions,
  certificate chains, headers, response timing.
disable-model-invocation: true
---

# Curl HTTP Tool

Debug HTTP requests, inspect SSL certificates, and test endpoints using curl.

## Tool Status

- Tool installed: !`command -v curl > /dev/null 2>&1 && echo "YES -- $(curl --version 2>/dev/null | head -1)" || echo "NO -- Install: apt install curl (Debian/Ubuntu) | brew install curl (macOS)"`
- Wrapper scripts available: !`test -f scripts/curl/check-ssl-certificate.sh && echo "YES -- use wrapper scripts for structured JSON output" || echo "NO -- using standalone mode with direct commands"`

## Mode: Wrapper Scripts Available

If wrapper scripts are available (shown as YES above), prefer these commands.
They provide structured JSON output and educational context.

### SSL/TLS Inspection
- `bash scripts/curl/check-ssl-certificate.sh <target> -j -x` -- Inspect certificate validity, expiry, TLS versions, cipher suites

### HTTP Debugging
- `bash scripts/curl/debug-http-response.sh <target> -j -x` -- Debug response timing, headers, redirects, and latency breakdown

### Endpoint Testing
- `bash scripts/curl/test-http-endpoints.sh <target> -j -x` -- Test HTTP methods (GET, POST, PUT, DELETE) and status codes

### Learning Mode
- `bash scripts/curl/examples.sh <target>` -- 10 common curl patterns with explanations

Always add `-j` for JSON output and `-x` to execute (vs display-only).

## Mode: Standalone (Direct Commands)

If wrapper scripts are NOT available, use these direct curl commands.

### SSL/TLS Inspection

Check certificate validity, expiry dates, TLS version support, and certificate
chain of trust. Weak TLS versions (1.0, 1.1) have known vulnerabilities.

- `curl -vI https://<target> 2>&1 | grep -E 'subject:|issuer:|expire|SSL'` -- View SSL certificate details
- `curl -vI https://<target> 2>&1 | grep 'expire date'` -- Check certificate expiry date
- `curl --tlsv1.2 --tls-max 1.2 -sI https://<target> -o /dev/null -w 'TLS 1.2: HTTP %{http_code}\n'` -- Test TLS 1.2 support
- `curl --tlsv1.3 -sI https://<target> -o /dev/null -w 'TLS 1.3: HTTP %{http_code}\n'` -- Test TLS 1.3 support
- `curl -vI https://<target> 2>&1 | grep -E 'subject:|issuer:'` -- Show certificate chain
- `curl -sI https://<target> | grep -i strict-transport-security` -- Check HSTS header
- `curl --ciphers ECDHE-RSA-AES256-GCM-SHA384 -sI https://<target> -o /dev/null -w 'Cipher test: HTTP %{http_code}\n'` -- Test specific cipher suite

### HTTP Debugging

Diagnose slow requests by breaking down DNS lookup, TCP connect, TLS handshake,
and time-to-first-byte. Pinpoint exactly where time is spent.

- `curl -I <target>` -- Show response headers only (HEAD request)
- `curl -iL <target>` -- Show headers and follow redirects
- `curl -v <target> 2>&1 | head -30` -- Verbose output with full request/response headers
- `curl -o /dev/null -s -w 'DNS: %{time_namelookup}s\nConnect: %{time_connect}s\nTLS: %{time_appconnect}s\nTTFB: %{time_starttransfer}s\nTotal: %{time_total}s\n' <target>` -- Full timing breakdown
- `curl -o /dev/null -s -w 'TTFB: %{time_starttransfer}s\n' <target>` -- Measure time-to-first-byte
- `curl -L -o /dev/null -s -w 'Redirects: %{num_redirects}\nTotal: %{time_total}s\n' <target>` -- Show redirect chain timing

### Endpoint Testing

Test how servers respond to different HTTP methods. Discover allowed methods,
CORS policies, and authentication behavior.

- `curl -s -o /dev/null -w 'HTTP %{http_code}\n' <target>` -- GET request status code
- `curl -X POST -d 'username=admin&password=test' -s -o /dev/null -w 'HTTP %{http_code}\n' <target>` -- POST with form data
- `curl -X POST -H 'Content-Type: application/json' -d '{"key":"value"}' <target>` -- POST with JSON body
- `curl -X OPTIONS -i -s <target>` -- Discover allowed methods and CORS
- `curl -A 'Mozilla/5.0 (compatible; SecurityAudit/1.0)' -s -o /dev/null -w 'HTTP %{http_code}\n' <target>` -- Custom User-Agent
- `curl -L -v -s -o /dev/null <target> 2>&1 | grep -E '< HTTP/|< location:'` -- Follow and show redirect chain

## Defaults

- Target defaults to `example.com` (SSL) or `https://example.com` (HTTP scripts)
- Target can be a domain name or full URL

## Target Validation

All commands validate targets against `.pentest/scope.json` via the PreToolUse hook.
