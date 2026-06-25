#!/usr/bin/env bash
# Runs the COMPLETE test suite and renders one unified results table: the offline unit + integration
# projects via test-unit-and-integration.sh, then the live end-to-end suite (Playwright + Appium)
# via test-e2e.sh.
#
# Unlike test-unit-and-integration.sh, this DOES boot a live system (backend, web host, simulator,
# iOS sim, Appium server) for the E2E phase — see test-playwright.sh / test-appium.sh for
# prerequisites. Both phases run even if the first fails, so you get the full picture; the exit code
# is non-zero if either phase fails.
#
# For the fast, offline-only run (no live system) use test-unit-and-integration.sh directly.
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../utils/test-report.sh
source "$SCRIPT_DIR/../utils/test-report.sh"

# Shared scratch dir: the unit phase appends its aggregated rows to SD_SUMMARY_FILE; the E2E phase's
# child scripts drop a TRX per suite into SD_TRX_DIR. Both feed the unified table at the end.
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
export SD_TRX_DIR="$WORK"
export SD_SUMMARY_FILE="$WORK/summary.txt"
: > "$SD_SUMMARY_FILE"

echo "==> [1/2] Unit + integration (test-unit-and-integration.sh) ..."
"$SCRIPT_DIR/test-unit-and-integration.sh"
UNIT_RC=$?

echo
echo "==> [2/2] End-to-end (test-e2e.sh) ..."
"$SCRIPT_DIR/test-e2e.sh"
E2E_RC=$?

echo
echo "==> Complete suite results"
{
  grep '^Backend|Unit|'        "$SD_SUMMARY_FILE"
  grep '^Backend|Integration|' "$SD_SUMMARY_FILE"
  grep '^Frontend|Unit|'       "$SD_SUMMARY_FILE"
  sd_trx_row 'Frontend' 'E2E (PW)'     "$SD_TRX_DIR/playwright.trx"
  sd_trx_row 'Frontend' 'E2E (Appium)' "$SD_TRX_DIR/appium.trx"
  grep '^Simulator|Unit|'      "$SD_SUMMARY_FILE"
} | sd_render_results_table

[ "$UNIT_RC" -eq 0 ] && [ "$E2E_RC" -eq 0 ] && exit 0
exit 1
