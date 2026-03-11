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

# 'docker compose down' removes containers but NOT named volumes.
# Named volumes (gitea-data, jenkins-data, registry-data) are preserved,
# so all Gitea repos, Jenkins jobs/credentials, and registry images survive.
docker compose down

echo "[OK] Docker containers stopped (named volumes preserved)"

echo ""
echo "[SUCCESS] Platform safely stopped"
echo ""
echo "Data preserved in named volumes:"
echo "  gitea-data    - Gitea repositories and config"
echo "  jenkins-data  - Jenkins jobs, credentials, build history"
echo "  registry-data - Docker images in private registry"
echo ""
echo "To restart: ./bootstrap.sh"
