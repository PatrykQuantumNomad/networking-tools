---
name: hashcat
description: >-
  Crack password hashes with GPU acceleration using hashcat. NTLM, MD5,
  SHA-256, bcrypt, rule-based attacks, benchmarking.
disable-model-invocation: true
---

# Hashcat Password Cracker

Crack password hashes with GPU acceleration using hashcat.

## Tool Status

- Tool installed: !`command -v hashcat > /dev/null 2>&1 && echo "YES -- $(hashcat --version 2>/dev/null)" || echo "NO -- Install: brew install hashcat (macOS) | apt install hashcat (Debian/Ubuntu)"`
- Wrapper scripts available: !`test -f scripts/hashcat/crack-ntlm-hashes.sh && echo "YES -- use wrapper scripts for structured JSON output" || echo "NO -- using standalone mode with direct commands"`

## Mode: Wrapper Scripts Available

If wrapper scripts are available (shown as YES above), prefer these commands.
They provide structured JSON output and educational context.

### GPU Benchmarking
- `bash scripts/hashcat/benchmark-gpu.sh -j -x` -- Benchmark GPU hash cracking speed across common hash types

### NTLM Cracking
- `bash scripts/hashcat/crack-ntlm-hashes.sh <hashfile> -j -x` -- Crack Windows NTLM hashes using dictionary, brute force, and rule-based attacks

### Web Hash Cracking
- `bash scripts/hashcat/crack-web-hashes.sh <hashfile> -j -x` -- Crack MD5, SHA-256, bcrypt, WordPress, Django, and MySQL hashes

### Learning Mode
- `bash scripts/hashcat/examples.sh` -- 10 common hashcat patterns with explanations

Always add `-j` for JSON output and `-x` to execute (vs display-only).

## Mode: Standalone (Direct Commands)

If wrapper scripts are NOT available, use these direct hashcat commands.

### Benchmarking

Test GPU cracking speed for different hash types. Useful for estimating crack
times and verifying hardware acceleration is working.

- `hashcat -b` -- Benchmark all hash types
- `hashcat -b -m 1000` -- Benchmark NTLM specifically
- `hashcat -b -m 3200` -- Benchmark bcrypt specifically

### Dictionary Attacks

Straight dictionary attack tries every word in a wordlist. Rule-based attacks
apply transformations (capitalize, append numbers, leet speak) to each word.

- `hashcat -m 1000 -a 0 hashes.txt wordlist.txt` -- NTLM dictionary attack
- `hashcat -m 0 -a 0 hashes.txt wordlist.txt` -- MD5 dictionary attack
- `hashcat -m 1400 -a 0 hashes.txt wordlist.txt` -- SHA-256 dictionary attack
- `hashcat -m 3200 -a 0 hashes.txt wordlist.txt` -- bcrypt dictionary attack
- `hashcat -m 1000 -a 0 hashes.txt wordlist.txt -r rules/best64.rule` -- NTLM with rule mutations
- `hashcat -m 0 -a 0 hashes.txt wordlist.txt -r rules/rockyou-30000.rule` -- MD5 with large ruleset

### Brute Force and Masks

Mask attacks try all combinations matching a pattern. Faster than pure brute
force when you know password structure (e.g., 8 chars, starts uppercase).

- `hashcat -m 1000 -a 3 hashes.txt ?u?l?l?l?l?d?d?d` -- NTLM mask: Upperlllnnn
- `hashcat -m 1000 -a 3 hashes.txt ?a?a?a?a?a?a` -- NTLM brute force 6 chars
- `hashcat -m 0 -a 6 hashes.txt wordlist.txt ?d?d?d` -- Hybrid: word + 3 digits

### Common Hash Mode Numbers

`-m 0` MD5, `-m 100` SHA1, `-m 1000` NTLM, `-m 1400` SHA-256, `-m 1800` sha512crypt,
`-m 3200` bcrypt, `-m 400` WordPress, `-m 10000` Django PBKDF2.

## Defaults

- Hash file argument is required for cracking (optional for benchmark)
- Hashcat operates on local files -- no network target needed
- Output shows cracked passwords with `hashcat --show -m <mode> hashes.txt`

## Target Validation

Hashcat operates on local hash files. No network scope validation required.
All commands validate via the PreToolUse hook.
