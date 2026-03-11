#!/usr/bin/env bash

set -euo pipefail

echo "========================================"
echo "DevSecOps Platform Bootstrap Starting"
echo "========================================"

# All paths are relative to the script's own directory - safe regardless of where it is called from
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------------------------------------------------------------
# Helper: run a numbered script and print clear section headers
# Defined at top of file so it's available before first call
# ---------------------------------------------------------------
run_step() {
    local script="$1"
    echo ""
    echo "----------------------------------------"
    echo "Running: $script"
    echo "----------------------------------------"
    "$SCRIPT_DIR/scripts/$script"
}

# ---------------------------------------------------------------
# STEP 0: Verify internet connectivity
# ---------------------------------------------------------------
echo "[INFO] Checking internet connectivity..."
if ! curl -s --max-time 10 https://github.com >/dev/null; then
    echo "[ERROR] No internet connectivity."
    exit 1
fi
echo "[OK] Internet connectivity verified"

# ---------------------------------------------------------------
# STEP 1: Generate TLS certificates (idempotent - skips if exist)
# ---------------------------------------------------------------
echo "========================================"
echo "TLS Certificate Setup"
echo "========================================"

CERT_DIR="$SCRIPT_DIR/certs"
ROOT_CA="$CERT_DIR/rootCA.crt"
REG_CERT="$CERT_DIR/local-docker-registry.pem"
REG_KEY="$CERT_DIR/local-docker-registry-key.pem"

echo "[INFO] Checking certificate integrity..."

if [ ! -f "$ROOT_CA" ] || [ ! -f "$REG_CERT" ] || [ ! -f "$REG_KEY" ]; then

    echo "[INFO] Certificates missing or incomplete. Generating..."
    chmod +x "$SCRIPT_DIR/scripts/generate-certs.sh"
    # Run from SCRIPT_DIR so relative paths inside generate-certs.sh work correctly
    (cd "$SCRIPT_DIR" && ./scripts/generate-certs.sh)

    if [ ! -f "$ROOT_CA" ] || [ ! -f "$REG_CERT" ] || [ ! -f "$REG_KEY" ]; then
        echo "[ERROR] Certificate generation failed"
        exit 1
    fi

    echo "[OK] Certificates generated successfully"
else
    echo "[OK] Certificates already exist"
fi

# ---------------------------------------------------------------
# STEP 2 onwards: Run modular infrastructure scripts
# ---------------------------------------------------------------
run_step "01-start-infrastructure.sh"
run_step "02-wait-for-services.sh"
run_step "03-create-cluster.sh"
run_step "04-configure-kubernetes.sh"
run_step "05-deploy-monitoring.sh"
run_step "06-verify-platform.sh"

echo ""
echo "========================================"
echo "BOOTSTRAP COMPLETE"
echo "========================================"
echo ""
echo "Platform Access:"
echo "  Gitea:    http://localhost:8081"
echo "  Jenkins:  http://localhost:8080"
echo "  Grafana:  http://localhost:30900"
echo "  App URL:  http://localhost:8082"
echo ""
echo "Next steps (one-time only):"
echo "  1. Set up Gitea: http://localhost:8081"
echo "  2. Set up Jenkins: http://localhost:8080"
echo "  3. See README.md -> Manual Setup section"
echo ""
