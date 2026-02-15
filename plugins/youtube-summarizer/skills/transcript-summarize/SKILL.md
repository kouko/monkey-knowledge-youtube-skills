---
name: transcript-summarize
description: Summarize YouTube video content with structured output. Use when user wants a detailed summary from a transcript file path or inline transcript text.
license: MIT
metadata:
  version: 2.0.0
  author: kouko
  tags:
    - youtube
    - summary
    - transcript
compatibility:
  claude-code: ">=1.0.0"
---

# YouTube Video Summary

Generate a structured, high-quality summary of a YouTube video from its transcript.

## Quick Start

```
/transcript-summarize <transcript_file_path>
/transcript-summarize (then paste transcript text in conversation)
```

## Examples

- `/transcript-summarize /tmp/youtube-captions/dQw4w9WgXcQ.en.txt` - Summarize from a transcript file
- `/transcript-summarize` followed by pasting transcript text - Summarize inline text

**Typical workflow:**

```
/youtube-get-caption https://youtube.com/watch?v=xxx
→ outputs transcript file path

/transcript-summarize /tmp/youtube-captions/VIDEO_ID.en.txt
→ generates structured summary
```

## How it Works

### Mode A: File Path

1. Execute: `{baseDir}/scripts/summary.sh "<transcript_file_path>"`
2. Parse JSON output to get validated `file_path`, `char_count`, and `strategy`
3. **Follow the processing strategy** indicated by `strategy` field (see **Processing Strategy** below)
4. Generate a structured summary following the **Summary Generation Rules** below

### Mode B: Inline Text

1. The user provides transcript text directly in the conversation (no script execution needed)
2. Generate a structured summary following the **Summary Generation Rules** below

### Processing Strategy (Mode A)

The `strategy` field from `summary.sh` determines how to handle the transcript:

#### Strategy: `standard` (< 80,000 chars, ~2 hr EN)

- Read the entire file with the Read tool
- Directly apply Summary Generation Rules

#### Strategy: `sectioned` (80,000–200,000 chars, ~2 hr – 5 hr EN)

Use a structured multi-phase approach within the main conversation to counter lost-in-middle effects:

1. **Read** the entire file with the Read tool
2. **Phase 1 — Segment identification**: Identify 5-10 major section boundaries (topic shifts, speaker changes, chapter markers) and list them
3. **Phase 2 — Section-by-section extraction**: For each identified section, extract key points, data, quotes, and arguments
4. **Phase 2.5 — Topic grouping** (if > 6 sections identified):
   - Group related sections into 4-6 macro-topics (e.g., "Background & Context", "Core Argument", "Evidence & Examples", "Implications")
   - Under each macro-topic, aggregate the key points from its constituent sections
   - This reduces synthesis pressure in Phase 3 by providing pre-organized intermediate structure
5. **Phase 3 — Synthesis**: Compose the final structured summary from the macro-topics (or directly from sections if ≤ 6), ensuring every identified section is represented
6. **Cross-check**: Verify that mid-content sections are not underrepresented compared to the beginning and end

#### Strategy: `chunked` (> 200,000 chars, > 5 hr EN)

Use parallel subagents to process chunks independently, keeping the main conversation context clean:

1. Calculate chunk count: `ceil(line_count / 1000)` — each chunk is ~1000 lines
2. **Spawn parallel subagents** using the Task tool (`subagent_type: "general-purpose"`):
   - Each subagent receives: the file path, start line offset, end line limit, and summarization instructions
   - **Chunk overlap**: Each chunk includes a 50-line overlap with the previous chunk for context continuity (chunk 1: lines 1–1000, chunk 2: lines 951–2000, chunk 3: lines 1951–3000, etc.). The first chunk has no leading overlap.
   - Each subagent prompt:
     ```
     Read the file at {file_path} from line {start_offset} to line {end_limit} using the Read tool (with offset and limit parameters).
     Then produce a summary of this section with 5-10 bullet points covering:
     - Main topics and arguments discussed
     - Key data points (numbers, dates, names) in **bold**
     - Notable quotes as blockquotes
     Write the summary in the same language as the transcript.
     IMPORTANT — Boundary continuity: If the beginning of your chunk clearly continues a topic from a previous section, prefix your first bullet with [continues from previous]. If the end of your chunk is mid-topic and clearly continues into the next section, suffix your last bullet with [continues to next]. This helps the synthesis step merge cross-chunk topics.
     ```
   - Use `model: "haiku"` for cost efficiency
3. **Collect** all subagent section summaries
4. **Synthesize** a final structured summary in the main conversation following the Summary Generation Rules
   - During synthesis, check for `[continues from previous]` and `[continues to next]` markers across adjacent chunks — merge bullets that belong to the same topic into a single coherent section rather than repeating them

#### Fallback Rules

- **Missing or unknown strategy**: If the `strategy` field is missing, empty, or contains an unrecognized value, default to the `standard` strategy
- **Mode B overflow detection**: If inline transcript text (Mode B) appears exceptionally long (estimated > 80,000 chars), advise the user to save the text to a file and use Mode A instead, so that `summary.sh` can determine the correct processing strategy
- **Chunked subagent retry**: If a subagent in `chunked` mode returns an empty result or clearly irrelevant content (e.g., error messages instead of summary bullets), retry that specific chunk once before proceeding with synthesis

## Summary Generation Rules

After obtaining the transcript, generate the summary using EXACTLY this structure and rules:

### Output Structure

```markdown
## Video Info (optional)

| Field | Value |
|-------|-------|
| **Title** | {title} |
| **Channel** | {channel} |
| **Duration** | {duration_string} |
| **Views** | {view_count, formatted with commas} |
| **Upload Date** | {upload_date, formatted as YYYY-MM-DD} |
| **Subtitle** | {subtitle_type} ({transcript_language}) |

## Content Summary

#### {Section Title 1}

- Bullet point with **key data** highlighted
- Another point
- ...

#### {Section Title 2}

- ...

(Continue for all logical sections)

## Key Takeaways

- 3-5 most important conclusions or insights from the video
```

### Video Info Table

- **Include** the Video Info table if `/youtube-get-info` results are available in the current conversation context
- **Omit** the table if no metadata is available (proceed directly to Content Summary)

### Content Rules

1. **Section structure**: Divide the summary into logical sections using H4 (`####`) headings
   - If the video description contains chapter timestamps, use those as the section skeleton
   - Otherwise, identify 3-8 logical topic shifts in the transcript
   - Each section should have 2-5 bullet points

2. **Data preservation**: Always preserve and highlight specific data points
   - Percentages, dollar amounts, dates, statistics → **bold**
   - Person names, company names, product names → **bold** on first mention
   - Direct quotes that are impactful → use blockquote format

3. **Language**: Write the summary in the same language as the transcript
   - If transcript is in English, summarize in English
   - If transcript is in Japanese, summarize in Japanese
   - If transcript is in Chinese, summarize in Traditional Chinese (繁體中文)

4. **Length**: Target compression ratio based on processing strategy:

   | Strategy | Compression | Guideline |
   |----------|-------------|-----------|
   | `standard` | 10-15% | Short content, detailed coverage |
   | `sectioned` | 8-12% | Medium-long content, balanced density |
   | `chunked` | 7-12% | Very long content, high-level synthesis |

   For Mode B (inline text), use the `standard` ratio as default

5. **Tone**: Maintain an informative, neutral tone
   - Present the speaker's arguments faithfully
   - Do not add opinions or editorial commentary
   - Use active voice

6. **Key Takeaways**: End with 3-5 bullet points summarizing the most important insights
   - These should be standalone — understandable without reading the full summary
   - Prioritize actionable insights and surprising findings

## Output Format

Script JSON output (Mode A only):
```json
{
  "status": "success",
  "file_path": "/tmp/youtube-captions/VIDEO_ID.en.txt",
  "char_count": 30000,
  "line_count": 450,
  "strategy": "standard"
}
```

## Notes

- This skill does NOT download videos or subtitles — use `/youtube-get-caption` first to obtain a transcript file
- On first run, if jq is not installed, it will be auto-downloaded
- For best results, combine with `/youtube-get-info` to include the Video Info table in the summary
