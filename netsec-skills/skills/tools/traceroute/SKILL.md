---
name: traceroute
description: >-
  Trace network paths and diagnose latency with traceroute and mtr. Hop
  analysis, route comparison, real-time latency monitoring.
disable-model-invocation: true
---

# Traceroute Path Analyzer

Trace network paths and diagnose latency using traceroute and mtr.

## Tool Status

- Tool installed: !`command -v traceroute > /dev/null 2>&1 && echo "YES -- traceroute installed" || echo "NO -- Install: pre-installed on macOS | apt install traceroute (Debian/Ubuntu)"`
- mtr installed: !`command -v mtr > /dev/null 2>&1 && echo "YES -- $(mtr --version 2>/dev/null | head -1)" || echo "NO -- Install: brew install mtr (macOS) | apt install mtr (Debian/Ubuntu)"`
- Wrapper scripts available: !`test -f scripts/traceroute/trace-network-path.sh && echo "YES -- use wrapper scripts for structured JSON output" || echo "NO -- using standalone mode with direct commands"`

## Mode: Wrapper Scripts Available

If wrapper scripts are available (shown as YES above), prefer these commands.
They provide structured JSON output and educational context.

### Path Tracing
- `bash scripts/traceroute/trace-network-path.sh <target> -j -x` -- Trace network path showing each hop and latency

### Route Comparison
- `bash scripts/traceroute/compare-routes.sh <target> -j -x` -- Compare TCP, UDP, and ICMP route paths to detect filtering

### Latency Diagnosis
- `bash scripts/traceroute/diagnose-latency.sh <target> -j -x` -- Diagnose network latency issues using mtr real-time analysis

### Learning Mode
- `bash scripts/traceroute/examples.sh <target>` -- 10 common traceroute patterns with explanations

Always add `-j` for JSON output and `-x` to execute (vs display-only).

## Mode: Standalone (Direct Commands)

If wrapper scripts are NOT available, use these direct traceroute/mtr commands.

### Basic Path Tracing

Traceroute sends packets with incrementing TTL values to map each hop between
source and destination. Reveals routers, latency per hop, and routing paths.

- `traceroute <target>` -- UDP traceroute (default)
- `traceroute -I <target>` -- ICMP traceroute (like ping path)
- `traceroute -T <target>` -- TCP traceroute (port 80, good for firewall traversal)
- `traceroute -n <target>` -- Numeric output (skip DNS resolution, faster)
- `traceroute -m 30 <target>` -- Set max hops (default 30)
- `traceroute -w 3 <target>` -- Set wait time per probe (seconds)

### Route Comparison

Compare different protocol paths to detect where filtering occurs. If TCP
reaches the target but UDP does not, a firewall is blocking UDP.

- `traceroute -T -p 80 <target>` -- TCP traceroute to port 80
- `traceroute -T -p 443 <target>` -- TCP traceroute to port 443
- `traceroute -U <target>` -- Explicit UDP traceroute
- `traceroute -I -n <target>` -- ICMP with numeric output for comparison

### MTR (My Traceroute)

MTR combines traceroute and ping into a real-time display. Shows packet loss
and latency statistics per hop over multiple rounds.

- `mtr --report <target>` -- Generate text report (default 10 rounds)
- `mtr -r -c 20 <target>` -- Report mode with 20 rounds
- `mtr -r -c 10 -n <target>` -- Report with numeric output (no DNS)
- `mtr -r --tcp -P 80 <target>` -- TCP mode to port 80
- `mtr -r --tcp -P 443 <target>` -- TCP mode to port 443

## Defaults

- Target defaults to `example.com` when not provided
- Requires sudo on macOS for raw socket access
- diagnose-latency requires mtr (install separately if needed)

## Target Validation

All commands validate targets against `.pentest/scope.json` via the PreToolUse hook.
