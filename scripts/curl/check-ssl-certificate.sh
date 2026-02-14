#!/usr/bin/env bash
# ============================================================================
# @description  Check SSL/TLS certificate details
# @usage        curl/check-ssl-certificate.sh [target] [-h|--help] [-x|--execute]
# @dependencies curl, common.sh
# ============================================================================
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [target] [-h|--help] [-x|--execute] [-v|--verbose] [-q|--quiet]"
    echo ""
    echo "Description:"
    echo "  Inspects SSL/TLS certificates using curl. Shows how to check"
    echo "  certificate validity, expiry dates, TLS version support, and"
    echo "  certificate chain of trust."
    echo "  Default target is example.com if none is provided."
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")                  # Check example.com"
    echo "  $(basename "$0") google.com       # Check google.com cert"
    echo "  $(basename "$0") 10.0.0.1         # Check internal server"
    echo "  $(basename "$0") -x google.com    # Execute checks against google.com"
    echo "  $(basename "$0") --help           # Show this help message"
}

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

require_cmd curl "apt install curl (Debian/Ubuntu) | brew install curl (macOS)"

# Strip https:// prefix if provided for clean display
TARGET="${1:-example.com}"
TARGET="${TARGET#https://}"
TARGET="${TARGET#http://}"

json_set_meta "curl" "$TARGET" "network-analysis"

confirm_execute "${1:-}"
safety_banner

info "=== Check SSL Certificate ==="
info "Target: ${TARGET}"
echo ""

info "Why check SSL certificates?"
echo "   SSL/TLS certificates are the backbone of web security:"
echo "   - They encrypt traffic between client and server"
echo "   - Expired certificates break trust and block users"
echo "   - Weak TLS versions (1.0, 1.1) have known vulnerabilities"
echo "   - Certificate chain issues cause intermittent failures"
echo "   - HSTS headers enforce HTTPS and prevent downgrade attacks"
echo "   Checking certificates reveals misconfigurations before attackers do."
echo ""

# 1. View SSL cert details
info "1) View SSL certificate details via verbose output"
echo "   curl -vI https://${TARGET} 2>&1 | grep -E 'subject:|issuer:|expire|SSL'"
json_add_example "1) View SSL certificate details via verbose output" \
    "curl -vI https://${TARGET} 2>&1 | grep -E 'subject:|issuer:|expire|SSL'"
echo ""

# 2. Check cert expiry date
info "2) Check certificate expiry date"
echo "   curl -vI https://${TARGET} 2>&1 | grep 'expire date'"
json_add_example "2) Check certificate expiry date" \
    "curl -vI https://${TARGET} 2>&1 | grep 'expire date'"
echo ""

# 3. Test TLS 1.2 support
info "3) Test TLS 1.2 support"
echo "   curl --tlsv1.2 --tls-max 1.2 -sI https://${TARGET} -o /dev/null -w 'TLS 1.2: HTTP %{http_code}\n'"
json_add_example "3) Test TLS 1.2 support" \
    "curl --tlsv1.2 --tls-max 1.2 -sI https://${TARGET} -o /dev/null -w 'TLS 1.2: HTTP %{http_code}\n'"
echo ""

# 4. Test TLS 1.3 support
info "4) Test TLS 1.3 support"
echo "   curl --tlsv1.3 -sI https://${TARGET} -o /dev/null -w 'TLS 1.3: HTTP %{http_code}\n'"
json_add_example "4) Test TLS 1.3 support" \
    "curl --tlsv1.3 -sI https://${TARGET} -o /dev/null -w 'TLS 1.3: HTTP %{http_code}\n'"
echo ""

# 5. Show full certificate chain
info "5) Show full certificate chain (issuer hierarchy)"
echo "   curl -vI https://${TARGET} 2>&1 | grep -E 'subject:|issuer:'"
json_add_example "5) Show full certificate chain (issuer hierarchy)" \
    "curl -vI https://${TARGET} 2>&1 | grep -E 'subject:|issuer:'"
echo ""

# 6. Check cert for specific hostname (SNI)
info "6) Check certificate for specific hostname (SNI)"
echo "   curl --resolve ${TARGET}:443:\$(dig +short ${TARGET} | head -1) -vI https://${TARGET} 2>&1 | grep 'subject:'"
json_add_example "6) Check certificate for specific hostname (SNI)" \
    "curl --resolve ${TARGET}:443:\$(dig +short ${TARGET} | head -1) -vI https://${TARGET} 2>&1 | grep 'subject:'"
echo ""

# 7. Test with specific cipher
info "7) Test connection with a specific cipher suite"
echo "   curl --ciphers ECDHE-RSA-AES256-GCM-SHA384 -sI https://${TARGET} -o /dev/null -w 'Cipher test: HTTP %{http_code}\n'"
json_add_example "7) Test connection with a specific cipher suite" \
    "curl --ciphers ECDHE-RSA-AES256-GCM-SHA384 -sI https://${TARGET} -o /dev/null -w 'Cipher test: HTTP %{http_code}\n'"
echo ""

# 8. Check HSTS header
info "8) Check HSTS (HTTP Strict Transport Security) header"
echo "   curl -sI https://${TARGET} | grep -i strict-transport-security"
json_add_example "8) Check HSTS (HTTP Strict Transport Security) header" \
    "curl -sI https://${TARGET} | grep -i strict-transport-security"
echo ""

# 9. Verify cert vs skip verification
info "9) Compare with vs without certificate verification"
echo "   curl -sI https://${TARGET} -o /dev/null -w 'With verify: HTTP %{http_code}\n'"
echo "   curl -sI -k https://${TARGET} -o /dev/null -w 'Skip verify: HTTP %{http_code}\n'"
json_add_example "9) Compare with vs without certificate verification" \
    "curl -sI https://${TARGET} -o /dev/null -w 'With verify: HTTP %{http_code}\n'"
echo ""

# 10. Check OCSP stapling
info "10) Check OCSP stapling status"
echo "    curl -v https://${TARGET} 2>&1 | grep -i 'OCSP'"
json_add_example "10) Check OCSP stapling status" \
    "curl -v https://${TARGET} 2>&1 | grep -i 'OCSP'"
echo ""

json_finalize

# Interactive demo (skip if non-interactive)
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    [[ ! -t 0 ]] && exit 0

    read -rp "Check SSL certificate for ${TARGET} now? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        info "Running: curl -vI https://${TARGET} 2>&1 | grep -E 'subject:|issuer:|expire|SSL connection'"
        echo ""
        curl -vI "https://${TARGET}" 2>&1 | grep -E "subject:|issuer:|expire|SSL connection"
    fi
fi
