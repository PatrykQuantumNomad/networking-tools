---
name: diagnose
description: Run network diagnostic workflow -- DNS, connectivity, and latency checks
argument-hint: "<target>"
disable-model-invocation: true
---

# Network Diagnostics Workflow

Run comprehensive network diagnostics against the target.

## Target

Target: $ARGUMENTS

If no target was provided, ask the user for a target before proceeding. Verify the target is in `.pentest/scope.json` (run `cat .pentest/scope.json` to check). If not in scope, ask the user to add it with `/scope add <target>`.

## Environment Detection

- Wrapper scripts available: !`test -f scripts/diagnostics/dns.sh && echo "YES" || echo "NO"`

## Important: Two Script Types

Diagnostic auto-report scripts (`scripts/diagnostics/`) do NOT support `-j` or `-x` flags. They run non-interactively and output directly to stdout in pass/fail/warn format. Interpret their text output directly.

Tool wrapper scripts (`scripts/traceroute/`, `scripts/dig/`) support `-j -x` as usual.

## Steps

### 1. DNS Diagnostics

Run DNS diagnostic checks to verify resolution, record types, and propagation across public resolvers.

**If wrapper scripts are available (YES above):**

```
bash scripts/diagnostics/dns.sh $ARGUMENTS
```

Do NOT add `-j` or `-x` to this command. Read the pass/fail/warn output directly and note any failures.

**If standalone (NO above), run these DNS checks manually:**

- `dig $ARGUMENTS A +noall +answer` -- A record resolution
- `dig $ARGUMENTS AAAA +noall +answer` -- IPv6 resolution
- `dig $ARGUMENTS MX +noall +answer` -- Mail exchange records
- `dig $ARGUMENTS NS +noall +answer` -- Authoritative nameservers
- `dig @8.8.8.8 $ARGUMENTS A +short` -- Google DNS propagation check
- `dig @1.1.1.1 $ARGUMENTS A +short` -- Cloudflare DNS propagation check
- `dig -x $(dig $ARGUMENTS A +short | head -1) +short` -- Reverse DNS lookup

Report findings as PASS/FAIL for each check.

### 2. Connectivity Diagnostics

Check ICMP reachability, TCP connectivity on common ports, and basic network path.

**If wrapper scripts are available (YES above):**

```
bash scripts/diagnostics/connectivity.sh $ARGUMENTS
```

Do NOT add `-j` or `-x` to this command. Note any failed connectivity checks and which ports are unreachable.

**If standalone (NO above), run these connectivity checks manually:**

- `ping -c 4 $ARGUMENTS` -- ICMP reachability test
- `curl -sI --connect-timeout 5 http://$ARGUMENTS` -- HTTP connectivity check
- `curl -sI --connect-timeout 5 https://$ARGUMENTS` -- HTTPS connectivity check
- `nc -zv $ARGUMENTS 22 2>&1` -- SSH port check
- `nc -zv $ARGUMENTS 80 2>&1` -- HTTP port check
- `nc -zv $ARGUMENTS 443 2>&1` -- HTTPS port check

Report each check as PASS (reachable) or FAIL (unreachable).

### 3. Performance Diagnostics

Measure latency, jitter, packet loss, and HTTP timing breakdown.

**If wrapper scripts are available (YES above):**

```
bash scripts/diagnostics/performance.sh $ARGUMENTS
```

Do NOT add `-j` or `-x` to this command. Note latency values, packet loss percentage, and any performance warnings.

**If standalone (NO above), run these performance checks manually:**

- `ping -c 10 $ARGUMENTS` -- Latency stats (min/avg/max/stddev)
- `curl -o /dev/null -s -w "DNS: %{time_namelookup}s\nConnect: %{time_connect}s\nTLS: %{time_appconnect}s\nTotal: %{time_total}s\n" https://$ARGUMENTS` -- HTTP timing breakdown

Review ping statistics for packet loss and jitter. Review curl timings for DNS/connect/TLS overhead.

### 4. Network Path Tracing

Trace the network path to the target using traceroute/mtr analysis. Review hop-by-hop latency and identify where delays or packet loss occur.

**If wrapper scripts are available (YES above):**

```
bash scripts/traceroute/trace-network-path.sh $ARGUMENTS -j -x
```

**If standalone (NO above), use direct traceroute commands:**

- `traceroute $ARGUMENTS` -- Standard UDP traceroute
- `mtr --report $ARGUMENTS` -- Combined traceroute+ping report
- `traceroute -T $ARGUMENTS` -- TCP traceroute (bypasses ICMP filters)

### 5. DNS Propagation Check

Check DNS propagation across multiple public resolvers. Compare responses to verify the target resolves consistently.

**If wrapper scripts are available (YES above):**

```
bash scripts/dig/check-dns-propagation.sh $ARGUMENTS -j -x
```

**If standalone (NO above), use direct dig commands:**

- `dig @8.8.8.8 $ARGUMENTS A +short` -- Google DNS
- `dig @1.1.1.1 $ARGUMENTS A +short` -- Cloudflare DNS
- `dig @208.67.222.222 $ARGUMENTS A +short` -- OpenDNS
- `dig @9.9.9.9 $ARGUMENTS A +short` -- Quad9 DNS

Compare responses across resolvers. Matching results indicate complete propagation.

## After Each Step

**Steps 1-3 (diagnostic scripts or standalone commands):**

- **If wrapper scripts are available:** Interpret the pass/fail/warn text output directly (no PostToolUse hook for diagnostic scripts).
- **If standalone:** Review the command output directly and report PASS/FAIL for each check.

**Steps 4-5 (tool wrapper scripts or standalone commands):**

- **If wrapper scripts are available:** Review the JSON output summary from the PostToolUse hook.
- **If standalone:** Review the command output directly for key findings.

- If a step fails due to missing tool or network access, note the error and continue.
- Adapt subsequent steps based on findings (e.g., if DNS resolution fails, network path tracing may also fail).

## Summary

After all steps complete, provide a structured diagnostics summary:

- **DNS Health**: Resolution status, record types found, propagation consistency
- **Connectivity**: Reachable ports, failed connections, ICMP status
- **Performance**: Latency (avg/min/max), packet loss, jitter
- **Network Path**: Hop count, problem hops, total path latency
- **Propagation**: Resolver agreement, propagation status across providers
