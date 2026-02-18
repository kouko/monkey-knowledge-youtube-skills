# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [1.1.0] - 2026-02-18

### Added
- `--check` mode for `mk-youtube-transcript-summarize`: verify cached summary without running pipeline
- `--force` flag support in `mk-youtube-summarize` pipeline
- Skill-local `data/` directories for output (get-caption, audio-transcribe, transcript-summarize)

### Changed
- Redesigned caption language detection as 3-stage cascading download strategy
  - Stage 1-2: Primary language (metadata → subtitle list → yt-dlp query)
  - Stage 3: yt-dlp built-in fallback (any language)
- Skill outputs relocated from centralized `/tmp/` to skill-local `data/` directories
- Updated documentation paths in audio-transcribe and get-caption

### Fixed
- Use portable `$TMPDIR` instead of hard-coded `/tmp` for sandbox compatibility (e.g. Gemini CLI Seatbelt)

### Internal
- Renamed plugin/extension name to match repository name

## [1.0.3] - 2026-02-18

### Changed
- Flatten directory structure for cross-platform compatibility
  - `plugins/youtube-summarizer/skills/` → `skills/`
  - `plugins/youtube-summarizer/.claude-plugin/` → `.claude-plugin/`
  - `plugins/youtube-summarizer/scripts/` → `scripts/`
- Rename repository to `monkey-knowledge-youtube-skills`
- Clarify interactive installation steps in README

### Fixed
- Update script paths in `verify-utility-sync.sh`, `build-binaries.sh`, `download-binaries.sh` for flat structure

## [1.0.2] - 2026-02-18

### Fixed
- Add root-level `gemini-extension.json` for direct repo install
- Add `.claude-plugin/plugin.json` for direct URL installation

## [1.0.1] - 2026-02-17

### Added
- Gemini CLI extension support (`gemini-extension.json`)
- Multi-platform installation docs (Claude Code, Gemini CLI, OpenCode)
- OpenCode remote install via curl

### Fixed
- Add missing plugin install step for Claude Code

## [1.0.0] - 2026-02-17

### Added
- 8 YouTube skills: search, get-info, get-caption, get-audio, get-channel-latest, audio-transcribe, transcript-summarize, summarize
- `mk-youtube-audio-transcribe` with local Whisper transcription and Metal GPU acceleration
- `mk-youtube-get-channel-latest` for batch channel content
- `mk-youtube-summarize` pipeline for end-to-end video summarization
- Centralized metadata storage (`/tmp/monkey_knowledge/youtube/meta/`)
- Unified filename convention (`{YYYYMMDD}__{video_id}`)
- Cross-platform binary support (macOS ARM64/x86_64, Linux ARM64/x86_64)
- Auto-download for dependencies (jq, yt-dlp, ffmpeg, whisper-cli, whisper models)
- Cookie fallback for restricted/members-only videos
- File cache with `--force` flag for re-download
- macOS Gatekeeper & Quarantine documentation

[1.1.0]: https://github.com/kouko/monkey-knowledge-youtube-skills/compare/v1.0.3...v1.1.0
[1.0.3]: https://github.com/kouko/monkey-knowledge-youtube-skills/compare/v1.0.2...v1.0.3
[1.0.2]: https://github.com/kouko/monkey-knowledge-youtube-skills/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/kouko/monkey-knowledge-youtube-skills/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/kouko/monkey-knowledge-youtube-skills/releases/tag/v1.0.0
