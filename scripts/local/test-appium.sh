#!/usr/bin/env bash
# Runs the Appium end-to-end suite (tests/ServiceDelivery.Client.Appium) against a live system on a
# booted iOS simulator.
#
# These tests drive the MAUI Blazor Hybrid Mobile host installed on the iOS simulator as a black box
# — they talk to the backend (:5180) and react to simulator-driven SignalR job offers. They are NOT
# part of the /master pipeline or the offline test-unit-and-integration.sh runner. They run live via
# test-e2e.sh (Playwright + Appium) or the top-level test-all.sh; this script runs the Appium suite
# alone. It brings the backend + simulator up if not already running, boots the iOS simulator, builds + installs the
# Mobile app, starts an Appium server, runs the suite, and tears down anything it started.
#
# Idempotent: if the backend is already up on :5180 it reuses it and does NOT tear it down on exit
# (only what this script starts is stopped). Booting an already-booted simulator is a no-op.
#
# Prerequisites (one-time):
#   npm install -g appium
#   appium driver install xcuitest
#
# Env overrides:
#   APPIUM_DEVICE         simulator device name      (default "iPhone 17 Pro")
#   APPIUM_BASE_URL       backend base URL           (default http://localhost:5180)
#   APPIUM_SERVER_URL     Appium server URL          (default http://localhost:4723)
#   APPIUM_REP_PASSWORD   seeded rep password        (default Password1!)
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$SCRIPT_DIR"
while [ ! -d "$ROOT_DIR/service-delivery-frontend" ] && [ "$ROOT_DIR" != "/" ]; do
  ROOT_DIR="$(dirname "$ROOT_DIR")"
done
if [ ! -d "$ROOT_DIR/service-delivery-frontend" ]; then
  echo "Error: could not find service-delivery-frontend repo from $SCRIPT_DIR" >&2
  exit 1
fi

FRONTEND_DIR="$ROOT_DIR/service-delivery-frontend"
APPIUM_PROJECT="$FRONTEND_DIR/tests/ServiceDelivery.Client.Appium"
MOBILE_PROJECT="$FRONTEND_DIR/src/ServiceDelivery.Client.Mobile"
BACKEND_URL="${APPIUM_BASE_URL:-http://localhost:5180}"
DEVICE_NAME="${APPIUM_DEVICE:-iPhone 17 Pro}"
SERVER_URL="${APPIUM_SERVER_URL:-http://localhost:4723}"
SERVER_PORT="${SERVER_URL##*:}"

STARTED_BACKEND=0
APPIUM_PID=""

cleanup() {
  if [ -n "$APPIUM_PID" ]; then
    echo "==> Stopping Appium server (PID $APPIUM_PID) ..."
    kill "$APPIUM_PID" 2>/dev/null || true
  fi
  if [ "$STARTED_BACKEND" -eq 1 ]; then
    echo "==> Stopping backend + simulator (stop.sh) ..."
    "$SCRIPT_DIR/stop.sh" || true
  fi
}
trap cleanup EXIT

# 0. Tooling — Appium must be on PATH.
if ! command -v appium > /dev/null 2>&1; then
  echo "!! 'appium' not found on PATH. Install it once with:" >&2
  echo "   npm install -g appium && appium driver install xcuitest" >&2
  exit 1
fi

# 1. Backend — start only if it is not already serving on :5180.
#    The suite runs BACKEND-ONLY (no simulator): the offer tests submit a service request as a
#    Requester, and with no rep-operating simulator the human-taken-over rep is the sole match
#    candidate, so the offer routes to it deterministically. A simulator operating rep1..rep8
#    would win the match instead and the offer would never reach the device under test.
if curl -s "$BACKEND_URL/health" > /dev/null 2>&1 || curl -s "$BACKEND_URL" > /dev/null 2>&1; then
  echo "==> Backend already up on $BACKEND_URL — reusing."
  if pgrep -f "ServiceDelivery.Simulator" > /dev/null 2>&1; then
    echo "!! A simulator is running against the reused backend. The offer tests need a backend-only" >&2
    echo "   system (a rep-operating simulator steals the job offer). Run scripts/local/stop.sh and" >&2
    echo "   re-run this script so it brings up the backend alone (SD_SKIP_SIMULATOR=1)." >&2
    exit 1
  fi
else
  echo "==> Starting backend only (start.sh, no simulator) ..."
  SD_SKIP_SIMULATOR=1 "$SCRIPT_DIR/start.sh" || { echo "!! start.sh failed" >&2; exit 1; }
  STARTED_BACKEND=1
fi

# 2. Resolve + boot the iOS simulator.
#    Device boot logic mirrors scripts/utils/run-on-simulator.sh (which cannot be called directly: it
#    ends with `exec dotnet build ... -t:Run`, a blocking foreground run). Only the UDID resolution
#    and boot steps are inlined here so the build/install/test flow below stays in this script.
UDID_RE='[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}'
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
echo "==> Target simulator: $DEVICE_NAME ($UDID)"
xcrun simctl boot "$UDID" >/dev/null 2>&1 || true
open -a Simulator
echo "==> Waiting for simulator to finish booting ..."
xcrun simctl bootstatus "$UDID" -b >/dev/null 2>&1 || true

# 3. Build the Mobile app for the iOS simulator and resolve the .app bundle path.
echo "==> Building ServiceDelivery.Client.Mobile for the iOS simulator ..."
( cd "$FRONTEND_DIR" && dotnet build "$MOBILE_PROJECT" -f net10.0-ios -p:Configuration=Debug ) \
  || { echo "!! Mobile build failed" >&2; exit 1; }

APP_PATH="$(find "$MOBILE_PROJECT/bin/Debug" -maxdepth 3 -name '*.app' -type d 2>/dev/null | head -1)"
if [ -z "$APP_PATH" ]; then
  echo "!! Could not locate the built .app under $MOBILE_PROJECT/bin/Debug" >&2
  exit 1
fi
echo "==> App bundle: $APP_PATH"

# 4. Install the app on the booted simulator (so the suite can run with noReset).
echo "==> Installing app on the simulator ..."
xcrun simctl install "$UDID" "$APP_PATH" || { echo "!! simctl install failed" >&2; exit 1; }

# 5. Start the Appium server in the background and wait for it to respond.
echo "==> Starting Appium server on port $SERVER_PORT ..."
appium --port "$SERVER_PORT" > /tmp/appium-server.log 2>&1 &
APPIUM_PID=$!
echo "==> Waiting for Appium server at $SERVER_URL ..."
for _ in $(seq 1 30); do
  curl -s "$SERVER_URL/status" > /dev/null 2>&1 && break
  sleep 1
done
if ! curl -s "$SERVER_URL/status" > /dev/null 2>&1; then
  echo "!! Appium server did not respond at $SERVER_URL in time (see /tmp/appium-server.log)." >&2
  exit 1
fi

# 6. Run the suite.
echo "==> Running Appium E2E suite ..."
export APPIUM_SERVER_URL="$SERVER_URL"
export APPIUM_DEVICE_UDID="$UDID"
export APPIUM_APP_PATH="$APP_PATH"
export APPIUM_BASE_URL="$BACKEND_URL"
export APPIUM_REP_PASSWORD="${APPIUM_REP_PASSWORD:-Password123!}"
# Optional first argument is an NUnit/xUnit --filter expression (e.g. "FullyQualifiedName~LoginTests")
# so a single test class can be run for fast iteration; with no argument the whole suite runs.
# When an orchestrator (test-e2e.sh / test-all.sh) sets SD_TRX_DIR, emit a TRX it can fold into its
# consolidated results table.
if [ -n "${SD_TRX_DIR:-}" ]; then
  LOGGER=(--logger "trx;LogFileName=appium.trx" --results-directory "$SD_TRX_DIR")
  if [ -n "${1:-}" ]; then
    dotnet test "$APPIUM_PROJECT" --nologo --filter "$1" "${LOGGER[@]}"
  else
    dotnet test "$APPIUM_PROJECT" --nologo "${LOGGER[@]}"
  fi
else
  if [ -n "${1:-}" ]; then
    dotnet test "$APPIUM_PROJECT" --nologo --filter "$1"
  else
    dotnet test "$APPIUM_PROJECT" --nologo
  fi
fi
RESULT=$?

exit $RESULT
