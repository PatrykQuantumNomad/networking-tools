---
title: "Connectivity Diagnostic"
description: "Layer-by-layer connectivity diagnostic from DNS to TLS for troubleshooting network issues"
sidebar:
  order: 2
---

## What It Checks

The connectivity diagnostic walks through network layers from local network to TLS, running checks at each level to pinpoint where connectivity breaks. It produces a structured report with `[PASS]`, `[FAIL]`, and `[WARN]` indicators across seven sections:

1. **Local Network** -- Can we detect our own IP and default gateway?
2. **DNS Resolution** -- Does the target domain resolve to an IP?
3. **ICMP Reachability** -- Can we ping the target?
4. **TCP Port Connectivity** -- Are ports 80 and 443 open?
5. **HTTP/HTTPS Response** -- Does the web server respond with valid status codes?
6. **TLS Certificate** -- Is the SSL certificate valid and not expired?
7. **Connection Timing** -- How long does each phase of the connection take?

## Running the Diagnostic

```bash
# Run with default target (example.com)
bash scripts/diagnostics/connectivity.sh

# Run against a specific domain
bash scripts/diagnostics/connectivity.sh google.com

# Protocol prefix is stripped automatically
bash scripts/diagnostics/connectivity.sh https://mysite.com

# Or via Makefile
make diagnose-connectivity TARGET=example.com
make diagnose-connectivity TARGET=google.com
```

The diagnostic is non-interactive and produces output directly to the terminal. Protocol prefixes (http:// or https://) are automatically stripped from the target.

## Understanding the Report

### Section 1: Local Network

Detects local network configuration using platform-specific methods.

| Check | Severity | Meaning |
| ----- | -------- | ------- |
| Local IP detected | **PASS** | Your machine has a network interface with an IP address |
| Local IP not detected | **WARN** | Could not determine local IP -- may indicate no active network interface |
| Default gateway detected | **PASS** | A default route exists (you have internet access path) |
| Default gateway not detected | **WARN** | No default gateway found -- you may not have internet access |

The local IP detection is platform-aware: it uses `ifconfig` on macOS (Darwin) and `ip` on Linux. This is because `iproute2mac`'s `ip` command behaves differently on macOS.

### Section 2: DNS Resolution

Checks if the target domain resolves to an IPv4 address using `dig +short`.

| Check | Severity | Meaning |
| ----- | -------- | ------- |
| DNS resolves | **PASS** | Domain resolved to an IP address (shown in output) |
| DNS fails | **FAIL** | No A record returned -- the domain cannot be reached by name |

DNS failure is a hard `[FAIL]` because all subsequent checks depend on name resolution.

### Section 3: ICMP Reachability

Sends 3 ICMP echo requests (ping) with a 5-second timeout.

| Check | Severity | Meaning |
| ----- | -------- | ------- |
| Ping succeeds | **PASS** | Host responds to ICMP -- includes packet stats and RTT |
| Ping fails | **WARN** | Host may block ICMP -- this is filtering, not necessarily broken connectivity |

ICMP failure is a `[WARN]`, not a `[FAIL]`. Many hosts and firewalls block ICMP echo requests as a security measure. A failed ping does not mean the host is unreachable -- it only means ICMP is filtered.

The ping command is platform-aware: macOS uses `ping -c 3 -t 5` (timeout via `-t`) while Linux uses `ping -c 3 -w 5` (timeout via `-w`).

### Section 4: TCP Port Connectivity

Tests whether TCP ports 80 (HTTP) and 443 (HTTPS) are open.

| Check | Severity | Meaning |
| ----- | -------- | ------- |
| Port 80 open | **PASS** | HTTP port is reachable |
| Port 80 closed/filtered | **WARN** | HTTP port is not reachable (may be intentional) |
| Port 443 open | **PASS** | HTTPS port is reachable |
| Port 443 closed/filtered | **WARN** | HTTPS port is not reachable |
| Neither port reachable | **FAIL** | No web service is accessible on standard ports |

The diagnostic uses `nc -z -w 3` when netcat is available, falling back to `curl` connection tests if `nc` is not installed.

### Section 5: HTTP/HTTPS Response

Sends HTTP and HTTPS HEAD requests and checks the status code.

| Check | Severity | Meaning |
| ----- | -------- | ------- |
| 2xx or 3xx response | **PASS** | Server responded successfully (or with redirect) |
| 4xx response | **WARN** | Client error (e.g., 403 Forbidden, 404 Not Found) |
| 000 (no response) | **WARN** | Connection failed -- no HTTP response received |
| Other codes | **WARN** | Unexpected status code |

The diagnostic checks both HTTP and HTTPS independently, with a 5-second connect timeout and 10-second max time.

### Section 6: TLS Certificate

Inspects the SSL/TLS certificate using `curl -vI`.

| Check | Severity | Meaning |
| ----- | -------- | ------- |
| Certificate found | **PASS** | TLS certificate exists, expiry date shown |
| Certificate valid for 30+ days | **PASS** | Certificate is not expiring soon |
| Certificate expires in < 30 days | **WARN** | Certificate is expiring soon -- renew it |
| Certificate expired | **FAIL** | Certificate has expired -- browsers will reject the connection |
| Certificate not verifiable | **FAIL** | Could not verify the TLS certificate |

When `openssl` is available, the diagnostic calculates the exact number of days until certificate expiry. The output also shows the certificate subject and issuer for identification.

### Section 7: Connection Timing

Measures the time spent in each phase of an HTTPS connection.

| Metric | What It Measures |
| ------ | ---------------- |
| DNS | Time to resolve the domain name |
| Connect | Time to establish TCP connection |
| TLS | Time to complete TLS handshake |
| First byte | Time to receive the first byte of response (TTFB) |
| Total | Total request time from start to finish |

| Check | Severity | Meaning |
| ----- | -------- | ------- |
| Timing collected | **PASS** | All timing phases measured successfully |
| Total > 5 seconds | **WARN** | Connection is slow -- investigate which phase is the bottleneck |
| Timing not available | **WARN** | Could not connect to measure timing |

### Summary

The report ends with a summary line showing total counts:

```text
[WARN] 10 passed, 0 failed, 3 warnings (13 checks)
```

- If any check failed: the summary line is marked `[FAIL]`
- If no failures but warnings exist: the summary line is marked `[WARN]`
- If all checks passed: the summary line is marked `[PASS]`

## Interpreting Results

### All PASS

Full connectivity is confirmed at every layer: DNS resolves, ICMP reaches the host, TCP ports are open, HTTP/HTTPS respond, TLS certificate is valid, and timing is acceptable.

### WARN only (no FAIL)

Common and often expected. Typical warnings include:

- **ICMP ping failed** -- Host blocks ICMP. This is normal for many web servers and cloud providers.
- **Port 80 closed** -- HTTPS-only site that does not listen on port 80.
- **HTTP 4xx response** -- Server returns a client error for the root URL (e.g., API servers that require authentication).
- **Total > 5 seconds** -- Slow connection, possibly due to geographic distance or server load.

### FAIL present

Indicates a real connectivity problem:

- **DNS resolution failed** -- Domain cannot be resolved. Check if the domain exists and DNS is properly configured.
- **Neither port 80 nor 443 reachable** -- No web service is running, or a firewall is blocking all traffic.
- **Certificate expired** -- TLS certificate needs renewal.
- **Certificate not verifiable** -- Certificate may be self-signed, chain may be incomplete, or the wrong certificate is served.

## Common Issues and Fixes

| Issue | Likely Cause | Fix |
| ----- | ------------ | --- |
| DNS resolution FAIL | Domain does not exist or DNS misconfigured | Verify domain and DNS records with `make diagnose-dns TARGET=<domain>` |
| ICMP WARN | Host blocks ping | Not a problem -- proceed to check TCP ports |
| Both ports closed | Firewall blocking, service not running | Check firewall rules, verify web server is running |
| HTTP 000 | Connection timeout | Check network path, DNS, and server availability |
| Certificate expired | Auto-renewal failed | Renew certificate (e.g., `certbot renew` for Let's Encrypt) |
| Slow timing (> 5s) | Geographic distance, server overload | Check which phase is slow (DNS, TLS, etc.) and address that layer |

## Requirements

The diagnostic requires the following tools:

| Tool | Required | Install |
| ---- | -------- | ------- |
| `curl` | Yes | `apt install curl` (Debian) / `dnf install curl` (RHEL) / Pre-installed on macOS |
| `dig` | Yes | `apt install dnsutils` (Debian) / `dnf install bind-utils` (RHEL) / `brew install bind` (macOS) |
| `nc` | Optional | Used for TCP port checks; falls back to `curl` if not available |
| `openssl` | Optional | Used for certificate expiry calculation; report still works without it |
| `ping` | Optional | Pre-installed on all platforms; used for ICMP reachability |
