# Transcript Summarize Skill

Generate structured, high-quality summaries of YouTube videos from transcript text.

## Overview

This skill takes a transcript file path and produces a consistent, structured summary. It is fully independent — no dependency on sibling skills. Use `/mk-youtube-get-caption` separately to obtain a transcript file, then pass the file path to this skill.

## File Structure

```
mk-youtube-transcript-summarize/
├── SKILL.md              # Skill definition with summary prompt template
├── README.md             # This file
├── bin/                  # Auto-downloaded binaries (initially empty)
│   └── .gitkeep
└── scripts/
    ├── _utility__ensure_jq.sh     # Ensures jq is available
    ├── _utility__naming.sh        # Unified naming and metadata functions
    └── summary.sh        # File validation script
```

## Dependencies

| Dependency | Purpose | Auto-download |
|------------|---------|---------------|
| jq | JSON formatting | Yes |
| curl/wget | Download binaries | Required (pre-installed) |

## Script: `summary.sh`

### Usage

```bash
./scripts/summary.sh "<transcript_file_path>"
```

### Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| transcript_file_path | Yes | Path to a plain text transcript file |

### Output Format

```json
{
  "status": "success",
  "source_transcript": "/tmp/monkey_knowledge/youtube/captions/20091025__VIDEO_ID.en.txt",
  "output_summary": "/tmp/monkey_knowledge/youtube/summaries/20091025__VIDEO_ID.en.md",
  "char_count": 30000,
  "line_count": 450,
  "strategy": "standard",
  "video_id": "dQw4w9WgXcQ",
  "title": "Video Title",
  "channel": "Channel Name",
  "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
}
```

### Output Fields

| Field | Type | Description |
|-------|------|-------------|
| status | string | `success` or `error` |
| source_transcript | string | Absolute path to the input transcript file |
| output_summary | string | Expected output path for the generated summary |
| char_count | number | Character count of the file |
| line_count | number | Line count of the file |
| strategy | string | Processing strategy: `standard`, `sectioned`, or `chunked` |
| video_id | string | YouTube video ID (from centralized metadata store) |
| title | string | Video title (from centralized metadata store) |
| channel | string | Channel name (from centralized metadata store) |
| url | string | Full video URL (from centralized metadata store) |

## Examples

```bash
# Validate a transcript file
./scripts/summary.sh "/tmp/monkey_knowledge/youtube/captions/20091025__dQw4w9WgXcQ.en.txt"

# Typical workflow in Claude Code
# Step 1: Download transcript
/mk-youtube-get-caption https://www.youtube.com/watch?v=xxx
# Step 2: Summarize from the downloaded file
/mk-youtube-transcript-summarize /tmp/monkey_knowledge/youtube/captions/20091025__VIDEO_ID.en.txt
```

## How It Works

```
  /mk-youtube-transcript-summarize /tmp/monkey_knowledge/youtube/captions/20091025__VIDEO_ID.en.txt
           │
           ▼
  ┌───────────────────┐
  │    summary.sh     │  ← Validate file + determine strategy
  │  (file_path arg)  │     + read metadata from /tmp/monkey_knowledge/youtube/meta/
  └────────┬──────────┘
           │
           ▼
  ┌───────────────────┐
  │  JSON response    │  ← {status, source_transcript, output_summary, metadata...}
  └────────┬──────────┘
           │
           ▼
  ┌─────────────────────────────────────────────────────┐
  │              Strategy Router                         │
  ├──────────┬─────────────────┬────────────────────────┤
  │ standard │    sectioned    │       chunked          │
  │ < 80K    │  80K–200K       │       > 200K           │
  │          │                 │                        │
  │ Read all │  Read all       │  Parallel subagents    │
  │ Summarize│  Segment → ①②③ │  (Task tool, haiku)    │
  │          │  Cross-check    │  Collect → Synthesize  │
  └──────────┴─────────────────┴────────────────────────┘
           │
           ▼
  ┌───────────────────┐
  │  Structured       │  ← Following SKILL.md prompt rules
  │  Summary Output   │     Save to /tmp/monkey_knowledge/youtube/summaries/
  └───────────────────┘
```

## Long Content Handling

The skill uses a three-tier strategy to handle transcripts of varying length, optimizing for summary quality and context window efficiency.

### Strategy Overview

| Strategy | Char Range | Approx. Duration (EN) | Approach |
|----------|-----------|----------------------|----------|
| `standard` | < 80,000 | < 2 hr | Single read + direct summary |
| `sectioned` | 80,000–200,000 | 2 hr – 5 hr | Single read + phased segmentation to counter lost-in-middle |
| `chunked` | > 200,000 | > 5 hr | Parallel subagents per ~1000-line chunk → synthesis |

### Why Three Strategies?

- **Lost-in-middle**: LLMs recall beginning/end of long text well, but mid-section accuracy drops to 40-60% (Stanford research)
- **Context pollution**: A 200K-char transcript consumes ~50K tokens, reducing main conversation capacity
- **Cost efficiency**: Short videos don't need subagent overhead; very long videos benefit from parallel processing

### Chunked Strategy Flow

```
Main Conversation              Subagent 1     Subagent 2     Subagent 3
  │                               │              │              │
  │ summary.sh → strategy:"chunked", line_count:3000            │
  │                               │              │              │
  │── Task tool (parallel) ──────►│              │              │
  │── Task tool (parallel) ───────────────────►  │              │
  │── Task tool (parallel) ──────────────────────────────────► │
  │                               │              │              │
  │                          Read lines     Read lines     Read lines
  │                          1–1000         1001–2000      2001–3000
  │                          → 5-10 bullets → 5-10 bullets → 5-10 bullets
  │                               │              │              │
  │◄─── Section 1 summary ───────│              │              │
  │◄─── Section 2 summary ──────────────────── │              │
  │◄─── Section 3 summary ─────────────────────────────────── │
  │                                                             │
  │  Main context receives only ~1500 tokens of condensed       │
  │  summaries (not 200K+ chars of raw transcript)              │
  │                                                             │
  │  Synthesize final structured summary                        │
  ▼
```

## Error Handling

| Error | Cause | Solution |
|-------|-------|----------|
| `Usage: summary.sh <transcript_file_path>` | No argument provided | Pass a transcript file path |
| `File not found: <path>` | File does not exist | Check the file path; run `/mk-youtube-get-caption` first |

## License

MIT
