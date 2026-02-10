# Phase 3: Diagnostic Scripts - Research

**Researched:** 2026-02-10
**Domain:** Cross-platform bash diagnostic scripting (DNS + connectivity), Pattern B auto-report architecture
**Confidence:** HIGH

## Summary

Phase 3 creates two diagnostic scripts (`scripts/diagnostics/dns.sh` and `scripts/diagnostics/connectivity.sh`) that follow the Pattern B auto-report approach established in the project architecture. These scripts are structurally different from the Pattern A educational scripts built in Phase 2 -- they execute actual commands, collect output, and produce structured pass/fail/warn reports instead of printing example commands for the user to run.

The primary technical challenge is cross-platform portability between macOS (BSD) and Linux (GNU/iproute2). The most dangerous differences are: (1) `ping` timeout flags differ between macOS (`-W` is milliseconds) and Linux (`-W` is seconds), (2) `ss` does not exist on macOS (use `lsof -i` or `netstat` instead), (3) `ip` command does not exist on macOS (use `ifconfig`), and (4) `sed -E` (extended regex) is the portable flag that works on both BSD and GNU sed, while `-r` is GNU-only. All of these must be handled with platform detection and fallback chains.

The diagnostic scripts build directly on infrastructure from Phase 1 (common.sh `report_pass/fail/warn/skip`, `report_section`, `run_check`) and tools from Phase 2 (dig, curl, nc are available). The `run_check` function already handles timeouts portably via `_run_with_timeout`, so diagnostic scripts can focus on check logic rather than timeout mechanics.

**Primary recommendation:** Build `dns.sh` first as it has fewer cross-platform concerns (dig output is consistent across platforms). Use it to establish the Pattern B template. Then build `connectivity.sh` which has more platform-specific logic. Both scripts should use `run_check` for individual checks and `report_section` for structural grouping, keeping scripts clean and consistent.

## Standard Stack

### Core (already available -- no new dependencies)

| Tool | Availability | Purpose in Diagnostics | Cross-Platform Notes |
|------|-------------|----------------------|---------------------|
| dig | macOS (pre-installed), Linux (dnsutils/bind-utils pkg) | DNS resolution, record queries, propagation checks | Output format is consistent across platforms when using `+short` and `+noall +answer` |
| curl | macOS (pre-installed), Linux (pre-installed) | HTTP connectivity, SSL cert checks, timing breakdown | `-w` format strings are identical across platforms |
| nc (netcat) | macOS (OpenBSD variant), Linux (varies) | TCP port connectivity checks | Use `detect_nc_variant()` from common.sh; `-z` flag works on all variants |
| ping | macOS (pre-installed), Linux (pre-installed) | ICMP reachability | CRITICAL: timeout flags differ (see Pitfalls) |
| host | macOS (pre-installed), Linux (dnsutils/bind-utils pkg) | Lightweight DNS lookup alternative | Simpler output than dig; good for quick resolution checks |

### Supporting (common.sh functions)

| Function | Purpose | Added In |
|----------|---------|----------|
| `report_pass` | Green [PASS] indicator | Phase 1 |
| `report_fail` | Red [FAIL] indicator | Phase 1 |
| `report_warn` | Yellow [WARN] indicator | Phase 1 |
| `report_skip` | Cyan [SKIP] indicator | Phase 1 |
| `report_section` | Cyan === Section === header | Phase 1 |
| `run_check` | Execute with 10s timeout, auto report pass/fail | Phase 1 |
| `_run_with_timeout` | Portable timeout (GNU timeout or POSIX fallback) | Phase 1 |
| `check_cmd` | Boolean command existence check | Original |
| `require_cmd` | Exit with install hint if missing | Original |
| `detect_nc_variant` | Identify netcat implementation | Phase 2 |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| dig for DNS checks | nslookup | dig has richer output and is the standard for DNS analysis; nslookup is considered semi-deprecated. Stick with dig. |
| ping for reachability | curl --connect-timeout | curl checks HTTP-level reachability but cannot test raw ICMP. Use both -- ping for Layer 3, curl for Layer 7. |
| nc for port checks | bash /dev/tcp | /dev/tcp is bash-specific (not POSIX), does not support timeouts natively, and is disabled in some bash builds. Use nc. |

**Installation:** No new packages needed. All tools are either pre-installed or were set up as Phase 2 dependencies.

## Architecture Patterns

### Recommended Project Structure

```
scripts/
  diagnostics/
    dns.sh              # NEW: DNS diagnostic auto-report
    connectivity.sh     # NEW: Connectivity diagnostic auto-report
  common.sh             # EXISTING: report_* and run_check functions
  dig/                  # EXISTING: Phase 2 dig scripts (referenced, not called)
  curl/                 # EXISTING: Phase 2 curl scripts (referenced, not called)
  netcat/               # EXISTING: Phase 2 netcat scripts (referenced, not called)
Makefile                # MODIFY: add diagnose-dns and diagnose-connectivity targets
USECASES.md             # MODIFY: add diagnostic "I want to..." entries
```

### Pattern B: Diagnostic Auto-Report Template

**What:** The canonical structure for all diagnostic scripts. Established here, reused in Phase 5 (performance.sh) and beyond.

**Structure:**

```bash
#!/usr/bin/env bash
# diagnostics/<name>.sh -- <one-line description>
source "$(dirname "$0")/../common.sh"

show_help() { ... }

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

# Require primary tool(s)
require_cmd <tool> "<install hint>"

# Target with sensible default
TARGET="${1:-example.com}"

# Header (NOT safety_banner -- diagnostics are passive/read-only)
info "=== <Diagnostic Name> Report ==="
info "Target: ${TARGET}"
info "Date:   $(date)"
echo ""

# Section 1
report_section "<Section Name>"
# Individual checks using run_check or manual report_pass/fail/warn
run_check "<Check description>" <command> <args>

# Section 2
report_section "<Section Name>"
# ... more checks ...

# Summary
report_section "Summary"
# Aggregate pass/fail counts or key findings
```

**Key differences from Pattern A:**

| Aspect | Pattern A (Educational) | Pattern B (Diagnostic) |
|--------|------------------------|----------------------|
| Header | `safety_banner` (active scanning) | `info` header (passive diagnostics) |
| Commands | Prints them for user to run | Executes them via `run_check` |
| Output | Numbered list with explanations | Structured report with [PASS]/[FAIL]/[WARN] |
| Interactivity | Optional demo at end | None -- fully non-interactive |
| Target | `require_target` (mandatory) | Sensible default (e.g., example.com) |
| Duration | Instant (prints text) | Takes time (runs checks with timeouts) |

### Pattern: Platform Detection for Command Selection

**What:** Detect OS to choose correct command or flags when behavior differs between macOS and Linux.

**When to use:** Only when commands have incompatible flag syntax (like ping timeout). Do NOT use for commands that work identically (like dig, curl).

```bash
# Detect OS once at script start
OS_TYPE="$(uname -s)"

# Use in a function for repeated platform-specific logic
get_ping_timeout_flag() {
    local seconds="$1"
    if [[ "$OS_TYPE" == "Darwin" ]]; then
        # macOS: -t sets overall timeout in seconds
        echo "-t $seconds"
    else
        # Linux: -w sets deadline in seconds
        echo "-w $seconds"
    fi
}
```

### Pattern: Fallback Chain for Modern/Legacy Commands

**What:** Try the modern command first, fall back to legacy if unavailable.

**When to use:** For `ip`/`ifconfig` and `ss`/`netstat` operations in the connectivity diagnostic.

```bash
get_local_ip() {
    if check_cmd ip; then
        # Modern Linux: ip addr
        ip -4 addr show scope global | grep -oP 'inet \K[0-9.]+'  | head -1
    elif check_cmd ifconfig; then
        # macOS / legacy Linux: ifconfig
        ifconfig | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | head -1
    else
        echo "unknown"
    fi
}
```

### Pattern: Custom Checks Beyond run_check

**What:** For checks where you need more control than `run_check` provides (e.g., parsing output to decide pass/warn/fail).

```bash
# When you need to interpret the output, not just check exit code
check_dns_resolution() {
    local domain="$1"
    local result
    result=$(dig +short "$domain" A 2>/dev/null)
    if [[ -z "$result" ]]; then
        report_fail "DNS resolution for $domain"
    elif echo "$result" | grep -q "^[0-9]"; then
        report_pass "DNS resolution for $domain"
        echo "   $result" | head -5
    else
        report_warn "DNS resolution returned non-IP result for $domain"
        echo "   $result" | head -5
    fi
}
```

### Anti-Patterns to Avoid

- **Calling Phase 2 use-case scripts from diagnostic scripts:** Diagnostic scripts call tools directly (dig, curl, nc), NOT Phase 2 scripts. Pattern B scripts are independent -- they source common.sh only.
- **Using `grep -P` (Perl regex):** macOS grep does not support `-P`. Use `grep -E` (extended regex) which works on both platforms.
- **Parsing `ifconfig` output with fixed column positions:** BSD ifconfig and GNU ifconfig format output differently. Use `awk` on field names, not positions.
- **Assuming `sed -r`:** GNU sed uses `-r` for extended regex, BSD sed uses `-E`. Use `sed -E` which works on modern versions of both.
- **Hardcoding DNS resolver IPs in multiple places:** Define resolvers in an array at the top of the script. Makes it easy to modify and keeps the DRY principle.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Command timeout | Custom background/kill logic | `run_check` (uses `_run_with_timeout`) | Already built in Phase 1 with portable macOS fallback. Handles exit code 124 for timeout detection. |
| Colored pass/fail output | Custom echo with escape codes | `report_pass/fail/warn/skip` | Consistent formatting across all diagnostic scripts. Already in common.sh. |
| Section headers | Custom echo formatting | `report_section` | Already in common.sh. Consistent visual style. |
| DNS resolution check | Raw dig + manual exit code parsing | `run_check "DNS resolution" dig +short TARGET` for simple cases | run_check handles timeout, captures output, reports result. Only write custom checks when you need to interpret the output beyond pass/fail. |
| Platform detection | Repeated `uname` calls in each check | Single `OS_TYPE="$(uname -s)"` at script start | One detection, reuse everywhere. |

**Key insight:** Phase 1 built `run_check` specifically for Phase 3. Use it heavily. The only time to bypass `run_check` is when you need to interpret command output to determine pass vs. warn vs. fail (not just exit code).

## Common Pitfalls

### Pitfall 1: ping Timeout Flags Differ Between macOS and Linux (CRITICAL)

**What goes wrong:** A diagnostic script uses `ping -W 3 -c 1 target` thinking `-W 3` means "3 second timeout." On macOS, `-W` means the per-packet wait time in MILLISECONDS, so `-W 3` means 3 milliseconds -- the ping will always timeout. On Linux, `-W` is seconds, and works as expected.

**Why it happens:** macOS ping is BSD-derived. Linux ping is from iputils. They chose different semantics for the same flag letter.

**How to avoid:**

```bash
OS_TYPE="$(uname -s)"

ping_check() {
    local target="$1"
    if [[ "$OS_TYPE" == "Darwin" ]]; then
        # macOS: -t is overall timeout in seconds, -W is per-packet wait in ms
        ping -c 1 -t 3 "$target" >/dev/null 2>&1
    else
        # Linux: -w is overall deadline in seconds, -W is per-response wait in seconds
        ping -c 1 -w 3 "$target" >/dev/null 2>&1
    fi
}
```

**Flag reference:**

| Flag | macOS (BSD) | Linux (iputils) |
|------|-------------|-----------------|
| `-c N` | Send N packets | Send N packets (same) |
| `-W N` | Per-packet wait, **milliseconds** | Per-response wait, **seconds** |
| `-t N` | Overall timeout, **seconds** | TTL value (NOT timeout!) |
| `-w N` | Does not exist | Overall deadline, **seconds** |

**Warning signs:** Ping checks always fail on one platform but work on the other.

**Confidence:** HIGH -- verified against macOS man page (ss64.com/mac/ping.html) and Linux man page (man7.org).

### Pitfall 2: `ss` Does Not Exist on macOS

**What goes wrong:** A diagnostic script uses `ss -tuln` to list listening ports. This works on Linux but fails with "command not found" on macOS because `ss` is a Linux-only tool (part of iproute2).

**Why it happens:** `ss` reads directly from Linux kernel's netlink socket interface. macOS has a completely different kernel architecture.

**How to avoid:** Use a fallback chain:

```bash
list_listening_ports() {
    if check_cmd ss; then
        # Modern Linux
        ss -tuln
    elif check_cmd netstat; then
        # macOS or legacy Linux
        netstat -tuln 2>/dev/null || netstat -an 2>/dev/null
    else
        report_skip "No tool available to list listening ports"
    fi
}
```

**Note:** On macOS, `netstat` does not support the `-p` flag (show PID) like Linux netstat does. Use `lsof -i -P -n` on macOS if you need PID information.

**Confidence:** HIGH -- verified: `ss` is part of iproute2, which is Linux-only.

### Pitfall 3: `ip` Command Does Not Exist on macOS

**What goes wrong:** A diagnostic script uses `ip addr show` or `ip route` for network information. Fails on macOS.

**Why it happens:** The `ip` command is part of the iproute2 suite, which is Linux-specific.

**How to avoid:** Prefer modern (`ip`) with fallback to legacy (`ifconfig`/`route`):

```bash
get_default_gateway() {
    if check_cmd ip; then
        ip route show default 2>/dev/null | awk '{print $3}' | head -1
    elif [[ "$OS_TYPE" == "Darwin" ]]; then
        route -n get default 2>/dev/null | grep 'gateway' | awk '{print $2}'
    else
        route -n 2>/dev/null | grep '^0.0.0.0' | awk '{print $2}' | head -1
    fi
}
```

**Confidence:** HIGH -- `ip` is Linux-only (iproute2 package).

### Pitfall 4: BSD grep Does Not Support -P (Perl Regex)

**What goes wrong:** A diagnostic script uses `grep -oP 'inet \K[0-9.]+'` to extract IP addresses. This Perl-regex flag works on Linux (GNU grep) but fails on macOS (BSD grep) with "invalid option".

**Why it happens:** macOS ships BSD grep which does not include PCRE support by default.

**How to avoid:** Use `grep -oE` (extended regex) or `awk` instead:

```bash
# Instead of: grep -oP 'inet \K[0-9.]+'
# Use:
grep -oE 'inet [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | awk '{print $2}'
# Or simply:
awk '/inet / && !/inet6/ {print $2}'
```

**Confidence:** HIGH -- well-known macOS limitation.

### Pitfall 5: `sed -r` Is GNU-only; Use `sed -E` for Portability

**What goes wrong:** Script uses `sed -r 's/pattern/replacement/'` which works on GNU sed (Linux) but fails on BSD sed (macOS).

**How to avoid:** Use `sed -E` which works on modern versions of both BSD and GNU sed.

**Confidence:** HIGH -- verified across platforms.

### Pitfall 6: Pattern Divergence Between Diagnostic Scripts (PITFALL-7)

**What goes wrong:** dns.sh and connectivity.sh end up with different structures, different output formats, different ways of handling errors. Each future diagnostic script copies a different one and the codebase becomes inconsistent.

**Why it happens:** Without a strict template, natural variation creeps in. Different developers (or the same developer on different days) make different structural choices.

**How to avoid:**
1. Build dns.sh FIRST and get it working.
2. Extract the structural pattern (preamble, sections, checks, summary).
3. Build connectivity.sh following the SAME structure.
4. Both scripts should use the same pattern: `show_help` -> `require_cmd` -> target default -> header -> sections with `report_section` -> checks with `run_check` or custom check functions -> summary.

**Confidence:** MEDIUM -- process discipline, not a technical fix.

### Pitfall 7: `run_check` Cannot Distinguish Warn from Fail

**What goes wrong:** `run_check` treats any non-zero, non-124 exit code as FAIL. But some checks should be WARN (e.g., no AAAA record is not a failure, just a notice).

**How to avoid:** Use `run_check` for binary pass/fail checks (command succeeds or fails). For nuanced checks that need WARN, write a custom check function that calls the command directly and uses `report_pass`, `report_warn`, or `report_fail` based on the output content.

```bash
# Binary check -- run_check is fine
run_check "DNS A record resolves" dig +short "$TARGET" A

# Nuanced check -- custom function needed
check_aaaa_record() {
    local result
    result=$(dig +short "$TARGET" AAAA 2>/dev/null)
    if [[ -n "$result" ]]; then
        report_pass "IPv6 (AAAA) record exists"
        echo "   $result"
    else
        report_warn "No IPv6 (AAAA) record found (not critical)"
    fi
}
```

**Confidence:** HIGH -- this is a design characteristic of run_check.

### Pitfall 8: dig Not Installed on Minimal Linux (PITFALL-14)

**What goes wrong:** DNS diagnostic script fails with "command not found" on a fresh minimal Linux install or container because dig is not installed by default.

**How to avoid:** `require_cmd dig` with a comprehensive install hint covering the major package managers:

```bash
require_cmd dig "apt install dnsutils (Debian/Ubuntu) | dnf install bind-utils (RHEL/Fedora) | brew install bind (macOS)"
```

This is already the pattern used in Phase 2 dig scripts. Carry it forward.

**Confidence:** HIGH -- factual dependency issue.

## Code Examples

### DNS Diagnostic Script Structure

```bash
#!/usr/bin/env bash
# diagnostics/dns.sh -- DNS diagnostic auto-report
source "$(dirname "$0")/../common.sh"

show_help() {
    cat <<EOF
Usage: $(basename "$0") [target] [-h|--help]

Description:
  Runs a comprehensive DNS diagnostic for the given domain.
  Checks resolution, record types, propagation across public
  resolvers, and reverse DNS lookup.
  Default target is example.com if none is provided.

Examples:
    $(basename "$0")                 # Diagnose example.com
    $(basename "$0") mysite.com      # Diagnose mysite.com
EOF
}

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

require_cmd dig "apt install dnsutils (Debian/Ubuntu) | dnf install bind-utils (RHEL/Fedora) | brew install bind (macOS)"

TARGET="${1:-example.com}"

info "=== DNS Diagnostic Report ==="
info "Target: ${TARGET}"
info "Date:   $(date)"
echo ""

# --- Section 1: Basic Resolution ---
report_section "DNS Resolution"
# Check A record
# Check AAAA record (warn if missing, not fail)
# Check CNAME

# --- Section 2: Record Types ---
report_section "DNS Record Types"
# Check MX, NS, TXT, SOA

# --- Section 3: Propagation ---
report_section "DNS Propagation"
# Query multiple public resolvers, compare results

# --- Section 4: Reverse DNS ---
report_section "Reverse DNS"
# Resolve IP to hostname via dig -x

# --- Summary ---
report_section "Summary"
# Report overall findings
```

### Connectivity Diagnostic Script Structure

```bash
#!/usr/bin/env bash
# diagnostics/connectivity.sh -- Connectivity diagnostic auto-report
source "$(dirname "$0")/../common.sh"

show_help() { ... }

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

require_cmd curl "apt install curl (Debian/Ubuntu) | brew install curl (macOS)"
require_cmd dig "apt install dnsutils (Debian/Ubuntu) | dnf install bind-utils (RHEL/Fedora) | brew install bind (macOS)"

TARGET="${1:-example.com}"
OS_TYPE="$(uname -s)"

info "=== Connectivity Diagnostic Report ==="
info "Target: ${TARGET}"
info "Date:   $(date)"
echo ""

# --- Section 1: DNS Resolution ---
report_section "DNS Resolution"
# Resolve target to IP (prerequisite for all following checks)

# --- Section 2: ICMP Reachability ---
report_section "ICMP Reachability (Ping)"
# Ping with platform-appropriate flags

# --- Section 3: TCP Port Checks ---
report_section "TCP Port Connectivity"
# Check common ports: 80, 443 (and others if applicable)
# Use nc -z with timeout

# --- Section 4: HTTP/HTTPS Response ---
report_section "HTTP/HTTPS Response"
# curl HEAD request, check status code

# --- Section 5: TLS Certificate ---
report_section "TLS Certificate"
# curl verbose to extract cert info
# Check expiry, issuer

# --- Section 6: Performance ---
report_section "Connection Timing"
# curl timing breakdown (DNS, connect, TLS, total)

# --- Summary ---
report_section "Summary"
```

### Portable Ping Function

```bash
# Source: Verified against macOS man page (ss64.com) and Linux man page (man7.org)
ping_host() {
    local target="$1"
    local count="${2:-3}"
    if [[ "$OS_TYPE" == "Darwin" ]]; then
        # macOS: -t is overall timeout in seconds
        ping -c "$count" -t 5 "$target" 2>&1
    else
        # Linux: -w is overall deadline in seconds
        ping -c "$count" -w 5 "$target" 2>&1
    fi
}
```

### Portable Local IP Detection

```bash
get_local_ip() {
    if check_cmd ip; then
        ip -4 addr show scope global 2>/dev/null | grep -oE 'inet [0-9.]+' | awk '{print $2}' | head -1
    elif check_cmd ifconfig; then
        ifconfig 2>/dev/null | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | head -1
    else
        echo "unknown"
    fi
}
```

### DNS Propagation Check Pattern

```bash
RESOLVERS=("8.8.8.8" "1.1.1.1" "9.9.9.9" "208.67.222.222")
RESOLVER_NAMES=("Google" "Cloudflare" "Quad9" "OpenDNS")

check_propagation() {
    local domain="$1"
    local record_type="${2:-A}"
    local results=()
    local i

    for i in "${!RESOLVERS[@]}"; do
        local resolver="${RESOLVERS[$i]}"
        local name="${RESOLVER_NAMES[$i]}"
        local result
        result=$(dig +short "@${resolver}" "$domain" "$record_type" 2>/dev/null | head -1)
        if [[ -n "$result" ]]; then
            report_pass "${name} (${resolver}): ${result}"
            results+=("$result")
        else
            report_warn "${name} (${resolver}): no response"
        fi
    done

    # Check consistency
    local unique
    unique=$(printf '%s\n' "${results[@]}" | sort -u | wc -l | tr -d ' ')
    if [[ "$unique" -le 1 ]]; then
        report_pass "All resolvers agree"
    else
        report_warn "Resolvers returned different results (propagation may be in progress)"
    fi
}
```

### Makefile Targets

```makefile
# Diagnostic targets (namespace: diagnose-*)
diagnose-dns: ## Run DNS diagnostic (usage: make diagnose-dns TARGET=<domain>)
	@bash scripts/diagnostics/dns.sh $(or $(TARGET),example.com)

diagnose-connectivity: ## Run connectivity diagnostic (usage: make diagnose-connectivity TARGET=<domain>)
	@bash scripts/diagnostics/connectivity.sh $(or $(TARGET),example.com)
```

### USECASES.md Entries

```markdown
## Network Diagnostics

| I want to... | Command | Tool |
| -------------- | --------- | ------ |
| Diagnose DNS resolution issues | `make diagnose-dns TARGET=<domain>` | dig |
| Check full connectivity (DNS to TLS) | `make diagnose-connectivity TARGET=<domain>` | dig, ping, nc, curl |
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `ifconfig` for interface info | `ip addr show` (Linux) / `ifconfig` still valid (macOS) | 2015+ on Linux | Diagnostic scripts MUST use `ip` first with `ifconfig` fallback |
| `netstat -tuln` for listening ports | `ss -tuln` (Linux) / `netstat` still valid (macOS) | 2015+ on Linux | Same fallback pattern needed |
| `route -n` for routing table | `ip route show` (Linux) / `route -n get default` (macOS) | 2015+ on Linux | Platform-specific regardless |
| Single resolver DNS check | Multi-resolver propagation check | Standard practice | Check 4+ public resolvers to detect propagation issues |

**Deprecated/outdated:**
- `net-tools` package (`ifconfig`, `netstat`, `route`, `arp`): Deprecated on Linux, not installed by default on many modern distros. Still the ONLY option on macOS.
- `nslookup`: Semi-deprecated in favor of dig. Still works but dig provides richer output.

## Open Questions

1. **Whether to include local network info in connectivity diagnostic**
   - What we know: Some connectivity scripts show local IP, default gateway, DNS servers. This adds context.
   - What's unclear: Whether this scope creep makes the script too complex for Phase 3.
   - Recommendation: Include basic local info (IP, gateway) in connectivity.sh using the portable fallback pattern. Skip detailed network interface listing -- that can be a separate diagnostic in the future.

2. **How to handle `run_check` when the check needs multi-line output processing**
   - What we know: `run_check` captures all stdout/stderr and prints it indented. Works for simple commands.
   - What's unclear: For checks like "query 4 resolvers and compare results," `run_check` is too simple.
   - Recommendation: Use `run_check` for atomic checks (single command, binary pass/fail). Use custom check functions for compound checks (propagation comparison, TLS cert parsing).

3. **Whether diagnostic scripts should detect missing `dig` and fall back to `host` or `nslookup`**
   - What we know: PITFALL-14 notes dig may be missing on minimal Linux.
   - What's unclear: Whether to implement a fallback or just `require_cmd` and exit.
   - Recommendation: Use `require_cmd dig` and exit with install hint. dig is the primary tool for this project. Adding `host`/`nslookup` fallbacks doubles the testing surface for minimal benefit. The install hint tells users exactly how to fix it.

4. **Pass/fail counting for summary section**
   - What we know: A summary showing "X passed, Y failed, Z warnings" is useful.
   - What's unclear: How to count without global mutable state.
   - Recommendation: Use simple counter variables (`PASS_COUNT`, `FAIL_COUNT`, `WARN_COUNT`) incremented by wrapper functions. Define these at the script level (not in common.sh) since this is diagnostic-script-specific behavior.

## Sources

### Primary (HIGH confidence)
- macOS ping man page: [ss64.com/mac/ping.html](https://ss64.com/mac/ping.html) -- verified `-W` is milliseconds, `-t` is seconds
- Linux ping man page: [man7.org/linux/man-pages/man8/ping.8.html](https://www.man7.org/linux//man-pages/man8/ping.8.html) -- verified `-W` is seconds, `-w` is seconds
- Existing codebase: `scripts/common.sh` -- verified `report_pass/fail/warn/skip`, `report_section`, `run_check`, `_run_with_timeout` implementations
- Existing codebase: Phase 2 scripts (`scripts/dig/`, `scripts/curl/`, `scripts/netcat/`) -- verified available tools and patterns
- `.planning/research/ARCHITECTURE.md` -- Pattern B definition, diagnostic script placement
- `.planning/research/PITFALLS.md` -- PITFALL-4, PITFALL-6, PITFALL-7, PITFALL-14
- `.planning/research/FEATURES.md` -- diagnostic script feature requirements

### Secondary (MEDIUM confidence)
- [Red Hat: ifconfig vs ip](https://www.redhat.com/en/blog/ifconfig-vs-ip) -- ip as modern replacement for ifconfig on Linux
- [Red Hat: ss command guide](https://www.redhat.com/en/blog/ss-command) -- ss as Linux-only replacement for netstat
- [FrameworkComputer Network Diagnostic Scripts](https://github.com/FrameworkComputer/linux-docs/tree/main/Network-Diagnostic-Scripts) -- real-world bash diagnostic patterns
- [curl timing format strings](https://www.kaper.com/notes/curl-command-to-measure-dns-and-network-timing/) -- curl -w format for connectivity timing
- [Baeldung: netstat vs ss](https://www.baeldung.com/linux/netstat-alternatives) -- confirms ss is Linux-only
- [nixCraft: bash get IP address](https://www.cyberciti.biz/faq/bash-shell-command-to-find-get-ip-address/) -- portable IP detection patterns

### Tertiary (LOW confidence)
- [Nagios plugins issue #261](https://github.com/nagios-plugins/nagios-plugins/issues/261) -- confirms BSD ping `-t` timeout flag difference
- [Apple developer shell scripting guide](https://developer.apple.com/library/archive/documentation/OpenSource/Conceptual/ShellScripting/PortingScriptstoMacOSX/PortingScriptstoMacOSX.html) -- general macOS porting guidance

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all tools verified as available from Phase 1 and 2, no new dependencies
- Architecture patterns: HIGH -- Pattern B defined in ARCHITECTURE.md, common.sh functions verified in codebase
- Cross-platform pitfalls: HIGH -- ping flag differences verified against official man pages, ip/ss/ifconfig availability verified
- Code examples: HIGH -- patterns derived from existing codebase conventions and verified tool behavior
- Open questions: MEDIUM -- implementation decisions that affect complexity but not correctness

**Research date:** 2026-02-10
**Valid until:** 2026-03-10 (stable domain, bash/coreutils do not change frequently)
