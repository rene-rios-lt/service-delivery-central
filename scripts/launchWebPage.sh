#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FRONTEND_DIR="$SCRIPT_DIR/../service-delivery-frontend"
URL="http://localhost:5023"

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
