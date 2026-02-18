---
name: hashcat
description: GPU-accelerated password hash cracking using hashcat wrapper scripts
disable-model-invocation: true
---

# Hashcat Password Cracker

Run hashcat wrapper scripts for GPU-accelerated hash cracking with educational examples and structured JSON output.

## Available Scripts

### GPU Performance

- `bash scripts/hashcat/benchmark-gpu.sh [-j] [-x]` -- Benchmark GPU hash cracking speed across common hash types (MD5, SHA-256, NTLM, bcrypt)

### NTLM Cracking

- `bash scripts/hashcat/crack-ntlm-hashes.sh [hashfile] [-j] [-x]` -- Crack Windows NTLM hashes using dictionary, brute force, and rule-based attacks

### Web Hash Cracking

- `bash scripts/hashcat/crack-web-hashes.sh [hashfile] [-j] [-x]` -- Crack MD5, SHA-256, bcrypt, WordPress, Django, and MySQL hashes

### Learning Mode

- `bash scripts/hashcat/examples.sh` -- View 10 common hashcat patterns with explanations

## Flags

All use-case scripts support these flags:

- `-j` / `--json` -- Output structured JSON envelope (enables PostToolUse hook summary)
- `-x` / `--execute` -- Execute commands instead of displaying them
- `--help` -- Show detailed usage, description, and examples for the script

Add `-j` to every invocation so Claude receives a parsed summary via the PostToolUse hook.
Without `-j`, Claude gets raw terminal output instead of structured results.

## Defaults

- Hash file argument is optional (scripts show techniques without a file when omitted)
- Benchmark runs against common hash types (MD5, SHA-256, NTLM, bcrypt)
- Scripts display commands without running them unless `-x` is passed

## Target Validation

All scripts validate commands via the PreToolUse hook.
If commands are blocked:

1. Run `/netsec-health` to check safety architecture status
2. Hashcat operates on local files -- no network scope validation required
