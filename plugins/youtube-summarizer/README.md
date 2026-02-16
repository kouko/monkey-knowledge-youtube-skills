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

- **Smart dependency management**: Uses system `yt-dlp` and `jq` if available, auto-downloads if not
- **Cross-platform**: Supports macOS (Intel/ARM), Linux (AMD64/ARM64), and Windows
- **Lightweight**: No pre-bundled binaries, downloads on first use
- **Independent skills**: Each skill is self-contained with its own dependencies
- **LLM-friendly output**: JSON output for easy parsing
- **Centralized metadata storage**: Video metadata shared across all skills via `/tmp/youtube-video-meta/`
- **Unified filename convention**: All files use `{YYYYMMDD}__{video_id}__{sanitized_title}.{ext}` format with date prefix for natural sorting

## Project Structure

```
plugins/youtube-summarizer/
├── .claude-plugin/
│   └── plugin.json
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
│  2. Check bin/ for downloaded binary                │
│     ├── Found → Use downloaded version              │
│     └── Not found ↓                                 │
│  3. Download platform-specific binary               │
│     ├── macOS: yt-dlp_macos                         │
│     ├── Linux: yt-dlp_linux                         │
│     └── Windows: yt-dlp.exe                         │
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
│  2. Detect OS + CPU architecture                    │
│     ├── macOS Intel: jq-macos-amd64                 │
│     ├── macOS ARM: jq-macos-arm64                   │
│     ├── Linux x64: jq-linux-amd64                   │
│     ├── Linux ARM: jq-linux-arm64                   │
│     └── Windows: jq-win64.exe                       │
│  3. Check bin/ for downloaded binary                │
│     ├── Found → Use downloaded version              │
│     └── Not found → Download from GitHub            │
└─────────────────────────────────────────────────────┘
```

## Centralized Metadata Storage

All video metadata is stored in `/tmp/youtube-video-meta/` for cross-skill access.

### Directory Structure

```
/tmp/
├── youtube-video-meta/           # Centralized metadata store
│   └── {YYYYMMDD}__{video_id}__{title}.meta.json
├── youtube-captions/             # Subtitle files
│   └── {YYYYMMDD}__{video_id}__{title}.{lang}.{srt|txt}
├── youtube-audio/                # Audio files
│   └── {YYYYMMDD}__{video_id}__{title}.{ext}
├── youtube-audio-transcribe/     # Transcription results
│   └── {YYYYMMDD}__{video_id}__{title}.{json|txt}
└── youtube-summaries/            # Summary files
    └── {YYYYMMDD}__{video_id}__{title}.{lang}.md
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
│                 /tmp/youtube-video-meta/                         │
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
- Remove filesystem-unsafe characters: `/:*?"<>|\`
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
  "title": "Video Title",
  "channel": "Channel Name",
  "channel_url": "https://www.youtube.com/channel/...",
  "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
  "duration_string": "10:23",
  "view_count": 1234567,
  "upload_date": "20240101",
  "description": "Video description (first 500 chars)..."
}
```

### mk-youtube-get-caption

```json
{
  "status": "success",
  "file_path": "/tmp/youtube-captions/20240101__VIDEO_ID__Video_Title.en.srt",
  "text_file_path": "/tmp/youtube-captions/20240101__VIDEO_ID__Video_Title.en.txt",
  "language": "en",
  "subtitle_type": "manual",
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
  "file_path": "/tmp/youtube-audio/20240101__VIDEO_ID__Video_Title.m4a",
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
  "file_path": "/tmp/youtube-audio-transcribe/20240101__VIDEO_ID__Video_Title.json",
  "text_file_path": "/tmp/youtube-audio-transcribe/20240101__VIDEO_ID__Video_Title.txt",
  "language": "en",
  "duration": "3:32",
  "model": "medium",
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
  "source_transcript": "/tmp/youtube-captions/20240101__VIDEO_ID__Video_Title.en.txt",
  "output_summary": "/tmp/youtube-summaries/20240101__VIDEO_ID__Video_Title.en.md",
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

```bash
# Add marketplace
/plugin marketplace add kouko/monkey-knowledge-skills

# Install plugin
/plugin install youtube-summarizer@monkey-marketplace
```

## Examples

```bash
# Search for videos
/mk-youtube-search "AI tutorial" 5

# Get video info (saves metadata to /tmp/youtube-video-meta/)
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
/mk-youtube-transcript-summarize /tmp/youtube-captions/20240101__VIDEO_ID__Video_Title.en.txt
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
