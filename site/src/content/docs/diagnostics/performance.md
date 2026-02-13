---
title: "Performance Diagnostic"
description: "Automated network performance diagnostic: hop-by-hop latency analysis, packet loss detection, and route comparison using traceroute and mtr."
sidebar:
  order: 3
---

## What It Checks

The performance diagnostic traces the network path to a target and analyzes per-hop latency to identify bottlenecks. It produces a structured report with `[PASS]`, `[FAIL]`, `[WARN]`, and `[SKIP]` indicators across four sections:

1. **Network Path** -- Can we trace the route to the target? How many hops are there?
2. **Per-Hop Latency** -- What is the packet loss and average latency at each hop? (requires mtr)
3. **Latency Analysis** -- Are there sudden latency spikes between consecutive hops?
4. **Summary** -- Overall pass/fail/warn tally

## Running the Diagnostic

```bash
# Run with default target (example.com)
bash scripts/diagnostics/performance.sh

# Run against a specific host
bash scripts/diagnostics/performance.sh 8.8.8.8

# Run against a domain
bash scripts/diagnostics/performance.sh cloudflare.com

# Or via Makefile
make diagnose-performance TARGET=example.com
make diagnose-performance TARGET=8.8.8.8
```

The diagnostic is non-interactive and produces output directly to the terminal. It works with just traceroute and provides enhanced analysis when mtr is also available.

## Understanding the Report

### Section 1: Network Path

Runs `traceroute -n -q 1 -m 30` to map the route from your machine to the target.

| Check | Severity | Meaning |
| ----- | -------- | ------- |
| Route found: N hops | **PASS** | traceroute reached the target through N responsive hops |
| No route to target | **FAIL** | All hops timed out -- no path to the destination |
| Hop(s) returned no response | **WARN** | Some intermediate routers did not respond (common, usually not a problem) |

The full traceroute output is printed indented below the check result. Hops showing `*` (no response) are routers configured to not respond to traceroute probes -- this is normal for intermediate hops and does not indicate a problem unless the final destination is also unreachable.

### Section 2: Per-Hop Latency

When mtr is available and usable, runs `mtr --report --report-wide -c 10 -n` to collect 10 cycles of per-hop statistics.

| Check | Severity | Meaning |
| ----- | -------- | ------- |
| All hops within thresholds | **PASS** | Every hop has less than 5% packet loss and less than 100ms average latency |
| Hop N: X% packet loss | **WARN** | Hop is dropping packets -- may indicate congestion or unreliable link |
| Hop N: high latency (Xms avg) | **WARN** | Hop has average latency above 100ms -- expected for geographically distant hops |
| mtr not installed | **SKIP** | mtr is not available; install with `brew install mtr` or `apt install mtr` |
| mtr requires sudo on macOS | **WARN** | mtr needs raw socket access; re-run with `sudo` |

The full mtr report is printed indented below the check results. The report shows loss percentage, sent/received counts, last/average/best/worst latency, and standard deviation for each hop.

### Section 3: Latency Analysis

Analyzes the collected path data for patterns that indicate network problems.

**With mtr data:**

| Check | Severity | Meaning |
| ----- | -------- | ------- |
| Latency is consistent | **PASS** | No sudden jumps greater than 50ms between consecutive hops |
| Latency spike at hop N | **WARN** | A sudden increase of more than 50ms between two consecutive hops -- indicates a slow link or geographic jump |

The highest-latency hop is also reported for reference.

**With traceroute data only (no mtr):**

| Check | Severity | Meaning |
| ----- | -------- | ------- |
| No significant spikes | **PASS** | Traceroute timing values show no jumps greater than 50ms |
| Latency spike at hop N | **WARN** | A sudden timing increase between hops |
| Limited analysis | **INFO** | Not enough timing data from traceroute for meaningful analysis |

Traceroute provides less timing data than mtr (single probe vs. statistical average), so the analysis is less precise without mtr.

### Section 4: Summary

The report ends with a summary line showing total counts:

```text
[WARN] 2 passed, 0 failed, 1 warnings (3 checks)
```

- If any check failed: the summary line is marked `[FAIL]`
- If no failures but warnings exist: the summary line is marked `[WARN]`
- If all checks passed: the summary line is marked `[PASS]`

## Interpreting Results

### All PASS

The network path is clean: route is reachable, all hops have acceptable latency and no packet loss, and there are no sudden latency spikes. This is the ideal result.

### WARN for filtered hops (common)

Some intermediate routers do not respond to traceroute probes. This produces a `[WARN]` for "no response" hops but is normal behavior -- many ISP and backbone routers are configured this way. As long as the final destination is reachable, filtered intermediate hops are not a concern.

### WARN for packet loss

Packet loss at an intermediate hop can mean:
- **Congestion** -- the router is overloaded and dropping packets
- **Rate limiting** -- the router deprioritizes traceroute/ICMP responses (not actual data loss)
- **Unreliable link** -- physical layer issues (bad cable, wireless interference)

To distinguish rate limiting from real loss: check if the final destination also shows loss. If only intermediate hops show loss but the destination does not, it is likely rate limiting.

### WARN for latency spike

A latency spike (>50ms increase between consecutive hops) typically indicates:
- **Geographic distance** -- packets crossing an ocean or continent (expected)
- **Congestion** -- a saturated link adding queuing delay
- **Routing detour** -- packets being routed through a longer path than expected

A spike at a geographic boundary (e.g., US to Europe) is normal. A spike within the same city or ISP may indicate a problem.

### SKIP for mtr

When mtr is not installed, Section 2 is skipped and Section 3 falls back to basic traceroute analysis. Install mtr for the full diagnostic:

```bash
# macOS
brew install mtr

# Debian/Ubuntu
apt install mtr

# RHEL/Fedora
dnf install mtr
```

On macOS, mtr requires sudo: `sudo bash scripts/diagnostics/performance.sh <target>`

## Requirements

| Tool | Required | Install | Notes |
| ---- | -------- | ------- | ----- |
| `traceroute` | Yes | `apt install traceroute` (Debian) / `dnf install traceroute` (RHEL) / Pre-installed on macOS | Core path tracing |
| `mtr` | Optional | `brew install mtr` (macOS) / `apt install mtr` (Debian) / `dnf install mtr` (RHEL) | Enhanced per-hop statistics; requires sudo on macOS |
