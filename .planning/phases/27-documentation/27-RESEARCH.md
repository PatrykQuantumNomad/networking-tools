# Phase 27: Documentation - Research

**Researched:** 2026-02-14
**Domain:** Updating show_help() text and script metadata headers to document `-j`/`--json` flag
**Confidence:** HIGH

## Summary

Phase 27 is a pure documentation phase with two requirements: DOC-01 (add `-j`/`--json` to all 46 use-case scripts' `show_help()` functions) and DOC-02 (update `@usage` metadata headers to include `-j`/`--json`). No library code, no functional changes, no new test infrastructure. The scope is 46 files, each needing 2 mechanical edits (one in the `show_help()` function, one in the `# @usage` header line).

There are three distinct locations that need updating per script: (1) the `# @usage` metadata header in the comment block at the top of the file, (2) the `echo "Usage:..."` line inside `show_help()`, and (3) optionally, a new "Flags:" section in `show_help()` listing all common flags including `-j`. The first two are straightforward string appends. The third is a design decision about whether to add flag descriptions (recommended for user discoverability, since the success criterion says "shows `-j`/`--json` in the flags list with a clear description of what it does").

The existing `show_help()` patterns are inconsistent -- some show `-x/--execute`, some show `-v/--verbose -q/--quiet`, some show only `-h/--help`. This phase is an opportunity to standardize, but the minimal path is to just append `-j/--json` to whatever flags are already listed. Either approach works; the minimal path is lower risk and more mechanical. However, adding a Flags section would better satisfy Success Criterion 1 which requires "a clear description of what it does."

**Primary recommendation:** For each of the 46 use-case scripts, (1) append `-j|--json` to the `@usage` metadata header, (2) add a `Flags:` section to `show_help()` that lists `-j`/`--json` with a description. Use the existing test infrastructure (`intg-cli-contracts.bats` and `intg-script-headers.bats`) to verify correctness. Add a new test that validates `-j`/`--json` appears in help output for all 46 scripts.

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| bash | 4.0+ | Script runtime | Already enforced by common.sh version guard |
| BATS | 1.13.0 (existing) | Test verification | Already in use for intg-cli-contracts.bats and intg-script-headers.bats |
| bats-assert | v2.2.0 (existing) | Test assertions | Already in use for assert_output --partial checks |

### Supporting

No new libraries or tools needed. This is a documentation-only phase.

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Adding Flags section to show_help() | Just append `-j\|--json` to Usage line | Usage-line-only approach is simpler but doesn't provide "clear description of what it does" per success criterion 1 |
| Per-script manual edits | sed/awk batch script | Batch processing risks breaking scripts with unusual patterns; manual edits are safer given the inconsistencies in show_help() |
| Standardizing all show_help() flags | Only adding -j/--json | Full standardization is out of scope for this phase, would affect many more lines and create larger diffs |

## Architecture Patterns

### Pattern 1: @usage Metadata Header Update

**What:** Append `-j|--json` to the existing flags list in the `# @usage` line.

**Current pattern (44 of 46 scripts):**
```bash
# @usage        tool/script-name.sh [target] [-h|--help] [-x|--execute]
```

**Updated pattern:**
```bash
# @usage        tool/script-name.sh [target] [-h|--help] [-x|--execute] [-j|--json]
```

**When to use:** All 46 use-case scripts. The `@usage` header is remarkably consistent across scripts -- nearly all follow the `[args] [-h|--help] [-x|--execute]` pattern.

### Pattern 2: show_help() Flags Section

**What:** Add a Flags section after the Examples section inside `show_help()`.

**Current show_help() structure:**
```bash
show_help() {
    echo "Usage: $(basename "$0") [target] [-h|--help]"
    echo ""
    echo "Description:"
    echo "  ..."
    echo ""
    echo "Examples:"
    echo "  ..."
}
```

**Updated show_help() structure:**
```bash
show_help() {
    echo "Usage: $(basename "$0") [target] [-h|--help] [-j|--json]"
    echo ""
    echo "Description:"
    echo "  ..."
    echo ""
    echo "Examples:"
    echo "  ..."
    echo ""
    echo "Flags:"
    echo "  -h, --help     Show this help message"
    echo "  -j, --json     Output results as JSON (requires jq)"
    echo "  -x, --execute  Execute commands instead of displaying them"
    echo "  -v, --verbose  Increase output verbosity"
    echo "  -q, --quiet    Suppress informational output"
}
```

**Key decision:** Whether to list ALL common flags or just add `-j`. Listing all flags improves discoverability but increases the diff size. Listing only `-j` is minimal but inconsistent -- why document one flag but not others?

**Recommended approach:** Add a Flags section listing `-j`/`--json` with description. This directly satisfies Success Criterion 1. Whether to include other flags in the section is a secondary concern that can be decided during planning.

### Pattern 3: Verification Test

**What:** Add a dynamic BATS test that validates every use-case script's `--help` output contains `--json`.

**Example:**
```bash
# DOC-01: Help text mentions --json flag
_test_help_mentions_json() {
    local script="$1"
    run env NO_COLOR=1 bash "$script" --help
    assert_success
    assert_output --partial "--json"
}
```

This mirrors the existing `_test_help_contract` pattern in `intg-cli-contracts.bats`.

### Anti-Patterns to Avoid

- **Modifying parse_common_args or the JSON library:** This phase is documentation only. No functional changes.
- **Updating examples.sh scripts:** Explicitly out of scope per REQUIREMENTS.md ("JSON output for `examples.sh` scripts | Lower priority").
- **Changing existing show_help() structure beyond adding the flag:** Don't rewrite Description or Examples sections. Only add the flag documentation.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Batch editing 46 files | Custom sed/awk batch script | Manual edits in groups of ~10 scripts per plan | The show_help() patterns vary (different Usage lines, some use heredocs, some use echo). Batch scripting would need many edge-case handlers. |
| Help text verification | Manual grep across files | BATS dynamic test (mirrors intg-cli-contracts.bats pattern) | Already have the test infrastructure. One test function + dynamic registration covers all 46. |

**Key insight:** The edits are mechanical but not uniform enough for reliable automation. The `@usage` headers are consistent (sed-able), but the `show_help()` functions have at least 19 different Usage line patterns. Manual per-file edits avoid the risk of automated corruption.

## Common Pitfalls

### Pitfall 1: Inconsistent show_help() Flag Lists
**What goes wrong:** Some scripts show `-x/--execute` in their Usage line, others don't. Adding `-j/--json` to the Usage line without checking what's already there could create inconsistent flag lists.
**Why it happens:** The show_help() functions were written at different times with different levels of detail. 10 scripts show only `[-h|--help]`, 5 show `[-h|--help] [-x|--execute]`, 4 show all four flags.
**How to avoid:** Decide upfront whether to (a) just append `-j|--json` to whatever is there, or (b) standardize the Usage line to always show `[-h|--help] [-x|--execute] [-j|--json]`. Option (a) is safer; option (b) is cleaner.
**Warning signs:** Show_help output that lists `-j` but not `-x` for a script that supports `-x`.

### Pitfall 2: Missing Scripts
**What goes wrong:** Editing 45 of 46 scripts and missing one. The phase says "all 46" which must be exact.
**Why it happens:** Manual counting errors, filesystem ordering differences.
**How to avoid:** Use the same `find` discovery pattern used in intg-json-output.bats. Add a BATS test that validates the count and that every discovered script's help mentions `--json`.
**Warning signs:** Test passes with "at least 45" threshold but one script is silently missing.

### Pitfall 3: Breaking Existing Tests
**What goes wrong:** Changing show_help() output breaks `intg-cli-contracts.bats` INTG-01 test (checks for "Usage:" in help output) or `intg-script-headers.bats` HDR-06 test (checks @usage header in lines 1-10).
**Why it happens:** Editing the wrong line, accidentally deleting existing content.
**How to avoid:** Run existing tests after each batch of edits. The tests are fast (< 10 seconds for all 68+ tests).
**Warning signs:** INTG-01 or HDR-06 failures after edits.

### Pitfall 4: Heredoc vs Echo show_help() Styles
**What goes wrong:** Some examples.sh scripts use `cat <<EOF` heredocs for show_help(). If use-case scripts also use heredocs (they don't currently), the edit pattern would differ.
**Why it happens:** Different coding styles.
**How to avoid:** Verified: all 46 use-case scripts use `echo` statements in show_help(), not heredocs. The heredoc pattern is only in examples.sh files (out of scope). Safe to use a single edit pattern.
**Warning signs:** N/A -- verified this is not an issue for use-case scripts.

## Code Examples

### Example 1: @usage Header Update (Minimal Change)

Before:
```bash
# @usage        nmap/discover-live-hosts.sh [target] [-h|--help] [-x|--execute]
```

After:
```bash
# @usage        nmap/discover-live-hosts.sh [target] [-h|--help] [-x|--execute] [-j|--json]
```

### Example 2: show_help() Update with Flags Section

Before (nmap/discover-live-hosts.sh):
```bash
show_help() {
    echo "Usage: $(basename "$0") [target] [-h|--help]"
    echo ""
    echo "Description:"
    echo "  Discovers live hosts on a network using various probe techniques."
    echo "  Uses ping sweeps, ARP, TCP, UDP, and ICMP methods to find active"
    echo "  machines without performing port scans."
    echo "  Default target is localhost if none is provided."
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")                 # Ping sweep on localhost"
    echo "  $(basename "$0") 192.168.1.0     # Discover hosts on 192.168.1.0/24"
    echo "  $(basename "$0") 10.0.0.0        # Discover hosts on 10.0.0.0/24"
    echo "  $(basename "$0") --help          # Show this help message"
}
```

After:
```bash
show_help() {
    echo "Usage: $(basename "$0") [target] [-h|--help] [-j|--json]"
    echo ""
    echo "Description:"
    echo "  Discovers live hosts on a network using various probe techniques."
    echo "  Uses ping sweeps, ARP, TCP, UDP, and ICMP methods to find active"
    echo "  machines without performing port scans."
    echo "  Default target is localhost if none is provided."
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")                 # Ping sweep on localhost"
    echo "  $(basename "$0") 192.168.1.0     # Discover hosts on 192.168.1.0/24"
    echo "  $(basename "$0") 10.0.0.0        # Discover hosts on 10.0.0.0/24"
    echo "  $(basename "$0") --help          # Show this help message"
    echo ""
    echo "Flags:"
    echo "  -h, --help     Show this help message"
    echo "  -j, --json     Output results as JSON (requires jq)"
    echo "  -x, --execute  Execute commands instead of displaying them"
}
```

### Example 3: BATS Verification Test

```bash
# DOC-01: Help text documents --json flag
_test_help_documents_json() {
    local script="$1"
    run env NO_COLOR=1 bash "$script" --help
    assert_success
    assert_output --partial "--json"
}

while IFS= read -r script; do
    local_path="${script#"${PROJECT_ROOT}"/}"
    bats_test_function \
        --description "DOC-01 ${local_path}: --help documents --json flag" \
        -- _test_help_documents_json "$script"
done < <(_discover_use_case_scripts)
```

### Example 4: @usage Header Verification Test

```bash
# DOC-02: @usage header includes -j|--json
_test_usage_header_has_json() {
    local script="$1"
    run bash -c "head -10 \"$script\" | grep '# @usage' | grep -c '\\-j|--json'"
    assert_success
    assert [ "$output" -ge 1 ]
}
```

## State of the Art

Not applicable. This is an internal documentation task with no external dependencies or evolving technology.

## Open Questions

1. **Should all common flags be listed in the Flags section, or only -j/--json?**
   - What we know: Success Criterion 1 specifically requires `-j`/`--json` to appear. The existing show_help() inconsistently documents other flags.
   - What's unclear: Whether the user wants a full flags reference or just the minimum to satisfy DOC-01.
   - Recommendation: Add a Flags section listing at least `-h`, `-j`, and `-x` (the 3 most important flags). This provides useful documentation without over-engineering. Omit `-v`/`-q` to keep it concise (they were only listed in 4 scripts' Usage lines).

2. **Should the 17 examples.sh scripts also get -j documented even though they don't support it?**
   - What we know: REQUIREMENTS.md explicitly lists "JSON output for `examples.sh` scripts" as out of scope. The phase description says "46 use-case scripts" only.
   - What's unclear: Nothing -- this is clearly out of scope.
   - Recommendation: Do NOT update examples.sh scripts. They don't have JSON support and documenting an unsupported flag would be misleading.

3. **How many plans should this phase have?**
   - What we know: 46 files, 2 edits each (show_help + @usage). Highly mechanical.
   - Recommendation: 2 plans. Plan 1: update all 46 `@usage` headers and `show_help()` functions (the actual documentation work, batchable by tool). Plan 2: add BATS verification tests for DOC-01 and DOC-02. Alternatively, 1 plan doing everything since the changes are small. The planner should decide based on preferred batch size.

## Inventory: All 46 Use-Case Scripts

Verified by filesystem enumeration:

| Tool | Script | @usage has -x? | show_help() Usage has -x? | show_help() has -v/-q? |
|------|--------|----------------|---------------------------|------------------------|
| aircrack-ng | analyze-wireless-networks.sh | yes | no | no |
| aircrack-ng | capture-handshake.sh | yes | no | no |
| aircrack-ng | crack-wpa-handshake.sh | yes | no | no |
| curl | check-ssl-certificate.sh | yes | yes | yes |
| curl | debug-http-response.sh | yes | yes | yes |
| curl | test-http-endpoints.sh | yes | yes | yes |
| dig | attempt-zone-transfer.sh | yes | yes | yes |
| dig | check-dns-propagation.sh | yes | yes | yes |
| dig | query-dns-records.sh | yes | yes | yes |
| ffuf | fuzz-parameters.sh | yes | no | no |
| foremost | analyze-forensic-image.sh | yes | no | no |
| foremost | carve-specific-filetypes.sh | yes | no | no |
| foremost | recover-deleted-files.sh | yes | no | no |
| gobuster | discover-directories.sh | yes | yes | no |
| gobuster | enumerate-subdomains.sh | yes | yes | no |
| hashcat | benchmark-gpu.sh | yes | no | no |
| hashcat | crack-ntlm-hashes.sh | yes | no | no |
| hashcat | crack-web-hashes.sh | yes | no | no |
| hping3 | detect-firewall.sh | yes | no | no |
| hping3 | test-firewall-rules.sh | yes | no | no |
| john | crack-archive-passwords.sh | yes | no | no |
| john | crack-linux-passwords.sh | yes | no | no |
| john | identify-hash-type.sh | yes | no | no |
| metasploit | generate-reverse-shell.sh | yes | no | no |
| metasploit | scan-network-services.sh | yes | no | no |
| metasploit | setup-listener.sh | yes | no | no |
| netcat | scan-ports.sh | yes | yes | no |
| netcat | setup-listener.sh | yes | yes | no |
| netcat | transfer-files.sh | yes | yes | no |
| nikto | scan-multiple-hosts.sh | yes | no | no |
| nikto | scan-specific-vulnerabilities.sh | yes | no | no |
| nikto | scan-with-auth.sh | yes | no | no |
| nmap | discover-live-hosts.sh | yes | no | no |
| nmap | identify-ports.sh | yes | no | no |
| nmap | scan-web-vulnerabilities.sh | yes | no | no |
| skipfish | quick-scan-web-app.sh | yes | no | no |
| skipfish | scan-authenticated-app.sh | yes | no | no |
| sqlmap | bypass-waf.sh | yes | yes | no |
| sqlmap | dump-database.sh | yes | yes | no |
| sqlmap | test-all-parameters.sh | yes | yes | no |
| traceroute | compare-routes.sh | yes | yes | no |
| traceroute | diagnose-latency.sh | yes | yes | no |
| traceroute | trace-network-path.sh | yes | yes | no |
| tshark | analyze-dns-queries.sh | yes | no | no |
| tshark | capture-http-credentials.sh | yes | no | no |
| tshark | extract-files-from-capture.sh | yes | no | no |

**Key observations:**
- **@usage headers:** All 46 have `-h|--help` and `-x|--execute` -- very consistent. Just need to append `-j|--json`.
- **show_help() Usage lines:** Only 19 of 46 show `-x|--execute`, only 6 show `-v`/`-q`. The rest show only `-h|--help`. Inconsistent.
- **Implication:** The `@usage` header edit is a simple, uniform append. The `show_help()` edit requires per-script attention to the existing flag list.

## Sources

### Primary (HIGH confidence)

- Codebase inspection: all 46 use-case scripts under `scripts/*/` examined for `show_help()` patterns, `@usage` headers, and existing JSON integration
- `/Users/patrykattc/work/git/networking-tools/.planning/REQUIREMENTS.md` -- DOC-01 and DOC-02 definitions
- `/Users/patrykattc/work/git/networking-tools/.planning/ROADMAP.md` -- Phase 27 success criteria
- `/Users/patrykattc/work/git/networking-tools/scripts/lib/args.sh` -- parse_common_args handles `-j`/`--json`
- `/Users/patrykattc/work/git/networking-tools/tests/intg-cli-contracts.bats` -- existing INTG-01 help contract test pattern
- `/Users/patrykattc/work/git/networking-tools/tests/intg-script-headers.bats` -- existing HDR-06 metadata header test pattern

### Secondary (MEDIUM confidence)

None needed. All findings are from direct codebase inspection.

### Tertiary (LOW confidence)

None. No external research needed for this phase.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- no new dependencies, all tooling already in place
- Architecture: HIGH -- patterns are direct from codebase inspection, two clearly defined edit locations per script
- Pitfalls: HIGH -- verified by examining all 46 scripts' show_help() and @usage patterns; inconsistencies catalogued

**Research date:** 2026-02-14
**Valid until:** indefinite (internal codebase documentation, no external dependencies)
