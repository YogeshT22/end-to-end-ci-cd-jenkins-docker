#!/usr/bin/env bash

set -euo pipefail

echo "========================================"
echo "Monitoring Stack Deployment Script"
echo "========================================"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

VALUES_FILE="$PROJECT_ROOT/helm-configs/prometheus-values.yaml"

CLUSTER_NAME="devops-cluster"
NAMESPACE="monitoring"
RELEASE_NAME="prometheus-stack"

echo "[INFO] Verifying kubectl access..."

kubectl cluster-info >/dev/null

echo "[OK] Cluster reachable"

echo "[INFO] Creating namespace if not exists..."

kubectl get namespace "$NAMESPACE" >/dev/null 2>&1 || kubectl create namespace "$NAMESPACE"

echo "[OK] Namespace ready"

echo "[INFO] Adding Helm repo..."

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true

helm repo update >/dev/null

echo "[OK] Helm repo ready"

echo "[INFO] Checking if monitoring already installed..."

if helm list -n "$NAMESPACE" | grep -q "$RELEASE_NAME"; then
    echo "[OK] Monitoring already installed"
else
    echo "[INFO] Installing monitoring stack..."

    helm install "$RELEASE_NAME" prometheus-community/kube-prometheus-stack \
        -n "$NAMESPACE" \
        -f "$VALUES_FILE"

    echo "[OK] Monitoring installed"
fi

echo "[INFO] Checking Grafana port mapping..."

if docker ps --format '{{.Ports}}' | grep -q "30900->30900"; then
    echo "[OK] Grafana port already mapped"
else
    echo "[INFO] Adding Grafana port mapping..."

    k3d cluster stop "$CLUSTER_NAME"

    k3d cluster edit "$CLUSTER_NAME" --port-add 30900:30900@loadbalancer

    k3d cluster start "$CLUSTER_NAME"

    echo "[OK] Grafana port mapping added"
fi

echo "[SUCCESS] Monitoring deployment complete"

echo "Grafana: http://localhost:30900"
