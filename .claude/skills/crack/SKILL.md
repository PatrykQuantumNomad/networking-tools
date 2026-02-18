---
name: crack
description: Run password cracking workflow -- hash identification, dictionary attacks, and brute force
argument-hint: "<hashfile-or-hash>"
disable-model-invocation: true
---

# Password Cracking Workflow

Identify and crack password hashes using multiple tools and techniques.

## Target

Target: $ARGUMENTS

If no input was provided, ask the user for a hash file path or hash string. This workflow operates on local files -- no network scope validation needed. The input can be a file containing hashes (one per line) or a single hash string.

## Steps

Always start with Step 1 (hash identification). Based on the type identified, run only the relevant cracking steps (2-5) -- do not run all steps blindly.

### 1. Hash Identification

Identify the hash algorithm(s) before attempting to crack:

```
bash scripts/john/identify-hash-type.sh $ARGUMENTS -j -x
```

This determines which subsequent tools and modes to use. Note the identified hash type (e.g., NTLM, MD5, bcrypt, sha512crypt) to select the appropriate cracking step below.

### 2. NTLM Cracking (if applicable)

If hashes are identified as NTLM (Windows password hashes), use GPU-accelerated hashcat:

```
bash scripts/hashcat/crack-ntlm-hashes.sh $ARGUMENTS -j -x
```

Skip if hashes are not NTLM. NTLM hashes typically come from SAM dumps, Mimikatz output, or Responder captures.

### 3. Web Hash Cracking (if applicable)

If hashes are MD5, SHA-256, bcrypt, WordPress, Django, or MySQL types, crack with hashcat:

```
bash scripts/hashcat/crack-web-hashes.sh $ARGUMENTS -j -x
```

Skip if not a web hash type. Web hashes typically come from database dumps, /etc/passwd entries, or captured web application data.

### 4. Linux Password Cracking (if applicable)

If hashes are from /etc/shadow or similar Linux password stores (sha512crypt, sha256crypt, yescrypt):

```
bash scripts/john/crack-linux-passwords.sh -j -x
```

Note: this script handles /etc/shadow internally and does not take a positional hash file argument. Skip if not Linux shadow hashes.

### 5. Archive Cracking (if applicable)

If the target is a password-protected ZIP, RAR, 7z, or PDF file:

```
bash scripts/john/crack-archive-passwords.sh $ARGUMENTS -j -x
```

Skip if not an archive file. John automatically extracts the hash from supported archive formats before cracking.

## After Each Step

- Review the cracking results from the PostToolUse hook
- Note any recovered passwords immediately -- record them for the summary
- If a tool is not installed, skip that step and note it
- If cracking fails with the default wordlist, consider suggesting custom wordlists or rule-based attacks

## Decision Guidance

Based on the hash type identified in Step 1, select the appropriate cracking step(s):

| Hash Type | Tool | Step |
|-----------|------|------|
| NTLM, NTLMv2 | hashcat | Step 2 |
| MD5, SHA-1, SHA-256, bcrypt, WordPress, Django, MySQL | hashcat | Step 3 |
| sha512crypt, sha256crypt, yescrypt (/etc/shadow) | john | Step 4 |
| ZIP, RAR, 7z, PDF (archive files) | john | Step 5 |

If the hash type is ambiguous, try multiple approaches. Some hashes (e.g., MD5) may be cracked by both hashcat modes.

## Summary

After completing the relevant steps, provide a structured cracking summary:

- **Hash Types Identified**: Algorithm(s) detected and confidence level
- **Passwords Recovered**: Cleartext passwords and the hashes they correspond to
- **Failed Attempts**: Steps that ran but did not recover passwords
- **Recommendations**: Suggestions for further cracking (custom wordlists, longer runtimes, rule-based attacks)
