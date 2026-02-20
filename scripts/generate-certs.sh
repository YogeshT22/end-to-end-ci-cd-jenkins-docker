#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CERT_DIR="$SCRIPT_DIR/certs"
TEMP_CERT_DIR="$SCRIPT_DIR/certs.tmp"

echo "[INFO] Preparing certificate directory..."

# Remove temp dir if exists
rm -rf "$TEMP_CERT_DIR"

# Create fresh temp dir
mkdir -p "$TEMP_CERT_DIR"

echo "========================================"
echo "Generating Certificate Authority..."
echo "========================================"

mkcert -install

# Copy root CA into temp dir
cp "$(mkcert -CAROOT)/rootCA.pem" "$TEMP_CERT_DIR/rootCA.crt"

echo "[OK] Root CA copied"

echo "========================================"
echo "Generating registry certificate..."
echo "========================================"

mkcert \
  -cert-file "$TEMP_CERT_DIR/local-docker-registry.pem" \
  -key-file "$TEMP_CERT_DIR/local-docker-registry-key.pem" \
  local-docker-registry localhost 127.0.0.1

echo "[OK] Registry certificates generated"

echo "[INFO] Activating certificate directory..."

# Ensure certs directory exists cleanly
if [ -e "$CERT_DIR" ]; then

    echo "[INFO] Removing old certificate directory safely..."

    chmod -R u+rwX "$CERT_DIR" 2>/dev/null || true

    rm -rf "$CERT_DIR" 2>/dev/null || true

fi

# Create fresh cert directory
mkdir -p "$CERT_DIR"

# Copy new certs into place
cp -r "$TEMP_CERT_DIR/"* "$CERT_DIR/"

# Remove temp dir
rm -rf "$TEMP_CERT_DIR"

echo "[OK] Certificate directory activated"

echo "========================================"
echo "Certificate generation complete"
echo "========================================"
