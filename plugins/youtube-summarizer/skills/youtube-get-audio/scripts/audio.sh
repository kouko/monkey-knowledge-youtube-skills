#!/bin/bash
set -e

# Load dependency scripts
source "$(dirname "$0")/_ensure_ytdlp.sh"
source "$(dirname "$0")/_ensure_jq.sh"

URL="$1"
OUTPUT_DIR="${2:-/tmp/youtube-audio}"
BROWSER="${3:-}"  # Optional: specify browser (chrome, firefox, safari, etc.)

if [ -z "$URL" ]; then
    "$JQ" -n '{status: "error", message: "Usage: audio.sh <url> [output_dir] [browser]"}'
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

# Get Chrome profiles directory based on OS
get_chrome_dir() {
    case "$(uname)" in
        Darwin) echo "$HOME/Library/Application Support/Google/Chrome" ;;
        Linux)  echo "$HOME/.config/google-chrome" ;;
        *)      echo "" ;;  # Windows needs different handling
    esac
}

# Try browser cookies and return the working browser string
try_browser_cookies() {
    local browser="$1"

    # For Chrome without specific profile, try all profiles
    if [[ "$browser" == "chrome" ]]; then
        local chrome_dir
        chrome_dir=$(get_chrome_dir)
        if [ -d "$chrome_dir" ]; then
            # Try Default profile first
            if "$YT_DLP" --cookies-from-browser "chrome:Default" --simulate "$URL" >/dev/null 2>&1; then
                echo "chrome:Default"
                return 0
            fi
            # Try other profiles
            for profile_dir in "$chrome_dir"/Profile*/; do
                if [ -d "$profile_dir" ]; then
                    local profile_name
                    profile_name=$(basename "$profile_dir")
                    if "$YT_DLP" --cookies-from-browser "chrome:$profile_name" --simulate "$URL" >/dev/null 2>&1; then
                        echo "chrome:$profile_name"
                        return 0
                    fi
                fi
            done
        fi
    fi

    # Non-Chrome or all Chrome profiles failed
    if "$YT_DLP" --cookies-from-browser "$browser" --simulate "$URL" >/dev/null 2>&1; then
        echo "$browser"
        return 0
    fi
    return 1
}

# Download audio with optional cookie authentication
download_audio() {
    local use_cookies="$1"
    local cookie_args=""

    if [ "$use_cookies" = "true" ] && [ -n "$BROWSER" ]; then
        cookie_args="--cookies-from-browser $BROWSER"
    elif [ "$use_cookies" = "true" ]; then
        # Auto-detect available browser (Chrome tries all profiles)
        for browser in chrome firefox safari edge brave; do
            local found_browser
            if found_browser=$(try_browser_cookies "$browser"); then
                cookie_args="--cookies-from-browser $found_browser"
                echo "[INFO] Using cookies from: $found_browser" >&2
                break
            fi
        done
    fi

    # shellcheck disable=SC2086
    "$YT_DLP" -x -o "$OUTPUT_DIR/%(title)s.%(ext)s" $cookie_args "$URL" 2>&1
}

# First attempt: without authentication
if ! download_audio "false" >&2; then
    echo "[INFO] First attempt failed, retrying with browser cookies..." >&2

    # Second attempt: with browser cookies
    if ! download_audio "true" >&2; then
        "$JQ" -n '{status: "error", message: "Download failed (tried with and without cookies)"}'
        exit 1
    fi
fi

# Find the downloaded file (any audio format)
AUDIO_FILE=$(ls -t "$OUTPUT_DIR"/*.{m4a,webm,opus,ogg,mp3,aac,wav} 2>/dev/null | head -1)

if [ -n "$AUDIO_FILE" ] && [ -f "$AUDIO_FILE" ]; then
    "$JQ" -n \
        --arg status "success" \
        --arg file_path "$AUDIO_FILE" \
        --arg file_size "$(ls -lh "$AUDIO_FILE" | awk '{print $5}')" \
        '{status: $status, file_path: $file_path, file_size: $file_size}'
else
    "$JQ" -n '{status: "error", message: "Download completed but file not found"}'
    exit 1
fi
