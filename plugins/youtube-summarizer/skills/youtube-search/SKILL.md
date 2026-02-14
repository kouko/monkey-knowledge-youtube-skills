---
name: youtube-search
description: Search YouTube videos. Use when user wants to find videos by keyword or topic.
license: MIT
metadata:
  version: 1.0.0
  author: kouko
  tags:
    - youtube
    - search
    - video
compatibility:
  claude-code: ">=1.0.0"
---

# YouTube Search

Search YouTube videos and list results.

## Quick Start

```
/youtube-search <query> [count]
```

## Examples

- `/youtube-search AI tutorial`
- `/youtube-search "machine learning" 10`

## How it Works

1. Execute: `{baseDir}/scripts/search.sh "<query>" <count>`
2. Parse JSON output
3. Display results in table format

## Output Format

| # | Title | Duration | Views | URL |
|---|-------|----------|-------|-----|
| 1 | ... | 10:23 | 1.2M | https://... |

## Notes

- Default result limit: 5 videos
- On first run, if yt-dlp or jq is not installed, it will be auto-downloaded
