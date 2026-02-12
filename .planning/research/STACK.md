# Technology Stack: BATS Testing Framework & Script Metadata Headers

**Project:** networking-tools -- BATS test migration and structured script headers
**Researched:** 2026-02-11
**Scope:** BATS test framework, helper libraries, CI integration, script metadata header format
**Constraint:** Must coexist with existing ShellCheck CI, Bash 4.0+ minimum, macOS primary + Linux CI

## Existing Stack (Validated, DO NOT Re-research)

| Technology | Version | Status |
|------------|---------|--------|
| Bash | 4.0+ target (5.3.9 on dev macOS via Homebrew) | Established |
| common.sh | Entry point sourcing 9 library modules from scripts/lib/ | Established |
| ShellCheck | 0.11.0 | CI via `.github/workflows/shellcheck.yml` on ubuntu-latest |
| GNU Make | System | Makefile with lint target, tool runners |
| Ad-hoc tests | tests/test-arg-parsing.sh (268 tests), tests/test-library-loads.sh (39 checks) | To be migrated |

**Current test harness pattern:** Manual pass/fail counters, `check_pass()`/`check_fail()` functions, `PASS_COUNT`/`FAIL_COUNT` globals, inline assertions with `if/else`. Functional but no TAP output, no parallel execution, no per-test isolation, no assertion library.

---

## Recommended Stack Additions

### 1. BATS-Core (Test Runner)

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| bats-core | v1.13.0 | TAP-compliant bash test runner | The only mature, actively maintained bash test framework. TAP output integrates with CI. Supports parallel execution, test tagging, setup/teardown lifecycle hooks, and test filtering. |

**Version rationale:** v1.13.0 (released 2024-11-07) is the latest stable release. Key features used by this project: `--filter` for running specific test subsets, `--jobs` for parallel execution, `setup_file`/`teardown_file` for per-file fixtures, and TAP output for CI parsers.

**Confidence: HIGH** -- Version verified via [GitHub releases page](https://github.com/bats-core/bats-core/releases).

### 2. BATS Helper Libraries

| Library | Version | Purpose | Why |
|---------|---------|---------|-----|
| bats-support | v0.3.0 | Shared output formatting and error reporting | Required dependency for bats-assert. Provides `fail` and output formatting primitives. |
| bats-assert | v2.2.0 | Assertion functions (assert_success, assert_failure, assert_output, assert_line) | Replaces manual `if/else` assertion boilerplate. Provides clear failure messages with expected vs actual diffs. |
| bats-file | v0.4.0 | Filesystem assertions (assert_file_exists, assert_dir_exists, assert_file_contains) | Useful for testing temp file cleanup, script output files, and directory structure validation. |

**bats-assert v2.2.0 vs v2.2.4:** The bats-action defaults to v2.1.0. The latest release is v2.2.4 (2024-10-14), which adds Bash 5.3 regex error forwarding. Use v2.2.0 (2024-08-15) because it includes the useful stderr assertion functions (`assert_stderr`, `assert_stderr_line`) without the v2.2.1-v2.2.4 churn on regex edge cases. Pin this version explicitly.

**bats-detik: NOT needed.** The bats-action installs bats-detik (Kubernetes testing) by default. This project has zero Kubernetes components. Disable in CI config: `detik-install: false`.

**Confidence: HIGH** -- Versions verified via GitHub releases pages for [bats-assert](https://github.com/bats-core/bats-assert/releases), [bats-support](https://github.com/bats-core/bats-support/releases), [bats-file](https://github.com/bats-core/bats-file/releases).

### 3. GitHub Action for CI

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| bats-core/bats-action | 4.0.0 | Install BATS + all helper libraries in CI | Official action from the bats-core organization. Handles binary caching, library installation, and BATS_LIB_PATH configuration. Updated 2025-02-08. |

**Confidence: HIGH** -- Version and inputs verified via [GitHub Marketplace listing](https://github.com/marketplace/actions/setup-bats-and-bats-libraries).

### 4. Script Metadata Headers (No External Tools)

No external tools needed. Use a lightweight, project-specific header comment convention inspired by shdoc syntax but without requiring shdoc as a dependency. The headers are parseable by simple grep/awk for future tooling (catalog generation, help systems) without adding a build-time dependency.

**Why NOT full shdoc:** shdoc (v1.2, 2023-07-31) is a documentation generator that reads `@tag` annotations and produces Markdown. It is useful for library code with many exported functions. This project's scripts are not libraries -- they are CLI tools with `show_help()` functions that already document usage. Adding shdoc would create a parallel documentation system. Instead, use a minimal header format that captures metadata shdoc cannot (tool category, required tools, target type) while remaining human-readable.

**Confidence: MEDIUM** -- shdoc tags reviewed via [reconquest/shdoc](https://github.com/reconquest/shdoc). Header format is a project-specific convention, not an industry standard.

---

## Installation Method: Git Submodules for Local, bats-action for CI

### Why Git Submodules (not npm, not Homebrew)

| Method | Pros | Cons | Verdict |
|--------|------|------|---------|
| **Git submodules** | Pinned versions in repo, works offline, no runtime dependency manager, CI and local use same code | Requires `git submodule update --init` after clone | **USE THIS** |
| npm | Easy install (`npm i -D bats`) | bats-support, bats-assert, bats-file are NOT published to npm. Only bats-core is on npm. Cannot use npm for the full stack. | **REJECTED** |
| Homebrew | One-liner install (`brew install bats-core`) | Different versions between local and CI. Homebrew taps for bats-assert/bats-file exist but lag behind releases. Not reproducible. Linux CI would need separate install method. | **REJECTED** |
| Direct download in CI | No submodule overhead | Version drift between local and CI. Two install mechanisms to maintain. | **REJECTED** |

**The npm blocker is definitive:** Helper libraries (bats-support, bats-assert, bats-file) are not published to npm. This was confirmed as a known gap in [bats-core issue #493](https://github.com/bats-core/bats-core/issues/493). Git submodules are the officially recommended approach per the [bats-core tutorial](https://bats-core.readthedocs.io/en/stable/tutorial.html).

**Dual strategy:** Git submodules for local development (pinned, reproducible). bats-action for CI (faster, avoids submodule init in workflows). Both use the same library versions because we pin versions explicitly in both places.

**Confidence: HIGH** -- npm limitation verified via bats-core GitHub issues. Submodule approach verified via official bats-core documentation.

### Submodule Setup

```bash
# From project root
git submodule add https://github.com/bats-core/bats-core.git tests/bats
git submodule add https://github.com/bats-core/bats-support.git tests/test_helper/bats-support
git submodule add https://github.com/bats-core/bats-assert.git tests/test_helper/bats-assert
git submodule add https://github.com/bats-core/bats-file.git tests/test_helper/bats-file
```

Pin to specific versions via tag checkout within each submodule:

```bash
cd tests/bats && git checkout v1.13.0 && cd ../..
cd tests/test_helper/bats-support && git checkout v0.3.0 && cd ../../..
cd tests/test_helper/bats-assert && git checkout v2.2.0 && cd ../../..
cd tests/test_helper/bats-file && git checkout v0.4.0 && cd ../../..
```

### Directory Structure

```
tests/
  bats/                          # git submodule: bats-core v1.13.0
  test_helper/
    bats-support/                # git submodule: v0.3.0
    bats-assert/                 # git submodule: v2.2.0
    bats-file/                   # git submodule: v0.4.0
    common-setup.bash            # shared setup: load helpers, set PROJECT_ROOT
  lib/                           # tests for scripts/lib/ modules
    logging.bats
    validation.bats
    args.bats
    cleanup.bats
    colors.bats
    output.bats
    strict.bats
  scripts/                       # tests for tool scripts
    nmap.bats
    ...
  integration/                   # cross-cutting integration tests
    common-source.bats
    help-flag.bats
    execute-mode.bats
  test-arg-parsing.sh            # KEEP: legacy tests (migrate incrementally)
  test-library-loads.sh          # KEEP: legacy tests (migrate incrementally)
```

---

## CI Integration

### New Workflow: `.github/workflows/bats.yml`

```yaml
name: BATS Tests

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

permissions:
  contents: read

jobs:
  bats:
    name: Run BATS tests
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v5

      - name: Setup BATS
        id: setup-bats
        uses: bats-core/bats-action@4.0.0
        with:
          bats-version: 1.13.0
          support-version: 0.3.0
          assert-version: 2.2.0
          file-version: 0.4.0
          detik-install: false

      - name: Run tests
        env:
          BATS_LIB_PATH: ${{ steps.setup-bats.outputs.lib-path }}
          TERM: xterm
        run: |
          bats tests/ --recursive --jobs 4 --timing
```

**Key decisions:**
- `detik-install: false` -- no Kubernetes components in this project
- `--recursive` -- discovers `.bats` files in subdirectories
- `--jobs 4` -- parallel test execution (ubuntu-latest has 4 cores)
- `--timing` -- shows per-test timing for identifying slow tests
- `TERM: xterm` -- required for bats output formatting in CI
- Separate workflow file (not merged into shellcheck.yml) -- tests and linting are independent concerns with different failure modes

### Coexistence with Existing ShellCheck CI

The existing `.github/workflows/shellcheck.yml` remains unchanged. The new `bats.yml` workflow runs in parallel. ShellCheck must also lint the new `.bats` files -- bats files are valid bash and should pass ShellCheck. However, ShellCheck does not natively understand `@test` syntax. Two approaches:

**Approach A (recommended):** Exclude `.bats` files from the ShellCheck workflow. Bats files have unusual syntax (`@test` blocks, `load` commands) that ShellCheck does not handle. ShellCheck lints the source code; BATS tests the behavior.

```bash
# In shellcheck.yml, add exclusion:
find . -name '*.sh' \
  -not -path './site/*' \
  -not -path './.planning/*' \
  -not -path './node_modules/*' \
  -not -path './tests/bats/*' \
  -not -path './tests/test_helper/*' \
  -exec shellcheck --severity=warning {} +
```

**Approach B:** Use `# shellcheck shell=bash` directive in `.bats` files and suppress bats-specific warnings. More work, fragile, not recommended.

---

## Library Loading Pattern

### Local Development (submodules)

```bash
# tests/test_helper/common-setup.bash

# Resolve project root
PROJECT_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd)"

# Load helper libraries from submodules
load "${PROJECT_ROOT}/tests/test_helper/bats-support/load"
load "${PROJECT_ROOT}/tests/test_helper/bats-assert/load"
load "${PROJECT_ROOT}/tests/test_helper/bats-file/load"

# Add project scripts to PATH for testing
export PATH="${PROJECT_ROOT}/scripts:${PATH}"
```

### CI (bats-action)

```bash
# tests/test_helper/common-setup.bash (same file, works for both)

PROJECT_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd)"

# Try bats_load_library first (CI with BATS_LIB_PATH), fall back to submodules (local)
if [[ -n "${BATS_LIB_PATH:-}" ]]; then
    bats_load_library bats-support
    bats_load_library bats-assert
    bats_load_library bats-file
else
    load "${PROJECT_ROOT}/tests/test_helper/bats-support/load"
    load "${PROJECT_ROOT}/tests/test_helper/bats-assert/load"
    load "${PROJECT_ROOT}/tests/test_helper/bats-file/load"
fi

export PATH="${PROJECT_ROOT}/scripts:${PATH}"
```

**Why the dual-path approach:** `bats_load_library` uses `BATS_LIB_PATH` to find system-installed libraries (set by bats-action in CI). Locally, submodule paths are used directly via `load`. This single file works in both environments without conditional CI-specific configuration.

**Confidence: HIGH** -- `bats_load_library` vs `load` behavior verified via [bats-core documentation](https://bats-core.readthedocs.io/en/stable/writing-tests.html).

---

## Script Metadata Header Format

### Recommended Format

```bash
#!/usr/bin/env bash
# -------------------------------------------------------------------
# @name        nmap/discover-live-hosts.sh
# @description Find all active hosts on a subnet
# @tool        nmap
# @category    use-case
# @target      required (subnet or IP)
# @requires    nmap
# -------------------------------------------------------------------
source "$(dirname "$0")/../common.sh"
```

### Tag Definitions

| Tag | Required | Values | Purpose |
|-----|----------|--------|---------|
| `@name` | Yes | Relative path from scripts/ | Unique identifier, matches filesystem path |
| `@description` | Yes | One-line summary | What the script does (shown in catalogs) |
| `@tool` | Yes | Tool name (nmap, tshark, etc.) | Groups scripts by tool |
| `@category` | Yes | `examples`, `use-case`, `diagnostic`, `library` | Script type classification |
| `@target` | For non-library | `required`, `optional (default=X)`, `none` | Whether script needs a target argument |
| `@requires` | For non-library | Comma-separated tool names | External commands needed (for `require_cmd`) |

### Why This Format (Not shdoc, Not YAML Front Matter)

| Alternative | Why Not |
|------------|---------|
| Full shdoc `@arg`/`@option`/`@exitcode` tags | Overkill. Scripts already have `show_help()` documenting usage. Duplicating arg docs in both header AND help text creates maintenance burden. |
| YAML front matter (`---` delimited) | Not a bash convention. Requires a YAML parser to extract. Grep/awk can parse `# @tag value` trivially. |
| No headers (status quo) | Current headers are inconsistent: `# nmap/examples.sh -- Network Mapper: host discovery and port scanning` vs `# nmap/identify-ports.sh -- Identify what's behind open ports`. No structured metadata for tooling. |
| Google Shell Style Guide headers | Recommends `# Description:` and `# Globals:` blocks. Good for library functions, but does not include tool-specific metadata (`@tool`, `@category`, `@target`). |

### Parsing Headers Programmatically

```bash
# Extract all @tool values across the project
grep -rh '# @tool' scripts/ | sed 's/# @tool *//' | sort -u

# List all use-case scripts
grep -rl '# @category.*use-case' scripts/

# Find scripts requiring nmap
grep -rl '# @requires.*nmap' scripts/
```

**No build step required.** Headers are grep-parseable. A future Makefile target or script can generate a catalog, but it is not a prerequisite for this milestone.

**Confidence: MEDIUM** -- This is a project-specific convention. The `@tag` syntax is inspired by shdoc/JSDoc but simplified. No external standard to verify against -- this is a design decision.

---

## Makefile Integration

### New Targets

```makefile
test: ## Run BATS tests
	@./tests/bats/bin/bats tests/ --recursive --timing

test-verbose: ## Run BATS tests with verbose output
	@./tests/bats/bin/bats tests/ --recursive --timing --verbose-run

test-filter: ## Run specific BATS tests (usage: make test-filter FILTER=logging)
	@./tests/bats/bin/bats tests/ --recursive --filter "$(FILTER)"
```

**Run bats from the submodule directly** (`./tests/bats/bin/bats`), not from system PATH. This ensures the pinned version is used regardless of what is installed globally. No `brew install bats-core` required for contributors.

---

## Migration Strategy for Existing Tests

### Do NOT Delete Existing Tests Immediately

The existing test files (`test-arg-parsing.sh` with 268 tests, `test-library-loads.sh` with 39 checks) represent validated behavior. Migrate incrementally:

1. **Phase 1:** Set up BATS infrastructure (submodules, test_helper, CI workflow, Makefile targets)
2. **Phase 2:** Write NEW tests in BATS for library modules (scripts/lib/*.sh)
3. **Phase 3:** Migrate `test-library-loads.sh` checks to BATS (39 checks become ~39 `@test` blocks)
4. **Phase 4:** Migrate `test-arg-parsing.sh` checks to BATS (268 tests become organized `.bats` files)
5. **Phase 5:** Delete legacy test files once all checks are covered

**Why incremental:** A big-bang rewrite risks regression. Keep both systems running in CI until BATS coverage matches legacy coverage. Compare test counts to ensure nothing is lost.

---

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Test framework | bats-core | shunit2 | shunit2 uses xUnit patterns (setUp/tearDown/assertEquals) familiar to Java developers, but bats has broader community adoption, native TAP output, parallel execution, and an official GitHub Action. shunit2 has not had a release since 2022. |
| Test framework | bats-core | Roundup | Abandoned since 2013. |
| Test framework | bats-core | bashunit | Newer (2023+) but very small community. 400 GitHub stars vs bats-core's 5000+. Not battle-tested. |
| Test framework | bats-core | Pure bash (keep current) | Current harness works but lacks: parallel execution, TAP output, per-test isolation, assertion library, test filtering, CI integration action. Migration cost is justified by these gains. |
| Assertion library | bats-assert | Manual `[[ ]]` checks | bats-assert provides clear failure diffs ("expected X, got Y") vs silent test failure. Worth the dependency. |
| Installation | Git submodules | npm | Helper libraries not on npm. Blocker. |
| Installation | Git submodules | Homebrew only | Not reproducible across macOS/Linux. CI would need different install. |
| CI action | bats-core/bats-action@4.0.0 | Manual bats install in CI | Action handles caching, BATS_LIB_PATH setup, version pinning. Manual install is more YAML to maintain. |
| Metadata headers | Custom `@tag` format | Full shdoc | shdoc is a doc generator for library functions. Project scripts are CLI tools with `show_help()`. Two doc systems create maintenance burden. |
| Metadata headers | Custom `@tag` format | No headers (status quo) | Current headers are inconsistent and not machine-parseable. Structured metadata enables future tooling (catalog, validation). |

---

## Version Pinning Summary

| Component | Pinned Version | Latest Available | Notes |
|-----------|---------------|-----------------|-------|
| bats-core | v1.13.0 | v1.13.0 | Latest stable |
| bats-support | v0.3.0 | v0.3.0 | Latest stable (re-released 2025-03-04 in migrated repo) |
| bats-assert | v2.2.0 | v2.2.4 | Pinned one minor behind latest; v2.2.1-v2.2.4 are regex edge case fixes not relevant to this project |
| bats-file | v0.4.0 | v0.4.0 | Latest stable |
| bats-action | 4.0.0 | 4.0.0 | Latest major (2025-02-08) |

---

## What NOT to Add

| Technology | Why Not |
|------------|---------|
| bats-detik | Kubernetes testing library. This project has no Kubernetes. Disable in bats-action config. |
| shdoc | Doc generator adds build-time dependency for marginal benefit. Scripts already have `show_help()`. |
| bashcov / kcov | Code coverage for bash. Interesting but premature -- get BATS running first. Coverage is a separate milestone. |
| bats-mock | Mock/stub library. The scripts under test print commands and source common.sh -- mocking at this level adds complexity. Test real behavior instead. |
| shellspec | Alternative BDD-style bash test framework. Switching to a different paradigm when bats-core is the dominant standard would be contrarian for no benefit. |
| npm/package.json | No JavaScript in the test stack. npm is not needed. |
| Docker for tests | Tests should run without Docker. The lab targets (DVWA, Juice Shop) are for manual practice, not automated testing. |

---

## Sources

### HIGH Confidence (Official documentation, verified releases)
- bats-core GitHub releases (v1.13.0): https://github.com/bats-core/bats-core/releases
- bats-assert GitHub releases (v2.2.0, v2.2.4): https://github.com/bats-core/bats-assert/releases
- bats-support GitHub releases (v0.3.0): https://github.com/bats-core/bats-support/releases
- bats-file GitHub releases (v0.4.0): https://github.com/bats-core/bats-file/releases
- bats-core/bats-action (v4.0.0): https://github.com/bats-core/bats-action
- bats-action GitHub Marketplace (inputs/defaults): https://github.com/marketplace/actions/setup-bats-and-bats-libraries
- bats-core official documentation (installation): https://bats-core.readthedocs.io/en/stable/installation.html
- bats-core official documentation (writing tests): https://bats-core.readthedocs.io/en/stable/writing-tests.html
- bats-core official tutorial (submodule setup): https://bats-core.readthedocs.io/en/stable/tutorial.html
- npm limitation for helper libraries (issue #493): https://github.com/bats-core/bats-core/issues/493

### MEDIUM Confidence (Community patterns verified against official docs)
- shdoc annotation format: https://github.com/reconquest/shdoc
- Git submodule pattern gist: https://gist.github.com/natbusa/1e4fc7c0b089f74560a6003dcd60dd9b
- Google Shell Style Guide (header conventions): https://google.github.io/styleguide/shellguide.html
- BashSupport Pro bats_load_library reference: https://www.bashsupport.com/bats-core/functions/bats_load_library/

### LOW Confidence (Single source, needs validation during implementation)
- bats-assert v2.2.0 stderr assertion functions -- mentioned in release notes but not verified in documentation
