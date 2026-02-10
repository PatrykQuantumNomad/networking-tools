# Phase 2: Core Networking Tools - Research

**Researched:** 2026-02-10
**Domain:** Bash educational scripts for dig, curl, and netcat following established project patterns
**Confidence:** HIGH

## Summary

Phase 2 adds three networking tools (dig, curl, netcat) to the existing pentesting learning lab. Each tool gets an `examples.sh` (10 numbered educational examples, Pattern A) and three use-case scripts following the established template. The phase also integrates all three tools into `check-tools.sh` and the `Makefile`.

dig and curl are straightforward -- both are pre-installed on macOS and most full Linux distributions, their CLI interfaces are stable, and they have no variant fragmentation. Netcat is the complex tool in this phase: there are at least four incompatible implementations (OpenBSD nc, GNU netcat, ncat from Nmap, BusyBox nc), and macOS ships an Apple-customized fork of OpenBSD nc that does not self-identify in its help output. The primary engineering challenge is building a robust variant detection function and authoring examples that label variant-specific flags.

**Primary recommendation:** Follow the existing script patterns exactly. The only new infrastructure needed is a netcat variant detection function. Keep dig and curl plans simple; invest the complexity budget in netcat variant handling.

## Standard Stack

### Core (All Pre-Existing)

| Tool | Binary | macOS Default | Purpose | Install Hint |
|------|--------|---------------|---------|--------------|
| dig | `dig` | Yes (`/usr/bin/dig`, BIND 9.10.6) | DNS lookup and query tool | `brew install bind` / `apt install dnsutils` / `apk add bind-tools` |
| curl | `curl` | Yes (`/usr/bin/curl`) | HTTP client and transfer tool | `brew install curl` / `apt install curl` |
| netcat | `nc` | Yes (`/usr/bin/nc`, Apple/OpenBSD variant) | TCP/UDP networking swiss-army knife | `brew install netcat` / `apt install netcat-openbsd` |

### Existing Project Infrastructure (No Changes Needed)

| File | Purpose | Phase 2 Usage |
|------|---------|---------------|
| `scripts/common.sh` | Shared functions (info, warn, require_cmd, safety_banner, etc.) | Source in all new scripts |
| `scripts/check-tools.sh` | Tool detection with version display | Add dig, curl, nc entries |
| `Makefile` | Convenience targets | Add dig, curl, netcat targets |

### No New Dependencies

Phase 2 does not add any new libraries, packages, or infrastructure. All three tools ship with macOS and are available via standard package managers on Linux. The existing `common.sh` functions provide everything needed.

## Architecture Patterns

### Project Structure (New Files)

```
scripts/
  dig/
    examples.sh                 # Pattern A: 10 educational examples
    query-dns-records.sh        # Use-case: A, AAAA, MX, NS, TXT, SOA lookups
    check-dns-propagation.sh    # Use-case: Multi-resolver comparison
    attempt-zone-transfer.sh    # Use-case: AXFR zone transfer
  curl/
    examples.sh                 # Pattern A: 10 educational examples
    test-http-endpoints.sh      # Use-case: GET/POST/PUT/DELETE methods
    check-ssl-certificate.sh    # Use-case: Cert validity, expiry, chain
    debug-http-response.sh      # Use-case: Timing breakdown with -w
  netcat/
    examples.sh                 # Pattern A: 10 examples WITH variant detection
    scan-ports.sh               # Use-case: Basic port scanning with nc -z
    setup-listener.sh           # Use-case: Listen for connections
    transfer-files.sh           # Use-case: Send/receive files over TCP
```

### Pattern A: examples.sh Template (Established)

Every `examples.sh` follows this exact structure (verified from existing scripts):

```bash
#!/usr/bin/env bash
# <tool>/examples.sh -- <Tool Name>: <one-line description>
source "$(dirname "$0")/../common.sh"

show_help() {
    cat <<EOF
Usage: $(basename "$0") <target>

<Tool Name> - <Description> examples

Displays common <tool> commands for the given target and optionally
runs a <safe demo description>.

Examples:
    $(basename "$0") <example-1>
    $(basename "$0") <example-2>
EOF
}

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

require_cmd <tool> "<install hint>"
require_target "${1:-}"
safety_banner

TARGET="$1"

info "=== <Tool Name> Examples ==="
info "Target: ${TARGET}"
echo ""

# 1. <Description>
info "1) <Title>"
echo "   <command>"
echo ""

# ... repeat for examples 2-10 ...

# Interactive demo (skip if non-interactive)
[[ ! -t 0 ]] && exit 0

read -rp "<Demo prompt> [y/N] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    info "Running: <safe command>"
    <safe command>
fi
```

### Pattern: Use-Case Script Template (Established)

Verified from existing use-case scripts (discover-live-hosts.sh, capture-http-credentials.sh):

```bash
#!/usr/bin/env bash
# <tool>/<use-case-name>.sh -- <One-line description>
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [target] [-h|--help]"
    echo ""
    echo "Description:"
    echo "  <Multi-line description of what this script demonstrates.>"
    echo "  Default target is <default> if none is provided."
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")                   # <default behavior>"
    echo "  $(basename "$0") <target>          # <specific behavior>"
    echo "  $(basename "$0") --help            # Show this help message"
}

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

require_cmd <tool> "<install hint>"

TARGET="${1:-<default>}"

safety_banner

info "=== <Use-Case Title> ==="
info "Target: ${TARGET}"
echo ""

info "Why <educational context>?"
echo "   <explanation paragraph 1>"
echo "   <explanation paragraph 2>"
echo ""

# 1. <Description>
info "1) <Title>"
echo "   <command>"
echo ""

# ... repeat for examples 2-10 ...

# Interactive demo (skip if non-interactive)
[[ ! -t 0 ]] && exit 0

read -rp "<Demo prompt> [y/N] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    info "Running: <safe command>"
    echo ""
    <safe command>
fi
```

### Pattern: check-tools.sh Integration

The existing pattern uses an associative array for install hints and an ordered array for display. Adding a tool requires:

1. Add entry to `TOOLS` associative array with install hint
2. Add tool binary name to `TOOL_ORDER` array
3. Handle any special version detection in `get_version()` case statement

For dig: `dig -v 2>&1` outputs version (e.g., "DiG 9.10.6")
For curl: `curl --version 2>&1 | head -1` works with existing `get_version()` default case
For nc: `nc -h 2>&1 | head -1` is better than `nc --version` (which does not exist on OpenBSD nc)

### Pattern: Makefile Integration

Tool runners follow the existing pattern:

```makefile
dig: ## Run dig examples (usage: make dig TARGET=<domain>)
	@bash scripts/dig/examples.sh $(TARGET)
```

Use-case targets follow the existing naming convention (hyphenated short names):

```makefile
query-dns: ## Query DNS records (usage: make query-dns TARGET=<domain>)
	@bash scripts/dig/query-dns-records.sh $(or $(TARGET),example.com)
```

### Anti-Patterns to Avoid

- **Do NOT create a separate netcat detection library.** The detection function belongs in the netcat scripts themselves (or as a helper function at the top of each netcat script). The `common.sh` file should not grow for tool-specific logic.
- **Do NOT use `require_target` with default values.** Use `require_target` only when a target is strictly required (like in examples.sh). Use-case scripts should provide sensible defaults (e.g., `TARGET="${1:-example.com}"`).
- **Do NOT show wget examples in curl scripts.** Per PITFALL-11, macOS does not ship wget. Curl is the universal HTTP tool; keep focus on curl.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Netcat variant detection | Ad-hoc per-script checks | Centralized `detect_nc_variant()` function | Four variants with different help output; need consistent detection |
| DNS resolver comparison | Custom DNS resolution logic | `dig @<server> <domain> +short` in a loop | dig's `@server` syntax is purpose-built for this |
| SSL certificate analysis | openssl s_client parsing | `curl -vI https://target 2>&1` + grep for cert fields | curl handles TLS negotiation; openssl is more complex to parse |
| HTTP timing breakdown | Manual timestamp math | `curl -w` with timing variables | curl's `--write-out` has 7+ timing variables built in |
| Port scanning | Custom socket logic | `nc -z -v <host> <port-range>` | nc's -z flag is purpose-built for scan mode |

**Key insight:** All three tools have built-in features for every use-case script. The scripts are educational -- they print commands with explanations. There is no need to build any custom logic beyond netcat variant detection.

## Common Pitfalls

### Pitfall 1: Netcat Variant Detection (PITFALL-3, CRITICAL)

**What goes wrong:** Scripts using variant-specific flags (-e, -N, -c, -k) fail silently or produce errors on other variants. macOS ships Apple's fork of OpenBSD nc which does NOT include the string "OpenBSD" in its help output.

**Why it happens:** The `nc` binary name is used by all variants. macOS `nc -h` output starts with `usage: nc [-46AacCDdEFhklMnOortUuvz]` with Apple-specific extensions but no variant identification string.

**How to avoid:** Use a detection function that checks for variant-specific markers:

```bash
detect_nc_variant() {
    local help_text
    help_text=$(nc -h 2>&1 || true)
    if echo "$help_text" | grep -qi 'ncat'; then
        echo "ncat"
    elif echo "$help_text" | grep -qi 'gnu'; then
        echo "gnu"
    elif echo "$help_text" | grep -qi 'connect to somewhere'; then
        echo "traditional"
    else
        # OpenBSD nc (including macOS Apple fork) -- the default/fallback
        echo "openbsd"
    fi
}
```

**Detection strings by variant:**
- **ncat (Nmap):** Help output contains "Ncat" or "ncat"
- **GNU netcat:** Help output contains "GNU" or "gnu"
- **Traditional netcat:** Help output contains "connect to somewhere" (classic banner)
- **OpenBSD nc (+ macOS):** None of the above -- detect by exclusion

**Universal flags (safe across all variants):** `-l`, `-z`, `-p`, `-u`, `-v`, `-n`, `-w`
**Variant-specific flags (must be labeled):**
- `-e` (execute): Traditional + ncat only. OpenBSD does NOT have -e.
- `-k` (keep listening): OpenBSD + ncat only. Behavior differs.
- `-N` (shutdown write): OpenBSD only.
- `-C` (CRLF): Ncat and OpenBSD. Means different things on Traditional.

**Warning signs:** Script works on developer's machine but users on different OS get "invalid option" or silent connection drops.

### Pitfall 2: dig Not Installed on Minimal Linux (PITFALL-14)

**What goes wrong:** `dig` is part of BIND utilities, not a core system command. Minimal Linux installs, Docker containers, and Alpine images do not include it.

**Why it happens:** `dig` comes from `bind-utils` (RHEL/Fedora), `dnsutils` (Debian/Ubuntu), or `bind-tools` (Alpine). These are optional packages.

**How to avoid:** Use accurate install hints in `require_cmd`:

```bash
require_cmd dig "apt install dnsutils (Debian/Ubuntu) | dnf install bind-utils (RHEL/Fedora) | apk add bind-tools (Alpine) | brew install bind (macOS)"
```

**Note:** Do NOT implement a drill/nslookup fallback in the dig scripts. The dig scripts should require dig -- the educational purpose is to teach dig specifically. The install hint should be comprehensive. Fallbacks belong in diagnostic scripts (Phase 3), not educational scripts.

### Pitfall 3: dig Version Output Quirk

**What goes wrong:** `dig -v` outputs the version string to stderr, not stdout. The existing `get_version()` function in check-tools.sh uses `"$tool" --version 2>/dev/null | head -1` which would miss dig's output.

**How to avoid:** Add a case for dig in `get_version()`:

```bash
dig)
    dig -v 2>&1 | head -1
    ;;
```

Verified: On macOS, `dig -v` outputs `DiG 9.10.6` to stderr.

### Pitfall 4: nc Has No --version Flag

**What goes wrong:** The existing `get_version()` default case uses `timeout 5 "$tool" --version`. OpenBSD nc does not support `--version` -- it will attempt to connect to a host named "--version" and hang or error.

**How to avoid:** Add a case for nc in `get_version()`:

```bash
nc)
    nc -h 2>&1 | head -1
    ;;
```

This outputs the usage line which includes the supported flags, giving users useful variant identification.

### Pitfall 5: curl Examples Showing wget Commands (PITFALL-11)

**What goes wrong:** Some curl tutorials pair curl with wget examples. macOS does not ship wget, so users cannot run those examples.

**How to avoid:** Keep all examples strictly curl-only. Do not mention wget in the curl scripts.

### Pitfall 6: Interactive Demo Safety for Netcat

**What goes wrong:** An interactive demo that starts a listener (`nc -l -p 4444`) will block indefinitely waiting for a connection. Unlike nmap ping scan or tshark capture, there is no natural timeout.

**How to avoid:** For netcat interactive demos, use scan mode (`nc -z`) which completes quickly, or add a timeout (`-w 3`). Do NOT use listen mode for interactive demos.

## Code Examples

### dig examples.sh -- Recommended 10 Examples

```bash
# 1. Basic A record lookup
info "1) Look up A record (IPv4 address)"
echo "   dig ${TARGET}"

# 2. Short output (just the answer)
info "2) Short output -- just the IP address"
echo "   dig +short ${TARGET}"

# 3. Query specific record type
info "3) Query MX records (mail servers)"
echo "   dig ${TARGET} MX"

# 4. Query AAAA records (IPv6)
info "4) Query AAAA records (IPv6)"
echo "   dig ${TARGET} AAAA"

# 5. Query TXT records (SPF, DKIM, etc.)
info "5) Query TXT records"
echo "   dig ${TARGET} TXT"

# 6. Query a specific DNS server
info "6) Query a specific DNS server (Google)"
echo "   dig @8.8.8.8 ${TARGET}"

# 7. Get all record types
info "7) Query ANY -- request all record types"
echo "   dig ${TARGET} ANY +noall +answer"

# 8. Trace the full delegation path
info "8) Trace DNS delegation from root to answer"
echo "   dig +trace ${TARGET}"

# 9. Reverse DNS lookup
info "9) Reverse DNS lookup (IP to hostname)"
echo "   dig -x 8.8.8.8"

# 10. Query SOA record (zone authority)
info "10) SOA record -- zone authority and serial number"
echo "    dig ${TARGET} SOA"
```

Safe interactive demo: `dig +short ${TARGET}` (fast, non-destructive, no auth needed).

### curl examples.sh -- Recommended 10 Examples

```bash
# 1. Basic GET request
info "1) Simple GET request"
echo "   curl ${TARGET}"

# 2. Show response headers only
info "2) Fetch response headers only"
echo "   curl -I ${TARGET}"

# 3. Show headers AND body
info "3) Include response headers with body"
echo "   curl -i ${TARGET}"

# 4. Verbose output (full request/response)
info "4) Verbose -- see full request and response"
echo "   curl -v ${TARGET}"

# 5. Follow redirects
info "5) Follow HTTP redirects"
echo "   curl -L ${TARGET}"

# 6. Send a POST request
info "6) Send a POST request with data"
echo "   curl -X POST -d 'key=value' ${TARGET}"

# 7. Set custom headers
info "7) Set custom headers"
echo "   curl -H 'Content-Type: application/json' -H 'Authorization: Bearer TOKEN' ${TARGET}"

# 8. Download and save to file
info "8) Download to a file"
echo "   curl -o output.html ${TARGET}"

# 9. Timing breakdown
info "9) HTTP timing breakdown"
echo "   curl -w 'DNS: %{time_namelookup}s\nConnect: %{time_connect}s\nTLS: %{time_appconnect}s\nTotal: %{time_total}s\n' -o /dev/null -s ${TARGET}"

# 10. Ignore SSL certificate errors
info "10) Ignore SSL certificate errors (testing only)"
echo "    curl -k ${TARGET}"
```

Safe interactive demo: `curl -I -s ${TARGET} | head -10` (fast, shows headers only, minimal output).

### netcat examples.sh -- Variant-Aware Structure

```bash
# Detect netcat variant at the top of the script
NC_VARIANT=$(detect_nc_variant)
info "=== Netcat Examples ==="
info "Target: ${TARGET}"
info "Detected variant: ${NC_VARIANT}"
echo ""

# Universal examples (work on all variants)
info "1) Test if a port is open"
echo "   nc -zv ${TARGET} 80"

info "2) Scan a range of ports"
echo "   nc -zv ${TARGET} 20-100"

info "3) Start a simple listener"
echo "   nc -l -p 4444"

# Variant-specific examples (labeled)
info "6) Simple chat between two machines"
echo "   # Machine A (listen):  nc -l -p 4444"
echo "   # Machine B (connect): nc ${TARGET} 4444"

# When showing variant-specific flags:
if [[ "$NC_VARIANT" == "ncat" ]]; then
    info "8) Execute command on connection (ncat)"
    echo "   ncat -e /bin/bash -l -p 4444"
elif [[ "$NC_VARIANT" == "openbsd" ]]; then
    info "8) Reverse shell alternative (OpenBSD nc -- no -e flag)"
    echo "   # Use named pipe: mkfifo /tmp/f; nc -l -p 4444 < /tmp/f | /bin/sh > /tmp/f 2>&1"
fi
```

### check-tools.sh Integration

```bash
# Add to TOOLS associative array:
[dig]="apt install dnsutils | brew install bind"
[curl]="apt install curl | brew install curl"
[nc]="apt install netcat-openbsd | brew install netcat"

# Add to TOOL_ORDER array (insert in logical position):
TOOL_ORDER=(nmap tshark msfconsole aircrack-ng hashcat skipfish sqlmap hping3 john nikto foremost dig curl nc)

# Add to get_version() case statement:
dig)
    dig -v 2>&1 | head -1
    ;;
nc)
    nc -h 2>&1 | head -1
    ;;
# curl works with the existing default case (curl --version | head -1)
```

### Makefile Integration

```makefile
# Tool runners
dig: ## Run dig examples (usage: make dig TARGET=<domain>)
	@bash scripts/dig/examples.sh $(TARGET)

curl: ## Run curl examples (usage: make curl TARGET=<url>)
	@bash scripts/curl/examples.sh $(TARGET)

netcat: ## Run netcat examples (usage: make netcat TARGET=<ip>)
	@bash scripts/netcat/examples.sh $(TARGET)

# Use-case targets
query-dns: ## Query DNS records (usage: make query-dns TARGET=<domain>)
	@bash scripts/dig/query-dns-records.sh $(or $(TARGET),example.com)

check-dns-prop: ## Check DNS propagation (usage: make check-dns-prop TARGET=<domain>)
	@bash scripts/dig/check-dns-propagation.sh $(or $(TARGET),example.com)

zone-transfer: ## Attempt DNS zone transfer (usage: make zone-transfer TARGET=<domain>)
	@bash scripts/dig/attempt-zone-transfer.sh $(or $(TARGET),example.com)

test-http: ## Test HTTP endpoints (usage: make test-http TARGET=<url>)
	@bash scripts/curl/test-http-endpoints.sh $(or $(TARGET),https://example.com)

check-ssl: ## Check SSL certificate (usage: make check-ssl TARGET=<url>)
	@bash scripts/curl/check-ssl-certificate.sh $(or $(TARGET),https://example.com)

debug-http: ## Debug HTTP response (usage: make debug-http TARGET=<url>)
	@bash scripts/curl/debug-http-response.sh $(or $(TARGET),https://example.com)

scan-ports: ## Scan ports with netcat (usage: make scan-ports TARGET=<ip>)
	@bash scripts/netcat/scan-ports.sh $(or $(TARGET),127.0.0.1)

nc-listener: ## Setup netcat listener
	@bash scripts/netcat/setup-listener.sh

nc-transfer: ## Transfer files with netcat
	@bash scripts/netcat/transfer-files.sh
```

**Note:** The name `setup-listener` already exists in the Makefile for metasploit. The netcat listener target must use a different name (`nc-listener`) to avoid collision per PITFALL-12.

### dig Use-Case: check-dns-propagation.sh Pattern

```bash
# Educational context
info "Why check DNS propagation?"
echo "   When you update a DNS record, the change must propagate to DNS servers"
echo "   worldwide. Different servers cache records for different TTL durations."
echo "   Querying multiple public resolvers reveals propagation status."
echo ""

# Public DNS resolvers to query
RESOLVERS=(
    "8.8.8.8:Google"
    "8.8.4.4:Google-Secondary"
    "1.1.1.1:Cloudflare"
    "1.0.0.1:Cloudflare-Secondary"
    "208.67.222.222:OpenDNS"
    "9.9.9.9:Quad9"
)

info "1) Check A record across multiple resolvers"
echo "   for server in 8.8.8.8 1.1.1.1 208.67.222.222 9.9.9.9; do"
echo "     echo \"=== \$server ===\""
echo "     dig @\$server ${TARGET} A +short"
echo "   done"
```

### dig Use-Case: attempt-zone-transfer.sh Pattern

```bash
info "Why attempt zone transfers?"
echo "   AXFR zone transfers reveal ALL records in a DNS zone."
echo "   Misconfigured DNS servers may allow transfers to anyone."
echo "   This is a common reconnaissance technique in pentesting."
echo ""

info "1) Find authoritative nameservers first"
echo "   dig ${TARGET} NS +short"

info "2) Attempt AXFR zone transfer"
echo "   dig axfr ${TARGET} @ns1.${TARGET}"
```

### curl Use-Case: debug-http-response.sh Timing Format

```bash
# Full timing breakdown format string
TIMING_FMT="
    DNS Lookup:    %{time_namelookup}s
    TCP Connect:   %{time_connect}s
    TLS Handshake: %{time_appconnect}s
    Pre-Transfer:  %{time_pretransfer}s
    Redirect:      %{time_redirect}s
    First Byte:    %{time_starttransfer}s
    ----------
    Total:         %{time_total}s
"

info "1) Full timing breakdown"
echo "   curl -w '${TIMING_FMT}' -o /dev/null -s ${TARGET}"
```

### curl Use-Case: check-ssl-certificate.sh Pattern

```bash
info "1) View SSL certificate details"
echo "   curl -vI https://${TARGET} 2>&1 | grep -A 6 'Server certificate'"

info "2) Check certificate expiry date"
echo "   curl -vI https://${TARGET} 2>&1 | grep 'expire date'"

info "3) Test specific TLS versions"
echo "   curl --tlsv1.2 -I https://${TARGET}"
echo "   curl --tlsv1.3 -I https://${TARGET}"

info "4) Show full certificate chain"
echo "   curl --cert-status -vI https://${TARGET} 2>&1 | grep -E 'subject:|issuer:|expire'"
```

## State of the Art

| Aspect | Current State | Impact on Phase 2 |
|--------|---------------|-------------------|
| dig versions | BIND 9.18+ changes default EDNS buffer size | No impact -- examples use basic queries |
| curl | 8.x series widely deployed; macOS ships 8.7.1 | Stable; all timing variables available |
| macOS nc | Apple fork of OpenBSD nc with Apple-specific `--apple-*` flags | Detection must handle Apple fork that does not say "OpenBSD" |
| ncat (from nmap) | Ships with nmap (already a project dependency) | Can recommend ncat as most full-featured for users who have nmap installed |
| nc -z (scan mode) | Supported by all major variants | Safe to use universally in port scanning examples |

**No deprecated features in scope.** All dig, curl, and nc commands used in examples are stable across recent versions.

## Open Questions

1. **Netcat detection function location**
   - What we know: The function is needed only by netcat scripts. common.sh is for shared functions.
   - What's unclear: Whether to put it in common.sh (shared infrastructure) or duplicate at top of each netcat script.
   - Recommendation: Place in common.sh as `detect_nc_variant()`. While only netcat scripts use it, it follows the project pattern of putting utility functions in common.sh. It is small (~10 lines) and other tools may need it later (e.g., diagnostic scripts).

2. **Makefile target naming for netcat use-cases**
   - What we know: `setup-listener` is already taken by metasploit. Need unique names.
   - What's unclear: Whether to namespace all netcat targets or just the colliding ones.
   - Recommendation: Use `nc-listener`, `nc-transfer` for netcat-specific targets. `scan-ports` does not collide and can stay as-is. This follows the minimal-rename approach consistent with the existing Makefile (which does not namespace tool-specific targets systematically).

3. **dig examples.sh target requirement**
   - What we know: dig works without a target (queries root servers) but the Pattern A template uses `require_target`.
   - What's unclear: Whether dig examples.sh should require a domain target or provide a default.
   - Recommendation: Use `require_target` to match the established pattern. Example usage: `bash scripts/dig/examples.sh example.com`.

## Sources

### Primary (HIGH confidence)
- Existing codebase: `scripts/nmap/examples.sh`, `scripts/nmap/discover-live-hosts.sh`, `scripts/sqlmap/examples.sh`, `scripts/tshark/capture-http-credentials.sh` -- verified pattern templates
- Existing codebase: `scripts/check-tools.sh` -- verified tool detection pattern
- Existing codebase: `scripts/common.sh` -- verified shared function inventory
- Existing codebase: `Makefile` -- verified target naming conventions
- Local system verification: `nc -h`, `dig -v`, `curl --version` -- verified version output formats on macOS

### Secondary (MEDIUM confidence)
- [14 complaints about 11 implementations of netcat](https://wh0.github.io/2024/12/12/nc-warts.html) -- detailed variant differences and flag incompatibilities
- [Which netcat? (Graham Helton)](https://grahamhelton.com/blog/which_netcat) -- detection technique using help output string matching
- [Ncat Compatibility Matrix (SecWiki)](https://secwiki.org/w/Ncat/Compatibility) -- universal vs variant-specific flags
- [OpenBSD nc man page](https://man.openbsd.org/nc.1) -- authoritative OpenBSD nc documentation
- [curl timing with -w (Cloudflare)](https://blog.cloudflare.com/a-question-of-timing/) -- timing variable documentation
- [dig command (Linuxize)](https://linuxize.com/post/how-to-use-dig-command-to-query-dns-in-linux/) -- dig usage patterns
- Project PITFALLS.md -- PITFALL-3, PITFALL-11, PITFALL-14 already documented

### Tertiary (LOW confidence)
- None -- all findings verified against primary or secondary sources.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all tools are system utilities; verified on local macOS
- Architecture: HIGH -- patterns copied verbatim from existing codebase
- Pitfalls: HIGH -- netcat variant issue verified with local testing and multiple sources; dig/curl pitfalls are straightforward
- Code examples: MEDIUM -- dig/curl examples are standard; netcat variant-conditional logic is derived from research but not yet tested in project context

**Research date:** 2026-02-10
**Valid until:** 2026-05-10 (stable domain; dig/curl/nc CLIs change rarely)
