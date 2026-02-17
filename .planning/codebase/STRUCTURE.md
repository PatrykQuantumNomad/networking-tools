# Codebase Structure

**Analysis Date:** 2026-02-17

## Directory Layout

```
networking-tools/
├── scripts/                   # All pentesting tool demonstration scripts
│   ├── lib/                   # Shared library modules
│   ├── common.sh              # Library orchestrator/entry point
│   ├── check-tools.sh         # Tool installation checker
│   ├── <tool-name>/           # Per-tool directories (18 tools)
│   │   ├── examples.sh        # Generic examples for the tool
│   │   └── <use-case>.sh      # Specialized scenario scripts
│   └── diagnostics/           # Network diagnostic reports
├── labs/                      # Docker vulnerable practice targets
│   └── docker-compose.yml     # DVWA, Juice Shop, WebGoat, VulnerableApp
├── tests/                     # BATS test suites
│   ├── *.bats                 # Test files
│   ├── bats/                  # BATS framework (submodule)
│   └── test_helper/           # BATS assertion libraries
├── site/                      # Astro documentation website
│   ├── src/                   # Astro components and content
│   ├── public/                # Static assets
│   └── package.json           # Node.js dependencies
├── wordlists/                 # Password cracking and fuzzing wordlists
├── notes/                     # Development notes and research
├── .claude/                   # GSD (Get Shit Done) system config
│   ├── agents/                # Claude agent definitions
│   ├── commands/              # GSD command workflows
│   └── get-shit-done/         # GSD framework files
├── .planning/                 # Project planning documents
│   └── codebase/              # Codebase analysis (this document)
├── Makefile                   # Primary user interface
├── README.md                  # Project overview
├── USECASES.md                # Index of 28 use-case scripts
└── LICENSE                    # MIT license
```

## Directory Purposes

**`scripts/`:**
- Purpose: All executable pentesting tool demonstration scripts
- Contains: Tool-specific directories, shared libraries, tool checker
- Key files: `common.sh` (library entry point), `check-tools.sh` (installation validator)
- Structure: 18 tool subdirectories + lib/ + diagnostics/

**`scripts/lib/`:**
- Purpose: Modular bash utility libraries
- Contains: args.sh, cleanup.sh, colors.sh, diagnostic.sh, json.sh, logging.sh, nc_detect.sh, output.sh, strict.sh, validation.sh
- Key pattern: Each module has source guard, loaded via common.sh in dependency order

**`scripts/<tool>/`:**
- Purpose: Isolated directory per pentesting tool
- Contains: examples.sh (10 generic examples) + use-case scripts (focused scenarios)
- Tools: nmap, tshark, metasploit, aircrack-ng, hashcat, john, sqlmap, nikto, hping3, skipfish, netcat, curl, dig, traceroute, foremost, gobuster, ffuf
- Naming: Lowercase tool name, hyphenated for multi-word tools

**`scripts/diagnostics/`:**
- Purpose: Network troubleshooting auto-reports
- Contains: dns.sh, connectivity.sh, performance.sh
- Pattern: Non-interactive, no safety banner, structured output

**`labs/`:**
- Purpose: Vulnerable practice environment
- Contains: docker-compose.yml defining 4 intentionally vulnerable web apps
- Services: DVWA (port 8080), Juice Shop (3030), WebGoat (8888), VulnerableApp (8180)
- Key files: `docker-compose.yml`

**`tests/`:**
- Purpose: Automated test suites
- Contains: BATS test files (*.bats), BATS framework, assertion helpers
- Coverage: CLI contracts, library functions, JSON output, script headers
- Key files: `intg-cli-contracts.bats`, `lib-*.bats`, `intg-json-output.bats`

**`tests/bats/`:**
- Purpose: BATS test framework (git submodule)
- Contains: BATS executable, core libraries
- Key files: `bin/bats` (test runner)

**`tests/test_helper/`:**
- Purpose: BATS assertion libraries
- Contains: bats-support, bats-assert, bats-file (submodules)
- Used by: All test files for assert_success, assert_output, etc.

**`site/`:**
- Purpose: Documentation website built with Astro
- Contains: Astro components, Markdown content, static assets
- Key files: `package.json`, `astro.config.mjs`, `src/content/docs/`
- Build: `make site-build`, Dev: `make site-dev`

**`wordlists/`:**
- Purpose: Password cracking and web fuzzing wordlists
- Contains: Download scripts for common wordlists
- Used by: hashcat, john, gobuster, ffuf scripts

**`notes/`:**
- Purpose: Development notes and research
- Contains: Tool-specific notes, vulnerability research
- Not committed: Development scratchpad

**`.claude/`:**
- Purpose: GSD (Get Shit Done) AI-assisted development system
- Contains: Agent definitions, command workflows, framework references
- Key files: `agents/*.md`, `commands/gsd/*.md`, `get-shit-done/workflows/*.md`

**`.planning/`:**
- Purpose: Project roadmaps, milestones, phase plans
- Contains: Roadmap, milestone tracking, codebase analysis
- Key files: `.planning/codebase/ARCHITECTURE.md`, `.planning/codebase/STRUCTURE.md` (this file)

## Key File Locations

**Entry Points:**
- `Makefile`: Primary user interface with 100+ targets
- `scripts/<tool>/examples.sh`: 10 generic examples per tool (18 files)
- `scripts/<tool>/<use-case>.sh`: Focused scenario scripts (28 files)
- `scripts/diagnostics/<diagnostic>.sh`: Auto-report diagnostics (3 files)

**Configuration:**
- `.shellcheckrc`: ShellCheck linter exclusions
- `site/astro.config.mjs`: Astro site configuration
- `site/package.json`: Node.js dependencies for documentation site
- `labs/docker-compose.yml`: Vulnerable lab container definitions

**Core Logic:**
- `scripts/common.sh`: Library orchestrator, Bash version guard, module loader
- `scripts/lib/output.sh`: run_or_show abstraction, safety_banner, confirm_execute
- `scripts/lib/validation.sh`: require_cmd, require_target, check_cmd
- `scripts/lib/args.sh`: parse_common_args flag parser
- `scripts/lib/json.sh`: JSON mode output formatting

**Testing:**
- `tests/intg-cli-contracts.bats`: CLI contract tests (--help, -x behavior)
- `tests/lib-*.bats`: Library module unit tests
- `tests/intg-json-output.bats`: JSON output structure validation

**Documentation:**
- `README.md`: Project overview, quick start, tool list
- `USECASES.md`: Index of 28 use-case scripts with descriptions
- `.claude/CLAUDE.md`: Instructions for Claude Code AI assistant
- `site/src/content/docs/`: Markdown documentation pages

## Naming Conventions

**Files:**
- Tool scripts: `examples.sh` (generic examples), `<use-case-name>.sh` (kebab-case)
- Library modules: `<module-name>.sh` (lowercase, no prefix)
- Test files: `<test-type>-<subject>.bats` (e.g., `intg-cli-contracts.bats`, `lib-args.bats`)
- Documentation: `UPPERCASE.md` for top-level docs (README.md, USECASES.md, LICENSE)

**Directories:**
- Tool directories: Lowercase tool name, hyphens for multi-word (e.g., `aircrack-ng/`)
- Library directory: `lib/` (singular)
- Special directories: Dot-prefixed for config (`.claude/`, `.planning/`)

**Functions:**
- Library functions: snake_case (e.g., `require_cmd`, `run_or_show`, `json_add_example`)
- Internal helpers: Underscore prefix (e.g., `_json_require_jq`, `_should_log`)
- Help functions: `show_help()` in every script

**Variables:**
- Global config: UPPERCASE (e.g., `EXECUTE_MODE`, `JSON_MODE`, `PROJECT_ROOT`)
- Local vars: lowercase (e.g., `target`, `description`, `answer`)
- Source guards: `_MODULE_LOADED` pattern (e.g., `_ARGS_LOADED`, `_COMMON_LOADED`)

**Makefile Targets:**
- Tool examples: Tool name (e.g., `nmap`, `sqlmap`, `tshark`)
- Use cases: Hyphenated action (e.g., `dump-db`, `crack-ntlm`, `scan-web-vulns`)
- Lab operations: `lab-` prefix (e.g., `lab-up`, `lab-down`, `lab-status`)
- Diagnostics: `diagnose-` prefix (e.g., `diagnose-dns`, `diagnose-connectivity`)

## Where to Add New Code

**New Pentesting Tool:**
- Primary code: Create `scripts/<tool-name>/` directory
- Examples script: `scripts/<tool-name>/examples.sh` following Pattern A template
- Tests: Add tool to `scripts/check-tools.sh` TOOLS array and TOOL_ORDER
- Makefile: Add target in appropriate section (e.g., `##@ Web Application Testing`)
- Documentation: Update `README.md` tool list, optionally add `site/src/content/docs/tools/<tool>.md`

**New Use-Case Script:**
- Implementation: `scripts/<tool-name>/<use-case-name>.sh` following Pattern A template
- Makefile: Add target with descriptive name and TARGET parameter
- Index: Add entry to `USECASES.md` with description and example
- Tests: Existing `intg-cli-contracts.bats` auto-discovers new scripts

**New Library Module:**
- Implementation: `scripts/lib/<module-name>.sh` with source guard `_MODULE_LOADED=1`
- Integration: Add `source "${_LIB_DIR}/<module>.sh"` to `scripts/common.sh` in dependency order
- Tests: Create `tests/lib-<module>.bats` with unit tests for all functions
- Documentation: Add `@description` and `@usage` header comments

**New Diagnostic:**
- Implementation: `scripts/diagnostics/<diagnostic>.sh` following Pattern B template
- Makefile: Add `diagnose-<name>` target in `##@ Diagnostics` section
- Tests: Add to `intg-cli-contracts.bats` if following --help contract

**Utilities:**
- Shared helpers: Add to appropriate `scripts/lib/*.sh` module or create new module
- Validation functions: `scripts/lib/validation.sh`
- Output formatting: `scripts/lib/output.sh`
- Argument parsing: `scripts/lib/args.sh`

**Documentation:**
- User guides: `site/src/content/docs/guides/<topic>.md` (Markdown with frontmatter)
- Tool documentation: `site/src/content/docs/tools/<tool>.md`
- Project docs: Top-level `*.md` files (README, USECASES, LICENSE)

**Tests:**
- Integration tests: `tests/intg-<subject>.bats`
- Library unit tests: `tests/lib-<module>.bats`
- Test helpers: `tests/test_helper/` (imported assertion libraries)

## Special Directories

**`scripts/lib/`:**
- Purpose: Shared bash library modules
- Generated: No (hand-written)
- Committed: Yes
- Source guard: Every module has `[[ -n "${_MODULE_LOADED:-}" ]] && return 0`

**`tests/bats/`:**
- Purpose: BATS test framework
- Generated: No (git submodule)
- Committed: Submodule reference only
- Clone: `git submodule update --init --recursive`

**`site/node_modules/`:**
- Purpose: Node.js dependencies for documentation site
- Generated: Yes (npm install)
- Committed: No (in .gitignore)
- Restore: `cd site && npm install`

**`site/dist/`:**
- Purpose: Built documentation site
- Generated: Yes (`make site-build`)
- Committed: No (in .gitignore)
- Deploy: Build artifacts for static hosting

**`.planning/`:**
- Purpose: Project planning documents (roadmaps, milestones, codebase docs)
- Generated: Partially (some by GSD system)
- Committed: Yes
- Structure: Organized by planning artifact type

**`.claude/`:**
- Purpose: GSD AI-assisted development system configuration
- Generated: No (hand-written system definitions)
- Committed: Yes
- Used by: Claude Code AI assistant for project workflows

---

*Structure analysis: 2026-02-17*
