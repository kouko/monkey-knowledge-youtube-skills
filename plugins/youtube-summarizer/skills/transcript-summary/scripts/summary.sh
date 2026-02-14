#!/bin/bash
set -e

# Load dependency
source "$(dirname "$0")/_ensure_jq.sh"

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

"$JQ" -n \
    --arg status "success" \
    --arg file_path "$ABS_PATH" \
    --argjson char_count "$CHAR_COUNT" \
    --argjson line_count "$LINE_COUNT" \
    --arg strategy "$STRATEGY" \
    '{status: $status, file_path: $file_path, char_count: $char_count, line_count: $line_count, strategy: $strategy}'
