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
| `youtube-summarizer` | Summarize YouTube videos | `youtube-search`, `youtube-get-info`, `youtube-get-transcript`, `youtube-get-audio`, `youtube-get-channel-latest`, `transcript-summary` |

## Plugin Details

### youtube-summarizer

Summarize YouTube videos from URL or transcript.

**Usage:**
```
/youtube <YouTube URL>
/youtube <transcript text>
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
/skills  # 應顯示 youtube-search, youtube-get-info, youtube-get-transcript, youtube-get-audio, youtube-get-channel-latest, transcript-summary
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
│           ├── youtube-search/
│           │   ├── SKILL.md
│           │   └── scripts/search.sh
│           ├── youtube-get-info/
│           │   ├── SKILL.md
│           │   └── scripts/info.sh
│           ├── youtube-get-transcript/
│           │   ├── SKILL.md
│           │   └── scripts/transcript.sh
│           ├── youtube-get-audio/
│           │   ├── SKILL.md
│           │   └── scripts/audio.sh
│           ├── youtube-get-channel-latest/
│           │   ├── SKILL.md
│           │   └── scripts/channel-latest.sh
│           └── transcript-summary/
│               ├── SKILL.md
│               └── scripts/summary.sh
├── CLAUDE.md
├── LICENSE
└── README.md
```

## License

MIT License - see [LICENSE](LICENSE) for details.
