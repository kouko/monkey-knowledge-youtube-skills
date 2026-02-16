#!/bin/bash
# _ensure_ffmpeg.sh - Ensure ffmpeg is available
#
# Checks for ffmpeg in:
#   1. System PATH
#   2. Package manager (brew/apt/dnf) - interactive install
#   3. bin/ directory
#
# Environment variables:
#   MK_AUTO_INSTALL=1      - Skip confirmation, auto-install via package manager
#   MK_SKIP_PKG_MANAGER=1  - Skip package manager, use bin/ only
#
# Usage:
#   source "$(dirname "$0")/_ensure_ffmpeg.sh"
#   if [ -n "$FFMPEG_ERROR_JSON" ]; then
#       echo "$FFMPEG_ERROR_JSON"
#       exit 1
#   fi
#   "$FFMPEG" -version
#
# Exit codes:
#   0 - ffmpeg found (FFMPEG variable is set)
#   1 - ffmpeg not found (FFMPEG_ERROR_JSON is set)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$SCRIPT_DIR/../bin"

# Initialize
FFMPEG=""
FFMPEG_ERROR_JSON=""
_FFMPEG_EXIT_CODE=0

# --- Package Manager Support ---

_detect_pkg_manager() {
    if command -v brew &>/dev/null; then
        echo "brew"
    elif command -v apt-get &>/dev/null; then
        echo "apt"
    elif command -v dnf &>/dev/null; then
        echo "dnf"
    else
        echo ""
    fi
}

_try_pkg_install() {
    local pkg_name="$1"
    local pkg_manager
    pkg_manager=$(_detect_pkg_manager)

    [ -z "$pkg_manager" ] && return 1

    # Auto-install mode
    if [ "${MK_AUTO_INSTALL:-}" = "1" ]; then
        echo "[INFO] Auto-installing $pkg_name via $pkg_manager..." >&2
        case "$pkg_manager" in
            brew) brew install "$pkg_name" >&2 ;;
            apt)  sudo apt-get install -y "$pkg_name" >&2 ;;
            dnf)  sudo dnf install -y "$pkg_name" >&2 ;;
        esac
        return $?
    fi

    # Interactive confirmation
    local prompt_suffix=""
    [ "$pkg_manager" != "brew" ] && prompt_suffix=" (requires sudo)"

    echo -n "Install $pkg_name via $pkg_manager?$prompt_suffix [y/N] " >&2
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        case "$pkg_manager" in
            brew) brew install "$pkg_name" >&2 ;;
            apt)  sudo apt-get install -y "$pkg_name" >&2 ;;
            dnf)  sudo dnf install -y "$pkg_name" >&2 ;;
        esac
        return $?
    fi
    return 1
}

# --- Main Logic ---

find_ffmpeg() {
    # 1. Prefer system-installed ffmpeg
    if command -v ffmpeg &> /dev/null; then
        echo "ffmpeg"
        return 0
    fi

    # 2. Try package manager install (unless skipped)
    if [ "${MK_SKIP_PKG_MANAGER:-}" != "1" ]; then
        if _try_pkg_install "ffmpeg"; then
            if command -v ffmpeg &> /dev/null; then
                echo "ffmpeg"
                return 0
            fi
        fi
    fi

    # 3. Check pre-built binary in bin/
    local binary_path="$BIN_DIR/ffmpeg"
    if [ -x "$binary_path" ]; then
        echo "$binary_path"
        return 0
    fi

    # 4. Not available
    return 1
}

# Try to find ffmpeg
if FFMPEG=$(find_ffmpeg); then
    _FFMPEG_EXIT_CODE=0
else
    # ffmpeg not found - prepare error info
    FFMPEG_ERROR_JSON=$(cat <<EOF
{
    "error_code": "FFMPEG_NOT_FOUND",
    "message": "ffmpeg not found. Please install it first.",
    "install_command": "brew install ffmpeg",
    "download_command": "$SCRIPT_DIR/_download_ffmpeg.sh"
}
EOF
)
    _FFMPEG_EXIT_CODE=1
fi

# Export results
export FFMPEG
export FFMPEG_ERROR_JSON

# Return/exit with appropriate code
if [ $_FFMPEG_EXIT_CODE -ne 0 ]; then
    return $_FFMPEG_EXIT_CODE 2>/dev/null || exit $_FFMPEG_EXIT_CODE
fi
