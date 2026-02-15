---
name: youtube-summarize
description: Summarize a YouTube video end-to-end. Use when user wants to summarize, recap, or get key points from a YouTube URL.
license: MIT
metadata:
  version: 1.0.0
  author: kouko
  tags:
    - youtube
    - summarize
    - pipeline
compatibility:
  claude-code: ">=1.0.0"
---

# YouTube Summarize (Pipeline)

End-to-end pipeline that summarizes a YouTube video by orchestrating existing skills in sequence.

## Quick Start

```
/youtube-summarize <URL>
```

## Examples

```
/youtube-summarize https://www.youtube.com/watch?v=dQw4w9WgXcQ
/youtube-summarize https://youtu.be/dQw4w9WgXcQ
```

## Pipeline Flow

```
URL
 │
 ▼
┌──────────────────┐
│ /youtube-get-info │  ← Step 1: Get metadata + check subtitle availability
└────────┬─────────┘
         │
    ┌────┴────┐
    │         │
has_subs   no_subs
    │         │
    ▼         ▼
┌────────┐ ┌──────────┐
│/get-   │ │/get-audio│  ← Step 2a or 2b
│caption │ └────┬─────┘
└───┬────┘       │
    │            ▼
    │     ┌────────────┐
    │     │/audio-     │  ← Step 2c (audio path only)
    │     │transcribe  │
    │     └────┬───────┘
    │          │
    └────┬─────┘
         │
         ▼
┌──────────────────────┐
│ /transcript-summarize  │  ← Step 3: MANDATORY — NEVER SKIP
└──────────────────────┘
```

## Steps

### Step 1: Get Video Info

Use the Skill tool to invoke `/youtube-get-info` with the URL:

```
/youtube-get-info <URL>
```

From the output, note:
- `has_subtitles` and `has_auto_captions` — determines the path for Step 2
- `language` — used for model selection if audio transcription is needed

### Step 2: Get Transcript

Choose ONE path based on subtitle availability from Step 1:

#### Path A — Subtitles available (`has_subtitles: true` OR `has_auto_captions: true`)

Use the Skill tool to invoke `/youtube-get-caption`:

```
/youtube-get-caption <URL>
```

Save the `text_file_path` from the output for Step 3.

#### Path B — No subtitles (`has_subtitles: false` AND `has_auto_captions: false`)

First, use the Skill tool to invoke `/youtube-get-audio`:

```
/youtube-get-audio <URL>
```

Then, use the Skill tool to invoke `/youtube-audio-transcribe` with the `file_path` from the audio output:

```
/youtube-audio-transcribe <file_path> auto <language>
```

Pass the `language` from Step 1 for best model auto-selection (e.g., `zh` → belle-zh, `ja` → kotoba-ja).

Save the `text_file_path` from the output for Step 3.

### Step 3: Generate Summary — MANDATORY — NEVER SKIP

Use the Skill tool to invoke `/transcript-summarize` with the `text_file_path` obtained from Step 2:

```
/transcript-summarize <text_file_path>
```

**CRITICAL**: You MUST use the Skill tool to invoke `/transcript-summarize`. Do NOT generate summaries directly. The skill contains critical rules for:
- Compression ratio calibration
- Section structure requirements
- Numerical data preservation
- Language handling

Skipping this step or generating summaries without the skill will produce lower-quality output.

## Processing Multiple Videos

When summarizing multiple videos in sequence, execute ALL steps (1 → 2 → 3) for EACH video independently. Do NOT batch Step 1 for all videos and then do Step 3 — complete the full pipeline per video before moving to the next.

## Notes

- This is a pure orchestration skill — it does not have its own scripts
- Each sub-skill handles its own dependency management (yt-dlp, jq, whisper-cli, etc.)
- For batch processing, consider processing videos one at a time to avoid context overflow
