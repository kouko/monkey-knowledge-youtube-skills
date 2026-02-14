# YouTube Audio Skill

Download audio from YouTube videos.

## Overview

This skill extracts audio from YouTube videos using `yt-dlp`. The output is in the best available format (typically m4a, webm, or opus) without conversion. The script returns a JSON response with the file path for easy LLM integration.

## File Structure

```
youtube-get-audio/
├── SKILL.md              # Skill definition for Claude Code
├── README.md             # This file
├── bin/                  # Auto-downloaded binaries (initially empty)
│   └── .gitkeep
└── scripts/
    ├── _ensure_ytdlp.sh  # Ensures yt-dlp is available
    ├── _ensure_jq.sh     # Ensures jq is available
    └── audio.sh          # Main audio download script
```

## Dependencies

| Dependency | Purpose | Auto-download |
|------------|---------|---------------|
| yt-dlp | Video/audio download | Yes |
| jq | JSON output formatting | Yes |
| curl/wget | Download binaries | Required (pre-installed) |

**Note**: No ffmpeg required. Audio is downloaded in the best available format without conversion.

## Script: `audio.sh`

### Usage

```bash
./scripts/audio.sh "<URL>" [output_dir]
```

### Parameters

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| URL | Yes | - | YouTube video URL |
| output_dir | No | /tmp/youtube-audio/ | Output directory |

### Output Format (JSON)

**Success:**
```json
{
  "status": "success",
  "file_path": "/tmp/youtube-audio/video_title.m4a",
  "file_size": "5.2M"
}
```

**Error:**
```json
{
  "status": "error",
  "message": "Download failed or file not found"
}
```

### Output Fields

| Field | Type | Description |
|-------|------|-------------|
| status | string | "success" or "error" |
| file_path | string | Absolute path to MP3 file |
| file_size | string | Human-readable file size |
| message | string | Error message (only on failure) |

## Examples

```bash
# Download to default location
./scripts/audio.sh "https://www.youtube.com/watch?v=xxx"

# Download to custom directory
./scripts/audio.sh "https://www.youtube.com/watch?v=xxx" ~/Music

# Download to current directory
./scripts/audio.sh "https://www.youtube.com/watch?v=xxx" .
```

## How It Works

```
┌─────────────────────┐
│     audio.sh        │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Load dependencies  │
│  _ensure_ytdlp.sh   │
│  _ensure_jq.sh      │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Create output dir  │
│  mkdir -p           │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  yt-dlp download    │
│  -x (extract audio) │
│  best available fmt │
│  (stderr output)    │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Find audio file    │
│  ls -t | head -1    │
└──────────┬──────────┘
           │
     ┌─────┴─────┐
     │           │
  Found?      Not Found
     │           │
     ▼           ▼
┌─────────┐  ┌─────────┐
│ Success │  │  Error  │
│  JSON   │  │  JSON   │
└─────────┘  └─────────┘
```

## Audio Format

The script downloads audio in the best available format without conversion:

- **Format**: Typically m4a, webm, or opus (depends on source)
- **Quality**: Best available from YouTube
- **Channels**: Same as source (usually stereo)
- **No conversion**: No ffmpeg required

## Output Location

| Directory | Persistence | Notes |
|-----------|-------------|-------|
| `/tmp/youtube-audio/` | Until reboot | Default location |
| `~/Music/` | Permanent | Recommended for keeping |
| Custom path | Permanent | User-specified |

## Use Cases

1. **Speech-to-text**: Download audio when video has no subtitles
2. **Podcast extraction**: Save podcast audio for offline listening
3. **Music download**: Extract music from music videos
4. **Content analysis**: Audio analysis with external tools

## Integration with LLM

The JSON output is designed for easy LLM parsing:

```python
import json

# Parse script output
result = json.loads(output)

if result["status"] == "success":
    audio_file = result["file_path"]
    # Process audio file...
else:
    error = result["message"]
    # Handle error...
```

## Error Handling

| Error | Cause | Solution |
|-------|-------|----------|
| `Download failed` | Invalid URL or network error | Check URL and connection |
| `File not found` | Download failed | Check disk space and permissions |

## Troubleshooting

### Permission errors

```bash
# Check output directory permissions
ls -la /tmp/youtube-audio/

# Create directory if needed
mkdir -p /tmp/youtube-audio/
```

### Disk space

```bash
# Check available space
df -h /tmp/
```

## License

MIT
