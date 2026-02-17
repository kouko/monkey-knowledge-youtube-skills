# Monkey Knowledge Skills

A Claude Code plugin marketplace for productivity skills.

## Installation

```bash
# Add marketplace
/plugin marketplace add kouko/monkey-knowledge-skills

# Install plugin
/plugin install youtube-summarizer@monkey-marketplace
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
│   └── marketplace.json
├── plugins/
│   └── youtube-summarizer/
│       ├── .claude-plugin/
│       │   └── plugin.json
│       └── skills/
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
