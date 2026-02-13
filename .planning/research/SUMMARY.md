# Research Summary: v1.4 JSON Output Mode

**Domain:** Structured JSON output for bash CLI pentesting scripts
**Researched:** 2026-02-13
**Overall confidence:** HIGH

## Executive Summary

This research establishes the architecture for adding a `-j`/`--json` flag to all 46 use-case scripts, producing a consistent JSON envelope (`{"meta": {...}, "results": [...], "summary": {...}}`) suitable for piping into `jq` and downstream automation. The research focused on how a new `lib/json.sh` module integrates with the existing 9-module library, how command output is captured, and how 46 scripts are modified with minimal per-script changes.

The critical architectural decision is the **fd3 redirection strategy**: when JSON mode activates, `exec 3>&1 1>&2` saves the original stdout as fd3 and redirects all normal stdout to stderr. This means every `echo`, `info()`, `safety_banner()`, and educational text line in all 46 scripts automatically goes to stderr -- requiring zero per-script changes for output suppression. Only `json_finalize()` writes to fd3 (the real stdout), producing clean JSON. This approach eliminates ~200 lines of per-script changes that alternative approaches (wrapper functions, per-echo gating) would require.

The second key decision is **raw stdout capture for Phase 1**: rather than attempting to parse 17 different tool output formats, `run_or_show()` captures raw command stdout/stderr to temp files and stores them as strings in the JSON envelope. This works for all tools immediately and defers structured parsing (using nmap `-oX`, nikto `-Format json`, tshark `-T json`) to a future milestone.

The third key decision is **jq as a hard dependency only when `-j` is used**: `json.sh` checks for jq at module load (non-fatal), but only enforces the dependency when the user passes `-j`. The 99% of invocations that don't use `-j` are unaffected. All JSON construction uses `jq -n --arg` for correct escaping -- no manual string concatenation.

## Key Findings

**Stack:** jq (lazy dependency, enforced only with `-j`) is the only new external tool. No other additions needed.

**Architecture:** Centralized JSON module (`lib/json.sh`) with fd3 redirection. 4 public functions (`json_is_active`, `json_set_meta`, `json_add_result`, `json_finalize`). Each script adds 2 lines (set meta + finalize). Library changes confined to 3 files (common.sh, args.sh, output.sh). logging.sh needs zero changes due to fd redirect.

**Critical pitfall:** Non-zero exit codes from security tools (`nmap`, `sqlmap`, etc.) triggering `set -e` and killing the script mid-execution. Prevention: `"$@" && code=0 || code=$?` pattern in run_or_show.

## Implications for Roadmap

Based on research, suggested phase structure:

1. **Library Core** - Create json.sh module, modify common.sh/args.sh/output.sh
   - Addresses: json.sh module, -j flag parsing, fd redirect, run_or_show capture
   - Avoids: Circular dependency (json.sh uses plain echo, not logging functions)
   - Deliverables: lib/json.sh, modified args.sh, modified output.sh, modified common.sh

2. **Unit Tests** - Write lib-json.bats, extend lib-args.bats and lib-output.bats
   - Addresses: JSON envelope validation, special character escaping, -j flag parsing, -j without -x rejection
   - Avoids: Testing without jq installed (mock-based), fd3 state leaking between tests

3. **Script Migration (Batch 1-3)** - Add json_set_meta + json_finalize to scripts
   - Addresses: nmap, nikto, sqlmap, tshark, hashcat, john (20 scripts)
   - Avoids: All-at-once migration (batched by tool family for incremental validation)

4. **Script Migration (Batch 4-6)** - Remaining scripts
   - Addresses: curl, dig, gobuster, ffuf, hping3, metasploit, netcat, traceroute, aircrack-ng, skipfish, foremost (26 scripts)

5. **Integration Tests + Documentation** - Contract tests, help text updates
   - Addresses: JSON output validation across all scripts, -j mentioned in show_help()
   - Avoids: Undocumented feature (users need to know -j exists)

**Phase ordering rationale:**
- Library before scripts: Scripts depend on json.sh, args.sh, output.sh being correct
- Tests before migration: Unit tests prove the library works before touching 46 scripts
- Batched migration: Validate pattern with small batch (nmap) before scaling to all tools
- Documentation last: Feature must be complete before documenting

**Research flags for phases:**
- Phase 1 (Library Core): Standard patterns, no research needed. All function signatures defined in ARCHITECTURE.md.
- Phase 2 (Tests): Standard BATS patterns from v1.3. May need research on testing fd redirections in BATS subshells.
- Phases 3-4 (Migration): Mechanical changes, no research needed. grep verification of completeness.
- Phase 5 (Docs): No research needed.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | jq is well-established, version 1.8.1 (July 2025). No alternatives needed. |
| Features | HIGH | Envelope schema defined. Raw capture approach verified against all 17 tools. |
| Architecture | HIGH | Based on line-by-line analysis of all 9 lib modules and 8 representative scripts. fd3 redirect verified against bash documentation. |
| Pitfalls | HIGH | Strict mode interactions verified against strict.sh source. Tool output formats verified against official documentation. |

## Gaps to Address

- **fd3 in BATS tests:** Need to verify that BATS `run` command properly handles fd3 redirections. May require `run --separate-stderr` (BATS 1.5+). Flag for Phase 2 research.
- **sudo commands in JSON mode:** Scripts with `sudo` in `run_or_show` calls will prompt for password. The password prompt goes to the terminal (stderr). If sudo is not cached, the command blocks. This is a user education issue, not a library issue.
- **ANSI codes in captured output:** Tools may emit color codes. Raw capture preserves them. Downstream consumers may want `NO_COLOR=1` or a strip-ansi post-processor. Defer to documentation guidance.

## Sources

- Direct codebase analysis of all 9 lib modules and 8 representative use-case scripts
- [jq official documentation](https://jqlang.org/) -- JSON construction with --arg/--argjson
- [Nmap output formats](https://nmap.org/book/output.html) -- Tool output capabilities
- [Nikto export formats](https://github.com/sullo/nikto/wiki/Export-Formats) -- Native JSON support
- [tshark documentation](https://www.wireshark.org/docs/man-pages/tshark.html) -- -T json output
- [ffuf GitHub](https://github.com/ffuf/ffuf) -- -of json output format
- [hashcat machine_readable](https://hashcat.net/wiki/doku.php?id=machine_readable) -- --status-json flag
- [Baeldung: Bash JSON construction](https://www.baeldung.com/linux/bash-variables-create-json-string) -- jq vs printf approaches

---
*Research completed: 2026-02-13*
*Ready for roadmap: yes*
