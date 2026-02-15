---
name: youtube-get-audio
description: Download YouTube video audio file. Use when user wants to extract audio or download music/podcast from a video.
license: MIT
metadata:
  version: 1.1.0
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
/youtube-get-audio <URL> [output_dir] [browser]
```

## Parameters

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| URL | Yes | - | YouTube video URL |
| output_dir | No | /tmp/youtube-audio | Output directory for audio file |
| browser | No | auto | Browser for cookies (chrome, firefox, safari, edge, brave) |

## Examples

- `/youtube-get-audio https://youtube.com/watch?v=xxx` - Download with auto cookie fallback
- `/youtube-get-audio https://youtube.com/watch?v=xxx ~/Music` - Save to custom directory
- `/youtube-get-audio https://youtube.com/watch?v=xxx /tmp chrome` - Use Chrome cookies

## How it Works

1. Execute: `{baseDir}/scripts/audio.sh "<URL>" "<output_dir>" "<browser>"`
2. First attempt: download without authentication
3. If failed: retry with browser cookies (auto-detect or specified)
4. Parse JSON output to get file path

```
┌─────────────────────────────┐
│   First attempt (no auth)   │
└──────────────┬──────────────┘
               │
       ┌───────┴───────┐
       │               │
    Success         Failed
       │               │
       ▼               ▼
   [Return]    ┌─────────────────────┐
               │ Retry with cookies  │
               │ chrome → firefox →  │
               │ safari → edge →     │
               │ brave               │
               └──────────┬──────────┘
                          │
                  ┌───────┴───────┐
                  │               │
               Success         Failed
                  │               │
                  ▼               ▼
              [Return]        [Error]
```

## Output Format

Success:
```json
{
  "status": "success",
  "file_path": "/tmp/youtube-audio/video_title.m4a",
  "file_size": "5.2M"
}
```

Error:
```json
{
  "status": "error",
  "message": "Download failed (tried with and without cookies)"
}
```

## Browser Cookie Fallback

When download fails (e.g., member-only or age-restricted content), the script automatically:

1. Tries each browser: chrome → firefox → safari → edge → brave
2. For Chrome: tries all profiles (Default, Profile 1, Profile 2, ...)
3. Uses first successful browser/profile combination

Supported browsers:

| Browser | Parameter | Chrome Profile Support |
|---------|-----------|------------------------|
| Chrome | `chrome` | Yes (auto-detect all profiles) |
| Firefox | `firefox` | Default profile only |
| Safari | `safari` | Default profile only |
| Edge | `edge` | Default profile only |
| Brave | `brave` | Default profile only |

## Use Cases

- Download audio for speech-to-text when video has no subtitles
- Podcast or music download
- Member-only or age-restricted content (with browser cookies)

## Notes

- On first run, if yt-dlp or jq is not installed, it will be auto-downloaded
- No ffmpeg required (uses best available format without conversion)
- Output format depends on source (typically m4a, webm, or opus)
- Cookie fallback only activates when initial download fails
- Using cookies may risk YouTube account suspension - use secondary account if needed
