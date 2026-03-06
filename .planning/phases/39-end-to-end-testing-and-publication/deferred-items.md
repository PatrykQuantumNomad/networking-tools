# Deferred Items -- Phase 39

## Pre-existing Issues (Out of Scope)

1. **validate-plugin-boundary.sh missing metadata headers** -- The script at `scripts/validate-plugin-boundary.sh` lacks `@description`, `@usage`, `@dependencies` header comments required by `tests/intg-script-headers.bats` (HDR-06). This was failing before Phase 39 changes. The script needs these 3 header lines added to its first 10 lines.
