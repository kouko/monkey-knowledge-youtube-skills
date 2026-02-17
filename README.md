# Monkey Knowledge Skills

A plugin marketplace for AI coding assistants. Follows the [Agent Skills](https://agentskills.io/) open standard for cross-platform compatibility.

## Platform Compatibility

| Platform | Support | Installation |
|----------|---------|--------------|
| Claude Code | ✅ | `/plugin marketplace add` |
| Gemini CLI | ✅ | `gemini extensions install` |
| OpenCode | ✅ | Native Agent Skills |
| VS Code Copilot | ✅ | Native Agent Skills |

## Installation

### Claude Code

```bash
# 1. Add marketplace
/plugin marketplace add kouko/monkey-knowledge-skills

# 2. Install plugin
/plugin install youtube-summarizer@kouko-monkey-knowledge-skills
```

### Gemini CLI

```bash
gemini extensions install https://github.com/kouko/monkey-knowledge-skills
```

### OpenCode

```bash
curl -sL https://github.com/kouko/monkey-knowledge-skills/archive/refs/heads/main.tar.gz | \
  tar -xz --strip-components=3 -C ~/.config/opencode/skills/ \
  "monkey-knowledge-skills-main/plugins/youtube-summarizer/skills/"
```

## Available Plugins

| Plugin | Description | Skills |
|--------|-------------|--------|
| `youtube-summarizer` | Summarize YouTube videos | `mk-youtube-search`, `mk-youtube-get-info`, `mk-youtube-get-caption`, `mk-youtube-get-audio`, `mk-youtube-get-channel-latest`, `mk-youtube-audio-transcribe`, `mk-youtube-transcript-summarize`, `mk-youtube-summarize` |

## Plugin Details

### youtube-summarizer

Summarize YouTube videos from URL or transcript.

**Usage:**
```
/mk-youtube-summarize <YouTube URL>
```

**Features:**
- Extract video info (title, channel, duration)
- Parse transcript/captions
- Generate structured summary
- Support multilingual content (EN, JP, ZH-TW)

## Development

### Local Testing

```bash
# 測試特定 plugin
claude --plugin-dir ./plugins/youtube-summarizer

# 驗證 skills 載入
/skills  # 應顯示 mk-youtube-search, mk-youtube-get-info, mk-youtube-get-caption, mk-youtube-get-audio, mk-youtube-get-channel-latest, mk-youtube-audio-transcribe, mk-youtube-transcript-summarize, mk-youtube-summarize
```

### Validate Structure

```bash
claude plugin validate .
```

## Structure

```
monkey-knowledge-skills/
├── .claude-plugin/
│   └── marketplace.json        # Claude Code marketplace
├── plugins/
│   └── youtube-summarizer/
│       ├── .claude-plugin/
│       │   └── plugin.json     # Claude Code manifest
│       ├── gemini-extension.json  # Gemini CLI manifest
│       └── skills/             # Agent Skills (cross-platform)
│           ├── mk-youtube-search/
│           ├── mk-youtube-get-info/
│           ├── mk-youtube-get-caption/
│           ├── mk-youtube-get-audio/
│           ├── mk-youtube-get-channel-latest/
│           ├── mk-youtube-audio-transcribe/
│           ├── mk-youtube-transcript-summarize/
│           └── mk-youtube-summarize/
├── CLAUDE.md
├── LICENSE
└── README.md
```

## License

MIT License - see [LICENSE](LICENSE) for details.
