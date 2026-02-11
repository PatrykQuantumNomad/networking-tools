# Phase 17: ShellCheck Compliance and CI - Research

**Researched:** 2026-02-11
**Domain:** Shell script linting (ShellCheck), GitHub Actions CI
**Confidence:** HIGH

## Summary

The codebase is in excellent shape for ShellCheck compliance. Running `shellcheck --severity=warning` across all 81 `.sh` files produces only 11 unique warnings -- all SC2034 (variable appears unused) and one SC2043 (single-iteration loop). There are zero SC2155 violations (the `local var=$(cmd)` pattern has already been eliminated or was never present). The fixes are straightforward: inline `# shellcheck disable=SC2034` directives for library variables that ARE used by sourcing scripts but ShellCheck cannot trace cross-file, one genuinely unused variable to remove, one unused test variable to prefix with `_`, and one single-iteration loop to unwrap.

For CI, ShellCheck is pre-installed on GitHub's `ubuntu-latest` runners, so the workflow needs no external action -- a simple `find . -name '*.sh' -exec shellcheck --severity=warning {} +` suffices. The `make lint` target wraps this for local use. The existing `deploy-site.yml` workflow provides a pattern for the new `shellcheck.yml` workflow.

**Primary recommendation:** Fix the 11 warnings (mostly SC2034 in library files), add `make lint`, and create a GitHub Actions workflow that gates PRs on ShellCheck compliance.

## Standard Stack

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| ShellCheck | 0.11.0 (local), pre-installed on ubuntu-latest | Static analysis for shell scripts | Industry standard, only serious bash linter |
| GitHub Actions | N/A | CI/CD platform | Already used for deploy-site.yml |

### Supporting
| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| GNU find | (system) | Locate all `.sh` files for linting | CI workflow and `make lint` target |
| Make | (system) | `make lint` target for local developer use | Before committing, in CI |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Pre-installed ShellCheck | ludeeus/action-shellcheck | Adds dependency on third-party action; pre-installed is simpler, no version drift |
| Pre-installed ShellCheck | reviewdog/action-shellcheck | Adds PR review comments but overkill for 81 scripts; plain output is sufficient |
| `find ... -exec shellcheck` | `shellcheck scripts/**/*.sh` | Glob expansion misses nested dirs; `find` is more reliable across shells |

**Installation:** No installation needed. ShellCheck is pre-installed on ubuntu-latest runners and already installed locally (v0.11.0).

## Architecture Patterns

### Recommended File Structure
```
.github/
  workflows/
    deploy-site.yml      # Existing -- deploys docs site
    shellcheck.yml       # NEW -- ShellCheck CI gate
.shellcheckrc            # Existing -- project-level ShellCheck config
Makefile                 # Add `lint` target
```

### Pattern 1: Inline SC2034 Disable for Library Variables
**What:** Variables defined in library files for use by sourcing scripts cannot be traced by ShellCheck. Use `# shellcheck disable=SC2034` on the specific lines.
**When to use:** Library files (`scripts/lib/*.sh`) that define variables consumed by other scripts.
**Example:**
```bash
# In scripts/lib/colors.sh -- these variables are used by all sourcing scripts
# shellcheck disable=SC2034  # Exported via source, used in logging.sh and all tool scripts
RED='\033[0;31m'
# shellcheck disable=SC2034
GREEN='\033[0;32m'
```

**Better approach -- block disable for related variables:**
```bash
# shellcheck disable=SC2034  # Color variables used by sourcing scripts via common.sh
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Disable colors when NO_COLOR is set or stdout is not a terminal
if [[ -n "${NO_COLOR:-}" ]] || [[ ! -t 1 ]]; then
    # shellcheck disable=SC2034
    RED=''
    # shellcheck disable=SC2034
    GREEN=''
    ...
fi
```

**Note:** The `# shellcheck disable` directive applies to the next ShellCheck-relevant code construct. For a block of assignments, it only covers the first one unless each has its own directive OR the disable is placed at the top of a function/block. The cleanest approach is to add the directive before each re-assignment in the `if` block, or use `export` for variables that are truly meant to be shared.

### Pattern 2: Make Lint Target
**What:** A `make lint` target that runs ShellCheck locally, matching CI behavior exactly.
**When to use:** Developer pre-commit check, CI pipeline.
**Example:**
```makefile
lint: ## Run ShellCheck on all shell scripts
	@echo "Running ShellCheck..."
	@find . -name '*.sh' -not -path './site/*' -not -path './.planning/*' -not -path './node_modules/*' -exec shellcheck --severity=warning {} +
	@echo "ShellCheck passed!"
```

### Pattern 3: GitHub Actions Workflow for PR Gating
**What:** A workflow that runs on pull requests to main, failing if ShellCheck finds warnings.
**When to use:** Every PR.
**Example:**
```yaml
name: ShellCheck

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

permissions:
  contents: read

jobs:
  shellcheck:
    name: ShellCheck
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run ShellCheck
        run: |
          find . -name '*.sh' \
            -not -path './site/*' \
            -not -path './.planning/*' \
            -not -path './node_modules/*' \
            -exec shellcheck --severity=warning {} +
```

### Anti-Patterns to Avoid
- **Global SC2034 disable in .shellcheckrc:** Do NOT add `disable=SC2034` to `.shellcheckrc`. This would hide genuinely unused variables across the entire project. Use targeted inline directives only where cross-file usage is known.
- **Using `export` to silence SC2034:** Do not `export` variables (like colors) just to satisfy ShellCheck. These are shell variables meant for the current process tree via `source`, not environment variables for subprocesses. `export` changes semantics.
- **Third-party ShellCheck actions:** Avoid `ludeeus/action-shellcheck` or similar when ShellCheck is already on the runner. External actions add supply-chain risk and version-pinning overhead for no benefit.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Shell linting | Custom grep for bad patterns | ShellCheck | 300+ rules, maintained, understands shell semantics |
| CI gating | Manual review for shell issues | GitHub Actions + ShellCheck | Automated, consistent, blocks merge on failure |
| File discovery | Hardcoded list of scripts | `find . -name '*.sh'` with exclusions | Auto-discovers new scripts, no maintenance |

**Key insight:** ShellCheck is the ONLY tool for this job. There are no alternatives worth considering for bash static analysis.

## Common Pitfalls

### Pitfall 1: SC2034 False Positives in Library Files
**What goes wrong:** ShellCheck reports variables as unused when they are defined in a library file but used by scripts that `source` the library.
**Why it happens:** ShellCheck analyzes files individually (or follows `source` one level) but cannot always trace variable usage across the full source chain, especially with the `if/else` branches in `colors.sh`.
**How to avoid:** Use inline `# shellcheck disable=SC2034` with a comment explaining WHY the variable is used.
**Warning signs:** SC2034 on color variables (RED, GREEN, etc.), PROJECT_ROOT, LOG_LEVEL.

### Pitfall 2: find + shellcheck Exit Code Behavior
**What goes wrong:** `find ... -exec shellcheck {} +` returns the exit code of the LAST invocation of shellcheck, which might succeed even if earlier batches failed.
**Why it happens:** When `find` batches files (due to ARG_MAX), only the last batch's exit code is returned.
**How to avoid:** For 81 files this is not a real risk (fits in one batch), but for safety use `find ... -print0 | xargs -0 shellcheck --severity=warning` or verify `shellcheck` receives all files in one invocation.
**Warning signs:** CI passes but `make lint` locally shows warnings.

### Pitfall 3: .shellcheckrc Not Found in CI
**What goes wrong:** ShellCheck in CI does not find `.shellcheckrc` because it searches relative to the script being checked, walking up to `/`.
**Why it happens:** `.shellcheckrc` lives at repository root. ShellCheck walks up from the script's directory. As long as scripts are under the repo root, it will be found.
**How to avoid:** Ensure `actions/checkout` places the repo at the default location. The existing `.shellcheckrc` with `source-path=SCRIPTDIR` etc. will be found automatically.
**Warning signs:** SC1091 (source not found) errors appearing only in CI.

### Pitfall 4: Exclusion Paths Diverging Between make lint and CI
**What goes wrong:** `make lint` excludes `./site/*` but CI workflow does not (or vice versa), causing false passes/failures.
**Why it happens:** Copy-paste error or forgetting to sync exclusions.
**How to avoid:** Use identical `find` commands in both `Makefile` and `.github/workflows/shellcheck.yml`. Consider extracting the find command into a variable or script.
**Warning signs:** CI fails on files that `make lint` does not check.

## Code Examples

### Fix 1: colors.sh SC2034 (6 warnings)
```bash
# In scripts/lib/colors.sh
# The color variables are defined here and used by ALL scripts that source common.sh.
# ShellCheck cannot trace cross-file usage through source chains.

# shellcheck disable=SC2034  # Color vars used by sourcing scripts (logging.sh, output.sh, all tool scripts)
RED='\033[0;31m'
# shellcheck disable=SC2034
GREEN='\033[0;32m'
# shellcheck disable=SC2034
YELLOW='\033[1;33m'
# shellcheck disable=SC2034
BLUE='\033[0;34m'
# shellcheck disable=SC2034
CYAN='\033[0;36m'
# shellcheck disable=SC2034
NC='\033[0m'

if [[ -n "${NO_COLOR:-}" ]] || [[ ! -t 1 ]]; then
    # shellcheck disable=SC2034
    RED=''
    # shellcheck disable=SC2034
    GREEN=''
    # shellcheck disable=SC2034
    YELLOW=''
    # shellcheck disable=SC2034
    BLUE=''
    # shellcheck disable=SC2034
    CYAN=''
    # shellcheck disable=SC2034
    NC=''
fi
```

### Fix 2: output.sh SC2034 -- PROJECT_ROOT (1 warning)
```bash
# In scripts/lib/output.sh line 25
# PROJECT_ROOT is used by 15+ scripts (hashcat, john, gobuster, ffuf, etc.)
# shellcheck disable=SC2034  # Used by sourcing scripts for wordlist/sample paths
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
```

### Fix 3: args.sh SC2034 -- LOG_LEVEL (1 warning)
```bash
# In scripts/lib/args.sh, inside parse_common_args()
# LOG_LEVEL is defined in logging.sh and modified here; ShellCheck sees the
# assignment in the case branch but not the cross-file read in logging.sh.
            -q|--quiet)
                # shellcheck disable=SC2034  # Used by logging.sh _should_log()
                LOG_LEVEL="warn"
                ;;
```

### Fix 4: check-dns-propagation.sh SC2034 -- RESOLVERS (1 warning)
```bash
# The RESOLVERS array on line 46 is genuinely unused -- the script hardcodes
# resolver IPs in echo strings instead of iterating the array.
# FIX: Remove the unused RESOLVERS array declaration entirely.
# (Lines 43-46 can be deleted; the comment about resolvers can stay.)
```

### Fix 5: test-arg-parsing.sh SC2034 -- order_output (1 warning)
```bash
# Line 166: order_output is captured but never used (only order_exit is checked)
# FIX: Prefix with underscore to indicate intentional discard
_order_output=$(bash "${PROJECT_ROOT}/scripts/nmap/examples.sh" scanme.nmap.org --custom-thing 2>/dev/null)
```

### Fix 6: test-library-loads.sh SC2043 -- single-iteration loop (1 warning)
```bash
# Line 87: "for fn in detect_nc_variant; do" -- loop with only one item
# FIX: Either add more functions to check, or unwrap the loop:
if declare -F "detect_nc_variant" > /dev/null 2>&1; then
    check_pass "detect_nc_variant() is defined"
else
    check_fail "detect_nc_variant() is NOT defined"
fi
```

### make lint Target
```makefile
.PHONY: lint

lint: ## Run ShellCheck on all shell scripts
	@echo "Running ShellCheck (severity=warning)..."
	@find . -name '*.sh' -not -path './site/*' -not -path './.planning/*' -not -path './node_modules/*' -exec shellcheck --severity=warning {} +
	@echo "All scripts pass ShellCheck."
```

### GitHub Actions Workflow: .github/workflows/shellcheck.yml
```yaml
name: ShellCheck

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

permissions:
  contents: read

jobs:
  shellcheck:
    name: Lint shell scripts
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Run ShellCheck
        run: |
          echo "ShellCheck version:"
          shellcheck --version
          echo ""
          find . -name '*.sh' \
            -not -path './site/*' \
            -not -path './.planning/*' \
            -not -path './node_modules/*' \
            -exec shellcheck --severity=warning {} +
          echo "All scripts pass ShellCheck."
```

## Current State Inventory

### Total Warnings: 11 unique (19 non-deduplicated due to cross-file sourcing)

| File | SC Code | Issue | Fix Strategy |
|------|---------|-------|-------------|
| `scripts/lib/colors.sh:19-24` | SC2034 x6 | Color vars appear unused | `# shellcheck disable=SC2034` -- vars used by 60+ sourcing scripts |
| `scripts/lib/output.sh:25` | SC2034 x1 | PROJECT_ROOT appears unused | `# shellcheck disable=SC2034` -- used by 15+ scripts |
| `scripts/lib/args.sh:37` | SC2034 x1 | LOG_LEVEL appears unused | `# shellcheck disable=SC2034` -- used by logging.sh |
| `scripts/dig/check-dns-propagation.sh:46` | SC2034 x1 | RESOLVERS genuinely unused | Remove the unused array |
| `tests/test-arg-parsing.sh:166` | SC2034 x1 | order_output unused | Prefix with `_` |
| `tests/test-library-loads.sh:87` | SC2043 x1 | Single-item loop | Unwrap the loop |

### SC2155 Status: ZERO violations
No `local var=$(cmd)` patterns exist in the codebase. This requirement is already satisfied.

### Files to Check: 81 total `.sh` files
- `scripts/` -- 67 files (lib, common, tools, diagnostics)
- `tests/` -- 2 files
- `wordlists/` -- 1 file
- `scripts/check-docs-completeness.sh` -- 1 file (already in CI)

### Existing Infrastructure
- `.shellcheckrc` -- Already configured with `source-path=SCRIPTDIR`, `SCRIPTDIR/..`, `SCRIPTDIR/../lib`, and `external-sources=true`
- `.github/workflows/deploy-site.yml` -- Existing CI workflow (pattern to follow)
- No existing `make lint` target
- No existing ShellCheck CI workflow

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Third-party ShellCheck actions | Pre-installed on ubuntu-latest | ~2023+ | No external action dependency needed |
| Global disables in .shellcheckrc | Targeted inline directives | Best practice | Preserves warning coverage for new code |
| `shellcheck files/*.sh` glob | `find . -exec shellcheck {} +` | N/A | More reliable file discovery |

**ShellCheck 0.11.0** is the latest stable release. Key features relevant to this project:
- `--extended-analysis` (default true) -- improved cross-function dataflow analysis
- `source-path=SCRIPTDIR` in `.shellcheckrc` -- already configured
- `external-sources=true` -- already configured

## Open Questions

1. **Branch protection rules**
   - What we know: The workflow will run on PRs and pushes to main
   - What's unclear: Whether GitHub branch protection rules are configured to require the ShellCheck check to pass before merge
   - Recommendation: After creating the workflow, manually enable "Require status checks to pass before merging" in repo settings and add the ShellCheck job as a required check. This is a manual GitHub UI step, not automatable via code.

2. **ShellCheck version pinning in CI**
   - What we know: ubuntu-latest has ShellCheck pre-installed; version may change with runner updates
   - What's unclear: Exact version on current ubuntu-latest (likely 0.9.x or 0.10.x based on Ubuntu package repos)
   - Recommendation: Print version in CI output for visibility. Do not pin version -- staying current is better for a linter. The severity=warning flag provides consistent behavior across versions.

## Sources

### Primary (HIGH confidence)
- **Local ShellCheck run** -- `shellcheck --severity=warning` on all 81 scripts, 11 unique warnings identified
- **Codebase inspection** -- All files read and analyzed directly
- **ShellCheck 0.11.0 --help** -- Format options, severity levels, configuration flags

### Secondary (MEDIUM confidence)
- [ShellCheck GitHub Actions wiki](https://github.com/koalaman/shellcheck/wiki/GitHub-Actions) -- Official workflow examples
- [SC2034 wiki page](https://github.com/koalaman/shellcheck/wiki/SC2034) -- Fix strategies for unused variable warnings
- [ShellCheck GitHub repository](https://github.com/koalaman/shellcheck) -- Current release info

### Tertiary (LOW confidence)
- [GitHub Marketplace ShellCheck actions](https://github.com/marketplace/actions/shellcheck) -- Third-party action landscape (not recommended for use)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- ShellCheck is the only tool, pre-installed on runners, verified locally
- Architecture: HIGH -- Workflow pattern directly from official ShellCheck wiki, Makefile is straightforward
- Pitfalls: HIGH -- All 11 warnings individually analyzed with verified fix strategies
- SC2155 status: HIGH -- Grep confirmed zero `local var=$(cmd)` patterns across entire codebase

**Research date:** 2026-02-11
**Valid until:** 2026-06-11 (stable domain, ShellCheck rarely has breaking changes)
