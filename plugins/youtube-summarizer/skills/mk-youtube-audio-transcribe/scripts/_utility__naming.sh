#!/bin/bash
# 統一命名規則與 metadata 管理函式

# Portable temp directory handling
get_base_tmp() {
    case "$(uname -s)" in
        Darwin|Linux)
            # macOS/Linux: use fixed /tmp for cache consistency
            echo "/tmp"
            ;;
        MINGW*|MSYS*|CYGWIN*)
            # Windows (Git Bash/MSYS/Cygwin): use fixed /tmp for cache consistency
            echo "/tmp"
            ;;
        *)
            # Other platforms: fallback to /tmp
            echo "/tmp"
            ;;
    esac
}

# Centralized directories (all skills share monkey_knowledge base)
MONKEY_KNOWLEDGE_TMP="$(get_base_tmp)/monkey_knowledge"
META_DIR="$MONKEY_KNOWLEDGE_TMP/youtube/meta"

# 生成統一檔案名稱基底（日期 + Video ID）
# 用法: make_basename "$UPLOAD_DATE" "$VIDEO_ID"
# 輸出: 20091025__dQw4w9WgXcQ
make_basename() {
    local upload_date="$1"
    local video_id="$2"
    echo "${upload_date}__${video_id}"
}

# 從 basename 提取 video_id（跳過日期前綴）
# 用法: extract_video_id_from_basename "$BASENAME"
# 輸入: 20091025__dQw4w9WgXcQ
# 輸出: dQw4w9WgXcQ
extract_video_id_from_basename() {
    local basename="$1"
    # 格式: YYYYMMDD__VIDEOID
    # 取第 10-20 字元（0-indexed: 從位置 10 取 11 個字元）
    echo "${basename:10:11}"
}

# 寫入或合併 metadata
# 用法: write_or_merge_meta "$META_FILE" "$NEW_JSON" "$IS_PARTIAL"
# $IS_PARTIAL: "true" 或 "false"
write_or_merge_meta() {
    local meta_file="$1"
    local new_data="$2"
    local is_partial="$3"

    mkdir -p "$(dirname "$meta_file")"

    if [ -f "$meta_file" ]; then
        # 檔案已存在
        local existing_partial
        existing_partial=$("$JQ" -r '.partial // true' "$meta_file")

        if [ "$is_partial" = "true" ] && [ "$existing_partial" = "false" ]; then
            # 新資料是 partial，但現有資料是 complete → 不覆蓋
            return 0
        fi

        # 合併：新資料覆蓋舊資料（但保留舊資料中新資料沒有的欄位）
        "$JQ" -s '.[0] * .[1]' "$meta_file" <(echo "$new_data") > "$meta_file.tmp"
        mv "$meta_file.tmp" "$meta_file"
    else
        # 檔案不存在 → 直接寫入
        echo "$new_data" > "$meta_file"
    fi
}

# 依 video_id 尋找 metadata 檔案
# 用法: find_meta_by_id "$VIDEO_ID"
# 輸出: 檔案路徑 或 空字串
find_meta_by_id() {
    local video_id="$1"
    local found
    # 格式: YYYYMMDD__VIDEO_ID.meta.json
    found=$(find "$META_DIR" -maxdepth 1 -name "*__${video_id}.meta.json" 2>/dev/null | head -1)
    echo "$found"
}

# 讀取 metadata
# 用法: read_meta "$VIDEO_ID"
# 輸出: JSON 內容 或 空字串
read_meta() {
    local video_id="$1"
    local meta_file
    meta_file=$(find_meta_by_id "$video_id")
    if [ -n "$meta_file" ] && [ -f "$meta_file" ]; then
        cat "$meta_file"
    fi
}

# 依 video_id 尋找檔案
# 用法: find_file_by_id "$DIR" "$VIDEO_ID" "$PATTERN"
# 範例: find_file_by_id "$AUDIO_DIR" "dQw4w9WgXcQ" "*.m4a"
# 輸出: 檔案路徑 或 空字串
find_file_by_id() {
    local dir="$1"
    local video_id="$2"
    local pattern="${3:-*}"
    # 格式: YYYYMMDD__VIDEO_ID.EXT
    find "$dir" -maxdepth 1 -name "*__${video_id}${pattern}" 2>/dev/null | head -1
}
