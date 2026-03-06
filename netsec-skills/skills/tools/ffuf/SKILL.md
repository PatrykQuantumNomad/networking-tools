---
name: ffuf
description: >-
  Fuzz web parameters, directories, and endpoints with ffuf. Parameter
  discovery, content filtering, custom wordlists.
disable-model-invocation: true
---

# Ffuf Web Fuzzer

Fuzz web parameters, directories, and endpoints using ffuf.

## Tool Status

- Tool installed: !`command -v ffuf > /dev/null 2>&1 && echo "YES -- $(ffuf -V 2>&1 | head -1)" || echo "NO -- Install: brew install ffuf (macOS) | go install github.com/ffuf/ffuf/v2@latest"`
- Wrapper scripts available: !`test -f scripts/ffuf/fuzz-parameters.sh && echo "YES -- use wrapper scripts for structured JSON output" || echo "NO -- using standalone mode with direct commands"`

## Mode: Wrapper Scripts Available

If wrapper scripts are available (shown as YES above), prefer these commands.
They provide structured JSON output and educational context.

### Parameter Fuzzing
- `bash scripts/ffuf/fuzz-parameters.sh <target> <wordlist> -j -x` -- Fuzz URL parameters, headers, and POST data to discover hidden inputs

### Learning Mode
- `bash scripts/ffuf/examples.sh <target>` -- 10 common ffuf patterns with explanations

Always add `-j` for JSON output and `-x` to execute (vs display-only).

## Mode: Standalone (Direct Commands)

If wrapper scripts are NOT available, use these direct ffuf commands.

### Directory and File Fuzzing

FUZZ is the placeholder keyword -- ffuf replaces it with each wordlist entry.
Filter responses by status code, size, or word count to remove noise.

- `ffuf -u http://<target>/FUZZ -w wordlist.txt` -- Basic directory fuzzing
- `ffuf -u http://<target>/FUZZ -w wordlist.txt -fc 404` -- Filter out 404 responses
- `ffuf -u http://<target>/FUZZ -w wordlist.txt -fc 404,403` -- Filter 404 and 403
- `ffuf -u http://<target>/FUZZ -w wordlist.txt -mc 200,301` -- Match only 200 and 301
- `ffuf -u http://<target>/FUZZ.php -w wordlist.txt -fc 404` -- Fuzz with .php extension
- `ffuf -u http://<target>/FUZZ -w wordlist.txt -t 50` -- 50 concurrent threads
- `ffuf -u http://<target>/FUZZ -w wordlist.txt -o results.json -of json` -- Save JSON output

### Parameter Fuzzing

Discover hidden GET and POST parameters by fuzzing parameter names or values.
Use response size filtering (-fs) to eliminate identical default responses.

- `ffuf -u "http://<target>/page?FUZZ=test" -w params.txt -fc 404` -- Fuzz GET parameter names
- `ffuf -u "http://<target>/page?id=FUZZ" -w values.txt -fc 404` -- Fuzz parameter values
- `ffuf -u http://<target>/page -X POST -d "FUZZ=test" -w params.txt -fc 404` -- Fuzz POST parameter names
- `ffuf -u http://<target>/page -X POST -d "user=FUZZ" -w wordlist.txt -fs 1234` -- Filter by response size

### Header and Authentication Fuzzing

Fuzz HTTP headers, virtual hosts, or authentication tokens.

- `ffuf -u http://<target> -H "Host: FUZZ.<domain>" -w subdomains.txt -fc 404` -- Virtual host discovery
- `ffuf -u http://<target>/api -H "Authorization: Bearer FUZZ" -w tokens.txt -fc 401` -- Token fuzzing
- `ffuf -u http://<target>/FUZZ -w wordlist.txt -b "PHPSESSID=abc123"` -- Fuzz with session cookie

### Recommended Wordlists

Ffuf requires wordlists. SecLists is the standard collection:
- Directories: `SecLists/Discovery/Web-Content/directory-list-2.3-medium.txt`
- Parameters: `SecLists/Discovery/Web-Content/burp-parameter-names.txt`
- Install: `git clone https://github.com/danielmiessler/SecLists.git`

## Defaults

- Target defaults to `http://localhost:8080` (DVWA)
- Wordlist argument required (no built-in default)
- FUZZ keyword is mandatory in the URL, data, or headers

## Target Validation

All commands validate targets against `.pentest/scope.json` via the PreToolUse hook.
