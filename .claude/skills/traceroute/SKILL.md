---
name: traceroute
description: Network path tracing and latency diagnosis using traceroute and mtr wrapper scripts
disable-model-invocation: true
---

# Traceroute Path Analyzer

Run traceroute wrapper scripts for network path tracing, route comparison, and latency diagnosis.

## Available Scripts

### Path Tracing

- `bash scripts/traceroute/trace-network-path.sh [target] [-j] [-x]` -- Trace network path to target showing each hop and latency

### Route Comparison

- `bash scripts/traceroute/compare-routes.sh [target] [-j] [-x]` -- Compare TCP, UDP, and ICMP route paths to detect filtering

### Latency Diagnosis

- `bash scripts/traceroute/diagnose-latency.sh [target] [-j] [-x]` -- Diagnose network latency issues using mtr real-time analysis

### Learning Mode

- `bash scripts/traceroute/examples.sh <target>` -- View 10 common traceroute patterns with explanations

## Flags

All use-case scripts support these flags:

- `-j` / `--json` -- Output structured JSON envelope (enables PostToolUse hook summary)
- `-x` / `--execute` -- Execute commands instead of displaying them
- `--help` -- Show detailed usage, description, and examples for the script

Add `-j` to every invocation so Claude receives a parsed summary via the PostToolUse hook.
Without `-j`, Claude gets raw terminal output instead of structured results.

## Defaults

- Target defaults to `example.com` when not provided
- diagnose-latency requires `mtr` (not traceroute) -- install separately if needed
- Requires sudo on macOS for raw socket access
- Scripts display commands without running them unless `-x` is passed

## Target Validation

All scripts validate targets against `.pentest/scope.json` via the PreToolUse hook.
If commands are blocked:

1. Run `/netsec-health` to check safety architecture status
2. Verify your target is listed in `.pentest/scope.json`
3. Default safe targets: localhost, 127.0.0.1, lab containers (ports 8080, 3030, 8888, 8180)
