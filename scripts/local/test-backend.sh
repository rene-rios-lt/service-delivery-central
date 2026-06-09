#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Walk up from script location to find the ServiceDelivery root
ROOT_DIR="$SCRIPT_DIR"
while [ ! -d "$ROOT_DIR/service-delivery-backend" ] && [ "$ROOT_DIR" != "/" ]; do
  ROOT_DIR="$(dirname "$ROOT_DIR")"
done

if [ ! -d "$ROOT_DIR/service-delivery-backend" ]; then
  echo "Error: could not find service-delivery-backend repo from $SCRIPT_DIR"
  exit 1
fi

BACKEND_DIR="$ROOT_DIR/service-delivery-backend"

echo "Running all backend tests..."
cd "$BACKEND_DIR"
dotnet test
