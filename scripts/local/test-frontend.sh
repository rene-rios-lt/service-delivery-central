#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Walk up from script location to find the ServiceDelivery root
ROOT_DIR="$SCRIPT_DIR"
while [ ! -d "$ROOT_DIR/service-delivery-frontend" ] && [ "$ROOT_DIR" != "/" ]; do
  ROOT_DIR="$(dirname "$ROOT_DIR")"
done

if [ ! -d "$ROOT_DIR/service-delivery-frontend" ]; then
  echo "Error: could not find service-delivery-frontend repo from $SCRIPT_DIR"
  exit 1
fi

FRONTEND_DIR="$ROOT_DIR/service-delivery-frontend"

echo "Running all frontend tests..."
cd "$FRONTEND_DIR"
dotnet test
