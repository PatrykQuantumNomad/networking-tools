# Phase 37: Standalone Workflow Skills - Research

**Researched:** 2026-03-06
**Domain:** Claude Code workflow skills, multi-tool orchestration, dual-mode branching at step level
**Confidence:** HIGH

## Summary

Phase 37 transforms 6 workflow skills (recon, scan, fuzz, crack, sniff, diagnose) from wrapper-script-only multi-step orchestrations into dual-mode workflows that work both standalone and in-repo. Currently, every workflow step is a bare `bash scripts/<tool>/<script>.sh $ARGUMENTS -j -x` call. Outside the repo, these workflows are completely non-functional because the wrapper scripts do not exist.

The key challenge is different from Phase 36's tool skills. Tool skills needed inline knowledge for a single tool. Workflow skills need inline knowledge for multiple tools across multiple steps, plus coherent step-by-step sequencing with decision points. The dual-mode branching must happen PER STEP, not once per skill. Each step needs: (1) a wrapper-script path for in-repo mode, (2) direct tool commands for standalone mode, and (3) educational context explaining why this step matters in the workflow sequence.

A critical structural finding is that workflow skills currently reference wrapper scripts UNCONDITIONALLY -- there is no `!`test -f`` detection like tool skills have. The transformation must add per-step dual-mode branching. Additionally, the diagnose workflow is unique: steps 1-3 use diagnostic auto-report scripts (`scripts/diagnostics/*.sh`) that are NOT wrapped by any tool skill and do NOT support `-j -x` flags. In standalone mode, these must be replaced with raw dig/ping/curl commands since the diagnostic scripts will not exist.

The plugin directory currently has symlinks (`netsec-skills/skills/workflows/<name> -> ../../../.claude/skills/<name>`) that must be replaced with real file copies, following the same pattern as Phase 36-03 for tool skills.

**Primary recommendation:** Add dual-mode branching per workflow step using `!`test -f`` detection for the first wrapper script in each workflow, then provide inline direct commands as the standalone fallback for each step. Keep workflow structure (step numbering, decision points, summary format) identical between modes.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| WORK-01 | User can use any of 6 workflow skills without wrapper scripts | Each workflow step gets standalone direct commands matching the tool commands documented in the Phase 36 dual-mode tool skills; no wrapper script dependency |
| WORK-02 | Workflow skills reference standalone tool skills with dual-mode branching at each step | Per-step `!`test -f`` detection branches between wrapper script invocation and direct tool commands; maintains coherent multi-step sequencing in both modes |
</phase_requirements>

## Standard Stack

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| Claude Code SKILL.md | Agent Skills spec | Workflow skill definition format | Same format as tool skills; workflows just have multi-step body content |
| `!`test -f`` dynamic injection | Claude Code skills | Per-workflow wrapper script detection | Single detection point determines mode for entire workflow |
| POSIX bash commands | POSIX | Standalone tool commands (nmap, dig, curl, tshark, etc.) | Direct tool invocations require no project infrastructure |

### Supporting
| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| BATS 1.x | installed at tests/bats/ | Structural validation of workflow skills | Verify dual-mode sections, step counts, command references |
| `scripts/validate-plugin-boundary.sh` | project script | Plugin boundary validation | After replacing workflow symlinks with real files |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Per-step dual-mode branching in SKILL.md | Reference tool skills by `/trigger` name | Would require model invocation, adding context overhead; `disable-model-invocation: true` means tool skills would NOT auto-load for standalone users |
| Single detection per workflow | Per-step `!`test -f`` for each script | Single detection is simpler; if one wrapper script exists, all likely do. Per-step would add ~6 dynamic injections per workflow (wasteful) |
| Inline standalone commands in workflow | Linking to tool skill files | Workflows need self-contained guidance; users should not have to cross-reference 5 different tool skills while following a workflow |

## Architecture Patterns

### Recommended Skill Structure
```
netsec-skills/skills/workflows/
  recon/SKILL.md         # 6-step recon workflow with dual-mode
  scan/SKILL.md          # 5-step vulnerability scanning workflow
  fuzz/SKILL.md          # 3-step web fuzzing workflow
  crack/SKILL.md         # 5-step password cracking workflow
  sniff/SKILL.md         # 3-step traffic analysis workflow
  diagnose/SKILL.md      # 5-step network diagnostics workflow
```

Each workflow SKILL.md is a self-contained file. No supporting files needed.

### Pattern 1: Dual-Mode Workflow Skill Template
**What:** A workflow SKILL.md that detects wrapper script availability ONCE and uses that to branch each step between wrapper and standalone commands.
**When to use:** All 6 workflow skills.
**Example:**
```markdown
---
name: recon
description: >-
  Run reconnaissance workflow -- host discovery, DNS enumeration, and OSINT gathering
argument-hint: "<target>"
disable-model-invocation: true
---

# Reconnaissance Workflow

Run comprehensive reconnaissance against the target.

## Target

Target: $ARGUMENTS

If no target was provided, ask the user for a target before proceeding.
Verify the target is in `.pentest/scope.json` (run `cat .pentest/scope.json` to check).
If not in scope, ask the user to add it with `/scope add <target>`.

## Environment Detection

- Wrapper scripts available: !`test -f scripts/nmap/discover-live-hosts.sh && echo "YES" || echo "NO"`

## Steps

### 1. Host Discovery

Discover active hosts on the target network. ARP scans are fastest on local networks;
TCP SYN/ACK probes work across subnets and through some firewalls.

**If wrapper scripts are available (YES above):**
```
bash scripts/nmap/discover-live-hosts.sh $ARGUMENTS -j -x
```

**If standalone (NO above), use direct nmap commands:**
- `nmap -sn $ARGUMENTS/24` -- Ping sweep to find live hosts
- `nmap -PS22,80,443 $ARGUMENTS/24` -- TCP SYN discovery on common ports
- `nmap -sn -PR $ARGUMENTS/24` -- ARP scan (local network only, fastest)

Review the results. If multiple hosts are found, note them for subsequent steps.

### 2. Port Scanning
[... same per-step dual-mode pattern ...]
```

### Pattern 2: Per-Step Dual-Mode Branching
**What:** Each workflow step provides BOTH the wrapper script command AND the standalone direct commands, clearly labeled so Claude picks the right path based on the environment detection result.
**When to use:** Every step in every workflow.
**Key insight:** The environment detection runs ONCE at the top of the skill via `!`test -f``. Claude then sees "YES" or "NO" as plain text and follows the appropriate branch for every step. No additional detection per step is needed.

### Pattern 3: Diagnose Workflow Special Handling
**What:** The diagnose workflow steps 1-3 reference `scripts/diagnostics/*.sh` (auto-report scripts) which are NOT standard wrapper scripts. They do not support `-j -x`, and there are no corresponding tool skills for them.
**When to use:** Only the diagnose workflow.
**How it works:**
- In-repo mode: Steps 1-3 use `bash scripts/diagnostics/dns.sh $ARGUMENTS` (no -j -x flags, text output)
- Standalone mode: Steps 1-3 use raw dig, ping, curl, traceroute commands that replicate the diagnostic checks
- Steps 4-5 use standard wrapper scripts (traceroute, dig) that DO have dual-mode tool skills

**Example for diagnose Step 1 (DNS Diagnostics) standalone:**
```markdown
**If standalone (NO above), run these DNS diagnostic checks manually:**
- `dig $ARGUMENTS A +noall +answer` -- A record resolution
- `dig $ARGUMENTS AAAA +noall +answer` -- IPv6 resolution
- `dig $ARGUMENTS MX +noall +answer` -- Mail exchange records
- `dig $ARGUMENTS NS +noall +answer` -- Authoritative nameservers
- `dig @8.8.8.8 $ARGUMENTS A +short` -- Google DNS propagation
- `dig @1.1.1.1 $ARGUMENTS A +short` -- Cloudflare DNS propagation
- `dig -x $(dig $ARGUMENTS A +short) +short` -- Reverse DNS lookup

Report findings as PASS/FAIL for each check.
```

### Pattern 4: Coherent End-to-End Results
**What:** Workflow summaries and "After Each Step" sections must be mode-agnostic -- they describe what to look for in the results regardless of whether wrapper scripts or direct commands were used.
**When to use:** All 6 workflows.
**Key insight:** The Summary section and decision guidance remain IDENTICAL between modes. Only the command invocations change. The step numbering, decision points, and summary format are the same in both paths.

### Anti-Patterns to Avoid

- **Making standalone workflow steps just "run the tool":** Each standalone step must provide the SPECIFIC commands that replicate what the wrapper script does, not just generic tool usage. Use the Phase 36 tool skill inline knowledge as the source.
- **Adding per-step `!`test -f`` detection:** One detection at the top is sufficient. All wrapper scripts live together -- if one exists, they all exist. Multiple detections waste dynamic injection processing.
- **Stripping decision guidance from standalone mode:** The crack workflow has hash-type-based routing (Steps 2-5 are conditional). This decision logic must remain in standalone mode.
- **Referencing PostToolUse hook output in standalone mode:** Standalone users may not have the PostToolUse hook. The "After Each Step" guidance should say "Review the output" rather than "Review the JSON output summary from the PostToolUse hook."
- **Bundling diagnostic scripts in the skill:** The diagnose workflow's `scripts/diagnostics/*.sh` are 8-12KB auto-report scripts. Bundling them defeats the standalone purpose. Replace with raw commands.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Standalone command knowledge per tool | Writing new tool commands from scratch | Copy from Phase 36 dual-mode tool skills (Standalone sections) | Already verified, consistent with tool skills |
| Wrapper script detection | Per-step detection scripts | Single `!`test -f scripts/<tool>/<script>.sh`` at workflow top | One detection point, Claude branches on text |
| Diagnostic standalone commands | Reimplementing dns.sh/connectivity.sh/performance.sh logic | Raw dig/ping/curl commands covering the same checks | Auto-report scripts are complex; raw commands cover the key checks |
| Description keyword optimization | Guessing keywords | Keep existing workflow descriptions (already action-verb oriented) | Workflow descriptions were written in v1.5 with good keywords |

**Key insight:** The Phase 36 dual-mode tool skills already contain all the standalone command knowledge needed. Each workflow step's standalone commands should be drawn from the corresponding tool skill's "Mode: Standalone" section.

## Common Pitfalls

### Pitfall 1: Workflow Skills Exceeding 500-Line Limit
**What goes wrong:** Adding inline commands for every step makes workflow skills too long, especially recon (6 steps x 3-5 commands each) and diagnose (5 steps with diagnostic script replacement).
**Why it happens:** Each step gets 3-8 standalone commands plus educational context plus wrapper script reference.
**How to avoid:** Keep standalone commands to 3-5 per step (the most essential ones). The tool skills have comprehensive coverage; workflow standalone needs only the PRIMARY commands for each step's purpose. Estimated size: recon ~180 lines, scan ~160 lines, fuzz ~120 lines, crack ~180 lines, sniff ~130 lines, diagnose ~200 lines. All well under 500.
**Warning signs:** SKILL.md exceeds 300 lines -- review for redundancy.

### Pitfall 2: Standalone Mode Missing Decision Logic
**What goes wrong:** The crack workflow has hash-type-based routing -- Steps 2-5 are conditional. If standalone mode only lists commands without the decision table, users run the wrong cracking tool.
**Why it happens:** Decision logic is easy to lose when rewriting steps.
**How to avoid:** Copy the "Decision Guidance" section verbatim into the standalone workflow. It is mode-agnostic (tells you WHICH step to run based on hash type, regardless of wrapper vs direct commands).
**Warning signs:** Standalone crack workflow has no hash-type routing table.

### Pitfall 3: Diagnose Workflow Diagnostic Script Detection
**What goes wrong:** The diagnose workflow references `scripts/diagnostics/dns.sh` (steps 1-3) and `scripts/traceroute/trace-network-path.sh` (step 4) and `scripts/dig/check-dns-propagation.sh` (step 5). The detection must check for diagnostic scripts separately because they are a different kind of script from tool wrappers.
**Why it happens:** `scripts/diagnostics/` scripts are Pattern B (auto-report, no -j -x) while `scripts/traceroute/` and `scripts/dig/` are Pattern A (wrapper scripts with -j -x). A single `test -f scripts/nmap/discover-live-hosts.sh` detection does not tell you if `scripts/diagnostics/dns.sh` exists.
**How to avoid:** For diagnose workflow specifically, use `test -f scripts/diagnostics/dns.sh` as the detection check (since diagnostics scripts are the unique ones -- if they exist, the standard tool wrappers certainly exist too). All other workflows can detect on any one of their wrapper scripts.
**Warning signs:** Diagnose workflow shows wrapper mode but diagnostic scripts are missing.

### Pitfall 4: PostToolUse Hook References in Standalone Mode
**What goes wrong:** Current workflows say "Review the JSON output summary from the PostToolUse hook" after each step. Standalone users don't have the hook.
**Why it happens:** Copy-pasting the "After Each Step" section without adapting for standalone mode.
**How to avoid:** Make "After Each Step" mode-aware: in wrapper mode, reference the PostToolUse hook summary. In standalone mode, say "Review the command output directly." Or better: make the section generic ("Review the results") so it works in both modes.
**Warning signs:** Standalone workflow mentions "PostToolUse hook" or "JSON output summary."

### Pitfall 5: Symlink Replacement Breaking Plugin Structure
**What goes wrong:** Running `rm netsec-skills/skills/workflows/recon` removes the symlink, but `mkdir -p netsec-skills/skills/workflows/recon` might fail if the parent directory has issues.
**Why it happens:** macOS handles symlink-to-directory removal differently than Linux.
**How to avoid:** Use `rm -f` for the symlink, then `mkdir -p` for the directory. This is the same pattern that worked in Phase 36-03. Verify with `file netsec-skills/skills/workflows/*/SKILL.md` to confirm real files.
**Warning signs:** `file` command shows "symbolic link" after replacement.

### Pitfall 6: Inconsistent $ARGUMENTS Usage Between Modes
**What goes wrong:** Wrapper mode uses `$ARGUMENTS` (Claude Code variable substitution). Standalone mode direct commands use `$ARGUMENTS` or `<target>` interchangeably, confusing Claude about how to substitute.
**Why it happens:** Tool skill standalone sections use `<target>` as a placeholder, but workflow skills use `$ARGUMENTS`.
**How to avoid:** Use `$ARGUMENTS` consistently throughout the workflow skill in BOTH modes. Claude Code substitutes `$ARGUMENTS` with the user's input before the skill content is processed.
**Warning signs:** Mix of `$ARGUMENTS` and `<target>` in the same workflow.

## Code Examples

Verified patterns from the project codebase:

### Workflow Dual-Mode Detection (Single Point)
```markdown
## Environment Detection

- Wrapper scripts available: !`test -f scripts/nmap/discover-live-hosts.sh && echo "YES" || echo "NO"`
```
Source: Extension of tool skill pattern from Phase 36 RESEARCH.md Pattern 3

### Per-Step Dual-Mode Branching
```markdown
### 1. Host Discovery

Discover active hosts on the target network. ARP scans are fastest on local
networks; TCP SYN/ACK probes work across subnets and through some firewalls.

**If wrapper scripts are available (YES above):**

```
bash scripts/nmap/discover-live-hosts.sh $ARGUMENTS -j -x
```

**If standalone (NO above), use direct nmap commands:**

- `nmap -sn $ARGUMENTS/24` -- Ping sweep to find live hosts
- `nmap -PS22,80,443 $ARGUMENTS/24` -- TCP SYN discovery on common ports
- `nmap -sn -PR $ARGUMENTS/24` -- ARP scan (local network only, fastest)

Review the results. If multiple hosts are found, note them for subsequent steps.
```
Source: Combining recon SKILL.md step structure with nmap tool skill standalone commands

### Diagnose Workflow Diagnostic Replacement (Standalone)
```markdown
### 1. DNS Diagnostics

Run DNS diagnostic checks to verify resolution, record types, and propagation.

**If wrapper scripts are available (YES above):**

```
bash scripts/diagnostics/dns.sh $ARGUMENTS
```

Do NOT add `-j` or `-x` to this command. Read the pass/fail/warn output directly.

**If standalone (NO above), run these DNS checks manually:**

- `dig $ARGUMENTS A +noall +answer` -- Check A record resolution (PASS if answer returned)
- `dig $ARGUMENTS AAAA +noall +answer` -- Check IPv6 resolution
- `dig $ARGUMENTS MX +noall +answer` -- Check mail exchange records
- `dig $ARGUMENTS NS +noall +answer` -- Check authoritative nameservers
- `dig $ARGUMENTS TXT +noall +answer` -- Check TXT records (SPF, DKIM)
- `dig @8.8.8.8 $ARGUMENTS A +short` -- Google DNS propagation check
- `dig @1.1.1.1 $ARGUMENTS A +short` -- Cloudflare DNS propagation check
- `dig -x $(dig $ARGUMENTS A +short | head -1) +short` -- Reverse DNS lookup

Note any failures. Compare results across resolvers for propagation issues.
```
Source: Derived from scripts/diagnostics/dns.sh check sequence and dig tool skill standalone commands

### Mode-Agnostic Summary Section
```markdown
## Summary

After all steps complete, provide a structured reconnaissance summary:

- **Hosts**: Active hosts discovered and their status
- **Ports/Services**: Open ports and identified services with versions
- **DNS**: Records, nameservers, zone transfer results (success/fail)
- **TLS**: Certificate details, issuer, expiry, SANs
- **Subdomains**: Enumerated subdomains (if gobuster was run)
```
Source: Existing recon SKILL.md -- kept verbatim as it is already mode-agnostic

## Workflow-to-Tool Mapping (Complete Reference)

Each workflow step maps to a specific tool skill's standalone commands. This table is the definitive reference for building standalone workflow steps:

### recon (6 steps)
| Step | Wrapper Script | Tool Skill Source | Key Standalone Commands |
|------|---------------|-------------------|------------------------|
| 1. Host Discovery | nmap/discover-live-hosts.sh | nmap (Host Discovery) | `nmap -sn`, `-PS22,80,443`, `-sn -PR` |
| 2. Port Scanning | nmap/identify-ports.sh | nmap (Port Scanning) | `nmap -sS`, `-sV`, `-p-`, `-A` |
| 3. DNS Records | dig/query-dns-records.sh | dig (DNS Records) | `dig A`, `MX`, `NS`, `TXT`, `SOA` |
| 4. Zone Transfer | dig/attempt-zone-transfer.sh | dig (Zone Transfers) | `dig NS +short`, `dig axfr @ns` |
| 5. SSL/TLS | curl/check-ssl-certificate.sh | curl (SSL/TLS Inspection) | `curl -vI https://`, TLS version tests |
| 6. Subdomains | gobuster/enumerate-subdomains.sh | gobuster (Subdomain Enumeration) | `gobuster dns -d`, `-w subdomains.txt` |

### scan (5 steps)
| Step | Wrapper Script | Tool Skill Source | Key Standalone Commands |
|------|---------------|-------------------|------------------------|
| 1. Port Scan | nmap/identify-ports.sh | nmap (Port Scanning) | `nmap -sS -sV`, `-p-` |
| 2. Web Vuln (NSE) | nmap/scan-web-vulnerabilities.sh | nmap (NSE Scripts) | `nmap --script=http-vuln-*`, `ssl-enum-ciphers` |
| 3. Web Server | nikto/scan-specific-vulnerabilities.sh | nikto (Basic + Tuning) | `nikto -h`, `-Tuning 123` |
| 4. SQL Injection | sqlmap/test-all-parameters.sh | sqlmap (Basic Testing) | `sqlmap -u --batch`, `--level=5 --risk=3` |
| 5. HTTP Endpoints | curl/test-http-endpoints.sh | curl (Endpoint Testing) | `curl -I`, `-X OPTIONS`, status code checks |

### fuzz (3 steps)
| Step | Wrapper Script | Tool Skill Source | Key Standalone Commands |
|------|---------------|-------------------|------------------------|
| 1. Directory Discovery | gobuster/discover-directories.sh | gobuster (Directory Discovery) | `gobuster dir -u`, `-w wordlist.txt`, `-x php,html` |
| 2. Parameter Fuzzing | ffuf/fuzz-parameters.sh | ffuf (Parameter Fuzzing) | `ffuf -u "?FUZZ=test"`, `-w params.txt` |
| 3. Web Vuln Scan | nikto/scan-specific-vulnerabilities.sh | nikto (Basic + Tuning) | `nikto -h`, `-Tuning 123` |

### crack (5 steps)
| Step | Wrapper Script | Tool Skill Source | Key Standalone Commands |
|------|---------------|-------------------|------------------------|
| 1. Hash ID | john/identify-hash-type.sh | john (Hash Identification) | `john --list=formats \| grep`, format detection |
| 2. NTLM | hashcat/crack-ntlm-hashes.sh | hashcat (Dictionary Attacks) | `hashcat -m 1000 -a 0`, mask attacks |
| 3. Web Hashes | hashcat/crack-web-hashes.sh | hashcat (Dictionary Attacks) | `hashcat -m 0/100/1400/3200 -a 0` |
| 4. Linux | john/crack-linux-passwords.sh | john (Linux Passwords) | `unshadow`, `john --wordlist=`, `--rules` |
| 5. Archives | john/crack-archive-passwords.sh | john (Archive Cracking) | `zip2john`, `john --wordlist=` |

### sniff (3 steps)
| Step | Wrapper Script | Tool Skill Source | Key Standalone Commands |
|------|---------------|-------------------|------------------------|
| 1. HTTP Credentials | tshark/capture-http-credentials.sh | tshark (Credential Extraction) | `tshark -Y "http.request.method==POST"`, auth headers |
| 2. DNS Analysis | tshark/analyze-dns-queries.sh | tshark (Display Filters) | `tshark -Y "dns" -T fields -e dns.qry.name` |
| 3. File Extraction | tshark/extract-files-from-capture.sh | tshark (File Extraction) | `tshark --export-objects http,dir/` |

### diagnose (5 steps -- SPECIAL)
| Step | Wrapper Script | Tool Skill Source | Key Standalone Commands |
|------|---------------|-------------------|------------------------|
| 1. DNS Diag | diagnostics/dns.sh (NO -j -x) | dig tool skill + raw commands | `dig A`, `NS`, `MX`, propagation checks |
| 2. Connectivity | diagnostics/connectivity.sh (NO -j -x) | curl + ping raw commands | `ping -c 4`, `curl -sI`, TCP port checks |
| 3. Performance | diagnostics/performance.sh (NO -j -x) | ping + curl raw commands | `ping -c 10` (stats), curl timing |
| 4. Path Tracing | traceroute/trace-network-path.sh | traceroute tool skill | `traceroute`, `mtr --report` |
| 5. DNS Propagation | dig/check-dns-propagation.sh | dig tool skill | `dig @8.8.8.8`, `@1.1.1.1`, `@208.67.222.222` |

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Workflow skills as wrapper-script-only | Dual-mode workflows with inline standalone commands | Phase 37 (now) | Workflows work outside the repo |
| Single-mode steps (wrapper only) | Per-step dual-mode branching | Phase 37 (now) | Each step works in both modes |
| Workflow symlinks in plugin | Real file copies | Phase 37 (applying Phase 36-03 pattern) | Portable plugin distribution |

**Deprecated/outdated:**
- Unconditional wrapper script references in workflow steps: Must be replaced with conditional dual-mode branching
- "Review the JSON output summary from the PostToolUse hook" in After Each Step: Must be made mode-aware or generic
- Symlinks in `netsec-skills/skills/workflows/`: Must be replaced with real files

## Open Questions

1. **Workflow description updates needed?**
   - What we know: Current workflow descriptions in marketplace.json are already action-verb oriented and do not mention "wrapper scripts"
   - What's unclear: Whether descriptions should be updated to mention "standalone" capability
   - Recommendation: Keep existing descriptions unchanged. They already describe the WHAT (what the workflow does) not the HOW (wrapper vs standalone). Adding "standalone" would be implementation detail that users don't care about.

2. **Should in-repo workflow skills also be updated to dual-mode?**
   - What we know: Phase 36 updated BOTH in-repo and plugin tool skills identically. The BATS sync test expects them to be identical.
   - What's unclear: Whether there's a reason to keep in-repo workflows wrapper-only
   - Recommendation: YES -- update both in-repo (`.claude/skills/<workflow>/SKILL.md`) and plugin (`netsec-skills/skills/workflows/<workflow>/SKILL.md`) to be identical dual-mode skills. This follows the Phase 36 precedent and keeps the BATS sync test pattern.

3. **Detection script for diagnose workflow**
   - What we know: The diagnose workflow uses `scripts/diagnostics/dns.sh` (steps 1-3) which are NOT tool wrapper scripts. The tool wrappers `scripts/traceroute/trace-network-path.sh` and `scripts/dig/check-dns-propagation.sh` (steps 4-5) do exist as tool wrappers.
   - What's unclear: Should detection check for diagnostic scripts or tool wrappers?
   - Recommendation: Use `test -f scripts/diagnostics/dns.sh` for diagnose detection. If diagnostic scripts exist, the repo is present and all scripts exist. If they do not exist, fall back to standalone for ALL steps (including steps 4-5 that use tool wrappers, since if diagnostics are missing, we are outside the repo). This keeps it simple: one detection, one branch.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | BATS 1.x (installed at tests/bats/) |
| Config file | None -- BATS uses direct invocation |
| Quick run command | `./tests/bats/bin/bats tests/test-workflow-skills.bats --timing` |
| Full suite command | `./tests/bats/bin/bats tests/ --timing` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| WORK-01 | Each workflow has standalone commands at every step | smoke | Verify SKILL.md contains standalone command blocks per step for each of 6 workflows | No -- Wave 0 |
| WORK-01 | Standalone commands reference direct tool commands (not wrapper scripts) | unit | Grep standalone sections for `nmap`, `dig`, `tshark` commands without `scripts/` prefix | No -- Wave 0 |
| WORK-02 | Each workflow has dual-mode branching with wrapper script references | smoke | Verify SKILL.md contains "wrapper scripts" branching and `scripts/` references for each workflow | No -- Wave 0 |
| WORK-02 | Environment Detection section exists with `!`test -f`` injection | unit | Grep for `test -f scripts/` dynamic injection in each workflow SKILL.md | No -- Wave 0 |
| ALL | Plugin and in-repo workflow skills are identical | unit | `diff` between `.claude/skills/<workflow>/SKILL.md` and `netsec-skills/skills/workflows/<workflow>/SKILL.md` | No -- Wave 0 |
| ALL | Workflow descriptions do not reference "wrapper scripts" | unit | Grep description frontmatter for "wrapper scripts" (should be absent) | No -- Wave 0 |

### Sampling Rate
- **Per task commit:** `./tests/bats/bin/bats tests/test-workflow-skills.bats --timing`
- **Per wave merge:** `./tests/bats/bin/bats tests/ --timing`
- **Phase gate:** Full suite green + manual smoke: invoke `/recon` outside repo, verify standalone commands appear

### Wave 0 Gaps
- [ ] `tests/test-workflow-skills.bats` -- covers WORK-01 and WORK-02 (SKILL.md structural validation for all 6 workflows)
- [ ] Manual smoke test: invoke a workflow skill outside the repo directory to confirm standalone commands render correctly

## Recommended Plan Structure

Based on the scope analysis, this phase should have 2-3 plans:

### Plan 1: BATS test scaffold + pilot dual-mode transformation (recon + crack)
- Create `tests/test-workflow-skills.bats` with structural tests for all 6 workflows
- Transform recon workflow (6 steps, most complex, uses 4 different tools -- nmap, dig, curl, gobuster)
- Transform crack workflow (5 steps, has conditional decision logic -- unique complexity)
- These two cover the hardest cases: multi-tool orchestration and conditional step routing
- Update in-repo skills, copy to plugin as real files (replace symlinks for these 2)
- Run BATS tests to validate pattern

### Plan 2: Scale to remaining 4 workflows + plugin sync
- Transform scan (5 steps), fuzz (3 steps), sniff (3 steps), diagnose (5 steps)
- diagnose is the special case (diagnostic script replacement in standalone mode)
- Replace remaining 4 symlinks with real files
- Update marketplace.json if description changes needed (likely not)
- Run full BATS suite including existing tests for zero regressions
- Run plugin boundary validation

## Sources

### Primary (HIGH confidence)
- Project codebase: All 6 workflow skills in `.claude/skills/` -- current structure, step counts, wrapper script references, summary formats
- Project codebase: All 17 dual-mode tool skills in `.claude/skills/` and `netsec-skills/skills/tools/` -- standalone command knowledge per tool (source of truth for workflow standalone commands)
- Project codebase: `scripts/diagnostics/*.sh` -- auto-report scripts used by diagnose workflow (Pattern B, no -j -x)
- Phase 36 RESEARCH.md -- dual-mode pattern, `!`test -f`` detection, description optimization, pilot-first approach
- Phase 36 plans (36-01 through 36-03) -- execution patterns for BATS scaffolding, skill transformation, symlink replacement

### Secondary (MEDIUM confidence)
- Claude Code Skills docs -- `!`command`` dynamic injection, $ARGUMENTS substitution, disable-model-invocation behavior
- Agent Skills spec -- 500-line recommendation, description field requirements

### Tertiary (LOW confidence)
- None -- all findings are based on project codebase analysis and Phase 36 verified patterns

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- Same SKILL.md format as Phase 36 tool skills; no new tools or patterns
- Architecture: HIGH -- Dual-mode pattern proven in Phase 36; workflow adaptation is structural, not novel
- Pitfalls: HIGH -- Most pitfalls identified from analyzing the 6 existing workflow skills against Phase 36 patterns
- Standalone commands: HIGH -- All standalone commands come from already-verified Phase 36 tool skill content
- Diagnose special case: MEDIUM -- Raw commands replacing diagnostic scripts need manual verification to ensure coverage parity

**Research date:** 2026-03-06
**Valid until:** 2026-04-06 (stable domain -- workflow skills are content, not API-dependent)
