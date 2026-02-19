#!/usr/bin/env bash

set -euo pipefail

echo "========================================"
echo "K3d Cluster Creation / Recovery Script"
echo "========================================"

CLUSTER_NAME="devops-cluster"
NETWORK_NAME="big-project-2-cicd-pipeline_cicd-net"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

CERT_PATH="$PROJECT_ROOT/certs/rootCA.crt"
REGISTRY_CONFIG="$PROJECT_ROOT/registries.yaml"

echo "[INFO] Checking k3d installation..."

if ! command -v k3d >/dev/null 2>&1; then
    echo "[ERROR] k3d not installed"
    exit 1
fi

echo "[OK] k3d installed"

cluster_exists=false
cluster_running=false

if k3d cluster list | grep -q "$CLUSTER_NAME"; then
    cluster_exists=true
fi

if [ "$cluster_exists" = true ]; then

    echo "[INFO] Cluster exists, checking health..."

    if kubectl cluster-info >/dev/null 2>&1; then
        cluster_running=true
    fi

    if [ "$cluster_running" = true ]; then
        echo "[OK] Cluster is already running and healthy"
        exit 0
    else
        echo "[WARN] Cluster exists but is stopped or unhealthy"
        echo "[INFO] Attempting to start cluster..."

        k3d cluster start "$CLUSTER_NAME"

        sleep 5

        if kubectl cluster-info >/dev/null 2>&1; then
            echo "[OK] Cluster recovered successfully"
            exit 0
        else
            echo "[ERROR] Cluster exists but failed to start"
            echo "[ACTION] Delete and recreate cluster manually:"
            echo "k3d cluster delete $CLUSTER_NAME"
            exit 1
        fi
    fi

fi

echo "[INFO] Cluster does not exist, creating new cluster..."

if [ ! -f "$CERT_PATH" ]; then
    echo "[ERROR] rootCA.crt not found"
    exit 1
fi

if [ ! -f "$REGISTRY_CONFIG" ]; then
    echo "[ERROR] registries.yaml not found"
    exit 1
fi

k3d cluster create "$CLUSTER_NAME" \
  --api-port 6550 \
  -p "8082:80@loadbalancer" \
  -p "30900:30900@loadbalancer" \
  --network "$NETWORK_NAME" \
  --registry-config "$REGISTRY_CONFIG" \
  --volume "$CERT_PATH:/usr/local/share/ca-certificates/my-root-ca.crt@server:*" \
  --volume "$CERT_PATH:/usr/local/share/ca-certificates/my-root-ca.crt@agent:*" \
  --k3s-arg "--resolv-conf=/etc/resolv.conf@server:*" \
  --k3s-arg "--resolv-conf=/etc/resolv.conf@agent:*"

echo "[SUCCESS] Cluster created"
