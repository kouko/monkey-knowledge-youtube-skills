#!/bin/bash
set -e

# Load dependency scripts
source "$(dirname "$0")/_ensure_ytdlp.sh"
source "$(dirname "$0")/_ensure_jq.sh"
source "$(dirname "$0")/_naming.sh"

URL="$1"

if [ -z "$URL" ]; then
    echo "Usage: info.sh <url>"
    exit 1
fi

# Get raw metadata from yt-dlp
RAW_META=$("$YT_DLP" -j --no-download "$URL" 2>/dev/null)

# Extract video ID, title, and upload_date for basename
VIDEO_ID=$(echo "$RAW_META" | "$JQ" -r '.id')
TITLE=$(echo "$RAW_META" | "$JQ" -r '.title')
UPLOAD_DATE=$(echo "$RAW_META" | "$JQ" -r '.upload_date')
BASENAME=$(make_basename "$UPLOAD_DATE" "$VIDEO_ID" "$TITLE")

# Build metadata JSON for storage (complete data)
META_JSON=$(echo "$RAW_META" | "$JQ" '{
    video_id: .id,
    title,
    channel,
    channel_url,
    url: .webpage_url,
    upload_date,
    duration_string,
    view_count,
    description: .description[0:500],
    language,
    has_subtitles: ((.subtitles | keys | length) > 0),
    subtitle_languages: (.subtitles | keys // []),
    has_auto_captions: ((.automatic_captions | keys | length) > 0),
    auto_caption_count: (.automatic_captions | keys | length // 0),
    source: "get-info",
    partial: false,
    fetched_at: (now | todate)
}')

# Write or merge metadata (complete data always updates)
write_or_merge_meta "$META_DIR/$BASENAME.meta.json" "$META_JSON" "false"

# Output JSON (same as before, with added video_id and url fields)
echo "$RAW_META" | "$JQ" '{
    video_id: .id,
    url: .webpage_url,
    title,
    channel,
    duration_string,
    view_count,
    upload_date,
    language,
    description: .description[0:1000],
    has_subtitles: ((.subtitles | keys | length) > 0),
    subtitle_languages: (.subtitles | keys // []),
    has_auto_captions: ((.automatic_captions | keys | length) > 0),
    auto_caption_count: (.automatic_captions | keys | length // 0)
}'
