# Codebase Structure

**Analysis Date:** 2026-02-23

## Directory Layout

```
networking-tools/                  # Project root
├── scripts/                       # All bash scripts (core deliverable)
│   ├── common.sh                  # Library entry point (source this in every script)
│   ├── check-tools.sh             # Detects which tools are installed
│   ├── check-docs-completeness.sh # Validates doc coverage
│   ├── lib/                       # Shared library modules (10 files)
│   │   ├── strict.sh              # set -eEuo pipefail + ERR trap with stack trace
│   │   ├── colors.sh              # ANSI color variables (NO_COLOR aware)
│   │   ├── logging.sh             # info/warn/error/debug/success with log level filtering
│   │   ├── validation.sh          # require_cmd, require_target, check_cmd, require_root
│   │   ├── cleanup.sh             # EXIT trap, make_temp, retry_with_backoff
│   │   ├── json.sh                # JSON envelope: json_set_meta, json_add_result, json_finalize
│   │   ├── output.sh              # run_or_show, confirm_execute, safety_banner, PROJECT_ROOT
│   │   ├── args.sh                # parse_common_args (--help, -x, -j, -v, -q)
│   │   ├── diagnostic.sh          # run_check, report_pass/fail/warn/skip (Pattern B only)
│   │   └── nc_detect.sh           # detect_nc_variant (ncat/gnu/traditional/openbsd)
│   ├── <tool>/                    # One directory per tool (18 tools)
│   │   ├── examples.sh            # Pattern A: 10 educational examples
│   │   └── <use-case>.sh          # Pattern A: task-focused, supports -j -x flags
│   └── diagnostics/               # Pattern B: auto-run diagnostic reports
│       ├── connectivity.sh        # DNS, ICMP, TCP, HTTP, TLS layers check
│       ├── dns.sh                 # DNS resolution diagnostics
│       └── performance.sh         # Network performance diagnostics
├── labs/
│   └── docker-compose.yml         # Vulnerable practice targets (DVWA, Juice Shop, WebGoat, VulnerableApp)
├── tests/                         # BATS test suite
│   ├── bats/                      # BATS runner (git submodule)
│   ├── test_helper/               # bats-assert, bats-support, bats-file (git submodules)
│   ├── lib-*.bats                 # Unit tests for each lib/ module
│   ├── intg-*.bats                # Integration tests for script contracts
│   └── smoke.bats                 # End-to-end smoke tests
├── site/                          # Astro/Starlight documentation site
│   ├── src/
│   │   ├── content/docs/
│   │   │   ├── tools/             # One .mdx per tool (aircrack-ng.mdx, nmap.mdx, etc.)
│   │   │   ├── guides/            # Learning guides (getting-started, lab-walkthrough, etc.)
│   │   │   └── diagnostics/      # Diagnostic script docs
│   │   ├── components/            # Astro components (Head.astro, Footer.astro)
│   │   └── styles/                # CSS overrides
│   └── dist/                      # Built site (generated, not committed)
├── wordlists/                     # Bundled wordlists for password cracking / enumeration
│   ├── rockyou.txt                # Password list (downloaded)
│   ├── common.txt                 # Common passwords
│   ├── directory-list-2.3-small.txt  # Directory bruteforce list
│   ├── subdomains-top1million-5000.txt  # Subdomain list
│   └── download.sh                # Fetches missing wordlists
├── .claude/                       # Claude Code configuration
│   ├── hooks/                     # Claude Code lifecycle hooks
│   │   ├── netsec-pretool.sh      # PreToolUse: scope validation + raw tool blocking
│   │   ├── netsec-posttool.sh     # PostToolUse: JSON parsing + audit logging
│   │   └── netsec-health.sh       # Health check for safety architecture
│   ├── skills/                    # Skill files for Claude Code integration
│   │   ├── <tool>/SKILL.md        # Per-tool skill (lists scripts, flags, usage)
│   │   ├── scan/SKILL.md          # Multi-step scanning workflow
│   │   ├── recon/SKILL.md         # Reconnaissance workflow
│   │   ├── pentester/SKILL.md     # Pentester subagent persona
│   │   ├── defender/SKILL.md      # Defender subagent persona
│   │   ├── analyst/SKILL.md       # Analyst subagent persona
│   │   └── pentest-conventions/SKILL.md  # Background conventions reference
│   └── CLAUDE.md                  # Project instructions for Claude Code
├── .pentest/                      # Runtime pentest data (gitignored)
│   ├── scope.json                 # Target allowlist {"targets": [...]}
│   └── audit-<date>.jsonl         # Append-only audit log
├── notes/                         # Project notes (markdown)
├── .planning/                     # GSD planning documents
│   ├── codebase/                  # Codebase mapping documents (this directory)
│   ├── milestones/                # Milestone definitions
│   └── phases/                    # Phase implementation plans
├── .github/workflows/             # CI
│   ├── tests.yml                  # BATS test suite on PR/push to main
│   ├── shellcheck.yml             # ShellCheck linting
│   └── deploy-site.yml            # Astro site deployment
├── Makefile                       # Top-level convenience targets
├── README.md                      # Project overview
├── USECASES.md                    # Use-case script index
├── .shellcheckrc                  # ShellCheck configuration
└── .gitmodules                    # BATS submodule references
```

## Directory Purposes

**`scripts/lib/`:**
- Purpose: All shared bash library modules; never invoked directly
- Contains: 10 single-responsibility modules, each with a source guard
- Key files: `args.sh` (flag parsing), `json.sh` (JSON envelope), `output.sh` (run_or_show + safety_banner)

**`scripts/<tool>/`:**
- Purpose: All scripts for a single tool; 18 tool directories exist
- Contains: Always `examples.sh`; use-case scripts (`<verb>-<noun>.sh`) when task-focused scripts exist
- Key tools: `nmap/`, `tshark/`, `metasploit/`, `hashcat/`, `john/`, `sqlmap/`, `nikto/`, `hping3/`, `skipfish/`, `aircrack-ng/`, `curl/`, `dig/`, `ffuf/`, `foremost/`, `gobuster/`, `netcat/`, `traceroute/`
- Sample files: `scripts/nmap/examples.sh`, `scripts/nmap/discover-live-hosts.sh`, `scripts/nmap/identify-ports.sh`, `scripts/nmap/scan-web-vulnerabilities.sh`

**`scripts/diagnostics/`:**
- Purpose: Pattern B scripts — run automated network diagnostics and produce pass/fail reports; no safety_banner, not scan tools
- Contains: `connectivity.sh`, `dns.sh`, `performance.sh`

**`labs/`:**
- Purpose: Docker Compose environment with intentionally vulnerable targets
- Contains: Single `docker-compose.yml` defining DVWA (8080), Juice Shop (3030), WebGoat (8888), VulnerableApp (8180)

**`tests/`:**
- Purpose: BATS test suite covering lib unit tests and integration contracts
- Contains: `lib-*.bats` (unit), `intg-*.bats` (integration), `smoke.bats`; `bats/` and `test_helper/` are git submodules
- Key files: `tests/lib-args.bats`, `tests/lib-json.bats`, `tests/intg-json-output.bats`, `tests/intg-cli-contracts.bats`

**`site/`:**
- Purpose: Astro/Starlight documentation site; built and deployed separately from scripts
- Contains: MDX content pages, Astro components, built dist/
- Key files: `site/src/content/docs/tools/*.mdx`, `site/src/content/docs/guides/*.md`

**`wordlists/`:**
- Purpose: Bundled wordlists for password cracking and directory enumeration; large files downloaded on demand
- Contains: rockyou.txt, common password lists, directory lists, subdomain lists, `download.sh`

**`.claude/skills/`:**
- Purpose: Skill definitions consumed by Claude Code; each SKILL.md describes available scripts and how to use them
- Contains: Per-tool skills (nmap, tshark, sqlmap, etc.), workflow skills (scan, recon, fuzz, sniff, crack), and persona skills (pentester, defender, analyst)
- Key files: `.claude/skills/pentest-conventions/SKILL.md` (always-loaded background reference), `.claude/skills/pentester/SKILL.md` (subagent persona)

**`.pentest/`:**
- Purpose: Runtime pentest state; gitignored
- Contains: `scope.json` (target allowlist), `audit-<date>.jsonl` (JSONL append-only log)
- Generated: Yes — `scope.json` created manually; audit files created by hooks automatically
- Committed: No (gitignored)

## Key File Locations

**Entry Points:**
- `Makefile`: Top-level user interface; all `make <target>` commands
- `scripts/common.sh`: Bash library entry point; sourced at top of every script
- `scripts/check-tools.sh`: Tool detection; invoked by `make check`

**Configuration:**
- `.shellcheckrc`: ShellCheck linting configuration
- `.gitmodules`: BATS test submodule references
- `labs/docker-compose.yml`: Vulnerable lab targets
- `.pentest/scope.json`: Runtime target allowlist (gitignored)

**Core Logic:**
- `scripts/lib/output.sh`: `run_or_show` — the central dispatch function used by every script
- `scripts/lib/json.sh`: JSON envelope construction and emission
- `scripts/lib/args.sh`: Common flag parsing for all scripts
- `.claude/hooks/netsec-pretool.sh`: Safety enforcement (scope + raw tool blocking)
- `.claude/hooks/netsec-posttool.sh`: JSON result parsing and audit logging

**Testing:**
- `tests/*.bats`: All BATS test files (flat, no subdirectory nesting for project tests)
- `.github/workflows/tests.yml`: CI configuration for BATS runs

**Documentation Site:**
- `site/src/content/docs/tools/*.mdx`: Per-tool documentation pages
- `site/src/content/docs/guides/*.md`: Learning guides

## Naming Conventions

**Files:**
- Library modules: lowercase, single word or compound word, `.sh` suffix — `args.sh`, `cleanup.sh`, `nc_detect.sh`
- Examples scripts: always named `examples.sh`
- Use-case scripts: `<verb>-<noun>.sh` kebab-case — `discover-live-hosts.sh`, `crack-ntlm-hashes.sh`, `test-http-endpoints.sh`
- Diagnostic scripts: `<noun>.sh` — `connectivity.sh`, `dns.sh`, `performance.sh`
- BATS tests: `lib-<module>.bats` for unit tests, `intg-<contract>.bats` for integration tests

**Directories:**
- Tool directories: match the CLI tool name exactly — `nmap/`, `aircrack-ng/`, `tshark/`
- Skill directories: match the skill name — `nmap/`, `scan/`, `pentester/`

**Bash:**
- Global library state vars: `_ALL_CAPS` with leading underscore — `_COMMON_LOADED`, `_JSON_RESULTS`, `_CLEANUP_BASE_DIR`
- Public functions: `snake_case` — `run_or_show`, `parse_common_args`, `json_set_meta`, `require_cmd`
- Private/internal functions: `_leading_underscore_snake_case` — `_cleanup_handler`, `_strict_error_handler`, `_json_require_jq`
- Mode flags: `UPPER_CASE` exported vars — `EXECUTE_MODE`, `JSON_MODE`, `LOG_LEVEL`, `VERBOSE`

## Where to Add New Code

**New Tool (examples + use-case scripts):**
1. Create directory: `scripts/<tool-name>/`
2. Create `scripts/<tool-name>/examples.sh` following the Pattern A template (source common.sh, show_help, parse_common_args, require_cmd, require_target, safety_banner, 10 `run_or_show` calls, interactive demo)
3. Add tool to `TOOLS` associative array and `TOOL_ORDER` in `scripts/check-tools.sh`
4. Add Makefile target in `Makefile`
5. Create `site/src/content/docs/tools/<tool-name>.mdx` for documentation
6. Create `.claude/skills/<tool-name>/SKILL.md` for Claude Code integration

**New Use-Case Script for Existing Tool:**
1. Create `scripts/<tool>/<verb>-<noun>.sh`
2. Follow Pattern A use-case template: source common.sh, `json_set_meta`, `parse_common_args`, `require_cmd`, `confirm_execute`, `safety_banner`, `run_or_show` calls, `json_finalize`
3. Update `.claude/skills/<tool>/SKILL.md` to list the new script

**New Shared Library Module:**
1. Create `scripts/lib/<module>.sh` with source guard pattern
2. Add `source "${_LIB_DIR}/<module>.sh"` to `scripts/common.sh` in dependency order

**New BATS Test:**
1. Library unit test: `tests/lib-<module>.bats`
2. Integration test: `tests/intg-<contract>.bats`

**New Diagnostic Script:**
1. Create `scripts/diagnostics/<noun>.sh` using Pattern B (no safety_banner; use `run_check` and `report_*` functions from `lib/diagnostic.sh`)
2. Add documentation page under `site/src/content/docs/diagnostics/`

**New Claude Skill:**
1. Create `.claude/skills/<skill-name>/SKILL.md`
2. Add YAML frontmatter with `name`, `description`, and optional `disable-model-invocation: true`

## Special Directories

**`.pentest/`:**
- Purpose: Runtime pentest state — scope allowlist and audit logs
- Generated: Scope file created manually; audit files appended by hooks automatically
- Committed: No (gitignored); must be created locally

**`tests/bats/`:**
- Purpose: BATS testing framework (git submodule)
- Generated: No — checked in as submodule
- Committed: As submodule reference only

**`tests/test_helper/`:**
- Purpose: bats-assert, bats-support, bats-file test helpers (git submodules)
- Generated: No — checked in as submodule references
- Committed: As submodule references only

**`site/dist/`:**
- Purpose: Astro build output for the documentation site
- Generated: Yes — via `npm run build` in `site/`
- Committed: No (gitignored in site/)

**`wordlists/`:**
- Purpose: Wordlist files for password cracking and enumeration
- Generated: Partially — large files downloaded via `wordlists/download.sh`; smaller lists committed
- Committed: Small lists committed; rockyou.txt and similar large files gitignored

---

*Structure analysis: 2026-02-23*
