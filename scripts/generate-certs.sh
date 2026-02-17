#!/bin/bash

set -e

CERT_DIR=certs

mkdir -p $CERT_DIR

echo "Generating root CA..."
mkcert -install

echo "Generating registry certificate..."
mkcert \
  -cert-file $CERT_DIR/local-docker-registry.pem \
  -key-file $CERT_DIR/local-docker-registry-key.pem \
  local-docker-registry localhost 127.0.0.1

echo "Done. Certificates generated in certs/"
