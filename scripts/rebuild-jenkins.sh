#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "[INFO] Rebuilding Jenkins image..."

docker compose build jenkins

echo "[INFO] Restarting Jenkins container..."

docker compose up -d jenkins

echo "[OK] Jenkins rebuilt and restarted"
