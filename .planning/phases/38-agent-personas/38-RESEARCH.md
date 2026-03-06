# Phase 38: Agent Personas - Research

**Researched:** 2026-03-06
**Domain:** Claude Code plugin agents, skill namespace resolution, agent invoker skills, subagent preloading
**Confidence:** HIGH

## Summary

Phase 38 transforms 3 agent persona files (pentester, defender, analyst) and 3 invoker skills from symlinks in the plugin directory into real, portable files that work correctly in standalone plugin context. Currently, all 6 items in the plugin are symlinks pointing back to `.claude/agents/` and `.claude/skills/` -- these break when the plugin is installed externally because symlink targets do not exist outside the repo.

The critical technical challenge is **skill namespace resolution in plugin agents**. When a plugin agent like `pentester.md` declares `skills: [pentest-conventions, recon, scan, fuzz, crack, sniff]`, the skill resolution engine looks for those skills within the same plugin's `skills/` directory. Two problems exist: (1) `pentest-conventions` does not exist anywhere in the plugin -- not even as a symlink, and (2) the current skill names in the agent frontmatter may not match the plugin's skill directory structure (`skills/workflows/recon/` vs `skills/recon/`). Additionally, the invoker skills use `agent: pentester` which must resolve to the plugin-namespaced agent `netsec-skills:pentester` in plugin context.

A secondary challenge is that the pentester agent body contains in-repo-only instructions: "Always use wrapper scripts with -j -x flags" and "Never invoke raw security tools directly." These instructions are wrong in standalone plugin context where wrapper scripts do not exist. The agent body needs the same dual-mode awareness pattern applied in Phases 36-37, or at minimum must not instruct behavior that is impossible in standalone mode.

**Primary recommendation:** Add `pentest-conventions` as a real skill in the plugin's `skills/utility/` directory, update agent `skills:` frontmatter to use directory-path-based names that match the plugin structure, update invoker skills to use plugin-namespaced agent references, and add dual-mode awareness to the pentester agent body.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| AGEN-01 | Pentester, defender, and analyst agents are distributed via plugin `agents/` directory | Replace 3 agent symlinks with real .md files containing correct skill references and dual-mode body content |
| AGEN-02 | Agent invoker skills (/pentester, /defender, /analyst) work correctly in plugin namespace | Replace 3 invoker skill symlinks with real SKILL.md files; resolve `agent:` field to plugin-namespaced agent names; verify `context: fork` behavior |
</phase_requirements>

## Standard Stack

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| Claude Code agent .md files | Agent Skills spec | Agent persona definition format | Standard `agents/` directory with YAML frontmatter + markdown body |
| Claude Code SKILL.md | Agent Skills spec | Invoker skill definition format | `context: fork` + `agent:` field combination for subagent launching |
| Plugin namespace system | Claude Code 1.0.33+ | Component namespacing | `plugin-name:component-name` format for all plugin components |

### Supporting
| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| BATS 1.x | installed at tests/bats/ | Structural validation of agent and invoker files | Verify frontmatter fields, skill references, file existence |
| `scripts/validate-plugin-boundary.sh` | project script | Plugin boundary validation | After replacing symlinks with real files |
| `diff` | POSIX | Sync validation | Verify in-repo and plugin versions match |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Plugin-namespaced skill refs in agents | Bare skill names without namespace | Bare names work ONLY if `name:` field in SKILL.md matches AND the skill is in the same plugin; using explicit directory-path names is safer |
| Dual-mode agent body | Two separate agent files (in-repo vs plugin) | Defeats the Phase 36-37 pattern of keeping files identical; dual-mode body handles both contexts |
| Adding pentest-conventions to plugin | Inlining conventions into agent body | Skill is referenced by all 3 agents; separate skill avoids 80 lines of duplication |

## Architecture Patterns

### Recommended Plugin Structure (After Phase 38)
```
netsec-skills/
  agents/
    pentester.md      # REAL FILE (was symlink)
    defender.md       # REAL FILE (was symlink)
    analyst.md        # REAL FILE (was symlink)
  skills/
    agents/
      pentester/SKILL.md  # REAL FILE (was symlink)
      defender/SKILL.md   # REAL FILE (was symlink)
      analyst/SKILL.md    # REAL FILE (was symlink)
    utility/
      pentest-conventions/SKILL.md  # NEW (never existed in plugin)
      check-tools/SKILL.md          # REAL FILE (was symlink) -- scope decision below
      report/SKILL.md               # REAL FILE (was symlink) -- scope decision below
    tools/    ... (17 real files from Phase 36)
    workflows/ ... (6 real files from Phase 37)
```

### Pattern 1: Plugin Skill Name Resolution in Agents
**What:** When a plugin agent declares `skills: [name1, name2]`, the skill resolution engine resolves each name by searching the plugin's own `skills/` directory. The resolution uses the skill's `name:` frontmatter field if present, or the directory name as fallback.
**When to use:** All 3 agent files.
**Critical insight:** All existing plugin skills have `name:` in their frontmatter (e.g., `name: recon`). Per GitHub issue #22063, skills with a `name:` field bypass the plugin namespace prefix and register as `/recon` (not `/netsec-skills:recon`). The agent's `skills:` field resolves by matching the `name:` field value. So `skills: [recon, scan]` in the agent SHOULD resolve to the plugin's `skills/workflows/recon/SKILL.md` and `skills/workflows/scan/SKILL.md` because those skills have `name: recon` and `name: scan`.
**Confidence:** MEDIUM -- this requires empirical testing (Success Criterion 3 explicitly calls for it).

### Pattern 2: Agent Field Resolution in Invoker Skills
**What:** When a plugin skill has `agent: pentester`, it needs to resolve to the plugin's `agents/pentester.md`. Plugin agents are namespaced as `netsec-skills:pentester` in the UI. The `agent:` field may need the full namespace prefix for plugin context.
**When to use:** All 3 invoker skills.
**Critical insight:** The official docs say "Options include built-in agents (Explore, Plan, general-purpose) or any custom subagent from `.claude/agents/`." They do NOT explicitly document how `agent:` resolves for plugin skills pointing to plugin agents. The safest approach is to test with bare name first (`agent: pentester`), and if that fails, try the namespaced form (`agent: netsec-skills:pentester`).
**Confidence:** MEDIUM -- requires empirical testing.

### Pattern 3: Dual-Mode Agent Body
**What:** The pentester agent body currently says "Always use wrapper scripts with -j -x flags" and "Never invoke raw security tools directly." In standalone plugin context, wrapper scripts do not exist. The body needs dual-mode awareness.
**When to use:** Pentester agent only (defender and analyst do not reference wrapper scripts).
**Example:**
```markdown
## Execution Rules

Detect which mode you are operating in:
- If wrapper scripts exist (check `test -f scripts/nmap/identify-ports.sh`): use wrapper scripts with `-j -x` flags
- If standalone: invoke security tools directly using the command knowledge from your preloaded workflow skills

In either mode:
- Reference the preloaded workflow skills for step-by-step instructions
- If a tool is not installed, skip that step and note it
- Check scope before every tool execution
```

### Pattern 4: pentest-conventions as Plugin Skill
**What:** The `pentest-conventions` skill must exist in the plugin because all 3 agents reference it via `skills: [pentest-conventions, ...]`. Currently it exists in `.claude/skills/pentest-conventions/SKILL.md` but NOT in the plugin at all.
**When to use:** This phase.
**Critical insight:** The existing `pentest-conventions` content references in-repo paths like `scripts/<tool>/<script>.sh`, `.claude/hooks/`, and `make lab-up`. In standalone plugin context, most of these do not exist. The skill needs dual-mode awareness or at minimum neutral language that works in both contexts.

### Pattern 5: Symlink Replacement (Established Phase 36-03 Pattern)
**What:** Remove symlinks, create real directories, copy real files.
**When to use:** All 8 remaining symlinks (3 agents, 3 agent invoker skills, 2 utility skills).
**Process:**
```bash
# For directory symlinks (invoker skills)
rm -f netsec-skills/skills/agents/pentester
mkdir -p netsec-skills/skills/agents/pentester
cp .claude/skills/pentester/SKILL.md netsec-skills/skills/agents/pentester/SKILL.md

# For file symlinks (agent files)
rm -f netsec-skills/agents/pentester.md
cp .claude/agents/pentester.md netsec-skills/agents/pentester.md
```

### Anti-Patterns to Avoid

- **Leaving `name:` in agent frontmatter as-is without testing:** The `name:` field in agents controls namespace. If the plugin agent has `name: pentester`, it might conflict with the project-level agent. The plugin system handles this via priority (project > plugin), but it should be verified.
- **Hard-coding in-repo paths in agent body or pentest-conventions:** Any `scripts/`, `.claude/hooks/`, or `make` references will break in standalone plugin context.
- **Assuming `agent:` field auto-resolves within plugin:** The docs are silent on this. Must test empirically.
- **Replacing utility symlinks (check-tools, report) without considering scope:** These are NOT required by AGEN-01 or AGEN-02. However, `report` IS referenced by the analyst agent's `skills:` field, so it MUST be a real file for the analyst agent to work in plugin context.
- **Ignoring that `disable-model-invocation: true` does not work for plugin skills:** Per Phase 36 research, this flag is ignored for plugin skills. The invoker skills have this flag, which means in plugin context they WILL be auto-loaded by Claude. This is acceptable for invoker skills since they are small passthrough files.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Skill namespace testing | Manual inspection of `/agents` output | Empirical test: `claude --plugin-dir ./netsec-skills` + invoke `/pentester` | Only runtime behavior reveals actual resolution |
| Agent body dual-mode | Complex conditional logic in agent body | Simple "detect and adapt" instruction pattern (same as workflow skills) | Agents are instruction documents, not code; Claude can branch on a simple detection result |
| pentest-conventions content | Rewriting from scratch for standalone | Adapt existing content with neutral language that works both in-repo and standalone | Content is correct for in-repo; just needs despecialization for portability |
| Sync validation between in-repo and plugin | Manual diff after each change | BATS test with `cmp -s` between in-repo and plugin versions | Same pattern as Phase 36 and 37 BATS tests |

**Key insight:** The transformation is primarily a namespace and portability problem, not a content creation problem. The agent content already exists and works well; it just needs to be ported to work without in-repo infrastructure.

## Common Pitfalls

### Pitfall 1: Skills Reference Resolution Failure in Plugin Context
**What goes wrong:** Agent declares `skills: [pentest-conventions]` but the skill does not exist in the plugin's `skills/` directory. Agent starts without the preloaded skill, losing critical context.
**Why it happens:** `pentest-conventions` was never added to the plugin -- not even as a symlink.
**How to avoid:** Add `pentest-conventions` as a real SKILL.md file in `netsec-skills/skills/utility/pentest-conventions/SKILL.md` before testing agents.
**Warning signs:** Agent runs but does not mention conventions, scope checking, or safety rules.

### Pitfall 2: Agent Field Does Not Resolve to Plugin Agent
**What goes wrong:** Invoker skill has `agent: pentester` but in plugin context this resolves to the project-level agent or fails entirely, instead of the plugin's `agents/pentester.md`.
**Why it happens:** The `agent:` field resolution for plugin skills is not explicitly documented. It may require the full namespace: `agent: netsec-skills:pentester`.
**How to avoid:** Test empirically with `claude --plugin-dir ./netsec-skills`. Try bare name first, then namespaced form. The success criterion explicitly requires this empirical test.
**Warning signs:** Invoker skill launches a generic agent instead of the specialized pentester/defender/analyst agent.

### Pitfall 3: In-Repo-Only Instructions in Agent Body
**What goes wrong:** Pentester agent says "Never invoke raw security tools directly" and "Always use wrapper scripts with -j -x flags." In standalone mode, this makes the agent refuse to do anything useful.
**Why it happens:** Agent was written for the in-repo context where wrapper scripts always exist.
**How to avoid:** Add dual-mode awareness: "If wrapper scripts are available, use them with -j -x. Otherwise, invoke tools directly using preloaded skill knowledge."
**Warning signs:** Pentester agent refuses to run nmap directly when wrapper scripts are not present.

### Pitfall 4: pentest-conventions References In-Repo Infrastructure
**What goes wrong:** The conventions skill references `scripts/<tool>/<use-case>.sh`, `.claude/hooks/netsec-health.sh`, `make lab-up`, etc. None of these exist in standalone plugin context.
**Why it happens:** Skill was written for in-repo use only.
**How to avoid:** Update pentest-conventions to use conditional language: "If wrapper scripts are available (in-repo mode), use `bash scripts/<tool>/<script>.sh`. In standalone mode, invoke tools directly."
**Warning signs:** Conventions skill tells Claude to run commands that do not exist.

### Pitfall 5: Report Skill Missing from Plugin
**What goes wrong:** Analyst agent declares `skills: [pentest-conventions, report]`. If `report` is still a symlink in the plugin, it will break when installed externally.
**Why it happens:** `report` utility skill was not in scope for Phases 36-37 because those phases focused on tool and workflow skills.
**How to avoid:** Replace the `report` symlink with a real file as part of this phase, since it is a dependency of the analyst agent.
**Warning signs:** Analyst agent starts without report template knowledge.

### Pitfall 6: check-tools Symlink Scope Decision
**What goes wrong:** `check-tools` is still a symlink in the plugin. It is NOT referenced by any agent's `skills:` field, so it does not block AGEN-01 or AGEN-02. But it will break when the plugin is installed externally.
**Why it happens:** check-tools was not addressed in Phases 36-37 and is not explicitly in Phase 38 requirements.
**How to avoid:** Include check-tools symlink replacement in this phase as an opportunistic fix (it is trivial -- the SKILL.md is self-contained), OR defer to Phase 39 pre-publication cleanup. **Recommendation:** Do it in this phase since it is <30 lines and eliminates a remaining symlink.
**Warning signs:** Plugin boundary validation shows remaining symlinks after Phase 38.

## Code Examples

Verified patterns from the project codebase and official docs:

### Agent File with Plugin-Correct Skill References
```markdown
---
name: pentester
description: Offensive pentesting specialist. Use when orchestrating multi-tool attack workflows, conducting vulnerability assessments, or testing targets with multiple security tools in sequence. Use proactively after scope is defined.
tools: Read, Grep, Glob, Bash
model: inherit
memory: project
skills:
  - pentest-conventions
  - recon
  - scan
  - fuzz
  - crack
  - sniff
---

You are a senior penetration tester conducting authorized security assessments.

[... body with dual-mode awareness ...]
```
Source: Existing pentester.md adapted for plugin context

### Invoker Skill with Plugin-Namespaced Agent Reference
```markdown
---
name: pentester
description: Invoke pentester subagent for multi-tool attack workflow orchestration
context: fork
agent: pentester
disable-model-invocation: true
argument-hint: "<target-or-task>"
---

## Engagement

Target or task: $ARGUMENTS

Conduct a penetration test against the specified target or complete the
specified task. Use the preloaded workflow skills to orchestrate tools.
Follow the project's pentesting conventions for all operations.

If no target or task was provided, ask what to test.
```
Source: Existing invoker skill; `agent:` field may need `netsec-skills:pentester` -- requires empirical test

### pentest-conventions Adapted for Dual-Mode
```markdown
---
name: pentest-conventions
description: Pentesting conventions for this project -- target notation, output formats, safety rules, lab details
user-invocable: false
---

# Pentesting Conventions

Background reference for pentesting workflows. Covers target notation, output formats, safety architecture, scope configuration, and project structure.

## Target Notation

- **IP addresses** -- Single host (10.0.0.1) or CIDR range (192.168.1.0/24)
- **Hostnames** -- Fully qualified (example.com) or short names
- **URLs** -- Full URL format (http://localhost:8080/path)

## Output Expectations

When wrapper scripts are available (in-repo mode), use-case scripts support two flags:
- `-j` / `--json` -- Output structured JSON envelope
- `-x` / `--execute` -- Execute commands instead of displaying them

In standalone mode, tools are invoked directly without wrapper scripts.

## Safety Rules

- All commands should be validated against `.pentest/scope.json` before execution
- Check scope before every tool execution
- Run security tools responsibly and only against authorized targets

## Scope File

Targets must be listed in `.pentest/scope.json` before any pentesting commands will execute.
```
Source: Adapted from existing pentest-conventions SKILL.md for dual-mode portability

### BATS Test for Agent Files (Structural Validation)
```bash
#!/usr/bin/env bats
# tests/test-agent-personas.bats

setup() {
    load 'test_helper/common-setup'
    _common_setup
}

AGENTS=(pentester defender analyst)

@test "AGEN-01: each agent file exists as real file in plugin" {
    local failing=()
    for agent in "${AGENTS[@]}"; do
        local plugin_file="${PROJECT_ROOT}/netsec-skills/agents/${agent}.md"
        if [[ ! -f "$plugin_file" ]]; then
            failing+=("$agent (missing)")
        elif [[ -L "$plugin_file" ]]; then
            failing+=("$agent (symlink)")
        fi
    done
    if [[ ${#failing[@]} -gt 0 ]]; then
        fail "Agent file issues: ${failing[*]}"
    fi
}

@test "AGEN-01: each agent has skills: field in frontmatter" {
    local failing=()
    for agent in "${AGENTS[@]}"; do
        local file="${PROJECT_ROOT}/.claude/agents/${agent}.md"
        if ! grep -q "^skills:" "$file"; then
            failing+=("$agent")
        fi
    done
    if [[ ${#failing[@]} -gt 0 ]]; then
        fail "Missing skills: in frontmatter: ${failing[*]}"
    fi
}
```
Source: Pattern from test-dual-mode-skills.bats and test-workflow-skills.bats

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Agent files as symlinks in plugin | Real files with dual-mode body content | Phase 38 (now) | Agents work outside the repo |
| In-repo-only agent instructions | Dual-mode detection in agent body | Phase 38 (now) | Pentester agent works in standalone |
| pentest-conventions missing from plugin | Real skill file with neutral/dual-mode language | Phase 38 (now) | All 3 agents get conventions context |
| Invoker skills as symlinks | Real SKILL.md files with correct agent references | Phase 38 (now) | /pentester, /defender, /analyst work in plugin |

**Deprecated/outdated:**
- Symlinks in `netsec-skills/agents/` and `netsec-skills/skills/agents/`: Must be replaced with real files
- "Never invoke raw security tools directly" in pentester agent: Must be replaced with dual-mode instruction
- pentest-conventions referencing `scripts/<tool>/<script>.sh` unconditionally: Must be made mode-aware

## Open Questions

1. **Does `agent: pentester` resolve to plugin agent in plugin context?**
   - What we know: Official docs say `agent:` resolves to `.claude/agents/` or built-in agents. Plugin agents are namespaced as `plugin-name:agent-name` in the UI. The bug report #29441 shows skills resolution uses "plugin-prefix fallback."
   - What's unclear: Whether a plugin skill with `agent: pentester` automatically resolves to the plugin's own `agents/pentester.md`, or whether it needs `agent: netsec-skills:pentester`.
   - Recommendation: Test empirically with bare name first. If it fails, try namespaced form. Success Criterion 3 explicitly requires this empirical test.

2. **Does `skills: [recon]` in a plugin agent resolve to plugin-local skills?**
   - What we know: Issue #15944 confirms "the skills field in agents only supports referencing skills within the same plugin." Skills with `name:` field register by that name. All plugin skills have `name:` fields matching the bare names used in agent `skills:` fields.
   - What's unclear: Whether skill resolution matches on `name:` field value or directory path within the plugin.
   - Recommendation: Test with one agent + one skill first (Success Criterion 3). If `name:` field matching works, all skills should resolve correctly.

3. **Should check-tools symlink be replaced in this phase?**
   - What we know: check-tools is NOT referenced by any agent's `skills:` field. It is a remaining symlink that will break in external plugin install. Its SKILL.md references `scripts/check-tools.sh` which does not exist in standalone mode.
   - What's unclear: Whether to include it in Phase 38 scope or defer to Phase 39.
   - Recommendation: Include it -- it is a small file (50 lines), has no dependencies, and eliminating all remaining symlinks simplifies Phase 39 scope. The check-tools skill also needs minor adaptation (remove hard reference to `bash scripts/check-tools.sh`, add inline tool detection commands).

4. **Should in-repo agents also be updated to dual-mode?**
   - What we know: Phase 36 and 37 both updated in-repo AND plugin versions identically. BATS sync tests verify they match.
   - What's unclear: Whether there is a reason to keep in-repo agents wrapper-script-only.
   - Recommendation: YES -- update both in-repo and plugin versions identically, following the Phase 36-37 precedent. Add a BATS sync test.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | BATS 1.x (installed at tests/bats/) |
| Config file | None -- BATS uses direct invocation |
| Quick run command | `./tests/bats/bin/bats tests/test-agent-personas.bats --timing` |
| Full suite command | `./tests/bats/bin/bats tests/ --timing` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| AGEN-01 | Agent files exist as real files (not symlinks) in plugin | unit | Check file existence + not symlink for 3 agents | No -- Wave 0 |
| AGEN-01 | Agent skills: field references valid skills | unit | Grep skills: field, verify each referenced skill exists in plugin | No -- Wave 0 |
| AGEN-01 | Agent body does not contain in-repo-only instructions | unit | Grep for "Never invoke raw" / "Always use wrapper" in agent body | No -- Wave 0 |
| AGEN-02 | Invoker SKILL.md files exist as real files (not symlinks) in plugin | unit | Check file existence + not symlink for 3 invoker skills | No -- Wave 0 |
| AGEN-02 | Invoker skills have context: fork and agent: fields | unit | Grep frontmatter for context and agent fields | No -- Wave 0 |
| AGEN-02 | pentest-conventions exists in plugin as real file | unit | Check file existence in netsec-skills/skills/utility/pentest-conventions/ | No -- Wave 0 |
| ALL | Plugin and in-repo agent files are identical | unit | `cmp -s` between in-repo and plugin versions | No -- Wave 0 |
| ALL | Plugin and in-repo invoker skills are identical | unit | `cmp -s` between in-repo and plugin versions | No -- Wave 0 |
| ALL | No remaining symlinks in plugin (except if check-tools deferred) | unit | `find netsec-skills -type l` returns 0 results | No -- Wave 0 |

### Sampling Rate
- **Per task commit:** `./tests/bats/bin/bats tests/test-agent-personas.bats --timing`
- **Per wave merge:** `./tests/bats/bin/bats tests/ --timing`
- **Phase gate:** Full suite green + manual smoke: `claude --plugin-dir ./netsec-skills` then invoke `/pentester` to verify agent loads with preloaded skills

### Wave 0 Gaps
- [ ] `tests/test-agent-personas.bats` -- covers AGEN-01 and AGEN-02 structural tests
- [ ] Manual smoke test: `claude --plugin-dir ./netsec-skills` then `/pentester <target>` to verify skill preloading and agent resolution

## Recommended Plan Structure

Based on scope analysis, this phase should have 2 plans:

### Plan 1: BATS scaffold + pilot transformation (pentester + pentest-conventions)
- Create `tests/test-agent-personas.bats` with structural tests for all 3 agents and 3 invoker skills
- Add `pentest-conventions` as a real SKILL.md in the plugin (currently missing entirely)
- Transform pentester agent: replace symlink with real file, add dual-mode body, correct skill references
- Transform pentester invoker skill: replace symlink with real file, verify agent field resolution
- **CRITICAL empirical test:** Run `claude --plugin-dir ./netsec-skills` and invoke `/pentester` to verify:
  - Agent launches (agent: field resolves correctly)
  - Skills are preloaded (pentest-conventions + at least one workflow skill like recon)
  - If bare name fails, try namespaced form and update all files accordingly
- This plan covers the hardest case and validates the pattern before scaling to remaining agents
- Update in-repo versions identically

### Plan 2: Scale to remaining agents + utility skills + final sync
- Transform defender and analyst agents: replace symlinks, update bodies as needed
- Transform defender and analyst invoker skills: replace symlinks
- Replace `report` utility skill symlink with real file (required by analyst agent's `skills:` field)
- Replace `check-tools` utility skill symlink with real file (opportunistic cleanup)
- Run full BATS suite including existing Phase 36-37 tests for zero regressions
- Run plugin boundary validation (`bash scripts/validate-plugin-boundary.sh`)
- Verify zero remaining symlinks in plugin directory

## Sources

### Primary (HIGH confidence)
- Claude Code Skills docs (https://code.claude.com/docs/en/skills) -- frontmatter fields, context: fork, agent: field resolution, skill namespace
- Claude Code Subagents docs (https://code.claude.com/docs/en/sub-agents) -- skills: preloading in agents, agent configuration, namespace
- Claude Code Plugins docs (https://code.claude.com/docs/en/plugins) -- plugin structure, component namespacing, skill namespace format
- Claude Code Plugins Reference (https://code.claude.com/docs/en/plugins-reference) -- agent file format, plugin directory structure, namespace rules
- Project codebase: All 3 agent files, 3 invoker skills, pentest-conventions skill, report skill, check-tools skill

### Secondary (MEDIUM confidence)
- GitHub issue #22063 (https://github.com/anthropics/claude-code/issues/22063) -- skills with `name:` field bypass plugin prefix (closed as not planned, behavior confirmed)
- GitHub issue #15944 (https://github.com/anthropics/claude-code/issues/15944) -- skills: field in agents only supports same-plugin references (closed as not planned, behavior confirmed)
- GitHub issue #17283 (https://github.com/anthropics/claude-code/issues/17283) -- agent: and context: fork now honored in skills (closed as completed Jan 2026)
- GitHub issue #29441 (https://github.com/anthropics/claude-code/issues/29441) -- skills: preloading works for in-process subagents, uses plugin-prefix fallback
- Phase 36 and 37 RESEARCH.md and PLANs -- established transformation patterns (symlink replacement, dual-mode, BATS testing)

### Tertiary (LOW confidence)
- Agent field resolution in plugin-to-plugin-agent context: Not explicitly documented in official docs; must be tested empirically

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- Same file formats as existing agents and skills; established transformation pattern from Phase 36-37
- Architecture: HIGH -- Plugin namespace rules well-documented; transformation pattern proven
- Skill resolution: MEDIUM -- Official docs confirm same-plugin-only resolution and `name:` field behavior, but exact matching mechanism (name vs directory) not explicitly documented
- Agent field resolution: MEDIUM -- Not explicitly documented for plugin-to-plugin-agent case; requires empirical test per Success Criterion 3
- Pitfalls: HIGH -- All identified from codebase analysis, official docs, and GitHub issues

**Research date:** 2026-03-06
**Valid until:** 2026-04-06 (stable domain -- agent files are markdown content, not API-dependent)
