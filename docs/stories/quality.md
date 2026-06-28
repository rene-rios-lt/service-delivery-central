# Engineering-Quality Stories (`QUAL-`)

> Cross-cutting enhancements to the AI pipeline and engineering practice — not feature work for a single product repo. Tracked in [`execution-plan.md`](execution-plan.md) under **Cross-Cutting — Engineering Quality**. Central skill/agent changes ship via `/ship-it` (the `/master` pipeline never targets the central repo); any product-repo code changes (e.g. a test-suite audit's fixes) go through `/master`.

---

## QUAL-001 — Catch "masking" tests in AI Review (strengthen `/test-quality`)

**As a** maintainer of the TDD pipeline,
**I want** the AI Reviewer to flag tests that pass by coincidence — placeholder reuse, or mirroring the production code's own wrong assumption — and to lean on integration runs for cross-process contracts,
**so that** wire/identity-contract bugs can't hide behind a green unit suite.

**Motivation**
`BUG-016` (sim deserialized `/vehicles/available` as `string[]`; test fed the same wrong shape) and `BUG-017` (sim keyed workers by registration; tests reused one value as both the route id and the fleet-state row id) both shipped with 150 green simulator unit tests. Same root cause both times — tests that did not mirror the real contract — and both were caught only by the headless smoke, never by unit tests. See memory `feedback-masking-tests`.

**Acceptance Criteria:**
- The `/test-quality` skill (`.claude/skills/test-quality/SKILL.md`) gains an explicit **anti-masking rule**: tests must use realistic, contract-faithful, **distinct** identifiers; never reuse one placeholder for two distinct concepts (e.g. backend GUID vs registration string); request/response fixtures must match the **real** API shape. A test that would still pass against the wrong/old contract provides no protection and must be called out.
- The `story-ai-reviewer` agent's test-value check references this rule so masking tests are flagged on every story (not just when remembered).
- The `/test-quality` skill notes that mocked unit tests **cannot** verify a cross-process wire/identity contract — the headless smoke (`scripts/local/start.sh` + `scripts/local/smoke.sh`) is the integration net for that, and should be run before a repo is declared "done."
- The **simulator test suite is audited** for other masking instances (placeholder reuse collapsing two identities, or fixtures mirroring the code's assumption); each finding is either fixed or logged as a `BUG-`.
- Demonstrated: the strengthened guidance would have flagged the `BUG-016`/`BUG-017`-style tests as masking.

**Out of scope:** changing the pipeline's stages or adding a CI system; this is guidance + an audit, not new tooling.

**Done when:** the `/test-quality` skill and `story-ai-reviewer` agent are updated and shipped via `/ship-it`; the simulator-suite audit is complete with findings fixed or logged; this story is struck in `execution-plan.md`.

---

## QUAL-002 — Pipeline builds frontend UI stories to their mockup (mockup-driven fidelity)

**As a** maintainer of the TDD pipeline,
**I want** every pipeline stage to treat a frontend story's mockup image as the visual spec — verified, read, composed, built-to, and fidelity-checked —
**so that** an implemented UI component reproduces its approved design instead of MudBlazor defaults.

**Motivation**
`BUG-021` (the login screen shipped from FE-001 diverged sharply from `login__web-1280x800.png` — floating labels instead of labels-above-fields, no brand mark, no gradient, auto-uppercased button) was caused by the pipeline having **no step that reads the mockup**. FE-001 passed evaluation, planning, implementation, and AI review without any stage ever looking at the design image. The fix worked only because a human eyeballed the rendered page against the mockup at the checkpoint. The same gap would recur on every `FE-` UI story. (These changes were drafted during the BUG-021 run and are shipped here as a tracked, reviewed item rather than bundled into the bug fix.)

**Acceptance Criteria:**
- `story-evaluator` gains a **mockup-availability** gate (Step 4a): a frontend UI story that describes a visible surface but references no mockup, or references a missing image, is BLOCKED; behaviour-only frontend stories (e.g. FE-002 JWT expiry) are exempt.
- `story-planner` reads the referenced mockup PNG(s) and `docs/ui-mockups/design-system.css` and emits a **UI Composition Map** (one row per visible element → MudBlazor component / design-system class → bound data → AC) plus layout/states/variants/tokens prose.
- `story-implementor` builds to the Composition Map ("reproduce, don't reinvent"), still TDD-first, and reports which mockup it built to.
- `story-ai-reviewer` adds **Check 10 — Mockup Fidelity**: 10a (AC-bound elements present in markup *and* asserted by a bUnit test) is blocking; 10b (non-AC visual/structural drift) is advisory; pixel-level differences are explicitly not flagged.
- `master/SKILL.md` surfaces the mockup reference when displaying a UI story so the developer reviews it at Checkpoint #1.
- All five edited files pass `./scripts/utils/validate-ai-system.sh` with no blocking findings or warnings.

**Out of scope:** changing the number of pipeline stages or the checkpoint structure; adding image-diffing tooling (fidelity stays human-verified at the checkpoint, AI-assisted by Check 10's structural comparison).

**Done when:** the four agents + `master/SKILL.md` are updated and shipped via `/ship-it`; the validator passes; this story is struck in `execution-plan.md`.

---

## QUAL-003 — Playwright end-to-end test suite (web host)

**As a** developer on the Service Delivery system,
**I want** a Playwright test suite that drives all implemented web-visible persona flows in a real browser against the running backend,
**so that** broken navigation targets, failed JavaScript interop (Google Maps, SignalR), and UI regressions that unit tests cannot catch are detected before merge.

**Motivation**
The unit and bUnit suites verify code structure and component rendering in isolation but cannot exercise the full browser stack. During FE-011 a broken FE-009 navigation target and unverified Google Maps JS interop were flagged only after merge — the gap between "all tests green" and "feature actually works" was exposed. Every frontend story that involves JS interop, SignalR events, or multi-page navigation has the same blind spot. Playwright fills it by running the app as a real user would.

**Acceptance Criteria:**

**Infrastructure:**
- A `tests/ServiceDelivery.Client.E2E/` project is added to the frontend repo targeting the Web host (`ServiceDelivery.Client.Web`); uses `Microsoft.Playwright.NUnit` or `Microsoft.Playwright.MSTest`
- `scripts/local/test-e2e.sh` starts the backend (`start.sh`), waits for `:5180` to be ready, runs `dotnet test` on the E2E project, and tears down on exit; it is idempotent and safe to run more than once
- `scripts/local/test-all.sh` is updated to include the E2E suite in its results table, distinguishing E2E pass/fail from unit pass/fail
- Each test is independent: does not depend on other tests having run first; relies on `start.sh` seed data or creates its own state via the API
- Tests assert on DOM-observable outcomes (`data-testid` attributes, text content, element presence) — not on pixel screenshots
- Google Maps assertions target overlay elements (e.g. `[data-testid="rep-marker"]`, `[data-testid="requester-pin"]`, `[data-testid="route-line"]`), not the tile layer
- SignalR assertions use `page.WaitForSelector` with a timeout of ≥ 10 s to allow real hub events to arrive

**Per-story coverage (all implemented FE stories that are web-visible at the time this story runs):**

| Story | Platform | Required Playwright scenario |
|-------|----------|------------------------------|
| FE-001 — Login | Web + Desktop | Login with valid `dispatcher1` credentials → routed to Dispatcher dashboard; login with invalid credentials → inline error shown; no role-selection screen |
| FE-002 — JWT expiry | Web (behaviour) | Expire the stored JWT (clear/overwrite localStorage) → redirect to login screen; cleared token not reused on next request |
| FE-021 — App shell & nav (Dispatcher web menu) | Web + Desktop | Authenticated Dispatcher → account menu reachable from app bar → Log out → redirected to login screen |

> Additional implemented web-visible stories (e.g. Dispatcher queue FE-004, Requester flow FE-015–FE-019, Dispatcher redirect FE-005, force-release FE-022) are **not yet implemented** at the time of this story — their Playwright tests are added when those stories are run through `/master` (see pipeline update below).

**Pipeline update — all three agents must be updated so every future FE story automatically produces a Playwright test alongside its unit/bUnit tests:**
- `story-planner/AGENT.md` — for any FE story whose platform includes Web or Desktop, include a `tests/ServiceDelivery.Client.E2E/` test file in the Files to Create table and a Playwright scenario per AC in the AC → Test Scenario Mapping (only when `tests/ServiceDelivery.Client.E2E/` already exists in the repo)
- `story-implementor/AGENT.md` — for any FE story whose platform includes Web or Desktop, write the Playwright test file as part of the TDD cycle (after bUnit tests); note that E2E tests are written but not executed in the pipeline (they require a live system — execution is via `test-e2e.sh`)
- `story-ai-reviewer/AGENT.md` — update Check 2 (Test Level): for FE stories whose platform includes Web or Desktop and where `tests/ServiceDelivery.Client.E2E/` exists, a missing Playwright test file is a **blocking** finding

**Out of scope:** CI pipeline integration; visual regression / screenshot diffing; Cypress; mobile/MAUI testing (see QUAL-004).

**Done when:** `tests/ServiceDelivery.Client.E2E/` exists with green Playwright tests for FE-001, FE-002, and FE-021; `test-e2e.sh` runs the suite against a live system; `test-all.sh` includes E2E results; the three pipeline agents are updated; and this story is struck in `execution-plan.md`.

---

## QUAL-004 — Appium end-to-end test suite (mobile host)

**As a** developer on the Service Delivery system,
**I want** an Appium test suite that drives all implemented mobile-visible ServiceRep flows on an iOS simulator,
**so that** MAUI-specific rendering issues, touch interactions, Google Maps interop, and mobile-only navigation paths are caught before merge and cannot hide behind the Playwright web suite.

**Motivation**
The ServiceRep persona is **mobile-only** (ADR-0008) — no web or desktop host. Playwright (QUAL-003) covers the web host but cannot reach the MAUI iOS app. All ServiceRep stories (FE-007 through FE-014, FE-020, FE-021, FE-023) land in the Mobile host; a Google Maps render failure, a tap-target too small to register, or a MAUI lifecycle event mishandled on iOS are invisible to bUnit and Playwright alike. Appium exercises the running app on a booted iOS simulator at the same layer a human tester would.

**Acceptance Criteria:**

**Infrastructure:**
- A `tests/ServiceDelivery.Client.Appium/` project is added to the frontend repo using `Appium.WebDriver` (NUnit or MSTest); targets `XCUITest` on iOS
- `scripts/local/test-appium.sh` boots the target iOS simulator (preferring one already booted, matching `startInPhone.sh`'s `"iPhone 17 Pro"` target), builds and installs the Mobile app, starts the Appium server, runs `dotnet test` on the Appium project, and tears down on exit; must not require the app to already be installed; reuses `scripts/utils/run-on-simulator.sh` for device boot — no duplicated boot logic
- `scripts/local/test-all.sh` is updated to include the Appium suite in its results table, distinguished from unit, bUnit, and Playwright E2E results
- Each test is independent; uses `rep1`–`rep8` seed accounts and relies on `start.sh` seed data
- Assertions target `accessibilityIdentifier` / `name` attributes on key interactive elements (add these to Razor components where missing as part of this story's implementation scope); Google Maps overlay assertions use the same `data-testid` strategy established in QUAL-003
- SignalR assertions use polling with a timeout of ≥ 15 s to allow real hub events to arrive over the simulator network stack
- The suite must pass against a locally running system (`start.sh` up, simulator running) before this story is considered done

**Per-story coverage (all implemented FE stories that are mobile-visible at the time this story runs):**

| Story | Required Appium scenario |
|-------|--------------------------|
| FE-001 — Login | Launch app → login screen shown → enter `rep1` credentials → submit → take-over screen shown (not idle view — login routes to vehicle selection for ServiceRep) |
| FE-002 — JWT expiry | Login → expire token (overwrite stored JWT) → next API call triggers `401` → redirected to login screen |
| FE-007 — Take over vehicle | Login as `rep1` → take-over screen → vehicle dropdown populated with idle vehicles (registration + equipment visible) → select first vehicle → `POST /vehicles/{id}/take-over` called → idle waiting view shown |
| FE-020 — Idle waiting view | (After FE-007) idle view shows "Available" state indicator and claimed vehicle registration; no manual refresh needed |
| FE-008 — Job offer + countdown | (Simulator sends offer to `rep1`) → job offer screen appears automatically → requester name, tier badge, DTC title, distance, ETA visible → countdown decrements in real time → turns red in final 10 seconds → "Accept" and "Decline" buttons visible |
| FE-009 — Accept offer | On job offer screen → tap "Accept" → `POST /job-offers/{id}/accept` called → transitions to active job map screen (FE-011) |
| FE-011 — Active job navigation | Active job map screen → rep marker visible → requester pin visible → route line visible → ETA shown → "I've Arrived" button present and disabled (rep not yet within 15 miles) |
| FE-010 — Decline offer | (New offer) on job offer screen → tap "Decline" → `POST /job-offers/{id}/decline` called → returns to idle waiting view |
| FE-021 — App shell + nav drawer | Authenticated ServiceRep → nav drawer opens on swipe/tap → "Release Vehicle" option visible and distinct → "Log out" option visible and distinct |

> Additional implemented mobile stories (FE-012 Mark arrived, FE-013 Mark complete, FE-014 Release vehicle, FE-023 Heartbeat) are **not yet implemented** at the time of this story — their Appium tests are added when those stories are run through `/master` (see pipeline update below).

**Pipeline update — story-implementor and story-ai-reviewer must be updated so every future FE mobile story automatically produces an Appium test:**
- `story-implementor/AGENT.md` — for any FE story whose platform includes Mobile, write an Appium test file as part of the TDD cycle (after bUnit tests); note that Appium tests are written but not executed in the pipeline (they require a live system and booted simulator — execution is via `test-appium.sh`); only applies when `tests/ServiceDelivery.Client.Appium/` already exists
- `story-ai-reviewer/AGENT.md` — update Check 2 (Test Level): for FE stories whose platform includes Mobile and where `tests/ServiceDelivery.Client.Appium/` exists, a missing Appium test file is a **blocking** finding

> Note: the story-planner update was already applied in QUAL-003 and covers both Playwright and Appium (the planner checks both project existence and story platform before including E2E files in the plan).

**Out of scope:** CI pipeline integration; Android testing; physical device testing; screenshot diffing; Dispatcher or Requester flows (web host — covered by QUAL-003).

**Depends on:** QUAL-003 (`tests/ServiceDelivery.Client.E2E/` project establishes the `data-testid` overlay-element strategy reused here; pipeline agent updates for Playwright are a prerequisite for the Appium pipeline update).

**Done when:** `tests/ServiceDelivery.Client.Appium/` exists with green Appium tests for all 9 stories in the per-story coverage table above; `test-appium.sh` runs the suite on an iOS simulator against a live system; `test-all.sh` includes Appium results; `story-implementor` and `story-ai-reviewer` are updated; and this story is struck in `execution-plan.md`.

---

## QUAL-005 — Run the frontend live-integration net early and continuously (not once at the end)

**As a** maintainer of the TDD pipeline,
**I want** every frontend story whose surface is reachable end-to-end to run its Playwright/Appium scenario against a live system *in the per-story loop* — the moment the screen exists, not deferred to a late catch-up — and a thin per-merge integration smoke to exist from the first frontend story,
**so that** cross-boundary defects surface one at a time in the PR that introduces them, the way the simulator's `smoke.sh` caught them, instead of accumulating silently and erupting in a flood.

**Motivation**
The simulator carried exactly two real integration bugs (`BUG-016`, `BUG-017`) and both were caught on the *first and second* combined backend+sim runs because `scripts/local/smoke.sh` exercised the whole real path continuously from early on — tight loop, one bug at a time, same-day fixes. The frontend had **no equivalent live net until 2026-06-24**, when `test-e2e.sh`/`test-appium.sh` first ran against the app. That single day uncovered a flood: `BUG-023, 024, 025, 026, 027, 028, 029, 030, 031, 032` — ten latent defects, all green in the unit suites the whole time. They didn't cluster because the frontend was buggier; they clustered because that was the first moment anything exercised the real boundaries. QUAL-003/004 built the E2E suites but did not put them *in the loop* — this story closes that gap.

**Acceptance Criteria:**
- A thin **per-merge frontend integration smoke** exists and is documented in central `CLAUDE.md` Commands: boot the system (`start.sh`) and drive the shortest real browser path (open the web host, log in as `dispatcher1`, land on the dashboard) — the frontend analogue of `smoke.sh`. It fails loudly (non-zero exit) on any cross-boundary break (CORS, missing auth header, unstyled host, dead SignalR) and runs fast enough to invoke per change.
- `story-ai-reviewer` Check 2 (Test Level) is strengthened: for a frontend story whose surface is reachable end-to-end on a running system, the story is **not "done"** until its Playwright (web) or Appium (mobile) scenario from QUAL-003/004's coverage tables has been **executed green against a live system** — not merely written. A scenario that was authored but never run is called out, mirroring QUAL-001's "mocked unit tests cannot verify a cross-process contract" rule.
- `master/SKILL.md` surfaces, at the relevant checkpoint, a reminder to run the live E2E scenario for the story before declaring it complete (the pipeline does not boot a live system itself; this is an explicit developer step, like the headless smoke).
- The guidance states plainly that a green unit/bUnit suite is **not** evidence the screen works end-to-end — the live net is, and it belongs at the front of the loop.
- Demonstrated: applied to the BUG-023…032 cluster, this loop would have surfaced each defect in its originating story's run rather than weeks later.

**Out of scope:** standing CI infrastructure (consistent with QUAL-003/004); the pipeline auto-booting a live system; new test scenarios beyond QUAL-003/004's tables (this story changes *when/whether they run*, not their content).

**Depends on:** QUAL-003 and QUAL-004 (the suites this story puts into the loop).

**Done when:** the per-merge frontend smoke exists and is documented; `story-ai-reviewer` + `master/SKILL.md` are updated and pass `./scripts/utils/validate-ai-system.sh`; shipped via `/ship-it`; this story is struck in `execution-plan.md`.

---

## QUAL-006 — Wire-contract integrity across repos: fail-loud deserialization + one source of truth

**As a** developer integrating the frontend and simulator against the backend,
**I want** cross-repo DTOs to derive from a single contract source and deserialization to **fail loudly** on any mismatch, with contract tests that feed a real captured backend payload through each consumer's deserializer,
**so that** a shape or enum drift becomes a red test at the boundary instead of a silent wrong value shipped to production.

**Motivation**
Every wire-drift defect traces to each repo hand-mirroring the other's DTOs, plus System.Text.Json silently falling back to `null`/`0`/`None` on a mismatch instead of throwing:
- `BUG-016` — sim deserialized `GET /vehicles/available` as `string[]`; backend returns objects. Threw only at runtime, invisible to unit tests (which fed the same wrong shape — see QUAL-001).
- `BUG-036` — the RepHub `JobOfferReceived` `Tier` arrived as an enum-name string the frontend payload didn't match, **silently defaulted to `None`**, and produced a white-on-white invisible tier badge. No crash, no failing test — just wrong.
- `BUG-028` / `BUG-030` — frontend REST + SignalR contracts assumed an auth mechanism that was never wired; the mismatch surfaced only as 401s under live E2E.

**Acceptance Criteria:**
- A **single source of truth** for the cross-repo wire contract is established and documented (e.g. the backend's OpenAPI/Swagger document generated and committed/exported, with frontend and simulator client models generated from or checked against it — or a shared contracts package). The chosen mechanism is recorded in an ADR (`docs/adr/`).
- **Fail-loud deserialization** in the frontend and simulator: enum deserialization rejects an unmapped/missing value rather than defaulting to `0`/`None` (a custom converter or strict option), so a `Tier` like BUG-036's throws instead of rendering invisibly. Documented as a convention in the relevant repo CLAUDE.md.
- **Captured-payload contract tests:** for each consumed endpoint/SignalR event, a test deserializes a **real captured backend payload** (not a hand-written fixture mirroring the consumer's assumption) and asserts the consumer obtains the expected typed values. Covers at minimum the BUG-016 (`/vehicles/available`) and BUG-036 (`JobOfferReceived`) shapes as regression cases.
- `/test-quality` references the captured-payload rule so future cross-process contracts are tested this way by default (extends QUAL-001's anti-masking guidance with a positive pattern).
- Demonstrated: the BUG-016 and BUG-036 drifts would each produce a red contract test under this scheme.

**Out of scope:** runtime schema negotiation / versioning of the live contract; replacing System.Text.Json; backend response-shape changes beyond exposing the contract document.

**Done when:** the contract source-of-truth + ADR exist; fail-loud deserialization and captured-payload contract tests are in the frontend and simulator (product-repo code → `/master`); `/test-quality` is updated and shipped via `/ship-it`; this story is struck in `execution-plan.md`.

---

## QUAL-007 — Frontend tests must exercise the real composition root, not components in a vacuum

**As a** maintainer of the TDD pipeline,
**I want** the frontend's critical-path tests to run through the real DI pipeline, HttpClient handler chain, and Blazor navigation lifecycle — not a component rendered in isolation on a convenient route —
**so that** a green suite means the integrated app works, not that an isolated widget renders.

**Motivation**
`BUG-026` says it outright: *"The unit test passed in CI because bUnit renders MainLayout directly on a non-login route, bypassing the login→navigate lifecycle entirely."* The `OnInitializedAsync`-vs-`OnParametersSetAsync` defect (`BUG-025`/`BUG-026`) and the startup auth-flash (`BUG-029`) all passed unit tests because the tests never exercised the real lifecycle/composition — a frontend instance of the masking pattern QUAL-001 caught in the simulator. The handler-pipeline gaps (`BUG-024` session-expiry handler firing on the login 401; `BUG-028` missing bearer handler) are the same shape: the real `DelegatingHandler` chain was never under test.

**Acceptance Criteria:**
- `/test-quality` (`.claude/skills/test-quality/SKILL.md`) gains a **frontend composition-root rule**: for behaviour that depends on the DI pipeline, the HttpClient `DelegatingHandler` chain, or the Blazor render/navigation lifecycle (`OnInitialized` vs `OnParametersSet`, parameter-diffing, router re-use of a layout), the test must exercise that real composition — rendering a component on a non-representative route, or stubbing the handler chain away, is a **masking test** and is called out.
- The rule names the concrete traps from the bug history: testing a layout on a non-`/login` route when the real flow starts at `/login` (BUG-026); asserting a handler in isolation when the defect is its *position/interaction* in the pipeline (BUG-024/028).
- `story-ai-reviewer`'s test-value/test-level checks reference this rule for frontend stories so it is applied every run, not when remembered.
- The **frontend test suite is audited** for existing masking instances of this class (lifecycle-bypassing component tests, handler tests that don't run the real chain); each finding is fixed or logged as a `BUG-`.
- Demonstrated: the strengthened guidance would have flagged the BUG-025/026 and BUG-024/028 tests as masking.

**Out of scope:** adding new test frameworks; the live-system E2E net (QUAL-005 covers that); changing pipeline stages.

**Depends on:** QUAL-001 (the anti-masking rule this extends to the frontend).

**Done when:** `/test-quality` + `story-ai-reviewer` are updated and pass `./scripts/utils/validate-ai-system.sh`; the frontend-suite audit is complete with findings fixed or logged; shipped via `/ship-it` (test-only audit fixes as their own PR); this story is struck in `execution-plan.md`.

---

## QUAL-008 — Treat each client runtime (browser / WebView / native) as its own integration target

**As a** developer shipping the same UI across the Web, Desktop, and Mobile hosts,
**I want** a thin per-runtime integration check for the boundaries that *only* break in one runtime, and a rule that host-bootstrapping changes are propagated to and verified on every host,
**so that** "it works in MAUI native" is never mistaken for "it works in the browser," and a per-host config defect can't ship twice.

**Motivation**
The meta-lesson from the bug history is that browser-WASM, WKWebView, and MAUI-native each have integration semantics the others don't share:
- `BUG-023` — CORS is enforced **only** by a browser; `curl`, `smoke.sh`, and MAUI native all bypass it, so the missing `AddCors()`/`UseCors()` was invisible until the first real-browser E2E run.
- `BUG-031` — MAUI Blazor renders inside a `WKWebView` whose HTML is invisible to the native accessibility tree; the Appium harness had to switch to the WEBVIEW context and `data-testid` selectors.
- `BUG-020` → `BUG-022` — the MudBlazor assets fix landed in the Web host's `index.html`, then the **same defect** shipped again on Desktop + Mobile because each host has its own `index.html`. One defect, three hosts, two PRs.

**Acceptance Criteria:**
- A documented **per-runtime smoke** for the things that break in exactly one runtime: at minimum (a) a browser-context check that the web host can complete a real cross-origin login (would have caught BUG-023's CORS), and (b) a WebView-context check that `data-testid` elements are reachable on the MAUI Mobile host (the BUG-031 strategy). These extend QUAL-005's smoke rather than duplicating it — one entry point, runtime-specific assertions.
- A **host-parity rule** in the frontend CLAUDE.md (and referenced by `story-ai-reviewer`): any change to host-bootstrapping config (`wwwroot/index.html`, the per-host `HttpClient`/DI registration) must be applied to **all three hosts** in the same change, with an explicit per-host verification step — so a fix can't land on one host and silently miss the other two (BUG-020→022).
- The backend CORS policy is covered by a regression check (browser-context or an explicit `Access-Control-Allow-Origin` assertion) so BUG-023 can't recur silently.
- Demonstrated: the CORS (BUG-023), WebView-visibility (BUG-031), and per-host-asset (BUG-020/022) defects each have a check that would have caught them in the originating runtime.

**Out of scope:** Android / physical-device testing; standing CI; screenshot diffing (consistent with QUAL-003/004).

**Depends on:** QUAL-005 (the smoke entry point these runtime-specific checks hang off).

**Done when:** the per-runtime smokes exist and are documented; the host-parity rule is in the frontend CLAUDE.md and referenced by `story-ai-reviewer`; the CORS regression check exists; central edits ship via `/ship-it` and product-repo code via `/master`; this story is struck in `execution-plan.md`.

---

## QUAL-009 — Live end-to-end verification of the go-off-duty / heartbeat-timeout chain (FE-023 + BE-028 + SIM-009)

> **Status: Done.** Verified two ways. (1) **Simulator-inclusive live run** (a short `HeartbeatTimeout` of 20 s): a human took over rep1, heartbeats kept it on duty past the timeout; stopping them swept rep1 Offline, parked the vehicle, and returned it to `GET /vehicles/available`; the simulator did **not** re-assume rep1 for 30 s after (the `YieldedRepRegistry` held) — 6/6 assertions. (2) **Appium suite** (`HeartbeatGoOffDutyTests`, backend-only): the app keeps the rep on duty while running, and closing the app stops heartbeats so the backend times out and the vehicle reappears — 2/2, and the full Appium suite stayed green at 18/0/1 with the test-scoped 25 s timeout. The "simulator does not re-assume" half (no simulator in the Appium harness) is covered by run (1) and SIM-009's own tests.

**As a** maintainer relying on the human-takeover model for the demo,
**I want** the full "rep goes off duty → backend times them out → vehicle parks → simulator does not re-assume → vehicle reappears in the take-over dropdown" loop verified live against a running system,
**so that** the cross-repo chain that was only ever proven in per-repo unit/integration isolation is confirmed to behave end-to-end before the demo depends on it.

**Motivation**
`FE-023` (frontend PR #55, which also fixed `BUG-043`) added the rep heartbeat and clean go-off-duty teardown: the heartbeat is `POST rep/heartbeat` on a 15 s interval while on duty, started in `RepIdleViewModel.StartAsync()` and deliberately spanning idle→offer→job; it stops on logout (`ServiceRepLogoutSideEffect`) and on release (store-cleared observe-the-store self-exit). The backend timeout/park/re-match (`BE-028` `StaleHeartbeatSweeper`) and the simulator "does not re-assume a human-controlled rep" behaviour (`SIM-009`) are all merged. But every layer was verified in isolation — frontend unit + composition-level integration, backend `HeartbeatTimeoutSweepTests`, simulator unit tests. **No test exercises the whole chain against a live system.** FE-023's AC-2 ("backgrounded/closed → backend times out, parks, re-queues") and AC-4 ("simulator does not re-assume; vehicle reappears in the dropdown") are E2E-observable only and currently rest on the assumption that the three independently-correct pieces compose correctly.

**Acceptance Criteria:**
- An Appium scenario (mobile ServiceRep, the `Client.Appium` suite run via `scripts/local/test-appium.sh`) covers **explicit go-off-duty**: a rep takes over a vehicle, then logs out (or releases) — assert the heartbeat stops, the backend marks the rep off-duty / parks the vehicle, the simulator does not re-assume that rep for the run, and the vehicle reappears in the take-over dropdown (FE-007) for an idle rep.
- The **heartbeat-timeout path** (heartbeats simply stop, no explicit logout — the "app backgrounded/closed/lost connectivity" case) is verified at least once against the live backend sweep: with a test-scoped short `HeartbeatTimeout` (env-var override, mirroring the `JobOfferExpiry` test override already used in `test-appium.sh`), stopping heartbeats leads to timeout → park → vehicle reappears. If a true app-background gesture isn't drivable from Appium, simulate it by stopping the client / cutting heartbeats and document that as the stand-in.
- The scenario asserts the **positive** invariant too: while the rep is on duty (including during an active job), heartbeats keep arriving so the backend does **not** time the rep out mid-job (guards the AC-1 lifecycle that the FE-023 regression-guard unit test protects, but live).
- The verification is wired into the existing E2E entry points (`test-appium.sh` / `test-e2e.sh` / `test-all.sh`) so it runs with the rest of the suite, not as a one-off manual check.

**Out of scope:** Android / physical-device testing; standing CI; screenshot diffing (consistent with QUAL-003/004). No production code change is expected unless the live run surfaces a defect — if it does, file a `BUG-` and fix via `/master`.

**Depends on:** QUAL-004 (Appium suite + its overlay/WebView-context strategy), and the merged FE-023 / BE-028 / SIM-009.

**Done when:** the go-off-duty and heartbeat-timeout scenarios exist in the Appium suite and run green against a live system; any defect the live run surfaces is filed and fixed; the frontend test-project code ships via `/master`; this story is struck in `execution-plan.md`.
