# Plugin Development Guide

## 參考資源

| 資源 | 說明 |
|------|------|
| [Agent Skills 規範](https://agentskills.io/home) | 開放標準規範，支援多種 AI 開發工具 |
| [Claude Code Skills 官方文檔](https://support.claude.com/en/articles/12512198-how-to-create-custom-skills) | SKILL.md 格式與最佳實踐 |
| [Agent Skills 設計理念](https://claude.com/blog/equipping-agents-for-the-real-world-with-agent-skills) | Progressive Disclosure 架構說明 |
| [官方範例 Skills](https://github.com/anthropics/skills) | Anthropic 提供的範例 |
| [Agent Skills GitHub](https://github.com/agentskills/agentskills) | 開放標準與驗證工具 |

## Skill 實作模式

### 目錄結構

每個 skill 遵循獨立自包含的結構：

```
skill-name/
├── SKILL.md           # Claude Code 技能定義（YAML frontmatter）
├── README.md          # 詳細文檔
├── bin/               # 自動下載的 binary（初始為空）
│   └── .gitkeep
└── scripts/
    ├── _ensure_*.sh   # 依賴管理腳本
    └── main.sh        # 主要邏輯腳本
```

### SKILL.md 格式

#### YAML Frontmatter（官方規範）

| 欄位 | 必要性 | 限制 | 說明 |
|------|--------|------|------|
| `name` | **必要** | 最多 64 字元 | 人類可讀的識別名稱 |
| `description` | **必要** | 最多 200 字元 | Claude 用來判斷何時調用此 skill |
| `license` | 選填 | - | 授權類型 |
| `metadata` | 選填 | - | 版本、作者、標籤等 |
| `compatibility` | 選填 | - | 相容性要求 |
| `dependencies` | 選填 | - | 軟體依賴（如 `python>=3.8`） |

```yaml
---
name: skill-name
description: 簡短描述，說明何時使用此 skill（Claude 用此判斷是否調用）
license: MIT
metadata:
  version: 1.0.0
  author: kouko
  tags:
    - domain
    - keyword
compatibility:
  claude-code: ">=1.0.0"
---
```

#### Progressive Disclosure 架構

Skills 採用漸進式載入設計，依需求逐層載入：

| 層級 | 載入時機 | 內容 |
|------|---------|------|
| Level 1 | 啟動時 | name + description（metadata） |
| Level 2 | 相關時 | 完整 SKILL.md 內容 |
| Level 3+ | 需要時 | 額外連結的檔案（REFERENCE.md、scripts） |

#### 內容區段

1. **# Skill 標題** (H1)
2. **## Quick Start** - 指令語法
3. **## Examples** - 使用範例（包含輸入/輸出示例）
4. **## How it Works** - 執行步驟（使用 `{baseDir}` 佔位符）
5. **## Output Format** - JSON 格式範例
6. **## Notes** - 注意事項

### Shell Script 模式

#### 依賴管理腳本 (_ensure_*.sh)

```bash
#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$SCRIPT_DIR/../bin"

get_tool() {
    # 1. 優先使用系統版本
    if command -v tool &> /dev/null; then
        echo "tool"
        return 0
    fi

    # 2. 偵測平台與 CPU 架構
    # uname -s: Darwin/Linux/MINGW*
    # uname -m: x86_64/arm64/aarch64

    # 3. 檢查 bin/ 是否已下載
    # 4. 自動下載對應版本
    # 5. 設定執行權限
}

TOOL="$(get_tool)"
```

#### 主要腳本

```bash
#!/bin/bash
set -e

# 載入依賴
source "$(dirname "$0")/_ensure_tool.sh"

# 參數處理
PARAM="$1"
if [ -z "$PARAM" ]; then
    echo "Usage: script.sh <param>"
    exit 1
fi

# 執行邏輯（進度輸出到 stderr）
"$TOOL" ... >&2

# 輸出 JSON 到 stdout
"$JQ" -n \
    --arg status "success" \
    --arg field "$value" \
    '{status: $status, field: $field}'
```

### JSON 輸出格式

#### 成功

```json
{
  "status": "success",
  "file_path": "/absolute/path/to/file",
  "field": "value"
}
```

#### 失敗

```json
{
  "status": "error",
  "message": "Error description"
}
```

### 依賴管理原則

| 優先順序 | 來源 | 說明 |
|---------|------|------|
| 1 | 系統版本 | `command -v tool` |
| 2 | bin/ 目錄 | 已下載的 binary |
| 3 | 自動下載 | 從 GitHub Releases 下載 |

### 平台支援

| 平台 | 架構 | Binary 命名 |
|------|------|-------------|
| macOS | Intel (x86_64) | tool-macos-amd64 |
| macOS | Apple Silicon (arm64) | tool-macos-arm64 |
| Linux | AMD64 (x86_64) | tool-linux-amd64 |
| Linux | ARM64 (aarch64) | tool-linux-arm64 |
| Windows | x64 | tool-win64.exe |

### README.md 結構

1. **# Skill 名稱**
2. **## Overview** - 功能說明
3. **## File Structure** - 目錄樹
4. **## Dependencies** - 依賴表格
5. **## Script: script.sh** - 腳本詳細說明
6. **## Examples** - 使用範例
7. **## How It Works** - ASCII 流程圖
8. **## Error Handling** - 錯誤處理表格
9. **## License** - MIT

### 最佳實踐

#### 官方建議（來自 Claude 文檔）

1. **Focus（專注）**: 為不同工作流程建立獨立的 skills，而非一個大而全的 skill
2. **Clarity（清晰）**: 撰寫明確的 description，讓 Claude 知道何時啟用
3. **Progression（漸進）**: 先從基本 Markdown 指令開始，再加入複雜腳本
4. **Examples（範例）**: 包含輸入/輸出範例以展示預期結果
5. **Testing（測試）**: 每次重大變更後驗證，而非一次建完所有功能
6. **Composability（組合性）**: Skills 無法直接引用其他 skills，但 Claude 可自動組合使用多個 skills

#### 本專案實踐

1. **Fail-fast**: 使用 `set -e`
2. **輸入驗證**: 在執行前檢查必要參數
3. **輸出分離**: stderr 用於進度/日誌，stdout 用於 JSON 結果
4. **絕對路徑**: 檔案路徑使用絕對路徑
5. **一致性**: 所有 skill 遵循相同的 JSON 格式
6. **獨立性**: 每個 skill 有自己的 bin/ 和依賴腳本

### 安全注意事項

- 只安裝來自可信來源的 skills
- 審查不熟悉的 skills，特別是檢查程式碼依賴和外部網路連線

## 開發與測試

### 本地測試 Plugin

使用 `--plugin-dir` 參數載入本地 plugin：

```bash
# 從專案根目錄測試 youtube-summarizer plugin
claude --plugin-dir ./plugins/youtube-summarizer

# 或使用完整路徑
claude --plugin-dir /path/to/monkey-knowledge-skills/plugins/youtube-summarizer
```

### 驗證 Skills 是否載入

啟動 Claude Code 後：
1. 執行 `/skills` 查看可用 skills
2. 應看到 `youtube-search`、`youtube-get-info`、`youtube-get-transcript`、`youtube-get-audio`、`transcript-summary`
3. 使用 `/youtube-search <query>` 測試功能

### 開發流程

1. 修改 `SKILL.md` 或 `scripts/*.sh`
2. 重新啟動 Claude Code（使用 `--plugin-dir`）
3. 測試修改後的功能
4. 提交變更

## 範例 Plugin

參考 `plugins/youtube-summarizer/` 的實作：
- 5 個獨立 skills（search、get-info、get-transcript、get-audio、transcript-summary）
- 智能依賴管理（yt-dlp、jq 自動下載）
- 統一 JSON 輸出格式
