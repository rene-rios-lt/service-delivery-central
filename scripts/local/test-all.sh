#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Running all tests..."
echo ""

echo "=== Backend ==="
"$SCRIPT_DIR/test-backend.sh"

echo ""
echo "=== Simulator ==="
"$SCRIPT_DIR/test-simulator.sh"

echo ""
echo "All tests passed."
