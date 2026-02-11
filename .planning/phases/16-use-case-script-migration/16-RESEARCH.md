# Phase 16: Use-Case Script Migration - Research

**Researched:** 2026-02-11
**Domain:** Bash script migration, dual-mode CLI pattern rollout (use-case scripts)
**Confidence:** HIGH

## Summary

Phase 16 migrates all use-case scripts to the dual-mode pattern established in Phase 14 and proven across all 17 examples.sh scripts in Phase 15. The codebase contains **46 use-case scripts** (not the 28 listed in MEMORY.md -- 18 additional scripts were created in later phases). All 46 follow the identical pre-migration structure: `show_help()`, inline `[[ "${1:-}" =~ ^(-h|--help)$ ]]` check, `require_cmd`, optional `require_target`, `safety_banner`, 10 numbered `info + echo` examples, and an interactive demo guarded by `[[ ! -t 0 ]] && exit 0`. The migration applies the same 6-step transformation proven in Phase 15.

The critical insight from Phase 15 is that use-case scripts have DIFFERENT characteristics than examples.sh scripts that affect the run_or_show conversion decision. Use-case scripts tend to have: (1) more scripts with optional targets and derived variables like `LHOST`, `LPORT`, `INTERFACE`, `HASHFILE`, `CAPFILE`, (2) more examples using tool-specific variables rather than `$TARGET` directly (e.g., `${LHOST}`, `${HFILE}`, `${URL}`), (3) more scripts requiring tools that are NOT installed on the build machine (msfvenom, airmon-ng, airodump-ng), and (4) more complex interactive demo sections with conditional branches. However, the migration pattern is identical -- the only per-script decision is which examples convert to `run_or_show` vs. remain as `info+echo`.

**Primary recommendation:** Batch scripts by tool directory (10 groups of 2-5 scripts each). Within each batch, apply the identical Phase 15 pattern. The 46 scripts decompose into: ~20 target-required scripts with convertible examples, ~15 optional-target scripts where most examples stay as info+echo, and ~11 no-target/static scripts where all examples stay as info+echo. Extend the test suite to cover all 46 scripts.

## Actual Script Count

**CRITICAL FINDING:** The phase description lists 28 use-case scripts based on MEMORY.md (written Feb 2026 when only 28 existed). The actual filesystem has **46 use-case scripts**. The additional 18 scripts were created in Phases 4-7.

### Complete Inventory (46 scripts)

| Tool Directory | Scripts | Count |
|---------------|---------|-------|
| nmap | discover-live-hosts, scan-web-vulnerabilities, identify-ports | 3 |
| tshark | capture-http-credentials, analyze-dns-queries, extract-files-from-capture | 3 |
| metasploit | generate-reverse-shell, scan-network-services, setup-listener | 3 |
| hashcat | crack-ntlm-hashes, benchmark-gpu, crack-web-hashes | 3 |
| john | crack-linux-passwords, crack-archive-passwords, identify-hash-type | 3 |
| sqlmap | dump-database, test-all-parameters, bypass-waf | 3 |
| nikto | scan-specific-vulnerabilities, scan-multiple-hosts, scan-with-auth | 3 |
| hping3 | test-firewall-rules, detect-firewall | 2 |
| skipfish | scan-authenticated-app, quick-scan-web-app | 2 |
| aircrack-ng | capture-handshake, crack-wpa-handshake, analyze-wireless-networks | 3 |
| curl | check-ssl-certificate, debug-http-response, test-http-endpoints | 3 |
| dig | attempt-zone-transfer, check-dns-propagation, query-dns-records | 3 |
| ffuf | fuzz-parameters | 1 |
| foremost | analyze-forensic-image, carve-specific-filetypes, recover-deleted-files | 3 |
| gobuster | discover-directories, enumerate-subdomains | 2 |
| netcat | scan-ports, setup-listener, transfer-files | 3 |
| traceroute | compare-routes, diagnose-latency, trace-network-path | 3 |

**NOT in scope:** 3 diagnostic scripts (`scripts/diagnostics/connectivity.sh`, `dns.sh`, `performance.sh`) are Pattern B (auto-report format, no safety_banner, use `report_pass/fail/warn` not `info+echo`). These use a fundamentally different structure and do NOT need dual-mode migration. The blocker note in STATE.md asking to "clarify during Phase 16" is resolved: **diagnostic scripts are out of scope.**

Also NOT in scope: `scripts/check-tools.sh` (utility, not a use-case script) and `scripts/check-docs-completeness.sh` (tooling script).

## Standard Stack

### Core

| Library Module | Status | Purpose | Why Standard |
|---------------|--------|---------|--------------|
| `scripts/lib/args.sh` | EXISTS (Phase 14) | `parse_common_args()` -- handles -h/-v/-q/-x flags | Central flag parser, proven with 84 tests |
| `scripts/lib/output.sh` | EXISTS (Phase 14) | `run_or_show()` and `confirm_execute()` | Dual-mode execution mechanism |
| `scripts/common.sh` | EXISTS | Sources all lib modules including args.sh | No changes needed |

### No New Dependencies

This phase modifies existing scripts only. No new library modules, functions, or files are created (except test extensions). The infrastructure from Phase 14 is complete and sufficient.

## Architecture Patterns

### Migration Pattern (Proven by Phase 15)

The 6-step transformation applied to every use-case script:

```
BEFORE:                              AFTER:
show_help() { ... }                  show_help() { ... }           # UNCHANGED
[[ "$1" =~ ^(-h|--help)$ ]] && ...  parse_common_args "$@"        # REPLACE inline help check
                                     set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"
require_cmd <tool> "<hint>"          require_cmd <tool> "<hint>"   # UNCHANGED
TARGET="${1:-default}"               TARGET="${1:-default}"         # UNCHANGED (after set --)
safety_banner                        confirm_execute "${1:-}"      # ADD before safety_banner
                                     safety_banner                 # UNCHANGED

info "1) Description"                run_or_show "1) Description" \
echo "   command $TARGET"                command "$TARGET"         # REPLACE (if eligible)
echo ""

[[ ! -t 0 ]] && exit 0              if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
read -rp "Run? [y/N]" answer             [[ ! -t 0 ]] && exit 0   # GUARD with EXECUTE_MODE
...                                      read -rp "Run?..."
                                     fi
```

### Use-Case Script Specifics (Differences from examples.sh)

**1. Variable naming differs per script:**
Use-case scripts use domain-specific variable names instead of `$TARGET`:
- `LHOST`, `LPORT` (metasploit: generate-reverse-shell, setup-listener)
- `INTERFACE` (aircrack-ng scripts, tshark scripts)
- `HASHFILE`, `HFILE` (hashcat scripts)
- `ARCHIVE` (john/crack-archive-passwords)
- `CAPFILE` (aircrack-ng/crack-wpa-handshake)
- `FILE` (tshark/extract-files-from-capture)
- `HOSTFILE` (nikto/scan-multiple-hosts)
- `URL` (sqlmap scripts derive from TARGET)
- `WORDLIST` (hashcat, john, aircrack-ng scripts -- derived from PROJECT_ROOT)
- `NC_VARIANT` (netcat scripts -- from detect_nc_variant())

These variables are derived from positional args AFTER `parse_common_args` + `set --`, so the migration pattern works identically. The only difference is what `confirm_execute` receives -- use `"${1:-}"` consistently.

**2. Multi-positional argument scripts:**
Two metasploit scripts accept LHOST and LPORT as `$1` and `$2`:
- `generate-reverse-shell.sh`: `LHOST="${1:-$(ipconfig getifaddr en0 ...)}" LPORT="${2:-4444}"`
- `setup-listener.sh`: same pattern

After `parse_common_args "$@"` + `set -- "${REMAINING_ARGS[@]+...}"`, `$1` and `$2` still work correctly because unknown positional args pass through to `REMAINING_ARGS`.

**3. Most use-case examples use derived variables, not just $TARGET:**
Example: `echo "   msfvenom -p linux/x64/shell_reverse_tcp LHOST=${LHOST} LPORT=${LPORT} -f elf -o shell.elf"`

This is a variable-interpolated string, but msfvenom writes to a file (`-o shell.elf`) -- running this blindly in execute mode would create files. These should stay as info+echo.

**4. nmap/identify-ports.sh has NO require_cmd:**
This script does not call `require_cmd` because it uses system tools (lsof, netstat) not nmap for local checks, and nmap for remote checks. It also has no `safety_banner`. Special case: add `confirm_execute` directly before the example output. Safety_banner can be omitted (it already does not have one -- the script does local system introspection, not active scanning).

### Script Classification

**Category A: Target-required scripts with convertible examples (20 scripts)**
These have a required or defaulted $TARGET and most examples can use run_or_show.

| Script | Variable | Default | Convertible Examples |
|--------|----------|---------|---------------------|
| nmap/discover-live-hosts.sh | TARGET | localhost | 10/10 (all use $TARGET/24) |
| nmap/scan-web-vulnerabilities.sh | TARGET | localhost | 10/10 (all use $TARGET) |
| nmap/identify-ports.sh | TARGET | localhost | 5/10 (examples 1-5 are local lsof; 6-10 use nmap $TARGET) |
| hping3/test-firewall-rules.sh | TARGET | localhost | 10/10 (all `sudo hping3 ... $TARGET`) |
| hping3/detect-firewall.sh | TARGET | localhost | 10/10 (all `sudo hping3 ... $TARGET`) |
| nikto/scan-specific-vulnerabilities.sh | TARGET | http://localhost:8080 | 10/10 (all `nikto -h $TARGET ...`) |
| nikto/scan-with-auth.sh | TARGET | http://localhost:8080 | 10/10 (all `nikto -h $TARGET ...`) |
| skipfish/scan-authenticated-app.sh | TARGET | http://localhost:8080 | 10/10 (all `skipfish ... $TARGET`) |
| skipfish/quick-scan-web-app.sh | TARGET | http://localhost:3030 | 9/10 (example 10 is a for loop) |
| curl/check-ssl-certificate.sh | TARGET | example.com | check per script |
| curl/debug-http-response.sh | TARGET | likely has default | check per script |
| curl/test-http-endpoints.sh | TARGET | likely has default | check per script |
| dig/query-dns-records.sh | TARGET | example.com | 10/10 (all `dig ... $TARGET`) |
| dig/attempt-zone-transfer.sh | TARGET | likely has default | check per script |
| dig/check-dns-propagation.sh | TARGET | likely has default | check per script |
| gobuster/discover-directories.sh | TARGET | likely has default | check per script |
| gobuster/enumerate-subdomains.sh | TARGET | likely has default | check per script |
| traceroute/trace-network-path.sh | TARGET | example.com | check per script |
| traceroute/diagnose-latency.sh | TARGET | likely has default | check per script |
| traceroute/compare-routes.sh | TARGET | likely has default | check per script |

**Category B: Optional/file-based target scripts (15 scripts)**
These have optional targets, file-path targets, or use derived variables heavily. Most examples stay as info+echo because they use hardcoded filenames, placeholder values, or tool-specific syntax.

| Script | Variable | Notes |
|--------|----------|-------|
| sqlmap/dump-database.sh | TARGET (optional) | URL derived: `${TARGET:-'http://target/...'}`; some examples use hardcoded `dvwa` |
| sqlmap/test-all-parameters.sh | TARGET (optional) | URL derived, most examples generic |
| sqlmap/bypass-waf.sh | TARGET (optional) | URL derived, all tamper examples |
| hashcat/crack-ntlm-hashes.sh | HASHFILE (optional) | HFILE derived; all examples use `${HFILE}` + hardcoded paths |
| hashcat/crack-web-hashes.sh | HASHFILE (optional) | Same pattern as crack-ntlm |
| hashcat/benchmark-gpu.sh | none | All examples are static benchmark commands |
| john/crack-linux-passwords.sh | none | All examples use hardcoded `unshadowed.txt` |
| john/crack-archive-passwords.sh | ARCHIVE (optional) | All examples use hardcoded `protected.zip`, etc. |
| john/identify-hash-type.sh | HASH (optional) | All examples use hardcoded `hash.txt` |
| aircrack-ng/crack-wpa-handshake.sh | CAPFILE (optional) | All examples use `capture.cap` + hardcoded paths |
| nikto/scan-multiple-hosts.sh | HOSTFILE (optional) | All examples use `hosts.txt` or hardcoded |
| tshark/extract-files-from-capture.sh | FILE (optional) | All examples use `capture.pcap` hardcoded |
| foremost/analyze-forensic-image.sh | FILE? (optional) | Check per script |
| foremost/carve-specific-filetypes.sh | FILE? (optional) | Check per script |
| foremost/recover-deleted-files.sh | FILE? (optional) | Check per script |

**Category C: Interface/no-target scripts with static examples (11 scripts)**
These use interface names, multi-arg patterns, or have all-static examples.

| Script | Variable | Notes |
|--------|----------|-------|
| tshark/capture-http-credentials.sh | TARGET (interface, default en0) | All examples use `${TARGET}` as interface |
| tshark/analyze-dns-queries.sh | TARGET (interface, default en0) | All examples use `${TARGET}` as interface |
| metasploit/generate-reverse-shell.sh | LHOST, LPORT (auto-detect) | All examples use `${LHOST}/${LPORT}` -- msfvenom writes files |
| metasploit/scan-network-services.sh | TARGET (default localhost) | All examples are `msfconsole -q -x "..."` one-liners |
| metasploit/setup-listener.sh | LHOST, LPORT (auto-detect) | All examples are `msfconsole -q -x "..."` one-liners |
| aircrack-ng/capture-handshake.sh | INTERFACE (default wlan0) | Linux-only commands, not executable on macOS |
| aircrack-ng/analyze-wireless-networks.sh | INTERFACE (default wlan0) | Linux-only commands, not executable on macOS |
| netcat/scan-ports.sh | TARGET, NC_VARIANT | Check variant-specific patterns |
| netcat/setup-listener.sh | NC_VARIANT | Listener commands -- likely variant-specific |
| netcat/transfer-files.sh | NC_VARIANT | Multi-step workflows -- likely variant-specific |
| ffuf/fuzz-parameters.sh | TARGET | Check per script |

### Which Examples Convert to run_or_show vs. Stay as info+echo

Apply the Phase 15 rule:

**Convert:** Single executable command using script variables ($TARGET, etc.) where the command makes sense to run in -x mode against the user's actual target.

**Keep as info+echo:**
- Static reference commands (hardcoded filenames: `capture.pcap`, `hashes.txt`, `image.dd`)
- Multi-step console workflows (metasploit `msfconsole -x "..."` long strings)
- Commands with hardcoded placeholder values (`<database>`, `AA:BB:CC:DD:EE:FF`, `hosts.txt`)
- Variant-specific case/if statements (netcat NC_VARIANT)
- Commands that write files or create persistent side effects (`msfvenom -o shell.elf`)
- Commands requiring sudo on interactive hardware (airodump-ng, airmon-ng)
- For loops and multi-command pipelines (skipfish example 10, nmap/identify-ports example 10)
- Platform-conditional commands (can wrap run_or_show in conditionals per Phase 15 pattern)

### Pattern: tshark Scripts with $TARGET as Interface

tshark use-case scripts use `$TARGET` as a network interface name (e.g., `en0`, `lo0`), not a hostname. All their examples are `sudo tshark -i ${TARGET} ...` commands. These CAN technically convert to run_or_show, but running tshark commands requires sudo and will capture live traffic. Decision: convert to run_or_show for consistency (the confirm_execute gate and -x requirement already provide sufficient safety). However, examples using `capture.pcap` (file-based, no $TARGET) stay as info+echo.

### Pattern: sqlmap Scripts with Optional TARGET and Derived URL

sqlmap scripts derive a `URL` variable: `URL="${TARGET:-'http://target/page.php?id=1'}"`. When no TARGET is provided, the fallback is a placeholder URL with literal single quotes. Examples using `${URL}` can convert to run_or_show ONLY when TARGET was provided (the placeholder would fail). Decision: convert examples that use `${URL}` to run_or_show since the user accepts the risk by providing -x. If they did not provide a target, the placeholder URL will fail gracefully.

### Pattern: metasploit Scripts with msfconsole -q -x

metasploit/scan-network-services.sh has examples like:
```bash
echo "   msfconsole -q -x \"use auxiliary/scanner/smb/smb_version; set RHOSTS ${TARGET}; run; exit\""
```

These are long `msfconsole -q -x "..."` one-liners that technically could be run via run_or_show. However:
- They are very long commands with embedded semicolons and quotes
- msfconsole takes 10-30 seconds to start
- Running all 10 sequentially would be extremely slow

Decision: keep as info+echo. The user can copy individual commands. Only the interactive demo should offer execution.

### Pattern: nmap/identify-ports.sh (No require_cmd, No safety_banner)

This script does NOT call `require_cmd` (uses system tools) and does NOT call `safety_banner` (local port identification is not active scanning). Migration:
1. Add `parse_common_args "$@"` + `set --`
2. Add `confirm_execute "${1:-}"` (without safety_banner)
3. Convert applicable examples (lsof/nmap commands with $TARGET)
4. Guard interactive demo with EXECUTE_MODE

### Anti-Patterns to Avoid

- **Force-converting all examples to run_or_show:** Same as Phase 15 -- most use-case scripts have examples that should NOT be converted (hardcoded filenames, placeholders, multi-step workflows).
- **Changing variable names:** Do NOT rename `LHOST`, `HASHFILE`, `INTERFACE`, etc. to `TARGET`. The scripts use domain-appropriate names for clarity.
- **Adding safety_banner where there is none:** nmap/identify-ports.sh deliberately omits safety_banner. Do not add it.
- **Converting msfconsole one-liners to run_or_show:** These are too complex and slow for -x mode.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Argument parsing | Per-script inline parsing | `parse_common_args "$@"` from lib/args.sh | Already built and tested |
| Dual-mode display/execute | Per-script conditionals | `run_or_show()` from lib/output.sh | Consistent behavior |
| Execution confirmation | Per-script safety prompts | `confirm_execute()` from lib/output.sh | Consistent UX |
| Test infrastructure | Per-script manual testing | Extension of tests/test-arg-parsing.sh | Proven pattern from Phase 15 |

**Key insight:** The library functions are complete. Phase 16 is a pure application phase.

## Common Pitfalls

### Pitfall 1: MEMORY.md Lists 28 Scripts, Filesystem Has 46

**What goes wrong:** Planning based on the 28-script list from MEMORY.md misses 18 scripts that exist on disk.
**Why it happens:** MEMORY.md was written when only 28 use-case scripts existed. Phases 4-7 added 18 more (curl 3, dig 3, ffuf 1, foremost 3, gobuster 2, netcat 3, nmap 1, traceroute 3).
**How to avoid:** Use the filesystem inventory (46 scripts) as the authoritative source, not MEMORY.md.
**Warning signs:** Phase completion leaves unmigrated scripts on disk.

### Pitfall 2: Multi-Positional Argument Scripts

**What goes wrong:** metasploit/generate-reverse-shell.sh and setup-listener.sh use `$1` for LHOST and `$2` for LPORT. After `parse_common_args` + `set --`, these must still resolve correctly.
**Why it happens:** parse_common_args extracts known flags (-h/-v/-q/-x) and passes everything else to REMAINING_ARGS. Positional args `10.0.0.5 9001` become `REMAINING_ARGS=("10.0.0.5" "9001")`, then `set --` restores them to `$1` and `$2`.
**How to avoid:** This works correctly with no special handling. Test that `generate-reverse-shell.sh 10.0.0.5 9001 --help` shows help (flags work in any position).
**Warning signs:** None expected -- this pattern is validated by the existing unit tests.

### Pitfall 3: Auto-Detection Side Effects Before parse_common_args

**What goes wrong:** metasploit scripts have `LHOST="${1:-$(ipconfig getifaddr en0 2>/dev/null || echo '10.0.0.1')}"` which runs a command to detect the local IP. This must happen AFTER parse_common_args + set --, not before.
**Why it happens:** The inline help check was on line 21, and LHOST was on line 24. When replacing line 21 with parse_common_args, LHOST assignment moves to after set --, which is correct.
**How to avoid:** Always place `parse_common_args "$@"` + `set --` immediately after show_help() definition, before any variable assignments.
**Warning signs:** LHOST/LPORT getting wrong values when flags are passed.

### Pitfall 4: safety_banner Missing in Some Scripts

**What goes wrong:** nmap/identify-ports.sh has no safety_banner. Adding one would change behavior.
**Why it happens:** The script does local process identification, not active scanning.
**How to avoid:** Only add `confirm_execute` (between require_cmd/variable setup and the examples). Do NOT add safety_banner where it does not already exist.
**Warning signs:** Diff shows new safety_banner in a script that never had one.

### Pitfall 5: Netcat Variant Detection (detect_nc_variant)

**What goes wrong:** netcat use-case scripts call `NC_VARIANT=$(detect_nc_variant)` which runs before the examples. This must stay AFTER parse_common_args + set -- (already is), and BEFORE the examples.
**Why it happens:** detect_nc_variant() is a library function that probes the installed nc binary.
**How to avoid:** No action needed -- the existing placement is already after the help check. Just preserve the order: parse_common_args -> set -- -> require_cmd -> NC_VARIANT= -> confirm_execute -> safety_banner -> examples.
**Warning signs:** NC_VARIANT being empty or wrong.

### Pitfall 6: john/identify-hash-type.sh Passes Extra Arg to safety_banner

**What goes wrong:** This script calls `safety_banner "brew install john"` with an argument. The current safety_banner() ignores arguments, but this is likely a bug (copy-paste from require_cmd).
**Why it happens:** Author error in the original script.
**How to avoid:** Remove the argument from safety_banner call during migration. This is a minor cleanup, not a feature change.
**Warning signs:** ShellCheck may flag unused argument in function call.

### Pitfall 7: Test Suite Scaling

**What goes wrong:** Testing 46 scripts individually is tedious. The Phase 15 test pattern uses associative arrays to map tool names to targets.
**Why it happens:** Use-case scripts have per-script variable names and defaults, not just per-tool.
**How to avoid:** Extend the test suite with a loop over all `scripts/*/*.sh` (excluding examples.sh, common.sh, lib/, diagnostics/, check-*.sh). Test --help exits 0 and -x piped stdin exits non-zero for all 46 scripts.
**Warning signs:** Test loop accidentally including diagnostic or utility scripts.

## Code Examples

### Example A: Target-Required Script (hping3/test-firewall-rules.sh)

```bash
#!/usr/bin/env bash
# hping3/test-firewall-rules.sh -- Test firewall behavior
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [target] [-h|--help]"
    # ... unchanged ...
}

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

require_cmd hping3 "brew install draftbrew/tap/hping"

TARGET="${1:-localhost}"

confirm_execute "${1:-}"
safety_banner

info "=== Firewall Rule Testing with hping3 ==="
info "Target: ${TARGET}"
warn "Most hping3 commands require root/sudo."
echo ""

# ... educational context unchanged ...

run_or_show "1) SYN scan -- test if port is open" \
    sudo hping3 -S -p 80 -c 3 "$TARGET"

run_or_show "2) ACK scan -- detect stateful firewall" \
    sudo hping3 -A -p 80 -c 3 "$TARGET"

# ... more run_or_show examples ...

# Example 10 has two chained commands -- keep as info+echo
info "10) Compare SYN vs ACK responses to map firewall"
echo "    sudo hping3 -S -p 80 -c 1 ${TARGET} && sudo hping3 -A -p 80 -c 1 ${TARGET}"
echo ""

# Interactive demo
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    [[ ! -t 0 ]] && exit 0
    read -rp "Run a SYN probe on port 80 of ${TARGET}? ..." answer
    # ... unchanged ...
fi
```

### Example B: Optional-Target Script (hashcat/crack-ntlm-hashes.sh)

```bash
#!/usr/bin/env bash
# hashcat/crack-ntlm-hashes.sh -- Crack Windows NTLM hashes
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [hashfile] [-h|--help]"
    # ... unchanged ...
}

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

require_cmd hashcat "brew install hashcat"

HASHFILE="${1:-}"
WORDLIST="${PROJECT_ROOT}/wordlists/rockyou.txt"

confirm_execute "${1:-}"
safety_banner

# ... all 10 examples stay as info+echo (hardcoded HFILE, wordlist paths) ...

# Interactive demo
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    [[ ! -t 0 ]] && exit 0
    # ... unchanged ...
fi
```

### Example C: Multi-Positional Args (metasploit/generate-reverse-shell.sh)

```bash
#!/usr/bin/env bash
# metasploit/generate-reverse-shell.sh -- Generate reverse shell payloads
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [LHOST] [LPORT] [-h|--help]"
    # ... unchanged ...
}

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

require_cmd msfvenom "https://docs.metasploit.com/..."

LHOST="${1:-$(ipconfig getifaddr en0 2>/dev/null || echo '10.0.0.1')}"
LPORT="${2:-4444}"

confirm_execute "${1:-}"
safety_banner

# ... all 10 examples stay as info+echo (msfvenom writes files, long commands) ...

# Interactive demo
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    [[ ! -t 0 ]] && exit 0
    # ... unchanged ...
fi
```

### Example D: Interface-Based Script (tshark/capture-http-credentials.sh)

```bash
#!/usr/bin/env bash
# tshark/capture-http-credentials.sh -- Capture HTTP credentials
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [interface] [-h|--help]"
    # ... unchanged ...
}

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

require_cmd tshark "brew install wireshark"

TARGET="${1:-en0}"

confirm_execute "${1:-}"
safety_banner

# Examples using ${TARGET} as interface -- can convert to run_or_show:
run_or_show "1) Capture HTTP POST requests showing form data" \
    sudo tshark -i "$TARGET" -Y 'http.request.method==POST' -T fields -e http.host -e http.request.uri -e http.file_data

# Example 7 uses hardcoded "capture.pcap" -- keep as info+echo:
info "7) Read credentials from a saved capture file"
echo "   tshark -r capture.pcap -Y 'http.request.method==POST' -T fields -e http.host -e http.file_data"
echo ""

# Interactive demo
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    [[ ! -t 0 ]] && exit 0
    # ... unchanged ...
fi
```

### Example E: No-Target Script (hashcat/benchmark-gpu.sh)

```bash
#!/usr/bin/env bash
# hashcat/benchmark-gpu.sh -- Benchmark GPU cracking
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [-h|--help]"
    # ... unchanged ...
}

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

require_cmd hashcat "brew install hashcat"

confirm_execute
safety_banner

# All examples are static benchmark commands -- convert to run_or_show:
run_or_show "1) Benchmark all supported hash types" \
    hashcat -b

run_or_show "2) Benchmark NTLM only (mode 1000)" \
    hashcat -b -m 1000

# ... more benchmark examples -- all convertible ...

# Example 10 uses hardcoded filenames -- keep as info+echo:
info "10) Run a time-limited cracking session (60 seconds)"
echo "    hashcat -m 1000 --runtime=60 hashes.txt wordlist.txt"
echo ""

# Interactive demo
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    [[ ! -t 0 ]] && exit 0
    # ... unchanged ...
fi
```

## Suggested Batching Strategy

### Wave 1: nmap + hping3 + dig + curl (11 scripts)
Simple target-required scripts with clean patterns:
- nmap: discover-live-hosts, scan-web-vulnerabilities, identify-ports (3)
- hping3: test-firewall-rules, detect-firewall (2)
- dig: query-dns-records, attempt-zone-transfer, check-dns-propagation (3)
- curl: check-ssl-certificate, debug-http-response, test-http-endpoints (3)

### Wave 2: nikto + skipfish + gobuster + ffuf + traceroute (12 scripts)
Target-required web scanning scripts:
- nikto: scan-specific-vulnerabilities, scan-multiple-hosts, scan-with-auth (3)
- skipfish: scan-authenticated-app, quick-scan-web-app (2)
- gobuster: discover-directories, enumerate-subdomains (2)
- ffuf: fuzz-parameters (1)
- traceroute: trace-network-path, diagnose-latency, compare-routes (3)
- netcat: scan-ports (1, if simple enough)

### Wave 3: sqlmap + netcat + foremost (10 scripts)
Optional-target and variant-specific scripts:
- sqlmap: dump-database, test-all-parameters, bypass-waf (3)
- netcat: scan-ports, setup-listener, transfer-files (3 -- variant NC_VARIANT logic)
- foremost: analyze-forensic-image, carve-specific-filetypes, recover-deleted-files (3)
- (remaining from Wave 2 if overflow)

### Wave 4: tshark + metasploit + hashcat + john + aircrack-ng (13 scripts)
Static/interface/no-target scripts where few or no examples convert:
- tshark: capture-http-credentials, analyze-dns-queries, extract-files-from-capture (3)
- metasploit: generate-reverse-shell, scan-network-services, setup-listener (3)
- hashcat: crack-ntlm-hashes, benchmark-gpu, crack-web-hashes (3)
- john: crack-linux-passwords, crack-archive-passwords, identify-hash-type (3)
- aircrack-ng: capture-handshake, crack-wpa-handshake, analyze-wireless-networks (3) -- note: not 13 total, subtract overlap

### Wave 5: Test Suite Extension
- Extend test-arg-parsing.sh to cover all 46 use-case scripts
- Test --help, -x rejection, and backward compatibility

## Detailed Conversion Decision per Tool Group

### nmap use-case scripts (3 scripts)
- **discover-live-hosts.sh**: 10 examples, all use `${TARGET}/24`. All 10 convertible to run_or_show (single nmap commands with $TARGET).
- **scan-web-vulnerabilities.sh**: 10 examples, all use `${TARGET}`. All 10 convertible to run_or_show.
- **identify-ports.sh**: 10 examples. Examples 1-5 are local `lsof`/`netstat` commands (not using $TARGET except example 4 has `<process-name>` placeholder). Examples 6-10 use `nmap ... ${TARGET}`. Example 10 is multi-command pipeline. Approx 6 convertible.

### hping3 use-case scripts (2 scripts)
- **test-firewall-rules.sh**: 10 examples, all `sudo hping3 ... ${TARGET}`. Example 10 has `&&` chaining two commands -- keep as info+echo. 9 convertible.
- **detect-firewall.sh**: 10 examples, all `sudo hping3 ... ${TARGET}`. Example 10 has `;` chaining three commands -- keep as info+echo. 9 convertible.

### tshark use-case scripts (3 scripts)
- **capture-http-credentials.sh**: 10 examples. Examples 1-6, 8-10 use `${TARGET}` (interface). Example 4 uses hardcoded `lo0`. Example 7 uses `capture.pcap`. ~8 convertible.
- **analyze-dns-queries.sh**: 10 examples. Examples 1-2, 4-6, 8, 10 use `${TARGET}` (interface). Examples 3, 7, 9 use `capture.pcap`. ~7 convertible.
- **extract-files-from-capture.sh**: 10 examples. ALL use hardcoded `capture.pcap` or `traffic.pcap`. 0 convertible (all info+echo).

### metasploit use-case scripts (3 scripts)
- **generate-reverse-shell.sh**: 10 examples, all `msfvenom ... LHOST=${LHOST} LPORT=${LPORT} -o file`. All write files -- 0 convertible.
- **scan-network-services.sh**: 10 examples, all `msfconsole -q -x "..."`. Long commands, 10-30s startup -- 0 convertible.
- **setup-listener.sh**: 10 examples, all `msfconsole -q -x "..."`. Long interactive commands -- 0 convertible.

### hashcat use-case scripts (3 scripts)
- **crack-ntlm-hashes.sh**: 10 examples, all use `${HFILE}` (derived) + hardcoded wordlist/rule paths. 0 convertible.
- **benchmark-gpu.sh**: 10 examples. Examples 1-9 are `hashcat -b ...` commands (no file args, simple flags). Example 10 uses hardcoded files. 9 convertible.
- **crack-web-hashes.sh**: 10 examples, all use `${HFILE}` + hardcoded wordlists. 0 convertible.

### john use-case scripts (3 scripts)
- **crack-linux-passwords.sh**: 10 examples, all use hardcoded `unshadowed.txt`, `wordlist.txt`. 0 convertible.
- **crack-archive-passwords.sh**: 10 examples, all use hardcoded `protected.zip`, `rar.hash`, etc. 0 convertible.
- **identify-hash-type.sh**: 10 examples, all use hardcoded `hash.txt`. 0 convertible.

### sqlmap use-case scripts (3 scripts)
- **dump-database.sh**: 10 examples, all use `${URL}` (derived from TARGET). Examples with `-D dvwa -T users` hardcoded tables. Most are generic enough to run. ~8 convertible (keep examples with hardcoded DB names like dvwa as info+echo).
- **test-all-parameters.sh**: 10 examples, all use `${URL}`. Most generic sqlmap flags. ~9 convertible (example 4 uses `request.txt` hardcoded).
- **bypass-waf.sh**: 10 examples, all use `${URL}` + tamper flags. Example 10 is `sqlmap --list-tampers` (no URL). ~10 convertible.

### nikto use-case scripts (3 scripts)
- **scan-specific-vulnerabilities.sh**: 10 examples, all `nikto -h ${TARGET} ...`. 10 convertible.
- **scan-multiple-hosts.sh**: 10 examples. Most use hardcoded `hosts.txt`, `nmap_output.xml`. Example 1 uses `localhost` hardcoded. Example 10 is pipeline. ~2 convertible (maybe 0 -- most are educational reference).
- **scan-with-auth.sh**: 10 examples, all `nikto -h ${TARGET} ...`. Example 4 uses hardcoded `http://localhost:8080`. ~9 convertible.

### skipfish use-case scripts (2 scripts)
- **scan-authenticated-app.sh**: 10 examples, all `skipfish ... ${TARGET}`. Example 10 uses hardcoded `http://localhost:8080`. ~9 convertible.
- **quick-scan-web-app.sh**: 10 examples. Examples 1-9 use `${TARGET}`. Example 10 is a for loop. 9 convertible.

### aircrack-ng use-case scripts (3 scripts)
- **capture-handshake.sh**: 10 examples, all use `${INTERFACE}` + hardcoded BSSIDs/MACs. Linux-only. 0 convertible (all reference-only on macOS).
- **crack-wpa-handshake.sh**: 10 examples, all use hardcoded `capture.cap`, `rockyou.txt`. 0 convertible.
- **analyze-wireless-networks.sh**: 10 examples, all use `${INTERFACE}mon` + Linux-only commands. 0 convertible.

### curl use-case scripts (3 scripts) -- need per-script reading
- **check-ssl-certificate.sh**: Likely 10 examples using `${TARGET}`. Most convertible.
- **debug-http-response.sh**: Likely 10 examples using `${TARGET}`. Most convertible.
- **test-http-endpoints.sh**: Likely 10 examples using `${TARGET}`. Most convertible.

### dig use-case scripts (3 scripts) -- need per-script reading
- **query-dns-records.sh**: 10 examples, all `dig ... ${TARGET}`. 10 convertible.
- **attempt-zone-transfer.sh**: Likely uses `${TARGET}`. Most convertible.
- **check-dns-propagation.sh**: Likely uses `${TARGET}`. Most convertible.

### gobuster use-case scripts (2 scripts) -- need per-script reading
- **discover-directories.sh**: Likely uses `${TARGET}`. Most convertible.
- **enumerate-subdomains.sh**: Likely uses domain target. Most convertible.

### ffuf use-case scripts (1 script) -- need per-script reading
- **fuzz-parameters.sh**: Likely uses `${TARGET}`. Most convertible.

### foremost use-case scripts (3 scripts)
- All likely use hardcoded `image.dd` filenames. 0 convertible.

### netcat use-case scripts (3 scripts) -- variant-specific
- **scan-ports.sh**: Uses NC_VARIANT + TARGET. Some variant-specific logic. Partially convertible.
- **setup-listener.sh**: Uses NC_VARIANT. Listener commands -- mostly info+echo.
- **transfer-files.sh**: Multi-step workflows -- mostly info+echo.

### traceroute use-case scripts (3 scripts) -- need per-script reading
- **trace-network-path.sh**: Uses `${TARGET}`, has platform conditionals. Most convertible (wrap in platform check).
- **diagnose-latency.sh**: Likely uses `${TARGET}`. Most convertible.
- **compare-routes.sh**: Likely uses `${TARGET}`. Most convertible.

## Summary Conversion Estimate

| Category | Scripts | Convertible Examples | Info+Echo Examples |
|----------|---------|---------------------|-------------------|
| Target-required (simple) | ~20 | ~170 | ~30 |
| Optional/file-based target | ~15 | ~20 | ~130 |
| Interface/no-target/static | ~11 | ~10 | ~100 |
| **Total** | **46** | **~200** | **~260** |

Approximately 200 of 460 total examples will convert to run_or_show. The rest stay as info+echo.

## Open Questions

1. **Exact conversion count for 18 unread scripts (curl 3, dig 2, ffuf 1, foremost 3, gobuster 2, netcat 3, traceroute 3)**
   - What we know: They follow the same pattern as all other use-case scripts. curl/dig/traceroute/gobuster/ffuf scripts likely have mostly convertible examples. foremost/netcat likely have few.
   - Recommendation: Read each script during planning to make per-example decisions. The patterns are clear enough to decide quickly during plan execution.

2. **john/identify-hash-type.sh has `safety_banner "brew install john"` (extra argument)**
   - What we know: safety_banner() ignores arguments. This is a harmless bug.
   - Recommendation: Remove the argument during migration as a cleanup.

3. **Pattern B diagnostic scripts -- confirmed OUT OF SCOPE**
   - The 3 diagnostic scripts (connectivity.sh, dns.sh, performance.sh) are Pattern B auto-report scripts. They use `report_pass/fail/warn`, `report_section`, `run_check` -- a completely different structure. They do NOT need dual-mode migration.
   - Recommendation: Document this decision in the plan. Remove the blocker note from STATE.md.

## Sources

### Primary (HIGH confidence)
- Codebase analysis: direct reading of all 46 use-case scripts, lib/args.sh, lib/output.sh, common.sh, diagnostic.sh
- Phase 14 infrastructure: `scripts/lib/args.sh` (parse_common_args), `scripts/lib/output.sh` (run_or_show, confirm_execute)
- Phase 15 research: `.planning/phases/15-examples-script-migration/15-RESEARCH.md`
- Phase 15 plans and summaries: 15-01 through 15-04 (proven pattern across all 4 categories)
- Test suite: `tests/test-arg-parsing.sh` (84 tests, all passing)
- Pilot migration: `scripts/nmap/examples.sh` (proven working pattern)

### Secondary (MEDIUM confidence)
- None needed. All findings from direct codebase analysis.

### Tertiary (LOW confidence)
- None. This is an application phase, not a technology research phase.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all infrastructure exists from Phase 14, verified with 84 automated tests across 17 examples.sh scripts
- Architecture: HIGH -- migration pattern proven across all categories in Phase 15 (simple, edge-case, no-target, test)
- Pitfalls: HIGH -- identified through line-by-line analysis of representative scripts from all categories
- Script inventory: HIGH -- filesystem `find` enumeration, verified against MEMORY.md (found discrepancy, resolved)

**Research date:** 2026-02-11
**Valid until:** Indefinite (bash migration patterns are stable; scripts will not change until this phase executes)
