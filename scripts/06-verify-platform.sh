#!/usr/bin/env bash

set -euo pipefail

echo "========================================"
echo "Platform Verification Script"
echo "========================================"

fail() {
    echo "[FAIL] $1"
    exit 1
}

pass() {
    echo "[OK] $1"
}

echo "[INFO] Checking Docker containers..."

docker ps | grep gitea-server >/dev/null || fail "Gitea container not running"
docker ps | grep jenkins-server >/dev/null || fail "Jenkins container not running"
docker ps | grep local-docker-registry >/dev/null || fail "Registry container not running"

pass "All containers running"

echo "[INFO] Checking Kubernetes cluster..."

kubectl cluster-info >/dev/null || fail "Cluster not reachable"

pass "Cluster reachable"

echo "[INFO] Checking Kubernetes nodes..."

kubectl get nodes | grep Ready >/dev/null || fail "Nodes not ready"

pass "Nodes ready"

echo "[INFO] Checking registry connectivity..."

curl -k -s https://localhost:5000/v2/ >/dev/null || fail "Registry not reachable"

pass "Registry reachable"

echo "[INFO] Checking Jenkins connectivity..."

curl -s http://localhost:8080/login >/dev/null || fail "Jenkins not reachable"

pass "Jenkins reachable"

echo "[INFO] Checking Gitea connectivity..."

curl -s http://localhost:8081 >/dev/null || fail "Gitea not reachable"

pass "Gitea reachable"

echo "[INFO] Checking monitoring namespace..."

kubectl get namespace monitoring >/dev/null || fail "Monitoring namespace missing"

pass "Monitoring namespace exists"

echo ""
echo "========================================"
echo "[SUCCESS] FULL PLATFORM VERIFIED"
echo "========================================"

echo ""
echo "Access URLs:"
echo "Gitea:    http://localhost:8081"
echo "Jenkins:  http://localhost:8080"
echo "Grafana:  http://localhost:30900"
echo "App URL:  http://localhost:8082"
echo ""
