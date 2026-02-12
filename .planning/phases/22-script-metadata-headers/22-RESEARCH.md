# Phase 22: Script Metadata Headers - Research

**Researched:** 2026-02-12
**Domain:** Structured bash comment headers for machine-parseable script metadata
**Confidence:** HIGH

## Summary

Phase 22 adds structured metadata headers to all 78 `.sh` files in the `scripts/` directory. The current codebase already has single-line comment headers (e.g., `# nmap/examples.sh -- Network Mapper: host discovery and port scanning`) but they vary in format and lack machine-parseable structure. The goal is a bordered comment block with Description, Usage, and Dependencies fields placed between the shebang line and the first `source` or executable line, using pure comments that cause zero behavioral change.

The header format must be simple enough to add to 78 files without excessive verbosity, machine-parseable via `grep` for validation and future tooling, and consistent across four distinct script categories (examples.sh, use-case scripts, lib modules, utilities). The BATS validation test (HDR-06) follows the established dynamic test registration pattern from Phase 20, using `bats_test_function` and `find`-based script discovery.

This phase is essentially a bulk refactoring task with a validation test. There are no new libraries, no new dependencies, and no behavioral changes. The primary risk is inconsistency across 78 files or accidentally breaking a script by inserting the header in the wrong position.

**Primary recommendation:** Use a `# @field value` annotation format inside a bordered comment block. Three required fields: `@description`, `@usage`, `@dependencies`. Validate with a BATS test that uses `grep -c` against each file. Keep fields single-line where possible for grep-friendliness.

## Standard Stack

### Core

No new libraries. This phase is pure comment editing plus one BATS test file.

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| bats-core | v1.13.0 | Test runner for HDR-06 validation test | Already installed from Phase 18 |
| bats-assert | v2.2.0 | Assertion helpers for test output | Already installed |
| grep | (system) | Machine-parsing of header fields | Universal, zero dependencies |

### Supporting

| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| bats_test_function | (bats v1.13.0) | Dynamic per-file test registration | HDR-06 test to register one test per .sh file |
| find | (system) | Script discovery for validation | Same pattern as intg-cli-contracts.bats |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `# @field value` annotations | shdoc `# @brief` / `# @description` format | shdoc is explicitly out-of-scope; using `@` prefix is fine but full shdoc compatibility adds complexity |
| Bordered comment block | Simple sequential comments | Borders improve visual scanning when editing; minor formatting cost |
| grep-based validation | awk/sed parsing | grep is simpler, more portable, sufficient for field presence checks |

**Installation:** None needed.

## Architecture Patterns

### Header Format Definition (HDR-01)

The header block goes between the shebang (`#!/usr/bin/env bash`) and the first functional line (`source`, `set`, or code). It uses `#` comment lines with `@` field annotations for machine parseability.

**Format for executable scripts (examples.sh, use-case, diagnostics, check-tools.sh):**

```bash
#!/usr/bin/env bash
# ============================================================================
# @description  Brief description of what this script does
# @usage        script-name.sh [target] [-h|--help] [-x|--execute]
# @dependencies nmap, common.sh
# ============================================================================
source "$(dirname "$0")/../common.sh"
```

**Format for library modules (lib/*.sh):**

```bash
#!/usr/bin/env bash
# ============================================================================
# @description  Brief description of what this library provides
# @usage        source "$(dirname "$0")/../common.sh"  (loaded via common.sh)
# @dependencies colors.sh (loaded before this module)
# ============================================================================

# Source guard -- prevent double-sourcing
[[ -n "${_MODULE_LOADED:-}" ]] && return 0
```

**Format for common.sh (entry-point library):**

```bash
#!/usr/bin/env bash
# ============================================================================
# @description  Shared utility functions for all tool scripts
# @usage        source "$(dirname "$0")/../common.sh"
# @dependencies lib/strict.sh, lib/colors.sh, lib/logging.sh, ...
# ============================================================================
```

**Format for check-docs-completeness.sh (standalone utility, no common.sh):**

```bash
#!/usr/bin/env bash
# ============================================================================
# @description  Verify every tool script has a docs page
# @usage        check-docs-completeness.sh
# @dependencies None (standalone)
# ============================================================================
set -euo pipefail
```

### Field Definitions

| Field | Required | Content | Machine Parse Pattern |
|-------|----------|---------|----------------------|
| `@description` | YES | One-line purpose of the script | `grep -m1 '# @description'` |
| `@usage` | YES | Invocation syntax | `grep -m1 '# @usage'` |
| `@dependencies` | YES | Required commands and/or sourced files | `grep -m1 '# @dependencies'` |

### Key Design Decisions

1. **`@` prefix for fields.** This makes fields unambiguously machine-parseable. A plain `# Description:` could collide with inline comments. The `@` prefix is a widely recognized documentation annotation pattern (javadoc, shdoc, PHPDoc) applied here as a lightweight convention.

2. **Border lines using `=` characters.** The `# ====...====` border visually separates metadata from code. It is not parsed by the validation test -- only the three `@field` lines are required.

3. **Single-line values.** Each `@field` value fits on one line. This keeps `grep` parsing trivial and avoids multi-line continuation syntax. If a description is long, it should be condensed.

4. **Dependencies field semantics.** For tool scripts: the external command(s) needed (e.g., `nmap`, `sqlmap`). For lib modules: other lib modules that must be loaded first. For scripts that need nothing external: `common.sh` or `None (standalone)`.

5. **No Version or Author fields.** Explicitly out-of-scope per REQUIREMENTS.md. Git handles both.

### Script Categories and Their Dependencies Patterns

| Category | Count | Typical @dependencies Value |
|----------|-------|-----------------------------|
| examples.sh | 17 | `<tool>, common.sh` (e.g., `nmap, common.sh`) |
| use-case scripts | 46 | `<tool>, common.sh` (e.g., `sqlmap, common.sh`) |
| lib modules | 9 | Other lib modules or `None` (e.g., `colors.sh` for logging.sh) |
| diagnostics | 3 | `dig/curl/traceroute/mtr, common.sh` |
| utility: common.sh | 1 | `lib/*.sh modules` |
| utility: check-tools.sh | 1 | `common.sh` |
| utility: check-docs-completeness.sh | 1 | `None (standalone)` |
| **Total** | **78** | |

### Anti-Patterns to Avoid

- **Multi-line field values.** Do NOT use continuation lines for `@description`. Breaks single-grep extraction. Condense to one line.
- **Putting the header after the `source` line.** The requirement states headers go between shebang and first `source`. Inserting after `source` violates HDR-01.
- **Using heredoc-style block comments.** `: <<'END_COMMENT' ... END_COMMENT` is technically executed code (a no-op command with a heredoc), not pure comments. Violates the "zero behavioral change" requirement.
- **Duplicating show_help() content.** The header is NOT a replacement for `show_help()`. Keep it brief -- one line per field.
- **Inconsistent border width.** Use exactly 76 `=` characters (78 total with `# `) for all headers. Consistency matters for visual scanning.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Header validation | Custom awk parser | `grep -c '# @description'` per file | grep is sufficient for presence checks; no need for field value parsing |
| Script discovery | Hardcoded file list | `find scripts/ -name '*.sh'` | Same proven pattern from intg-cli-contracts.bats (INTG-03) |
| Dynamic test generation | Loop inside single @test | `bats_test_function` | One test per file gives individual pass/fail in TAP/JUnit output |

**Key insight:** The validation test only needs to verify field *presence*, not field *content*. Checking that `# @description` exists in the file is sufficient. Validating that the description is accurate or the usage is correct is a human review concern, not an automated test concern.

## Common Pitfalls

### Pitfall 1: Breaking Script Behavior by Inserting Code Instead of Comments

**What goes wrong:** If the header accidentally includes non-comment lines (e.g., a stray line without `#`), the script's behavior changes. An empty line between shebang and the header is fine (comments), but a line like `@description ...` without `#` would be interpreted as a command.

**Why it happens:** Copy-paste errors when adding headers to 78 files.

**How to avoid:** Every line in the header block MUST start with `#`. The BATS test should also verify that no `.sh` file has a behavioral change (but this is already covered by existing tests from Phases 19-20). Run `make test` after adding headers to confirm zero regressions.

**Warning signs:** ShellCheck or BATS test failures after header addition.

### Pitfall 2: Header Placed After Source Line

**What goes wrong:** If the header is placed after `source "$(dirname "$0")/../common.sh"`, it still works as comments but violates the HDR-01 requirement of "between shebang and first source line."

**Why it happens:** Some scripts have multi-line existing comments between shebang and source. Easy to accidentally append below `source` instead of inserting above it.

**How to avoid:** For each script, identify line 1 (shebang), identify the first `source` or `set` or code line, and insert the header block between them. Replace the existing single-line comment header.

**Warning signs:** The BATS validation test (HDR-06) should check field position, not just presence. See Open Questions section.

### Pitfall 3: Inconsistent Field Names or Formatting

**What goes wrong:** Using `@desc` in some files and `@description` in others. Or `@deps` vs `@dependencies`. The grep-based validation fails on inconsistent names.

**Why it happens:** 78 files is a lot of manual editing. Fatigue leads to typos.

**How to avoid:** Define the exact field names once (in the BATS test as grep patterns) and use them everywhere. Consider a helper script or template to generate headers.

**Warning signs:** BATS test catches this immediately if field names are wrong.

### Pitfall 4: Forgetting New Scripts

**What goes wrong:** Future scripts added without headers will fail HDR-06 validation in CI.

**Why it happens:** The header convention is new; contributors may not know about it.

**How to avoid:** This is actually a *feature* -- HDR-06 running in CI ensures all future scripts get headers. Document the header format in CLAUDE.md or the project's contributing guide.

**Warning signs:** CI failure on PR with new script.

### Pitfall 5: Border Lines Triggering ShellCheck Warnings

**What goes wrong:** ShellCheck might warn about comment formatting in certain edge cases.

**Why it happens:** Unlikely, but `#` comment lines with special characters could theoretically trigger SC directives.

**How to avoid:** Use only `=` characters in borders. No `!`, no backticks, no dollar signs in the header block.

**Warning signs:** ShellCheck failures in CI after adding headers.

## Code Examples

### Example 1: Complete Header for an examples.sh Script

```bash
#!/usr/bin/env bash
# ============================================================================
# @description  Network scanning and host discovery examples using nmap
# @usage        nmap/examples.sh <target> [-h|--help] [-v|--verbose] [-x|--execute]
# @dependencies nmap, common.sh
# ============================================================================
source "$(dirname "$0")/../common.sh"
```

### Example 2: Complete Header for a Use-Case Script

```bash
#!/usr/bin/env bash
# ============================================================================
# @description  Identify what services are running behind open ports
# @usage        nmap/identify-ports.sh [target] [-h|--help] [-x|--execute]
# @dependencies nmap, common.sh
# ============================================================================
source "$(dirname "$0")/../common.sh"
```

### Example 3: Complete Header for a Library Module

```bash
#!/usr/bin/env bash
# ============================================================================
# @description  Logging functions with LOG_LEVEL filtering and VERBOSE timestamps
# @usage        Sourced via common.sh (not invoked directly)
# @dependencies colors.sh
# ============================================================================

# Source guard -- prevent double-sourcing
[[ -n "${_LOGGING_LOADED:-}" ]] && return 0
_LOGGING_LOADED=1
```

### Example 4: Complete Header for a Diagnostic Script

```bash
#!/usr/bin/env bash
# ============================================================================
# @description  DNS diagnostic auto-report with PASS/FAIL/WARN indicators
# @usage        diagnostics/dns.sh [target] [-h|--help]
# @dependencies dig, common.sh
# ============================================================================
source "$(dirname "$0")/../common.sh"
```

### Example 5: HDR-06 BATS Validation Test

```bash
#!/usr/bin/env bats
# tests/intg-script-headers.bats -- Validate structured metadata headers (HDR-06)

PROJECT_ROOT="$(git rev-parse --show-toplevel)"

# Required header fields (grep patterns)
REQUIRED_FIELDS=(
    '# @description'
    '# @usage'
    '# @dependencies'
)

_discover_all_sh_files() {
    find "${PROJECT_ROOT}/scripts" -name '*.sh' | sort
}

_test_header_fields() {
    local script="$1"
    for field in "${REQUIRED_FIELDS[@]}"; do
        run grep -c "$field" "$script"
        assert_success
        # At least one match
        assert [ "$output" -ge 1 ]
    done
}

# Dynamic test registration: one test per .sh file
while IFS= read -r script; do
    local_path="${script#"${PROJECT_ROOT}"/}"
    bats_test_function \
        --description "HDR-06 ${local_path}: has required header fields" \
        -- _test_header_fields "$script"
done < <(_discover_all_sh_files)

# Meta-test: verify discovery finds all scripts
@test "HDR-06: discovery finds all script files" {
    local count
    count=$(_discover_all_sh_files | wc -l | tr -d ' ')
    assert [ "$count" -ge 78 ]
}

# Load test infrastructure
setup() {
    load 'test_helper/common-setup'
    _common_setup
}
```

### Example 6: Extracting Metadata with grep (Future Tooling)

```bash
# Extract description from a script
grep -m1 '# @description' scripts/nmap/examples.sh | sed 's/# @description  *//'

# List all scripts and their dependencies
for f in scripts/**/*.sh; do
    echo "$f: $(grep -m1 '# @dependencies' "$f" | sed 's/# @dependencies *//')"
done
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Single-line `# filename -- description` | Structured `@field` annotation blocks | This phase | Machine-parseable metadata; consistent format across 78 files |
| No validation of header presence | BATS test enforces headers on all files | This phase | CI prevents headerless scripts from merging |

**Deprecated/outdated:**
- shdoc-style `# @brief` / `# @description` with multi-line support: Explicitly out-of-scope. The `@description` field name is borrowed but used as a single-line annotation, not as shdoc-compatible markup.

## Open Questions

1. **Should HDR-06 validate field position (before first `source` line) or just field presence?**
   - What we know: The requirement says headers go "between shebang and first source line." Presence-only validation is simpler but could miss headers added in the wrong location.
   - What's unclear: Whether position validation is worth the added test complexity. A `head -N` + `grep` approach could check the first N lines, but N varies by file.
   - Recommendation: Use `head -10 "$script" | grep -c '# @description'` to check the header appears in the first 10 lines. This catches headers placed after the source line or deep in the file, without needing to find the exact source line. All current scripts have their source line within the first 7 lines, so 10 lines provides comfortable margin.

2. **Should borders be required or optional in the validation test?**
   - What we know: Borders (`# ====...====`) are visual aids. The three `@field` lines are the machine-parseable content.
   - What's unclear: Whether enforcing border presence adds value or just makes the test brittle.
   - Recommendation: Do NOT validate borders. Only validate the three `@field` lines. Borders are a convention, not a requirement. This keeps the test focused and resilient to minor formatting changes.

3. **How to handle check-docs-completeness.sh which has no `source` line?**
   - What we know: This script uses `set -euo pipefail` directly instead of sourcing common.sh.
   - What's unclear: Nothing -- the header goes between shebang and `set -euo pipefail`.
   - Recommendation: Same header format, just with `@dependencies None (standalone)` and placed before the `set` line.

## Sources

### Primary (HIGH confidence)

- **Codebase analysis** -- Direct inspection of all 78 `.sh` files in `scripts/`, examining current header patterns, source lines, and script structure
- **Existing BATS tests** -- `tests/intg-cli-contracts.bats` for dynamic test registration pattern with `bats_test_function`
- **REQUIREMENTS.md** -- HDR-01 through HDR-06 definitions and out-of-scope items
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html) -- Recommends "start each file with a description of its contents"; minimal but authoritative

### Secondary (MEDIUM confidence)

- [Bash Script Header Essentials](https://bashcommands.com/bash-script-header) -- Community best practices for header fields; `# Field: value` format is widely used
- [8 Tips for Better Bash Scripts](https://bencane.com/2014/06/06/8-tips-for-creating-better-bash-scripts/) -- Structured `# @field value` annotation examples
- [shdoc GitHub](https://github.com/reconquest/shdoc) -- Reference for `@` annotation convention (used as inspiration, NOT as dependency)

### Tertiary (LOW confidence)

- None. All findings verified against codebase and/or multiple sources.

## Metadata

**Confidence breakdown:**
- Header format design: HIGH -- Simple comment convention with clear grep patterns; verified against all 78 existing scripts
- Script inventory: HIGH -- Direct `find` enumeration; counts verified: 17 examples + 46 use-case + 9 lib + 3 diagnostics + 3 utility = 78 total
- BATS test pattern: HIGH -- Exact same pattern proven in Phase 20 (`bats_test_function` + `find` discovery)
- Pitfalls: HIGH -- Based on direct analysis of script structure and existing CI configuration

**Research date:** 2026-02-12
**Valid until:** 2026-03-12 (stable domain; header conventions do not change rapidly)
