#!/usr/bin/env bash
# ============================================================================
# @description  Test HTTP endpoints with different methods
# @usage        curl/test-http-endpoints.sh [target] [-h|--help] [-x|--execute] [-j|--json]
# @dependencies curl, common.sh
# ============================================================================
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [target] [-h|--help] [-x|--execute] [-j|--json] [-v|--verbose] [-q|--quiet]"
    echo ""
    echo "Description:"
    echo "  Demonstrates HTTP method testing with curl. Shows how to send"
    echo "  GET, POST, PUT, DELETE, PATCH, HEAD, and OPTIONS requests to"
    echo "  inspect API behavior and status codes."
    echo "  Default target is https://example.com if none is provided."
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")                          # Test example.com"
    echo "  $(basename "$0") http://localhost:8080     # Test local server"
    echo "  $(basename "$0") https://api.example.com   # Test API endpoint"
    echo "  $(basename "$0") -x https://example.com    # Execute HTTP method tests"
    echo "  $(basename "$0") --help                    # Show this help message"
    echo ""
    echo "Flags:"
    echo "  -h, --help     Show this help message"
    echo "  -j, --json     Output as JSON; add -x to run and capture results (requires jq)"
    echo "  -x, --execute  Execute commands instead of displaying them"
    echo "  -v, --verbose  Increase output verbosity"
    echo "  -q, --quiet    Suppress informational output"
}

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

require_cmd curl "apt install curl (Debian/Ubuntu) | brew install curl (macOS)"

TARGET="${1:-https://example.com}"

json_set_meta "curl" "$TARGET" "network-analysis"

confirm_execute "${1:-}"
safety_banner

info "=== Test HTTP Endpoints ==="
info "Target: ${TARGET}"
echo ""

info "Why test HTTP endpoints?"
echo "   Different HTTP methods serve different purposes:"
echo "   - GET: Retrieve data (read-only, safe)"
echo "   - POST: Create new resources (login forms, file uploads)"
echo "   - PUT: Replace an entire resource (full update)"
echo "   - PATCH: Partially update a resource (change one field)"
echo "   - DELETE: Remove a resource"
echo "   - HEAD: Like GET but returns headers only (check existence)"
echo "   - OPTIONS: Discover allowed methods and CORS policy"
echo "   Testing each method reveals how servers respond and what's allowed."
echo ""

# 1. GET request
info "1) GET request — retrieve a resource"
echo "   curl -s -o /dev/null -w 'HTTP %{http_code}\n' ${TARGET}"
echo ""
json_add_example "GET request — retrieve a resource" \
    "curl -s -o /dev/null -w 'HTTP %{http_code}\n' ${TARGET}"

# 2. POST with form data
info "2) POST with form data"
echo "   curl -X POST -d 'username=admin&password=test' -s -o /dev/null -w 'HTTP %{http_code}\n' ${TARGET}"
echo ""
json_add_example "POST with form data" \
    "curl -X POST -d 'username=admin&password=test' -s -o /dev/null -w 'HTTP %{http_code}\n' ${TARGET}"

# 3. POST with JSON body
info "3) POST with JSON body"
echo "   curl -X POST -H 'Content-Type: application/json' -d '{\"key\":\"value\"}' ${TARGET}"
echo ""
json_add_example "POST with JSON body" \
    "curl -X POST -H 'Content-Type: application/json' -d '{\"key\":\"value\"}' ${TARGET}"

# 4. PUT request
info "4) PUT request — replace a resource"
echo "   curl -X PUT -H 'Content-Type: application/json' -d '{\"name\":\"updated\"}' ${TARGET}/resource/1"
echo ""
json_add_example "PUT request — replace a resource" \
    "curl -X PUT -H 'Content-Type: application/json' -d '{\"name\":\"updated\"}' ${TARGET}/resource/1"

# 5. DELETE request
info "5) DELETE request — remove a resource"
echo "   curl -X DELETE -s -o /dev/null -w 'HTTP %{http_code}\n' ${TARGET}/resource/1"
echo ""
json_add_example "DELETE request — remove a resource" \
    "curl -X DELETE -s -o /dev/null -w 'HTTP %{http_code}\n' ${TARGET}/resource/1"

# 6. PATCH request
info "6) PATCH request — partial update"
echo "   curl -X PATCH -H 'Content-Type: application/json' -d '{\"status\":\"active\"}' ${TARGET}/resource/1"
echo ""
json_add_example "PATCH request — partial update" \
    "curl -X PATCH -H 'Content-Type: application/json' -d '{\"status\":\"active\"}' ${TARGET}/resource/1"

# 7. HEAD request
run_or_show "7) HEAD request — headers only, no body" \
    curl -I -s "$TARGET"

# 8. OPTIONS request
run_or_show "8) OPTIONS request — discover allowed methods and CORS" \
    curl -X OPTIONS -i -s "$TARGET"

# 9. Custom User-Agent
info "9) Send with custom User-Agent"
echo "   curl -A 'Mozilla/5.0 (compatible; SecurityAudit/1.0)' -s -o /dev/null -w 'HTTP %{http_code}\n' ${TARGET}"
echo ""
json_add_example "Send with custom User-Agent" \
    "curl -A 'Mozilla/5.0 (compatible; SecurityAudit/1.0)' -s -o /dev/null -w 'HTTP %{http_code}\n' ${TARGET}"

# 10. Follow redirects and show chain
info "10) Follow redirects and show the redirect chain"
echo "    curl -L -v -s -o /dev/null ${TARGET} 2>&1 | grep -E '< HTTP/|< location:'"
echo ""
json_add_example "Follow redirects and show the redirect chain" \
    "curl -L -v -s -o /dev/null ${TARGET} 2>&1 | grep -E '< HTTP/|< location:'"

json_finalize

# Interactive demo (skip if non-interactive)
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    [[ ! -t 0 ]] && exit 0

    read -rp "Check HTTP status code for ${TARGET} now? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        info "Running: curl -s -o /dev/null -w 'HTTP %{http_code}' ${TARGET}"
        echo ""
        curl -s -o /dev/null -w "HTTP %{http_code}" "$TARGET"
        echo ""
    fi
fi
