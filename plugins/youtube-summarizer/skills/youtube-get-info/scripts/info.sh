#!/bin/bash
set -e

# Load dependency scripts
source "$(dirname "$0")/_ensure_ytdlp.sh"
source "$(dirname "$0")/_ensure_jq.sh"

URL="$1"

if [ -z "$URL" ]; then
    echo "Usage: info.sh <url>"
    exit 1
fi

"$YT_DLP" -j --no-download "$URL" 2>/dev/null | \
    "$JQ" '{
        title,
        channel,
        duration_string,
        view_count,
        upload_date,
        language,
        description: .description[0:1000]
    }'
