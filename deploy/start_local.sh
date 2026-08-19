#!/bin/bash
# ErBolamm Studio — PocketBase local (standalone binary, no Docker)
cd "$(dirname "$0")"

PB_DIR="./pocketbase_local"
PB_BINARY="$PB_DIR/pocketbase"
PB_DATA="$PB_DIR/pb_data"
PB_URL="https://github.com/pocketbase/pocketbase/releases/download/v0.23.4/pocketbase_0.23.4_darwin_arm64.zip"

mkdir -p "$PB_DATA"

# Descargar si no existe
if [ ! -f "$PB_BINARY" ]; then
    echo "Descargando PocketBase..."
    mkdir -p "$PB_DIR"
    curl -L -o "$PB_DIR/pb.zip" "$PB_URL"
    unzip -o "$PB_DIR/pb.zip" pocketbase -d "$PB_DIR"
    rm "$PB_DIR/pb.zip"
    chmod +x "$PB_BINARY"
fi

echo ""
echo "Iniciando PocketBase en http://localhost:8090"
echo "Admin UI → http://localhost:8090/_/"
echo "Datos    → $PB_DATA"
echo ""
echo "PASOS:"
echo "  1. Abre http://localhost:8090/_/ en el navegador"
echo "  2. Crea tu cuenta admin"
echo "  3. Ve a Settings → Import collections → pega el contenido de pb_schema.json"
echo "  4. Ve a Collections → users → edit → busca tu email y cámbialo a 'pro'"
echo ""

"$PB_BINARY" serve --http=0.0.0.0:8090 --dir="$PB_DATA"
