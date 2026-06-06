#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
URL="http://localhost:5023"
PORT=5023

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

# Kill any existing process on the port
EXISTING_PID=$(lsof -ti tcp:$PORT 2>/dev/null || true)
if [ -n "$EXISTING_PID" ]; then
  echo "Stopping existing instance on port $PORT (PID $EXISTING_PID)..."
  kill "$EXISTING_PID" 2>/dev/null || true
  sleep 1
fi

echo "Starting Service Delivery web app..."

cd "$FRONTEND_DIR"
dotnet run --project src/ServiceDelivery.Client.Web &
SERVER_PID=$!

echo "Waiting for server to be ready..."
until curl -s "$URL" > /dev/null 2>&1; do
  sleep 1
done

echo "Opening $URL"
open "$URL"

wait $SERVER_PID
