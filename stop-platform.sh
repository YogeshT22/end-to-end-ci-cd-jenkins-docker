#!/usr/bin/env bash

set -euo pipefail

echo "========================================"
echo "Stopping End-to-End DevSecOps Platform"
echo "========================================"

CLUSTER_NAME="devops-cluster"

echo "[INFO] Stopping Kubernetes cluster..."

if k3d cluster list | grep -q "$CLUSTER_NAME"; then
    k3d cluster stop "$CLUSTER_NAME"
    echo "[OK] Cluster stopped"
else
    echo "[OK] Cluster already stopped"
fi

echo "[INFO] Stopping Docker infrastructure..."

docker compose down

echo "[OK] Docker containers stopped"

echo ""
echo "[SUCCESS] Platform safely stopped"
