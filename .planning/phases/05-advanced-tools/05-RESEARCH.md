# Phase 5: Advanced Tools - Research

**Researched:** 2026-02-10
**Domain:** traceroute/mtr educational scripts, cross-platform route tracing, per-hop latency diagnostic
**Confidence:** HIGH

## Summary

Phase 5 adds traceroute and mtr as a combined tool family under `scripts/traceroute/`, following the same dual-pattern approach used throughout the project: Pattern A (educational examples.sh) plus Pattern A use-case scripts (trace-network-path, diagnose-latency, compare-routes), plus a new Pattern B diagnostic script (`scripts/diagnostics/performance.sh`) for structured latency reporting.

The primary technical challenge is cross-platform compatibility. There are three critical differences between macOS and Linux: (1) macOS traceroute uses `-P tcp` for TCP probes while Linux uses `-T`; macOS has no `-T` flag at all. (2) mtr requires sudo on macOS because it needs raw socket access; Homebrew's mtr formula explicitly states this requirement. (3) traceroute on macOS is the BSD version which uses `-I` for ICMP (same as Linux), but macOS uses `-P` to specify protocol whereas Linux uses dedicated short flags (`-T`, `-U`, `-I`). Both platforms share common flags: `-n` (numeric), `-q` (queries per hop), `-m` (max TTL), `-w` (wait timeout), `-f` (first TTL).

The mtr tool is powerful for the diagnostic use case because it runs in report mode (`mtr --report -c N`) producing per-hop statistics (loss%, sent, last, avg, best, worst, stdev) in a single non-interactive execution. It also supports `--json` output (requires jansson library, included in Homebrew install) which could be parsed by the diagnostic script. However, the simpler approach is to use `--report-wide` for human-readable output and parse the text report, avoiding a jq dependency.

**Primary recommendation:** Build examples.sh first covering both traceroute and mtr commands (they are complementary, not competing tools). Build use-case scripts following the established Pattern A template. Build performance.sh diagnostic last, following Pattern B established in Phase 3. Handle the macOS mtr sudo requirement with a `require_sudo_for_mtr()` helper that detects the OS and either warns or prompts for elevation.

## Standard Stack

### Core (already available -- no new dependencies to install for the project)

| Tool | Availability | Purpose | Cross-Platform Notes |
|------|-------------|---------|---------------------|
| traceroute | macOS (pre-installed at /usr/sbin/traceroute), Linux (inetutils or traceroute pkg) | Trace network path, show each hop to destination | BSD version (macOS) vs Linux version -- flag differences for TCP/UDP protocol selection (see Pitfalls) |
| mtr | macOS (brew install mtr), Linux (apt/dnf install mtr) | Combined ping+traceroute with continuous monitoring and per-hop stats | Requires sudo on macOS (raw socket access). Report mode (`-r`) is non-interactive. |

### Supporting (common.sh functions -- all from prior phases)

| Function | Purpose | Used In |
|----------|---------|---------|
| `report_pass/fail/warn/skip` | Colored indicators for diagnostic output | performance.sh (Pattern B) |
| `report_section` | Section headers for diagnostic output | performance.sh (Pattern B) |
| `run_check` / `_run_with_timeout` | Execute with timeout, auto report | performance.sh (Pattern B) |
| `require_cmd` | Exit with install hint if missing | All scripts |
| `check_cmd` | Boolean command existence check | Conditional tool availability |
| `safety_banner` | Legal authorization warning | examples.sh, use-case scripts |
| `info/success/warn/error` | Colored log output | All scripts |

### No New Libraries Needed

traceroute is pre-installed on macOS and available via package manager on Linux. mtr needs to be installed (`brew install mtr` on macOS, `apt install mtr` on Linux). No bash libraries, no jq dependency, no new common.sh additions required.

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| mtr for per-hop stats | traceroute + ping (manual combination) | mtr does both in one tool. Manual combination is fragile and verbose. Use mtr. |
| mtr --json for diagnostic parsing | mtr --report (text) with awk/grep parsing | JSON requires jq (new dependency). Text parsing with awk is sufficient and avoids adding dependencies. Use text report mode. |
| traceroute -P tcp (macOS) | tcptraceroute (separate tool) | tcptraceroute is not pre-installed anywhere. Use platform-detected flag instead. |

**Installation hints for scripts:**
```bash
# traceroute
require_cmd traceroute "apt install traceroute (Debian/Ubuntu) | dnf install traceroute (RHEL/Fedora) | pre-installed on macOS"

# mtr
require_cmd mtr "apt install mtr (Debian/Ubuntu) | dnf install mtr (RHEL/Fedora) | brew install mtr (macOS)"
```

## Architecture Patterns

### Recommended Project Structure

```
scripts/
  traceroute/
    examples.sh              # NEW: 10 examples covering traceroute + mtr (Pattern A)
    trace-network-path.sh    # NEW: Use-case: basic path tracing with explanation
    diagnose-latency.sh      # NEW: Use-case: mtr per-hop latency analysis
    compare-routes.sh        # NEW: Use-case: TCP vs ICMP vs UDP route comparison
  diagnostics/
    dns.sh                   # EXISTING (Phase 3)
    connectivity.sh          # EXISTING (Phase 3)
    performance.sh           # NEW: Latency diagnostic auto-report (Pattern B)
  common.sh                  # EXISTING: No changes needed
Makefile                     # MODIFY: Add traceroute/mtr targets + diagnose-performance
USECASES.md                  # MODIFY: Add route tracing and performance diagnostic entries
site/src/content/docs/
  tools/traceroute.md        # NEW: Tool page for traceroute/mtr
  diagnostics/performance.md # NEW: Diagnostic page for performance report
```

### Pattern A: examples.sh for traceroute/mtr (Combined Tool Family)

**What:** A single examples.sh covers both traceroute and mtr because they are complementary tools in the same domain (route tracing). This follows the same approach as other tool families in the project.

**Structure:**
```bash
#!/usr/bin/env bash
# traceroute/examples.sh -- Route tracing and path analysis examples
source "$(dirname "$0")/../common.sh"

show_help() { ... }

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

require_cmd traceroute "apt install traceroute (Debian) | pre-installed (macOS)"
require_target "${1:-}"
safety_banner

TARGET="$1"

info "=== Traceroute & MTR Examples ==="
info "Target: ${TARGET}"
echo ""

# Examples 1-5: traceroute commands
# Examples 6-10: mtr commands (note: may require sudo on macOS)

# Interactive demo at end
[[ -t 0 ]] || exit 0
read -rp "Run a basic traceroute to ${TARGET}? [y/N] " answer
```

**Key design decision:** examples.sh requires traceroute (pre-installed everywhere) but only checks for mtr availability for mtr-specific examples (6-10). If mtr is not installed, those examples still print the commands but note mtr is required.

### Pattern A: Use-Case Scripts with Platform Detection

**What:** Use-case scripts that detect the platform and adjust traceroute/mtr flags accordingly.

**Platform detection pattern for traceroute TCP flag:**
```bash
OS_TYPE="$(uname -s)"

# Platform-portable TCP traceroute
run_tcp_traceroute() {
    local target="$1"
    if [[ "$OS_TYPE" == "Darwin" ]]; then
        sudo traceroute -P tcp -n "$target"
    else
        sudo traceroute -T -n "$target"
    fi
}
```

### Pattern A: mtr Sudo Detection (PITFALL-10 / TOOL-018)

**What:** On macOS, mtr requires sudo. Scripts must detect this and handle it gracefully rather than failing silently.

**Implementation pattern:**
```bash
OS_TYPE="$(uname -s)"

# Check if mtr needs sudo and we have it
require_mtr_with_sudo() {
    require_cmd mtr "apt install mtr (Debian/Ubuntu) | brew install mtr (macOS)"
    if [[ "$OS_TYPE" == "Darwin" ]]; then
        if [[ $EUID -ne 0 ]]; then
            warn "mtr requires sudo on macOS (raw socket access)"
            warn "Re-running with sudo..."
            exec sudo "$0" "$@"
        fi
    fi
}

# Alternative: warn but don't auto-elevate
check_mtr_sudo() {
    if [[ "$OS_TYPE" == "Darwin" ]] && [[ $EUID -ne 0 ]]; then
        warn "mtr requires sudo on macOS for raw socket access"
        warn "Run with: sudo $0 $*"
        warn "Falling back to traceroute where possible"
        return 1
    fi
    return 0
}
```

**Recommendation:** Use the "warn and fall back" approach rather than auto-elevating with `exec sudo`. Auto-elevation can be surprising and is an anti-pattern for educational scripts. If mtr is unavailable (no sudo), fall back to traceroute for the same check where possible.

### Pattern B: performance.sh Diagnostic (Following Phase 3 Pattern)

**What:** The performance diagnostic follows the exact same Pattern B template established in Phase 3 by dns.sh and connectivity.sh. It is a non-interactive auto-report with sections, pass/fail/warn counters, and a summary.

**Structure:**
```bash
#!/usr/bin/env bash
# diagnostics/performance.sh -- Latency diagnostic auto-report
# Traces the network path and identifies where latency occurs hop-by-hop
# Pattern B: Diagnostic auto-report (non-interactive, no safety_banner)
source "$(dirname "$0")/../common.sh"

show_help() { ... }

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

require_cmd traceroute "..."
# mtr is optional -- enhances the report but not required

TARGET="${1:-example.com}"
OS_TYPE="$(uname -s)"

info "=== Performance Diagnostic Report ==="
info "Target: ${TARGET}"
info "Date:   $(date)"
echo ""

# Section 1: Basic Route (traceroute)
report_section "Network Path"

# Section 2: Per-Hop Latency (mtr --report, if available)
report_section "Per-Hop Latency"

# Section 3: Latency Analysis (identify high-latency hops)
report_section "Latency Analysis"

# Section 4: Protocol Comparison (optional, if mtr available)
report_section "Protocol Comparison"

# Summary
report_section "Summary"
```

### Anti-Patterns to Avoid

- **Using `-T` flag unconditionally for TCP traceroute:** macOS traceroute has no `-T` flag. Use `-P tcp` on macOS, `-T` on Linux. Always detect OS first.
- **Running mtr without checking sudo on macOS:** mtr will fail with "operation not permitted" on macOS without root. Always check and warn.
- **Adding jq as a dependency for JSON parsing:** The project has zero external bash dependencies beyond the tools themselves. Parse mtr text output with awk/grep instead of requiring jq.
- **Making performance.sh depend on mtr being installed:** Make traceroute the base requirement and mtr an enhancement. If mtr is missing, the diagnostic should still produce a useful (if less detailed) report using traceroute alone.
- **Using `exec sudo` to auto-elevate:** Educational scripts should warn and suggest, not auto-escalate privileges. The user should explicitly choose to run with sudo.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Per-hop statistics | Manual ping each hop from traceroute output | `mtr --report -c 10` | mtr already does this perfectly -- loss%, avg, best, worst, stdev per hop |
| Cross-platform traceroute flag selection | Repeated if/else blocks in each script | Single helper function with OS_TYPE detection | One function, reuse everywhere |
| Command timeout in diagnostic | Custom background/kill logic | `run_check` / `_run_with_timeout` from common.sh | Already built in Phase 1 |
| Colored pass/fail output | Custom echo with escape codes | `report_pass/fail/warn/skip` from common.sh | Already in common.sh |
| Sudo detection for mtr | Scattered sudo checks | `check_mtr_sudo()` helper function defined once | Consistent behavior across all mtr-using scripts |

**Key insight:** mtr in report mode (`mtr -r -c N target`) is essentially a "per-hop latency diagnostic" out of the box. The performance.sh diagnostic script's job is to run mtr, interpret the results (flag high-latency hops, detect packet loss), and present them in the project's structured report format -- not to reinvent mtr's functionality.

## Common Pitfalls

### Pitfall 1: macOS traceroute Has No -T Flag (CRITICAL)

**What goes wrong:** A script uses `traceroute -T target` for TCP traceroute. Works on Linux (where `-T` means TCP SYN), fails on macOS with "traceroute: unknown option -- T".

**Why it happens:** macOS ships BSD traceroute which uses `-P proto` to specify protocol (e.g., `-P tcp`). Linux ships a different implementation that uses dedicated flags (`-T` for TCP, `-U` for UDP, `-I` for ICMP).

**How to avoid:**
```bash
OS_TYPE="$(uname -s)"

traceroute_tcp() {
    local target="$1"
    if [[ "$OS_TYPE" == "Darwin" ]]; then
        sudo traceroute -P tcp -n "$target"
    else
        sudo traceroute -T -n "$target"
    fi
}

traceroute_icmp() {
    local target="$1"
    # -I works on both platforms
    sudo traceroute -I -n "$target"
}

traceroute_udp() {
    local target="$1"
    # Default behavior on both platforms (UDP)
    traceroute -n "$target"
}
```

**Flag cross-reference:**

| Protocol | macOS (BSD) | Linux (inetutils/traceroute) |
|----------|-------------|------------------------------|
| UDP (default) | `traceroute target` | `traceroute target` |
| ICMP | `traceroute -I target` or `traceroute -P icmp target` | `traceroute -I target` |
| TCP | `traceroute -P tcp target` | `traceroute -T target` |

**Warning signs:** "unknown option" errors on macOS only.

**Confidence:** HIGH -- verified against macOS man page (ss64.com/mac/traceroute.html) and Linux man page (man7.org).

### Pitfall 2: mtr Requires sudo on macOS (PITFALL-10)

**What goes wrong:** A script runs `mtr --report target` on macOS. It fails with "mtr: unable to get raw sockets" or "operation not permitted" because mtr needs raw socket access which requires root.

**Why it happens:** mtr creates raw ICMP sockets to send probe packets and receive TTL-exceeded replies. macOS restricts raw socket creation to root. On Linux, mtr is typically installed with the setuid bit set so it can run without explicit sudo.

**How to avoid:**
1. Check OS type at script start
2. If macOS, check if running as root
3. If not root on macOS, warn clearly and either fall back to traceroute or suggest re-running with sudo

```bash
run_mtr_report() {
    local target="$1"
    local cycles="${2:-10}"

    if ! check_cmd mtr; then
        report_skip "mtr not installed (install: brew install mtr)"
        return 1
    fi

    if [[ "$OS_TYPE" == "Darwin" ]] && [[ $EUID -ne 0 ]]; then
        report_warn "mtr requires sudo on macOS (raw socket access)"
        info "Run with: sudo $(basename "$0") ${target}"
        info "Falling back to traceroute..."
        return 1
    fi

    mtr --report --report-wide -c "$cycles" -n "$target"
}
```

**Confidence:** HIGH -- Homebrew formula page explicitly states: "mtr requires root privileges so you will need to run sudo mtr."

### Pitfall 3: traceroute TCP/ICMP Modes Require sudo on Both Platforms

**What goes wrong:** A script runs `traceroute -I target` (ICMP mode) or TCP mode without sudo. It fails because raw sockets are needed for non-UDP probe methods.

**Why it happens:** UDP traceroute works without root because it uses regular datagram sockets. ICMP and TCP modes require raw sockets to craft custom packets.

**How to avoid:** For the compare-routes.sh script, warn that TCP and ICMP modes require sudo:

```bash
info "Note: ICMP (-I) and TCP traceroute modes require sudo"
info "UDP mode (default) works without elevated privileges"
```

**Confidence:** HIGH -- standard Unix networking behavior.

### Pitfall 4: mtr Report Mode Output Can Be Slow

**What goes wrong:** A diagnostic script runs `mtr --report -c 100 target` and it takes 100+ seconds because each cycle takes approximately 1 second. Users think the script is hung.

**Why it happens:** mtr's `--report` mode produces no output until ALL cycles complete. With `-c 100`, that is approximately 100 seconds of silence.

**How to avoid:** Use a low cycle count for the diagnostic (10 is sufficient for basic statistics). Print a progress message before running mtr:

```bash
info "Running mtr (10 cycles, ~10 seconds)..."
mtr --report --report-wide -c 10 -n "$target"
```

**Confidence:** HIGH -- documented behavior of mtr --report mode.

### Pitfall 5: traceroute Not Installed on Minimal Linux

**What goes wrong:** traceroute is not installed by default on many minimal Linux distributions or containers.

**Why it happens:** traceroute is in the `traceroute` or `inetutils-traceroute` package on Debian/Ubuntu, and `traceroute` package on RHEL/Fedora. Not part of the base install.

**How to avoid:**
```bash
require_cmd traceroute "apt install traceroute (Debian/Ubuntu) | dnf install traceroute (RHEL/Fedora) | pre-installed on macOS"
```

**Confidence:** HIGH -- factual dependency issue.

### Pitfall 6: Common Flags That Work on Both Platforms

**What goes right:** These flags are safe to use without platform detection.

| Flag | Meaning | Both Platforms |
|------|---------|---------------|
| `-n` | Numeric output (no DNS resolution) | YES |
| `-q N` | Number of probes per hop (default 3) | YES |
| `-m N` | Max TTL / max hops (default 30) | YES |
| `-w N` | Wait time for probe response | YES (seconds on both) |
| `-f N` | First TTL (start hop) | YES |

**Confidence:** HIGH -- verified against both man pages.

## Code Examples

### examples.sh Structure (10 Examples: 5 traceroute + 5 mtr)

```bash
#!/usr/bin/env bash
# traceroute/examples.sh -- Route tracing and network path analysis
source "$(dirname "$0")/../common.sh"

# ... show_help, require_cmd traceroute, require_target, safety_banner ...

TARGET="$1"
HAS_MTR=false
check_cmd mtr && HAS_MTR=true

info "=== Traceroute & MTR Examples ==="
info "Target: ${TARGET}"
echo ""

# 1. Basic traceroute
info "1) Basic traceroute — show the path to a host"
echo "   traceroute ${TARGET}"
echo ""

# 2. Numeric output (skip DNS resolution, faster)
info "2) Numeric output — skip DNS lookups for speed"
echo "   traceroute -n ${TARGET}"
echo ""

# 3. ICMP traceroute (requires sudo)
info "3) ICMP traceroute — use ICMP ECHO instead of UDP (requires sudo)"
echo "   sudo traceroute -I ${TARGET}"
echo ""

# 4. Limit hops and probes
info "4) Limit to 15 hops, 1 probe per hop (faster)"
echo "   traceroute -m 15 -q 1 ${TARGET}"
echo ""

# 5. TCP traceroute (requires sudo, bypasses ICMP-blocking firewalls)
info "5) TCP traceroute — bypasses firewalls that block ICMP/UDP (requires sudo)"
if [[ "$(uname -s)" == "Darwin" ]]; then
    echo "   sudo traceroute -P tcp ${TARGET}"
else
    echo "   sudo traceroute -T ${TARGET}"
fi
echo ""

# 6-10: mtr examples
info "6) mtr — continuous traceroute with live statistics"
echo "   mtr ${TARGET}"
[[ "$HAS_MTR" == false ]] && echo "   (mtr not installed — brew install mtr / apt install mtr)"
echo ""

# 7. mtr report mode (non-interactive, 10 cycles)
info "7) mtr report mode — run 10 cycles and print summary"
echo "   mtr --report -c 10 ${TARGET}"
echo ""

# ... etc
```

### diagnose-latency.sh Use-Case Script

```bash
#!/usr/bin/env bash
# traceroute/diagnose-latency.sh -- Per-hop latency analysis using mtr
source "$(dirname "$0")/../common.sh"

show_help() { ... }

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

require_cmd mtr "apt install mtr (Debian/Ubuntu) | brew install mtr (macOS)"

TARGET="${1:-example.com}"
OS_TYPE="$(uname -s)"

# Check sudo for macOS
if [[ "$OS_TYPE" == "Darwin" ]] && [[ $EUID -ne 0 ]]; then
    warn "mtr requires sudo on macOS (raw socket access)"
    info "Re-run with: sudo $0 ${TARGET}"
    exit 1
fi

safety_banner

info "=== Diagnose Latency ==="
info "Target: ${TARGET}"
echo ""

info "Why per-hop latency matters?"
echo "   High latency at a single hop can indicate congestion, routing issues,"
echo "   or geographic distance. mtr shows statistics for EVERY hop, letting"
echo "   you pinpoint exactly where delays occur."
echo ""

# ... 10 examples of mtr latency analysis commands ...
```

### compare-routes.sh Use-Case Script (TCP vs ICMP vs UDP)

```bash
#!/usr/bin/env bash
# traceroute/compare-routes.sh -- Compare routes using different protocols
source "$(dirname "$0")/../common.sh"

# ... preamble ...

TARGET="${1:-example.com}"
OS_TYPE="$(uname -s)"

info "Why compare different protocols?"
echo "   Firewalls and routers treat ICMP, UDP, and TCP differently."
echo "   A path that blocks ICMP may allow TCP on port 80."
echo "   Comparing protocols reveals firewall behavior and alternate paths."
echo ""

# 1. UDP traceroute (default, no sudo needed)
info "1) UDP traceroute (default protocol, no sudo needed)"
echo "   traceroute -n ${TARGET}"
echo ""

# 2. ICMP traceroute (requires sudo)
info "2) ICMP traceroute (requires sudo)"
echo "   sudo traceroute -I -n ${TARGET}"
echo ""

# 3. TCP traceroute (requires sudo, platform-specific flag)
info "3) TCP traceroute (requires sudo, bypasses ICMP-blocking firewalls)"
if [[ "$OS_TYPE" == "Darwin" ]]; then
    echo "   sudo traceroute -P tcp -n ${TARGET}"
else
    echo "   sudo traceroute -T -n ${TARGET}"
fi
echo ""

# ... more comparison examples ...
```

### performance.sh Diagnostic (Pattern B)

```bash
#!/usr/bin/env bash
# diagnostics/performance.sh -- Latency diagnostic auto-report
# Traces the network path and identifies per-hop latency bottlenecks
# Pattern B: Diagnostic auto-report (non-interactive, no safety_banner)
source "$(dirname "$0")/../common.sh"

# ... show_help, require_cmd traceroute ...

TARGET="${1:-example.com}"
OS_TYPE="$(uname -s)"
HAS_MTR=false
check_cmd mtr && HAS_MTR=true

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

count_pass() { report_pass "$@"; PASS_COUNT=$((PASS_COUNT + 1)); }
count_fail() { report_fail "$@"; FAIL_COUNT=$((FAIL_COUNT + 1)); }
count_warn() { report_warn "$@"; WARN_COUNT=$((WARN_COUNT + 1)); }

info "=== Performance Diagnostic Report ==="
info "Target: ${TARGET}"
info "Date:   $(date)"
echo ""

# ===================================================================
# Section 1: Network Path (traceroute)
# ===================================================================
report_section "Network Path"
# Run traceroute, count hops, report pass/fail

# ===================================================================
# Section 2: Per-Hop Latency (mtr if available)
# ===================================================================
report_section "Per-Hop Latency"
if [[ "$HAS_MTR" == true ]]; then
    # Check sudo on macOS
    if [[ "$OS_TYPE" == "Darwin" ]] && [[ $EUID -ne 0 ]]; then
        count_warn "mtr requires sudo on macOS -- run with: sudo $0 ${TARGET}"
        info "Skipping per-hop latency analysis"
    else
        info "Running mtr (10 cycles, ~10 seconds)..."
        mtr_output=$(mtr --report --report-wide -c 10 -n "$TARGET" 2>&1)
        # Parse output, flag high-latency hops (>100ms avg), packet loss (>5%)
    fi
else
    report_skip "mtr not installed (install: brew install mtr / apt install mtr)"
    info "Per-hop latency requires mtr. Continuing with basic path analysis."
fi

# ===================================================================
# Section 3: Latency Analysis
# ===================================================================
report_section "Latency Analysis"
# Analyze mtr output: flag hops with >5% loss, >100ms avg, high jitter

# ===================================================================
# Section 4: Summary
# ===================================================================
report_section "Summary"
total=$((PASS_COUNT + FAIL_COUNT + WARN_COUNT))
# ... standard summary pattern from dns.sh / connectivity.sh ...
```

### Makefile Targets

```makefile
# In .PHONY line, add:
# traceroute trace-path diagnose-latency compare-routes diagnose-performance

traceroute: ## Run traceroute/mtr examples (usage: make traceroute TARGET=<host>)
	@bash scripts/traceroute/examples.sh $(TARGET)

trace-path: ## Trace network path (usage: make trace-path TARGET=<host>)
	@bash scripts/traceroute/trace-network-path.sh $(or $(TARGET),example.com)

diagnose-latency: ## Diagnose per-hop latency (usage: make diagnose-latency TARGET=<host>)
	@bash scripts/traceroute/diagnose-latency.sh $(or $(TARGET),example.com)

compare-routes: ## Compare TCP/ICMP/UDP routes (usage: make compare-routes TARGET=<host>)
	@bash scripts/traceroute/compare-routes.sh $(or $(TARGET),example.com)

diagnose-performance: ## Run performance diagnostic (usage: make diagnose-performance TARGET=<host>)
	@bash scripts/diagnostics/performance.sh $(or $(TARGET),example.com)
```

### USECASES.md Additions

```markdown
## Route Tracing & Performance

| I want to... | Command | Tool |
| -------------- | --------- | ------ |
| Trace the network path to a host | `make trace-path TARGET=<host>` | traceroute |
| Analyze per-hop latency | `make diagnose-latency TARGET=<host>` | mtr |
| Compare TCP/ICMP/UDP routes | `make compare-routes TARGET=<host>` | traceroute |
| Run a full performance diagnostic | `make diagnose-performance TARGET=<host>` | traceroute, mtr |
```

### Site Tool Page Structure (traceroute.md)

```markdown
---
title: "traceroute / mtr -- Route Tracing"
description: "Trace network paths, analyze per-hop latency, and compare routing protocols"
sidebar:
  order: 15
  badge:
    text: 'New'
    variant: 'tip'
---

## What They Do
[Description of traceroute and mtr as complementary tools]

## Running the Examples Script
[bash/make commands]

## Key Flags to Remember
[Flag table for traceroute and mtr separately]

## Install
[Platform install table]

## Use-Case Scripts
### trace-network-path.sh
### diagnose-latency.sh
### compare-routes.sh

## macOS Notes
[sudo requirement for mtr, TCP traceroute flag difference]

## Notes
[Tips and gotchas]
```

### Site Diagnostic Page Structure (performance.md)

```markdown
---
title: "Performance Diagnostic"
description: "Hop-by-hop latency diagnostic using traceroute and mtr"
sidebar:
  order: 3
---

## What It Checks
[Sections overview: network path, per-hop latency, latency analysis]

## Running the Diagnostic
[bash/make commands]

## Understanding the Report
[Section-by-section explanation with severity tables]

## Requirements
[traceroute required, mtr optional but recommended]
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| traceroute only (single snapshot) | mtr (continuous monitoring with stats) | mtr has been available for 20+ years | mtr is strictly superior for latency analysis; traceroute is still useful for one-shot path discovery |
| Text-only mtr output | mtr --json / --csv / --xml | Available since mtr 0.87+ | Machine-readable output for automation. However, text report is sufficient for this project. |
| BSD traceroute -P tcp | Linux traceroute -T | Diverged in the 2000s | Scripts MUST handle both flag styles |

**Current versions:**
- mtr: 0.96 (Homebrew stable, current as of research date)
- traceroute: Pre-installed on macOS (BSD version), various versions on Linux

## Open Questions

1. **Whether examples.sh should require traceroute AND mtr, or just traceroute**
   - What we know: traceroute is pre-installed on macOS. mtr requires separate installation.
   - What's unclear: Should examples 6-10 (mtr) require mtr to be installed, or should they print commands regardless?
   - Recommendation: Require traceroute only. Check mtr availability with `check_cmd mtr` and print mtr examples regardless (they are educational), but note "(requires mtr)" next to them. This matches the educational approach -- users learn the commands even before installing.

2. **Whether performance.sh should degrade gracefully without mtr**
   - What we know: mtr provides the best per-hop statistics. traceroute alone gives path but not continuous stats.
   - What's unclear: How useful is a performance diagnostic without mtr?
   - Recommendation: Make traceroute the base requirement. If mtr is available, produce the full per-hop latency analysis. If mtr is missing, produce a basic path report with traceroute and `report_skip` the latency analysis section. This follows the connectivity.sh pattern where nc is optional (falls back to curl).

3. **Whether to add traceroute/mtr to check-tools.sh**
   - What we know: check-tools.sh currently checks 14 tools. traceroute and mtr are new additions.
   - What's unclear: Should they be added to the checked tools list?
   - Recommendation: Yes, add both to `TOOLS` associative array and `TOOL_ORDER` in check-tools.sh. traceroute and mtr are now first-class tools in the project.

4. **Whether mtr sudo handling should auto-elevate or warn-and-exit**
   - What we know: The project's educational philosophy favors transparency over magic.
   - What's unclear: Whether to use `exec sudo "$0" "$@"` (convenient) or just warn and exit (transparent).
   - Recommendation: For use-case scripts (Pattern A), warn and exit -- let the user explicitly run with sudo. For the diagnostic script (Pattern B / performance.sh), also warn and skip the mtr section rather than auto-elevating. Never auto-elevate.

## Sources

### Primary (HIGH confidence)
- macOS traceroute man page: [ss64.com/mac/traceroute.html](https://ss64.com/mac/traceroute.html) -- verified `-P tcp` (not `-T`), `-I` for ICMP, UDP default
- Linux traceroute man page: [man7.org/linux/man-pages/man8/traceroute.8.html](https://www.man7.org/linux/man-pages/man8/traceroute.8.html) -- verified `-T` for TCP, `-I` for ICMP, `-U` for UDP
- mtr Debian man page: [manpages.debian.org/testing/mtr/mtr.8.en.html](https://manpages.debian.org/testing/mtr/mtr.8.en.html) -- verified `--report`, `--report-wide`, `--report-cycles`, `--tcp`, `--udp`, `--json`, `--csv`, `--no-dns`, `-o` field order
- Homebrew mtr formula: [formulae.brew.sh/formula/mtr](https://formulae.brew.sh/formula/mtr) -- verified version 0.96, sudo requirement caveat, jansson dependency
- Existing codebase: `scripts/common.sh` -- verified all required functions available
- Existing codebase: `scripts/diagnostics/connectivity.sh`, `scripts/diagnostics/dns.sh` -- Pattern B template verified
- Existing codebase: `scripts/nmap/examples.sh`, `scripts/dig/query-dns-records.sh` -- Pattern A template verified

### Secondary (MEDIUM confidence)
- [Dave's Network Blog: Using MTR on OS X without sudo](https://blog.dave-bell.co.uk/2020/01/06/using-mtr-on-os-x-without-sudo/) -- SUID workaround for mtr-packet on macOS
- [Dzubayyan Ahmad: Using MTR on macOS Without sudo](https://article.masdzub.com/how-to-use-mtr-without-sudo-macos.aspx/) -- confirms mtr raw socket requirement on macOS
- [Linode: Diagnosing Network Issues with MTR](https://www.linode.com/docs/guides/diagnosing-network-issues-with-mtr/) -- mtr report interpretation patterns
- [Homebrew/homebrew-core Issue #35085](https://github.com/Homebrew/homebrew-core/issues/35085) -- mtr setuid discussion, confirms sudo requirement is intentional
- [GTHost: Traceroute And MTR In-Depth Guide](https://gthost.com/blog/mtr-and-traceroute-in-depth-guide) -- traceroute vs mtr comparison
- [LinuxBash: mtr Network diagnostic tool](https://www.linuxbash.sh/post/mtr-network-diagnostic-tool-ping--traceroute) -- mtr flags reference

### Tertiary (LOW confidence)
- [Apple Developer Forums: traceroute socket operation not permitted](https://developer.apple.com/forums/thread/91878) -- traceroute permission issues on macOS (thread content not fully accessible)
- [Apple Developer Forums: tcptraceroute](https://developer.apple.com/forums/thread/708344) -- TCP traceroute limitations on macOS

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- traceroute/mtr are well-established Unix tools, verified against official man pages
- Architecture patterns: HIGH -- follows established Pattern A and Pattern B from Phases 2 and 3; templates verified in codebase
- Cross-platform pitfalls: HIGH -- traceroute flag differences verified against official macOS and Linux man pages; mtr sudo requirement confirmed by Homebrew formula
- Code examples: HIGH -- derived from existing codebase conventions and verified tool behavior
- Open questions: MEDIUM -- implementation decisions that affect UX but not correctness

**Research date:** 2026-02-10
**Valid until:** 2026-03-10 (stable domain, traceroute/mtr do not change frequently)
