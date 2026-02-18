#!/usr/bin/env bash

set -euo pipefail

echo "========================================"
echo "Waiting for CI/CD services readiness"
echo "========================================"

MAX_RETRIES=60
SLEEP_SECONDS=2

check_service() {
    local name="$1"
    local url="$2"

    echo "[INFO] Waiting for $name..."

    for ((i=1; i<=MAX_RETRIES; i++)); do

        if curl -k -s -o /dev/null "$url"; then
            echo "[OK] $name is ready"
            return 0
        fi

        echo "[WAIT] $name not ready yet ($i/$MAX_RETRIES)"
        sleep "$SLEEP_SECONDS"

    done

    echo "[ERROR] $name failed to become ready"
    exit 1
}

# Check Gitea
check_service "Gitea" "http://localhost:8081"

# Check Jenkins
check_service "Jenkins" "http://localhost:8080/login"

# Check Registry
check_service "Docker Registry" "https://localhost:5000/v2/"

echo ""
echo "[SUCCESS] All services are ready"
echo ""
