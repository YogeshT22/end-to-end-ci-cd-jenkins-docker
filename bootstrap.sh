#!/usr/bin/env bash

set -euo pipefail

echo "========================================"
echo "DevSecOps Platform Bootstrap Starting"
echo "========================================"

# Determine the directory of the script to ensure all paths are relative to it
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# STEP 0: Verify internet
echo "[INFO] Checking internet connectivity..."
if ! curl -s https://github.com >/dev/null; then
    echo "[ERROR] No internet connectivity."
    exit 1
fi
echo "[OK] Internet connectivity verified"

# STEP 1: Generate certificates FIRST
echo "========================================"
echo "TLS Certificate Setup"
echo "========================================"

CERT_DIR="$SCRIPT_DIR/certs"

ROOT_CA="$CERT_DIR/rootCA.crt"
REG_CERT="$CERT_DIR/local-docker-registry.pem"
REG_KEY="$CERT_DIR/local-docker-registry-key.pem"

echo "[INFO] Checking certificate integrity..."

if [ ! -f "$ROOT_CA" ] || \
   [ ! -f "$REG_CERT" ] || \
   [ ! -f "$REG_KEY" ]; then

    echo "[INFO] Certificates missing or incomplete. Generating..."

    chmod +x "$SCRIPT_DIR/scripts/generate-certs.sh"

    cd "$SCRIPT_DIR"
    ./scripts/generate-certs.sh

    # Verify generation success
    if [ ! -f "$ROOT_CA" ] || \
       [ ! -f "$REG_CERT" ] || \
       [ ! -f "$REG_KEY" ]; then

        echo "[ERROR] Certificate generation failed"
        exit 1
    fi

    echo "[OK] Certificates generated successfully"

else
    echo "[OK] Certificates already exist and valid"
fi

echo "========================================"
echo "Sample Application Setup"
echo "========================================"

# preferred location (inside platform repo)
LOCAL_APP_DIR="$SCRIPT_DIR/sample-flask-app"

# fallback location (parent folder, your current structure)
PARENT_APP_DIR="$(dirname "$SCRIPT_DIR")/sample-flask-app"

if [ -d "$LOCAL_APP_DIR" ]; then

    echo "[OK] Sample app found inside platform repo"

elif [ -d "$PARENT_APP_DIR" ]; then

    echo "[OK] Sample app found in parent directory"

    # optional: create symlink so scripts work consistently
    ln -sf "$PARENT_APP_DIR" "$LOCAL_APP_DIR"

else

    echo "[INFO] Sample app not found. Cloning..."

    git clone https://github.com/YogeshT22/sample-flask-app.git "$LOCAL_APP_DIR"

    echo "[OK] Sample app cloned"

fi

run_step() {

    local script="$1"

    echo ""
    echo "----------------------------------------"
    echo "Running: $script"
    echo "----------------------------------------"

    "$SCRIPT_DIR/scripts/$script"

}

run_step "01-start-infrastructure.sh"

run_step "02-wait-for-services.sh"

run_step "03-create-cluster.sh"

# Note: The sample app is needed for the cluster setup, so we ensure it's available before running the cluster script
APP_DIR="$SCRIPT_DIR/sample-flask-app"

if [ ! -d "$APP_DIR" ]; then
    echo "[INFO] Cloning sample app..."
    git clone https://github.com/YogeshT22/sample-flask-app.git "$APP_DIR"
    echo "[OK] Sample app cloned"
fi


run_step "04-configure-kubernetes.sh"

run_step "05-deploy-monitoring.sh"

run_step "06-verify-platform.sh"

echo ""
echo "========================================"
echo "BOOTSTRAP COMPLETE"
echo "========================================"

echo ""
echo "Platform Access:"
echo "Gitea:    http://localhost:8081"
echo "Jenkins:  http://localhost:8080"
echo "Grafana:  http://localhost:30900"
echo "App URL:  http://localhost:8082"
echo ""
