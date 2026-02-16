#!/bin/bash
# _ensure_whisper.sh - Ensure whisper-cli is available
#
# Checks for whisper-cli in:
#   1. System PATH
#   2. bin/ directory (platform-specific binary)
#
# Usage:
#   source "$(dirname "$0")/_ensure_whisper.sh"
#   if [ -n "$WHISPER_ERROR_JSON" ]; then
#       echo "$WHISPER_ERROR_JSON"
#       exit 1
#   fi
#   "$WHISPER" --help
#
# Exit codes:
#   0 - whisper-cli found (WHISPER variable is set)
#   1 - whisper-cli not found (WHISPER_ERROR_JSON is set)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$SCRIPT_DIR/../bin"

# Initialize
WHISPER=""
WHISPER_ERROR_JSON=""
_WHISPER_EXIT_CODE=0

# --- Platform Detection ---

get_whisper_binary_name() {
    local os arch
    os="$(uname -s | tr '[:upper:]' '[:lower:]')"
    arch="$(uname -m)"

    # Normalize arch names
    case "$arch" in
        x86_64)        arch="amd64" ;;
        arm64|aarch64) arch="arm64" ;;
        *)             echo ""; return 1 ;;
    esac

    echo "whisper-cli-${os}-${arch}"
}

# --- Main Logic ---

find_whisper() {
    # 1. Prefer system-installed whisper-cli
    if command -v whisper-cli &> /dev/null; then
        echo "whisper-cli"
        return 0
    fi

    # 2. Check pre-built binary in bin/ (with platform suffix)
    local binary_name="$(get_whisper_binary_name)"
    if [ -n "$binary_name" ]; then
        local binary_path="$BIN_DIR/$binary_name"
        if [ -x "$binary_path" ]; then
            echo "$binary_path"
            return 0
        fi
    fi

    # 3. Not available
    return 1
}

# Try to find whisper-cli
if WHISPER=$(find_whisper); then
    _WHISPER_EXIT_CODE=0
else
    # whisper-cli not found - prepare error info
    WHISPER_ERROR_JSON=$(cat <<EOF
{
    "error_code": "WHISPER_NOT_FOUND",
    "message": "whisper-cli not found. Please build or download it first.",
    "build_command": "$SCRIPT_DIR/_build_whisper.sh"
}
EOF
)
    _WHISPER_EXIT_CODE=1
fi

# Export results
export WHISPER
export WHISPER_ERROR_JSON

# Return/exit with appropriate code
if [ $_WHISPER_EXIT_CODE -ne 0 ]; then
    return $_WHISPER_EXIT_CODE 2>/dev/null || exit $_WHISPER_EXIT_CODE
fi
