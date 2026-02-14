#!/bin/bash
# _ensure_jq.sh - Ensure jq is available
#
# Priority:
#   1. System-installed jq
#   2. Previously downloaded binary in bin/
#   3. Auto-download platform-specific binary
#
# Usage:
#   source "$(dirname "$0")/_ensure_jq.sh"
#   "$JQ" --version

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$SCRIPT_DIR/../bin"

# Download URL template (jq 1.7.1)
JQ_RELEASE_URL="https://github.com/jqlang/jq/releases/download/jq-1.7.1"

get_jq() {
    # 1. Prefer system-installed jq
    if command -v jq &> /dev/null; then
        echo "jq"
        return 0
    fi

    # 2. Detect platform and CPU architecture
    local os arch binary_name download_url

    os="$(uname -s)"
    arch="$(uname -m)"

    case "$os" in
        Darwin)
            case "$arch" in
                x86_64)
                    binary_name="jq-macos-amd64"
                    download_url="$JQ_RELEASE_URL/jq-macos-amd64"
                    ;;
                arm64)
                    binary_name="jq-macos-arm64"
                    download_url="$JQ_RELEASE_URL/jq-macos-arm64"
                    ;;
                *)
                    echo "ERROR: Unsupported macOS architecture: $arch" >&2
                    exit 1
                    ;;
            esac
            ;;
        Linux)
            case "$arch" in
                x86_64)
                    binary_name="jq-linux-amd64"
                    download_url="$JQ_RELEASE_URL/jq-linux-amd64"
                    ;;
                aarch64|arm64)
                    binary_name="jq-linux-arm64"
                    download_url="$JQ_RELEASE_URL/jq-linux-arm64"
                    ;;
                *)
                    echo "ERROR: Unsupported Linux architecture: $arch" >&2
                    exit 1
                    ;;
            esac
            ;;
        MINGW*|CYGWIN*|MSYS*)
            binary_name="jq-win64.exe"
            download_url="$JQ_RELEASE_URL/jq-win64.exe"
            ;;
        *)
            echo "ERROR: Unsupported platform: $os" >&2
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
    echo "jq not installed, downloading for $os/$arch..." >&2
    mkdir -p "$BIN_DIR"

    if command -v curl &> /dev/null; then
        curl -L -o "$binary_path" "$download_url" >&2
    elif command -v wget &> /dev/null; then
        wget -O "$binary_path" "$download_url" >&2
    else
        echo "ERROR: curl or wget required to download jq" >&2
        exit 1
    fi

    # 5. Set execute permission
    chmod +x "$binary_path"
    echo "jq downloaded: $binary_path" >&2

    echo "$binary_path"
}

# Get jq path
JQ="$(get_jq)"
