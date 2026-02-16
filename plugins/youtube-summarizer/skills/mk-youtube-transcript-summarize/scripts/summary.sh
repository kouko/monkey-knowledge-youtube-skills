#!/bin/bash
set -e

# Load dependencies
source "$(dirname "$0")/_utility__ensure_jq.sh"
source "$(dirname "$0")/_utility__naming.sh"

FILE_PATH="$1"

if [ -z "$FILE_PATH" ]; then
    "$JQ" -n --arg status "error" \
        --arg message "Usage: summary.sh <transcript_file_path>" \
        '{status: $status, message: $message}'
    exit 1
fi

if [ ! -f "$FILE_PATH" ]; then
    "$JQ" -n --arg status "error" \
        --arg message "File not found: $FILE_PATH" \
        '{status: $status, message: $message}'
    exit 1
fi

# Resolve absolute path
ABS_PATH="$(cd "$(dirname "$FILE_PATH")" && pwd)/$(basename "$FILE_PATH")"
CHAR_COUNT=$(wc -c < "$FILE_PATH" | tr -d ' ')
LINE_COUNT=$(wc -l < "$FILE_PATH" | tr -d ' ')

# Determine processing strategy based on content size
if [ "$CHAR_COUNT" -lt 80000 ]; then
    STRATEGY="standard"
elif [ "$CHAR_COUNT" -lt 200000 ]; then
    STRATEGY="sectioned"
else
    STRATEGY="chunked"
fi

# Calculate output summary path
BASENAME=$(basename "$ABS_PATH")
BASENAME_NO_EXT="${BASENAME%.*}"
OUTPUT_SUMMARY="$MONKEY_KNOWLEDGE_TMP/youtube/summaries/${BASENAME_NO_EXT}.md"

# Extract video ID from filename (format: {YYYYMMDD}__{id}__{title}.{lang}.{ext})
# Video ID is extracted from position 10-20 (after the date prefix)
VIDEO_ID=""
if [[ "$BASENAME_NO_EXT" == *"__"* ]]; then
    VIDEO_ID=$(extract_video_id_from_basename "$BASENAME_NO_EXT")
fi

# Read metadata from centralized store (if available)
META_VIDEO_ID=""
META_TITLE=""
META_CHANNEL=""
META_URL=""
if [ -n "$VIDEO_ID" ]; then
    EXISTING_META=$(read_meta "$VIDEO_ID")
    if [ -n "$EXISTING_META" ]; then
        META_VIDEO_ID=$(echo "$EXISTING_META" | "$JQ" -r '.video_id // empty')
        META_TITLE=$(echo "$EXISTING_META" | "$JQ" -r '.title // empty')
        META_CHANNEL=$(echo "$EXISTING_META" | "$JQ" -r '.channel // empty')
        META_URL=$(echo "$EXISTING_META" | "$JQ" -r '.url // empty')
    fi
fi

"$JQ" -n \
    --arg status "success" \
    --arg source_transcript "$ABS_PATH" \
    --arg output_summary "$OUTPUT_SUMMARY" \
    --argjson char_count "$CHAR_COUNT" \
    --argjson line_count "$LINE_COUNT" \
    --arg strategy "$STRATEGY" \
    --arg video_id "$META_VIDEO_ID" \
    --arg title "$META_TITLE" \
    --arg channel "$META_CHANNEL" \
    --arg url "$META_URL" \
    '{
        status: $status,
        source_transcript: $source_transcript,
        output_summary: $output_summary,
        char_count: $char_count,
        line_count: $line_count,
        strategy: $strategy,
        video_id: $video_id,
        title: $title,
        channel: $channel,
        url: $url
    }'
