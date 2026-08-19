#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# 🗣️ Voice Pipeline Setup — Instala dependencias de clonación
# ═══════════════════════════════════════════════════════════════
# Uso: ./setup_voice.sh [--gpu]
#
# Crea un virtualenv e instala:
#   - torch (CPU o CUDA)
#   - TTS (Coqui XTTS v2)
#   - soundfile
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VENV_DIR="$SCRIPT_DIR/.venv"
USE_GPU=false

if [[ "${1:-}" == "--gpu" ]]; then
    USE_GPU=true
fi

echo "🗣️ Instalando Voice Pipeline..."

# Crear virtualenv
if [[ ! -d "$VENV_DIR" ]]; then
    echo "📦 Creando virtualenv..."
    python3 -m venv "$VENV_DIR"
fi

source "$VENV_DIR/bin/activate"

# Actualizar pip
pip install --upgrade pip

# Instalar torch
if [[ "$(uname)" == "Darwin" ]]; then
    echo "🍎 macOS detected — installing torch (CPU)"
    pip install torch torchaudio
elif $USE_GPU; then
    echo "🖥️ GPU mode — installing torch with CUDA"
    pip install torch torchaudio --index-url https://download.pytorch.org/whl/cu118
else
    echo "💻 CPU mode — installing torch"
    pip install torch torchaudio --index-url https://download.pytorch.org/whl/cpu
fi

# Instalar TTS y dependencias
pip install TTS soundfile

echo ""
echo "✅ Voice Pipeline instalado"
echo "   Python: $(python3 --version)"
echo "   Torch: $(python3 -c 'import torch; print(torch.__version__)')"
echo "   TTS: $(python3 -c 'from TTS.api import TTS; print(TTS.__module__)')"
echo ""
echo "Ejecutá el pipeline: python3 voice_pipeline.py check"
