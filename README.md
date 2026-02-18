# YouTube Summarizer

Summarize YouTube videos from URL or transcript. Follows the [Agent Skills](https://agentskills.io/) open standard for cross-platform compatibility.

## Platform Compatibility

| Platform | Support | Installation |
|----------|---------|--------------|
| Claude Code | ✅ | `/plugin install` or `/plugin marketplace add` |
| Gemini CLI | ✅ | `gemini extensions install` |
| OpenCode | ✅ | Native Agent Skills |
| VS Code Copilot | ✅ | Native Agent Skills |

## Installation

### Claude Code

**方式 1：直接安裝**
```bash
/plugin install https://github.com/kouko/monkey-knowledge-youtube-skills
```

**方式 2：透過 Marketplace 瀏覽安裝**
```bash
# 1. 加入 marketplace
/plugin marketplace add kouko/monkey-knowledge-youtube-skills

# 2. 開啟互動介面
/plugin

# 3. 進入 Discover 分頁，選擇 youtube-summarizer 安裝
```

### Gemini CLI

```bash
gemini extensions install https://github.com/kouko/monkey-knowledge-youtube-skills
```

### OpenCode

```bash
curl -L https://github.com/kouko/monkey-knowledge-youtube-skills/archive/refs/heads/main.tar.gz | \
  tar -xz --strip-components=1 -C ~/.config/opencode/skills/ \
  "monkey-knowledge-youtube-skills-main/skills/"
```

## Available Skills

| Skill | Description |
|-------|-------------|
| `mk-youtube-search` | Search YouTube videos |
| `mk-youtube-get-info` | Get video metadata |
| `mk-youtube-get-caption` | Download captions/subtitles |
| `mk-youtube-get-audio` | Download audio track |
| `mk-youtube-get-channel-latest` | Get latest videos from a channel |
| `mk-youtube-audio-transcribe` | Transcribe audio using Whisper |
| `mk-youtube-transcript-summarize` | Summarize transcript |
| `mk-youtube-summarize` | End-to-end video summarization |

## Usage

```bash
# Search for videos
/mk-youtube-search "AI tutorial" 5

# Get video info
/mk-youtube-get-info https://www.youtube.com/watch?v=VIDEO_ID

# Summarize a video
/mk-youtube-summarize https://www.youtube.com/watch?v=VIDEO_ID
```

## Features

- Extract video info (title, channel, duration)
- Parse transcript/captions
- Generate structured summary
- Local audio transcription with Whisper.cpp (Metal GPU acceleration on macOS)
- Support multilingual content (EN, JP, ZH-TW)
- Auto-download for dependencies (yt-dlp, ffmpeg, whisper-cli, jq)

## Development

### Local Testing

```bash
# Test plugin locally
claude --plugin-dir .

# Verify skills loaded
/skills
```

### Validate Structure

```bash
claude plugin validate .
```

## Structure

```
monkey-knowledge-youtube-skills/
├── .claude-plugin/
│   ├── marketplace.json        # Claude Code marketplace (互動式瀏覽)
│   └── plugin.json             # Claude Code manifest (直接安裝)
├── gemini-extension.json       # Gemini CLI manifest
├── skills/                     # Agent Skills (cross-platform)
│   ├── mk-youtube-search/
│   ├── mk-youtube-get-info/
│   ├── mk-youtube-get-caption/
│   ├── mk-youtube-get-audio/
│   ├── mk-youtube-get-channel-latest/
│   ├── mk-youtube-audio-transcribe/
│   ├── mk-youtube-transcript-summarize/
│   └── mk-youtube-summarize/
├── CLAUDE.md
├── LICENSE
└── README.md
```

## License

MIT License - see [LICENSE](LICENSE) for details.
