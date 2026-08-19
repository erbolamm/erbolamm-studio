#!/bin/bash
# mix-narration.sh — Mezcla narración TTS con videos por idioma.
#
# Uso:
#   bash mix-narration.sh videos_dir/ narration_dir/ output_dir/
#
# Busca pares: promo-es.mp4 + narration-es.mp3 → final-es.mp4

set -e

VIDEOS_DIR="${1:?Uso: bash mix-narration.sh videos_dir/ narration_dir/ output_dir/}"
NARRATION_DIR="${2:?Falta: narration_dir/}"
OUT_DIR="${3:-$VIDEOS_DIR/final}"

mkdir -p "$OUT_DIR"

echo "▸ Videos: $VIDEOS_DIR/"
echo "▸ Narración: $NARRATION_DIR/"
echo "▸ Salida: $OUT_DIR/"
echo ""

for LANG in es en pt fr de it; do
  VIDEO="$VIDEOS_DIR/promo-$LANG.mp4"
  AUDIO="$NARRATION_DIR/narration-$LANG.mp3"
  OUTPUT="$OUT_DIR/final-$LANG.mp4"

  if [ ! -f "$VIDEO" ]; then
    echo "  ⚠ [$LANG] No existe $VIDEO, saltando"
    continue
  fi

  if [ ! -f "$AUDIO" ]; then
    echo "  ⚠ [$LANG] No existe $AUDIO, saltando"
    continue
  fi

  echo "  ▸ [$LANG] Mezclando..."

  ffmpeg -y -i "$VIDEO" -i "$AUDIO" \
    -c:v copy -c:a aac -b:a 192k \
    -shortest \
    -map 0:v:0 -map 1:a:0 \
    "$OUTPUT" 2>/dev/null

  SIZE=$(du -h "$OUTPUT" | cut -f1)
  echo "  [$LANG] ✓ final-$LANG.mp4 ($SIZE)"
done

echo ""
echo "✓ Videos con narración listos."
