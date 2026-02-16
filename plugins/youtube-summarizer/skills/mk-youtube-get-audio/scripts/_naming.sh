#!/bin/bash
# 統一命名規則與 metadata 管理函式

META_DIR="/tmp/youtube-video-meta"

# 清理標題以用於檔案名稱
# 用法: sanitize_title "$TITLE" [max_length]
sanitize_title() {
    local title="$1"
    local max_length="${2:-80}"

    echo "$title" | \
        tr '\n\r' ' ' |                    # 換行 → 空格
        tr -d '/:*?"<>|\\' |               # 移除檔案系統禁用字元
        tr -s ' ' '_' |                    # 連續空格 → 單底線
        sed 's/^_//; s/_$//' |             # 移除首尾底線
        cut -c1-"$max_length"              # 截斷長度
}

# 生成統一檔案名稱基底
# 用法: make_basename "$VIDEO_ID" "$TITLE"
# 輸出: dQw4w9WgXcQ__Rick_Astley_Never_Gonna_Give_You_Up
make_basename() {
    local video_id="$1"
    local title="$2"
    local sanitized
    sanitized=$(sanitize_title "$title" 80)
    echo "${video_id}__${sanitized}"
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
    found=$(ls "$META_DIR/${video_id}"__*.meta.json 2>/dev/null | head -1)
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
