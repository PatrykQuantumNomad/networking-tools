---
title: "John the Ripper — Versatile Password Cracker"
description: John the Ripper is a versatile password cracker that works on CPU, best at cracking Linux system passwords, password-protected archives, SSH keys, and more
sidebar:
  order: 12
---

## What It Does

John the Ripper is a versatile password cracker that works on CPU. Best at cracking Linux system passwords (`/etc/shadow`), password-protected archives (ZIP, RAR, 7z), SSH keys, Office documents, KeePass databases, and PDFs. Its key advantage over hashcat is the `*2john` family of utilities that extract crackable hashes from files. John auto-detects hash types and supports dictionary, rule-based, and incremental (brute force) attacks.

## Running the Examples Script

```bash
# No target argument required
bash scripts/john/examples.sh

# No direct Makefile target for base examples
# Use the use-case scripts below instead
```

The script creates sample hash files for practice, then prints 10 example commands covering dictionary attacks, hash extraction, format specification, and session management.

## Wordlist Setup

John needs a wordlist for dictionary attacks. Download rockyou.txt (~14M passwords, ~140MB):

```bash
make wordlists
# or: bash wordlists/download.sh
```

This places `rockyou.txt` in the project's `wordlists/` directory. The use-case scripts reference it automatically via `$WORDLIST`.

## Key Flags to Remember

| Flag | What It Does |
| ------ | ------------- |
| `--wordlist=<file>` | Dictionary attack with wordlist |
| `--rules=<name>` | Apply word mangling rules (best64, jumbo, etc.) |
| `--format=<type>` | Specify hash format (raw-md5, sha512crypt, bcrypt, nt, etc.) |
| `--show` | Display cracked passwords |
| `--incremental` | Brute force mode (tries all combinations) |
| `--fork=<n>` | Use N CPU cores for parallel cracking |
| `--users=<name>` | Target specific user only |
| `--list=formats` | List all supported hash formats |
| `--restore=<name>` | Resume an interrupted session |
| `--mask=<pattern>` | Mask-based attack (if you know password pattern) |

## Hash Extraction Utilities (*2john)

John's killer feature -- extract crackable hashes from password-protected files:

| Utility | Extracts From |
| ------ | ------------- |
| `unshadow` | Linux passwd + shadow files |
| `zip2john` | ZIP archives |
| `rar2john` | RAR archives |
| `7z2john` | 7-Zip archives |
| `pdf2john` | PDF documents |
| `ssh2john` | SSH private keys |
| `keepass2john` | KeePass databases |
| `office2john` | Office documents (docx, xlsx, pptx) |
| `gpg2john` | GPG/PGP keys |
| `dmg2john` | macOS disk images |
| `bitlocker2john` | BitLocker volumes |

## Cracking Progression (recommended order)

1. `john hashes.txt` -- default mode (auto-detect format, try common passwords)
2. `john --wordlist=rockyou.txt hashes.txt` -- dictionary attack
3. `john --wordlist=rockyou.txt --rules=best64 hashes.txt` -- dictionary + rules
4. `john --incremental hashes.txt` -- brute force (last resort, slow)
5. `john --show hashes.txt` -- display cracked passwords

## Use-Case Scripts

### crack-linux-passwords.sh -- Extract and crack /etc/shadow hashes

Demonstrates the full workflow for cracking Linux system passwords. Uses `unshadow` to combine `/etc/passwd` and `/etc/shadow` into a format John can process, then cracks with dictionary and rule-based attacks.

**When to use:** After gaining root access to a Linux system and extracting password files, or during post-exploitation to recover plaintext credentials for lateral movement.

**Linux hash type prefixes:**
- `$6$` = SHA-512 (most common on modern Linux)
- `$5$` = SHA-256
- `$y$` = yescrypt (newer distros like Debian 11+)
- `$2b$` = bcrypt (some BSD systems)
- `$1$` = MD5 (legacy, insecure)

**Key commands:**

```bash
# Step 1: Combine passwd and shadow files
sudo unshadow /etc/passwd /etc/shadow > unshadowed.txt

# Step 2: Crack with default settings (auto-detects hash type)
john unshadowed.txt

# Crack with a wordlist
john --wordlist=wordlists/rockyou.txt unshadowed.txt

# Crack with wordlist + rules for word mutations
john --wordlist=wordlist.txt --rules=best64 unshadowed.txt

# Target a specific user only
john --users=admin unshadowed.txt

# Use multiple CPU cores
john --fork=4 --wordlist=rockyou.txt unshadowed.txt

# Specify hash format explicitly
john --format=sha512crypt unshadowed.txt

# Show cracked passwords
john --show unshadowed.txt
```

**Make target:** `make crack-linux-pw`

---

### crack-archive-passwords.sh -- Crack password-protected archives

Cracks password-protected ZIP, RAR, 7z, PDF, SSH keys, KeePass databases, and Office documents. Uses a two-step process: first extract the hash with a `*2john` utility, then crack the extracted hash.

**When to use:** When you encounter a password-protected file during an engagement -- encrypted archives from file shares, locked PDFs, passphrase-protected SSH keys, KeePass vaults.

**Key commands:**

```bash
# ZIP: extract hash then crack
zip2john protected.zip > zip.hash
john --wordlist=wordlists/rockyou.txt zip.hash

# RAR: extract hash then crack
rar2john protected.rar > rar.hash
john --wordlist=rockyou.txt rar.hash

# 7-Zip: extract hash then crack
7z2john protected.7z > 7z.hash
john --wordlist=rockyou.txt 7z.hash

# PDF: extract hash then crack
pdf2john protected.pdf > pdf.hash
john --wordlist=rockyou.txt pdf.hash

# SSH private key: extract passphrase hash then crack
ssh2john id_rsa > ssh.hash
john --wordlist=rockyou.txt ssh.hash

# KeePass database: extract hash then crack
keepass2john database.kdbx > keepass.hash
john --wordlist=rockyou.txt keepass.hash

# Office document: extract hash then crack
office2john protected.docx > office.hash
john --wordlist=rockyou.txt office.hash

# Show cracked password
john --show zip.hash

# Crack with a mask if you know the password pattern (e.g., 4 digits)
john --mask='?d?d?d?d' zip.hash
```

**Make target:** `make crack-archive TARGET=<file>`

---

### identify-hash-type.sh -- Identify unknown hash types by pattern

Helps identify unknown hash types by analyzing their length, character set, and prefix. Shows how to find the correct John format for cracking. Pass a hash string as an argument for automatic pattern analysis.

**When to use:** When you have a hash but don't know the algorithm. Before running John or hashcat, you need to know the format.

**Quick reference:**

| Length | Characters | Likely Type | John Format |
| ------ | ------------- | ------------- | ------------- |
| 32 | hex | MD5 or NTLM | `raw-md5` or `nt` |
| 40 | hex | SHA-1 | `raw-sha1` |
| 64 | hex | SHA-256 | `raw-sha256` |
| 128 | hex | SHA-512 | `raw-sha512` |
| `$6$...` | mixed | SHA-512crypt | `sha512crypt` |
| `$5$...` | mixed | SHA-256crypt | `sha256crypt` |
| `$1$...` | mixed | MD5crypt | `md5crypt` |
| `$2b$...` | mixed | bcrypt | `bcrypt` |
| `$P$...` | mixed | phpass (WordPress) | `phpass` |

**Key commands:**

```bash
# List all supported formats
john --list=formats

# Search for formats matching a keyword
john --list=formats | grep -i md5
john --list=formats | grep -i sha

# Auto-detect format by running John directly
john hash.txt

# Analyze a specific hash interactively
bash scripts/john/identify-hash-type.sh '5f4dcc3b5aa765d61d8327deb882cf99'
```

**Make target:** `make identify-hash TARGET=<hash>`

## Practice Against Lab Targets

```bash
make lab-up

# If you extract MD5 hashes from DVWA via SQL injection:
# 1. Save them to a file
echo "admin:5f4dcc3b5aa765d61d8327deb882cf99" > dvwa-hashes.txt

# 2. Crack with John
john --format=raw-md5 --wordlist=wordlists/rockyou.txt dvwa-hashes.txt

# 3. Show results
john --show --format=raw-md5 dvwa-hashes.txt

# Practice archive cracking: create a test ZIP and crack it
echo "secret data" > /tmp/secret.txt
zip -P test123 /tmp/test.zip /tmp/secret.txt
zip2john /tmp/test.zip > /tmp/test.hash
john /tmp/test.hash
```

## Notes

- John auto-detects hash format in most cases -- only use `--format` when it guesses wrong
- The `*2john` utilities are John's superpower -- hashcat cannot extract hashes from files
- John uses CPU by default; for GPU-heavy cracking, prefer hashcat
- Cracked passwords are stored in `~/.john/john.pot` -- `--show` reads from this potfile
- Use `--fork=<n>` to use multiple CPU cores (set to number of physical cores)
- John's `--rules` applies word mutations (capitalize, append numbers, leet speak, etc.)
- The `--incremental` mode tries all character combinations -- effective but very slow for long passwords
- Session management: John auto-saves progress. Use `--restore` to resume after interruption
- On macOS, install with `brew install john` (includes jumbo patch with all formats)
- John and hashcat complement each other: John for file extraction + CPU cracking, hashcat for GPU speed
