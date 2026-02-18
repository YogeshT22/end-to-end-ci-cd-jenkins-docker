#!/usr/bin/env bash

set -euo pipefail

echo "========================================"
echo "Starting CI/CD infrastructure"
echo "========================================"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

NETWORK_NAME="big-project-2-cicd-pipeline_cicd-net"

echo "[INFO] Checking Docker..."

if ! command -v docker >/dev/null 2>&1; then
    echo "[ERROR] Docker not installed"
    exit 1
fi

if ! docker info >/dev/null 2>&1; then
    echo "[ERROR] Docker daemon not running"
    exit 1
fi

echo "[OK] Docker running"

echo "[INFO] Checking network: $NETWORK_NAME"

if docker network inspect "$NETWORK_NAME" >/dev/null 2>&1; then
    echo "[OK] Network exists"
else
    echo "[INFO] Creating network..."
    docker network create "$NETWORK_NAME"
    echo "[OK] Network created"
fi

echo "[INFO] Starting docker compose services..."

docker compose up -d

echo "[OK] Infrastructure started"

echo ""
echo "Services:"
echo "  Gitea     → http://localhost:8081"
echo "  Jenkins   → http://localhost:8080"
echo "  Registry  → https://localhost:5000"
echo ""

docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
