#!/bin/bash
# test-report.sh — shared helpers for the live test-summary table in test-all.sh.
# Sourced, not executed. Provides: root discovery, TRX parsing, and colour setup.

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
