---
name: ffuf
description: Web fuzzing for parameters, directories, and endpoints using ffuf wrapper scripts
disable-model-invocation: true
---

# Ffuf Web Fuzzer

Run ffuf wrapper scripts for web parameter fuzzing with educational examples and structured JSON output.

## Available Scripts

### Parameter Fuzzing

- `bash scripts/ffuf/fuzz-parameters.sh [target] [wordlist] [-j] [-x]` -- Fuzz URL parameters, headers, and POST data to discover hidden inputs

### Learning Mode

- `bash scripts/ffuf/examples.sh <target>` -- View 10 common ffuf patterns with explanations

## Flags

All use-case scripts support these flags:

- `-j` / `--json` -- Output structured JSON envelope (enables PostToolUse hook summary)
- `-x` / `--execute` -- Execute commands instead of displaying them
- `--help` -- Show detailed usage, description, and examples for the script

Add `-j` to every invocation so Claude receives a parsed summary via the PostToolUse hook.
Without `-j`, Claude gets raw terminal output instead of structured results.

## Defaults

- Target defaults to `http://localhost:8080` (DVWA)
- Second argument is an optional custom wordlist path
- Scripts display commands without running them unless `-x` is passed

## Target Validation

All scripts validate targets against `.pentest/scope.json` via the PreToolUse hook.
If commands are blocked:

1. Run `/netsec-health` to check safety architecture status
2. Verify your target is listed in `.pentest/scope.json`
3. Default safe targets: localhost, 127.0.0.1, lab containers (ports 8080, 3030, 8888, 8180)
