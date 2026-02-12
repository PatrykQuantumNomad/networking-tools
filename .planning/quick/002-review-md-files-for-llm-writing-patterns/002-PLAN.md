---
phase: quick-002
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - README.md
  - USECASES.md
  - notes/nmap.md
  - notes/tshark.md
  - notes/sqlmap.md
  - notes/metasploit.md
  - notes/nikto.md
  - notes/hashcat.md
  - notes/john.md
  - notes/hping3.md
  - notes/foremost.md
  - notes/skipfish.md
  - notes/aircrack-ng.md
  - notes/lab-walkthrough.md
autonomous: true
must_haves:
  truths:
    - "No em dashes remain in any user-facing markdown file"
    - "No filler phrases like 'it is worth noting', 'furthermore', 'moreover', 'additionally' remain"
    - "No corporate jargon like 'comprehensive', 'robust', 'leverage', 'utilize' remains"
    - "Opening descriptions are direct and plain-spoken, not salesy"
    - "Technical accuracy and code blocks are unchanged"
  artifacts:
    - path: "README.md"
      provides: "Project README"
    - path: "USECASES.md"
      provides: "Use-case quick reference"
    - path: "notes/nmap.md"
      provides: "Nmap tool notes"
    - path: "notes/tshark.md"
      provides: "TShark tool notes"
    - path: "notes/sqlmap.md"
      provides: "SQLMap tool notes"
    - path: "notes/metasploit.md"
      provides: "Metasploit tool notes"
    - path: "notes/nikto.md"
      provides: "Nikto tool notes"
    - path: "notes/hashcat.md"
      provides: "Hashcat tool notes"
    - path: "notes/john.md"
      provides: "John the Ripper tool notes"
    - path: "notes/hping3.md"
      provides: "hping3 tool notes"
    - path: "notes/foremost.md"
      provides: "Foremost tool notes"
    - path: "notes/skipfish.md"
      provides: "Skipfish tool notes"
    - path: "notes/aircrack-ng.md"
      provides: "Aircrack-ng tool notes"
    - path: "notes/lab-walkthrough.md"
      provides: "Lab walkthrough guide"
  key_links: []
---

<objective>
Review all user-facing markdown files for LLM writing patterns and rewrite affected sections to sound more human, direct, and plain-spoken.

Purpose: The project documentation should read like it was written by a person taking notes for themselves, not like marketing copy or AI-generated content. Fix em dashes, filler phrases, corporate jargon, and overly formal openings.

Output: All 14 user-facing markdown files reviewed and cleaned up where needed.
</objective>

<execution_context>
@./.claude/get-shit-done/workflows/execute-plan.md
@./.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@README.md
@USECASES.md
@notes/nmap.md
@notes/tshark.md
@notes/sqlmap.md
@notes/metasploit.md
@notes/nikto.md
@notes/hashcat.md
@notes/john.md
@notes/hping3.md
@notes/foremost.md
@notes/skipfish.md
@notes/aircrack-ng.md
@notes/lab-walkthrough.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: Fix LLM writing patterns across all user-facing markdown files</name>
  <files>
    README.md
    USECASES.md
    notes/nmap.md
    notes/tshark.md
    notes/sqlmap.md
    notes/metasploit.md
    notes/nikto.md
    notes/hashcat.md
    notes/john.md
    notes/hping3.md
    notes/foremost.md
    notes/skipfish.md
    notes/aircrack-ng.md
    notes/lab-walkthrough.md
  </files>
  <action>
Review each file and fix these specific LLM writing patterns:

**Em dashes (---):** These files already use `--` (double hyphen) not `---` (em dash). Scan for any Unicode em dashes (U+2014: ---) and replace with `--` or rewrite. Most files look clean here.

**Filler/transition words to delete or simplify:**
- "Furthermore", "Moreover", "Additionally" - remove or replace with "Also" / just start the sentence
- "It's worth noting that", "It should be noted" - delete, start with the actual point
- "In order to" - replace with "to"
- "It is important to" - delete or rephrase

**Corporate/marketing jargon to simplify:**
- "comprehensive" -> "full", "complete", or just remove
- "robust" -> "solid", "reliable", or remove
- "leverage" / "leveraging" -> "use" / "using"
- "utilize" / "utilization" -> "use"
- "essential" -> "important" or "key", or remove if the sentence works without it
- "industry-standard" -> just name what it is, or say "widely used"
- "world's fastest" -> drop superlative, say what it does plainly

**Overly formal or salesy openings to rewrite:**
The "What It Does" sections in some notes files read like product descriptions. Rewrite to be plain and direct. Examples of what to fix:

- notes/hashcat.md: "Hashcat is the world's fastest password cracker, leveraging GPU acceleration to test billions of hashes per second." -> "Hashcat cracks passwords using GPU acceleration. It tests billions of hashes per second and supports 350+ hash types..."
- notes/metasploit.md: "Metasploit Framework is the industry-standard penetration testing platform." -> "Metasploit Framework is a penetration testing platform with exploits, payloads, scanners, and post-exploitation modules."
- notes/metasploit.md: "The framework ties together the full attack lifecycle" -> "It covers scanning, exploitation, post-exploitation, and reporting."
- notes/tshark.md: "Essential for packet analysis" -> "Used for packet analysis"
- notes/nikto.md: "typically doubling or tripling the attack surface found" -> "which usually finds a lot more"
- notes/john.md: "John the Ripper is a versatile password cracker" -> "John the Ripper cracks passwords on CPU"
- notes/aircrack-ng.md: "Aircrack-ng is a complete suite for WiFi security auditing" -> "Aircrack-ng is a set of tools for WiFi security testing"

**Repeated list pattern starts:**
Check for lists where every item starts with the same word. Vary the sentence structure if found.

**What NOT to change:**
- Code blocks (anything in backticks or fenced code blocks)
- Command examples
- Table data
- Technical accuracy
- File paths or URLs
- The overall structure and section headings
- The `site/README.md` (Starlight template, not user content)
- Any files under `.planning/`
  </action>
  <verify>
Run these checks after editing:

```bash
# Check for em dashes (Unicode U+2014) in all target files
grep -rn '—' README.md USECASES.md notes/*.md

# Check for common LLM filler words (case-insensitive)
grep -rni 'furthermore\|moreover\|additionally\|it.s worth noting\|comprehensive\|robust\|leverage\|leveraging\|utilize\|utilization\|industry-standard' README.md USECASES.md notes/*.md

# Check for "essential for" pattern
grep -rni 'essential for' README.md USECASES.md notes/*.md

# Verify no code blocks were accidentally modified (spot check)
# Compare line counts to make sure files weren't drastically shortened
wc -l README.md USECASES.md notes/*.md
```

All grep checks should return empty (no matches). Line counts should be similar to originals (within ~5% variation).
  </verify>
  <done>
All 14 user-facing markdown files are free of em dashes, LLM filler phrases, corporate jargon, and overly formal/salesy language. Technical content and code blocks are unchanged. Files read like practical notes written by a person, not AI-generated marketing copy.
  </done>
</task>

</tasks>

<verification>
- No Unicode em dashes in any user-facing markdown
- No instances of: furthermore, moreover, additionally, comprehensive, robust, leverage, utilize, industry-standard, essential for
- Opening "What It Does" sections read plainly and directly
- All code blocks and command examples are byte-identical to originals
- File structure and section headings unchanged
</verification>

<success_criteria>
All 14 files reviewed. LLM writing patterns removed. Technical accuracy preserved. Files sound like they were written by a human taking notes.
</success_criteria>

<output>
After completion, create `.planning/quick/002-review-md-files-for-llm-writing-patterns/002-SUMMARY.md`
</output>
