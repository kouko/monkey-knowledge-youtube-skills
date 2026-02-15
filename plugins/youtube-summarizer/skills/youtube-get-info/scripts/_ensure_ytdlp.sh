#!/bin/bash
# _ensure_ytdlp.sh - Ensure yt-dlp is available (detection only, no auto-download)
#
# Checks for yt-dlp in:
#   1. System PATH
#   2. bin/ directory
#
# Does NOT auto-download. If yt-dlp is not found, outputs error JSON with download info.
#
# Usage:
#   source "$(dirname "$0")/_ensure_ytdlp.sh"
#   if [ -n "$YTDLP_ERROR_JSON" ]; then
#       echo "$YTDLP_ERROR_JSON"
#       exit 1
#   fi
#   "$YT_DLP" --version
#
# Exit codes:
#   0 - yt-dlp found (YT_DLP variable is set)
#   1 - yt-dlp not found (YTDLP_ERROR_JSON is set)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$SCRIPT_DIR/../bin"

# Initialize
YT_DLP=""
YTDLP_ERROR_JSON=""
_YTDLP_EXIT_CODE=0

# Detect platform for binary name
get_ytdlp_binary_name() {
    local os
    os="$(uname -s)"

    case "$os" in
        Darwin)
            echo "yt-dlp-macos"
            ;;
        Linux)
            echo "yt-dlp-linux"
            ;;
        MINGW*|CYGWIN*|MSYS*)
            echo "yt-dlp.exe"
            ;;
        *)
            echo ""
            ;;
    esac
}

find_ytdlp() {
    # 1. Check system yt-dlp
    if command -v yt-dlp &> /dev/null; then
        echo "$(command -v yt-dlp)"
        return 0
    fi

    # 2. Check bin/ directory
    local binary_name binary_path
    binary_name=$(get_ytdlp_binary_name)

    if [ -n "$binary_name" ] && [ -x "$BIN_DIR/$binary_name" ]; then
        echo "$BIN_DIR/$binary_name"
        return 0
    fi

    # Not found
    return 1
}

# Try to find yt-dlp
if YT_DLP=$(find_ytdlp); then
    _YTDLP_EXIT_CODE=0
else
    # yt-dlp not found - prepare error info
    YTDLP_ERROR_JSON=$(cat <<EOF
{
    "error_code": "YTDLP_NOT_FOUND",
    "message": "yt-dlp not found. Please install it first.",
    "download_command": "$SCRIPT_DIR/_download_ytdlp.sh"
}
EOF
)
    _YTDLP_EXIT_CODE=1
fi

# Export results
export YT_DLP
export YTDLP_ERROR_JSON

# Return/exit with appropriate code
if [ $_YTDLP_EXIT_CODE -ne 0 ]; then
    return $_YTDLP_EXIT_CODE 2>/dev/null || exit $_YTDLP_EXIT_CODE
fi
