---
name: john
description: Password hash cracking and identification using John the Ripper wrapper scripts
disable-model-invocation: true
---

# John the Ripper

Run John the Ripper wrapper scripts for password cracking, hash identification, and educational examples.

## Available Scripts

### Linux Passwords

- `bash scripts/john/crack-linux-passwords.sh [-j] [-x]` -- Crack /etc/shadow hashes using wordlists, rules, and incremental modes

### Archive Cracking

- `bash scripts/john/crack-archive-passwords.sh [archive] [-j] [-x]` -- Crack password-protected ZIP, RAR, 7z, and PDF files

### Hash Identification

- `bash scripts/john/identify-hash-type.sh [hash] [-j] [-x]` -- Identify unknown hash types using john's format detection and hash-identifier

### Learning Mode

- `bash scripts/john/examples.sh` -- View 10 common John the Ripper patterns with explanations

## Flags

All use-case scripts support these flags:

- `-j` / `--json` -- Output structured JSON envelope (enables PostToolUse hook summary)
- `-x` / `--execute` -- Execute commands instead of displaying them
- `--help` -- Show detailed usage, description, and examples for the script

Add `-j` to every invocation so Claude receives a parsed summary via the PostToolUse hook.
Without `-j`, Claude gets raw terminal output instead of structured results.

## Defaults

- Arguments vary by script (archive file, hash string, or none for linux-passwords)
- John requires PATH setup (scripts handle via setup_john_path internally)
- Scripts display commands without running them unless `-x` is passed

## Target Validation

All scripts validate commands via the PreToolUse hook.
If commands are blocked:

1. Run `/netsec-health` to check safety architecture status
2. John operates on local files -- no network scope validation required
