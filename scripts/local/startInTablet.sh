#!/usr/bin/env bash
# Build the MAUI frontend app and deploy it to an iPad mini (A17 Pro) simulator.
# Thin wrapper over scripts/utils/run-on-simulator.sh (which does the work).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/../utils/run-on-simulator.sh" "iPad mini (A17 Pro)"
