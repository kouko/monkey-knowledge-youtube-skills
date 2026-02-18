---
name: release
description: Use when publishing a new version — bumps versions across all config files, updates CHANGELOG, verifies utility sync, commits, creates PR, and tags release
---

# Release New Version

## Quick Start

```
/project:release <version>
```

| Parameter | Description |
|-----------|-------------|
| `version` | Target version (e.g. `1.2.0`). Determines SemVer bump level |

## How it Works

### 1. Determine Version Bump

Analyze commits since last release (`git log <last-tag>..HEAD`) and apply:

| Commit Type | Bump | Example |
|-------------|------|---------|
| feat | Minor | 1.0.0 → 1.1.0 |
| refactor | Minor | 1.1.0 → 1.2.0 |
| fix / internal | Patch | 1.0.0 → 1.0.1 |
| breaking change | Major | 1.0.0 → 2.0.0 |

### 2. Bump Skill Versions

Update `metadata.version` in each `skills/*/SKILL.md`:
- Skills with functional changes: Minor or Patch based on scope
- Skills with only `_utility__` changes: Patch bump

### 3. Bump Plugin Version

Update version in **all 3 files** (must be identical):

| File | Fields |
|------|--------|
| `.claude-plugin/plugin.json` | `version` |
| `.claude-plugin/marketplace.json` | `metadata.version` + `plugins[0].version` |
| `gemini-extension.json` | `version` |

### 4. Update CHANGELOG.md

Insert new section **before** the previous version entry.
Format: [Keep a Changelog](https://keepachangelog.com/)

Sections: Added / Changed / Fixed / Internal

Append comparison link at bottom:
`[X.Y.Z]: https://github.com/kouko/monkey-knowledge-youtube-skills/compare/vPREV...vX.Y.Z`

### 5. Verify

Run `bash scripts/verify-utility-sync.sh` — all `_utility__` copies must be identical.

### 6. Commit & PR

1. Commit: `chore: bump version to X.Y.Z`
2. Push branch → Create PR → Merge

### 7. Tag & GitHub Release

After PR merge, on main:
```bash
git tag vX.Y.Z
git push origin vX.Y.Z
gh release create vX.Y.Z --title "vX.Y.Z" --notes "<CHANGELOG content for this version>"
```

## Checklist

- [ ] All `skills/*/SKILL.md` versions bumped
- [ ] 3 plugin/extension configs have identical version
- [ ] CHANGELOG.md has new version section + comparison link
- [ ] `verify-utility-sync.sh` passes
- [ ] Commit message follows `chore: bump version to X.Y.Z`
- [ ] PR created and merged
- [ ] Tag pushed
- [ ] GitHub Release created (with release notes from CHANGELOG)
