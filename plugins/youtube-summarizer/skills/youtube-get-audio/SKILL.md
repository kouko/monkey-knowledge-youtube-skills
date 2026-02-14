---
name: youtube-get-audio
description: Download YouTube video audio file. Use when user wants to extract audio or download music/podcast from a video.
license: MIT
metadata:
  version: 1.0.0
  author: kouko
  tags:
    - youtube
    - audio
    - download
compatibility:
  claude-code: ">=1.0.0"
---

# YouTube Audio Download

Download video audio file (best available format, no conversion).

## Quick Start

```
/youtube-get-audio <URL> [output_dir]
```

## Examples

- `/youtube-get-audio https://youtube.com/watch?v=xxx`
- `/youtube-get-audio https://youtube.com/watch?v=xxx ~/Music`

## How it Works

1. Execute: `{baseDir}/scripts/audio.sh "<URL>" "<output_dir>"`
2. Wait for download to complete
3. Parse JSON output to get file path

## Output Format

Success:
```json
{
  "status": "success",
  "file_path": "/tmp/youtube-get-audio/video_title.m4a",
  "file_size": "5.2M"
}
```

Error:
```json
{
  "status": "error",
  "message": "Download failed or file not found"
}
```

## Use Cases

- Download audio for speech-to-text when video has no subtitles
- Podcast or music download

## Notes

- On first run, if yt-dlp or jq is not installed, it will be auto-downloaded
- No ffmpeg required (uses best available format without conversion)
- Output format depends on source (typically m4a, webm, or opus)
- Default output directory: /tmp/youtube-get-audio/
