# YouTube Audio Transcribe Skill

Transcribe audio files to text using local whisper.cpp with Metal acceleration.

## Overview

This skill converts audio files to text using OpenAI's Whisper model (via whisper.cpp). It supports:
- **Local processing**: No cloud API required
- **Metal acceleration**: Fast processing on macOS
- **Auto language detection**: Supports multiple languages
- **Multiple models**: From tiny (fast) to large (accurate)

## File Structure

```
youtube-audio-transcribe/
├── SKILL.md              # Skill definition for Claude Code
├── README.md             # This file
├── bin/                  # Pre-built binaries (macOS)
│   ├── ffmpeg            # Audio converter
│   ├── whisper-cli       # Whisper CLI with Metal
│   └── .gitkeep
├── models/               # Downloaded Whisper models
│   └── .gitkeep
└── scripts/
    ├── _ensure_ffmpeg.sh    # Ensures ffmpeg is available
    ├── _ensure_whisper.sh   # Ensures whisper-cli is available
    ├── _ensure_model.sh     # Ensures model is downloaded
    ├── _ensure_jq.sh        # Ensures jq is available
    ├── _build_whisper.sh    # Build script for updates
    ├── _download_ffmpeg.sh  # Download script for updates
    └── transcribe.sh        # Main transcription script
```

## Dependencies

| Dependency | Purpose | Location |
|------------|---------|----------|
| ffmpeg | Audio conversion | System or bin/ |
| whisper-cli | Speech-to-text | System or bin/ |
| jq | JSON formatting | System or auto-download |

## Script: `transcribe.sh`

### Usage

```bash
./scripts/transcribe.sh "<audio_file>" [model] [language]
```

### Parameters

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| audio_file | Yes | - | Path to audio file |
| model | No | auto | Model name (auto = automatic selection) |
| language | No | auto | Language code |

### Available Models

#### Standard Models

| Model | Size | RAM | Description |
|-------|------|-----|-------------|
| auto | - | - | Automatic selection based on language (default) |
| tiny | 75MB | ~273MB | Fastest, lowest accuracy |
| base | 142MB | ~388MB | Fast, moderate accuracy |
| small | 466MB | ~852MB | Balanced |
| medium | 1.5GB | ~2.1GB | High accuracy |
| large-v3 | 2.9GB | ~3.9GB | Best accuracy |

#### Language-Specialized Models

| Model | Language | Size | Source |
|-------|----------|------|--------|
| belle-zh | Chinese | 1.62GB | [BELLE-2](https://huggingface.co/BELLE-2/Belle-whisper-large-v3-turbo-zh-ggml) |
| kotoba-ja | Japanese | - | [kotoba-tech](https://huggingface.co/kotoba-tech/kotoba-whisper-v2.0-ggml) |
| kotoba-ja-q5 | Japanese | smaller | Quantized version (faster) |

#### Auto-Selection (model=auto)

When model is `auto` (default), the script automatically selects the best model based on language:

| Language | Auto-Selected Model |
|----------|---------------------|
| zh | belle-zh (Chinese-specialized) |
| ja | kotoba-ja (Japanese-specialized) |
| others | medium (general purpose) |

```bash
# Auto-selection examples:
./scripts/transcribe.sh video.m4a auto zh   # → uses belle-zh
./scripts/transcribe.sh video.m4a auto ja   # → uses kotoba-ja
./scripts/transcribe.sh video.m4a auto en   # → uses medium
./scripts/transcribe.sh video.m4a           # → uses medium (default)
```

### Supported Languages

- `auto` - Auto-detect (default)
- `en` - English
- `ja` - Japanese
- `zh` - Chinese
- `ko` - Korean
- And many more (Whisper supports 99 languages)

### Output Format

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

### Output Fields

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

### JSON File Format

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

## Examples

```bash
# Transcribe with default settings (medium model, auto language)
./scripts/transcribe.sh /tmp/youtube-audio/video.m4a

# Use smaller model for faster processing
./scripts/transcribe.sh audio.mp3 small

# Force English language
./scripts/transcribe.sh podcast.wav medium en

# Use tiny model for quick preview
./scripts/transcribe.sh long-video.m4a tiny auto

# Use Chinese-specialized model for better Chinese transcription
./scripts/transcribe.sh chinese-video.m4a belle-zh zh

# Use Japanese-specialized model for better Japanese transcription
./scripts/transcribe.sh japanese-video.m4a kotoba-ja ja

# Use quantized Japanese model for faster processing
./scripts/transcribe.sh japanese-video.m4a kotoba-ja-q5 ja
```

## How It Works

```
┌─────────────────────────────┐
│      transcribe.sh          │
│  audio_file, [model], [lang]│
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│   Load dependencies         │
│   _ensure_ffmpeg.sh         │
│   _ensure_whisper.sh        │
│   _ensure_model.sh          │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│   Convert audio to WAV      │
│   ffmpeg -i input           │
│   -ar 16000 -ac 1           │
│   -c:a pcm_s16le out.wav    │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│   Run whisper-cli           │
│   -f audio.wav              │
│   -m model -oj              │
│   (Metal acceleration)      │
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

## Building Binaries

### whisper-cli (macOS with Metal)

```bash
./scripts/_build_whisper.sh
```

This will:
1. Clone whisper.cpp repository
2. Build with Metal acceleration enabled
3. Copy binary to bin/
4. Clean up source code

### ffmpeg

```bash
./scripts/_download_ffmpeg.sh
```

This will download a pre-built ffmpeg binary from evermeet.cx.

## Use Cases

1. **No subtitles**: Transcribe videos that don't have captions
2. **Podcast transcription**: Convert podcasts to searchable text
3. **Meeting notes**: Transcribe recorded meetings
4. **Content analysis**: Extract text for summarization

## Error Handling

| Error | Cause | Solution |
|-------|-------|----------|
| `File not found` | Invalid path | Check file path |
| `Transcription failed` | whisper error | Check audio format |
| `ffmpeg not found` | Missing ffmpeg | Run _download_ffmpeg.sh |
| `whisper-cli not found` | Missing whisper | Run _build_whisper.sh |

## Performance Tips

1. **Specify language**: Enables auto-selection of specialized models (zh→belle-zh, ja→kotoba-ja) for best accuracy
2. **Model selection**: Use `auto` (default) for optimal results, or `small` for faster processing
3. **Audio quality**: Better source audio = better transcription
4. **Memory**: Ensure enough RAM for chosen model

## License

MIT
