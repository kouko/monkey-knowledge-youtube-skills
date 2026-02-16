#!/bin/bash
# _ensure_jq.sh - Ensure jq is available (detection only, no auto-download)
#
# Checks for jq in:
#   1. System PATH
#   2. bin/ directory
#
# Does NOT auto-download. If jq is not found, outputs error JSON with download info.
#
# Usage:
#   source "$(dirname "$0")/_ensure_jq.sh"
#   if [ -n "$JQ_ERROR_JSON" ]; then
#       echo "$JQ_ERROR_JSON"
#       exit 1
#   fi
#   "$JQ" --version
#
# Exit codes:
#   0 - jq found (JQ variable is set)
#   1 - jq not found (JQ_ERROR_JSON is set)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$SCRIPT_DIR/../bin"

# Initialize
JQ=""
JQ_ERROR_JSON=""
_JQ_EXIT_CODE=0

# Detect platform for binary name
get_jq_binary_name() {
    local os arch
    os="$(uname -s)"
    arch="$(uname -m)"

    case "$os" in
        Darwin)
            case "$arch" in
                x86_64)  echo "jq-macos-amd64" ;;
                arm64)   echo "jq-macos-arm64" ;;
                *)       echo "" ;;
            esac
            ;;
        Linux)
            case "$arch" in
                x86_64)       echo "jq-linux-amd64" ;;
                aarch64|arm64) echo "jq-linux-arm64" ;;
                *)            echo "" ;;
            esac
            ;;
        MINGW*|CYGWIN*|MSYS*)
            echo "jq-win64.exe"
            ;;
        *)
            echo ""
            ;;
    esac
}

find_jq() {
    # 1. Check system jq
    if command -v jq &> /dev/null; then
        echo "$(command -v jq)"
        return 0
    fi

    # 2. Check bin/ directory
    local binary_name binary_path
    binary_name=$(get_jq_binary_name)

    if [ -n "$binary_name" ] && [ -x "$BIN_DIR/$binary_name" ]; then
        echo "$BIN_DIR/$binary_name"
        return 0
    fi

    # Not found
    return 1
}

# Try to find jq
if JQ=$(find_jq); then
    _JQ_EXIT_CODE=0
else
    # jq not found - prepare error info
    JQ_ERROR_JSON=$(cat <<EOF
{
    "error_code": "JQ_NOT_FOUND",
    "message": "jq not found. Please install it first.",
    "download_command": "$SCRIPT_DIR/_utility__download_jq.sh"
}
EOF
)
    _JQ_EXIT_CODE=1
fi

# Export results
export JQ
export JQ_ERROR_JSON

# Return/exit with appropriate code
if [ $_JQ_EXIT_CODE -ne 0 ]; then
    return $_JQ_EXIT_CODE 2>/dev/null || exit $_JQ_EXIT_CODE
fi
