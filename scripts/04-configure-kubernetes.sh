#!/usr/bin/env bash

set -euo pipefail

echo "========================================"
echo "Kubernetes Configuration Script"
echo "========================================"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_K8S_DIR="$PROJECT_ROOT/sample-flask-app/k8s"

# Verify sample app Kubernetes manifests exist
if [ ! -d "$APP_K8S_DIR" ]; then
    echo "[ERROR] sample-flask-app not found at $APP_K8S_DIR"
    echo "[INFO] Run bootstrap.sh or clone sample-flask-app"
    exit 1
fi

SERVICE_ACCOUNT_FILE="$APP_K8S_DIR/service-account.yaml"
SECRET_FILE="$APP_K8S_DIR/jenkins-token-secret.yaml"

OUTPUT_KUBECONFIG="$PROJECT_ROOT/kubeconfig-jenkins.yaml"

CLUSTER_NAME="devops-cluster"

echo "[INFO] Verifying cluster connectivity..."

if ! kubectl cluster-info >/dev/null 2>&1; then
    echo "[ERROR] Kubernetes cluster not reachable"
    exit 1
fi

echo "[OK] Cluster reachable"

echo "[INFO] Applying service account..."

kubectl apply -f "$SERVICE_ACCOUNT_FILE"

echo "[INFO] Applying token secret..."

kubectl apply -f "$SECRET_FILE"

echo "[OK] Kubernetes credentials created"

echo "[INFO] Extracting cluster CA..."

CA_DATA=$(k3d kubeconfig get "$CLUSTER_NAME" | grep certificate-authority-data | awk '{print $2}')

if [ -z "$CA_DATA" ]; then
    echo "[ERROR] Failed to extract CA data"
    exit 1
fi

echo "[INFO] Extracting service account token..."

TOKEN=$(kubectl get secret jenkins-admin-token -o jsonpath='{.data.token}' | base64 --decode)

if [ -z "$TOKEN" ]; then
    echo "[ERROR] Failed to extract token"
    exit 1
fi

echo "[INFO] Generating kubeconfig for Jenkins..."

cat > "$OUTPUT_KUBECONFIG" <<EOF
apiVersion: v1
kind: Config
clusters:
- name: k3d-devops-cluster
  cluster:
    server: https://host.docker.internal:6550
    certificate-authority-data: $CA_DATA

users:
- name: jenkins-admin
  user:
    token: $TOKEN

contexts:
- name: jenkins-context
  context:
    cluster: k3d-devops-cluster
    user: jenkins-admin
    namespace: default

current-context: jenkins-context
EOF

echo "[SUCCESS] kubeconfig generated at:"
echo "$OUTPUT_KUBECONFIG"
