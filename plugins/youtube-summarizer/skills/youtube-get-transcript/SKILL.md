---
name: youtube-get-transcript
description: Download YouTube video subtitles. Use when user wants to get transcript or captions from a video.
license: MIT
metadata:
  version: 1.1.0
  author: kouko
  tags:
    - youtube
    - transcript
    - subtitle
compatibility:
  claude-code: ">=1.0.0"
---

# YouTube Transcript Download

Download video subtitles and display content. Automatically detects video's original language and distinguishes between manual and auto-generated subtitles.

## Quick Start

```
/youtube-get-transcript <URL> [language|auto]
```

## Examples

- `/youtube-get-transcript https://youtube.com/watch?v=xxx` - Auto-detect original language
- `/youtube-get-transcript https://youtube.com/watch?v=xxx auto` - Explicitly use original language
- `/youtube-get-transcript https://youtube.com/watch?v=xxx ja` - Download Japanese subtitles
- `/youtube-get-transcript https://youtube.com/watch?v=xxx "zh-TW,en"` - Language priority list

## Language Options

| Value | Behavior |
|-------|----------|
| (empty) | Auto-detect video's original language |
| `auto` | Same as empty |
| `en`, `ja`, etc. | Specific language code |
| `"en,ja,zh-TW"` | Comma-separated priority list |

## How it Works

1. Execute: `{baseDir}/scripts/transcript.sh "<URL>" "<language>"`
2. If no language specified, detect video's original language
3. Try to download manual (author-uploaded) subtitles first
4. If unavailable, fall back to auto-generated subtitles
5. Parse JSON output to get file path and metadata
6. Use Read tool to get subtitle content if needed

## Output Format

Success:
```json
{
  "status": "success",
  "file_path": "/tmp/youtube-get-transcripts/VIDEO_ID.en.srt",
  "text_file_path": "/tmp/youtube-get-transcripts/VIDEO_ID.en.txt",
  "language": "en",
  "subtitle_type": "manual",
  "char_count": 30287,
  "line_count": 1555,
  "text_char_count": 25000,
  "text_line_count": 800
}
```

Error:
```json
{
  "status": "error",
  "message": "No subtitles found (this video may not have subtitles)"
}
```

## Output Fields

| Field | Description |
|-------|-------------|
| `file_path` | Absolute path to the downloaded SRT file |
| `text_file_path` | Absolute path to plain text file (no timestamps) |
| `language` | Detected language code of the downloaded subtitle |
| `subtitle_type` | `manual` (author-uploaded) or `auto-generated` (YouTube AI) |
| `char_count` | Number of characters in the SRT file |
| `line_count` | Number of lines in the SRT file |
| `text_char_count` | Number of characters in the plain text file |
| `text_line_count` | Number of lines in the plain text file |

## Notes

- On first run, if yt-dlp or jq is not installed, it will be auto-downloaded
- Some videos may not have subtitles
- Manual subtitles are prioritized over auto-generated ones
- Auto-generated subtitles may be less accurate
