#!/bin/bash
set -e

source "$(dirname "$0")/_utility__ensure_ytdlp.sh"
source "$(dirname "$0")/_utility__ensure_jq.sh"
source "$(dirname "$0")/_utility__naming.sh"

URL="$1"
LANG="${2:-}"  # Empty means auto-detect original language
OUTPUT_DIR="$MONKEY_KNOWLEDGE_TMP/youtube/captions"

if [ -z "$URL" ]; then
    "$JQ" -n --arg status "error" \
        --arg message "Usage: caption.sh <url> [lang|auto]" \
        '{status: $status, message: $message}'
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

# Read existing metadata or create minimal entry
EXISTING_META=$(read_meta "$VIDEO_ID")
if [ -z "$EXISTING_META" ]; then
    # Fetch minimal metadata for centralized store
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
        --arg source "caption" \
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
rm -f "$OUTPUT_DIR/"*"__${VIDEO_ID}__"*.srt "$OUTPUT_DIR/"*"__${VIDEO_ID}__"*.txt 2>/dev/null || true

# If no language specified, get video's original language
if [ -z "$LANG" ] || [ "$LANG" = "auto" ]; then
    LANG=$("$YT_DLP" --print "%(language)s" "$URL" 2>/dev/null || echo "")
    # If detection failed, use default priority
    if [ -z "$LANG" ] || [ "$LANG" = "NA" ] || [ "$LANG" = "null" ]; then
        LANG="en,ja,zh-TW,zh-Hant"
    fi
fi

# First try to download manual (author-uploaded) subtitles
# Download to temp location first, then rename
TEMP_DIR=$(mktemp -d)
"$YT_DLP" --write-subs \
          --sub-lang "$LANG" \
          --skip-download --convert-subs srt \
          -o "$TEMP_DIR/%(id)s" "$URL" >&2 || true

TEMP_SRT=$(ls -t "$TEMP_DIR"/*.srt 2>/dev/null | head -1)
SUBTITLE_TYPE="manual"

# If no manual subtitles found, try auto-generated
if [ -z "$TEMP_SRT" ] || [ ! -f "$TEMP_SRT" ]; then
    "$YT_DLP" --write-auto-subs \
              --sub-lang "$LANG" \
              --skip-download --convert-subs srt \
              -o "$TEMP_DIR/%(id)s" "$URL" >&2 || true

    TEMP_SRT=$(ls -t "$TEMP_DIR"/*.srt 2>/dev/null | head -1)
    SUBTITLE_TYPE="auto-generated"
fi

if [ -n "$TEMP_SRT" ] && [ -f "$TEMP_SRT" ]; then
    # Extract language from filename (e.g., VIDEO_ID.en.srt -> en)
    DETECTED_LANG=$(basename "$TEMP_SRT" | sed 's/.*\.\([^.]*\)\.srt$/\1/')

    # Rename to unified format: {id}__{title}.{lang}.srt
    SRT_FILE="$OUTPUT_DIR/${BASENAME}.${DETECTED_LANG}.srt"
    mv "$TEMP_SRT" "$SRT_FILE"

    # Generate plain text version (remove sequence numbers, timestamps, empty lines)
    TEXT_FILE="${SRT_FILE%.srt}.txt"
    sed '/^[0-9]*$/d; /-->/d; /^[[:space:]]*$/d' "$SRT_FILE" | uniq > "$TEXT_FILE"

    # Clean up temp directory
    rm -rf "$TEMP_DIR"

    # Get SRT file statistics
    CHAR_COUNT=$(wc -c < "$SRT_FILE" | tr -d ' ')
    LINE_COUNT=$(wc -l < "$SRT_FILE" | tr -d ' ')

    # Get text file statistics
    TEXT_CHAR_COUNT=$(wc -c < "$TEXT_FILE" | tr -d ' ')
    TEXT_LINE_COUNT=$(wc -l < "$TEXT_FILE" | tr -d ' ')

    # Extract metadata fields for output
    META_VIDEO_ID=$(echo "$EXISTING_META" | "$JQ" -r '.video_id // empty')
    META_TITLE=$(echo "$EXISTING_META" | "$JQ" -r '.title // empty')
    META_CHANNEL=$(echo "$EXISTING_META" | "$JQ" -r '.channel // empty')
    META_URL=$(echo "$EXISTING_META" | "$JQ" -r '.url // empty')

    # Output JSON with both file paths and metadata
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
        --arg video_id "$META_VIDEO_ID" \
        --arg title "$META_TITLE" \
        --arg channel "$META_CHANNEL" \
        --arg url "$META_URL" \
        '{
            status: $status,
            file_path: $file_path,
            text_file_path: $text_file_path,
            language: $language,
            subtitle_type: $subtitle_type,
            char_count: $char_count,
            line_count: $line_count,
            text_char_count: $text_char_count,
            text_line_count: $text_line_count,
            video_id: $video_id,
            title: $title,
            channel: $channel,
            url: $url
        }'
else
    # Clean up temp directory
    rm -rf "$TEMP_DIR"

    "$JQ" -n \
        --arg status "error" \
        --arg message "No subtitles found (this video may not have subtitles)" \
        '{status: $status, message: $message}'
    exit 1
fi
