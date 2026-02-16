---
name: mk-youtube-audio-transcribe
description: Transcribe audio to text using local whisper.cpp. Use when user wants to convert audio/video to text, get transcription, or speech-to-text.
license: MIT
metadata:
  version: 1.0.0
  author: kouko
  tags:
    - youtube
    - audio
    - transcribe
    - whisper
    - speech-to-text
compatibility:
  claude-code: ">=1.0.0"
---

# YouTube Audio Transcribe

Transcribe audio files to text using local whisper.cpp (no cloud API required).

## Quick Start

```
/youtube-audio-transcribe <audio_file> [model] [language]
```

## Parameters

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| audio_file | Yes | - | Path to audio file |
| model | No | auto | Model: auto, tiny, base, small, medium, large-v3, belle-zh, kotoba-ja |
| language | No | auto | Language code: en, ja, zh, auto (auto-detect) |

## Examples

- `/youtube-audio-transcribe /tmp/youtube-audio/video.m4a` - Transcribe with auto model selection
- `/youtube-audio-transcribe video.m4a auto zh` - Auto-select best model for Chinese → belle-zh
- `/youtube-audio-transcribe video.m4a auto ja` - Auto-select best model for Japanese → kotoba-ja
- `/youtube-audio-transcribe audio.mp3 small en` - Use small model, force English
- `/youtube-audio-transcribe podcast.wav medium ja` - Use medium model (explicit), Japanese

## How it Works

1. Execute: `{baseDir}/scripts/transcribe.sh "<audio_file>" "<model>" "<language>"`
2. Check if model exists (does NOT auto-download)
3. Convert audio to 16kHz mono WAV using ffmpeg
4. Run whisper-cli for transcription
5. Save full JSON to `/tmp/youtube-audio-transcribe/<filename>.json`
6. Save plain text to `/tmp/youtube-audio-transcribe/<filename>.txt`
7. Return file paths and metadata

```
┌─────────────────────────────┐
│      transcribe.sh          │
│  audio_file, [model], [lang]│
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│   ffmpeg: convert to WAV    │
│   16kHz, mono, pcm_s16le    │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│   whisper-cli: transcribe   │
│   with Metal acceleration   │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│   Save to files             │
│   .json (full) + .txt       │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│   Return file paths         │
│   {file_path, text_file_path}│
└─────────────────────────────┘
```

## Output Format

**Success:**
```json
{
  "status": "success",
  "file_path": "/tmp/youtube-audio-transcribe/VIDEO_ID__Video_Title.json",
  "text_file_path": "/tmp/youtube-audio-transcribe/VIDEO_ID__Video_Title.txt",
  "language": "en",
  "duration": "3:32",
  "model": "medium",
  "char_count": 12345,
  "line_count": 100,
  "text_char_count": 10000,
  "text_line_count": 50,
  "video_id": "dQw4w9WgXcQ",
  "title": "Video Title",
  "channel": "Channel Name",
  "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
}
```

**Error (general):**
```json
{
  "status": "error",
  "message": "Error description"
}
```

**Error (model not found):**
```json
{
  "status": "error",
  "error_code": "MODEL_NOT_FOUND",
  "message": "Model 'medium' not found. Please download it first.",
  "model": "medium",
  "model_size": "1.4GB",
  "download_command": "curl -L --progress-bar -o '/path/to/models/ggml-medium.bin' 'https://...' 2>&1",
  "download_url": "https://huggingface.co/...",
  "output_path": "/path/to/models/ggml-medium.bin"
}
```

When you receive `MODEL_NOT_FOUND` error:
1. Ask user if they want to download the model now using AskUserQuestion tool
2. If user agrees: execute `download_command` (curl) using Bash tool with `timeout: 600000` (10 minutes), then retry transcription when complete
3. Progress will be shown in real-time due to `2>&1` redirect in download_command
4. If user declines: show the same curl command in a code block for manual execution

Example flow:
1. Execute transcribe.sh → receive MODEL_NOT_FOUND
2. Ask: "Model 'medium' (1.5GB) not found. Download now?"
3. If yes: run Bash tool with the `download_command` curl command
4. When complete: retry transcribe.sh

**Error (model corrupted):**
```json
{
  "status": "error",
  "error_code": "MODEL_CORRUPTED",
  "message": "Model 'medium' is corrupted or incomplete. Please re-download.",
  "model": "medium",
  "model_size": "1.4GB",
  "expected_sha256": "6c14d5adee5f86394037b4e4e8b59f1673b6cee10e3cf0b11bbdbee79c156208",
  "actual_sha256": "def456...",
  "model_path": "/path/to/models/ggml-medium.bin",
  "download_command": "rm '/path/to/models/ggml-medium.bin' && curl -L --progress-bar -o '/path/to/models/ggml-medium.bin' 'https://...' 2>&1"
}
```

When you receive `MODEL_CORRUPTED` error:
1. Ask user: "Model 'medium' is corrupted or incomplete. Re-download now?"
2. If user agrees: execute `download_command` (removes corrupted file and re-downloads) using Bash tool with `timeout: 600000`
3. If user declines: show the command in a code block for manual execution

## Output Fields

| Field | Description |
|-------|-------------|
| `file_path` | Absolute path to JSON file (with segments) |
| `text_file_path` | Absolute path to plain text file |
| `language` | Detected language code |
| `duration` | Audio duration |
| `model` | Model used for transcription |
| `char_count` | Character count of JSON file |
| `line_count` | Line count of JSON file |
| `text_char_count` | Character count of plain text file |
| `text_line_count` | Line count of plain text file |
| `video_id` | YouTube video ID (from centralized metadata store) |
| `title` | Video title (from centralized metadata store) |
| `channel` | Channel name (from centralized metadata store) |
| `url` | Full video URL (from centralized metadata store) |

## Filename Format

Output files preserve the input audio filename's unified naming format: `{video_id}__{sanitized_title}.{ext}`

Example: `dQw4w9WgXcQ__Rick_Astley_Never_Gonna_Give_You_Up.json`

## JSON File Format

The JSON file at `file_path` contains:
```json
{
  "text": "Full transcription text...",
  "language": "en",
  "duration": "3:32",
  "model": "medium",
  "segments": [
    {
      "start": "00:00:00.000",
      "end": "00:00:05.000",
      "text": "First segment..."
    }
  ]
}
```

## Models

### Standard Models

| Model | Size | RAM | Speed | Accuracy |
|-------|------|-----|-------|----------|
| auto | - | - | - | Auto-select based on language (default) |
| tiny | 74MB | ~273MB | Fastest | Low |
| base | 141MB | ~388MB | Fast | Medium |
| small | 465MB | ~852MB | Moderate | Good |
| medium | 1.4GB | ~2.1GB | Slow | High |
| large-v3 | 2.9GB | ~3.9GB | Slowest | Best |
| large-v3-turbo | 1.5GB | ~2.1GB | Moderate | High (optimized for speed) |

### Language-Specialized Models

| Model | Language | Size | Description |
|-------|----------|------|-------------|
| belle-zh | Chinese | 1.5GB | BELLE-2 Chinese-specialized model |
| kotoba-ja | Japanese | 1.4GB | kotoba-tech Japanese-specialized model |
| kotoba-ja-q5 | Japanese | 513MB | Quantized version (faster, smaller) |

### Auto-Selection (model=auto)

When model is `auto` (default), the system automatically selects the best model based on language:

| Language | Auto-Selected Model |
|----------|---------------------|
| zh | belle-zh (Chinese-specialized) |
| ja | kotoba-ja (Japanese-specialized) |
| others | medium (general purpose) |

Example: `/youtube-audio-transcribe video.m4a auto zh` → uses `belle-zh`

## Notes

- **Specify language for best results** - enables auto-selection of specialized models (zh→belle-zh, ja→kotoba-ja)
- Use Read tool to get file content from `file_path` or `text_file_path`
- **Models must be downloaded before first use** - run `./scripts/download-model.sh <model>` in terminal
- Uses Metal acceleration on macOS for faster processing
- Supports auto language detection
- Audio is converted to 16kHz WAV for optimal results
- Requires ffmpeg and whisper-cli (pre-built in bin/)

## Model Download

Models are NOT auto-downloaded. To download a model:

```bash
# In terminal (to see progress bar)
./scripts/download-model.sh medium      # 1.4GB
./scripts/download-model.sh belle-zh    # 1.5GB (Chinese)
./scripts/download-model.sh kotoba-ja   # 1.4GB (Japanese)
./scripts/download-model.sh --list      # Show all available models
```

## Next Step

After transcription completes, invoke `/mk-youtube-transcript-summarize` with the `text_file_path` from the output to generate a structured summary:

```
/mk-youtube-transcript-summarize <text_file_path>
```

**IMPORTANT**: Always use the Skill tool to invoke `/mk-youtube-transcript-summarize`. Do NOT generate summaries directly without loading the skill — it contains critical rules for compression ratio, section structure, data preservation, and language handling.
