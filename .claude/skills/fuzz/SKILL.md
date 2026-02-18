---
name: fuzz
description: Run fuzzing workflow -- directory brute-force, parameter fuzzing, and web scanning
argument-hint: "<target-url>"
disable-model-invocation: true
---

# Fuzzing Workflow

Run web fuzzing and enumeration against the target URL.

## Target

Target: $ARGUMENTS

Fuzzing targets are typically URLs (e.g., http://localhost:8080). If no target was provided, ask the user for a target URL. Verify the host portion is in `.pentest/scope.json` (run `cat .pentest/scope.json` to check). If not in scope, ask the user to add it with `/scope add <target>`.

## Steps

### 1. Directory Discovery

Brute-force discover hidden directories and files on the web server:

```
bash scripts/gobuster/discover-directories.sh $ARGUMENTS -j -x
```

Review the results. Note all discovered paths, status codes, and content lengths. Hidden admin panels, backup files, and configuration endpoints are high-value findings.

### 2. Parameter Fuzzing

Fuzz URL parameters, headers, and request bodies for hidden inputs:

```
bash scripts/ffuf/fuzz-parameters.sh $ARGUMENTS -j -x
```

Look for parameters that trigger different responses -- these may indicate injection points, hidden functionality, or access control bypasses.

### 3. Web Vulnerability Scan

Scan for known web server vulnerabilities, misconfigurations, and dangerous files:

```
bash scripts/nikto/scan-specific-vulnerabilities.sh $ARGUMENTS -j -x
```

Nikto covers a broad range of checks including outdated software, default credentials, dangerous HTTP methods, and sensitive file exposure.

## After Each Step

- Review the JSON output summary from the PostToolUse hook
- Note discovered paths, parameters, and vulnerabilities
- If a tool is not installed, skip that step and note it in the summary
- Adapt subsequent steps based on findings (e.g., fuzz newly discovered paths in Step 2)
- If Step 1 reveals an admin panel, prioritize it in Step 3

## Summary

After all steps complete, provide a structured fuzzing summary:

- **Discovered Paths**: Hidden directories, files, and admin endpoints found
- **Parameters Found**: URL parameters, headers, or body fields revealing hidden inputs
- **Vulnerabilities**: CVEs, misconfigurations, dangerous files, and outdated components identified
- **Next Steps**: High-priority targets for deeper exploitation based on findings
