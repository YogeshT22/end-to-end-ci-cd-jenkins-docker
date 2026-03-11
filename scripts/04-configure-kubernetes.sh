#!/usr/bin/env bash

set -euo pipefail

echo "========================================"
echo "Kubernetes Configuration Script"
echo "========================================"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ---------------------------------------------------------------
# Locate sample-flask-app k8s manifests.
# Priority order:
#   1. Sibling directory  <parent>/sample-flask-app  (standard dev layout)
#   2. Local clone inside the cicd repo              (fallback: clone from GitHub)
# bootstrap.sh no longer needs to pre-create a symlink.
# ---------------------------------------------------------------
SIBLING_APP_DIR="$(dirname "$PROJECT_ROOT")/sample-flask-app"
LOCAL_APP_DIR="$PROJECT_ROOT/sample-flask-app"

if [ -d "$SIBLING_APP_DIR/k8s" ]; then
    APP_K8S_DIR="$SIBLING_APP_DIR/k8s"
    echo "[INFO] Using sibling sample-flask-app at: $SIBLING_APP_DIR"
elif [ -d "$LOCAL_APP_DIR/k8s" ]; then
    APP_K8S_DIR="$LOCAL_APP_DIR/k8s"
    echo "[INFO] Using local sample-flask-app clone at: $LOCAL_APP_DIR"
else
    echo "[INFO] sample-flask-app not found locally — cloning from GitHub..."
    git clone https://github.com/YogeshT22/sample-flask-app.git "$LOCAL_APP_DIR"
    APP_K8S_DIR="$LOCAL_APP_DIR/k8s"
    echo "[OK] Cloned sample-flask-app"
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

# Use the k3d serverlb container hostname — it is on the shared cicd-net Docker
# network alongside Jenkins, and its name is present in the API server TLS cert SANs.
# Do NOT use host.docker.internal:6550 — that hostname is NOT in the cert SANs
# and will cause x509 TLS verification failures inside the Jenkins container.
cat > "$OUTPUT_KUBECONFIG" <<EOF
apiVersion: v1
kind: Config
clusters:
- name: k3d-devops-cluster
  cluster:
    server: https://k3d-${CLUSTER_NAME}-serverlb:6443
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

echo "[SUCCESS] kubeconfig generated at: $OUTPUT_KUBECONFIG"

# ---------------------------------------------------------------
# Apply app Kubernetes manifests (deployment, service, ingress)
# This must happen BEFORE Jenkins runs its first pipeline so that
# `kubectl set image` has a Deployment object to update.
# These are idempotent (kubectl apply) — safe to run on every start.
# ---------------------------------------------------------------
echo "[INFO] Applying app Kubernetes manifests (deployment, service, ingress)..."

DEPLOYMENT_FILE="$APP_K8S_DIR/deployment.yaml"
SERVICE_FILE="$APP_K8S_DIR/service.yaml"
INGRESS_FILE="$APP_K8S_DIR/ingress.yaml"

for f in "$DEPLOYMENT_FILE" "$SERVICE_FILE" "$INGRESS_FILE"; do
    if [ ! -f "$f" ]; then
        echo "[WARN] Manifest not found, skipping: $f"
    fi
done

KUBECONFIG="$OUTPUT_KUBECONFIG" kubectl apply -f "$DEPLOYMENT_FILE" || true
KUBECONFIG="$OUTPUT_KUBECONFIG" kubectl apply -f "$SERVICE_FILE"    || true
KUBECONFIG="$OUTPUT_KUBECONFIG" kubectl apply -f "$INGRESS_FILE"    || true

echo "[OK] App manifests applied (deployment/service/ingress)"
