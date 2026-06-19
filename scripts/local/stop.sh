#!/usr/bin/env bash
# Stops the backend and simulator started by start.sh.
set -u

for svc in sim backend; do
  pidfile="/tmp/sd-$svc.pid"
  if [ -f "$pidfile" ]; then
    pid="$(cat "$pidfile")"
    if kill -0 "$pid" 2>/dev/null; then
      echo "==> Stopping $svc (PID $pid) and its dotnet children ..."
      # kill the dotnet run wrapper and any child (the actual app host)
      pkill -P "$pid" 2>/dev/null
      kill "$pid" 2>/dev/null
    fi
    rm -f "$pidfile"
  fi
done

# Belt-and-braces: free the backend port if anything is still holding it.
lingering=$(lsof -nP -iTCP:5180 -sTCP:LISTEN -t 2>/dev/null)
[ -n "$lingering" ] && { echo "==> Freeing port 5180 (PIDs: $lingering)"; kill $lingering 2>/dev/null; }

echo "==> Stopped."
