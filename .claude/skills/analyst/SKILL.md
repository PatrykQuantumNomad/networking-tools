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
