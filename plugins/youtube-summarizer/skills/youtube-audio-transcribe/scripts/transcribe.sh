#!/bin/bash
# transcribe.sh - Transcribe audio to text using whisper.cpp
#
# Usage:
#   ./scripts/transcribe.sh "<audio_file>" [model] [language]
#
# Parameters:
#   audio_file - Path to audio file (required)
#   model      - Model name: auto, tiny, base, small, medium, large-v3, belle-zh, kotoba-ja (default: auto)
#   language   - Language code: en, ja, zh, auto (default: auto)
#
# Auto-selection (model=auto):
#   - zh → belle-zh (Chinese-specialized)
#   - ja → kotoba-ja (Japanese-specialized)
#   - others → medium (general purpose)
#
# Output: JSON with transcription result

set -e

# Load dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_ensure_ffmpeg.sh"
source "$SCRIPT_DIR/_ensure_whisper.sh"
source "$SCRIPT_DIR/_ensure_jq.sh"

AUDIO_FILE="$1"
MODEL="${2:-auto}"
LANGUAGE="${3:-auto}"

# Auto-select model based on language when model=auto
if [ "$MODEL" = "auto" ]; then
    case "$LANGUAGE" in
        zh)
            MODEL="belle-zh"
            echo "[INFO] Auto-selected Chinese-specialized model: belle-zh" >&2
            ;;
        ja)
            MODEL="kotoba-ja"
            echo "[INFO] Auto-selected Japanese-specialized model: kotoba-ja" >&2
            ;;
        *)
            MODEL="medium"
            echo "[INFO] Auto-selected general model: medium" >&2
            ;;
    esac
fi

if [ -z "$AUDIO_FILE" ]; then
    "$JQ" -n '{status: "error", message: "Usage: transcribe.sh <audio_file> [model] [language]"}'
    exit 1
fi

if [ ! -f "$AUDIO_FILE" ]; then
    "$JQ" -n --arg file "$AUDIO_FILE" '{status: "error", message: ("File not found: " + $file)}'
    exit 1
fi

# Ensure model is downloaded
source "$SCRIPT_DIR/_ensure_model.sh" "$MODEL"

# Create temp directory for processing
TEMP_DIR="/tmp/whisper-transcribe-$$"
mkdir -p "$TEMP_DIR"

# Output directory (persistent)
OUTPUT_DIR="/tmp/youtube-audio-transcribe"
mkdir -p "$OUTPUT_DIR"

# Generate output filename from audio file
BASENAME=$(basename "$AUDIO_FILE" | sed 's/\.[^.]*$//')
JSON_OUTPUT="$OUTPUT_DIR/${BASENAME}.json"
TEXT_OUTPUT="$OUTPUT_DIR/${BASENAME}.txt"

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Convert audio to 16kHz mono WAV (required by whisper)
WAV_FILE="$TEMP_DIR/audio.wav"
echo "[INFO] Converting audio to WAV..." >&2
"$FFMPEG" -i "$AUDIO_FILE" -ar 16000 -ac 1 -c:a pcm_s16le "$WAV_FILE" -y 2>/dev/null

# Get audio duration
DURATION=$("$FFMPEG" -i "$AUDIO_FILE" 2>&1 | grep "Duration" | cut -d ' ' -f 4 | sed 's/,//' | cut -d '.' -f 1)

# Build whisper command
WHISPER_ARGS=("-f" "$WAV_FILE" "-m" "$MODEL_PATH" "-oj")

# Add language option (auto = don't specify, let whisper detect)
if [ "$LANGUAGE" != "auto" ]; then
    WHISPER_ARGS+=("-l" "$LANGUAGE")
fi

# Run whisper
echo "[INFO] Transcribing with model: $MODEL..." >&2
OUTPUT_FILE="$TEMP_DIR/output"
"$WHISPER" "${WHISPER_ARGS[@]}" -of "$OUTPUT_FILE" >/dev/null 2>&1

# Check if output exists
JSON_FILE="$OUTPUT_FILE.json"
if [ ! -f "$JSON_FILE" ]; then
    "$JQ" -n '{status: "error", message: "Transcription failed"}'
    exit 1
fi

# Extract language from whisper output
DETECTED_LANG=$("$JQ" -r '.result.language // "unknown"' "$JSON_FILE")

# Save full JSON to file
"$JQ" --arg model "$MODEL" --arg duration "$DURATION" '
{
    text: .transcription | map(.text) | join(""),
    language: .result.language,
    duration: $duration,
    model: $model,
    segments: [.transcription[] | {
        start: .timestamps.from,
        end: .timestamps.to,
        text: .text
    }]
}
' "$JSON_FILE" > "$JSON_OUTPUT"

# Save plain text to file
"$JQ" -r '.transcription | map(.text) | join("")' "$JSON_FILE" > "$TEXT_OUTPUT"

# Get file statistics
CHAR_COUNT=$(wc -c < "$JSON_OUTPUT" | tr -d ' ')
LINE_COUNT=$(wc -l < "$JSON_OUTPUT" | tr -d ' ')
TEXT_CHAR_COUNT=$(wc -c < "$TEXT_OUTPUT" | tr -d ' ')
TEXT_LINE_COUNT=$(wc -l < "$TEXT_OUTPUT" | tr -d ' ')

# Output file paths and metadata
"$JQ" -n \
    --arg file_path "$JSON_OUTPUT" \
    --arg text_file_path "$TEXT_OUTPUT" \
    --arg language "$DETECTED_LANG" \
    --arg duration "$DURATION" \
    --arg model "$MODEL" \
    --argjson char_count "$CHAR_COUNT" \
    --argjson line_count "$LINE_COUNT" \
    --argjson text_char_count "$TEXT_CHAR_COUNT" \
    --argjson text_line_count "$TEXT_LINE_COUNT" \
    '{
        status: "success",
        file_path: $file_path,
        text_file_path: $text_file_path,
        language: $language,
        duration: $duration,
        model: $model,
        char_count: $char_count,
        line_count: $line_count,
        text_char_count: $text_char_count,
        text_line_count: $text_line_count
    }'
