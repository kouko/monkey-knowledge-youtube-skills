#!/bin/bash
set -e

# Load dependency scripts
source "$(dirname "$0")/_ensure_ytdlp.sh"
source "$(dirname "$0")/_ensure_jq.sh"

URL="$1"
OUTPUT_DIR="${2:-/tmp/youtube-audio}"

if [ -z "$URL" ]; then
    echo "Usage: audio.sh <url> [output_dir]"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

# Download audio (progress to stderr)
# Uses best available audio format without conversion (no ffmpeg required)
"$YT_DLP" -x -o "$OUTPUT_DIR/%(title)s.%(ext)s" "$URL" >&2

# Find the downloaded file (any audio format: m4a, webm, opus, etc.)
AUDIO_FILE=$(ls -t "$OUTPUT_DIR"/*.{m4a,webm,opus,ogg,mp3,aac,wav} 2>/dev/null | head -1)

if [ -n "$AUDIO_FILE" ] && [ -f "$AUDIO_FILE" ]; then
    # Output JSON for LLM parsing
    "$JQ" -n \
        --arg status "success" \
        --arg file_path "$AUDIO_FILE" \
        --arg file_size "$(ls -lh "$AUDIO_FILE" | awk '{print $5}')" \
        '{status: $status, file_path: $file_path, file_size: $file_size}'
else
    "$JQ" -n \
        --arg status "error" \
        --arg message "Download failed or file not found" \
        '{status: $status, message: $message}'
    exit 1
fi
