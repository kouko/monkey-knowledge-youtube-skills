#!/bin/bash
set -e

# Load dependency scripts
source "$(dirname "$0")/_ensure_ytdlp.sh"
source "$(dirname "$0")/_ensure_jq.sh"

QUERY="$1"
COUNT="${2:-5}"

if [ -z "$QUERY" ]; then
    echo "Usage: search.sh <query> [count]"
    exit 1
fi

"$YT_DLP" "ytsearch${COUNT}:${QUERY}" \
    --dump-json --flat-playlist 2>/dev/null | \
    "$JQ" -s 'map({
        title,
        url: .webpage_url,
        duration_string,
        view_count
    })'
