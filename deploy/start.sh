#!/bin/bash
# ErBolamm Studio — PocketBase local launcher
cd "$(dirname "$0")"

if ! command -v docker &> /dev/null; then
    echo "Docker no está instalado. Instálalo desde https://docs.docker.com/get-docker/"
    exit 1
fi

echo "Iniciando PocketBase..."
docker compose up -d
echo ""
echo "Admin UI → http://localhost:8090/_/"
echo "API       → http://localhost:8090"
echo ""
echo "Primer paso: abre la Admin UI y crea tu cuenta de admin."
echo "Después: crea las collections (tablas) desde Settings > Import collections."
echo ""
read -p "Presiona Enter para abrir la Admin UI... "
open http://localhost:8090/_
