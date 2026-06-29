#!/usr/bin/env bash
# smoke-mobile.sh — the WebView per-runtime smoke (QUAL-008).
#
# The mobile / WKWebView analogue of smoke-web.sh. MAUI Blazor Hybrid renders the entire UI inside a
# WKWebView (BlazorWebView); XCUITest's native accessibility tree sees only the WebView container, so
# the HTML the app actually renders is reachable ONLY after switching to the WEBVIEW context and
# selecting by data-testid. That is the runtime boundary that broke in BUG-031 — and one that neither
# the headless smoke.sh (no UI at all) nor the browser smoke-web.sh (a real browser DOM, not a
# WKWebView) can exercise. This smoke is the single runtime-specific assertion for that boundary:
# launch the Mobile app on a booted iOS simulator, switch to the WEBVIEW context, and confirm a known
# data-testid element is reachable inside it.
#
# It is deliberately thin — one assertion, not a flow (the full ServiceRep flow is the Appium suite).
# It runs that one smoke test (WebViewReachabilitySmokeTests) through test-appium.sh, which owns the
# heavy lifting and the teardown: bring the backend up if needed, boot the simulator, build + install
# the Mobile app, start Appium, run the filtered test, and tear down only what it started. Idempotent
# and live — like test-appium.sh it needs a Mac with Xcode simulators and Appium installed:
#   npm install -g appium && appium driver install xcuitest
#
# Per-runtime smoke entry points (QUAL-008) — each asserts only what breaks in its own runtime:
#   * Browser (WASM) -> scripts/local/smoke-web.sh    real cross-origin login (CORS, BUG-023)
#   * WebView (MAUI) -> scripts/local/smoke-mobile.sh  data-testid reachable in WEBVIEW (BUG-031)
#   * Headless (API) -> scripts/local/smoke.sh         one job end-to-end by API (no UI runtime)
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Delegate to test-appium.sh with an NUnit filter so ONLY the WebView reachability smoke runs. exec
# replaces this process so test-appium.sh's exit code (and its EXIT-trap teardown) propagate directly.
exec "$SCRIPT_DIR/test-appium.sh" "FullyQualifiedName~WebViewReachabilitySmokeTests"
