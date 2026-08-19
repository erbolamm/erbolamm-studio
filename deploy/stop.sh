#!/bin/bash
cd "$(dirname "$0")"
echo "Deteniendo PocketBase..."
docker compose down
echo "Listo."
