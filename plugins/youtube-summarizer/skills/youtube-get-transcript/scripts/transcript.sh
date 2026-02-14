#!/bin/bash
set -e

source "$(dirname "$0")/_ensure_ytdlp.sh"
source "$(dirname "$0")/_ensure_jq.sh"

URL="$1"
LANG="${2:-}"  # Empty means auto-detect original language
OUTPUT_DIR="/tmp/youtube-transcripts"

if [ -z "$URL" ]; then
    echo "Usage: transcript.sh <url> [lang|auto]"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

# Clean up old files
rm -f "$OUTPUT_DIR"/*.srt "$OUTPUT_DIR"/*.txt 2>/dev/null || true

# If no language specified, get video's original language
if [ -z "$LANG" ] || [ "$LANG" = "auto" ]; then
    LANG=$("$YT_DLP" --print "%(language)s" "$URL" 2>/dev/null || echo "")
    # If detection failed, use default priority
    if [ -z "$LANG" ] || [ "$LANG" = "NA" ] || [ "$LANG" = "null" ]; then
        LANG="en,ja,zh-TW,zh-Hant"
    fi
fi

# First try to download manual (author-uploaded) subtitles
"$YT_DLP" --write-subs \
          --sub-lang "$LANG" \
          --skip-download --convert-subs srt \
          -o "$OUTPUT_DIR/%(id)s" "$URL" >&2 || true

SRT_FILE=$(ls -t "$OUTPUT_DIR"/*.srt 2>/dev/null | head -1)
SUBTITLE_TYPE="manual"

# If no manual subtitles found, try auto-generated
if [ -z "$SRT_FILE" ] || [ ! -f "$SRT_FILE" ]; then
    "$YT_DLP" --write-auto-subs \
              --sub-lang "$LANG" \
              --skip-download --convert-subs srt \
              -o "$OUTPUT_DIR/%(id)s" "$URL" >&2 || true

    SRT_FILE=$(ls -t "$OUTPUT_DIR"/*.srt 2>/dev/null | head -1)
    SUBTITLE_TYPE="auto-generated"
fi

if [ -n "$SRT_FILE" ] && [ -f "$SRT_FILE" ]; then
    # Extract language from filename (e.g., VIDEO_ID.en.srt -> en)
    DETECTED_LANG=$(basename "$SRT_FILE" | sed 's/.*\.\([^.]*\)\.srt$/\1/')

    # Generate plain text version (remove sequence numbers, timestamps, empty lines)
    TEXT_FILE="${SRT_FILE%.srt}.txt"
    sed '/^[0-9]*$/d; /-->/d; /^[[:space:]]*$/d' "$SRT_FILE" | uniq > "$TEXT_FILE"

    # Get SRT file statistics
    CHAR_COUNT=$(wc -c < "$SRT_FILE" | tr -d ' ')
    LINE_COUNT=$(wc -l < "$SRT_FILE" | tr -d ' ')

    # Get text file statistics
    TEXT_CHAR_COUNT=$(wc -c < "$TEXT_FILE" | tr -d ' ')
    TEXT_LINE_COUNT=$(wc -l < "$TEXT_FILE" | tr -d ' ')

    # Output JSON with both file paths
    "$JQ" -n \
        --arg status "success" \
        --arg file_path "$SRT_FILE" \
        --arg text_file_path "$TEXT_FILE" \
        --arg language "$DETECTED_LANG" \
        --arg subtitle_type "$SUBTITLE_TYPE" \
        --argjson char_count "$CHAR_COUNT" \
        --argjson line_count "$LINE_COUNT" \
        --argjson text_char_count "$TEXT_CHAR_COUNT" \
        --argjson text_line_count "$TEXT_LINE_COUNT" \
        '{status: $status, file_path: $file_path, text_file_path: $text_file_path, language: $language, subtitle_type: $subtitle_type, char_count: $char_count, line_count: $line_count, text_char_count: $text_char_count, text_line_count: $text_line_count}'
else
    "$JQ" -n \
        --arg status "error" \
        --arg message "No subtitles found (this video may not have subtitles)" \
        '{status: $status, message: $message}'
    exit 1
fi
