#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

ROOT_DIR="$SCRIPT_DIR"
while [ ! -d "$ROOT_DIR/service-delivery-simulator" ] && [ "$ROOT_DIR" != "/" ]; do
  ROOT_DIR="$(dirname "$ROOT_DIR")"
done

if [ ! -d "$ROOT_DIR/service-delivery-simulator" ]; then
  echo "Error: could not find service-delivery-simulator repo from $SCRIPT_DIR"
  exit 1
fi

SIMULATOR_DIR="$ROOT_DIR/service-delivery-simulator"

echo "Running all simulator tests..."
cd "$SIMULATOR_DIR"
dotnet test
