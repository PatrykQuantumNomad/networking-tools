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

## Important: Two Script Types

Diagnostic auto-report scripts (`scripts/diagnostics/`) do NOT support `-j` or `-x` flags. They run non-interactively and output directly to stdout in pass/fail/warn format. Interpret their text output directly.

Tool wrapper scripts (`scripts/traceroute/`, `scripts/dig/`) support `-j -x` as usual.

## Steps

### 1. DNS Diagnostics

Run the DNS diagnostic auto-report. This checks DNS resolution, record types, propagation across public resolvers, and reverse DNS.

```
bash scripts/diagnostics/dns.sh $ARGUMENTS
```

Do NOT add `-j` or `-x` to this command. Read the pass/fail/warn output directly and note any failures.

### 2. Connectivity Diagnostics

Run the connectivity diagnostic auto-report. This checks ICMP reachability, TCP connectivity on common ports, and basic network path.

```
bash scripts/diagnostics/connectivity.sh $ARGUMENTS
```

Do NOT add `-j` or `-x` to this command. Note any failed connectivity checks and which ports are unreachable.

### 3. Performance Diagnostics

Run the performance diagnostic auto-report. This measures latency, jitter, packet loss, and bandwidth estimation.

```
bash scripts/diagnostics/performance.sh $ARGUMENTS
```

Do NOT add `-j` or `-x` to this command. Note latency values, packet loss percentage, and any performance warnings.

### 4. Network Path Tracing

Trace the network path to the target using traceroute/mtr analysis:

```
bash scripts/traceroute/trace-network-path.sh $ARGUMENTS -j -x
```

This uses standard tool wrapper flags. Review hop-by-hop latency and identify where delays or packet loss occur.

### 5. DNS Propagation Check

Check DNS propagation across multiple resolvers:

```
bash scripts/dig/check-dns-propagation.sh $ARGUMENTS -j -x
```

This uses standard tool wrapper flags. Compare responses across public resolvers (Google, Cloudflare, OpenDNS) to identify propagation issues.

## After Each Step

- **Steps 1-3** (diagnostics scripts): Interpret text output directly. Look for PASS/FAIL/WARN markers and note all failures.
- **Steps 4-5** (tool wrapper scripts): Review the JSON output summary from the PostToolUse hook.
- If a step fails due to missing tool or network access, note the error and continue.
- Adapt subsequent steps based on findings (e.g., if DNS resolution fails, network path tracing may also fail).

## Summary

After all steps complete, provide a structured diagnostics summary:

- **DNS Health**: Resolution status, record types found, propagation consistency
- **Connectivity**: Reachable ports, failed connections, ICMP status
- **Performance**: Latency (avg/min/max), packet loss, jitter
- **Network Path**: Hop count, problem hops, total path latency
- **Propagation**: Resolver agreement, propagation status across providers
