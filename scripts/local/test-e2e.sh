#!/usr/bin/env bash
# Runs the Playwright end-to-end suite (tests/ServiceDelivery.Client.E2E) against a live system.
#
# These tests drive the running Web host (default http://localhost:5023) and the backend (:5180)
# as a black box — they are NOT part of the /master pipeline or test-all.sh (which never starts a
# live system). This script brings the system up if it is not already running, installs the
# Playwright browser binaries on first run, executes the suite, and tears down anything it started.
#
# Idempotent: if the backend is already up on :5180 and the web host on :5023, it reuses them and
# does NOT tear them down on exit (only what this script starts is stopped).
#
# Env overrides:
#   E2E_BASE_URL             web host base URL          (default http://localhost:5023)
#   E2E_DISPATCHER_PASSWORD  seeded dispatcher password (default Password1!)
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
E2E_PROJECT="$FRONTEND_DIR/tests/ServiceDelivery.Client.E2E"
BACKEND_URL="http://localhost:5180"
WEB_URL="${E2E_BASE_URL:-http://localhost:5023}"

STARTED_BACKEND=0
STARTED_WEB=0
WEB_PID=""

cleanup() {
  if [ "$STARTED_WEB" -eq 1 ] && [ -n "$WEB_PID" ]; then
    echo "==> Stopping web host (PID $WEB_PID) ..."
    kill "$WEB_PID" 2>/dev/null || true
  fi
  if [ "$STARTED_BACKEND" -eq 1 ]; then
    echo "==> Stopping backend + simulator (stop.sh) ..."
    "$SCRIPT_DIR/stop.sh" || true
  fi
}
trap cleanup EXIT

# 1. Backend — start only if it is not already serving on :5180.
if curl -s "$BACKEND_URL/health" > /dev/null 2>&1 || curl -s "$BACKEND_URL" > /dev/null 2>&1; then
  echo "==> Backend already up on $BACKEND_URL — reusing."
else
  echo "==> Starting backend + simulator (start.sh) ..."
  "$SCRIPT_DIR/start.sh" || { echo "!! start.sh failed" >&2; exit 1; }
  STARTED_BACKEND=1
fi

# 2. Web host — start only if it is not already serving on :5023.
if curl -s "$WEB_URL" > /dev/null 2>&1; then
  echo "==> Web host already up on $WEB_URL — reusing."
else
  echo "==> Starting web host ($WEB_URL) ..."
  ( cd "$FRONTEND_DIR" && dotnet run --project src/ServiceDelivery.Client.Web ) &
  WEB_PID=$!
  STARTED_WEB=1
  echo "==> Waiting for web host to respond at $WEB_URL ..."
  for _ in $(seq 1 60); do
    curl -s "$WEB_URL" > /dev/null 2>&1 && break
    sleep 1
  done
  if ! curl -s "$WEB_URL" > /dev/null 2>&1; then
    echo "!! Web host did not respond at $WEB_URL in time." >&2
    exit 1
  fi
fi

# 3. Playwright browser binaries — install once (no-op if already present).
echo "==> Ensuring Playwright browsers are installed ..."
( cd "$E2E_PROJECT" && dotnet build > /dev/null )
PW_SCRIPT="$E2E_PROJECT/bin/Debug/net10.0/playwright.ps1"
if [ -f "$PW_SCRIPT" ]; then
  pwsh "$PW_SCRIPT" install chromium || {
    echo "!! Could not install Playwright browsers. Install pwsh, then run:" >&2
    echo "   pwsh $PW_SCRIPT install" >&2
    exit 1
  }
else
  echo "!! playwright.ps1 not found at $PW_SCRIPT — build the E2E project first." >&2
  exit 1
fi

# 4. Run the suite.
echo "==> Running Playwright E2E suite ..."
export E2E_BASE_URL="$WEB_URL"
export E2E_DISPATCHER_PASSWORD="${E2E_DISPATCHER_PASSWORD:-Password1!}"
dotnet test "$E2E_PROJECT" --nologo
RESULT=$?

exit $RESULT
