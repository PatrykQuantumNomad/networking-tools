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

## Environment Detection

- Wrapper scripts available: !`test -f scripts/john/identify-hash-type.sh && echo "YES" || echo "NO"`

## Steps

Always start with Step 1 (hash identification). Based on the type identified, run only the relevant cracking steps (2-5) -- do not run all steps blindly.

### 1. Hash Identification

Identify the hash algorithm(s) before attempting to crack. Correct identification determines which tool and mode to use, avoiding wasted time on wrong formats.

**If wrapper scripts are available (YES above):**

```
bash scripts/john/identify-hash-type.sh $ARGUMENTS -j -x
```

**If standalone (NO above), use direct commands:**

- `john --list=formats | grep -i <suspected_type>` -- Filter formats by type
- `john --format=raw-md5 --test hash.txt` -- Test specific format
- `hashcat --identify hash.txt` -- Alternative: hashcat's identify mode (if hashcat 6.2.6+)

Note the identified hash type (e.g., NTLM, MD5, bcrypt, sha512crypt) to select the appropriate cracking step below.

### 2. NTLM Cracking (if applicable)

If hashes are identified as NTLM (Windows password hashes), use GPU-accelerated hashcat. NTLM hashes typically come from SAM dumps, Mimikatz output, or Responder captures.

**If wrapper scripts are available (YES above):**

```
bash scripts/hashcat/crack-ntlm-hashes.sh $ARGUMENTS -j -x
```

**If standalone (NO above), use direct hashcat commands:**

- `hashcat -m 1000 -a 0 $ARGUMENTS wordlist.txt` -- Dictionary attack on NTLM
- `hashcat -m 1000 -a 3 $ARGUMENTS ?a?a?a?a?a?a` -- Mask attack (6 chars)

Skip if hashes are not NTLM.

### 3. Web Hash Cracking (if applicable)

If hashes are MD5, SHA-256, bcrypt, WordPress, Django, or MySQL types, crack with hashcat. Web hashes typically come from database dumps or captured web application data.

**If wrapper scripts are available (YES above):**

```
bash scripts/hashcat/crack-web-hashes.sh $ARGUMENTS -j -x
```

**If standalone (NO above), use direct hashcat commands:**

- `hashcat -m 0 -a 0 $ARGUMENTS wordlist.txt` -- MD5 dictionary attack
- `hashcat -m 100 -a 0 $ARGUMENTS wordlist.txt` -- SHA-1
- `hashcat -m 1400 -a 0 $ARGUMENTS wordlist.txt` -- SHA-256
- `hashcat -m 3200 -a 0 $ARGUMENTS wordlist.txt` -- bcrypt

Skip if not a web hash type.

### 4. Linux Password Cracking (if applicable)

If hashes are from /etc/shadow or similar Linux password stores (sha512crypt, sha256crypt, yescrypt). Shadow files require combining passwd and shadow before cracking.

**If wrapper scripts are available (YES above):**

```
bash scripts/john/crack-linux-passwords.sh -j -x
```

**If standalone (NO above), use direct john commands:**

- `unshadow /etc/passwd /etc/shadow > combined.txt` -- Merge passwd and shadow
- `john --wordlist=wordlist.txt combined.txt` -- Dictionary attack
- `john --wordlist=wordlist.txt --rules combined.txt` -- With rule mutations
- `john --show combined.txt` -- Display cracked passwords

Note: this step handles /etc/shadow internally. Skip if not Linux shadow hashes.

### 5. Archive Cracking (if applicable)

If the target is a password-protected ZIP, RAR, 7z, or PDF file. John can extract hashes from supported archive formats and crack them in one workflow.

**If wrapper scripts are available (YES above):**

```
bash scripts/john/crack-archive-passwords.sh $ARGUMENTS -j -x
```

**If standalone (NO above), use direct john commands:**

- `zip2john protected.zip > hash.txt` -- Extract hash from ZIP
- `rar2john protected.rar > hash.txt` -- Extract from RAR
- `john --wordlist=wordlist.txt hash.txt` -- Crack extracted hash

Skip if not an archive file.

## After Each Step

**If wrapper scripts are available:** Review the cracking results from the PostToolUse hook.

**If standalone:** Review the command output directly for recovered passwords.

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
