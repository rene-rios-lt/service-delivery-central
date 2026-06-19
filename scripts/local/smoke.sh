#!/usr/bin/env bash
# Headless smoke: drives ONE service-delivery job end-to-end by API and watches
# the automated cycle (offer -> accept -> en route -> arrive -> dwell -> complete).
# Assumes backend + simulator are already running (scripts/local/start.sh).
set -u

BASE="http://localhost:5180"
PW="Password123!"

login() { # $1=email -> prints token
  curl -s -X POST "$BASE/auth/login" -H "Content-Type: application/json" \
    -d "{\"email\":\"$1\",\"password\":\"$PW\"}" | jq -r '.token // empty'
}

echo "==> Logging in (dispatcher alex, requester bronze1) ..."
DISP=$(login "alex@dealer.com")
REQ=$(login "bronze1@example.com")
if [ -z "$DISP" ] || [ -z "$REQ" ]; then echo "!! login failed (backend up? seeded?)"; exit 1; fi

echo "==> WARM-UP GATE: waiting for the simulator to claim vehicles and post positions ..."
echo "    (polling GET /dispatcher/fleet for an Available rep with a position; up to 90s)"
LAT=""; LNG=""; REPNAME=""
for i in $(seq 1 30); do
  fleet=$(curl -s "$BASE/dispatcher/fleet" -H "Authorization: Bearer $DISP")
  row=$(echo "$fleet" | jq -c '[.[] | select(.state=="Available" and .lastPosition!=null)][0] // empty')
  if [ -n "$row" ]; then
    LAT=$(echo "$row" | jq -r '.lastPosition.lat')
    LNG=$(echo "$row" | jq -r '.lastPosition.lng')
    REPNAME=$(echo "$row" | jq -r '.name')
    echo "    fleet warm: $REPNAME is Available at ($LAT, $LNG) after $((i*3))s."
    break
  fi
  sleep 3
done
if [ -z "$LAT" ]; then
  echo "!! COLD-START GAP HIT: no Available rep with a position after 90s."
  echo "   Simulator probably isn't posting/claiming. Last 30 simulator log lines:"
  tail -30 /tmp/sd-sim.log 2>/dev/null
  exit 1
fi

echo "==> Picking DTC-001 (Hydraulic — widely covered) ..."
DTCID=$(curl -s "$BASE/dtcs" -H "Authorization: Bearer $REQ" | jq -r '.[] | select(.code=="DTC-001") | .id')
echo "    DTC id: $DTCID"

echo "==> Submitting a request AT the rep's position (short navigate leg) ..."
SUBMIT=$(curl -s -X POST "$BASE/service-requests" -H "Authorization: Bearer $REQ" \
  -H "Content-Type: application/json" \
  -d "{\"dtcId\":\"$DTCID\",\"latitude\":$LAT,\"longitude\":$LNG}")
RID=$(echo "$SUBMIT" | jq -r '.requestId // empty')
echo "    submit response: $SUBMIT"
if [ -z "$RID" ]; then echo "!! submit failed"; exit 1; fi

echo "==> Watching the job (poll every 3s, up to ~6 min for the 120-240s dwell) ..."
last=""
for i in $(seq 1 120); do
  st=$(curl -s "$BASE/service-requests/$RID" -H "Authorization: Bearer $REQ")
  status=$(echo "$st" | jq -r '.status')
  offers=$(echo "$st" | jq '.offerHistory | length')
  rep=$(echo "$st" | jq -r '.assignedRep.name // "none"')
  line="status=$status offers=$offers assignedRep=$rep"
  if [ "$line" != "$last" ]; then echo "    [$((i*3))s] $line"; last="$line"; fi
  if [ "$status" = "Completed" ]; then echo "==> COMPLETED — full automated cycle worked end-to-end."; exit 0; fi
  sleep 3
done

echo "!! Did not reach Completed in time. Final request state:"
curl -s "$BASE/service-requests/$RID" -H "Authorization: Bearer $REQ" | jq '.'
echo "--- last 20 simulator log lines ---"; tail -20 /tmp/sd-sim.log 2>/dev/null
exit 1
