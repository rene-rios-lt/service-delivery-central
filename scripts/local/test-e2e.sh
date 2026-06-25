#!/usr/bin/env bash
# Runs the full end-to-end suite against a live system: the Playwright (web/desktop) suite via
# test-playwright.sh, then the Appium (iOS mobile) suite via test-appium.sh.
#
# Each child script manages its own setup and teardown (backend, web host, simulator, iOS sim,
# Appium server), so this orchestrator just runs them in sequence and renders a consolidated table.
# Both suites run even if the first fails, so you get the full picture; the exit code is non-zero
# if either suite fails.
#
# NOT part of the /master pipeline or the offline test-unit-and-integration.sh runner — these need
# a live system. See test-playwright.sh / test-appium.sh headers for prerequisites (Playwright
# browsers, Appium + xcuitest driver, a booted iOS simulator).
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../utils/test-report.sh
source "$SCRIPT_DIR/../utils/test-report.sh"

# Collect each suite's TRX so we can render one consolidated table. If a parent orchestrator
# (test-all.sh) already set SD_TRX_DIR, write into it and let the parent render; otherwise make our
# own scratch dir and render the E2E table here.
STANDALONE=0
if [ -z "${SD_TRX_DIR:-}" ]; then
  SD_TRX_DIR="$(mktemp -d)"
  export SD_TRX_DIR
  STANDALONE=1
  trap 'rm -rf "$SD_TRX_DIR"' EXIT
fi

echo "==> [1/2] Playwright E2E (test-playwright.sh) ..."
"$SCRIPT_DIR/test-playwright.sh"
PW_RC=$?

echo
echo "==> [2/2] Appium E2E (test-appium.sh) ..."
"$SCRIPT_DIR/test-appium.sh"
APPIUM_RC=$?

if [ "$STANDALONE" -eq 1 ]; then
  echo
  echo "==> End-to-end results"
  {
    sd_trx_row 'Frontend' 'E2E (PW)'     "$SD_TRX_DIR/playwright.trx"
    sd_trx_row 'Frontend' 'E2E (Appium)' "$SD_TRX_DIR/appium.trx"
  } | sd_render_results_table
fi

[ "$PW_RC" -eq 0 ] && [ "$APPIUM_RC" -eq 0 ] && exit 0
exit 1
