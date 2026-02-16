#!/bin/bash
# _ensure_ytdlp.sh - Ensure yt-dlp is available
#
# Checks for yt-dlp in:
#   1. System PATH
#   2. Package manager (brew/apt/dnf) - interactive install
#   3. bin/ directory
#
# Environment variables:
#   MK_AUTO_INSTALL=1      - Skip confirmation, auto-install via package manager
#   MK_SKIP_PKG_MANAGER=1  - Skip package manager, use bin/ only
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

# --- Platform Detection ---

# Get platform-specific binary name (local build)
get_ytdlp_platform_binary_name() {
    local os arch
    os="$(uname -s)"
    arch="$(uname -m)"

    # Normalize OS names
    case "$os" in
        Darwin)               os="darwin" ;;
        Linux)                os="linux" ;;
        MINGW*|CYGWIN*|MSYS*) os="windows" ;;
        *)                    echo ""; return 1 ;;
    esac

    # Normalize arch names
    case "$arch" in
        x86_64)        arch="amd64" ;;
        arm64|aarch64) arch="arm64" ;;
        i686|i386)     arch="386" ;;
        *)             echo ""; return 1 ;;
    esac

    echo "yt-dlp-${os}-${arch}"
}

# Get universal binary name (official release)
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

    # 2. Try package manager install (unless skipped)
    if [ "${MK_SKIP_PKG_MANAGER:-}" != "1" ]; then
        if _try_pkg_install "yt-dlp"; then
            if command -v yt-dlp &> /dev/null; then
                echo "$(command -v yt-dlp)"
                return 0
            fi
        fi
    fi

    # 3. Check bin/ directory - platform-specific binary first (smaller)
    local platform_binary_name
    platform_binary_name=$(get_ytdlp_platform_binary_name)
    if [ -n "$platform_binary_name" ] && [ -x "$BIN_DIR/$platform_binary_name" ]; then
        echo "$BIN_DIR/$platform_binary_name"
        return 0
    fi

    # 4. Check bin/ directory - universal binary (official release)
    local binary_name
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
    "install_command": "brew install yt-dlp",
    "download_command": "$SCRIPT_DIR/_utility__download_ytdlp.sh",
    "build_command": "$SCRIPT_DIR/_utility__build_ytdlp.sh"
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
