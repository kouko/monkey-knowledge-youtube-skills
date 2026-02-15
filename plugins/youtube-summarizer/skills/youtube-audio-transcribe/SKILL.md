---
name: youtube-audio-transcribe
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
2. Convert audio to 16kHz mono WAV using ffmpeg
3. Download model if not present
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
  "file_path": "/tmp/youtube-audio-transcribe/video.json",
  "text_file_path": "/tmp/youtube-audio-transcribe/video.txt",
  "language": "en",
  "duration": "3:32",
  "model": "medium",
  "char_count": 12345,
  "line_count": 100,
  "text_char_count": 10000,
  "text_line_count": 50
}
```

**Error:**
```json
{
  "status": "error",
  "message": "Error description"
}
```

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
| tiny | 75MB | ~273MB | Fastest | Low |
| base | 142MB | ~388MB | Fast | Medium |
| small | 466MB | ~852MB | Moderate | Good |
| medium | 1.5GB | ~2.1GB | Slow | High |
| large-v3 | 2.9GB | ~3.9GB | Slowest | Best |

### Language-Specialized Models

| Model | Language | Size | Description |
|-------|----------|------|-------------|
| belle-zh | Chinese | 1.62GB | BELLE-2 Chinese-specialized model |
| kotoba-ja | Japanese | - | kotoba-tech Japanese-specialized model |
| kotoba-ja-q5 | Japanese | smaller | Quantized version (faster, smaller) |

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
- First run downloads the model (~1.5GB for medium)
- Uses Metal acceleration on macOS for faster processing
- Supports auto language detection
- Audio is converted to 16kHz WAV for optimal results
- Requires ffmpeg and whisper-cli (pre-built in bin/)
