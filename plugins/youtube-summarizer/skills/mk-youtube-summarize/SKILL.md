---
name: mk-youtube-summarize
description: Summarize YouTube videos or channel's latest videos. Use for single video URL, channel URL, or @handle to summarize recent uploads.
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

End-to-end pipeline that summarizes YouTube videos by orchestrating existing skills in sequence. Supports both single video URLs and channels (summarizes latest N videos).

## Quick Start

```
/mk-youtube-summarize <URL|Channel> [count]
```

| Parameter | Description |
|-----------|-------------|
| `URL` | Single video URL (existing behavior) |
| `Channel` | Channel URL, @handle, or channel name |
| `count` | Number of videos to process (default: 3, for channels only) |

## Examples

```bash
# Single video (existing behavior)
/mk-youtube-summarize https://www.youtube.com/watch?v=dQw4w9WgXcQ
/mk-youtube-summarize https://youtu.be/dQw4w9WgXcQ

# Channel's latest 3 videos (default)
/mk-youtube-summarize @RickAstleyYT
/mk-youtube-summarize https://www.youtube.com/@RickAstleyYT

# Channel's latest 5 videos
/mk-youtube-summarize @RickAstleyYT 5

# Get channel from video URL, then summarize latest 3
/mk-youtube-summarize https://www.youtube.com/watch?v=dQw4w9WgXcQ channel
/mk-youtube-summarize https://www.youtube.com/watch?v=dQw4w9WgXcQ channel 5
```

## Pipeline Flow

### Single Video Flow

```
URL (single video)
 │
 ▼
┌───────────────────────────┐
│ /mk-youtube-get-info      │  ← Step 1: Get metadata + check subtitle availability
└────────────┬──────────────┘
             │
        ┌────┴────┐
        │         │
   has_subs    no_subs
        │         │
        ▼         ▼
┌───────────────┐ ┌─────────────────┐
│/mk-youtube-   │ │/mk-youtube-     │  ← Step 2a or 2b
│get-caption    │ │get-audio        │
└───────┬───────┘ └────────┬────────┘
        │                  │
        │                  ▼
        │         ┌─────────────────┐
        │         │/mk-youtube-     │  ← Step 2c (audio path only)
        │         │audio-transcribe │
        │         └────────┬────────┘
        │                  │
        └────────┬─────────┘
                 │
                 ▼
┌────────────────────────────────┐
│ /mk-youtube-transcript-summarize │  ← Step 3: MANDATORY — NEVER SKIP
└────────────────────────────────┘
```

### Channel Flow

```
Channel (@handle, channel URL, or video URL + "channel")
 │
 ▼
┌─────────────────────────────────┐
│ /mk-youtube-get-channel-latest  │  ← Step 0: Get latest N video URLs
│          [channel] [count]      │
└────────────┬────────────────────┘
             │
             ▼
┌─────────────────────────────────┐
│ For each video (1..N):          │
│   Execute full Single Video     │
│   pipeline (Steps 1 → 2 → 3)    │
│   before moving to next video   │
└─────────────────────────────────┘
             │
             ▼
        ✅ All summaries generated
```

## Steps

### Step 0: Detect Input Type

Determine whether input is a single video or a channel:

**Single Video** → proceed to Step 1:
- URL contains `youtube.com/watch?v=`
- URL contains `youtu.be/`
- URL contains `youtube.com/shorts/` (single short)

**Channel** → proceed to Channel Path:
- URL contains `youtube.com/@`
- URL contains `youtube.com/channel/`
- URL contains `youtube.com/c/`
- Input starts with `@` (e.g., `@RickAstleyYT`)
- Input is plain text without URL format (treated as @handle)
- User explicitly provides `channel` keyword after video URL

### Channel Path: Get Latest Videos

Use the Skill tool to invoke `/mk-youtube-get-channel-latest`:

```
/mk-youtube-get-channel-latest <channel> [count]
```

- Default count: **3** (if not specified)
- Maximum recommended: **10** (to avoid excessive processing time)

The output is a JSON array of video objects. For each video in the array, execute the full Single Video pipeline (Steps 1 → 2 → 3) **completely** before moving to the next video.

**Progress Display** (recommended format):
```
Processing 3 videos from @RickAstleyYT...

[1/3] Rick Astley - Never Gonna Give You Up
→ Summary: $TMPDIR/monkey_knowledge/youtube/summaries/20091025__dQw4w9WgXcQ__...md

[2/3] Rick Astley - Together Forever
→ Summary: $TMPDIR/monkey_knowledge/youtube/summaries/19880201__xyz123__...md

[3/3] Rick Astley - Take Me to Your Heart
→ Summary: $TMPDIR/monkey_knowledge/youtube/summaries/19880815__abc456__...md

✅ Completed: 3/3 summaries generated
```

---

### Step 1: Get Video Info

Use the Skill tool to invoke `/mk-youtube-get-info` with the URL:

```
/mk-youtube-get-info <URL>
```

From the output, note:
- `has_subtitles` and `has_auto_captions` — determines the path for Step 2
- `language` — used for model selection if audio transcription is needed

### Step 2: Get Transcript

Choose ONE path based on subtitle availability from Step 1:

#### Path A — Subtitles available (`has_subtitles: true` OR `has_auto_captions: true`)

Use the Skill tool to invoke `/mk-youtube-get-caption`:

```
/mk-youtube-get-caption <URL>
```

Save the `text_file_path` from the output for Step 3.

#### Path B — No subtitles (`has_subtitles: false` AND `has_auto_captions: false`)

First, use the Skill tool to invoke `/mk-youtube-get-audio`:

```
/mk-youtube-get-audio <URL>
```

Then, use the Skill tool to invoke `/mk-youtube-audio-transcribe` with the `file_path` from the audio output:

```
/mk-youtube-audio-transcribe <file_path> auto <language>
```

Pass the `language` from Step 1 for best model auto-selection (e.g., `zh` → belle-zh, `ja` → kotoba-ja).

Save the `text_file_path` from the output for Step 3.

### Step 3: Generate Summary — MANDATORY — NEVER SKIP

Use the Skill tool to invoke `/mk-youtube-transcript-summarize` with the `text_file_path` obtained from Step 2:

```
/mk-youtube-transcript-summarize <text_file_path>
```

**CRITICAL**: You MUST use the Skill tool to invoke `/mk-youtube-transcript-summarize`. Do NOT generate summaries directly. The skill contains critical rules for:
- Compression ratio calibration
- Section structure requirements
- Numerical data preservation
- Language handling

Skipping this step or generating summaries without the skill will produce lower-quality output.

**Display Rule**: The `/mk-youtube-transcript-summarize` skill will generate and save the full summary. You MUST display the COMPLETE summary content to the user as-is. Do NOT create a condensed or abbreviated version after the summary is generated.

## Processing Multiple Videos

When summarizing multiple videos (either from a channel or manually specified):
- Execute ALL steps (1 → 2 → 3) for EACH video **independently**
- Do NOT batch Step 1 for all videos and then do Step 3
- Complete the full pipeline per video before moving to the next
- Display progress after each video completion

## Notes

- This is a pure orchestration skill — it does not have its own scripts
- Each sub-skill handles its own dependency management (yt-dlp, jq, whisper-cli, etc.)
- For batch processing, consider limiting count to avoid context overflow
- Channel processing uses `/mk-youtube-get-channel-latest` which auto-detects channel from video URLs
