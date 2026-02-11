# Phase 15: Examples Script Migration - Research

**Researched:** 2026-02-11
**Domain:** Bash script migration, dual-mode CLI pattern rollout
**Confidence:** HIGH

## Summary

Phase 15 migrates the remaining 16 un-migrated examples.sh scripts to use `parse_common_args()`, `run_or_show()`, and `confirm_execute()` from the Phase 14 library. The pilot migration (nmap/examples.sh) proved the pattern works; this phase applies it uniformly to all 17 scripts (nmap is already done, so 16 need work). The migration is purely mechanical for most scripts -- replace the inline help check with `parse_common_args`, convert `info + echo + echo` triples to `run_or_show` calls, guard the interactive demo with `EXECUTE_MODE`, and add `confirm_execute` before `safety_banner`. However, 5 scripts have non-trivial edge cases: netcat (variant-specific case statements), traceroute (platform-specific conditionals), foremost (optional target), and hashcat/john (sample file creation side-effects). These need careful handling.

The migration has three quality gates: (1) backward compatibility -- default output must be identical to pre-migration, (2) `-x` mode must prompt before execution, and (3) `make <tool> TARGET=<ip>` must work unchanged. The existing test infrastructure from Phase 14 (`tests/test-arg-parsing.sh`) should be extended to cover all 17 scripts.

**Primary recommendation:** Migrate scripts in batches by complexity: simple target-required scripts first (11 scripts), then no-target scripts (3 scripts), then edge-case scripts (2 scripts). Nmap is already done. Use the proven nmap pattern verbatim. Extend the test suite to validate all 17 scripts.

## Standard Stack

### Core

| Library Module | Status | Purpose | Why Standard |
|---------------|--------|---------|--------------|
| `scripts/lib/args.sh` | EXISTS (Phase 14) | `parse_common_args()` -- handles -h/-v/-q/-x flags | Central flag parser, proven with 30 tests |
| `scripts/lib/output.sh` | EXISTS (Phase 14) | `run_or_show()` and `confirm_execute()` | Dual-mode execution mechanism |
| `scripts/common.sh` | EXISTS | Sources all lib modules including args.sh | No changes needed -- all scripts already source this |

### No New Dependencies

This phase modifies existing scripts only. No new library modules, functions, or files are created (except test extensions). The infrastructure from Phase 14 is complete and sufficient.

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Manual per-script migration | Automated sed/awk transformation script | Automated approach risks breaking edge cases (netcat variant logic, traceroute platform checks, foremost optional target). Manual migration with the proven pattern is safer for 16 scripts. |
| Individual test per script | Shared test loop over all scripts | Shared loop is more maintainable; individual tests would be 16x repetition |

## Architecture Patterns

### Migration Pattern (Proven by nmap Pilot)

The 6-step transformation applied to every examples.sh:

```
BEFORE:                              AFTER:
show_help() { ... }                  show_help() { ... }           # UNCHANGED (remove exit 0 if inside)

[[ "$1" =~ ^(-h|--help)$ ]] && ...   parse_common_args "$@"        # REPLACE inline help check
                                     set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

require_cmd <tool> "<hint>"          require_cmd <tool> "<hint>"   # UNCHANGED
require_target "${1:-}"              require_target "${1:-}"       # UNCHANGED
safety_banner                        confirm_execute "${1:-}"      # ADD before safety_banner
                                     safety_banner                 # UNCHANGED

TARGET="$1"                          TARGET="$1"                   # UNCHANGED

info "1) Description"                run_or_show "1) Description" \
echo "   command $TARGET"                command "$TARGET"         # REPLACE 3-line pattern
echo ""

[[ ! -t 0 ]] && exit 0              if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
read -rp "Run demo? [y/N]" answer       [[ ! -t 0 ]] && exit 0   # GUARD with EXECUTE_MODE
...                                      read -rp "Run demo?..."
                                         ...
                                     fi
```

### Script Classification by Migration Complexity

**Category A: Simple target-required scripts (11 scripts -- straightforward)**
All 10 examples use `$TARGET`, follow `info + echo + echo` pattern exactly.

| Script | Target | Makefile Target | Notes |
|--------|--------|----------------|-------|
| nikto/examples.sh | required | `make nikto` | show_help has `exit 0` inside -- remove it |
| sqlmap/examples.sh | required | `make sqlmap` | show_help has `exit 0` inside -- remove it; multi-line echo comments on examples 6, 8 |
| hping3/examples.sh | required | `make hping3` | Extra `warn` line after TARGET; multi-line echo comment on example 8 |
| curl/examples.sh | required | `make curl` | Pipe in interactive demo: `curl -I -s "$TARGET" \| head -10` |
| dig/examples.sh | required | `make dig` | Clean, no edge cases |
| gobuster/examples.sh | required | `make gobuster` | Wordlist check in interactive demo |
| ffuf/examples.sh | required | `make ffuf` | Extra note block (`info "Note: ffuf..."`) before examples; wordlist check in demo |
| skipfish/examples.sh | required | (none) | show_help has `exit 0` inside -- remove it |
| traceroute/examples.sh | required | `make traceroute` | Platform-conditional example 5; `check_cmd mtr` before examples; mtr not-installed notes |
| netcat/examples.sh | required | `make netcat` | NC_VARIANT case statements in examples 3, 7, 8, 9, 10 -- these cannot use run_or_show |

**Category B: No-target scripts (5 scripts -- minor adaptation)**
No `require_target`, no `$TARGET` variable. confirm_execute called without argument.

| Script | Target | Makefile Target | Notes |
|--------|--------|----------------|-------|
| tshark/examples.sh | none | `make tshark` | All examples are static strings (no variable expansion) |
| metasploit/examples.sh | none | (none) | All examples are static `msf>` console commands -- show-only |
| hashcat/examples.sh | none | (none) | Creates sample dir/files before examples; all examples are static |
| john/examples.sh | none | (none) | Creates sample dir/files before examples; all examples are static |
| aircrack-ng/examples.sh | none | (none) | `check_cmd airmon-ng` conditional block; macOS-specific notes |

**Category C: Optional target (1 script -- special handling)**

| Script | Target | Makefile Target | Notes |
|--------|--------|----------------|-------|
| foremost/examples.sh | optional | `make foremost` | TARGET is `${1:-}` (optional); all examples use hardcoded filenames not $TARGET; interactive demo branches on `$TARGET` existence |

**Already migrated (1 script):**
- nmap/examples.sh -- completed in Phase 14

### Pattern: Examples That Cannot Use run_or_show

Some examples have structure incompatible with `run_or_show()`:

**1. Multi-line echo patterns (comments/annotations)**
```bash
# CURRENT:
info "6) Scan only for specific vulnerability types"
echo "   nikto -h ${TARGET} -Tuning 1234"
echo "   # 1=Files, 2=Misconfig, 3=Info, 4=XSS"
echo "   # 5=RFI, 6=DOS, 7=RCE, 8=Injection, 9=SQLi, 0=Upload"
echo ""
```

**Solution:** Use `run_or_show` for the primary command, then keep the comment echos as standalone lines:
```bash
run_or_show "6) Scan only for specific vulnerability types" \
    nikto -h "$TARGET" -Tuning 1234
# In show mode, run_or_show prints the blank line. In execute mode, it runs the command.
# The comment lines below are educational -- print them always (only in show mode):
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    echo "   # 1=Files, 2=Misconfig, 3=Info, 4=XSS"
    echo "   # 5=RFI, 6=DOS, 7=RCE, 8=Injection, 9=SQLi, 0=Upload"
    echo ""
fi
```

**Alternative (simpler, recommended):** Keep the entire example as `info + echo + echo` for examples with comment lines. Only convert simple single-command examples to `run_or_show`. This preserves exact output fidelity.

**2. Variant-specific case statements (netcat)**
```bash
info "8) Keep listener open [variant: ${NC_VARIANT}]"
case "$NC_VARIANT" in
    ncat) echo "   ncat -k -l -p 4444" ;;
    openbsd) echo "   nc -k -l 4444" ;;
    ...
esac
```

**Solution:** Keep as `info + case + echo ""`. These examples show different commands per variant and are inherently show-only (you would not want `-x` to blindly execute a listener). The variant-specific examples (3, 7, 8, 9, 10 in netcat) should remain as static info+echo patterns.

**3. Platform-conditional examples (traceroute)**
```bash
info "5) TCP traceroute"
if [[ "$(uname -s)" == "Darwin" ]]; then
    echo "   sudo traceroute -P tcp ${TARGET}"
else
    echo "   sudo traceroute -T ${TARGET}"
fi
```

**Solution:** In show mode, keep the conditional echo. In execute mode, `run_or_show` could be used with the platform-appropriate command:
```bash
if [[ "$(uname -s)" == "Darwin" ]]; then
    run_or_show "5) TCP traceroute" sudo traceroute -P tcp "$TARGET"
else
    run_or_show "5) TCP traceroute" sudo traceroute -T "$TARGET"
fi
```

**4. Static examples without $TARGET (metasploit console commands, hashcat modes)**
```bash
info "1) Start Metasploit console"
echo "   msfconsole"
```

**Solution:** Keep as `info + echo + echo`. These are interactive tool commands (metasploit console syntax) that cannot be meaningfully executed via `run_or_show`. They are educational reference only.

**5. Multi-command examples (metasploit workflows)**
```bash
info "3) Select and configure an exploit"
echo "   msf> use exploit/multi/handler"
echo "   msf> set PAYLOAD linux/x64/meterpreter/reverse_tcp"
echo "   msf> set LHOST <your-ip>"
```

**Solution:** Keep as `info + echo` pattern. These are console session workflows, not individual commands.

### Pattern: Which Examples to Convert vs. Keep Static

**Convert to run_or_show:** Examples that are a single executable command using `$TARGET` (or other variables). These make sense to run in `-x` mode.

**Keep as info+echo:** Examples that are:
- Static reference commands (no `$TARGET` variable)
- Multi-step console workflows (metasploit `msf>` prompts)
- Commands with comment annotations (multiple echo lines)
- Variant-specific commands (netcat case statements)
- Commands with hardcoded placeholder values like `<database>`, `<channel>`, `<AP-MAC>`

### Pattern: Interactive Demo Guard

Every script's interactive demo section at the bottom must be wrapped:

```bash
# BEFORE:
[[ ! -t 0 ]] && exit 0
read -rp "Run demo? [y/N] " answer
...

# AFTER:
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    [[ ! -t 0 ]] && exit 0
    read -rp "Run demo? [y/N] " answer
    ...
fi
```

Some scripts (metasploit, sqlmap, aircrack-ng) have non-standard interactive sections (just warn messages, no read prompt). These should also be guarded.

### Anti-Patterns to Avoid

- **Force-converting all examples to run_or_show:** NOT every example should be converted. Static reference commands, multi-line workflows, and variant-specific examples should remain as info+echo patterns. Only single-command, variable-using examples benefit from run_or_show.
- **Modifying show_help() content:** The help text itself should not change. Only remove `exit 0` from inside show_help() for the 3 scripts that have it (nikto, sqlmap, skipfish).
- **Adding confirm_execute to no-target scripts without any executable examples:** Scripts like metasploit where ALL examples are static console references do not need confirm_execute since run_or_show is never called in execute mode. However, for consistency and future-proofing, add it anyway with no argument.
- **Changing the order of require_cmd/require_target/safety_banner:** The existing order must be preserved. confirm_execute is inserted between require_target (or require_cmd for no-target scripts) and safety_banner.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Argument parsing | Per-script inline parsing | `parse_common_args "$@"` from lib/args.sh | Already built and tested in Phase 14 |
| Dual-mode display/execute | Per-script conditionals around each example | `run_or_show()` from lib/output.sh | Consistent behavior, tested |
| Execution confirmation | Per-script safety prompts | `confirm_execute()` from lib/output.sh | Consistent UX, interactive terminal check |
| Output comparison testing | Manual diff of each script | Automated test loop | 17 scripts would be tedious to manually verify |

**Key insight:** The library functions are complete. Phase 15 is a pure application phase -- apply the proven pattern, do not extend or modify the library.

## Common Pitfalls

### Pitfall 1: show_help() with Internal exit 0

**What goes wrong:** Three scripts (nikto, sqlmap, skipfish) have `exit 0` inside `show_help()`. If not removed, `parse_common_args` works correctly (show_help exits before the `exit 0` in parse_common_args), but the inconsistency is confusing and should be cleaned up.
**Why it happens:** These were written in a different style where show_help was responsible for exiting.
**How to avoid:** Remove `exit 0` from inside show_help() for nikto, sqlmap, and skipfish. parse_common_args handles the exit.
**Warning signs:** Lint or review catches `exit 0` inside show_help as dead code.

### Pitfall 2: Output Fidelity for Multi-Line Examples

**What goes wrong:** Converting a multi-line example (info + echo + echo-comment + echo "") to run_or_show drops the comment lines, changing the educational output.
**Why it happens:** `run_or_show` only handles description + single command. Extra annotation lines are lost.
**How to avoid:** Keep multi-line annotated examples as info+echo patterns. Only convert clean single-command examples.
**Warning signs:** Diff between pre- and post-migration output shows missing lines.

### Pitfall 3: run_or_show with Pipelines

**What goes wrong:** `run_or_show "desc" curl -I -s "$TARGET" | head -10` is parsed as `run_or_show ... "$TARGET"` piped to `head -10`, not as a single command with a pipe.
**Why it happens:** Shell pipe syntax is not an argument -- it is shell structure.
**How to avoid:** For the interactive demo section of curl (which has `curl -I -s "$TARGET" | head -10`), keep it in the EXECUTE_MODE-guarded demo section, not as a run_or_show call. For the educational examples themselves, they already use simple echo and do not need pipe handling.
**Warning signs:** Syntax errors or unexpected truncated output.

### Pitfall 4: Foremost Optional Target

**What goes wrong:** foremost/examples.sh does not call `require_target` -- TARGET is optional. The migration pattern assumes `$1` exists for confirm_execute.
**Why it happens:** foremost can show examples without a target; the target is only used for the interactive demo.
**How to avoid:** Call `confirm_execute` without argument (or with `"${1:-}"`) and handle the empty case. Since foremost examples are all static (hardcoded filenames), none use run_or_show with `$TARGET` anyway.
**Warning signs:** foremost/examples.sh crashing when called without arguments.

### Pitfall 5: Metasploit/Hashcat/John/Aircrack Have No Executable Examples

**What goes wrong:** These scripts display `msf>` console syntax, hash cracking commands with placeholder filenames, or Linux-only wireless commands. None of their 10 examples can meaningfully be executed via run_or_show in `-x` mode.
**Why it happens:** These tools require interactive consoles, specific input files, or Linux-specific hardware.
**How to avoid:** Keep all 10 examples as info+echo for these scripts. Still add parse_common_args (for -h/-v/-q flag consistency) and confirm_execute (for pattern consistency), but none of the examples become run_or_show. The `-x` flag effectively does nothing different for these scripts (except skipping the interactive demo).
**Warning signs:** Attempting to run `hashcat -m 0 -a 0 hash.txt wordlist.txt` in execute mode with non-existent files.

### Pitfall 6: Test Coverage Gaps

**What goes wrong:** Tests only check nmap (from Phase 14) and miss regressions in other scripts.
**Why it happens:** Phase 14 test suite was designed for the pilot only.
**How to avoid:** Extend tests to loop over all 17 examples.sh scripts. At minimum, verify: (1) `--help` exits 0, (2) default mode produces expected output markers, (3) `-x` with piped stdin exits non-zero.
**Warning signs:** A migrated script fails in production but tests pass because they only check nmap.

### Pitfall 7: Hashcat/John Sample File Creation in Strict Mode

**What goes wrong:** hashcat and john examples.sh create sample directories and files before displaying examples. Under the migration, this side-effect code stays unchanged, but `parse_common_args` is now called before it. If `-h` is passed, the script exits before creating sample files (which is correct but different from before where `-h` was only checked as `$1`).
**Why it happens:** The old pattern `[[ "${1:-}" =~ ^(-h|--help)$ ]]` only caught help as the first argument. `parse_common_args` catches it anywhere.
**How to avoid:** This is actually improved behavior (help works from any position). No action needed, but be aware the sample-creation code only runs when not requesting help.
**Warning signs:** None -- this is a positive change.

## Code Examples

### Example A: Simple Target-Required Script (dig)

```bash
#!/usr/bin/env bash
# dig/examples.sh -- dig: DNS lookup and query tool
source "$(dirname "$0")/../common.sh"

show_help() {
    cat <<EOF
Usage: $(basename "$0") <target>
...
EOF
}

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

require_cmd dig "..."
require_target "${1:-}"

confirm_execute "${1:-}"
safety_banner

TARGET="$1"

info "=== dig Examples ==="
info "Target: ${TARGET}"
echo ""

run_or_show "1) Basic A record lookup" \
    dig "$TARGET"

run_or_show "2) Short output -- just the answer" \
    dig +short "$TARGET"

# ... 8 more examples ...

# Interactive demo
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    [[ ! -t 0 ]] && exit 0
    read -rp "Run a quick A record lookup on ${TARGET} now? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        info "Running: dig +short ${TARGET}"
        dig +short "$TARGET"
    fi
fi
```

### Example B: No-Target Script with Static Examples (metasploit)

```bash
#!/usr/bin/env bash
# metasploit/examples.sh -- Metasploit Framework
source "$(dirname "$0")/../common.sh"

show_help() {
    cat <<EOF
Usage: $(basename "$0")
...
EOF
}

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

require_cmd msfconsole "..."

confirm_execute
safety_banner

info "=== Metasploit Framework Examples ==="
echo ""

# All examples are console workflows -- keep as info+echo
info "1) Start Metasploit console"
echo "   msfconsole"
echo ""

# ... 9 more static examples ...

# Interactive section
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    [[ ! -t 0 ]] && exit 0
    warn "Metasploit is interactive -- run 'msfconsole' to start."
    warn "Practice against the lab targets..."
fi
```

### Example C: Variant-Specific Examples (netcat)

```bash
# Examples 1-2, 4-6: simple target commands -- use run_or_show
run_or_show "1) Test if a port is open (-z = scan without sending data)" \
    nc -zv "$TARGET" 80

# Examples 3, 7, 8, 9, 10: variant-specific -- keep as info+echo+case
info "3) Start a simple listener on port 4444"
if [[ "$NC_VARIANT" == "openbsd" ]]; then
    echo "   nc -l 4444                  # OpenBSD: -p is optional with -l"
else
    echo "   nc -l -p 4444"
fi
echo ""
```

### Example D: Test Extension Pattern

```bash
# Loop over all 17 examples.sh scripts
SCRIPTS_DIR="${PROJECT_ROOT}/scripts"
for tool_dir in "$SCRIPTS_DIR"/*/; do
    script="${tool_dir}examples.sh"
    [[ -f "$script" ]] || continue
    tool=$(basename "$tool_dir")

    # SC1: --help exits 0
    if bash "$script" --help &>/dev/null; then
        check_pass "${tool}: --help exits 0"
    else
        check_fail "${tool}: --help exits non-zero"
    fi

    # SC3: -x with piped stdin exits non-zero
    if echo "" | bash "$script" -x ${TARGET_FOR_TOOL[$tool]:-} 2>&1 | grep -qi "interactive terminal"; then
        check_pass "${tool}: -x rejects non-interactive"
    else
        check_fail "${tool}: -x does not reject non-interactive"
    fi
done
```

## Detailed Script Inventory

### Conversion Decision Per Example

**Scripts where MOST examples convert to run_or_show (target-based, simple commands):**
- dig: 10/10 examples convertible (all single commands with $TARGET)
- curl: 9/10 convertible (example 9 has complex format string with single quotes -- keep as echo)
- hping3: 10/10 convertible (all `sudo hping3 ... $TARGET`)
- gobuster: 10/10 convertible (all single commands with $TARGET)
- ffuf: 10/10 convertible (all single commands with $TARGET)
- nikto: 8/10 convertible (examples 6, 10 have multi-line annotations)
- skipfish: 10/10 convertible
- traceroute: 8/10 convertible (example 5 is platform-conditional; examples 6-10 use mtr which may not be installed)
- sqlmap: 6/10 convertible (examples 2-5, 8-10 have placeholder values `<database>`, `<table>`)

**Scripts where FEW/NO examples convert to run_or_show (static/complex):**
- netcat: 5/10 convertible (examples 1-2, 4-6); 5 are variant-specific case statements
- tshark: 0/10 (no $TARGET -- all static interface-specific commands)
- metasploit: 0/10 (all console workflow syntax)
- hashcat: 0/10 (all use placeholder filenames)
- john: 0/10 (all use placeholder filenames)
- aircrack-ng: 0/10 (all Linux-specific or placeholder-based)
- foremost: 0/10 (all use hardcoded `image.dd` filenames)

### Makefile Targets

12 Makefile targets call examples.sh scripts. These are the critical backward-compatibility test points:

| Make Target | Script | Passes TARGET? |
|-------------|--------|----------------|
| `make nmap TARGET=x` | nmap/examples.sh | Yes (already migrated) |
| `make tshark` | tshark/examples.sh | No |
| `make sqlmap TARGET=x` | sqlmap/examples.sh | Yes |
| `make nikto TARGET=x` | nikto/examples.sh | Yes |
| `make hping3 TARGET=x` | hping3/examples.sh | Yes |
| `make foremost TARGET=x` | foremost/examples.sh | Yes |
| `make dig TARGET=x` | dig/examples.sh | Yes |
| `make curl TARGET=x` | curl/examples.sh | Yes |
| `make netcat TARGET=x` | netcat/examples.sh | Yes |
| `make traceroute TARGET=x` | traceroute/examples.sh | Yes |
| `make gobuster TARGET=x` | gobuster/examples.sh | Yes |
| `make ffuf TARGET=x` | ffuf/examples.sh | Yes |

5 tools have examples.sh but NO Makefile target: hashcat, john, metasploit, aircrack-ng, skipfish.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Inline `[[ "$1" =~ ^(-h\|--help)$ ]]` | `parse_common_args "$@"` | Phase 14 | Flags work in any position, consistent across scripts |
| `info + echo + echo` 3-line display | `run_or_show` 1-line dual-mode | Phase 14 | Enables execution with -x flag |
| Interactive demo as only execution | `-x` flag + `confirm_execute` gate | Phase 14 | Scriptable execution for advanced users |
| No common flags across tools | `-h/-v/-q/-x` on every script | Phase 15 (this phase) | Consistent CLI experience |

## Suggested Batching Strategy

### Wave 1: Simple Target-Required Scripts (7 scripts)
Scripts with clean patterns, no edge cases:
- dig, hping3, gobuster, ffuf, skipfish, nikto, sqlmap

### Wave 2: Target Scripts with Edge Cases (4 scripts)
Scripts requiring per-example decisions:
- curl (format string in example 9)
- traceroute (platform conditional, mtr check)
- netcat (variant case statements)
- foremost (optional target)

### Wave 3: No-Target Static Scripts (5 scripts)
Scripts where no examples convert to run_or_show:
- tshark, metasploit, hashcat, john, aircrack-ng

### Wave 4: Test Extension and Verification
- Extend test-arg-parsing.sh to cover all 17 scripts
- Verify Makefile targets
- Run full regression

## Open Questions

1. **Should static-only scripts (metasploit, hashcat, john, aircrack-ng, tshark, foremost) still get run_or_show conversions?**
   - What we know: None of their examples can be meaningfully executed (console syntax, placeholder files, Linux-only hardware).
   - What's unclear: Is it worth converting them at all, or just add parse_common_args for flag consistency?
   - Recommendation: Add parse_common_args + confirm_execute for flag/pattern consistency. Leave all examples as info+echo. The `-x` flag simply skips the interactive demo for these scripts. This satisfies the requirement that all scripts "accept" the flags (they do, via parse_common_args) without pretending the examples are executable.

2. **Should examples with placeholder values like `<database>` use run_or_show?**
   - What we know: `run_or_show "4) List tables" sqlmap -u "${TARGET}?id=1" -D "<database>" --tables` would try to execute with literal `<database>` in -x mode.
   - What's unclear: Is this a useful execution or a confusing error?
   - Recommendation: Keep these as info+echo. Only convert examples where ALL arguments are known values or script variables. Placeholder `<database>`, `<table>`, `<channel>`, `<AP-MAC>` examples stay static.

3. **How should the test extension handle scripts requiring tools not installed?**
   - What we know: `require_cmd` exits if the tool is not installed. `--help` is checked BEFORE require_cmd (via parse_common_args), so help works without the tool. But default-mode testing requires the tool to be installed.
   - What's unclear: Should tests skip scripts whose tools are not installed?
   - Recommendation: Test `--help` for all 17 scripts (works without tool installed). Test default-mode output only for scripts whose tools are installed. Test `-x` rejection for all 17 scripts (the non-interactive check happens before any tool execution).

## Sources

### Primary (HIGH confidence)
- Codebase analysis: direct reading of all 17 examples.sh scripts, lib/args.sh, lib/output.sh, common.sh, Makefile
- Phase 14 research: `.planning/phases/14-argument-parsing-and-dual-mode-pattern/14-RESEARCH.md`
- Phase 14 verification: `.planning/phases/14-argument-parsing-and-dual-mode-pattern/14-VERIFICATION.md`
- Phase 14 test suite: `tests/test-arg-parsing.sh` (30 tests, all passing)
- Pilot migration: `scripts/nmap/examples.sh` (proven working pattern)

### Secondary (MEDIUM confidence)
- None needed. All findings derived from direct codebase analysis.

### Tertiary (LOW confidence)
- None. This is an application phase, not a technology research phase.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all infrastructure exists from Phase 14, verified with 30 automated tests
- Architecture: HIGH -- migration pattern proven on nmap pilot, all 16 remaining scripts analyzed in detail
- Pitfalls: HIGH -- identified through line-by-line analysis of all 17 scripts, edge cases catalogued
- Migration plan: HIGH -- scripts classified by complexity, conversion decisions documented per-example

**Research date:** 2026-02-11
**Valid until:** Indefinite (bash migration patterns are stable; scripts will not change until this phase executes)
