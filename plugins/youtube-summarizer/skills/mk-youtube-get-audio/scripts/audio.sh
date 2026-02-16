#!/bin/bash
set -e

# Load dependency scripts
source "$(dirname "$0")/_utility__ensure_ytdlp.sh"
source "$(dirname "$0")/_utility__ensure_jq.sh"
source "$(dirname "$0")/_utility__naming.sh"

URL="$1"
OUTPUT_DIR="${2:-$MONKEY_KNOWLEDGE_TMP/youtube/audio}"
BROWSER="${3:-}"  # Optional: specify browser (chrome, firefox, safari, etc.)

if [ -z "$URL" ]; then
    "$JQ" -n '{status: "error", message: "Usage: audio.sh <url> [output_dir] [browser]"}'
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

# Get video ID, title, and upload_date for unified naming
VIDEO_ID=$("$YT_DLP" --print id "$URL" 2>/dev/null)
TITLE=$("$YT_DLP" --print title "$URL" 2>/dev/null)
UPLOAD_DATE=$("$YT_DLP" --print upload_date "$URL" 2>/dev/null)

if [ -z "$VIDEO_ID" ]; then
    "$JQ" -n --arg status "error" \
        --arg message "Could not extract video ID from URL" \
        '{status: $status, message: $message}'
    exit 1
fi

BASENAME=$(make_basename "$UPLOAD_DATE" "$VIDEO_ID" "$TITLE")

# Read existing metadata or create entry
EXISTING_META=$(read_meta "$VIDEO_ID")
if [ -z "$EXISTING_META" ]; then
    # Fetch metadata for centralized store
    CHANNEL=$("$YT_DLP" --print channel "$URL" 2>/dev/null || echo "")
    DURATION=$("$YT_DLP" --print duration_string "$URL" 2>/dev/null || echo "")
    WEBPAGE_URL=$("$YT_DLP" --print webpage_url "$URL" 2>/dev/null || echo "$URL")

    META_JSON=$("$JQ" -n \
        --arg video_id "$VIDEO_ID" \
        --arg title "$TITLE" \
        --arg channel "$CHANNEL" \
        --arg url "$WEBPAGE_URL" \
        --arg upload_date "$UPLOAD_DATE" \
        --arg duration_string "$DURATION" \
        --arg source "audio" \
        '{
            video_id: $video_id,
            title: $title,
            channel: $channel,
            url: $url,
            upload_date: $upload_date,
            duration_string: $duration_string,
            source: $source,
            partial: true,
            fetched_at: (now | todate)
        }')

    write_or_merge_meta "$META_DIR/$BASENAME.meta.json" "$META_JSON" "true"
    EXISTING_META="$META_JSON"
fi

# Clean up old files for this video (supports new date-prefixed format)
rm -f "$OUTPUT_DIR/"*"__${VIDEO_ID}__"*.{m4a,webm,opus,ogg,mp3,aac,wav} 2>/dev/null || true

# Create temp directory for download
TEMP_DIR=$(mktemp -d)

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

    # Download to temp directory first, then rename
    # shellcheck disable=SC2086
    "$YT_DLP" -x -o "$TEMP_DIR/%(id)s.%(ext)s" $cookie_args "$URL" 2>&1
}

# First attempt: without authentication
if ! download_audio "false" >&2; then
    echo "[INFO] First attempt failed, retrying with browser cookies..." >&2

    # Second attempt: with browser cookies
    if ! download_audio "true" >&2; then
        rm -rf "$TEMP_DIR"
        "$JQ" -n '{status: "error", message: "Download failed (tried with and without cookies)"}'
        exit 1
    fi
fi

# Find the downloaded file in temp directory (any audio format)
TEMP_FILE=$(ls -t "$TEMP_DIR"/*.{m4a,webm,opus,ogg,mp3,aac,wav} 2>/dev/null | head -1)

if [ -n "$TEMP_FILE" ] && [ -f "$TEMP_FILE" ]; then
    # Get the extension from the downloaded file
    EXT="${TEMP_FILE##*.}"

    # Rename to unified format: {id}__{title}.{ext}
    AUDIO_FILE="$OUTPUT_DIR/${BASENAME}.${EXT}"
    mv "$TEMP_FILE" "$AUDIO_FILE"

    # Clean up temp directory
    rm -rf "$TEMP_DIR"

    # Extract metadata fields for output
    META_VIDEO_ID=$(echo "$EXISTING_META" | "$JQ" -r '.video_id // empty')
    META_TITLE=$(echo "$EXISTING_META" | "$JQ" -r '.title // empty')
    META_CHANNEL=$(echo "$EXISTING_META" | "$JQ" -r '.channel // empty')
    META_URL=$(echo "$EXISTING_META" | "$JQ" -r '.url // empty')
    META_DURATION=$(echo "$EXISTING_META" | "$JQ" -r '.duration_string // empty')

    "$JQ" -n \
        --arg status "success" \
        --arg file_path "$AUDIO_FILE" \
        --arg file_size "$(ls -lh "$AUDIO_FILE" | awk '{print $5}')" \
        --arg video_id "$META_VIDEO_ID" \
        --arg title "$META_TITLE" \
        --arg channel "$META_CHANNEL" \
        --arg url "$META_URL" \
        --arg duration_string "$META_DURATION" \
        '{
            status: $status,
            file_path: $file_path,
            file_size: $file_size,
            video_id: $video_id,
            title: $title,
            channel: $channel,
            url: $url,
            duration_string: $duration_string
        }'
else
    rm -rf "$TEMP_DIR"
    "$JQ" -n '{status: "error", message: "Download completed but file not found"}'
    exit 1
fi
