#!/bin/bash
# _download_ffmpeg.sh - Download ffmpeg binary for macOS
#
# Downloads ffmpeg from martin-riedl.de (signed & notarized)
# Supports both Apple Silicon (arm64) and Intel (x86_64)
#
# Usage:
#   ./scripts/_download_ffmpeg.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$SCRIPT_DIR/../bin"

# Only support macOS
if [ "$(uname -s)" != "Darwin" ]; then
    echo "ERROR: This script is for macOS only" >&2
    exit 1
fi

# Detect architecture
get_arch() {
    local arch
    arch=$(uname -m)
    case "$arch" in
        arm64)
            echo "arm64"
            ;;
        x86_64)
            echo "amd64"
            ;;
        *)
            echo "ERROR: Unsupported architecture: $arch" >&2
            exit 1
            ;;
    esac
}

download_ffmpeg() {
    local arch
    arch=$(get_arch)

    echo "[INFO] Detected architecture: $arch" >&2
    echo "[INFO] Downloading ffmpeg..." >&2
    mkdir -p "$BIN_DIR"

    local temp_dir="/tmp/ffmpeg-download-$$"
    mkdir -p "$temp_dir"

    # Download from martin-riedl.de (signed & notarized)
    local download_url="https://ffmpeg.martin-riedl.de/redirect/latest/macos/${arch}/snapshot/ffmpeg.zip"

    echo "[INFO] Downloading from martin-riedl.de ($arch)..." >&2
    curl -L -o "$temp_dir/ffmpeg.zip" "$download_url"

    echo "[INFO] Extracting..." >&2
    unzip -q "$temp_dir/ffmpeg.zip" -d "$temp_dir"

    # Find and copy the binary
    local ffmpeg_bin
    ffmpeg_bin=$(find "$temp_dir" -name "ffmpeg" -type f -perm +111 | head -1)

    if [ -z "$ffmpeg_bin" ]; then
        echo "ERROR: ffmpeg binary not found in archive" >&2
        rm -rf "$temp_dir"
        exit 1
    fi

    cp "$ffmpeg_bin" "$BIN_DIR/ffmpeg"
    chmod +x "$BIN_DIR/ffmpeg"

    echo "[INFO] Cleaning up..." >&2
    rm -rf "$temp_dir"

    echo "[INFO] ffmpeg installed: $BIN_DIR/ffmpeg" >&2
    echo "[INFO] Architecture: $arch (native)" >&2
}

download_ffmpeg

echo "[SUCCESS] Download complete!" >&2
"$BIN_DIR/ffmpeg" -version 2>&1 | head -1
