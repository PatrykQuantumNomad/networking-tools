# Requirements: Networking Tools

**Defined:** 2026-02-13
**Core Value:** Ready-to-run scripts and accessible documentation that eliminate the need to remember tool flags and configurations -- run one command, get what you need.

## v1.4 Requirements

Requirements for JSON Output Mode milestone. Each maps to roadmap phases.

### JSON Library

- [ ] **JSON-01**: User can get structured JSON output from any use-case script by passing `-j`/`--json` flag
- [ ] **JSON-02**: JSON output follows envelope pattern: `{"meta": {...}, "results": [...], "summary": {...}}`
- [ ] **JSON-03**: `lib/json.sh` module provides `json_is_active`, `json_set_meta`, `json_add_result`, `json_finalize` functions
- [ ] **JSON-04**: jq is required only when `-j` is used (lazy dependency enforcement)
- [ ] **JSON-05**: fd3 redirection ensures clean stdout for JSON -- all human output goes to stderr in JSON mode
- [ ] **JSON-06**: All JSON construction uses `jq -n --arg` for correct RFC 8259 escaping

### Flag Integration

- [ ] **FLAG-01**: `-j`/`--json` flag is recognized by `parse_common_args` and sets `OUTPUT_FORMAT=json`
- [ ] **FLAG-02**: `-j` works with `-x` (execute mode) to capture and structure real tool output
- [ ] **FLAG-03**: `-j` works without `-x` (show mode) to output example commands as JSON
- [ ] **FLAG-04**: `confirm_execute()` skips interactive prompt when JSON mode is active
- [ ] **FLAG-05**: `NO_COLOR=1` is set automatically when JSON mode is active

### Script Migration

- [ ] **SCRIPT-01**: All 46 use-case scripts call `json_set_meta` and `json_finalize` for JSON support
- [ ] **SCRIPT-02**: Scripts using `run_or_show` get JSON output automatically via library changes
- [ ] **SCRIPT-03**: Scripts using `info`+`echo` patterns are updated to use JSON accumulation helpers
- [ ] **SCRIPT-04**: Each script's JSON output includes correct tool name, script name, and category in meta

### Testing

- [ ] **TEST-01**: BATS unit tests validate `lib/json.sh` functions (envelope assembly, escaping, meta fields)
- [ ] **TEST-02**: BATS unit tests validate `-j` flag parsing in `parse_common_args`
- [ ] **TEST-03**: BATS integration tests validate every use-case script produces valid JSON with `-j`
- [ ] **TEST-04**: JSON output from each script passes `jq .` validation (valid JSON structure)

### Documentation

- [ ] **DOC-01**: All 46 use-case scripts' `show_help()` mentions `-j`/`--json` flag
- [ ] **DOC-02**: Script metadata headers updated to include JSON output capability

## Future Requirements

Deferred to future release. Tracked but not in current roadmap.

### Structured Tool Output

- **STRUCT-01**: Execute mode parses nmap XML output into structured JSON results
- **STRUCT-02**: Execute mode parses tshark `-T json` output into structured JSON results
- **STRUCT-03**: Execute mode parses nikto native JSON into structured results

### Advanced JSON Features

- **ADV-01**: `--jq EXPR` flag pipes JSON output through jq filter expression
- **ADV-02**: NDJSON streaming mode for long-running execute mode commands
- **ADV-03**: Field selection to limit which envelope fields are emitted

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Pure bash JSON generation (no jq) | Research showed manual escaping is fragile and produces invalid JSON on edge cases. jq `--arg` handles all RFC 8259 escaping correctly. |
| JSON output for `examples.sh` scripts | Lower priority; use-case scripts are the primary automation target. Same pattern applies later. |
| Parsing tool-specific output formats | Raw stdout capture covers all tools immediately. Structured parsing is per-tool work for a future milestone. |
| JSON schema validation (jsonschema) | Overkill for v1.4. `jq .` validation is sufficient to prove structural correctness. |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| JSON-01 | — | Pending |
| JSON-02 | — | Pending |
| JSON-03 | — | Pending |
| JSON-04 | — | Pending |
| JSON-05 | — | Pending |
| JSON-06 | — | Pending |
| FLAG-01 | — | Pending |
| FLAG-02 | — | Pending |
| FLAG-03 | — | Pending |
| FLAG-04 | — | Pending |
| FLAG-05 | — | Pending |
| SCRIPT-01 | — | Pending |
| SCRIPT-02 | — | Pending |
| SCRIPT-03 | — | Pending |
| SCRIPT-04 | — | Pending |
| TEST-01 | — | Pending |
| TEST-02 | — | Pending |
| TEST-03 | — | Pending |
| TEST-04 | — | Pending |
| DOC-01 | — | Pending |
| DOC-02 | — | Pending |

**Coverage:**
- v1.4 requirements: 21 total
- Mapped to phases: 0
- Unmapped: 21

---
*Requirements defined: 2026-02-13*
*Last updated: 2026-02-13 after initial definition*
