# YouTube Summarizer Plugin

Claude Code plugin for YouTube video tools - search, info, transcript, audio download, and summary.

## Skills

| Skill | Description | Usage |
|-------|-------------|-------|
| `/mk-youtube-search` | Search YouTube videos | `/mk-youtube-search <query> [count]` |
| `/mk-youtube-get-info` | Get video info and summary | `/mk-youtube-get-info <url>` |
| `/mk-youtube-get-caption` | Download subtitles | `/mk-youtube-get-caption <url> [lang]` |
| `/mk-youtube-get-audio` | Download audio | `/mk-youtube-get-audio <url> [output_dir]` |
| `/mk-youtube-get-channel-latest` | Get latest channel videos | `/mk-youtube-get-channel-latest <channel> [type] [count]` |
| `/mk-youtube-audio-transcribe` | Transcribe audio to text | `/mk-youtube-audio-transcribe <audio_file> [model] [lang]` |
| `/mk-youtube-transcript-summarize` | Structured video summary | `/mk-youtube-transcript-summarize <transcript_file_path>` |
| `/mk-youtube-summarize` | End-to-end video summarization | `/mk-youtube-summarize <url>` |

## Features

- **Smart dependency management**: Uses system `yt-dlp` and `jq` if available, auto-downloads on first run
- **Cross-platform**: Supports macOS (Intel/ARM), Linux (AMD64/ARM64), and Windows
- **Auto-provisioning**: Dependencies auto-download or build when missing
- **Independent skills**: Each skill is self-contained with its own dependencies
- **LLM-friendly output**: JSON output for easy parsing
- **Centralized metadata storage**: Video metadata shared across all skills via `/tmp/monkey_knowledge/youtube/meta/`
- **Cross-platform temp paths**: Uses `/tmp` on macOS/Linux, `$TEMP`/`$TMP` on Windows
- **Unified filename convention**: All files use `{YYYYMMDD}__{video_id}__{sanitized_title}.{ext}` format with date prefix for natural sorting

## Project Structure

```
plugins/youtube-summarizer/
├── .claude-plugin/
│   └── plugin.json          # Claude Code manifest
├── gemini-extension.json    # Gemini CLI manifest
├── skills/
│   ├── mk-youtube-search/
│   ├── mk-youtube-get-info/
│   ├── mk-youtube-get-caption/
│   ├── mk-youtube-get-audio/
│   ├── mk-youtube-get-channel-latest/
│   ├── mk-youtube-audio-transcribe/
│   ├── mk-youtube-transcript-summarize/
│   └── mk-youtube-summarize/
└── README.md
```

## Platform Compatibility

This plugin follows the [Agent Skills](https://agentskills.io/) open standard, enabling cross-platform compatibility:

| Platform | Support | Manifest |
|----------|---------|----------|
| Claude Code | ✅ | `.claude-plugin/plugin.json` |
| Gemini CLI | ✅ | `gemini-extension.json` |
| OpenCode | ✅ | Native Agent Skills support |
| VS Code Copilot | ✅ | Native Agent Skills support |

## Requirements

| Dependency | Required For | Auto-download | Manual Install |
|------------|--------------|---------------|----------------|
| curl/wget | Download binaries | - | Pre-installed |
| yt-dlp | search, info, transcript, audio | Yes | `brew install yt-dlp` |
| jq | search, info, transcript, audio, summary | Yes | `brew install jq` |

**Note**: No ffmpeg required. Audio downloads use best available format without conversion.

## Dependency Management

### yt-dlp Resolution Flow

```
┌─────────────────────────────────────────────────────┐
│              yt-dlp Resolution Flow                 │
│  (used by: search, info, transcript, audio)         │
├─────────────────────────────────────────────────────┤
│  1. Check system yt-dlp (command -v yt-dlp)         │
│     ├── Found → Use system version                  │
│     └── Not found ↓                                 │
│  2. Check bin/ for existing binary                  │
│     ├── yt-dlp-macos (universal)                    │
│     └── yt-dlp-darwin-arm64 (platform-specific)     │
│     ├── Found → Use existing binary                 │
│     └── Not found ↓                                 │
│  3. Auto-download from GitHub releases              │
│     ├── Success → Use downloaded binary             │
│     └── Failed → Error                              │
└─────────────────────────────────────────────────────┘
```

### jq Resolution Flow

```
┌─────────────────────────────────────────────────────┐
│                jq Resolution Flow                   │
│  (used by: all skills)                              │
├─────────────────────────────────────────────────────┤
│  1. Check system jq (command -v jq)                 │
│     ├── Found → Use system version                  │
│     └── Not found ↓                                 │
│  2. Check bin/ for existing binary                  │
│     ├── jq-macos-arm64                              │
│     ├── jq-macos-amd64                              │
│     ├── jq-linux-amd64                              │
│     ├── jq-linux-arm64                              │
│     └── jq-win64.exe                                │
│     ├── Found → Use existing binary                 │
│     └── Not found ↓                                 │
│  3. Auto-download from GitHub releases              │
│     ├── Success → Use downloaded binary             │
│     └── Failed → Error                              │
└─────────────────────────────────────────────────────┘
```

## Centralized Metadata Storage

All video metadata is stored in a portable temp directory for cross-skill access.

### Portable Temp Path Resolution

Temp directory is resolved by platform:

| Platform | Path |
|----------|------|
| macOS | `/tmp/monkey_knowledge/` |
| Linux | `/tmp/monkey_knowledge/` |
| Windows (Git Bash) | `$TEMP/monkey_knowledge/` or `$TMP/monkey_knowledge/` |

### Directory Structure

```
/tmp/monkey_knowledge/           # macOS/Linux
├── youtube/
│   ├── meta/                    # Centralized metadata store
│   │   └── {YYYYMMDD}__{video_id}__{title}.meta.json
│   ├── captions/                # Subtitle files
│   │   └── {YYYYMMDD}__{video_id}__{title}.{lang}.{srt|txt}
│   ├── audio/                   # Audio files
│   │   └── {YYYYMMDD}__{video_id}__{title}.{ext}
│   ├── transcribe/              # Transcription results
│   │   └── {YYYYMMDD}__{video_id}__{title}.{json|txt}
│   └── summaries/               # Summary files
│       └── {YYYYMMDD}__{video_id}__{title}.{lang}.md
└── build/                       # Build process temp directories
    ├── whisper-cpp-$$/
    ├── whisper-transcribe-$$/
    └── ffmpeg-download-$$/
```

### Metadata Merge Strategy

| Scenario | Behavior |
|----------|----------|
| `channel-latest` → `get-info` | `channel-latest` writes partial, `get-info` updates to complete |
| `get-info` → `channel-latest` | `get-info` is complete, `channel-latest` won't overwrite |
| `caption`/`audio` self-extract | Creates if not exists, reads only if exists |

### Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                 Centralized Metadata Store                       │
│             /tmp/monkey_knowledge/youtube/meta/                  │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────────┐                                                │
│  │ get-info     │──▶ Writes complete metadata (partial: false)   │
│  └──────────────┘                                                │
│  ┌──────────────────┐                                            │
│  │ channel-latest   │──▶ Batch writes partial metadata           │
│  └──────────────────┘                                            │
│  ┌──────────────┐                                                │
│  │ get-caption  │──▶ Reads existing or creates partial metadata  │
│  │ get-audio    │                                                │
│  └──────────────┘                                                │
│  ┌──────────────┐                                                │
│  │ transcribe   │──▶ Extracts video ID from filename → reads     │
│  │ summarize    │                                                │
│  └──────────────┘                                                │
└─────────────────────────────────────────────────────────────────┘
```

## Unified Filename Convention

All generated files use a consistent naming format with date prefix for natural sorting and easy identification.

### Format

```
{YYYYMMDD}__{video_id}__{sanitized_title}.{content_type}.{extension}
```

The date prefix `{YYYYMMDD}` is the video's upload date, enabling chronological file sorting.

### Examples

| File Type | Example |
|-----------|---------|
| Metadata | `20091025__dQw4w9WgXcQ__Rick_Astley_Never_Gonna_Give_You_Up.meta.json` |
| Caption (SRT) | `20091025__dQw4w9WgXcQ__Rick_Astley_Never_Gonna_Give_You_Up.en.srt` |
| Caption (TXT) | `20091025__dQw4w9WgXcQ__Rick_Astley_Never_Gonna_Give_You_Up.en.txt` |
| Audio | `20091025__dQw4w9WgXcQ__Rick_Astley_Never_Gonna_Give_You_Up.m4a` |
| Transcript (JSON) | `20091025__dQw4w9WgXcQ__Rick_Astley_Never_Gonna_Give_You_Up.json` |
| Transcript (TXT) | `20091025__dQw4w9WgXcQ__Rick_Astley_Never_Gonna_Give_You_Up.txt` |
| Summary | `20091025__dQw4w9WgXcQ__Rick_Astley_Never_Gonna_Give_You_Up.en.md` |

### Title Sanitization Rules

- Replace newlines/carriage returns with spaces
- Remove ASCII filesystem-unsafe characters: `/:*?"<>|\`
- Remove Unicode punctuation: `""''！？｜：` (Chinese quotes, fullwidth symbols)
- Replace consecutive spaces with single underscore
- Remove leading/trailing underscores
- Truncate to 80 characters maximum

### Length Limits

| Component | Length |
|-----------|--------|
| Date prefix | 8 chars (YYYYMMDD) |
| Separators | 4 chars (`__` x 2) |
| Video ID | 11 chars (fixed) |
| Title | max 80 chars |
| Content type + ext | max 20 chars |
| **Total** | ≤ 123 chars ✅ |

## Output Formats

All skills include video metadata in their JSON output when available.

### mk-youtube-search

```json
[
  {
    "title": "Video Title",
    "url": "https://www.youtube.com/watch?v=...",
    "duration_string": "10:23",
    "view_count": 1234567
  }
]
```

### mk-youtube-get-info

```json
{
  "video_id": "dQw4w9WgXcQ",
  "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
  "title": "Video Title",
  "channel": "Channel Name",
  "duration_string": "10:23",
  "view_count": 1234567,
  "upload_date": "20240101",
  "language": "en",
  "description": "Video description (first 1000 chars)...",
  "has_subtitles": true,
  "subtitle_languages": ["en", "ja", "zh-TW"],
  "has_auto_captions": true,
  "auto_caption_count": 15
}
```

### mk-youtube-get-caption

```json
{
  "status": "success",
  "file_path": "/tmp/monkey_knowledge/youtube/captions/20240101__VIDEO_ID__Video_Title.en.srt",
  "text_file_path": "/tmp/monkey_knowledge/youtube/captions/20240101__VIDEO_ID__Video_Title.en.txt",
  "language": "en",
  "subtitle_type": "manual",
  "char_count": 30287,
  "line_count": 1555,
  "text_char_count": 25000,
  "text_line_count": 800,
  "video_id": "dQw4w9WgXcQ",
  "title": "Video Title",
  "channel": "Channel Name",
  "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
}
```

### mk-youtube-get-audio

```json
{
  "status": "success",
  "file_path": "/tmp/monkey_knowledge/youtube/audio/20240101__VIDEO_ID__Video_Title.m4a",
  "file_size": "5.2M",
  "video_id": "dQw4w9WgXcQ",
  "title": "Video Title",
  "channel": "Channel Name",
  "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
  "duration_string": "3:32"
}
```

### mk-youtube-audio-transcribe

```json
{
  "status": "success",
  "file_path": "/tmp/monkey_knowledge/youtube/transcribe/20240101__VIDEO_ID__Video_Title.json",
  "text_file_path": "/tmp/monkey_knowledge/youtube/transcribe/20240101__VIDEO_ID__Video_Title.txt",
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

### mk-youtube-transcript-summarize

```json
{
  "status": "success",
  "source_transcript": "/tmp/monkey_knowledge/youtube/captions/20240101__VIDEO_ID__Video_Title.en.txt",
  "output_summary": "/tmp/monkey_knowledge/youtube/summaries/20240101__VIDEO_ID__Video_Title.en.md",
  "char_count": 30000,
  "line_count": 450,
  "strategy": "standard",
  "video_id": "dQw4w9WgXcQ",
  "title": "Video Title",
  "channel": "Channel Name",
  "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
}
```

## Installation

### Claude Code

```bash
# 1. Add marketplace
/plugin marketplace add kouko/monkey-knowledge-skills

# 2. Install plugin
/plugin install youtube-summarizer@kouko-monkey-knowledge-skills
```

### Gemini CLI

```bash
gemini extensions install https://github.com/kouko/monkey-knowledge-skills/tree/main/plugins/youtube-summarizer
```

### OpenCode

```bash
curl -sL https://github.com/kouko/monkey-knowledge-skills/archive/refs/heads/main.tar.gz | \
  tar -xz --strip-components=3 -C ~/.config/opencode/skills/ \
  "monkey-knowledge-skills-main/plugins/youtube-summarizer/skills/"
```

## Examples

```bash
# Search for videos
/mk-youtube-search "AI tutorial" 5

# Get video info (saves metadata to /tmp/monkey_knowledge/youtube/meta/)
/mk-youtube-get-info https://www.youtube.com/watch?v=dQw4w9WgXcQ

# Download subtitles (English)
/mk-youtube-get-caption https://www.youtube.com/watch?v=xxx

# Download subtitles (Japanese)
/mk-youtube-get-caption https://www.youtube.com/watch?v=xxx ja

# Download audio to default location
/mk-youtube-get-audio https://www.youtube.com/watch?v=xxx

# Download audio to custom location
/mk-youtube-get-audio https://www.youtube.com/watch?v=xxx ~/Music

# End-to-end summarization (recommended)
/mk-youtube-summarize https://www.youtube.com/watch?v=xxx

# Manual workflow: caption → summarize
/mk-youtube-get-caption https://www.youtube.com/watch?v=xxx
/mk-youtube-transcript-summarize /tmp/monkey_knowledge/youtube/captions/20240101__VIDEO_ID__Video_Title.en.txt
```

## Workflow: Video Summarization

### Recommended: End-to-end Pipeline

```
/mk-youtube-summarize <URL>
         │
         ▼
┌────────────────────────────────────────────────────────┐
│ Automatically orchestrates: get-info → get-caption/   │
│ get-audio → audio-transcribe → transcript-summarize   │
└────────────────────────────────────────────────────────┘
```

### Manual Workflow

```
┌────────────────────────┐
│ /mk-youtube-search     │ ← Find videos by keyword
└──────────┬─────────────┘
           │
           ▼
┌────────────────────────┐
│ /mk-youtube-get-info   │ ← Get metadata + check subtitle availability
└──────────┬─────────────┘
           │
     ┌─────┴─────┐
     │           │
has_subs      no_subs
     │           │
     ▼           ▼
┌─────────────┐ ┌─────────────────────────────────┐
│/mk-youtube- │ │/mk-youtube-get-audio            │
│get-caption  │ │  ↓                              │
└──────┬──────┘ │/mk-youtube-audio-transcribe     │
       │        └───────────────┬─────────────────┘
       └────────────┬───────────┘
                    │
                    ▼
       ┌────────────────────────────┐
       │/mk-youtube-transcript-     │
       │summarize                   │
       └────────────────────────────┘
```

## Troubleshooting

### Permission denied

```bash
# Set execute permissions
chmod +x skills/*/scripts/*.sh
```

### Download failed

```bash
# Check network connection
curl -I https://github.com

# Try manual download
curl -L -o bin/yt-dlp https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_macos
chmod +x bin/yt-dlp
```

## License

MIT
