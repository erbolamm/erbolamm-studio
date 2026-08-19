#!/bin/bash
# generate-narration.sh — Genera narración TTS en los 6 idiomas del ecosistema.
# Requiere: python3 -m pip install --break-system-packages edge-tts
#
# Uso:
#   bash generate-narration.sh narration.json outdir/

set -e

NARRATION_FILE="${1:?Uso: bash generate-narration.sh narration.json outdir/}"
OUT_DIR="${2:-.}"
mkdir -p "$OUT_DIR"

if ! command -v edge-tts &> /dev/null; then
  echo "✗ edge-tts no instalado. Ejecuta:"
  echo "  python3 -m pip install --break-system-packages edge-tts"
  exit 1
fi

echo "▸ Narración: $NARRATION_FILE"
echo "▸ Salida: $OUT_DIR/"
echo ""

python3 << PYEOF
import json, subprocess, os, sys

voices = {
    "es": "es-ES-AlvaroNeural",
    "en": "en-US-GuyNeural",
    "pt": "pt-BR-AntonioNeural",
    "fr": "fr-FR-HenriNeural",
    "de": "de-DE-ConradNeural",
    "it": "it-IT-DiegoNeural",
}

with open("$NARRATION_FILE") as f:
    data = json.load(f)

for lang, voice in voices.items():
    text = data.get(lang, "")
    if not text:
        print(f"  ⚠ [{lang}] Sin texto, saltando")
        continue

    output = os.path.join("$OUT_DIR", f"narration-{lang}.mp3")
    print(f"  ▸ [{lang}] {voice}...")
    subprocess.run(
        ["edge-tts", "--voice", voice, "--text", text, "--write-media", output],
        check=True, capture_output=True
    )
    size = os.path.getsize(output)
    print(f"  [{lang}] ✓ narration-{lang}.mp3 ({size//1024} KB)")

print("")
print("✓ Narración generada en 6 idiomas.")
print("")
print("Para mezclar con video:")
print("  bash mix-narration.sh videos/ narration/ final/")
PYEOF
