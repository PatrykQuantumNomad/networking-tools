---
phase: 06-site-polish-and-learning-paths
plan: 03
subsystem: ci
tags: [ci, validation, docs-completeness, github-actions]

# Dependency graph
requires:
  - phase: 06-01
    provides: 15 MDX tool pages at site/src/content/docs/tools/
provides:
  - CI validation that every tool script has a corresponding docs page
  - Docs completeness bash script reusable for local pre-push checks
affects: [07-01, 07-02]

# Tech tracking
tech-stack:
  added: []
  patterns: ["bash glob + file-existence check for cross-directory validation", "fail-fast CI step before expensive build"]

key-files:
  created:
    - scripts/check-docs-completeness.sh
  modified:
    - .github/workflows/deploy-site.yml

key-decisions:
  - "|| true guard on ((errors++)) to prevent set -e exit when incrementing from 0"

# Metrics
duration: 3min
started: 2026-02-10T22:54:55Z
completed: 2026-02-10T22:57:50Z
tasks: 2
files_changed: 2
---

# Phase 6 Plan 03: CI Docs-Completeness Validation Summary

Bash validation script that fails CI when any tool script lacks a docs page, integrated as a fail-fast step before the Astro build in the deploy workflow.

## Tasks Completed

### Task 1: Create docs completeness validation script
**Commit:** `20cb52f`
**Files:** `scripts/check-docs-completeness.sh`

Created `scripts/check-docs-completeness.sh` that:
- Iterates over all `scripts/*/examples.sh` files (15 tools)
- Checks for corresponding `.md` or `.mdx` docs page in `site/src/content/docs/tools/`
- Prints actionable ERROR lines with expected file paths for any missing docs
- Exits 0 with "OK: All 15 tools have documentation pages" when all pass
- Exits 1 with "FAILED: N tool(s) missing documentation pages" when any are missing

Verified both the pass path (all 15 tools present) and the failure path (temporarily renamed nmap.mdx to confirm detection).

### Task 2: Add docs validation step to deploy workflow
**Commit:** `94688d5`
**Files:** `.github/workflows/deploy-site.yml`

Added "Validate docs completeness" step to the build job, positioned between Checkout and Build Astro site. This ensures the workflow fails fast with a clear error message before running the more expensive Astro build.

Final build job step order:
1. Checkout
2. Validate docs completeness (NEW)
3. Build Astro site

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed ((errors++)) exit under set -e**
- **Found during:** Task 1 verification
- **Issue:** `((errors++))` when `errors=0` evaluates to 0 (post-increment returns old value), which is falsy in arithmetic context, causing `set -e` to exit the script before printing the FAILED summary
- **Fix:** Added `|| true` guard: `((errors++)) || true`
- **Files modified:** `scripts/check-docs-completeness.sh`
- **Commit:** `20cb52f`

## Verification Results

| Check | Result |
|-------|--------|
| `bash scripts/check-docs-completeness.sh` exits 0 | PASSED - "OK: All 15 tools have documentation pages" |
| Script exits 1 when docs page missing | PASSED - Detected missing nmap page with actionable error |
| Workflow has 3 build steps in correct order | PASSED - Checkout, Validate, Build |
| `make site-build` still works | PASSED - 29 pages built |

## Self-Check: PASSED

All files exist. All commits verified.
