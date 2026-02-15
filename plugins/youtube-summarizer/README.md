# YouTube Summarizer Plugin

Claude Code plugin for YouTube video tools - search, info, transcript, audio download, and summary.

## Skills

| Skill | Description | Usage |
|-------|-------------|-------|
| `/youtube-search` | Search YouTube videos | `/youtube-search <query> [count]` |
| `/youtube-info` | Get video info and summary | `/youtube-info <url>` |
| `/youtube-caption` | Download subtitles | `/youtube-caption <url> [lang]` |
| `/youtube-audio` | Download audio (MP3) | `/youtube-audio <url> [output_dir]` |
| `/transcript-summarize` | Structured video summary | `/transcript-summarize <transcript_file_path>` |

## Features

- **Smart dependency management**: Uses system `yt-dlp` and `jq` if available, auto-downloads if not
- **Cross-platform**: Supports macOS (Intel/ARM), Linux (AMD64/ARM64), and Windows
- **Lightweight**: No pre-bundled binaries, downloads on first use
- **Independent skills**: Each skill is self-contained with its own dependencies
- **LLM-friendly output**: JSON output for easy parsing

## Project Structure

```
plugins/youtube-summarizer/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   ├── youtube-search/
│   │   ├── SKILL.md
│   │   ├── README.md
│   │   ├── bin/
│   │   └── scripts/
│   │       ├── _ensure_ytdlp.sh
│   │       ├── _ensure_jq.sh
│   │       └── search.sh
│   ├── youtube-info/
│   │   ├── SKILL.md
│   │   ├── README.md
│   │   ├── bin/
│   │   └── scripts/
│   │       ├── _ensure_ytdlp.sh
│   │       ├── _ensure_jq.sh
│   │       └── info.sh
│   ├── youtube-caption/
│   │   ├── SKILL.md
│   │   ├── README.md
│   │   ├── bin/
│   │   └── scripts/
│   │       ├── _ensure_ytdlp.sh
│   │       └── caption.sh
│   ├── youtube-audio/
│   │   ├── SKILL.md
│   │   ├── README.md
│   │   ├── bin/
│   │   └── scripts/
│   │       ├── _ensure_ytdlp.sh
│   │       ├── _ensure_jq.sh
│   │       └── audio.sh
│   └── transcript-summarize/
│       ├── SKILL.md
│       ├── README.md
│       ├── bin/
│       └── scripts/
│           ├── _ensure_jq.sh
│           └── summary.sh
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

## Output Formats

### youtube-search

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

### youtube-info

```json
{
  "title": "Video Title",
  "channel": "Channel Name",
  "duration_string": "10:23",
  "view_count": 1234567,
  "upload_date": "20240101",
  "description": "Video description..."
}
```

### youtube-caption

```json
{
  "status": "success",
  "file_path": "/tmp/youtube-captions/VIDEO_ID.en.srt",
  "language": "en",
  "content": "transcript text content..."
}
```

### youtube-audio

```json
{
  "status": "success",
  "file_path": "/tmp/youtube-audio/video_title.m4a",
  "file_size": "5.2M"
}
```

### transcript-summarize

```json
{
  "status": "success",
  "file_path": "/tmp/youtube-captions/VIDEO_ID.en.txt",
  "char_count": 30000,
  "line_count": 450,
  "strategy": "standard"
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
/youtube-search "AI tutorial" 5

# Get video info and summary
/youtube-info https://www.youtube.com/watch?v=dQw4w9WgXcQ

# Download subtitles (English)
/youtube-caption https://www.youtube.com/watch?v=xxx

# Download subtitles (Japanese)
/youtube-caption https://www.youtube.com/watch?v=xxx ja

# Download audio to default location
/youtube-audio https://www.youtube.com/watch?v=xxx

# Download audio to custom location
/youtube-audio https://www.youtube.com/watch?v=xxx ~/Music

# Summarize from a transcript file (typical two-step workflow)
/youtube-caption https://www.youtube.com/watch?v=xxx
/transcript-summarize /tmp/youtube-captions/VIDEO_ID.en.txt

# Summarize with metadata (three-step workflow)
/youtube-info https://www.youtube.com/watch?v=xxx
/youtube-caption https://www.youtube.com/watch?v=xxx
/transcript-summarize /tmp/youtube-captions/VIDEO_ID.en.txt
```

## Workflow: Video Summarization

```
┌──────────────────┐
│ /youtube-search  │ ← Find videos by keyword
└────────┬─────────┘
         │
         ▼
┌──────────────────┐   ┌──────────────────┐
│ /youtube-info    │   │/youtube-caption│ ← Run independently
│ (optional)       │   │ (required)       │
└────────┬─────────┘   └────────┬─────────┘
         │                      │
         │  metadata in         │  transcript
         │  conversation        │  file path
         │  context             │
         └──────────┬───────────┘
                    │
                    ▼
           ┌──────────────┐
           │/youtube-      │ ← Pass transcript file path
           │ summary       │
           └──────┬───────┘
                  │
                  ▼
           ┌──────────────┐
           │  Structured  │
           │  AI Summary  │
           └──────────────┘

Alternative (for videos without subtitles):
  /youtube-audio → Speech-to-Text → /transcript-summarize (inline text)
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
