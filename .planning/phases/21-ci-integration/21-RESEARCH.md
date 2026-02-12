# Phase 21: CI Integration - Research

**Researched:** 2026-02-12
**Domain:** GitHub Actions CI workflow for BATS tests with JUnit reporting and parallel linting
**Confidence:** HIGH

## Summary

Phase 21 adds a GitHub Actions workflow that runs the full BATS test suite on every push and PR, with test failure annotations on PRs via JUnit XML reports. The workflow must coexist with the existing ShellCheck workflow (`.github/workflows/shellcheck.yml`) as independent jobs -- either in the same workflow file or as separate workflow files.

The project already has a fully working BATS test suite (186 tests across 8 `.bats` files), submodule-based library loading (`tests/bats/` for bats-core v1.13.0, `tests/test_helper/bats-{support,assert,file}/` for helper libraries), and a `make test` target. The `common-setup.bash` helper already implements dual-path library loading: prefer submodules (check directory existence), fall back to `bats_load_library` for CI environments.

The CI workflow uses `bats-core/bats-action@4.0.0` (released 2025-02-08) to install `bats` on the runner, `actions/checkout@v5` with `submodules: recursive` to populate submodule directories, BATS `--report-formatter junit --output` to generate JUnit XML, and `mikepenz/action-junit-report@v6` to convert JUnit XML into GitHub PR annotations and check runs.

**Primary recommendation:** Create a single new workflow file `.github/workflows/tests.yml` with one job (`bats`) that checks out with submodules, runs `bats-action@4.0.0` for the `bats` binary, executes tests with `--report-formatter junit`, and publishes results via `action-junit-report@v6`. Keep ShellCheck in its existing separate workflow file. Both workflows trigger on the same events (`push: main`, `pull_request: main`) and run independently.

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| bats-core/bats-action | 4.0.0 | Install `bats` binary on CI runner | Official GitHub Action from bats-core org. Adds `bats` to `$PATH`, provides `BATS_LIB_PATH` output. Released 2025-02-08. |
| actions/checkout | v5 | Clone repo with submodules | Standard checkout action. `submodules: recursive` populates bats-core and helper library submodules. |
| mikepenz/action-junit-report | v6 | Convert JUnit XML to GitHub annotations | 3.5k+ stars, actively maintained (v6.2.0 released 2025-01-31). Creates GitHub Check Run with test results, supports PR annotations. |
| BATS `--report-formatter junit` | Built into bats-core v1.13.0 | Generate JUnit XML report file | Built-in BATS formatter. Generates `report.xml` in specified `--output` directory. Compatible with standard JUnit XML schema. |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| actions/upload-artifact | v4 | Upload JUnit XML as workflow artifact | Optional: preserve test reports beyond workflow run for debugging |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `bats-action@4.0.0` | `checkout --recursive` only (run `./tests/bats/bin/bats` directly) | Would work since submodules contain bats binary. But CI-01 requirement explicitly specifies `bats-action@4.0.0`. Using the action also provides caching and ensures `bats` is on PATH for cleaner workflow steps. |
| `mikepenz/action-junit-report@v6` | `dorny/test-reporter@v1` | dorny/test-reporter has JUnit support marked "experimental". mikepenz is more widely used for JUnit specifically, with better maintenance. |
| `mikepenz/action-junit-report@v6` | `EnricoMi/publish-unit-test-result-action@v2` | More features but heavier. mikepenz is simpler, focused on JUnit only. |
| Separate workflow files | Single workflow with multiple jobs | Both work for CI-03. Separate files are simpler (no `needs:` management) and the ShellCheck workflow already exists. Adding a new file avoids modifying existing working config. |

## Architecture Patterns

### Recommended Project Structure

```
.github/
  workflows/
    shellcheck.yml          # EXISTING - lint shell scripts (unchanged)
    deploy-site.yml         # EXISTING - deploy docs site (unchanged)
    tests.yml               # NEW - BATS test suite with JUnit reporting
```

### Pattern 1: BATS CI Workflow with JUnit Reporting

**What:** A GitHub Actions workflow that runs BATS tests, generates JUnit XML, and publishes results as PR annotations.

**When to use:** CI-01, CI-02, CI-03 -- the full phase.

**Example:**

```yaml
# .github/workflows/tests.yml
name: Tests

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

permissions:
  contents: read
  checks: write

jobs:
  bats:
    name: BATS test suite
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v5
        with:
          submodules: recursive

      - name: Setup BATS
        uses: bats-core/bats-action@4.0.0
        with:
          bats-version: 1.13.0
          support-install: false
          assert-install: false
          detik-install: false
          file-install: false

      - name: Run BATS tests
        run: bats tests/ --report-formatter junit --output "$RUNNER_TEMP" --timing
        env:
          TERM: xterm

      - name: Publish test results
        uses: mikepenz/action-junit-report@v6
        if: always()
        with:
          report_paths: '${{ runner.temp }}/report.xml'
```

**Source:** Synthesized from [bats-action README](https://github.com/bats-core/bats-action), [bats-core usage docs](https://bats-core.readthedocs.io/en/stable/usage.html), [action-junit-report README](https://github.com/mikepenz/action-junit-report)

### Pattern 2: Submodule-First Library Loading in CI

**What:** Use `checkout --recursive` to populate submodule directories, so `common-setup.bash` uses the submodule path (not `bats_load_library`).

**When to use:** Always in this project. The `common-setup.bash` checks `if [[ -d "${PROJECT_ROOT}/tests/test_helper/bats-support" ]]` and loads from submodules when the directory exists.

**How it works in CI:**
1. `actions/checkout@v5` with `submodules: recursive` clones all four submodules
2. `bats-action@4.0.0` installs `bats` binary to `$HOME/.local/share/bats/bin` and adds it to `$PATH`
3. We disable all library installations in `bats-action` (`support-install: false`, etc.) because submodules already provide them
4. `bats` command runs tests; `common-setup.bash` finds submodule directories and loads libraries from there

**Why disable bats-action library installs:** The submodules are pinned to exact versions (support v0.3.0, assert v2.2.0, file v0.4.0) matching local development. bats-action defaults differ (assert defaults to v2.1.0, not v2.2.0). Using submodules ensures version parity between local and CI.

### Pattern 3: Independent Workflow Files (CI-03)

**What:** BATS tests and ShellCheck linting run as completely independent workflows in separate files.

**When to use:** CI-03 requires neither blocks the other.

**How it works:**
- `shellcheck.yml` already exists and triggers on `push: main` and `pull_request: main`
- `tests.yml` triggers on the same events
- GitHub Actions runs workflows independently by default -- no `needs:` or dependency between separate workflow files
- A failure in ShellCheck does not affect BATS test results, and vice versa
- Both appear as separate check runs on the PR

### Anti-Patterns to Avoid

- **Using `--recursive` flag with `bats`:** BATS `--recursive` discovers `.bats` files in subdirectories. The project deliberately uses non-recursive discovery (`bats tests/`) to avoid running bats-core's own internal test fixtures in `tests/bats/test/`. The Makefile's `test` target does NOT use `--recursive`. CI must match.
- **Installing bats-action libraries alongside submodules:** Creates version confusion. If submodules provide v2.2.0 of bats-assert but bats-action installs v2.1.0 globally, the `BATS_LIB_PATH` fallback path would load wrong version if submodule detection fails.
- **Using `--formatter junit` (instead of `--report-formatter junit`):** `--formatter` replaces terminal output with JUnit XML. `--report-formatter` writes JUnit to a file while keeping pretty/TAP output on stdout. CI wants both: readable logs AND XML report.
- **Omitting `if: always()` on the report step:** If tests fail, the workflow step exits non-zero. Without `if: always()`, the JUnit report step is skipped -- meaning failures are never reported as annotations. The whole point of CI-02 is to see failures.
- **Using `if: success() || failure()`:** Slightly better but still skips on cancellation. `if: always()` is the simplest and most robust option for the reporting step.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| BATS installation on CI | `curl` + manual install script | `bats-action@4.0.0` | Handles caching, PATH setup, version pinning, cross-platform |
| JUnit XML generation | Custom TAP-to-JUnit converter | `bats --report-formatter junit` | Built into bats-core since v1.7.0+. Tested, maintained, handles edge cases (XML escaping, ANSI stripping) |
| PR test annotations | Manual `::error file=...` workflow commands | `mikepenz/action-junit-report@v6` | Creates proper GitHub Check Runs with expandable test results, not just log annotations |
| Parallel workflow execution | Job dependency management with `needs:` | Separate workflow files | GitHub runs separate workflows independently by default. No coordination code needed. |

**Key insight:** The BATS JUnit formatter is already bundled in the project's submodule at `tests/bats/libexec/bats-core/bats-format-junit` (verified: 262 lines of bash, handles XML escaping, ANSI stripping, timing data). No external JUnit conversion tool is needed.

## Common Pitfalls

### Pitfall 1: Submodules Not Checked Out in CI

**What goes wrong:** `actions/checkout` does NOT check out submodules by default. Without `submodules: recursive`, the `tests/bats/`, `tests/test_helper/bats-support/`, etc. directories are empty. `common-setup.bash` falls through to `bats_load_library`, but if `bats-action` library installs are also disabled, tests fail with "library not found".

**Why it happens:** GitHub Actions checkout defaults to `submodules: false` for speed.

**How to avoid:** Always use `submodules: recursive` in the checkout step. This is non-negotiable for this project since the bats binary itself comes from the submodule (or bats-action).

**Warning signs:** CI fails with "load: cannot find ..." or "bats_load_library: ..." errors.

### Pitfall 2: `--recursive` Flag on BATS Command

**What goes wrong:** Using `bats --recursive tests/` discovers `.bats` files inside `tests/bats/test/` (the bats-core internal test suite) -- approximately 40+ internal fixture files that will fail in this context.

**Why it happens:** `tests/bats/` is a full checkout of bats-core including its own test directory.

**How to avoid:** Use `bats tests/` WITHOUT `--recursive`. The project's test files live at `tests/*.bats` (flat, non-recursive). The Makefile target does not use `--recursive`. This was a deliberate Phase 18 decision.

**Warning signs:** Hundreds of unexpected tests appear, many failing with missing fixtures or helper files.

### Pitfall 3: JUnit Report File Not Found

**What goes wrong:** The `action-junit-report` step fails because `report.xml` does not exist at the expected path.

**Why it happens:** BATS writes `report.xml` to the current working directory by default. If the working directory or `--output` path is wrong, the file ends up somewhere unexpected.

**How to avoid:** Use `--output "$RUNNER_TEMP"` to write to a known, writable directory. Then reference `${{ runner.temp }}/report.xml` in the report action. Using `$RUNNER_TEMP` is idiomatic for GitHub Actions -- it's cleaned up automatically.

**Warning signs:** Report step shows "No test report files were found" warning.

### Pitfall 4: bats-action Library Version Mismatch

**What goes wrong:** bats-action defaults to `assert-version: 2.1.0` but the project submodule pins `bats-assert v2.2.0`. If both are installed, the `BATS_LIB_PATH` version differs from the submodule version.

**Why it happens:** bats-action's defaults are not updated to match latest releases.

**How to avoid:** Disable all library installs in bats-action (`support-install: false`, `assert-install: false`, `detik-install: false`, `file-install: false`). Use submodules for libraries. Use bats-action only for the `bats` binary.

**Warning signs:** Tests pass locally but behave differently in CI due to different assertion library version.

### Pitfall 5: Missing `checks: write` Permission

**What goes wrong:** `action-junit-report` fails with "Resource not accessible by integration" or "Bad credentials" error.

**Why it happens:** The default `GITHUB_TOKEN` for `pull_request` events from forks has read-only permissions. Even for same-repo PRs, `checks: write` must be explicitly declared.

**How to avoid:** Add `permissions: checks: write` at the workflow or job level. The existing `shellcheck.yml` only uses `permissions: contents: read`, so this is a new permission specific to the test workflow.

**Warning signs:** JUnit report step fails with 403/permission error, test results never appear as PR annotations.

### Pitfall 6: Tests Always Show as Passing Despite Failures

**What goes wrong:** The `bats` command fails (non-zero exit), but the JUnit report step never runs.

**Why it happens:** Without `if: always()` on the report step, GitHub Actions skips subsequent steps when a previous step fails.

**How to avoid:** Add `if: always()` to the `action-junit-report` step. This ensures the report is published even when tests fail -- which is precisely when you need it most.

**Warning signs:** CI shows "BATS tests failed" in logs but no annotation or check run for the test results.

## Code Examples

Verified patterns from official sources:

### Complete Workflow File (.github/workflows/tests.yml)

```yaml
# Source: Synthesized from bats-action README, action-junit-report README, bats-core docs
name: Tests

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

permissions:
  contents: read
  checks: write

jobs:
  bats:
    name: BATS test suite
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v5
        with:
          submodules: recursive

      - name: Setup BATS
        uses: bats-core/bats-action@4.0.0
        with:
          bats-version: 1.13.0
          support-install: false
          assert-install: false
          detik-install: false
          file-install: false

      - name: Run BATS tests
        run: bats tests/ --report-formatter junit --output "$RUNNER_TEMP" --timing
        env:
          TERM: xterm

      - name: Publish test results
        uses: mikepenz/action-junit-report@v6
        if: always()
        with:
          report_paths: '${{ runner.temp }}/report.xml'
```

### BATS JUnit Command Line

```bash
# Generate JUnit report to specific directory, with pretty terminal output
bats tests/ --report-formatter junit --output /path/to/reports --timing

# This generates:
#   /path/to/reports/report.xml    (JUnit XML)
#   stdout: TAP output with timing (default formatter for non-terminal)
```

Source: [bats-core usage docs](https://bats-core.readthedocs.io/en/stable/usage.html)

### JUnit XML Output Format (from BATS)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<testsuites time="12.345">
  <testsuite name="tests/smoke.bats" tests="5" failures="0" errors="0" skipped="0"
             time="1.234" timestamp="2026-02-12T10:00:00" hostname="runner">
    <testcase classname="tests/smoke.bats" name="BATS runs and assertions work" time="0.080" />
    <testcase classname="tests/smoke.bats" name="bats-file assertions work" time="0.074" />
  </testsuite>
</testsuites>
```

Source: Verified from `tests/bats/libexec/bats-core/bats-format-junit` (bundled in submodule)

### Existing ShellCheck Workflow (reference -- do not modify)

```yaml
# .github/workflows/shellcheck.yml (EXISTING, unchanged by this phase)
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
        uses: actions/checkout@v5
      - name: Run ShellCheck
        run: |
          find . -name '*.sh' \
            -not -path './site/*' \
            -not -path './.planning/*' \
            -not -path './node_modules/*' \
            -not -path './tests/bats/*' \
            -not -path './tests/test_helper/bats-*/*' \
            -exec shellcheck --severity=warning {} +
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `--formatter junit` (replaces terminal output) | `--report-formatter junit` (writes file, keeps terminal output) | bats-core v1.7.0+ | Can have readable CI logs AND JUnit report simultaneously |
| `dorny/test-reporter` (JUnit "experimental") | `mikepenz/action-junit-report@v6` | 2024+ | More reliable JUnit parsing, better maintained for JUnit specifically |
| `bats-action@3.x` (auto-passes GitHub token) | `bats-action@4.0.0` (no auto-token) | 2025-02-08 | Breaking change: must pass `github-token` explicitly if hitting rate limits |
| Single workflow file with multiple jobs | Separate workflow files | Current best practice | Simpler, no cross-job dependency management, each workflow has focused permissions |

**Deprecated/outdated:**
- **`ffurrer2/bats-action`:** Docker-based alternative. Much slower than `bats-core/bats-action` (pulls Docker image). Not the official bats-core action.
- **Manual `install.sh` in CI:** Unnecessarily complex when `bats-action` handles caching, PATH, and version management.
- **`actions/checkout@v4`:** The existing workflows already use `@v5`. Continue with v5 for consistency.

## Specific Implementation Details for Phase 21

### CI-01: GitHub Actions Workflow with bats-action@4.0.0

**File:** `.github/workflows/tests.yml`

**Key decisions:**
1. Use `bats-action@4.0.0` with `bats-version: 1.13.0` (pin exact version, don't rely on "latest")
2. Disable all library installs (`support-install: false`, `assert-install: false`, `detik-install: false`, `file-install: false`) -- submodules provide the libraries at pinned versions
3. Use `submodules: recursive` in checkout -- critical for populating bats-core binary and helper libraries
4. Use `bats tests/` (NOT `bats tests/ --recursive`) -- matches Makefile behavior, avoids bats internal fixtures
5. Set `TERM: xterm` environment variable for the bats step (prevents terminal detection issues)

**Why `bats-action` when we have submodules:** bats-action adds `bats` to `$PATH`, provides caching, and makes the workflow step cleaner (`bats tests/` vs `./tests/bats/bin/bats tests/`). The requirement CI-01 explicitly specifies it.

**Alternative if bats-action were not required:** Could use `./tests/bats/bin/bats tests/` directly from the submodule. Would still need `submodules: recursive` in checkout. Simpler but does not satisfy CI-01.

### CI-02: JUnit Format for Test Annotations

**Approach:** Two-step process:
1. BATS generates JUnit XML via `--report-formatter junit --output "$RUNNER_TEMP"`
2. `mikepenz/action-junit-report@v6` reads the XML and creates a GitHub Check Run with annotations

**JUnit report file location:** `$RUNNER_TEMP/report.xml` -- `$RUNNER_TEMP` is a GitHub Actions-provided temp directory, cleaned up after the workflow. Reference in the action as `${{ runner.temp }}/report.xml`.

**Permissions:** `checks: write` at the workflow level (or job level). This permission is required for `action-junit-report` to create Check Runs.

**The `if: always()` requirement:** The report step MUST use `if: always()` so it runs even when tests fail. Without this, the step is skipped on failure, and annotations never appear.

### CI-03: Independent Jobs

**Approach:** Keep ShellCheck in its existing `shellcheck.yml` file. Create BATS tests in a new `tests.yml` file. No `needs:` dependencies between workflows.

**How GitHub handles this:**
- Each workflow file is triggered independently
- Both workflows run in parallel on the same event (push/PR)
- Failure in one does not affect the other
- Each appears as a separate "Check" on the PR
- No changes to `shellcheck.yml` required

**Integration test count on CI (Linux):** 187 tests (vs 186 on macOS, due to `diagnose-latency.sh` inclusion on Linux per Phase 20 decision).

## Open Questions

1. **`report.xml` filename hardcoded?**
   - What we know: The bats JUnit formatter writes to `report.xml` in the `--output` directory. The `bats-format-junit` source does not show a configurable filename.
   - What's unclear: Whether the filename can be customized. The bats docs show `report.xml` in examples.
   - Recommendation: Use the default `report.xml` name. Set `report_paths: '${{ runner.temp }}/report.xml'` in the action. If the name proves different, adjust the glob pattern (e.g., `'${{ runner.temp }}/*.xml'`).

2. **PR annotations for forked PRs?**
   - What we know: `action-junit-report` requires `checks: write` permission. For PRs from forks, the `GITHUB_TOKEN` is read-only.
   - What's unclear: Whether this project accepts external contributions from forks.
   - Recommendation: Start with basic `permissions: checks: write`. If fork support is needed later, investigate `workflow_run` trigger pattern. Out of scope for Phase 21.

## Sources

### Primary (HIGH confidence)
- [bats-core/bats-action releases](https://github.com/bats-core/bats-action/releases) -- v4.0.0 released 2025-02-08, verified via WebFetch
- [bats-action README/action.yaml](https://github.com/bats-core/bats-action) -- All inputs, outputs, PATH setup, library installation behavior verified via WebFetch
- [bats-core official usage docs](https://bats-core.readthedocs.io/en/stable/usage.html) -- `--report-formatter`, `--output`, `--timing` flags verified via WebFetch
- [mikepenz/action-junit-report](https://github.com/mikepenz/action-junit-report) -- v6.2.0 (latest, 2025-01-31), inputs, permissions, `if: always()` pattern verified via WebFetch
- Codebase: `tests/bats/libexec/bats-core/bats-format-junit` -- 262-line JUnit formatter, XML structure verified by reading source
- Codebase: `tests/test_helper/common-setup.bash` -- Dual-path loading (submodule-first, bats_load_library fallback)
- Codebase: `.github/workflows/shellcheck.yml` -- Existing workflow, triggers, permissions, structure
- Codebase: `.github/workflows/deploy-site.yml` -- Existing workflow for reference
- Codebase: `.gitmodules` -- Four submodules: bats-core, bats-support, bats-assert, bats-file
- Codebase: `Makefile` -- `test` target: `./tests/bats/bin/bats tests/ --timing` (non-recursive)
- Phase 18 research: `.planning/phases/18-bats-infrastructure/18-RESEARCH.md` -- Version pins, dual-path loading decision, non-recursive discovery
- Phase 20 summary: `.planning/phases/20-script-integration-tests/20-01-SUMMARY.md` -- 186 tests, mock infrastructure, Linux vs macOS test counts

### Secondary (MEDIUM confidence)
- [bats-core issue #342](https://github.com/bats-core/bats-core/issues/342) -- Confirmed `--formatter` and `--report-formatter` can be used simultaneously
- [GitHub Actions workflow syntax docs](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions) -- `if: always()`, permissions, job independence

### Tertiary (LOW confidence)
- bats-action `bats-version` default documentation says "default to latest (1.11.0 atm)" but actual latest is v1.13.0. This stale documentation was identified in Phase 18 research. Recommendation to pin explicitly remains valid.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- All action versions verified via release pages, bats JUnit formatter verified by reading source code, permissions verified via action-junit-report README
- Architecture: HIGH -- Workflow pattern follows standard GitHub Actions conventions, submodule-first loading already proven in local tests, independent workflow files are the simplest approach
- Pitfalls: HIGH -- Non-recursive discovery documented in Phase 18, submodule checkout requirement verified empirically, `if: always()` pattern documented in action-junit-report README, version mismatch risk verified by comparing bats-action defaults vs submodule pins

**Research date:** 2026-02-12
**Valid until:** 2026-03-12 (GitHub Actions ecosystem is stable; pinned action versions prevent drift)
