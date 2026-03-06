# Pitfalls Research: Publishing Pentesting Skills to skills.sh

**Domain:** Publishing security/pentesting Claude Code skills to skills.sh from an existing toolkit repo
**Researched:** 2026-03-06
**Confidence:** HIGH (based on examination of actual project files, official Claude Code docs, skills.sh documentation, and known plugin bugs)

## Critical Pitfalls

### Pitfall 1: Publishing GSD Framework Files Alongside Netsec Skills

**What goes wrong:**
The `.claude/` directory contains two entirely separate concerns: project-specific netsec skills/hooks/agents (32 skills, 3 hooks, 3 agents) and the Get-Shit-Done (GSD) framework files (14 agents, 3 hooks, ~50 commands, templates, references, bin/). Running `npx skills add patrykquantumnomad/networking-tools` would install EVERYTHING in `.claude/skills/`, but the GSD agents in `.claude/agents/` (gsd-executor.md, gsd-planner.md, gsd-debugger.md, etc.), GSD hooks (gsd-check-update.js, gsd-context-monitor.js, gsd-statusline.js), and the entire `get-shit-done/` directory are third-party framework files that should not be distributed as part of this project's skill pack.

**Why it happens:**
The GSD framework was installed into the same `.claude/` directory as the netsec skills. There is no separation boundary. The skills.sh CLI auto-discovers skills from `.claude/skills/` and skills from agent-specific subdirectories. If publishing as a Claude Code plugin, the migration guide says to copy `.claude/agents/`, `.claude/skills/`, and hooks wholesale -- which would sweep in GSD files.

**How to avoid:**
- Create an explicit publishing manifest or build script that enumerates ONLY netsec files
- Option A: Restructure to a dedicated plugin directory (`networking-tools-plugin/`) containing only netsec content, separate from `.claude/`
- Option B: Use `.gitignore`-style exclusion patterns in a build step that copies only netsec files to a publish directory
- The netsec files are identifiable by prefix/naming: agents are `pentester.md`, `analyst.md`, `defender.md`; hooks are `netsec-*.sh`; GSD files all have `gsd-` prefix
- Create a `publish.sh` script or `Makefile` target that assembles only the publishable subset

**Warning signs:**
- GSD-prefixed files appear in the published package
- Install count for the package includes GSD agent files
- Users report getting project management tooling when they expected pentesting skills

**Phase to address:**
Phase 1 (project setup) -- establish the publishing boundary before any content work begins

---

### Pitfall 2: Hooks Reference Local Project Conventions That Break on Install

**What goes wrong:**
The three netsec hooks (`netsec-pretool.sh`, `netsec-posttool.sh`, `netsec-health.sh`) depend on project-local conventions that do not exist in the installer's repo:

1. **`.pentest/scope.json`** -- The PreToolUse hook requires this file to validate targets. Without it, ALL wrapper script commands are blocked (line 126-136 of netsec-pretool.sh: "No scope file found... BLOCKED")
2. **`$CLAUDE_PROJECT_DIR`** -- Hooks use `${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}` which works for in-repo use but is fragile for plugins. On Windows, `$CLAUDE_PROJECT_DIR` is reported as broken (GitHub issue #6023). For plugins, `$CLAUDE_PLUGIN_ROOT` should be used instead, but it has its own bugs (GitHub issue #9354)
3. **`scripts/` directory** -- The pretool hook hardcodes paths to `scripts/<tool>/` directories (lines 67-93). These wrapper scripts exist in the networking-tools repo but NOT in the user's project when skills are installed standalone
4. **`jq` dependency** -- Both hooks require `jq` for JSON parsing. Not guaranteed to be installed

**Why it happens:**
The hooks were designed for in-repo use where the wrapper scripts, scope file, and directory structure all exist together. Publishing makes them available to repos that lack this structure.

**How to avoid:**
- Hooks must gracefully detect whether they are running in the networking-tools repo vs. installed as a standalone skill pack
- Add fallback behavior: if `scripts/` directory does not exist, skip raw-tool interception (the skill instructions already guide Claude to use correct patterns)
- Add first-run bootstrap: if `.pentest/scope.json` missing, auto-create with defaults instead of hard-blocking
- For plugin distribution, use `$CLAUDE_PLUGIN_ROOT` for hook paths in `hooks.json`, with awareness of the known bugs
- Document `jq` as a prerequisite in the README/install instructions
- Consider shipping a "setup" skill that runs on first install to create `.pentest/` infrastructure

**Warning signs:**
- Every pentesting command immediately blocked on fresh install
- Hook error messages reference files/paths that don't exist in the user's project
- Windows users report hook failures due to path separator issues

**Phase to address:**
Phase 2 (hook portability) -- the hooks must be made portable before any publication

---

### Pitfall 3: Skills Reference Wrapper Scripts That Only Exist in the Source Repo

**What goes wrong:**
Nearly every skill instructs Claude to run commands like:
```
bash scripts/nmap/identify-ports.sh $ARGUMENTS -j -x
bash scripts/nikto/scan-specific-vulnerabilities.sh $ARGUMENTS -j -x
bash scripts/sqlmap/test-all-parameters.sh $ARGUMENTS -j -x
```

These 28+ wrapper scripts live in the `scripts/` directory of the networking-tools repo. When someone installs just the skills via `npx skills add`, they get SKILL.md files that reference scripts that do not exist on their system. Claude will attempt to run `bash scripts/nmap/identify-ports.sh localhost -j -x` and fail with "No such file or directory."

**Why it happens:**
The skills were designed as project-local orchestration layers that depend on the co-located bash scripts. skills.sh only distributes SKILL.md files and their supporting directories, not the entire repo.

**How to avoid:**
- Two distribution strategies, pick one:
  - **Strategy A (Recommended): Full repo install** -- Publish as a Claude Code plugin (not just skills.sh). Users clone the repo and install the plugin, which gives them the wrapper scripts, hooks, and skills together. Use skills.sh listing as a discovery mechanism that points to the repo
  - **Strategy B: Self-contained skills** -- Rewrite skills to be independent of wrapper scripts. Instead of `bash scripts/nmap/identify-ports.sh`, the skill would contain the nmap commands directly and instruct Claude on patterns. Loses the safety hooks and audit logging
- If Strategy A: ensure the plugin manifest's `skills/` points to the right location and README explains the full install
- If Strategy B: create "standalone" versions of skills that work without wrapper scripts, maintaining "repo-native" versions for in-project use

**Warning signs:**
- Users report "command not found" or "no such file" after installing skills
- Skills appear in Claude's skill list but fail on every invocation
- Frustrated users uninstall after first attempt

**Phase to address:**
Phase 1 (architecture decision) -- the distribution strategy must be chosen before any publishing work

---

### Pitfall 4: Security Tools Become More Accessible Without Safety Controls

**What goes wrong:**
The networking-tools repo has a carefully designed safety architecture: PreToolUse hooks enforce scope validation, block raw tool usage, and maintain audit logs. When skills are published standalone (without the hooks), users get instructions for running nmap, sqlmap, nikto, hashcat, etc. without any guardrails. The Cato Networks/MedusaLocker research demonstrated that skills can be weaponized -- security tool skills amplify this risk because they are inherently designed to probe and exploit systems.

Specific risks:
1. **No scope validation** -- Skills instruct Claude to run scans against `$ARGUMENTS` without checking if the target is authorized
2. **Raw tool execution** -- Without the PreToolUse hook, Claude may invoke `nmap` or `sqlmap` directly instead of through wrapper scripts
3. **No audit trail** -- Without PostToolUse hook, no record of what tools were run against what targets
4. **Legal liability** -- Running pentesting tools against unauthorized targets is illegal in most jurisdictions. Skills that make this easy without warnings increase liability

**Why it happens:**
The safety controls are in the hooks, not in the skills themselves. Publishing skills without hooks strips the safety layer.

**How to avoid:**
- MUST distribute hooks alongside skills -- never skills alone
- Add safety disclaimers directly into SKILL.md content (not just in hooks), e.g., "ONLY run against authorized targets"
- Include `safety_banner` equivalent text in every tool skill
- Add a `pentest-conventions` skill that is `user-invocable: false` and auto-loaded, containing authorization requirements
- Consider requiring scope initialization before any tool skill works (the current pattern, but needs to work post-install)
- Add prominent legal warnings in README and skill descriptions
- Include link to scope setup in every tool skill's error path

**Warning signs:**
- Skills installed without corresponding hooks
- No `.pentest/scope.json` check in skill flow
- Users running skills against external targets without authorization warnings
- Legal complaints or platform terms violations

**Phase to address:**
Phase 2 (hook portability) and Phase 3 (skill content review) -- safety controls must travel with skills

---

### Pitfall 5: Agent Personas Reference Skills That Must Exist by Name

**What goes wrong:**
The three agent definitions reference skills by name in their `skills:` frontmatter:

- `pentester.md`: references `pentest-conventions`, `recon`, `scan`, `fuzz`, `crack`, `sniff`
- `analyst.md`: references `pentest-conventions`, `report`
- `defender.md`: references `pentest-conventions`

If any of these skill names change, are renamed for the published version, or are not included in the published package, the agents will fail to preload their required skills. Worse, in plugin distribution, skill names get namespaced (e.g., `/networking-tools:scan` instead of `/scan`), which may break agent skill references.

**Why it happens:**
Agent skill preloading uses exact name matching. Plugin namespacing changes the effective skill name. Skills and agents are separate files that can drift out of sync.

**How to avoid:**
- Maintain a manifest of agent-to-skill dependencies and validate it in CI
- Test agents in plugin mode (`--plugin-dir`) to verify skill preloading works with namespaced names
- If publishing as a plugin, verify that agents can reference skills within the same plugin by short name (without namespace prefix) -- this needs testing
- Add a smoke test that spawns each agent and verifies all referenced skills are loaded
- Keep skill names stable -- do not rename published skills

**Warning signs:**
- Agent starts but reports missing skills
- Agent logs show skill preload failures
- Pentester agent cannot run recon/scan/fuzz workflows

**Phase to address:**
Phase 3 (content validation) -- test all agent-skill cross-references in plugin context

---

### Pitfall 6: settings.json Contains Both GSD and Netsec Hook Registrations

**What goes wrong:**
The current `.claude/settings.json` registers both GSD hooks and netsec hooks:

```json
{
  "hooks": {
    "SessionStart": [{ "hooks": [{ "command": "node .claude/hooks/gsd-check-update.js" }] }],
    "PreToolUse": [{ "matcher": "Bash", "hooks": [{ "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/netsec-pretool.sh\"" }] }],
    "PostToolUse": [
      { "matcher": "Bash", "hooks": [{ "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/netsec-posttool.sh\"" }] },
      { "hooks": [{ "command": "node .claude/hooks/gsd-context-monitor.js" }] }
    ]
  },
  "statusLine": { "command": "node .claude/hooks/gsd-statusline.js" }
}
```

Publishing this as-is would register GSD framework hooks in the user's environment. Even worse, the GSD hooks reference `.claude/hooks/gsd-*.js` files that would not be present if only netsec content was shipped.

**Why it happens:**
Settings.json is a single file that serves as the project's hook registry for all purposes. There is no mechanism to separate "my hooks" from "framework hooks" within a single settings.json.

**How to avoid:**
- For plugin distribution, create a separate `hooks/hooks.json` in the plugin directory that ONLY contains netsec hook registrations
- Do NOT copy the project's `settings.json` into the plugin
- Strip GSD-related entries from any published configuration
- Add this to the build/publish script validation: fail if any `gsd-` references appear in published hooks

**Warning signs:**
- Published package references `gsd-check-update.js` or `gsd-context-monitor.js`
- Users report "command not found" errors from GSD hooks on session start
- statusLine configuration references missing GSD files

**Phase to address:**
Phase 1 (project setup) -- create clean hook configuration for publishing

---

## Technical Debt Patterns

Shortcuts that seem reasonable but create long-term problems.

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Publishing skills without testing in plugin mode | Ships faster | Every skill that references `scripts/` breaks on install | Never -- always test with `--plugin-dir` |
| Hardcoding `scripts/` paths in SKILL.md | Works perfectly in-repo | All tool skills fail for standalone install users | Only if distribution is repo-clone-only |
| Skipping scope.json bootstrap in hooks | Simpler hook code | First-time users blocked on every command | Never -- always provide guided setup |
| Copying all `.claude/` files to plugin | Catches everything | GSD framework leaks, settings conflicts, bloat | Never -- use explicit inclusion list |
| Publishing without legal disclaimers | Less text clutter | Liability exposure, platform ToS violations, skill removal | Never for security tools |
| Using `$CLAUDE_PROJECT_DIR` in plugin hooks | Works on macOS | Breaks on Windows, fragile across platforms | Only for project-local (non-distributed) use |

## Integration Gotchas

Common mistakes when connecting to skills.sh and the Claude Code plugin ecosystem.

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| skills.sh listing | Assuming `npx skills add` installs the entire repo | skills.sh only discovers SKILL.md files; wrapper scripts, hooks, and labs are NOT installed. Either publish as a full plugin or document that users must clone the repo |
| Claude Code plugins | Putting skills/agents/hooks inside `.claude-plugin/` directory | Only `plugin.json` goes in `.claude-plugin/`. Skills, agents, hooks go at the plugin ROOT level |
| Plugin hook paths | Using `$CLAUDE_PROJECT_DIR` in plugin `hooks.json` | Use `$CLAUDE_PLUGIN_ROOT` for plugin-bundled scripts. But note: this variable is buggy -- not set during SessionStart (issue #27145), broken on Windows (issue #18527) |
| Plugin skill namespacing | Expecting `/scan` to work as a plugin skill name | Plugin skills are namespaced: `/networking-tools:scan`. Agent skill references may need to account for this |
| settings.json in plugins | Copying project settings.json to plugin root | Plugin settings.json only supports the `agent` key currently. Hooks go in `hooks/hooks.json`, not settings.json |
| `$CLAUDE_PLUGIN_ROOT` in SKILL.md | Using `${CLAUDE_PLUGIN_ROOT}` in markdown content | This variable only works in JSON configurations (hooks, MCP). In SKILL.md, use `${CLAUDE_SKILL_DIR}` instead to reference supporting files |

## Security Mistakes

Domain-specific security issues for publishing pentesting skills.

| Mistake | Risk | Prevention |
|---------|------|------------|
| Publishing skills without safety hooks | Users run nmap/sqlmap against unauthorized targets with no scope check | Always distribute hooks alongside skills; add inline safety text to every tool SKILL.md |
| No legal disclaimer in published skills | Liability for unauthorized scanning; platform ToS violations | Add "authorized targets only" warning to every tool skill description and to the README |
| Hardcoding lab credentials in skills | DVWA default creds (admin/password) in published skills normalize insecure defaults | Keep lab-specific content (credentials, ports) in a separate `lab` skill that is clearly labeled as local-only |
| Publishing audit log paths | Reveals internal file structure and scope targets | Ensure `.pentest/` directory contents are never published; add to `.gitignore` and verify |
| Making crack/hashcat skills too easy | Lowers barrier for password cracking against unauthorized systems | Add clear "authorized use only" warnings; require explicit hash file path not network targets |
| No scope initialization flow | Users skip scope setup and run tools against arbitrary targets | Make scope check the first step in every workflow skill; provide helpful error when scope is missing |

## UX Pitfalls

Common user experience mistakes when publishing security tool skills.

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| All tool skills fail silently without wrapper scripts | User installs, tries `/scan localhost`, gets cryptic bash errors | Detect missing scripts and provide clear error: "This skill requires the networking-tools repo. Clone from..." |
| No first-run experience | User installs and has no idea what to do first | Create a `/netsec-setup` or `/netsec-health` skill that bootstraps scope, verifies tools, and guides the user |
| 32 skills with no clear entry point | Overwhelming skill list, user does not know where to start | Add a `/netsec-help` or README skill that explains the skill hierarchy: workflows > tools > utilities |
| Skills assume tools are installed | nmap/nikto/sqlmap may not be installed; skill fails with obscure errors | Each tool skill should check for tool availability and provide install instructions on failure |
| Workflow skills assume all sub-tools exist | `/scan` runs nmap, nikto, sqlmap, curl in sequence; one missing tool breaks the flow | Workflow skills should gracefully skip unavailable tools and summarize what was skipped |
| No distinction between "learning mode" and "execution mode" | Users confused by scripts that show commands vs. execute them | Clearly document the `-j -x` flags in skill descriptions; consider defaulting to execution mode for installed skills |

## "Looks Done But Isn't" Checklist

Things that appear complete but are missing critical pieces.

- [ ] **Skills published:** Often missing hook distribution -- verify hooks are included and registered in `hooks/hooks.json`
- [ ] **Hooks ported:** Often missing `jq` dependency check -- verify hooks fail gracefully when `jq` is not installed
- [ ] **Hooks ported:** Often missing Windows compatibility -- verify `$CLAUDE_PLUGIN_ROOT` works on Windows (known bug #18527)
- [ ] **Plugin created:** Often missing `.claude-plugin/plugin.json` manifest -- verify manifest exists with correct name/version
- [ ] **Agents published:** Often missing skill reference validation -- verify all `skills:` references in agent frontmatter resolve in plugin context
- [ ] **Safety controls:** Often missing inline safety text -- verify every tool skill contains authorization warning, not just hooks
- [ ] **README written:** Often missing install prerequisites -- verify jq, bash 4+, and tool-specific requirements are documented
- [ ] **Testing done:** Often missing plugin-mode testing -- verify all skills work with `claude --plugin-dir ./plugin` not just in-repo
- [ ] **GSD excluded:** Often missing validation -- verify no `gsd-` prefixed files exist in the published directory
- [ ] **scope.json bootstrap:** Often missing first-run flow -- verify fresh install creates scope infrastructure automatically

## Recovery Strategies

When pitfalls occur despite prevention, how to recover.

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| GSD files published | LOW | Remove GSD files from published package, publish new version, notify users to update |
| Hooks break on install | MEDIUM | Ship updated hooks with graceful fallbacks; provide manual setup instructions in README |
| Skills fail without scripts | HIGH | Fundamental architecture decision needed: either ship full repo or rewrite skills to be self-contained. Cannot patch partway |
| Security incident from unscoped scanning | HIGH | Cannot undo. Add retroactive warnings, update all skill descriptions, consider adding scope requirement to skill content itself |
| Agent-skill references broken | LOW | Fix skill names or agent references, publish update |
| settings.json conflicts | MEDIUM | Create dedicated plugin hooks.json, remove settings.json from published package, document migration for affected users |

## Pitfall-to-Phase Mapping

How roadmap phases should address these pitfalls.

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| GSD files leaked into publication | Phase 1: Project Setup | Run `grep -r "gsd-" published/` returns zero results |
| Hooks break on install | Phase 2: Hook Portability | `claude --plugin-dir ./plugin` starts cleanly with no hook errors |
| Skills reference missing scripts | Phase 1: Architecture Decision | All tool skills either work standalone OR clearly fail with "clone repo" message |
| Safety controls missing | Phase 2: Hook Portability + Phase 3: Content Review | Every tool SKILL.md contains authorization warning text; scope check exists in skill flow |
| Agent-skill reference mismatch | Phase 3: Content Validation | Each agent tested in plugin mode; all preloaded skills resolve |
| settings.json conflict | Phase 1: Project Setup | Published plugin has `hooks/hooks.json`, no `settings.json` with hook registrations |
| No first-run experience | Phase 3: Content Polishing | Fresh install of plugin followed by `/netsec-health` produces clear status and guided repair |
| Windows path issues | Phase 2: Hook Portability | Hooks tested on Windows with `$CLAUDE_PLUGIN_ROOT` or documented as macOS/Linux only |
| Legal disclaimer missing | Phase 3: Content Review | Every tool skill description includes "authorized targets only" language |
| Lab credentials published | Phase 1: Project Setup | Lab skill clearly marked local-only; credentials not in published tool skills |

## Sources

- Claude Code official skills documentation: https://code.claude.com/docs/en/skills
- Claude Code plugins documentation: https://code.claude.com/docs/en/plugins
- Claude Code hooks reference: https://code.claude.com/docs/en/hooks
- skills.sh CLI documentation: https://skills.sh/docs/cli
- skills.sh FAQ: https://skills.sh/docs/faq
- vercel-labs/skills GitHub repo: https://github.com/vercel-labs/skills
- CLAUDE_PLUGIN_ROOT bug (command markdown): https://github.com/anthropics/claude-code/issues/9354
- CLAUDE_PLUGIN_ROOT unset in SessionStart: https://github.com/anthropics/claude-code/issues/27145
- CLAUDE_PLUGIN_ROOT Windows path bug: https://github.com/anthropics/claude-code/issues/18527
- CLAUDE_PROJECT_DIR bug: https://github.com/anthropics/claude-code/issues/6023
- Weaponizing Claude Skills (MedusaLocker): https://www.catonetworks.com/blog/cato-ctrl-weaponizing-claude-skills-with-medusalocker/
- Claude Code skill security audit guidance: https://repello.ai/blog/claude-code-skill-security
- Trail of Bits security skills: https://github.com/trailofbits/skills
- Anthropic official skills repo: https://github.com/anthropics/skills
- Direct examination of project files: `.claude/hooks/netsec-pretool.sh`, `.claude/hooks/netsec-posttool.sh`, `.claude/hooks/netsec-health.sh`, `.claude/settings.json`, all 32 skill SKILL.md files, all 3 agent definitions

---
*Pitfalls research for: Publishing pentesting skills to skills.sh*
*Researched: 2026-03-06*
