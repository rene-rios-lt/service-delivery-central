#!/usr/bin/env bash
# Tear down everything startSystem.sh brings up — the inverse of startSystem.sh:
#   1. backend + data-simulator (via stop.sh: also releases caffeinate, frees :5180)
#   2. the web client (frees :5023)
#   3. the mobile clients (kills the build/deploy console sessions, terminates the
#      app on the simulators, and shuts down the demo simulators)
#
# Safe to run anytime — idempotent, quietly skips anything that isn't running.
set -u

LOCAL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # scripts/local

APP_BUNDLE_ID="com.companyname.servicedelivery.client.mobile"
DEMO_DEVICES=("iPhone 17 Pro" "iPad mini (A17 Pro)")   # devices startInPhone.sh / startInTablet.sh use
WEB_PORT=5023
UDID_RE='[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}'

# --- 1. Backend + data-simulator (+ caffeinate, + frees :5180) ---
echo "==> Stopping backend + simulator ..."
"$LOCAL/stop.sh"

# --- 2. Web client (launchWebPage.sh keeps no pidfile; free its port) ---
web_pids="$(lsof -nP -iTCP:$WEB_PORT -sTCP:LISTEN -t 2>/dev/null || true)"
if [ -n "$web_pids" ]; then
  echo "==> Stopping web client on :$WEB_PORT (PIDs: $web_pids) ..."
  kill $web_pids 2>/dev/null || true
else
  echo "==> Web client not running on :$WEB_PORT."
fi

# --- 3. Mobile clients: console/deploy sessions, then the simulator apps ---
echo "==> Stopping mobile client build/deploy sessions ..."
pkill -f "ServiceDelivery.Client.Mobile" 2>/dev/null || true
pkill -f "simctl launch --console" 2>/dev/null || true

# Terminate the app on any booted device (harmless where it isn't installed/running).
for udid in $(xcrun simctl list devices booted 2>/dev/null | grep -oE "$UDID_RE"); do
  xcrun simctl terminate "$udid" "$APP_BUNDLE_ID" >/dev/null 2>&1 || true
done

# Shut down only the demo simulators (leaves any other booted simulators alone).
for name in "${DEMO_DEVICES[@]}"; do
  for udid in $(xcrun simctl list devices booted 2>/dev/null | grep -F "$name (" | grep -oE "$UDID_RE"); do
    echo "==> Shutting down simulator: $name ($udid)"
    xcrun simctl shutdown "$udid" >/dev/null 2>&1 || true
  done
done

# Quit Simulator.app only if nothing is left booted (don't close windows for other sims).
if ! xcrun simctl list devices booted 2>/dev/null | grep -qE "$UDID_RE"; then
  osascript -e 'tell application "Simulator" to quit' >/dev/null 2>&1 || true
fi

echo "==> System torn down."
