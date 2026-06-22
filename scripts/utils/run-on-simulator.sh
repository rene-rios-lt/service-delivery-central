#!/usr/bin/env bash
# Build the MAUI frontend (ServiceDelivery.Client.Mobile) and deploy it to a named
# iOS Simulator device. Shared helper behind scripts/local/startInPhone.sh and
# scripts/local/startInTablet.sh — those pass the device name; this does the work.
#
# Usage: run-on-simulator.sh "<simulator device name>"
#   e.g. run-on-simulator.sh "iPhone 17 Pro"
#        run-on-simulator.sh "iPad mini (A17 Pro)"
#
# Picks an available simulator whose name matches exactly, preferring one that is
# already booted; boots it and opens Simulator.app if needed; then builds + deploys
# + launches the app on it (blocks, streaming the app console — Ctrl-C to stop).
set -euo pipefail

DEVICE_NAME="${1:-}"
if [ -z "$DEVICE_NAME" ]; then
  echo "Error: a simulator device name is required (e.g. \"iPhone 17 Pro\")." >&2
  exit 1
fi

# Resolve the frontend repo by walking up from this script's location to the
# ServiceDelivery root (same approach as launchWebPage.sh) — portable, no hardcoded path.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR"
while [ ! -d "$ROOT_DIR/service-delivery-frontend" ] && [ "$ROOT_DIR" != "/" ]; do
  ROOT_DIR="$(dirname "$ROOT_DIR")"
done
if [ ! -d "$ROOT_DIR/service-delivery-frontend" ]; then
  echo "Error: could not find service-delivery-frontend repo from $SCRIPT_DIR" >&2
  exit 1
fi
FRONTEND_DIR="$ROOT_DIR/service-delivery-frontend"
MOBILE_PROJECT="src/ServiceDelivery.Client.Mobile"

UDID_RE='[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}'

# Find a matching available simulator. Exact name match ("iPhone 17 Pro (" never matches
# "iPhone 17 Pro Max ("). Prefer an already-booted instance, else the first available.
DEVICES="$(xcrun simctl list devices available)"
MATCHES="$(printf '%s\n' "$DEVICES" | grep -F "$DEVICE_NAME (" || true)"
if [ -z "$MATCHES" ]; then
  echo "Error: no available simulator named \"$DEVICE_NAME\". Available devices:" >&2
  printf '%s\n' "$DEVICES" | grep -oE '^\s+\S.*\(' | sed -E 's/ \($//' | sort -u >&2
  exit 1
fi

UDID="$(printf '%s\n' "$MATCHES" | grep '(Booted)' | grep -oE "$UDID_RE" | head -1 || true)"
if [ -z "$UDID" ]; then
  UDID="$(printf '%s\n' "$MATCHES" | grep -oE "$UDID_RE" | head -1)"
fi

echo "==> Target: $DEVICE_NAME ($UDID)"

# Boot it if needed (booting an already-booted device is a no-op error we ignore) and
# bring the Simulator window up.
xcrun simctl boot "$UDID" >/dev/null 2>&1 || true
open -a Simulator
echo "==> Waiting for simulator to finish booting ..."
xcrun simctl bootstatus "$UDID" -b >/dev/null 2>&1 || true

echo "==> Building and deploying ServiceDelivery.Client.Mobile to the simulator ..."
echo "    (first build is slow; the app console streams below — press Ctrl-C to stop)"
cd "$FRONTEND_DIR"
exec dotnet build "$MOBILE_PROJECT" -f net10.0-ios -t:Run \
  -p:Configuration=Debug \
  -p:_DeviceName=":v2:udid=$UDID"
