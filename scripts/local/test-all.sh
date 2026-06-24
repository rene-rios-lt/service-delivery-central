#!/bin/bash
# Runs every test project across the three repos in parallel and renders a live
# table of unit/integration counts (total / passed / failed) per suite, updating
# as each project finishes. On a non-terminal stdout it prints the final table once.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../utils/test-report.sh
source "$SCRIPT_DIR/../utils/test-report.sh"

ROOT_DIR="$(sd_find_root "$SCRIPT_DIR")" || exit 1

BACKEND="$ROOT_DIR/service-delivery-backend/tests"
FRONTEND="$ROOT_DIR/service-delivery-frontend/tests"
SIMULATOR="$ROOT_DIR/service-delivery-simulator/tests"

# Per-project definitions: a short key and its test project directory.
KEYS=(be_domain be_app be_arch be_infra be_api fe_client sim)
DIR_be_domain="$BACKEND/ServiceDelivery.Domain.Tests"
DIR_be_app="$BACKEND/ServiceDelivery.Application.Tests"
DIR_be_arch="$BACKEND/ServiceDelivery.Architecture.Tests"
DIR_be_infra="$BACKEND/ServiceDelivery.Infrastructure.Tests"
DIR_be_api="$BACKEND/ServiceDelivery.Api.Tests"
DIR_fe_client="$FRONTEND/ServiceDelivery.Client.Tests"
DIR_sim="$SIMULATOR/ServiceDelivery.Simulator.Tests"

TMP="$(mktemp -d)"
mkdir -p "$TMP/trx"
trap 'rm -rf "$TMP"' EXIT

REDRAW_LINES=14
first_render=1

# Run one test project in the background, recording status and a TRX result file.
run_project() {
  local key="$1"
  local dir
  eval "dir=\$DIR_$key"
  echo "STARTED" > "$TMP/$key.status"
  dotnet test "$dir" --nologo \
    --logger "trx;LogFileName=$key.trx" \
    --results-directory "$TMP/trx" > "$TMP/$key.log" 2>&1
  echo "DONE $?" > "$TMP/$key.status"
}

# Aggregate the projects making up one cell. Echoes "total passed failed state",
# where state is pending | running | pass | fail.
cell_stats() {
  local t=0 p=0 f=0 any_fail=0 n=0 started=0 done_n=0
  local key status tt pp ff rc
  for key in "$@"; do
    n=$((n + 1))
    status="$(cat "$TMP/$key.status" 2>/dev/null)"
    [ -n "$status" ] && started=$((started + 1))
    case "$status" in
      DONE*)
        done_n=$((done_n + 1))
        read -r tt pp ff <<< "$(sd_parse_trx "$TMP/trx/$key.trx")"
        t=$((t + tt)); p=$((p + pp)); f=$((f + ff))
        rc="${status#DONE }"
        { [ "$rc" != "0" ] || [ "${ff:-0}" -gt 0 ]; } && any_fail=1
        ;;
    esac
  done
  local state
  if [ "$started" -eq 0 ]; then state="pending"
  elif [ "$done_n" -lt "$n" ]; then state="running"
  elif [ "$any_fail" -eq 1 ]; then state="fail"
  else state="pass"; fi
  echo "$t $p $f $state"
}

# Print one table line plus a clear-to-end-of-line so stale chars never linger.
pln() { printf '%s%s\n' "$1" "$CLR_EOL"; }

# Build a formatted data row. stats = "total passed failed state"; state "na"
# renders a not-applicable row.
fmt_row() {
  local suite="$1" level="$2" stats="$3"
  local t p f state tcol pcol fcol scol
  read -r t p f state <<< "$stats"
  if [ "$state" = "na" ]; then
    tcol=$(printf '%7s' '-'); pcol=$(printf '%8s' '-'); fcol=$(printf '%8s' '-')
    scol="${C_DIM}n/a${C_RESET}"
  else
    tcol=$(printf '%7s' "$t")
    pcol=$(printf '%8s' "$p")
    fcol=$(printf '%8s' "$f")
    [ "${f:-0}" -gt 0 ] 2>/dev/null && fcol="${C_RED}${fcol}${C_RESET}"
    case "$state" in
      pending) scol="${C_DIM}. pending${C_RESET}" ;;
      running) scol="${C_YELLOW}... running${C_RESET}" ;;
      pass)    scol="${C_GREEN}done${C_RESET}" ;;
      fail)    scol="${C_RED}FAILED${C_RESET}" ;;
    esac
  fi
  printf ' %-10s %-12s %s %s %s  %s' "$suite" "$level" "$tcol" "$pcol" "$fcol" "$scol"
}

render() {
  if [ "$SD_TTY" -eq 1 ] && [ "$first_render" -eq 0 ]; then
    printf '\033[%dA' "$REDRAW_LINES"
  fi
  first_render=0

  local be_unit be_integ fe_unit sim_unit
  be_unit="$(cell_stats be_domain be_app be_arch)"
  be_integ="$(cell_stats be_infra be_api)"
  fe_unit="$(cell_stats fe_client)"
  sim_unit="$(cell_stats sim)"

  pln "$(printf '%s %-10s %-12s %7s %8s %8s  %s%s' "$C_BOLD" 'Suite' 'Level' 'Total' 'Passed' 'Failed' 'Status' "$C_RESET")"
  pln " ---------- ------------ ------- -------- --------  ----------"
  pln "$(fmt_row 'Backend'   'Unit'        "$be_unit")"
  pln "$(fmt_row 'Backend'   'Integration' "$be_integ")"
  pln "$(fmt_row 'Frontend'  'Unit'        "$fe_unit")"
  pln "$(fmt_row 'Frontend'  'E2E (PW)'    '0 0 0 na')"
  pln "$(fmt_row 'Frontend'  'E2E (Appium)' '0 0 0 na')"
  pln "$(fmt_row 'Simulator' 'Unit'        "$sim_unit")"
  pln "$(fmt_row 'Simulator' 'Integration' '0 0 0 na')"

  # Column totals across every project.
  local gt gp gf gstate
  read -r gt gp gf gstate <<< "$(cell_stats "${KEYS[@]}")"
  pln " ---------- ------------ ------- -------- --------  ----------"
  pln "$(fmt_row 'Total' '' "$gt $gp $gf $gstate")"
  pln ""
  case "$gstate" in
    pending|running) pln "  ${C_YELLOW}Running... ${gp}/${gt} passed so far${C_RESET}" ;;
    pass)            pln "  ${C_GREEN}${C_BOLD}All ${gt} tests passed.${C_RESET}" ;;
    fail)            pln "  ${C_RED}${C_BOLD}${gf} failed, ${gp} passed of ${gt} tests.${C_RESET}" ;;
  esac
  pln "  ${C_DIM}Frontend E2E (Playwright/Appium) needs a live system — run test-e2e.sh / test-appium.sh.${C_RESET}"
}

all_done() {
  local key
  for key in "${KEYS[@]}"; do
    case "$(cat "$TMP/$key.status" 2>/dev/null)" in
      DONE*) ;;
      *) return 1 ;;
    esac
  done
  return 0
}

# Launch every project in parallel.
for key in "${KEYS[@]}"; do
  run_project "$key" &
done

if [ "$SD_TTY" -eq 1 ]; then
  render
  while ! all_done; do
    sleep 0.5
    render
  done
  render
else
  wait
  render
fi

# Exit non-zero if any project failed to build/run or reported failing tests.
read -r _ _ total_failed final_state <<< "$(cell_stats "${KEYS[@]}")"
[ "$final_state" = "fail" ] && exit 1
exit 0
