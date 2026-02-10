#!/usr/bin/env bash
# curl/test-http-endpoints.sh — Test HTTP endpoints with different methods
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [target] [-h|--help]"
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
    echo "  $(basename "$0") --help                    # Show this help message"
}

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

require_cmd curl "apt install curl (Debian/Ubuntu) | brew install curl (macOS)"

TARGET="${1:-https://example.com}"

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

# 2. POST with form data
info "2) POST with form data"
echo "   curl -X POST -d 'username=admin&password=test' -s -o /dev/null -w 'HTTP %{http_code}\n' ${TARGET}"
echo ""

# 3. POST with JSON body
info "3) POST with JSON body"
echo "   curl -X POST -H 'Content-Type: application/json' -d '{\"key\":\"value\"}' ${TARGET}"
echo ""

# 4. PUT request
info "4) PUT request — replace a resource"
echo "   curl -X PUT -H 'Content-Type: application/json' -d '{\"name\":\"updated\"}' ${TARGET}/resource/1"
echo ""

# 5. DELETE request
info "5) DELETE request — remove a resource"
echo "   curl -X DELETE -s -o /dev/null -w 'HTTP %{http_code}\n' ${TARGET}/resource/1"
echo ""

# 6. PATCH request
info "6) PATCH request — partial update"
echo "   curl -X PATCH -H 'Content-Type: application/json' -d '{\"status\":\"active\"}' ${TARGET}/resource/1"
echo ""

# 7. HEAD request
info "7) HEAD request — headers only, no body"
echo "   curl -I -s ${TARGET}"
echo ""

# 8. OPTIONS request
info "8) OPTIONS request — discover allowed methods and CORS"
echo "   curl -X OPTIONS -i -s ${TARGET}"
echo ""

# 9. Custom User-Agent
info "9) Send with custom User-Agent"
echo "   curl -A 'Mozilla/5.0 (compatible; SecurityAudit/1.0)' -s -o /dev/null -w 'HTTP %{http_code}\n' ${TARGET}"
echo ""

# 10. Follow redirects and show chain
info "10) Follow redirects and show the redirect chain"
echo "    curl -L -v -s -o /dev/null ${TARGET} 2>&1 | grep -E '< HTTP/|< location:'"
echo ""

# Interactive demo
[[ ! -t 0 ]] && exit 0

read -rp "Check HTTP status code for ${TARGET} now? [y/N] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    info "Running: curl -s -o /dev/null -w 'HTTP %{http_code}' ${TARGET}"
    echo ""
    curl -s -o /dev/null -w "HTTP %{http_code}" "$TARGET"
    echo ""
fi
