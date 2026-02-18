---
name: foremost
description: File carving and forensic data recovery using foremost wrapper scripts
disable-model-invocation: true
---

# Foremost File Carver

Run foremost wrapper scripts for recovering deleted files, carving specific file types, and analyzing forensic disk images.

## Available Scripts

### File Recovery

- `bash scripts/foremost/recover-deleted-files.sh [disk-image] [-j] [-x]` -- Recover deleted files from disk images using header/footer signatures

### Targeted Carving

- `bash scripts/foremost/carve-specific-filetypes.sh [disk-image] [-j] [-x]` -- Carve specific file types (jpg, pdf, doc, zip) from disk images

### Forensic Analysis

- `bash scripts/foremost/analyze-forensic-image.sh [evidence-image] [-j] [-x]` -- Analyze forensic evidence images for recoverable artifacts

### Learning Mode

- `bash scripts/foremost/examples.sh [disk-image]` -- View 10 common foremost patterns with explanations

## Flags

All use-case scripts support these flags:

- `-j` / `--json` -- Output structured JSON envelope (enables PostToolUse hook summary)
- `-x` / `--execute` -- Execute commands instead of displaying them
- `--help` -- Show detailed usage, description, and examples for the script

Add `-j` to every invocation so Claude receives a parsed summary via the PostToolUse hook.
Without `-j`, Claude gets raw terminal output instead of structured results.

## Defaults

- Disk image argument is optional (scripts show techniques when omitted)
- Output goes to a timestamped directory by default
- Scripts display commands without running them unless `-x` is passed

## Target Validation

All scripts validate commands via the PreToolUse hook.
If commands are blocked:

1. Run `/netsec-health` to check safety architecture status
2. Foremost operates on local disk images -- no network scope validation required
