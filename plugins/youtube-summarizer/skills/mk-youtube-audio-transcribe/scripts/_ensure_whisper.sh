#!/bin/bash
# _ensure_whisper.sh - Ensure whisper-cli is available
#
# Checks for whisper-cli in:
#   1. System PATH
#   2. Package manager (Homebrew only: whisper-cpp)
#   3. bin/ directory
#
# Note: whisper-cpp is only available in Homebrew (macOS).
# For Linux, use ./scripts/_build_whisper.sh to build from source.
#
# Environment variables:
#   MK_AUTO_INSTALL=1      - Skip confirmation, auto-install via package manager
#   MK_SKIP_PKG_MANAGER=1  - Skip package manager, use bin/ only
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

# --- Package Manager Support (Homebrew only for whisper-cpp) ---

_try_pkg_install_whisper() {
    # whisper-cpp is only available in Homebrew
    if ! command -v brew &>/dev/null; then
        return 1
    fi

    # Auto-install mode
    if [ "${MK_AUTO_INSTALL:-}" = "1" ]; then
        echo "[INFO] Auto-installing whisper-cpp via brew..." >&2
        brew install whisper-cpp >&2
        return $?
    fi

    # Interactive confirmation
    echo -n "Install whisper-cpp via brew? [y/N] " >&2
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        brew install whisper-cpp >&2
        return $?
    fi
    return 1
}

# --- Main Logic ---

find_whisper() {
    # 1. Prefer system-installed whisper-cli
    if command -v whisper-cli &> /dev/null; then
        echo "whisper-cli"
        return 0
    fi

    # 2. Try Homebrew install (unless skipped)
    if [ "${MK_SKIP_PKG_MANAGER:-}" != "1" ]; then
        if _try_pkg_install_whisper; then
            if command -v whisper-cli &> /dev/null; then
                echo "whisper-cli"
                return 0
            fi
        fi
    fi

    # 3. Check pre-built binary in bin/
    local binary_path="$BIN_DIR/whisper-cli"
    if [ -x "$binary_path" ]; then
        echo "$binary_path"
        return 0
    fi

    # 4. Not available
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
    "message": "whisper-cli not found. Please install it first.",
    "install_command": "brew install whisper-cpp",
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
