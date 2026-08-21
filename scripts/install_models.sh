#!/usr/bin/env bash
# install_models.sh – Download all AI models to /models
# Usage: bash scripts/install_models.sh [models_dir]
# Requires: huggingface-hub (pip install huggingface-hub)

set -euo pipefail

MODELS_DIR="${1:-/models}"
mkdir -p "$MODELS_DIR"

echo "==> Installing models to $MODELS_DIR"

# ── 1. SkyReels V2 (Image-to-Video, 14B, 720p) ────────────────────────────
# Source: https://huggingface.co/Skywork/SkyReels-V2-I2V-14B-720P
echo ""
echo "[1/4] Downloading SkyReels V2 (Skywork/SkyReels-V2-I2V-14B-720P)..."
python3 -c "
from huggingface_hub import snapshot_download
snapshot_download(
    repo_id='Skywork/SkyReels-V2-I2V-14B-720P',
    cache_dir='$MODELS_DIR',
    ignore_patterns=['*.bin'],   # prefer safetensors
)
"
echo "    SkyReels V2 done."

# ── 2. AudioLDM2 Large ────────────────────────────────────────────────────
# Source: https://huggingface.co/cvssp/audioldm2-large
echo ""
echo "[2/4] Downloading AudioLDM2 Large (cvssp/audioldm2-large)..."
python3 -c "
from huggingface_hub import snapshot_download
snapshot_download(
    repo_id='cvssp/audioldm2-large',
    cache_dir='$MODELS_DIR',
)
"
echo "    AudioLDM2 done."

# ── 3. Tortoise TTS ───────────────────────────────────────────────────────
# Tortoise downloads its own weights on first run via tortoise-tts package.
# We trigger a one-shot download here to pre-cache weights.
# Source: https://huggingface.co/jbetker/tortoise-tts-v2
echo ""
echo "[3/4] Pre-caching Tortoise TTS weights..."
python3 -c "
import os
os.environ['TORTOISE_MODELS_DIR'] = '$MODELS_DIR/tortoise'
from tortoise.api import TextToSpeech
tts = TextToSpeech(models_dir='$MODELS_DIR/tortoise')
print('    Tortoise TTS ready.')
"

# ── 4. Mistral 7B Instruct v0.3 ───────────────────────────────────────────
# Source: https://huggingface.co/mistralai/Mistral-7B-Instruct-v0.3
echo ""
echo "[4/4] Downloading Mistral 7B Instruct v0.3 (mistralai/Mistral-7B-Instruct-v0.3)..."
python3 -c "
from huggingface_hub import snapshot_download
snapshot_download(
    repo_id='mistralai/Mistral-7B-Instruct-v0.3',
    cache_dir='$MODELS_DIR',
)
"
echo "    Mistral 7B done."

echo ""
echo "==> All models downloaded to $MODELS_DIR"
