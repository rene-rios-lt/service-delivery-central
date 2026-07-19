#!/usr/bin/env bash
# Runs the Desktop Mac2Driver end-to-end suite (tests/ServiceDelivery.Client.Appium.Mac) against a live
# system on macOS (FE-003 Phase 3).
#
# These tests drive the MAUI Blazor Hybrid DESKTOP host (Mac Catalyst) as a black box — they talk to the
# backend (:5180) and assert NATIVELY on the macOS accessibility (AX) tree (the mac2 driver has no WEBVIEW
# contexts, CSS selectors, or DOM JS; WKWebView content surfaces in the AX tree, so anchors are visible
# text, input types, and aria-labels — see MacDesktopTestBase). They are NOT part of the /master pipeline
# or the offline test-unit-and-integration.sh runner. This is the Desktop analogue of test-appium.sh
# (iOS/XCUITest): it brings the backend up if not already running, builds the Desktop Mac Catalyst app in
# Debug, starts an Appium server, runs the suite, and tears down anything it started.
#
# Idempotent: if the backend is already up on :5180 it reuses it and does NOT tear it down on exit (only
# what this script starts is stopped).
#
# The suite runs BACKEND-ONLY (SD_SKIP_SIMULATOR=1): the Mac helper (BackendApiHelper.PositionFleetAt)
# posts vehicle positions as the Simulator account so the dispatcher fleet map has markers to render,
# rather than relying on a rep-operating simulator.
#
# Prerequisites (one-time, per machine — CI cannot perform these; see docs/testing/desktop-appium-setup.md):
#   npm install -g appium
#   appium driver install mac2
#   System Settings → Privacy & Security → Accessibility           → enable Terminal (or the test runner)
#   System Settings → Privacy & Security → Screen Recording        → enable Terminal (for SD_SHOT_DIR shots)
#
# Env overrides:
#   APPIUM_BASE_URL             backend base URL          (default http://localhost:5180)
#   APPIUM_SERVER_URL           Appium server URL         (default http://localhost:4723)
#   APPIUM_DISPATCHER_PASSWORD  seeded dispatcher password (default Password123!)
#   SD_AX_DUMP=1                dump the AX element tree to TestResults/ on a setup failure (diagnostics)
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
MAC_APPIUM_PROJECT="$FRONTEND_DIR/tests/ServiceDelivery.Client.Appium.Mac"
DESKTOP_PROJECT="$FRONTEND_DIR/src/ServiceDelivery.Client.Desktop"
BACKEND_URL="${APPIUM_BASE_URL:-http://localhost:5180}"
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
    echo "==> Stopping backend (stop.sh) ..."
    "$SCRIPT_DIR/stop.sh" || true
  fi
}
trap cleanup EXIT

# 0. Tooling — Appium must be on PATH.
if ! command -v appium > /dev/null 2>&1; then
  echo "!! 'appium' not found on PATH. Install it once with:" >&2
  echo "   npm install -g appium && appium driver install mac2" >&2
  exit 1
fi

# 1. Backend — start only if it is not already serving on :5180. Backend-only (no rep-operating simulator);
#    the suite posts positions itself via the Mac BackendApiHelper.
if curl -s "$BACKEND_URL/health" > /dev/null 2>&1 || curl -s "$BACKEND_URL" > /dev/null 2>&1; then
  echo "==> Backend already up on $BACKEND_URL — reusing."
else
  echo "==> Starting backend only (start.sh, no simulator) ..."
  SD_SKIP_SIMULATOR=1 "$SCRIPT_DIR/start.sh" || { echo "!! start.sh failed" >&2; exit 1; }
  STARTED_BACKEND=1
fi

# 2. Build the Desktop Mac Catalyst app in Debug (the local-dev configuration; the suite automates the
#    native AX tree, so no WebView inspector is involved) and resolve the .app bundle path.
echo "==> Building ServiceDelivery.Client.Desktop for Mac Catalyst (Debug) ..."
( cd "$FRONTEND_DIR" && dotnet build "$DESKTOP_PROJECT/ServiceDelivery.Client.Desktop.csproj" \
    -f net10.0-maccatalyst -c Debug ) \
  || { echo "!! Desktop build failed" >&2; exit 1; }

APP_PATH="$(find "$DESKTOP_PROJECT/bin/Debug" -maxdepth 3 -name '*.app' -type d 2>/dev/null | head -1)"
if [ -z "$APP_PATH" ]; then
  echo "!! Could not locate the built .app under $DESKTOP_PROJECT/bin/Debug" >&2
  exit 1
fi
echo "==> App bundle: $APP_PATH"

# 3. Start the Appium server in the background and wait for it to respond.
echo "==> Starting Appium server on port $SERVER_PORT ..."
appium --port "$SERVER_PORT" > /tmp/appium-mac-server.log 2>&1 &
APPIUM_PID=$!
echo "==> Waiting for Appium server at $SERVER_URL ..."
for _ in $(seq 1 30); do
  curl -s "$SERVER_URL/status" > /dev/null 2>&1 && break
  sleep 1
done
if ! curl -s "$SERVER_URL/status" > /dev/null 2>&1; then
  echo "!! Appium server did not respond at $SERVER_URL in time (see /tmp/appium-mac-server.log)." >&2
  exit 1
fi

# 3.5 Clean app state — wipe the Desktop app's persisted Preferences (NSUserDefaults under the bundle id)
#     so every run cold-starts unauthenticated. The PreferencesTokenStore (FE-003) persists the JWT across
#     app restarts, and a cold start with a valid persisted token currently lands on a blank "/" page
#     (BUG-050), which would strand the suite's EnsureLoggedOut. Deterministic clean state per run is the
#     right E2E hygiene regardless of that fix.
defaults delete com.companyname.servicedelivery.client.desktop > /dev/null 2>&1 || true

# 4. Run the suite.
echo "==> Running Desktop Mac2Driver E2E suite ..."
export APPIUM_SERVER_URL="$SERVER_URL"
export APPIUM_APP_PATH="$APP_PATH"
export APPIUM_BASE_URL="$BACKEND_URL"
export APPIUM_DISPATCHER_PASSWORD="${APPIUM_DISPATCHER_PASSWORD:-Password123!}"
# When an orchestrator sets SD_TRX_DIR, emit a TRX it can fold into its consolidated results table.
if [ -n "${SD_TRX_DIR:-}" ]; then
  dotnet test "$MAC_APPIUM_PROJECT" --nologo \
    --logger "trx;LogFileName=mac-appium-results.trx" --results-directory "$SD_TRX_DIR"
else
  dotnet test "$MAC_APPIUM_PROJECT" --nologo --logger "trx;LogFileName=mac-appium-results.trx"
fi
RESULT=$?

exit $RESULT
