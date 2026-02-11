# Phase 12: Pre-Refactor Cleanup - Research

**Researched:** 2026-02-11
**Domain:** Bash script normalization, ShellCheck configuration, version guards
**Confidence:** HIGH

## Summary

Phase 12 is a normalization phase with three well-scoped requirements: standardize interactive guards, add a bash version check, and create a `.shellcheckrc` file. The codebase has exactly 63 scripts with interactive guards split across two logically equivalent but syntactically different patterns: 44 use `[[ ! -t 0 ]] && exit 0` and 19 use `[[ -t 0 ]] || exit 0`. The target is the first variant. Five scripts correctly lack guards (3 diagnostic auto-reports, `check-tools.sh`, `check-docs-completeness.sh`). No guard should be added to those.

The bash version check is straightforward -- `BASH_VERSINFO[0]` comparison at the top of `common.sh` before any Bash 4.0+ syntax executes. The `.shellcheckrc` configuration is well-documented by ShellCheck's official wiki: `source-path=SCRIPTDIR`, `source-path=SCRIPTDIR/..`, and `external-sources=true` handle this project's source pattern perfectly. ShellCheck is not currently installed on this machine.

**Primary recommendation:** Execute all three requirements as a single plan. Total scope is approximately 20 files of modifications (19 guard changes + `common.sh` edit + 1 new file). Low risk, high value for future phases.

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Bash | 4.0+ minimum (5.3.9 on dev machine) | Script runtime | Already required -- `declare -A` in check-tools.sh is Bash 4.0+ |
| ShellCheck | 0.11.0 | Static analysis config (.shellcheckrc only) | Industry standard bash linter; Phase 17 will do full compliance |

### Supporting

| Tool | Purpose | When to Use |
|------|---------|-------------|
| `sed` | In-place file edits for guard normalization | Bulk-changing 19 files with identical pattern |
| `grep` | Verification of changes | Post-change audit |

### Installation

```bash
brew install shellcheck    # macOS (needed for Phase 17, optional for Phase 12)
```

Phase 12 only creates `.shellcheckrc` -- it does not require ShellCheck to be installed. ShellCheck installation is Phase 17's concern.

## Architecture Patterns

### Current Interactive Guard Patterns (to normalize)

**Variant A (44 scripts) -- TARGET pattern:**
```bash
# Interactive demo (skip if non-interactive, e.g. running via make)
[[ ! -t 0 ]] && exit 0
```

**Variant B (19 scripts) -- must change to Variant A:**
```bash
# Interactive demo
[[ -t 0 ]] || exit 0
```

Both are logically identical. NORM-01 requires standardizing on Variant A.

**Scripts WITHOUT guards (5 total -- correctly excluded):**
| Script | Reason |
|--------|--------|
| `scripts/diagnostics/connectivity.sh` | Pattern B: non-interactive auto-report |
| `scripts/diagnostics/dns.sh` | Pattern B: non-interactive auto-report |
| `scripts/diagnostics/performance.sh` | Pattern B: non-interactive auto-report |
| `scripts/check-tools.sh` | Utility script, no interactive demo section |
| `scripts/check-docs-completeness.sh` | Utility script, no interactive demo section |

### Comment Variations Above Guards

The comment line above the guard also varies. Current variants:

| Comment Pattern | Count |
|-----------------|-------|
| `# Interactive demo (skip if non-interactive, e.g. running via make)` | ~36 |
| `# Interactive demo (skip if non-interactive)` | ~8 |
| `# Interactive demo` | ~8 |
| `# Non-interactive exit guard` + `# Interactive demo` | ~4 (foremost scripts) |
| (no comment / other comment) | ~7 |

The requirement (NORM-01) specifies syntax normalization, not comment normalization. However, normalizing the comment as part of this phase would be prudent -- it prevents confusion during the Phase 15/16 migration. Recommended standard comment: `# Interactive demo (skip if non-interactive)`.

### Source Path Patterns

Two source patterns exist:

| Pattern | Count | Used By |
|---------|-------|---------|
| `source "$(dirname "$0")/../common.sh"` | 66 | All tool scripts in `scripts/<tool>/` |
| `source "$(dirname "$0")/common.sh"` | 1 | `scripts/check-tools.sh` (sits alongside common.sh) |

Both resolve correctly. The `.shellcheckrc` `source-path=SCRIPTDIR` + `source-path=SCRIPTDIR/..` handles both patterns.

### Bash Version Guard Pattern

**Recommended placement:** Top of `common.sh`, before any Bash 4.0+ syntax.

```bash
# Require Bash 4.0+ (associative arrays, mapfile, etc.)
if [[ -z "${BASH_VERSINFO:-}" ]] || ((BASH_VERSINFO[0] < 4)); then
    echo "[ERROR] Bash 4.0+ required (found: ${BASH_VERSION:-unknown})" >&2
    echo "[ERROR] macOS ships Bash 3.2. Install modern bash: brew install bash" >&2
    exit 1
fi
```

**Key design decisions:**
- Use `BASH_VERSINFO[0]` (integer array), not string comparison on `$BASH_VERSION`
- Check for major version 4 only (not 4.x) -- codebase uses `declare -A` (4.0) but nothing from 4.2/4.3/4.4
- The guard itself must use only Bash 3.x-compatible syntax (no `declare -A`, no `[[ ]]` with BASH_VERSINFO as array -- actually `[[ ]]` is fine back to Bash 2.x, and `BASH_VERSINFO` as array is fine too; the `(( ))` arithmetic is also Bash 2.x+)
- Print actionable macOS-specific install hint since that is the primary "Bash 3.2" scenario
- Use `>&2` for error output consistency

### .shellcheckrc Configuration

```bash
# .shellcheckrc -- ShellCheck project-level configuration
# Placed at project root; ShellCheck walks up directories to find this

# Resolve source paths relative to each script's directory
source-path=SCRIPTDIR
source-path=SCRIPTDIR/..

# Future-proofing for Phase 13 library split
source-path=SCRIPTDIR/../lib

# Allow following source statements to external files
external-sources=true
```

**How ShellCheck finds it:** ShellCheck searches from the checked script's directory upward through parent directories. Placing `.shellcheckrc` at the project root means every script under `scripts/` will find it automatically.

**Why three source-path entries:**
- `SCRIPTDIR`: Handles `check-tools.sh` sourcing `common.sh` from the same directory
- `SCRIPTDIR/..`: Handles `scripts/<tool>/examples.sh` sourcing `../common.sh` -- this resolves to `scripts/` which contains `common.sh`
- `SCRIPTDIR/../lib`: Pre-positioned for Phase 13 library split where `common.sh` will source `lib/*.sh` modules

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Bulk file editing | Custom bash loop with string manipulation | `sed -i '' 's/pattern/replacement/' file` | sed is purpose-built for this; less error-prone |
| Version comparison | String splitting/comparing `$BASH_VERSION` | `BASH_VERSINFO[0]` integer comparison | BASH_VERSINFO is a built-in integer array specifically for this |
| ShellCheck source resolution | Per-file `# shellcheck source=` directives | `.shellcheckrc` with `source-path=SCRIPTDIR` | One config vs 66 inline directives |

## Common Pitfalls

### Pitfall 1: macOS sed -i Requires Empty String Argument
**What goes wrong:** `sed -i 's/old/new/' file` fails on macOS because BSD sed requires `-i ''` (empty backup extension), while GNU sed uses `-i` alone.
**Why it happens:** macOS ships BSD sed, not GNU sed.
**How to avoid:** Always use `sed -i '' 's/...' file` on macOS, or use `perl -pi -e` which is portable.
**Warning signs:** "extra characters at end of d command" error.

### Pitfall 2: Guard Line Contains Shell Metacharacters for sed
**What goes wrong:** The `[[ ]]` and `||` characters in the guard pattern need proper escaping in sed.
**Why it happens:** Square brackets and pipes are sed regex metacharacters.
**How to avoid:** Use fixed-string matching or carefully escape: `\[\[ -t 0 \]\] || exit 0` becomes `\[\[ -t 0 \]\] || exit 0` (brackets need escaping; `||` is literal in basic regex).
**Warning signs:** sed replacing wrong lines or failing silently.

### Pitfall 3: Version Guard Uses Bash 4.0+ Syntax
**What goes wrong:** If the version guard itself uses syntax that requires Bash 4.0+, it will produce a cryptic parse error on Bash 3.2 instead of a helpful message.
**Why it happens:** Bash parses the entire script before executing, but function definitions and sourced files are parsed on demand.
**How to avoid:** The guard must use only constructs available in Bash 2.x/3.x: `[[ ]]` (Bash 2.0+), `(( ))` (Bash 2.0+), `BASH_VERSINFO` (Bash 2.0+). All three are safe. The `common.sh` file is sourced (not parsed upfront), so the guard runs before any `declare -A` in scripts that source it later.
**Warning signs:** Test by running `common.sh` under `/bin/bash` (3.2) on macOS -- should show the clear error.

### Pitfall 4: Accidentally Modifying Scripts That Should NOT Have Guards
**What goes wrong:** Adding or changing guards in diagnostic scripts or utility scripts that correctly lack them.
**Why it happens:** Bulk operations without a precise file list.
**How to avoid:** Only target the 19 files that have `[[ -t 0 ]] || exit 0`. Never add guards to the 5 scripts that correctly lack them.

### Pitfall 5: .shellcheckrc Overridden by Local Config
**What goes wrong:** A developer's `~/.shellcheckrc` has conflicting settings.
**Why it happens:** ShellCheck searches script directory first, then parents, then home directory. Project-level `.shellcheckrc` takes precedence over home directory config. But if there is a `.shellcheckrc` in a subdirectory, it would take precedence.
**How to avoid:** Place `.shellcheckrc` at project root only. Do not create subdirectory-level configs.

## Code Examples

### Guard Normalization (sed command)

```bash
# For each of the 19 files with variant B:
sed -i '' 's/\[\[ -t 0 \]\] || exit 0/[[ ! -t 0 ]] \&\& exit 0/' "$file"
```

Or more safely, per-file with explicit list:

```bash
# Exact list of 19 files needing change (variant B -> variant A)
files=(
  scripts/curl/examples.sh
  scripts/dig/examples.sh
  scripts/ffuf/examples.sh
  scripts/ffuf/fuzz-parameters.sh
  scripts/gobuster/discover-directories.sh
  scripts/gobuster/enumerate-subdomains.sh
  scripts/gobuster/examples.sh
  scripts/hashcat/examples.sh
  scripts/hping3/examples.sh
  scripts/john/examples.sh
  scripts/netcat/examples.sh
  scripts/nikto/examples.sh
  scripts/nmap/examples.sh
  scripts/skipfish/examples.sh
  scripts/traceroute/compare-routes.sh
  scripts/traceroute/diagnose-latency.sh
  scripts/traceroute/examples.sh
  scripts/traceroute/trace-network-path.sh
  scripts/tshark/examples.sh
)
```

### Bash Version Guard (in common.sh)

```bash
#!/usr/bin/env bash
# common.sh -- Shared utility functions for all tool scripts
# Source this file: source "$(dirname "$0")/../common.sh"

# --- Bash Version Guard ---
# Require Bash 4.0+ (associative arrays, etc.)
# This check uses only Bash 2.x+ syntax so it prints a clear error on old bash.
if [[ -z "${BASH_VERSINFO:-}" ]] || ((BASH_VERSINFO[0] < 4)); then
    echo "[ERROR] Bash 4.0+ required (found: ${BASH_VERSION:-unknown})" >&2
    echo "[ERROR] macOS ships Bash 3.2 -- install modern bash: brew install bash" >&2
    exit 1
fi

set -euo pipefail
# ... rest of common.sh
```

### .shellcheckrc (project root)

```bash
# .shellcheckrc -- ShellCheck project-level configuration
# ShellCheck walks up from each script's directory to find this file

# Resolve source statements relative to each script's directory
source-path=SCRIPTDIR
source-path=SCRIPTDIR/..
source-path=SCRIPTDIR/../lib

# Allow following dynamically-constructed source paths
external-sources=true
```

### Verification Commands

```bash
# Verify NORM-01: All guards use the same syntax
grep -rn '\[\[ -t 0 \]\] || exit 0' scripts/
# Expected: zero results

grep -rn '\[\[ ! -t 0 \]\] && exit 0' scripts/ | wc -l
# Expected: 63

# Verify NORM-02: Bash 3.2 produces clear error
/bin/bash -c 'source scripts/common.sh' 2>&1
# Expected: "[ERROR] Bash 4.0+ required (found: 3.2.57...)"

# Verify NORM-03: ShellCheck resolves sources (requires shellcheck installed)
shellcheck scripts/nmap/examples.sh 2>&1 | grep -c 'SC1091'
# Expected: 0 (no "not following" warnings)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `shellcheck -x` flag | `.shellcheckrc` with `external-sources=true` | ShellCheck 0.7.0+ | No need to pass CLI flags; config checked into repo |
| `# shellcheck source=path` per file | `source-path=SCRIPTDIR` in `.shellcheckrc` | ShellCheck 0.7.0+ | One config handles all scripts |
| `$BASH_VERSION` string parsing | `BASH_VERSINFO` array | Always available (Bash 2.0+) | Integer comparison, no string parsing needed |

## Codebase Inventory (Precise Counts)

**Total .sh files:** 68

| Category | Count | Has Guard | Source Pattern |
|----------|-------|-----------|----------------|
| examples.sh (Pattern A) | 17 | Yes | `source "$(dirname "$0")/../common.sh"` |
| Use-case scripts | 28 | Yes | `source "$(dirname "$0")/../common.sh"` |
| foremost/examples.sh | (1, counted above) | Yes | Same |
| Diagnostic scripts (Pattern B) | 3 | No (correct) | `source "$(dirname "$0")/../common.sh"` |
| check-tools.sh | 1 | No (correct) | `source "$(dirname "$0")/common.sh"` |
| check-docs-completeness.sh | 1 | No (correct) | Does NOT source common.sh |
| common.sh | 1 | N/A (library) | N/A |

**Guard variant breakdown (63 scripts with guards):**

| Variant | Syntax | Count | Action |
|---------|--------|-------|--------|
| A (target) | `[[ ! -t 0 ]] && exit 0` | 44 | Keep as-is |
| B (change) | `[[ -t 0 ]] || exit 0` | 19 | Change to variant A |

## Open Questions

1. **Comment normalization scope**
   - What we know: Comments above the guard vary across 7+ patterns
   - What's unclear: Whether NORM-01 scope includes comment normalization or only the guard syntax
   - Recommendation: Normalize comments to `# Interactive demo (skip if non-interactive)` as part of the same change -- low effort, high clarity. If the planner wants to minimize scope, comments can be left as-is since the requirement only specifies syntax.

2. **ShellCheck installation timing**
   - What we know: ShellCheck is not installed on this machine. Phase 12 only creates `.shellcheckrc`. Phase 17 does full ShellCheck compliance.
   - What's unclear: Whether to install shellcheck now for verification of NORM-03 success criterion
   - Recommendation: Install during Phase 12 verification step. The `.shellcheckrc` can be created without it, but success criterion #3 ("ShellCheck resolves source paths") requires running shellcheck to verify.

3. **check-docs-completeness.sh does not source common.sh**
   - What we know: This script uses its own `set -euo pipefail` and never sources common.sh
   - What's unclear: Whether Phase 13+ will bring it into the common.sh fold
   - Recommendation: Out of scope for Phase 12. Note for Phase 13 planning.

## Sources

### Primary (HIGH confidence)
- **Codebase analysis** -- Direct grep/read of all 68 scripts in `scripts/` directory
- [ShellCheck man page (shellcheck.1.md)](https://github.com/koalaman/shellcheck/blob/master/shellcheck.1.md) -- `.shellcheckrc`, `source-path`, `external-sources` configuration
- [ShellCheck SC1091 wiki](https://www.shellcheck.net/wiki/SC1091) -- Source file resolution
- [ShellCheck SC1144 wiki](https://www.shellcheck.net/wiki/SC1144) -- `external-sources` can only be in `.shellcheckrc`
- Prior project research: `.planning/research/STACK.md` section 6 (ShellCheck Compliance)

### Secondary (MEDIUM confidence)
- [BASH_VERSINFO documentation](https://www.bashsupport.com/bash/variables/bash_versinfo/) -- Array structure and availability
- [commandlinefu.com](https://www.commandlinefu.com/commands/view/7962/make-sure-your-script-runs-with-a-minimum-bash-version) -- Bash version check patterns

## Metadata

**Confidence breakdown:**
- Interactive guard inventory: HIGH -- Direct codebase grep with exact counts verified
- Bash version guard: HIGH -- `BASH_VERSINFO` is well-documented, pattern is standard
- `.shellcheckrc` configuration: HIGH -- Verified against official ShellCheck documentation
- Pitfalls: HIGH -- macOS sed and bash 3.2 behaviors are well-known

**Research date:** 2026-02-11
**Valid until:** Indefinite (stable domain, no fast-moving dependencies)
