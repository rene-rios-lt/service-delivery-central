#!/usr/bin/env bash
# Per-merge FRONTEND integration smoke — the browser analogue of smoke.sh (QUAL-005).
#
# smoke.sh drives the backend+simulator job cycle by API. This script drives the shortest
# REAL cross-origin web path the Dispatcher takes: open the web host, complete a cross-origin
# login as the seeded dispatcher, load the dashboard's first data, and reach SignalR — every
# boundary a browser crosses on the way to the dashboard. It fails LOUDLY (non-zero exit) the
# instant any one of those boundaries breaks, so a cross-process defect surfaces in the PR that
# introduces it instead of accumulating until the late E2E run (the BUG-023…032 flood; see QUAL-005).
#
# A green unit/bUnit suite is NOT evidence the screen works end-to-end — those defects were all
# green in the unit suites the whole time. This live net is the evidence, and it belongs at the
# FRONT of the loop, run per change.
#
# What each check guards (and the bug class it would have caught):
#   1. Web host shell + styling   — unstyled/mis-bundled host (BUG-020/021/022)
#   2. CORS preflight             — browser-only CORS break (BUG-023)
#   3. Cross-origin login         — login blocked by CORS / broken auth (BUG-023/028/030)
#   4. Dashboard data (authed)    — missing bearer / wrong 401 handling (BUG-024/028/030)
#   5. SignalR negotiate          — dead real-time channel ("dead SignalR")
#
# Thin and fast: on a warm system (backend on :5180 + web host on :5023 already up) it reuses
# both and just runs the five checks in a few seconds — cheap enough to invoke per change. On a
# cold system it boots via start.sh + the web host, and tears down ONLY what it started.
#
# This is the WEB-runtime smoke (a real browser-context cross-origin login — the CORS boundary,
# BUG-023). QUAL-008 completes the per-runtime set with the WKWebView DOM-reachability check on MAUI
# Mobile (BUG-031) in scripts/local/smoke-mobile.sh, and the headless API path in scripts/local/smoke.sh.
#
# Scope note: "dispatcher1" in the QUAL-005 story is the dispatcher persona; the seeded dispatcher
# account is alex@dealer.com (same account smoke.sh uses). Override creds with the env vars below.
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

BASE="${SD_BACKEND_URL:-http://localhost:5180}"
WEB_ORIGIN="${SD_WEB_URL:-http://localhost:5023}"   # the browser origin the WASM app runs from
DISP_EMAIL="${SD_DISPATCHER_EMAIL:-alex@dealer.com}"
DISP_PW="${SD_DISPATCHER_PASSWORD:-Password123!}"

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

# fail <step> <why> — print a loud diagnosis, dump the most relevant log, and exit non-zero.
fail() {
  echo ""
  echo "!! FRONTEND SMOKE FAILED at: $1"
  echo "   $2"
  echo "   A cross-boundary break is live RIGHT NOW — do not merge until this passes."
  echo "--- last 30 backend log lines ---"
  tail -30 /tmp/sd-backend.log 2>/dev/null || echo "   (no backend log)"
  exit 1
}

# ---------------------------------------------------------------------------
# Boot the system idempotently (mirrors test-playwright.sh): reuse what is up,
# start only what is missing, tear down on exit only what THIS script started.
# ---------------------------------------------------------------------------
if curl -s "$BASE/health" > /dev/null 2>&1 || curl -s "$BASE" > /dev/null 2>&1; then
  echo "==> Backend already up on $BASE — reusing."
else
  echo "==> Starting backend + simulator (start.sh) ..."
  "$SCRIPT_DIR/start.sh" || { echo "!! start.sh failed" >&2; exit 1; }
  STARTED_BACKEND=1
fi

if curl -s "$WEB_ORIGIN" > /dev/null 2>&1; then
  echo "==> Web host already up on $WEB_ORIGIN — reusing."
else
  echo "==> Starting web host ($WEB_ORIGIN) ..."
  ( cd "$FRONTEND_DIR" && dotnet run --project src/ServiceDelivery.Client.Web ) > /tmp/sd-web.log 2>&1 &
  WEB_PID=$!
  STARTED_WEB=1
  echo "==> Waiting for web host to respond at $WEB_ORIGIN (up to 90s) ..."
  for _ in $(seq 1 90); do
    curl -s "$WEB_ORIGIN" > /dev/null 2>&1 && break
    sleep 1
  done
  curl -s "$WEB_ORIGIN" > /dev/null 2>&1 || fail "web host boot" "Web host did not respond at $WEB_ORIGIN within 90s (see /tmp/sd-web.log)."
fi

echo ""
echo "==> FRONTEND SMOKE — driving the Dispatcher web path against the live system ..."

# --- 1. Web host shell is served AND styled ---------------------------------
# Catches an unstyled / mis-bundled host (BUG-020/021/022): the page loads but its CSS
# bundle 404s, so the app renders naked. Assert the Blazor boot marker is present and the
# scoped-CSS bundle + app stylesheet both resolve 200.
host_html="$(curl -s "$WEB_ORIGIN/")"
echo "$host_html" | grep -q "_framework/blazor.webassembly" \
  || fail "web host shell" "GET $WEB_ORIGIN/ did not reference _framework/blazor.webassembly — the WASM host is not being served."
for css in "ServiceDelivery.Client.Web.styles.css" "css/app.css"; do
  code="$(curl -s -o /dev/null -w "%{http_code}" "$WEB_ORIGIN/$css")"
  [ "$code" = "200" ] || fail "web host styling" "Stylesheet /$css returned HTTP $code (expected 200) — host would render unstyled."
done
echo "    [1/5] PASS  web host shell served and styled (Blazor boot + CSS bundle resolve)."

# --- 2. CORS preflight from the web origin ----------------------------------
# Catches a browser-only CORS break (BUG-023): the server must answer the preflight with
# Access-Control-Allow-Origin for the browser to even attempt the login POST.
pf_headers="$(curl -s -o /dev/null -D - -X OPTIONS "$BASE/auth/login" \
  -H "Origin: $WEB_ORIGIN" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: content-type")"
echo "$pf_headers" | grep -iq "^access-control-allow-origin:" \
  || fail "CORS preflight" "OPTIONS $BASE/auth/login from Origin $WEB_ORIGIN returned no Access-Control-Allow-Origin — the browser would block login (CORS, BUG-023 class)."
echo "    [2/5] PASS  CORS preflight on /auth/login honours origin $WEB_ORIGIN."

# --- 3. Real cross-origin login ---------------------------------------------
# Catches login broken at the boundary: a token must come back AND the response must carry
# Access-Control-Allow-Origin so the browser is allowed to read it.
login_headers="$(mktemp)"
login_body="$(curl -s -D "$login_headers" -X POST "$BASE/auth/login" \
  -H "Origin: $WEB_ORIGIN" -H "Content-Type: application/json" \
  -d "{\"email\":\"$DISP_EMAIL\",\"password\":\"$DISP_PW\"}")"
TOKEN="$(echo "$login_body" | jq -r '.token // empty')"
grep -iq "^access-control-allow-origin:" "$login_headers" || { rm -f "$login_headers"; fail "cross-origin login" "POST /auth/login returned no Access-Control-Allow-Origin — a browser could not read the login response (CORS)."; }
rm -f "$login_headers"
[ -n "$TOKEN" ] || fail "cross-origin login" "Login as $DISP_EMAIL returned no token (backend up and seeded? response: $login_body)."
echo "    [3/5] PASS  cross-origin login as $DISP_EMAIL returns a token with CORS headers."

# --- 4. Dashboard's first data load (authenticated) -------------------------
# "Land on the dashboard": the dispatcher dashboard's first call is GET /dispatcher/fleet.
# Catches a missing bearer / wrong 401 handling (BUG-024/028/030): must be 200 + a JSON array.
fleet_body="$(mktemp)"
fleet_code="$(curl -s -o "$fleet_body" -w "%{http_code}" "$BASE/dispatcher/fleet" \
  -H "Authorization: Bearer $TOKEN" -H "Origin: $WEB_ORIGIN")"
if [ "$fleet_code" != "200" ]; then
  msg="GET /dispatcher/fleet returned HTTP $fleet_code (expected 200) — dashboard data path is broken"
  [ "$fleet_code" = "401" ] && msg="$msg (bearer not accepted — BUG-028/030 class)"
  rm -f "$fleet_body"; fail "dashboard data" "$msg."
fi
jq -e 'type == "array"' "$fleet_body" > /dev/null 2>&1 || { rm -f "$fleet_body"; fail "dashboard data" "GET /dispatcher/fleet did not return a JSON array — the dashboard would fail to render the fleet."; }
rm -f "$fleet_body"
echo "    [4/5] PASS  dispatcher dashboard data loads (GET /dispatcher/fleet → 200, array)."

# --- 5. SignalR is alive ----------------------------------------------------
# Catches a dead real-time channel. The browser SignalR client passes the JWT via the
# access_token query string for /hubs/* paths, then POSTs to .../negotiate. A live hub
# answers 200 with a connectionId (or connectionToken) and the CORS header.
neg_headers="$(mktemp)"
neg_body="$(mktemp)"
neg_code="$(curl -s -o "$neg_body" -D "$neg_headers" -w "%{http_code}" -X POST \
  "$BASE/hubs/dispatch/negotiate?negotiateVersion=1&access_token=$TOKEN" \
  -H "Origin: $WEB_ORIGIN")"
if [ "$neg_code" != "200" ]; then
  rm -f "$neg_headers" "$neg_body"; fail "SignalR negotiate" "POST /hubs/dispatch/negotiate returned HTTP $neg_code (expected 200) — real-time channel is dead."
fi
jq -e '.connectionId // .connectionToken' "$neg_body" > /dev/null 2>&1 || { rm -f "$neg_headers" "$neg_body"; fail "SignalR negotiate" "negotiate response carried no connectionId — SignalR handshake is broken."; }
grep -iq "^access-control-allow-origin:" "$neg_headers" || { rm -f "$neg_headers" "$neg_body"; fail "SignalR negotiate" "negotiate response had no Access-Control-Allow-Origin — the browser could not open the SignalR connection (CORS)."; }
rm -f "$neg_headers" "$neg_body"
echo "    [5/5] PASS  SignalR /hubs/dispatch negotiate succeeds (connectionId + CORS)."

echo ""
echo "==> FRONTEND SMOKE PASSED — the Dispatcher web path works end-to-end across every boundary."
exit 0
