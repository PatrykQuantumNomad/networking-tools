---
name: foremost
description: >-
  Recover deleted files and carve data from disk images with foremost. File
  carving, forensic analysis, header/footer recovery.
disable-model-invocation: true
---

# Foremost File Carver

Recover deleted files and carve data from disk images using foremost.

## Tool Status

- Tool installed: !`command -v foremost > /dev/null 2>&1 && echo "YES -- $(foremost -V 2>&1 | head -1 || echo 'foremost available')" || echo "NO -- Install: brew install foremost (macOS) | apt install foremost (Debian/Ubuntu)"`
- Wrapper scripts available: !`test -f scripts/foremost/recover-deleted-files.sh && echo "YES -- use wrapper scripts for structured JSON output" || echo "NO -- using standalone mode with direct commands"`

## Mode: Wrapper Scripts Available

If wrapper scripts are available (shown as YES above), prefer these commands.
They provide structured JSON output and educational context.

### File Recovery
- `bash scripts/foremost/recover-deleted-files.sh <disk-image> -j -x` -- Recover deleted files from disk images using header/footer signatures

### Targeted Carving
- `bash scripts/foremost/carve-specific-filetypes.sh <disk-image> -j -x` -- Carve specific file types (jpg, pdf, doc, zip) from disk images

### Forensic Analysis
- `bash scripts/foremost/analyze-forensic-image.sh <evidence-image> -j -x` -- Analyze forensic evidence images for recoverable artifacts

### Learning Mode
- `bash scripts/foremost/examples.sh <disk-image>` -- 10 common foremost patterns with explanations

Always add `-j` for JSON output and `-x` to execute (vs display-only).

## Mode: Standalone (Direct Commands)

If wrapper scripts are NOT available, use these direct foremost commands.

### Basic File Recovery

Foremost scans binary data for file headers and footers to reconstruct deleted
files. Works on raw disk images, partitions, and individual files.

- `foremost -i image.dd -o output/` -- Recover all file types from disk image
- `foremost -i /dev/sda1 -o output/` -- Recover from raw partition
- `foremost -i image.dd -o output/ -v` -- Verbose output with detailed progress
- `foremost -i image.dd -o output/ -q` -- Quick mode (skip header-only matches)

### Targeted File Type Carving

Specify file types to recover using -t flag. Reduces scan time and output
noise when you know what you are looking for.

- `foremost -t jpg,png,gif -i image.dd -o output/` -- Recover image files only
- `foremost -t pdf,doc,docx -i image.dd -o output/` -- Recover document files only
- `foremost -t zip,rar -i image.dd -o output/` -- Recover archive files only
- `foremost -t all -i image.dd -o output/` -- Recover all known file types (explicit)
- `foremost -t exe,dll -i image.dd -o output/` -- Recover Windows executables

### Forensic Analysis

Process forensic evidence images with audit trail output. The audit file
(audit.txt) documents what was found and where.

- `foremost -i evidence.E01 -o output/ -v` -- Process EnCase evidence image
- `foremost -i evidence.dd -o output/ -T` -- Timestamp output directories
- `foremost -i image.dd -o output/ -b 4096` -- Set block size (match filesystem)

**Output structure:** foremost creates subdirectories per file type (jpg/, pdf/, etc.)
with an `audit.txt` summary listing all recovered files with offsets.

## Defaults

- Disk image argument is required for carving
- Output goes to a timestamped directory by default
- Foremost operates on local files -- no network target needed

## Target Validation

Foremost operates on local disk images and files. No network scope validation required.
All commands validate via the PreToolUse hook.
