#!/bin/bash
# _ensure_model.sh - Ensure whisper model is available
#
# Downloads model from Hugging Face if not present
#
# Usage:
#   source "$(dirname "$0")/_ensure_model.sh" [model_name]
#   echo "Model path: $MODEL_PATH"

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODELS_DIR="$SCRIPT_DIR/../models"

# Model name (default: medium)
MODEL_NAME="${1:-medium}"

# Hugging Face base URL
HF_BASE_URL="https://huggingface.co/ggerganov/whisper.cpp/resolve/main"

# Map model name to local filename
get_model_filename() {
    local name="$1"
    case "$name" in
        # Standard whisper.cpp models
        tiny|tiny.en)     echo "ggml-${name}.bin" ;;
        base|base.en)     echo "ggml-${name}.bin" ;;
        small|small.en)   echo "ggml-${name}.bin" ;;
        medium|medium.en) echo "ggml-${name}.bin" ;;
        large|large-v1)   echo "ggml-large-v1.bin" ;;
        large-v2)         echo "ggml-large-v2.bin" ;;
        large-v3)         echo "ggml-large-v3.bin" ;;
        large-v3-turbo)   echo "ggml-large-v3-turbo.bin" ;;
        # Language-specialized models
        belle-zh)         echo "ggml-belle-zh.bin" ;;
        kotoba-ja)        echo "ggml-kotoba-ja.bin" ;;
        kotoba-ja-q5)     echo "ggml-kotoba-ja-q5.bin" ;;
        *)
            echo "ERROR: Unknown model: $name" >&2
            echo "Available: tiny, base, small, medium, large-v3, belle-zh, kotoba-ja, kotoba-ja-q5" >&2
            exit 1
            ;;
    esac
}

# Get download URL for model
get_model_url() {
    local name="$1"
    case "$name" in
        # Chinese-specialized model (BELLE-2)
        belle-zh)
            echo "https://huggingface.co/BELLE-2/Belle-whisper-large-v3-turbo-zh-ggml/resolve/main/ggml-model.bin"
            ;;
        # Japanese-specialized model (kotoba-tech)
        kotoba-ja)
            echo "https://huggingface.co/kotoba-tech/kotoba-whisper-v2.0-ggml/resolve/main/ggml-kotoba-whisper-v2.0.bin"
            ;;
        kotoba-ja-q5)
            echo "https://huggingface.co/kotoba-tech/kotoba-whisper-v2.0-ggml/resolve/main/ggml-kotoba-whisper-v2.0-q5_0.bin"
            ;;
        # Standard whisper.cpp models
        *)
            local filename
            filename=$(get_model_filename "$name")
            echo "$HF_BASE_URL/$filename"
            ;;
    esac
}

download_model() {
    local model_name="$1"
    local filename
    filename=$(get_model_filename "$model_name")
    local model_path="$MODELS_DIR/$filename"
    local download_url
    download_url=$(get_model_url "$model_name")

    # Check if already downloaded
    if [ -f "$model_path" ]; then
        echo "$model_path"
        return 0
    fi

    echo "[INFO] Downloading model: $filename..." >&2
    mkdir -p "$MODELS_DIR"

    if command -v curl &> /dev/null; then
        curl -L --progress-bar -o "$model_path" "$download_url"
    elif command -v wget &> /dev/null; then
        wget --show-progress -O "$model_path" "$download_url"
    else
        echo "ERROR: curl or wget required to download model" >&2
        exit 1
    fi

    echo "[INFO] Model downloaded: $model_path" >&2
    echo "$model_path"
}

# Get model path
MODEL_PATH="$(download_model "$MODEL_NAME")"
