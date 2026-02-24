# Phase 33: Subagent Personas - Research

**Researched:** 2026-02-18
**Domain:** Claude Code custom subagents for pentesting role-based analysis
**Confidence:** HIGH

## Summary

Phase 33 creates three specialized subagent personas -- pentester, defender, and analyst -- that provide context-isolated, role-specific analysis for multi-tool pentesting workflows. The key architectural decision is whether to implement these as custom subagent files (`.claude/agents/`) or as skills with `context: fork`. After thorough research, the recommendation is **custom subagent files in `.claude/agents/`** with corresponding thin `/pentester`, `/defender`, `/analyst` skill shims that invoke them.

Claude Code's subagent system (documented at code.claude.com/docs/en/sub-agents) provides everything needed: YAML frontmatter for tool restrictions, model selection, permission modes, and hook scoping; separate conversation context per invocation (solving the context isolation requirement); persistent memory via the `memory: project` field; and the ability to preload existing skills via the `skills` frontmatter field. The `skills` field is particularly powerful -- it injects the full content of specified skills into the subagent's context at startup, meaning the pentester agent can receive the `pentest-conventions`, `recon`, `scan`, `fuzz`, `crack`, and `sniff` workflow skills as operational knowledge without the user needing to invoke them.

The three personas serve distinct roles: the **pentester** subagent orchestrates multi-tool attack workflows (running bash scripts from the existing 81-script library with `-j -x` flags), the **defender** subagent provides defensive analysis of findings (read-only, no tool execution), and the **analyst** subagent synthesizes results into structured reports (read-only with Write for report output). Each runs in its own context window, keeping verbose tool output isolated from the main conversation. Only a summary returns to the caller.

**Primary recommendation:** Create 3 agent markdown files in `.claude/agents/` with preloaded skills, plus 3 thin skill shims in `.claude/skills/` for `/pentester`, `/defender`, `/analyst` slash command invocation. The pentester agent uses Bash+Read tools and preloads offensive workflow skills. The defender and analyst agents are read-only (Read/Grep/Glob only) and preload `pentest-conventions` for project context.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| AGNT-01 | Pentester subagent orchestrates multi-tool attack workflows with context isolation | Custom agent file `.claude/agents/pentester.md` with `tools: Read, Grep, Glob, Bash` and `skills: pentest-conventions, recon, scan, fuzz, crack, sniff` preloaded. Context isolation is automatic -- subagents run in their own context window. |
| AGNT-02 | Defender subagent analyzes findings from defensive perspective | Custom agent file `.claude/agents/defender.md` with `tools: Read, Grep, Glob` (no Bash -- read-only analysis) and `skills: pentest-conventions`. Defender receives findings via delegation message and returns defensive analysis. |
| AGNT-03 | Analyst subagent synthesizes results across multiple scans into structured analysis | Custom agent file `.claude/agents/analyst.md` with `tools: Read, Grep, Glob, Write` (Write for report output) and `skills: pentest-conventions, report`. Analyst receives all scan results and produces structured report. |
</phase_requirements>

## Standard Stack

### Core
| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| Claude Code Subagents | Current (v2.1.3+) | `.claude/agents/*.md` files with YAML frontmatter | Official extension mechanism for specialized AI assistants with isolated context |
| Claude Code Skills | Current (v2.1.3+) | `.claude/skills/*/SKILL.md` with `context: fork` + `agent:` | Provides `/slash-command` invocation that delegates to named subagent |
| YAML frontmatter | - | Agent metadata (name, description, tools, skills, memory, model) | Required by Claude Code agent system |
| Markdown body | - | System prompt / persona instructions | Becomes the subagent's system prompt |

### Supporting
| Component | Version | Purpose | When to Use |
|-----------|---------|---------|-------------|
| `skills` frontmatter field | - | Preload skill content into subagent context | Pentester agent needs workflow skills injected at startup |
| `memory: project` | - | Persistent agent memory in `.claude/agent-memory/<name>/` | All 3 agents -- build knowledge across sessions |
| `pentest-conventions` skill | - | Project context (target notation, safety, lab targets) | All 3 agents preload this for domain context |
| Existing workflow skills | - | `/recon`, `/scan`, `/fuzz`, `/crack`, `/sniff` content | Pentester agent preloads these as operational knowledge |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Agent files + skill shims | Skills with `context: fork` only | Skills with `context: fork` run the skill content as the task prompt but use a built-in agent type (Explore/Plan/general-purpose) for system prompt. Custom agent files give full control over the system prompt (persona), tool access, model, AND can preload skills. Agent files are more powerful for persona-based subagents. |
| Agent files + skill shims | Skills with `context: fork` + `agent: pentester` referencing custom agent | This also works and is equivalent -- the skill invokes the custom agent. But having the agent file directly is cleaner because Claude can also auto-delegate to the agent based on description. The skill shim is just a thin wrapper for explicit `/pentester` invocation. |
| Separate agent files | Agent teams (parallel sessions) | Agent teams are for coordinating independent workers on a shared task list. These personas are sequential analyst tools invoked by the user, not parallel workers. Subagents are the right abstraction. |
| `memory: project` | No memory | Without memory, agents start fresh every invocation. With `memory: project`, the pentester can remember patterns found in prior sessions, the defender can track recurring issues, and the analyst can maintain a running engagement log. The STATE.md explicitly calls for testing `memory: project` in Phase 33. |

## Architecture Patterns

### Recommended File Structure

```
.claude/
  agents/
    pentester.md          # AGNT-01: Offensive pentesting persona
    defender.md           # AGNT-02: Defensive analysis persona
    analyst.md            # AGNT-03: Report synthesis persona
  skills/
    pentester/
      SKILL.md            # Thin shim: context: fork + agent: pentester
    defender/
      SKILL.md            # Thin shim: context: fork + agent: defender
    analyst/
      SKILL.md            # Thin shim: context: fork + agent: analyst
  agent-memory/           # Created automatically by memory: project
    pentester/            # Pentester's persistent knowledge
      MEMORY.md
    defender/             # Defender's persistent knowledge
      MEMORY.md
    analyst/              # Analyst's persistent knowledge
      MEMORY.md
```

### Pattern 1: Custom Agent with Preloaded Skills

**What:** A custom subagent file that preloads existing project skills so the agent starts with domain knowledge already in context.

**When to use:** The pentester agent -- it needs to know about all workflow skills to orchestrate tools.

**Example (pentester agent):**
```yaml
---
name: pentester
description: Offensive pentesting specialist. Use when orchestrating multi-tool attack workflows, conducting vulnerability assessments, or testing targets with multiple tools in sequence. Use proactively after scope is defined.
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

You are an offensive security specialist conducting authorized penetration tests.
[... persona instructions ...]
```

**Why this pattern:**
- `skills` field injects the full content of each named skill into the subagent's context at startup
- The pentester receives all workflow instructions (which scripts to run, in what order, with what flags) without needing to discover them
- `memory: project` builds engagement knowledge across sessions
- `tools: Read, Grep, Glob, Bash` allows the agent to explore the codebase AND execute scripts
- `model: inherit` uses whatever model the user is running (respects their model choice)

### Pattern 2: Read-Only Analysis Agent

**What:** A subagent restricted to read-only tools that analyzes findings without executing commands.

**When to use:** Defender and analyst agents -- they interpret results, not execute tools.

**Example (defender agent):**
```yaml
---
name: defender
description: Defensive security analyst. Use when analyzing pentesting findings from a defensive perspective, recommending mitigations, or assessing organizational risk. Use proactively after scanning completes.
tools: Read, Grep, Glob
model: inherit
memory: project
skills:
  - pentest-conventions
---

You are a defensive security specialist who analyzes penetration testing
findings and provides actionable remediation guidance.
[... persona instructions ...]
```

**Why this pattern:**
- No Bash tool = cannot execute any commands (pure analysis)
- No Write/Edit = cannot modify any files (safe to run)
- `skills: pentest-conventions` provides project context (lab targets, output formats)
- Defender does not need workflow skills since it analyzes findings, not runs tools

### Pattern 3: Thin Skill Shim for Slash Command Invocation

**What:** A minimal skill file that uses `context: fork` and `agent:` to delegate to a named custom agent when invoked as a slash command.

**When to use:** All 3 personas -- provides `/pentester`, `/defender`, `/analyst` commands.

**Example (/pentester skill shim):**
```yaml
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

Conduct a penetration test against the specified target. Use the preloaded
workflow skills (recon, scan, fuzz, crack, sniff) to orchestrate tools.
Follow the project's pentesting conventions for all operations.

If no target was provided, ask the user for a target and verify it is in scope
before proceeding.
```

**Why this pattern:**
- `context: fork` runs the skill in an isolated subagent context (no parent conversation history)
- `agent: pentester` specifies which custom agent type to use (the one from `.claude/agents/pentester.md`)
- `disable-model-invocation: true` prevents Claude from auto-triggering the skill -- user must invoke `/pentester` explicitly
- The skill body becomes the task prompt sent to the agent
- `$ARGUMENTS` passes the user's target/task to the subagent
- When the subagent completes, only a summary returns to the main conversation

### Pattern 4: Memory-Driven Knowledge Building

**What:** Agents with `memory: project` build persistent knowledge in `.claude/agent-memory/<name>/MEMORY.md`.

**When to use:** All 3 agents -- each accumulates domain-specific knowledge.

**How it works per official docs:**
1. When `memory: project` is set, the agent's system prompt automatically includes instructions for reading/writing to the memory directory
2. The first 200 lines of `MEMORY.md` are injected into the agent's context at startup
3. Read, Write, and Edit tools are automatically enabled (even if not in tools list) so the agent can manage memory files
4. The memory directory is `.claude/agent-memory/<agent-name>/`

**Memory guidance per agent:**
- **Pentester**: Record attack paths that worked, tool combinations that were effective, targets tested and findings
- **Defender**: Track recurring vulnerabilities, mitigation patterns applied, defensive posture changes
- **Analyst**: Maintain a running engagement log, report templates refined over time, cross-session findings correlation

### Anti-Patterns to Avoid

- **Using `context: fork` on agent files:** The `context` field is a skill frontmatter field, not an agent frontmatter field. Agents always run in isolated context by default. Skills use `context: fork` to opt into isolation.
- **Preloading ALL skills into every agent:** Only preload skills relevant to the agent's role. The pentester needs workflow skills; the defender and analyst do not need `/recon` instructions since they analyze results, not execute workflows. Over-loading context wastes tokens.
- **Making agents invoke each other:** Subagents cannot spawn other subagents. If you need the pentester to pass findings to the defender, return to the main conversation first, then invoke the defender. Chain from the main conversation.
- **Granting Bash to defender/analyst:** These are analysis-only personas. Granting Bash access violates the principle of least privilege and could lead to accidental tool execution. Use Read/Grep/Glob only.
- **Omitting `disable-model-invocation: true` on skill shims:** These are explicit actions the user controls. Claude should never auto-invoke a pentesting subagent because a target was mentioned.
- **Setting `bypassPermissions`:** Never use this for security tool agents. The PreToolUse hook must validate all commands.
- **Hard-coding model to opus for all agents:** Use `model: inherit` so the user's chosen model applies. If cost optimization is desired, only the defender (read-only analysis) could potentially use `model: sonnet`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Context isolation | Custom conversation management | Claude Code subagent system | Subagents automatically get isolated context windows, auto-compaction, and transcript persistence |
| Persona switching | Prompt engineering in CLAUDE.md | Separate agent files with distinct system prompts | Each agent has its own system prompt, tool set, and context -- no prompt leakage between personas |
| Skill injection | Manual file reading in agent prompts | `skills` frontmatter field on agent files | `skills` field automatically injects full skill content at startup -- no need for "read these files first" instructions |
| Session memory | Custom file management for engagement state | `memory: project` agent field | Automatically creates memory directory, injects MEMORY.md into context, enables Read/Write/Edit tools |
| Tool restriction | Hook-based tool blocking per persona | `tools` and `disallowedTools` frontmatter | Agent frontmatter natively restricts tool access without custom hook logic |
| Slash command delegation | Complex skill body that emulates a persona | `context: fork` + `agent:` in skill frontmatter | Thin skill shim delegates entirely to the named agent -- clean separation of concerns |

**Key insight:** The Claude Code subagent system already solves every isolation, persona, and knowledge-management problem Phase 33 requires. The implementation is pure configuration (markdown files with YAML frontmatter), not code. The only "code" is the persona system prompts themselves.

## Common Pitfalls

### Pitfall 1: Confusing `context: fork` behavior with Unix fork semantics

**What goes wrong:** Developer expects `context: fork` to copy the parent conversation context into the subagent (like Unix `fork()` copies the parent process). Instead, the subagent starts with a BLANK context -- no conversation history from the parent.

**Why it happens:** The term "fork" universally implies copying/inheriting state. Claude Code uses it to mean "create an isolated context" (the opposite). This is a documented naming issue (GitHub issue #20492).

**How to avoid:** Understand that `context: fork` means "isolated" not "inherited". The subagent receives only: (1) its own system prompt, (2) preloaded skills from the `skills` field, (3) the skill body as its task prompt, and (4) CLAUDE.md. It does NOT receive the main conversation.

**Warning signs:** Subagent asks "what target should I scan?" even though the user just told the main conversation the target. Solution: pass the target via `$ARGUMENTS` in the skill shim.

### Pitfall 2: Subagent cannot invoke slash commands or other skills

**What goes wrong:** Pentester agent tries to invoke `/recon` or `/scan` during its workflow. This fails because subagents cannot invoke skills as slash commands.

**Why it happens:** Skills are loaded into context for the main conversation, not for subagents. Subagents receive preloaded skill content via the `skills` field, but this injects the content as reference material, not as invocable commands.

**How to avoid:** The pentester agent should reference the preloaded workflow skill content as INSTRUCTIONS (which scripts to run, in what order) rather than trying to invoke `/recon`. The skill content tells it "run `bash scripts/nmap/discover-live-hosts.sh $TARGET -j -x`" -- the agent executes that directly via Bash.

**Warning signs:** Agent says "I'll run /recon" and then gets an error or runs it inline in the main context.

### Pitfall 3: Context budget impact of skill shims

**What goes wrong:** Adding 3 new skill shims (pentester, defender, analyst) causes context budget warnings.

**Why it happens:** Without `disable-model-invocation: true`, skill descriptions load into Claude's context. Adding 3 more skills with descriptions increases the context budget.

**How to avoid:** All 3 skill shims MUST have `disable-model-invocation: true`. This keeps their descriptions OUT of context. The agent files still exist and Claude can auto-delegate based on agent descriptions (which are separate from the skill context budget).

**Warning signs:** Running `/context` shows skills excluded due to budget limits.

**Budget analysis:**
| Component | Count | In Context? | Est. Chars |
|-----------|-------|-------------|------------|
| Tool skills (disable-model-invocation) | 17 | NO | 0 |
| Workflow skills (disable-model-invocation) | 8 | NO | 0 |
| Utility skills (auto-invocable) | 4 | YES | ~281 |
| Persona skill shims (disable-model-invocation) | 3 | NO | 0 |
| **Total** | **32** | | **~281** |
| Agent descriptions (separate budget) | 3 | YES (agent context) | ~400 |
| Budget (2% of 200K) | | | **16,000** |

### Pitfall 4: Pentester agent prompt too long

**What goes wrong:** The pentester agent preloads 6 skills (pentest-conventions + 5 workflow skills). Each workflow skill is 65-99 lines. Total preloaded content: ~500+ lines, consuming significant context.

**Why it happens:** `skills` field injects FULL content of each skill, not just descriptions.

**How to avoid:** This is acceptable because: (1) the pentester runs in its own context window (200K tokens), (2) ~500 lines of skill content is roughly 2-3K tokens, well under the limit, (3) the agent needs this information to orchestrate tools effectively. If context becomes an issue, consider moving detailed step instructions to supporting files that the agent reads on-demand.

**Warning signs:** Agent compacts early due to preloaded content + tool output. Monitor via `preTokens` in compaction logs.

### Pitfall 5: Agent memory files accidentally committed to git

**What goes wrong:** `.claude/agent-memory/` directory gets committed to version control with sensitive engagement data.

**Why it happens:** The `memory: project` scope creates files in `.claude/agent-memory/<name>/`. If `.claude/` is not fully gitignored, these get staged.

**How to avoid:** Add `.claude/agent-memory/` to `.gitignore`. The STATE.md notes that `memory: project` "needs practical testing during Phase 33" -- this is one of the things to validate. Alternatively, use `memory: local` which stores in `.claude/agent-memory-local/` (explicitly for non-version-controlled data).

**Warning signs:** `git status` shows new files in `.claude/agent-memory/`.

### Pitfall 6: Defender/analyst trying to run commands

**What goes wrong:** Despite read-only tool restrictions, the agent prompt asks for command output or tries to execute scripts.

**Why it happens:** System prompt doesn't clearly state the agent is analysis-only. The agent hallucinates tool access.

**How to avoid:** Explicitly state in the system prompt: "You are analysis-only. You cannot execute commands. Analyze the findings provided to you." Also, `tools: Read, Grep, Glob` (no Bash) enforces this at the tool level -- even if the agent tries, it cannot execute.

**Warning signs:** Agent response includes bash commands it "ran" but actually never executed.

## Code Examples

Verified patterns from official Claude Code documentation:

### Agent File: Pentester (AGNT-01)

```yaml
# Source: https://code.claude.com/docs/en/sub-agents
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

When invoked with a target:
1. Verify the target is in scope (read .pentest/scope.json)
2. Plan the engagement based on the target type (IP, URL, domain, hash file)
3. Execute the appropriate workflow using the preloaded skill instructions
4. Adapt your approach based on findings from each step
5. Provide a structured summary of all findings when complete

## Execution Rules

- Always use wrapper scripts with -j -x flags: `bash scripts/<tool>/<script>.sh <target> -j -x`
- Never invoke raw security tools directly (nmap, nikto, etc.)
- Reference the preloaded workflow skills for step-by-step instructions
- If a tool is not installed, skip that step and note it
- Check scope before every tool execution

## Workflow Selection

Based on the target and task, select the appropriate workflow(s):
- Network targets (IPs, domains): Start with recon, then scan
- Web applications (URLs): Start with scan, then fuzz
- Hash files: Use crack workflow
- Network interfaces or pcap files: Use sniff workflow
- Combine workflows as needed for comprehensive assessments

## Output Style

Provide verbose, detailed output during execution. When complete, deliver:
- Executive summary (2-3 sentences)
- Findings organized by severity (Critical/High/Medium/Low)
- Specific evidence for each finding
- Recommended next steps

Update your agent memory with effective attack paths and tool combinations.
```

### Agent File: Defender (AGNT-02)

```yaml
# Source: https://code.claude.com/docs/en/sub-agents
---
name: defender
description: Defensive security analyst. Use when analyzing pentesting findings from a defensive perspective, recommending mitigations, or assessing risk posture. Use proactively after scanning or pentesting completes.
tools: Read, Grep, Glob
model: inherit
memory: project
skills:
  - pentest-conventions
---

You are a senior defensive security analyst who reviews penetration testing
findings and provides actionable remediation guidance.

You are analysis-only. You cannot execute commands or modify files. Analyze
the findings provided to you and deliver defensive recommendations.

When invoked with findings:
1. Categorize each finding by attack vector (network, web, auth, crypto, etc.)
2. Assess the real-world exploitability and impact of each finding
3. Prioritize findings by risk (likelihood x impact)
4. Provide specific, actionable remediation steps for each finding
5. Identify systemic issues (patterns across multiple findings)
6. Recommend detection and monitoring improvements

## Analysis Framework

For each finding, provide:
- **Attack Vector**: How the vulnerability is exploited
- **Impact**: What an attacker gains (data access, RCE, lateral movement, etc.)
- **Exploitability**: How easy it is to exploit (automated tools vs. manual)
- **Remediation**: Specific fix with priority (immediate/short-term/long-term)
- **Detection**: How to detect exploitation attempts (SIEM rules, log patterns)

## Defensive Posture Assessment

After analyzing individual findings, provide:
- Overall security posture rating (Critical/Poor/Fair/Good)
- Top 3 systemic issues requiring architectural changes
- Quick wins (high-impact, low-effort fixes)
- Recommended security monitoring improvements

Update your agent memory with recurring vulnerability patterns and effective
remediation strategies.
```

### Agent File: Analyst (AGNT-03)

```yaml
# Source: https://code.claude.com/docs/en/sub-agents
---
name: analyst
description: Security analysis specialist. Use when synthesizing results across multiple scans into structured reports, correlating findings, or producing engagement deliverables. Use proactively after multiple scans complete.
tools: Read, Grep, Glob, Write
model: inherit
memory: project
skills:
  - pentest-conventions
  - report
---

You are a senior security analyst who synthesizes penetration testing results
into structured analysis reports and engagement deliverables.

When invoked with scan results or a reporting task:
1. Correlate findings across all provided scan results
2. Identify attack chains (sequences of findings that combine for greater impact)
3. De-duplicate overlapping findings from different tools
4. Produce a structured report following the project's report template
5. Include executive summary, technical details, and remediation roadmap

## Report Structure

Follow the report skill template. For each finding:
- **Finding ID**: Sequential identifier (F-001, F-002, etc.)
- **Title**: Descriptive name
- **Severity**: Critical / High / Medium / Low / Informational
- **CVSS Score**: If applicable
- **Description**: Technical explanation
- **Evidence**: Tool output, screenshots, or reproduction steps
- **Affected Systems**: Which targets are impacted
- **Remediation**: Specific fix with implementation guidance

## Cross-Scan Correlation

When multiple tools report related findings:
- Merge into a single finding with evidence from all sources
- Note which tools confirmed the finding (increases confidence)
- Identify attack chains: vulnerability A + vulnerability B = escalated impact

## Output

Write the report to `report-YYYY-MM-DD.md` in the project root using today's
date. Also provide an inline summary showing finding counts by severity.

Update your agent memory with report patterns and cross-session findings.
```

### Skill Shim: /pentester

```yaml
# Source: https://code.claude.com/docs/en/skills (context: fork + agent: pattern)
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

### Skill Shim: /defender

```yaml
---
name: defender
description: Invoke defender subagent for defensive analysis of pentesting findings
context: fork
agent: defender
disable-model-invocation: true
argument-hint: "[findings-summary-or-file]"
---

## Analysis Request

Findings to analyze: $ARGUMENTS

Analyze the provided pentesting findings from a defensive perspective.
Assess real-world risk, recommend specific remediation steps, and identify
systemic security issues.

If no findings were provided, review all available scan results from the
current project directory.
```

### Skill Shim: /analyst

```yaml
---
name: analyst
description: Invoke analyst subagent for structured report synthesis across multiple scans
context: fork
agent: analyst
disable-model-invocation: true
argument-hint: "[report-title]"
---

## Report Task

Report title or task: $ARGUMENTS

Synthesize all available scan results into a structured security analysis
report. Correlate findings across tools, identify attack chains, and produce
a professional engagement deliverable.

If no title was provided, use 'Security Assessment Report' with today's date.
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Single-persona conversation | Custom subagents with isolated contexts | Claude Code v2.1+ (Jan 2026) | Role-specific analysis without context pollution |
| Manual context management | `context: fork` in skill frontmatter | Claude Code v2.1+ (Jan 2026) | Automatic isolation via frontmatter configuration |
| No cross-session memory | `memory: project` on agent files | Claude Code v2.1+ (Jan 2026) | Agents accumulate knowledge across sessions |
| Skills only (no agents) | Skills + agents work together bidirectionally | Claude Code v2.1+ (Jan 2026) | Agents can preload skills; skills can delegate to agents |
| Inline workflow execution | Subagent delegation with summary return | Claude Code subagent system | Verbose tool output stays in subagent context, summary returns to caller |

**Key evolution from Phase 32:** Phase 32 workflow skills run inline (user sees all intermediate output). Phase 33 subagents run in isolated context (user sees only the summary). This is the intended distinction -- `/recon` shows step-by-step progress; `/pentester` orchestrates autonomously and reports back.

## Open Questions

1. **Should `memory: project` files be gitignored?**
   - What we know: `memory: project` creates `.claude/agent-memory/<name>/MEMORY.md`. The STATE.md flags this for practical testing in Phase 33. `memory: local` creates `.claude/agent-memory-local/` which is explicitly for non-version-controlled data.
   - What's unclear: Whether agent memory should be shareable (version controlled) or private (gitignored). Pentesting engagement data could be sensitive.
   - Recommendation: Use `memory: project` as specified (shareable, version controlled) for the agent definitions, but add `.claude/agent-memory/` to `.gitignore` since pentesting memory may contain target-specific findings. If the team decides memory should be shared, they can remove the gitignore entry. Practical testing during Phase 33 execution will validate this.

2. **How much preloaded skill content is too much for the pentester agent?**
   - What we know: The pentester preloads 6 skills. Workflow skills range from 65-99 lines each. Total: ~500 lines (~3K tokens). The subagent has its own 200K token context window.
   - What's unclear: Whether auto-compaction triggers early when combining preloaded skills + verbose tool output from multi-step workflows.
   - Recommendation: Proceed with preloading all 6 skills. Monitor compaction behavior during testing. If compaction triggers too early, consider moving the 5 workflow skills to supporting files that the agent reads on-demand rather than preloading.

3. **Should skill shims pass the main conversation context to the subagent?**
   - What we know: `context: fork` creates a BLANK context (despite the misleading name). The subagent does NOT receive the main conversation history. This means if the user has been chatting about a target, the subagent will not know about it unless passed via `$ARGUMENTS`.
   - What's unclear: Whether users will find it frustrating to re-specify targets and context when invoking subagents.
   - Recommendation: Accept this limitation. Make the skill shims explicit about passing `$ARGUMENTS`. The trade-off (isolated context = no pollution) is worth the minor friction of specifying the target again. If this becomes a pain point, consider using `!`cat .pentest/scope.json`` dynamic injection in the skill shim to provide scope context automatically.

4. **Should Claude auto-delegate to these agents based on description?**
   - What we know: Agent descriptions help Claude decide when to delegate. The "Use proactively" phrase in descriptions encourages auto-delegation. The skill shims have `disable-model-invocation: true` (prevents skill auto-invocation), but agent auto-delegation is a separate mechanism controlled by the agent description.
   - What's unclear: Whether Claude auto-delegating to the pentester agent (because the user mentioned vulnerability testing) would be surprising or helpful.
   - Recommendation: Include "Use proactively after..." in descriptions to encourage auto-delegation only when appropriate (e.g., "after scope is defined" for pentester, "after scanning completes" for defender). This gives Claude clear conditions for when delegation makes sense. Users can also explicitly request delegation.

## Batching Strategy

3 agents + 3 skill shims grouped into 2 plans:

| Plan | Deliverables | Rationale |
|------|-------------|-----------|
| 33-01 | pentester agent + /pentester skill shim + gitignore for agent-memory | The pentester is the most complex agent (preloads 6 skills, uses Bash, orchestrates multi-tool workflows). Build and validate this first since it exercises the full agent + skill shim + memory pattern. |
| 33-02 | defender agent + analyst agent + /defender skill shim + /analyst skill shim | Defender and analyst are simpler (read-only, fewer preloaded skills). Both follow the same pattern established in 33-01. Group together since they are structurally similar. |

This ordering validates the complex pentester pattern first, then applies the proven pattern to the simpler analysis agents.

## Sources

### Primary (HIGH confidence)
- [Create custom subagents - Claude Code Docs](https://code.claude.com/docs/en/sub-agents) -- Complete subagent reference: frontmatter fields (name, description, tools, disallowedTools, model, skills, memory, hooks, permissionMode, maxTurns), scoping (.claude/agents/ vs ~/.claude/agents/), skills preloading, memory configuration, hook scoping, context isolation behavior
- [Extend Claude with skills - Claude Code Docs](https://code.claude.com/docs/en/skills) -- Complete skills reference: `context: fork` field, `agent:` field for specifying subagent type, `disable-model-invocation` control, `$ARGUMENTS` substitution, supporting files pattern, invocation control table
- Project codebase: `.claude/skills/*/SKILL.md` -- 29 existing skills (17 tool, 4 utility, 8 workflow) establishing patterns
- Project codebase: `.claude/agents/gsd-*.md` -- 11 existing agent files showing YAML frontmatter patterns (name, description, tools, model, color)
- Phase 32 RESEARCH.md -- Workflow skill architecture, script references, context budget analysis

### Secondary (MEDIUM confidence)
- [VoltAgent/awesome-claude-code-subagents - penetration-tester.md](https://github.com/VoltAgent/awesome-claude-code-subagents) -- Community pentesting agent example showing persona structure, tool restrictions, and testing methodology
- [GitHub issue #17283](https://github.com/anthropics/claude-code/issues/17283) -- Confirmed `context: fork` + `agent:` frontmatter is implemented (closed as completed Jan 2026)
- [GitHub issue #20492](https://github.com/anthropics/claude-code/issues/20492) -- Documents that `context: fork` means ISOLATED (blank) context, not inherited context. Important for understanding isolation behavior.

### Tertiary (LOW confidence)
- None -- all findings verified against primary or secondary sources

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- Claude Code subagent system is well-documented with clear official docs, verified frontmatter fields, and the project already has 11 agent files as precedent
- Architecture: HIGH -- Agent files + skill shims pattern is directly supported by official docs (bidirectional skills/agents relationship). `skills` preloading, `memory: project`, and `context: fork` + `agent:` are all documented features.
- Context isolation: HIGH -- Official docs explicitly state subagents run in their own context window. `context: fork` creates blank (not inherited) context, confirmed by issue #20492.
- Memory system: MEDIUM -- `memory: project` is documented but STATE.md explicitly flags it as "needs practical testing during Phase 33". The feature exists; real-world behavior needs validation.
- Pitfalls: HIGH -- Drawn from official docs, community issues (#20492 naming confusion), and established project patterns from Phases 29-32.

**Research date:** 2026-02-18
**Valid until:** 2026-03-18 (30 days -- agent system is stable, well-documented)
