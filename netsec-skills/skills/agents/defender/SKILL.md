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
