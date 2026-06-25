#!/bin/bash
# test-report.sh — shared helpers for the test-summary tables. Sourced, not executed.
# Provides: root discovery, TRX parsing, colour setup, and a static results-table renderer.
# The live in-progress table lives in test-unit-and-integration.sh; test-all.sh and test-e2e.sh
# use sd_render_results_table here for their final consolidated tables.

# Walk up from the given directory to the ServiceDelivery root (the dir that
# contains the three working repos). Echoes the root path, or fails with a message.
sd_find_root() {
  local d="${1:-$PWD}"
  while [ ! -d "$d/service-delivery-backend" ] && [ "$d" != "/" ]; do
    d="$(dirname "$d")"
  done
  if [ ! -d "$d/service-delivery-backend" ]; then
    echo "Error: could not find service-delivery-backend repo from ${1:-$PWD}" >&2
    return 1
  fi
  echo "$d"
}

# Echo "total passed failed" pulled from the <Counters .../> line of a TRX file.
# Echoes "0 0 0" if the file or counters are missing (e.g. the run errored).
sd_parse_trx() {
  local f="$1" line total passed failed
  if [ ! -f "$f" ]; then
    echo "0 0 0"
    return
  fi
  line=$(grep -o '<Counters[^>]*>' "$f" | head -1)
  total=$(echo "$line" | sed -n 's/.*total="\([0-9]*\)".*/\1/p')
  passed=$(echo "$line" | sed -n 's/.*passed="\([0-9]*\)".*/\1/p')
  failed=$(echo "$line" | sed -n 's/.*failed="\([0-9]*\)".*/\1/p')
  echo "${total:-0} ${passed:-0} ${failed:-0}"
}

# Echo one pipe-delimited table row ("Suite|Level|total|passed|failed|state") for a TRX file.
# state is "pass" when the file exists with no failures, "fail" otherwise (missing file = a run
# that never produced results, treated as a failure).
sd_trx_row() {
  local suite="$1" level="$2" trx="$3" t p f state
  read -r t p f <<< "$(sd_parse_trx "$trx")"
  if [ ! -f "$trx" ] || [ "${f:-0}" -gt 0 ]; then state="fail"; else state="pass"; fi
  printf '%s|%s|%s|%s|%s|%s\n' "$suite" "$level" "${t:-0}" "${p:-0}" "${f:-0}" "$state"
}

# Render a static results table from pipe-delimited rows on stdin:
#   Suite|Level|total|passed|failed|state      (state: pass | fail | na)
# Appends a Total row summed from the data rows, then a one-line verdict. Colours are empty on a
# non-TTY so piped/CI output stays clean. Returns 1 if any row failed, else 0.
sd_render_results_table() {
  local rows=() line
  while IFS= read -r line; do
    [ -n "$line" ] && rows+=("$line")
  done

  local gt=0 gp=0 gf=0 gany=0 suite level t p f state tcol pcol fcol scol
  printf '%s %-10s %-12s %7s %8s %8s  %s%s\n' "$C_BOLD" 'Suite' 'Level' 'Total' 'Passed' 'Failed' 'Status' "$C_RESET"
  printf ' ---------- ------------ ------- -------- --------  ----------\n'

  for line in "${rows[@]}"; do
    IFS='|' read -r suite level t p f state <<< "$line"
    if [ "$state" = "na" ]; then
      tcol=$(printf '%7s' '-'); pcol=$(printf '%8s' '-'); fcol=$(printf '%8s' '-')
      printf ' %-10s %-12s %s %s %s  %sn/a%s\n' "$suite" "$level" "$tcol" "$pcol" "$fcol" "$C_DIM" "$C_RESET"
      continue
    fi
    t=${t:-0}; p=${p:-0}; f=${f:-0}
    tcol=$(printf '%7s' "$t"); pcol=$(printf '%8s' "$p"); fcol=$(printf '%8s' "$f")
    [ "$f" -gt 0 ] 2>/dev/null && fcol="${C_RED}${fcol}${C_RESET}"
    case "$state" in
      pass) scol="${C_GREEN}done${C_RESET}" ;;
      fail) scol="${C_RED}FAILED${C_RESET}" ;;
      *)    scol="$state" ;;
    esac
    printf ' %-10s %-12s %s %s %s  %s\n' "$suite" "$level" "$tcol" "$pcol" "$fcol" "$scol"
    gt=$((gt + t)); gp=$((gp + p)); gf=$((gf + f))
    { [ "$state" = "fail" ] || [ "$f" -gt 0 ]; } && gany=1
  done

  printf ' ---------- ------------ ------- -------- --------  ----------\n'
  tcol=$(printf '%7s' "$gt"); pcol=$(printf '%8s' "$gp"); fcol=$(printf '%8s' "$gf")
  [ "$gf" -gt 0 ] && fcol="${C_RED}${fcol}${C_RESET}"
  if [ "$gany" -eq 1 ]; then scol="${C_RED}FAILED${C_RESET}"; else scol="${C_GREEN}done${C_RESET}"; fi
  printf ' %-10s %-12s %s %s %s  %s\n' 'Total' '' "$tcol" "$pcol" "$fcol" "$scol"
  printf '\n'
  if [ "$gany" -eq 1 ]; then
    printf '  %s%s%d failed, %d passed of %d tests.%s\n' "$C_RED" "$C_BOLD" "$gf" "$gp" "$gt" "$C_RESET"
    return 1
  fi
  printf '  %s%sAll %d tests passed.%s\n' "$C_GREEN" "$C_BOLD" "$gt" "$C_RESET"
  return 0
}

# Colour / cursor escapes — active only when stdout is a real terminal so piped
# or CI output stays clean. Sets SD_TTY=1 on a terminal, 0 otherwise.
if [ -t 1 ]; then
  SD_TTY=1
  C_RESET=$'\033[0m'
  C_GREEN=$'\033[32m'
  C_RED=$'\033[31m'
  C_YELLOW=$'\033[33m'
  C_DIM=$'\033[2m'
  C_BOLD=$'\033[1m'
  CLR_EOL=$'\033[K'
else
  SD_TTY=0
  C_RESET=''
  C_GREEN=''
  C_RED=''
  C_YELLOW=''
  C_DIM=''
  C_BOLD=''
  CLR_EOL=''
fi
