# YouTube Summarize (Pipeline Skill)

## Overview

A pure orchestration skill that summarizes a YouTube video end-to-end by invoking existing sub-skills in sequence. No scripts or binaries — just instructions that guide Claude through the full pipeline.

## File Structure

```
youtube-summarize/
├── SKILL.md        # Pipeline definition (instructions only)
└── README.md       # This file
```

## Dependencies

This skill depends on the following sub-skills (all part of the `youtube-summarizer` plugin):

| Skill | Role | When Used |
|-------|------|-----------|
| `youtube-get-info` | Get video metadata | Always (Step 1) |
| `youtube-get-caption` | Download subtitles | When subtitles available (Step 2a) |
| `youtube-get-audio` | Download audio | When no subtitles (Step 2b) |
| `youtube-audio-transcribe` | Transcribe audio | When no subtitles (Step 2c) |
| `transcript-summarize` | Generate summary | Always (Step 3) |

## How It Works

```
URL ──▶ get-info ──▶ has subtitles? ──┬── YES ──▶ get-caption ──▶ transcript-summarize
                                      │
                                      └── NO  ──▶ get-audio ──▶ audio-transcribe ──▶ transcript-summarize
```

### Decision Logic

1. **Step 1** (`/youtube-get-info`): Retrieve video metadata including `has_subtitles` and `has_auto_captions`
2. **Step 2**: Branch based on subtitle availability
   - **Path A**: If subtitles exist → `/youtube-get-caption`
   - **Path B**: If no subtitles → `/youtube-get-audio` → `/youtube-audio-transcribe`
3. **Step 3** (`/transcript-summarize`): Always invoked via Skill tool — never skipped

## Examples

```
/youtube-summarize https://www.youtube.com/watch?v=dQw4w9WgXcQ
/youtube-summarize https://youtu.be/dQw4w9WgXcQ
```

## Error Handling

| Error | Source | Recovery |
|-------|--------|----------|
| Invalid URL | youtube-get-info | Check URL format |
| No subtitles found | youtube-get-caption | Falls back to audio path |
| Download failed | youtube-get-audio | Check network/cookies |
| Model not found | youtube-audio-transcribe | Download model first |
| Empty transcript | transcript-summarize | Check source quality |

## License

MIT
