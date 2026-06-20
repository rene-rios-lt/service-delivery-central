#!/usr/bin/env bash
# Headless smoke: drives ONE service-delivery job end-to-end by API and watches
# the automated cycle (offer -> accept -> en route -> arrive -> dwell -> complete).
# Assumes backend + simulator are already running (scripts/local/start.sh).
#
# BUG-018: idle vehicles teleport between sparse loop waypoints each tick, so the
# position sampled at warm-up is stale by the time matching runs — a matched rep
# could start a job up to ~one waypoint-hop (~12 km) away. Two guards keep this
# smoke honest rather than falsely timing out:
#   1) Short common-case leg — the DTC is fetched BEFORE sampling the position, then
#      the request is submitted immediately after the sample, so the matched rep is
#      usually right at the requester (~0 km leg) and arrives within a tick or two.
#   2) Worst-case window — the watch loop covers a full ~12 km leg at 65 mph
#      (~7 min) PLUS the 120-240 s on-site dwell, and logs elapsed time + remaining
#      distance each heartbeat. A run that never completes is classified as
#      "slow but progressing" (distance still shrinking) vs a real stall, so the
#      widened tolerance never masks a genuine regression.
set -u

BASE="http://localhost:5180"
PW="Password123!"
MAX_TICKS=240          # ~12 min: covers a worst-case ~12 km leg (~7 min) + max dwell (4 min)
HEARTBEAT_EVERY=5      # print a progress heartbeat every N ticks (~15 s)

login() { # $1=email -> prints token
  curl -s -X POST "$BASE/auth/login" -H "Content-Type: application/json" \
    -d "{\"email\":\"$1\",\"password\":\"$PW\"}" | jq -r '.token // empty'
}

# Haversine ground distance in metres between two lat/lng pairs.
hav() { # $1=lat1 $2=lng1 $3=lat2 $4=lng2 -> prints integer metres
  awk -v la1="$1" -v lo1="$2" -v la2="$3" -v lo2="$4" 'BEGIN{
    r=6371000; d2r=atan2(0,-1)/180;
    dla=(la2-la1)*d2r; dlo=(lo2-lo1)*d2r;
    a=sin(dla/2)^2 + cos(la1*d2r)*cos(la2*d2r)*sin(dlo/2)^2;
    printf "%.0f", r*2*atan2(sqrt(a),sqrt(1-a))
  }'
}

echo "==> Logging in (dispatcher alex, requester bronze1) ..."
DISP=$(login "alex@dealer.com")
REQ=$(login "bronze1@example.com")
if [ -z "$DISP" ] || [ -z "$REQ" ]; then echo "!! login failed (backend up? seeded?)"; exit 1; fi

echo "==> Picking DTC-001 (Hydraulic — widely covered) BEFORE sampling position ..."
DTCID=$(curl -s "$BASE/dtcs" -H "Authorization: Bearer $REQ" | jq -r '.[] | select(.code=="DTC-001") | .id')
if [ -z "$DTCID" ] || [ "$DTCID" = "null" ]; then echo "!! could not resolve DTC-001 id"; exit 1; fi
echo "    DTC id: $DTCID"

echo "==> WARM-UP GATE + immediate submit (keeps the navigate leg short) ..."
echo "    (polling GET /dispatcher/fleet for an Available rep with a position; up to 90s)"
LAT=""; LNG=""; REPNAME=""; RID=""
for i in $(seq 1 30); do
  fleet=$(curl -s "$BASE/dispatcher/fleet" -H "Authorization: Bearer $DISP")
  row=$(echo "$fleet" | jq -c '[.[] | select(.state=="Available" and .lastPosition!=null)][0] // empty')
  if [ -n "$row" ]; then
    LAT=$(echo "$row" | jq -r '.lastPosition.lat')
    LNG=$(echo "$row" | jq -r '.lastPosition.lng')
    REPNAME=$(echo "$row" | jq -r '.name')
    # Submit RIGHT NOW, before the vehicle's next position post (every 3s) moves it
    # off this waypoint — so the matched rep starts at ~0 km from the requester.
    SUBMIT=$(curl -s -X POST "$BASE/service-requests" -H "Authorization: Bearer $REQ" \
      -H "Content-Type: application/json" \
      -d "{\"dtcId\":\"$DTCID\",\"latitude\":$LAT,\"longitude\":$LNG}")
    RID=$(echo "$SUBMIT" | jq -r '.requestId // empty')
    echo "    fleet warm after $((i*3))s: submitted at $REPNAME's position ($LAT, $LNG)."
    echo "    submit response: $SUBMIT"
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
if [ -z "$RID" ]; then echo "!! submit failed: $SUBMIT"; exit 1; fi

echo "==> Watching the job (poll every 3s, up to ~$((MAX_TICKS*3/60)) min) ..."
last=""; first_dist=""; last_dist=""; ever_assigned=0
for i in $(seq 1 "$MAX_TICKS"); do
  st=$(curl -s "$BASE/service-requests/$RID" -H "Authorization: Bearer $REQ")
  status=$(echo "$st" | jq -r '.status')
  offers=$(echo "$st" | jq '.offerHistory | length')
  rep=$(echo "$st" | jq -r '.assignedRep.name // "none"')
  [ "$rep" != "none" ] && ever_assigned=1

  # Track the assigned rep's remaining distance so a slow leg reads as progress, not a hang.
  dist=""
  if [ "$rep" != "none" ]; then
    frow=$(curl -s "$BASE/dispatcher/fleet" -H "Authorization: Bearer $DISP" \
      | jq -c --arg n "$rep" '[.[] | select(.name==$n)][0] // empty')
    vlat=$(echo "$frow" | jq -r '.lastPosition.lat // empty')
    vlng=$(echo "$frow" | jq -r '.lastPosition.lng // empty')
    if [ -n "$vlat" ] && [ -n "$vlng" ]; then
      dist=$(hav "$vlat" "$vlng" "$LAT" "$LNG")
      [ -z "$first_dist" ] && first_dist="$dist"
      last_dist="$dist"
    fi
  fi

  line="status=$status offers=$offers assignedRep=$rep"
  if [ "$line" != "$last" ]; then
    echo "    [$((i*3))s] $line${dist:+ dist=${dist}m}"
    last="$line"
  elif [ $((i % HEARTBEAT_EVERY)) -eq 0 ]; then
    echo "    [$((i*3))s] (working) $line${dist:+ dist=${dist}m}"
  fi

  if [ "$status" = "Completed" ]; then echo "==> COMPLETED — full automated cycle worked end-to-end in $((i*3))s."; exit 0; fi
  sleep 3
done

echo "!! Did not reach Completed within ~$((MAX_TICKS*3/60)) min. Final request state:"
curl -s "$BASE/service-requests/$RID" -H "Authorization: Bearer $REQ" | jq '.'
# Classify the non-completion so a widened window never hides a real regression, and so
# the three distinct failure modes are not confused for one another.
if [ "$ever_assigned" -eq 0 ]; then
  echo "--- DIAGNOSIS: request was NEVER assigned (offers=$offers, all expired/declined)."
  echo "    The simulator never accepted an offer. This is the OFFER/RepHub path, NOT navigation:"
  echo "    most likely the smoke submitted before the sim's per-rep RepHub auto-accept warmed up"
  echo "    (the warm-up gate only confirms position-posting, which comes up first), or auto-accept"
  echo "    is down. Re-run after the sim has been up longer, or check the sim's RepHub connections."
elif [ -n "$first_dist" ] && [ -n "$last_dist" ] && [ "$last_dist" -lt "$first_dist" ]; then
  echo "--- DIAGNOSIS: assigned and still closing (${first_dist}m -> ${last_dist}m): the leg is just long."
  echo "    This is NOT a navigation stall — raise MAX_TICKS or shorten the leg. See BUG-018."
else
  echo "--- DIAGNOSIS: assigned but distance did NOT shrink (${first_dist:-n/a}m -> ${last_dist:-n/a}m):"
  echo "    possible REAL navigation stall — investigate the sim navigation step."
fi
echo "--- last 20 simulator log lines ---"; tail -20 /tmp/sd-sim.log 2>/dev/null
exit 1
