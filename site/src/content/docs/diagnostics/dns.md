---
title: "DNS Diagnostic"
description: "Comprehensive DNS diagnostic auto-report for domain troubleshooting"
sidebar:
  order: 1
---

## What It Checks

The DNS diagnostic runs a comprehensive set of DNS checks against a target domain and produces a structured report with `[PASS]`, `[FAIL]`, and `[WARN]` indicators. It covers four areas:

1. **DNS Resolution** -- Can the domain be resolved? Does it have IPv4, IPv6, and www records?
2. **DNS Record Types** -- Are the essential record types (MX, NS, TXT, SOA) present?
3. **DNS Propagation** -- Do multiple public resolvers return consistent results?
4. **Reverse DNS** -- Does the resolved IP have a PTR record?

## Running the Diagnostic

```bash
# Run with default target (example.com)
bash scripts/diagnostics/dns.sh

# Run against a specific domain
bash scripts/diagnostics/dns.sh mysite.com

# Or via Makefile
make diagnose-dns TARGET=example.com
make diagnose-dns TARGET=mysite.com
```

The diagnostic is non-interactive and produces output directly to the terminal. No `safety_banner` is displayed because DNS queries are passive lookups.

## Understanding the Report

### Section 1: DNS Resolution

Checks whether the domain resolves to an IP address.

| Check | Severity | Meaning |
| ----- | -------- | ------- |
| A record | **FAIL** if missing | The domain has no IPv4 address -- this is critical |
| AAAA record | **WARN** if missing | IPv6 is not configured -- common and non-critical |
| CNAME / A for www | **WARN** if missing | `www.` subdomain does not resolve -- not always required |

The A record check looks for IPv4 addresses using `dig +short <domain> A`. If no address is returned, the check fails because this means the domain cannot be reached via IPv4.

The AAAA check warns rather than fails because many domains do not yet have IPv6 configured.

### Section 2: DNS Record Types

Checks for essential DNS record types beyond the basic A record.

| Check | Severity | Meaning |
| ----- | -------- | ------- |
| MX records | **WARN** if missing | No mail servers configured -- not all domains handle email |
| NS records | **FAIL** if missing | No authoritative nameservers found -- this is critical for any domain |
| TXT records | **WARN** if missing | No SPF/DKIM/verification records -- non-critical but recommended |
| SOA record | **FAIL** if missing | No Start of Authority record -- every DNS zone must have one |

NS and SOA are structural requirements for any DNS zone. Missing NS means no nameserver is authoritative for the domain. Missing SOA means the zone is not properly configured.

### Section 3: DNS Propagation

Queries the domain's A record across four public DNS resolvers and checks for consistency.

| Resolver | IP |
| -------- | -- |
| Google | 8.8.8.8 |
| Cloudflare | 1.1.1.1 |
| Quad9 | 9.9.9.9 |
| OpenDNS | 208.67.222.222 |

| Check | Severity | Meaning |
| ----- | -------- | ------- |
| Resolver returns result | **PASS** per resolver | That resolver can resolve the domain |
| Resolver returns no result | **WARN** per resolver | Resolver did not return an A record |
| All resolvers agree | **PASS** | All resolvers returned the same IP |
| Resolvers disagree | **WARN** | Different IPs returned -- DNS propagation may be in progress |

Disagreement between resolvers typically means a recent DNS change has not fully propagated. Each resolver caches records for the duration of the TTL.

### Section 4: Reverse DNS

Performs a reverse lookup (PTR record) on the first resolved IP address.

| Check | Severity | Meaning |
| ----- | -------- | ------- |
| PTR record found | **PASS** | The IP has a hostname associated with it |
| No PTR record | **WARN** | Common for shared hosting and CDN IPs -- not critical |
| Cannot perform lookup | **WARN** | No A record was available to look up |

### Summary

The report ends with a summary line showing total counts:

```text
[PASS] 12 passed, 0 failed, 2 warnings (14 checks)
```

- If any check failed: the summary line is marked `[FAIL]`
- If no failures but warnings exist: the summary line is marked `[WARN]`
- If all checks passed: the summary line is marked `[PASS]`

## Interpreting Results

### All PASS

The domain's DNS is healthy. All record types are present, all resolvers return consistent results, and reverse DNS is configured.

### WARN only (no FAIL)

Common and usually acceptable. Typical warnings include:

- **No AAAA record** -- IPv6 not configured (most domains)
- **No MX records** -- Domain does not handle email
- **No TXT records** -- No SPF/DKIM configured
- **No PTR record** -- Shared hosting or CDN IP without reverse DNS
- **Resolvers disagree** -- Recent DNS change still propagating

### FAIL present

Indicates a critical DNS issue:

- **No A record** -- The domain cannot be resolved to an IPv4 address. Check if the DNS zone exists and the A record is configured.
- **No NS records** -- No nameserver is authoritative for the domain. The domain may not be registered or the registrar's nameserver configuration is wrong.
- **No SOA record** -- The DNS zone is not properly configured. Every zone must have exactly one SOA record.

## Common Issues and Fixes

| Issue | Likely Cause | Fix |
| ----- | ------------ | --- |
| A record FAIL | DNS zone not created or A record deleted | Add an A record at your DNS provider |
| NS record FAIL | Domain not registered or nameservers not set | Verify domain registration and nameserver configuration at registrar |
| SOA record FAIL | Zone not properly initialized | Contact DNS provider -- SOA is usually auto-created |
| Resolvers disagree | Recent DNS change | Wait for TTL to expire (check `dig +short <domain> SOA` for TTL values) |
| No AAAA | IPv6 not configured | Add AAAA record if IPv6 is desired |
| No PTR | Hosting provider does not set reverse DNS | Contact hosting provider or set PTR via IP management panel |

## Requirements

The diagnostic requires the following tool:

| Tool | Install |
| ---- | ------- |
| `dig` | `apt install dnsutils` (Debian) / `dnf install bind-utils` (RHEL) / `brew install bind` (macOS) |
