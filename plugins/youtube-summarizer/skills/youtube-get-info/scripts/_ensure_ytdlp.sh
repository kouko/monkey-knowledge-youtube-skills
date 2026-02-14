#!/bin/bash
# _ensure_ytdlp.sh - Ensure yt-dlp is available
#
# Priority:
#   1. System-installed yt-dlp
#   2. Previously downloaded binary in bin/
#   3. Auto-download platform-specific binary
#
# Usage:
#   source "$(dirname "$0")/_ensure_ytdlp.sh"
#   "$YT_DLP" --version

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$SCRIPT_DIR/../bin"

# Download URL template
YT_DLP_RELEASE_URL="https://github.com/yt-dlp/yt-dlp/releases/latest/download"

get_ytdlp() {
    # 1. Prefer system-installed yt-dlp
    if command -v yt-dlp &> /dev/null; then
        echo "yt-dlp"
        return 0
    fi

    # 2. Detect platform
    local platform binary_name download_url
    case "$(uname -s)" in
        Darwin)
            platform="macos"
            binary_name="yt-dlp-macos"
            download_url="$YT_DLP_RELEASE_URL/yt-dlp_macos"
            ;;
        Linux)
            platform="linux"
            binary_name="yt-dlp-linux"
            download_url="$YT_DLP_RELEASE_URL/yt-dlp_linux"
            ;;
        MINGW*|CYGWIN*|MSYS*)
            platform="windows"
            binary_name="yt-dlp.exe"
            download_url="$YT_DLP_RELEASE_URL/yt-dlp.exe"
            ;;
        *)
            echo "ERROR: Unsupported platform: $(uname -s)" >&2
            exit 1
            ;;
    esac

    local binary_path="$BIN_DIR/$binary_name"

    # 3. Check if already downloaded
    if [ -x "$binary_path" ]; then
        echo "$binary_path"
        return 0
    fi

    # 4. Download binary
    echo "yt-dlp not installed, downloading $platform version..." >&2
    mkdir -p "$BIN_DIR"

    if command -v curl &> /dev/null; then
        curl -L -o "$binary_path" "$download_url" >&2
    elif command -v wget &> /dev/null; then
        wget -O "$binary_path" "$download_url" >&2
    else
        echo "ERROR: curl or wget required to download yt-dlp" >&2
        exit 1
    fi

    # 5. Set execute permission
    chmod +x "$binary_path"
    echo "yt-dlp downloaded: $binary_path" >&2

    echo "$binary_path"
}

# Get yt-dlp path
YT_DLP="$(get_ytdlp)"
