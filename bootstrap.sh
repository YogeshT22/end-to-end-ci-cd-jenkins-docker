#!/usr/bin/env bash

set -euo pipefail

echo "========================================"
echo "DevSecOps Platform Bootstrap Starting"
echo "========================================"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
