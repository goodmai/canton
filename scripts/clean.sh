#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "Cleaning up Docker resources..."
docker-compose down -v --remove-orphans

echo "Cleaning up generated artifacts..."
rm -rf "$PROJECT_ROOT/logs/"
rm -rf "$PROJECT_ROOT/my-app/main/.daml"
rm -rf "$PROJECT_ROOT/my-app/main/daml.yaml.lock"

echo "Cleanup complete."
