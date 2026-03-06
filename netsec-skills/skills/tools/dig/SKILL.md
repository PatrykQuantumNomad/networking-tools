---
name: dig
description: >-
  Query DNS records and test zone transfers with dig. A, MX, NS, TXT records,
  AXFR, propagation checks, nameserver queries.
disable-model-invocation: true
---

# Dig DNS Tool

Query DNS records, test zone transfers, and check propagation using dig.

## Tool Status

- Tool installed: !`command -v dig > /dev/null 2>&1 && echo "YES -- $(dig -v 2>&1 | head -1)" || echo "NO -- Install: apt install dnsutils (Debian/Ubuntu) | brew install bind (macOS)"`
- Wrapper scripts available: !`test -f scripts/dig/query-dns-records.sh && echo "YES -- use wrapper scripts for structured JSON output" || echo "NO -- using standalone mode with direct commands"`

## Mode: Wrapper Scripts Available

If wrapper scripts are available (shown as YES above), prefer these commands.
They provide structured JSON output and educational context.

### DNS Records
- `bash scripts/dig/query-dns-records.sh <domain> -j -x` -- Query A, AAAA, MX, NS, TXT, SOA, CNAME records

### Zone Transfers
- `bash scripts/dig/attempt-zone-transfer.sh <domain> -j -x` -- Attempt AXFR zone transfer against nameservers

### Propagation Checks
- `bash scripts/dig/check-dns-propagation.sh <domain> -j -x` -- Compare DNS responses across public resolvers

### Learning Mode
- `bash scripts/dig/examples.sh <target>` -- 10 common dig patterns with explanations

Always add `-j` for JSON output and `-x` to execute (vs display-only).

## Mode: Standalone (Direct Commands)

If wrapper scripts are NOT available, use these direct dig commands.

### DNS Records

Query different record types to map a domain's infrastructure. Each type reveals
different information: A/AAAA for IP addresses, MX for mail servers, NS for
nameservers, TXT for security policies (SPF, DKIM).

- `dig <target> A +noall +answer` -- IPv4 address lookup
- `dig <target> AAAA +noall +answer` -- IPv6 address lookup
- `dig <target> MX +noall +answer` -- Mail exchange servers
- `dig <target> NS +noall +answer` -- Authoritative nameservers
- `dig <target> TXT +noall +answer` -- SPF, DKIM, domain verification records
- `dig <target> SOA +noall +answer` -- Zone authority and serial number
- `dig www.<target> CNAME +noall +answer` -- Domain aliases
- `dig <target> ANY +noall +answer` -- Query all available records
- `dig <target> A +short` -- Clean output for scripting
- `dig @1.1.1.1 <target> A +noall +answer` -- Query via specific DNS server

### Zone Transfers

A DNS zone transfer (AXFR) copies all records from a nameserver. Misconfigured
servers allow anyone to download the entire zone, revealing subdomains, IP
addresses, and internal infrastructure.

- `dig <target> NS +short` -- Find authoritative nameservers first
- `dig axfr <target> @<nameserver>` -- Attempt AXFR zone transfer
- `dig +tcp axfr <target> @<nameserver>` -- Force TCP for zone transfer
- `dig <target> SOA +short` -- Check SOA serial number (tracks zone changes)
- `dig randomsubdomain1234.<target> A +short` -- Check for wildcard DNS records

### Propagation Checks

After changing DNS records, compare responses across public resolvers to verify
the update has propagated globally. Different resolvers cache at different rates.

- `dig @8.8.8.8 <target> A +short` -- Google DNS
- `dig @1.1.1.1 <target> A +short` -- Cloudflare DNS
- `dig @208.67.222.222 <target> A +short` -- OpenDNS
- `dig @9.9.9.9 <target> A +short` -- Quad9 DNS
- `dig +trace <target>` -- Trace delegation path from root servers
- `dig @8.8.8.8 <target> A +noall +answer +stats` -- Verbose query with stats

## Defaults

- Domain defaults to `example.com` when not provided
- Argument is a domain name (not IP address or URL)

## Target Validation

All commands validate targets against `.pentest/scope.json` via the PreToolUse hook.
