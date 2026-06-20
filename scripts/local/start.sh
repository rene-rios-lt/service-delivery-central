#!/usr/bin/env bash
# Starts the backend (HTTP profile) and simulator as background processes for a
# local headless run. Logs to /tmp/sd-*.log; PIDs to /tmp/sd-*.pid.
# Stop with scripts/local/stop.sh.
set -u

ROOT="/Users/rrios/dev/ServiceDelivery"
BACKEND="$ROOT/service-delivery-backend"
SIM="$ROOT/service-delivery-simulator"
BASE="http://localhost:5180"

# Load appsettings.Local.json (gitignored, holds local creds) on top of appsettings.json.
# CreateDefaultBuilder layers appsettings.{DOTNET_ENVIRONMENT}.json — same pattern serves
# future Development / Test / Production environments.
export DOTNET_ENVIRONMENT=Local

# Keep the host awake for the lifetime of the local system. On macOS, idle sleep / App Nap
# suspends the dotnet processes and drops the simulator's SignalR (RepHub) connections — which
# makes jobs silently fail (offers expire, an in-progress job re-queues) without any code being
# wrong. A standalone `caffeinate -i` asserts "no idle sleep" until stop.sh kills it (its own
# pidfile keeps the dotnet process tree untouched so teardown is unchanged). See BUG-019.
if command -v caffeinate >/dev/null 2>&1; then
  caffeinate -i > /dev/null 2>&1 & echo $! > /tmp/sd-caffeinate.pid
  echo "==> caffeinate holding off idle sleep (PID $(cat /tmp/sd-caffeinate.pid))."
fi

echo "==> Starting backend (HTTP profile, $BASE, env=$DOTNET_ENVIRONMENT) ..."
( cd "$BACKEND" && nohup dotnet run --project src/ServiceDelivery.Api --launch-profile http \
    > /tmp/sd-backend.log 2>&1 & echo $! > /tmp/sd-backend.pid )

echo "==> Waiting for backend to come up and seed (polling login, up to 180s) ..."
up=0
for i in $(seq 1 60); do
  tok=$(curl -s -X POST "$BASE/auth/login" -H "Content-Type: application/json" \
        -d '{"email":"alex@dealer.com","password":"Password123!"}' 2>/dev/null | jq -r '.token // empty')
  if [ -n "$tok" ]; then up=1; echo "    backend is up and seeded (login returned a token)."; break; fi
  sleep 3
done
if [ "$up" -ne 1 ]; then
  echo "!! Backend did not respond with a token in time. Last 40 log lines:"
  tail -40 /tmp/sd-backend.log
  exit 1
fi

echo "==> Starting simulator ..."
( cd "$SIM" && nohup dotnet run --project src/ServiceDelivery.Simulator \
    > /tmp/sd-sim.log 2>&1 & echo $! > /tmp/sd-sim.pid )

echo "==> Started. Backend PID $(cat /tmp/sd-backend.pid 2>/dev/null), Simulator PID $(cat /tmp/sd-sim.pid 2>/dev/null)."
echo "    Backend log:   /tmp/sd-backend.log"
echo "    Simulator log: /tmp/sd-sim.log"
echo "    Run scripts/local/smoke.sh to drive a job. Stop with scripts/local/stop.sh."
