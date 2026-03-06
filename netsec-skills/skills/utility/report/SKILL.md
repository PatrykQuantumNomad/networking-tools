---
name: report
description: Generate a structured pentesting findings report from the current session
argument-hint: "[title]"
disable-model-invocation: true
---

# Findings Report

Generate a structured report of all pentesting findings from this session.

## Report Title

Title: $ARGUMENTS

If no title provided, use 'Pentesting Findings Report' with today's date.

## Instructions

Synthesize all findings from the current conversation into a structured markdown report. Do NOT read audit log files -- use the results and summaries from this session's tool outputs.

Review all tool outputs, PostToolUse hook summaries, and findings mentioned in this conversation. Organize everything by severity. If no findings exist for a severity level, include the section header with "None identified."

## Report Structure

Use this exact template:

```markdown
# [Title]
**Date:** [today's date]
**Scope:** [targets from .pentest/scope.json]
**Tools Used:** [list tools run in this session]

## Executive Summary
[2-3 sentence overview of key findings and risk level]

## Scope & Methodology
- Target(s) tested
- Tools and techniques used
- Testing approach

## Findings
### Critical
### High
### Medium
### Low / Informational

## Recommendations
[Prioritized actions]

## Appendix
[Raw data references, tool versions, timestamps]
```

For each finding, include:
- **Finding name** -- short descriptive title
- **Severity** -- Critical / High / Medium / Low / Informational
- **Description** -- what was found and why it matters
- **Evidence** -- relevant tool output or command result
- **Recommendation** -- specific remediation step

## Output

Write the report to `report-YYYY-MM-DD.md` in the project root, replacing YYYY-MM-DD with today's actual date.

Also display a brief summary inline in the conversation showing:
- Number of findings by severity
- Top 3 most critical findings
- Path to the saved report file
