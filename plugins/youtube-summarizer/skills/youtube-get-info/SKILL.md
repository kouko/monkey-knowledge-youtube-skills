---
name: youtube-get-info
description: Get YouTube video info and summarize content. Use when user provides a YouTube URL and wants video details or summary.
license: MIT
metadata:
  version: 1.0.0
  author: kouko
  tags:
    - youtube
    - info
    - summary
compatibility:
  claude-code: ">=1.0.0"
---

# YouTube Video Info

Get video details and generate content summary.

## Quick Start

```
/youtube-get-info <URL>
```

## Examples

```
/youtube-get-info https://www.youtube.com/watch?v=dQw4w9WgXcQ
```

## How it Works

1. Execute: `{baseDir}/scripts/info.sh "<URL>"`
2. Parse JSON to get video metadata
3. Try to get subtitles for summarization
4. Generate summary based on subtitle content
5. If no subtitles, display video info only

## Output Format

### Video Info
- **Title**: ...
- **Channel**: ...
- **Duration**: ...
- **Views**: ...
- **Upload Date**: ...

### Content Summary
(Generated from subtitle analysis)
- Key point 1
- Key point 2
- ...

## Notes

- On first run, if yt-dlp or jq is not installed, it will be auto-downloaded
