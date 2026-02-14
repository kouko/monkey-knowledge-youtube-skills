# YouTube Search Skill

Search YouTube videos by keyword and return structured results.

## Overview

This skill uses `yt-dlp` to search YouTube and returns video metadata in JSON format. It supports automatic dependency management - if `yt-dlp` or `jq` is not installed on the system, it will be downloaded automatically.

## File Structure

```
youtube-search/
├── SKILL.md              # Skill definition for Claude Code
├── README.md             # This file
├── bin/                  # Auto-downloaded binaries (initially empty)
│   └── .gitkeep
└── scripts/
    ├── _ensure_ytdlp.sh  # Ensures yt-dlp is available
    ├── _ensure_jq.sh     # Ensures jq is available
    └── search.sh         # Main search script
```

## Dependencies

| Dependency | Purpose | Auto-download |
|------------|---------|---------------|
| yt-dlp | YouTube search | Yes |
| jq | JSON formatting | Yes |
| curl/wget | Download binaries | Required (pre-installed) |

## Dependency Management

### `_ensure_ytdlp.sh`

```
Priority:
1. System-installed yt-dlp (command -v yt-dlp)
2. Previously downloaded binary in bin/
3. Auto-download from GitHub releases
```

### `_ensure_jq.sh`

```
Priority:
1. System-installed jq (command -v jq)
2. Previously downloaded binary in bin/
3. Auto-download based on OS + CPU architecture:
   - macOS Intel: jq-macos-amd64
   - macOS ARM: jq-macos-arm64
   - Linux x64: jq-linux-amd64
   - Linux ARM: jq-linux-arm64
   - Windows: jq-win64.exe
```

## Script: `search.sh`

### Usage

```bash
./scripts/search.sh "<query>" [count]
```

### Parameters

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| query | Yes | - | Search keywords |
| count | No | 5 | Number of results |

### Output Format

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

## Examples

```bash
# Search for AI tutorials (default 5 results)
./scripts/search.sh "AI tutorial"

# Search with specific count
./scripts/search.sh "machine learning" 10

# Search with quoted phrase
./scripts/search.sh "\"deep learning\" beginner" 3
```

## How It Works

```
┌─────────────────┐
│  search.sh      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐     ┌─────────────────┐
│ _ensure_ytdlp   │────▶│ $YT_DLP         │
└─────────────────┘     └────────┬────────┘
                                 │
┌─────────────────┐              │
│ _ensure_jq      │────▶ $JQ    │
└─────────────────┘              │
                                 ▼
                        ┌─────────────────┐
                        │ yt-dlp search   │
                        │ ytsearch5:query │
                        └────────┬────────┘
                                 │
                                 ▼
                        ┌─────────────────┐
                        │ jq transform    │
                        │ JSON output     │
                        └─────────────────┘
```

## Error Handling

| Error | Cause | Solution |
|-------|-------|----------|
| `ERROR: Unsupported platform` | OS not recognized | Check `uname -s` output |
| `ERROR: curl or wget required` | No download tool | Install curl or wget |
| Empty output | No search results | Try different keywords |

## License

MIT
