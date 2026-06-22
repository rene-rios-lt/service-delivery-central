#!/usr/bin/env bash
# Bring up the whole local demo in one command: backend + data-simulator, then the
# three frontend clients — each in its own Terminal.app window.
#
#   Dispatcher -> Web        (launchWebPage.sh)
#   ServiceRep -> iPhone sim (startInPhone.sh)
#   Requester  -> iPad sim   (startInTablet.sh)
#
# Backend + simulator are started in the background (via start.sh) and this returns
# once they're up; the three client launchers block in their own windows (Ctrl-C each
# to stop). Tear down backend + simulator with scripts/local/stop.sh.
#
# Env:
#   SD_NO_LAUNCH=1   don't open Terminal windows — print the commands instead
set -euo pipefail

LOCAL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # scripts/local

# --- 1. Backend + data-simulator (idempotent: skip if already listening on :5180) ---
if lsof -nP -iTCP:5180 -sTCP:LISTEN -t >/dev/null 2>&1; then
  echo "==> Backend already running on :5180 — skipping start.sh."
else
  echo "==> Starting backend + simulator ..."
  "$LOCAL/start.sh"
fi

# --- 2. Frontend clients, each in its own Terminal.app window ---
open_in_terminal() {
  local cmd="$1" esc
  if [ "${SD_NO_LAUNCH:-0}" = "1" ]; then
    echo "    (no-launch) would open Terminal and run: $cmd"
    return 0
  fi
  esc="${cmd//\\/\\\\}"; esc="${esc//\"/\\\"}"
  osascript \
    -e 'tell application "Terminal"' \
    -e 'activate' \
    -e "do script \"$esc\"" \
    -e 'end tell' >/dev/null 2>&1 \
    || echo "!! Could not open Terminal.app (macOS only). Run it manually: $cmd"
}

echo "==> Launching frontend clients (each in its own Terminal window) ..."
open_in_terminal "$LOCAL/launchWebPage.sh"    # Dispatcher -> Web
open_in_terminal "$LOCAL/startInPhone.sh"     # ServiceRep -> iPhone
open_in_terminal "$LOCAL/startInTablet.sh"    # Requester  -> iPad

cat <<'EOF'

==> System starting.
    Dispatcher -> Web        (browser opens at http://localhost:5023; log in as a dispatcher)
    ServiceRep -> iPhone sim (log in as a rep)
    Requester  -> iPad sim   (log in as a requester)

    The two simulator builds take a few minutes on first run.
    Stop a client: Ctrl-C in its Terminal window.
    Stop backend + simulator: scripts/local/stop.sh
EOF
