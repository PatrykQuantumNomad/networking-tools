---
name: john
description: >-
  Crack passwords and identify hash types with John the Ripper. Linux shadows,
  archive passwords, wordlists, incremental mode.
disable-model-invocation: true
---

# John the Ripper

Crack passwords and identify hash types using John the Ripper.

## Tool Status

- Tool installed: !`command -v john > /dev/null 2>&1 && echo "YES -- $(john --format=dummy 2>&1 | head -1 || echo 'john available')" || echo "NO -- Install: brew install john-jumbo (macOS) | apt install john (Debian/Ubuntu)"`
- Wrapper scripts available: !`test -f scripts/john/crack-linux-passwords.sh && echo "YES -- use wrapper scripts for structured JSON output" || echo "NO -- using standalone mode with direct commands"`

## Mode: Wrapper Scripts Available

If wrapper scripts are available (shown as YES above), prefer these commands.
They provide structured JSON output and educational context.

### Linux Passwords
- `bash scripts/john/crack-linux-passwords.sh -j -x` -- Crack /etc/shadow hashes using wordlists, rules, and incremental modes

### Archive Cracking
- `bash scripts/john/crack-archive-passwords.sh <archive> -j -x` -- Crack password-protected ZIP, RAR, 7z, and PDF files

### Hash Identification
- `bash scripts/john/identify-hash-type.sh <hash> -j -x` -- Identify unknown hash types using john's format detection

### Learning Mode
- `bash scripts/john/examples.sh` -- 10 common John the Ripper patterns with explanations

Always add `-j` for JSON output and `-x` to execute (vs display-only).

## Mode: Standalone (Direct Commands)

If wrapper scripts are NOT available, use these direct john commands.

### Linux Password Cracking

Combine /etc/passwd and /etc/shadow with unshadow, then crack. John auto-detects
hash types but you can force a format for speed.

- `unshadow /etc/passwd /etc/shadow > combined.txt` -- Merge passwd and shadow files
- `john combined.txt` -- Auto-detect hash type and crack
- `john --wordlist=wordlist.txt combined.txt` -- Dictionary attack with wordlist
- `john --wordlist=wordlist.txt --rules combined.txt` -- Dictionary with rule mutations
- `john --incremental combined.txt` -- Brute force (incremental mode)
- `john --show combined.txt` -- Display cracked passwords

### Archive Password Cracking

Extract hash from password-protected archives using *2john tools, then crack
the hash. Each archive format has its own extraction tool.

- `zip2john protected.zip > hash.txt` -- Extract hash from ZIP file
- `rar2john protected.rar > hash.txt` -- Extract hash from RAR file
- `pdf2john protected.pdf > hash.txt` -- Extract hash from PDF file
- `john --wordlist=wordlist.txt hash.txt` -- Crack extracted archive hash
- `john --incremental hash.txt` -- Brute force archive hash

### Hash Identification and Format

John supports hundreds of hash formats. List available formats or filter by type
to find the right mode for your hash.

- `john --list=formats` -- List all supported hash formats
- `john --list=formats | grep -i md5` -- Find MD5-related formats
- `john --list=formats | grep -i sha` -- Find SHA-related formats
- `john --format=raw-md5 --wordlist=wordlist.txt hash.txt` -- Force specific format

### Session Management

Long cracking jobs can be paused and resumed. Status shows current progress
and estimated completion time.

- `john --session=mysession hash.txt` -- Name a cracking session
- `john --restore=mysession` -- Resume a paused session
- `john --status=mysession` -- Check session progress

## Defaults

- John operates on local hash files -- no network target needed
- Auto-detects hash format when not specified
- Results stored in `~/.john/john.pot` (potfile)

## Target Validation

John operates on local hash files. No network scope validation required.
All commands validate via the PreToolUse hook.
