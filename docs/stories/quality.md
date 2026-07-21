# Engineering-Quality Stories (`QUAL-`)

> Cross-cutting enhancements to the AI pipeline and engineering practice — not feature work for a single product repo. Tracked in [`execution-plan.md`](execution-plan.md) under **Cross-Cutting — Engineering Quality**. **Routing:** a QUAL story with a `- **Repo / Area:**` bullet directly under its heading is **product-code** work — it runs the full TDD pipeline via `/master QUAL-NNN` (or `/worktree QUAL-NNN`), targeting the repo named first on that line (backend / frontend / simulator), on a `feat/QUAL-NNN-<kebab-title>` branch. A QUAL story **without** that bullet is **central-only** governance work (skill/agent/doc edits) and ships via `/ship-it` (the `/master` pipeline never targets the central repo). Mixed stories split per their own **Done when**: central edits via `/ship-it`, product-repo code via `/master`.

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

---

## QUAL-010 — Resolve the QUAL-007 skills-audit backlog (pipeline-skill drift + the missing `/master` QUAL redirect)

**As a** maintainer of the AI pipeline,
**I want** the drift and gaps surfaced by the `/audit-skills` run on the QUAL-007 changes resolved — chiefly the missing `QUAL-`→`/ship-it` routing rule in `/master`, plus stale test-API references and a staleness blind spot in the audit skills themselves —
**so that** the skill set stays self-consistent and an operator never has to bridge from memory a routing decision the skills should encode.

**Motivation**
Running `/audit-skills` against the QUAL-007 changes scored the set 9.0/10 with no contradictions, but produced a 7-item backlog. The highest-value item isn't in the changed file: `/master`'s Working Repo Resolution table maps `BE-`/`SIM-`/`FE-`/`BUG-` but says nothing about a `QUAL-` (or otherwise unmapped) prefix, so an operator who runs `/master QUAL-NNN` has to know from memory to redirect to `/ship-it`. `ship-it` already documents that it owns `QUAL-NNN`; `/master` is the half that stays silent. The rest are low-effort hygiene: a stale bUnit v1 API reference in `tdd-cycle`, two consistency nits in the new QUAL-007 rule, a missing back-reference, and the audit skills having no first-class signal for a stale API/version reference (exactly the class that let `tdd-cycle`'s `TestContext` drift unnoticed).

**Acceptance Criteria:**
- **`/master` documents the unmapped-prefix redirect** (`.claude/skills/master/SKILL.md`): a `QUAL-` prefix — or any story prefix with no working-repo mapping — is out-of-pipeline governance work; `/master` redirects it to `/ship-it` and does **not** attempt a TDD pipeline run. Stated in the Working Repo Resolution section so the routing is encoded, not remembered.
- **`tdd-cycle` uses the current bUnit API** (`.claude/skills/tdd-cycle/SKILL.md`): the frontend component-test example uses bUnit v2 (`BunitContext` / `Render<T>()`), not the stale v1 `new TestContext()`, matching the frontend `CLAUDE.md` and the actual `Client.Tests` project.
- **`test-quality` composition-root rule notes the hosting precondition** (`.claude/skills/test-quality/SKILL.md`): the faithful "render at `/login` then navigate" pattern only exercises the transition if the layout is hosted so navigation drives `OnParametersSetAsync` — call this out so a faithful-looking test does not silently skip the lifecycle it targets.
- **`test-quality` references the precise reviewer check**: the enforcement pointer reads "Checks 2 and 3b" (the masking sub-check in `story-ai-reviewer`), not "Checks 2 and 3".
- **`test-quality` trims the redundant restatement**: the "render from `/login` then navigate" guidance is stated once in the rule body plus the quick-ref checklist + table — drop the duplicate bullet.
- **`audit-skills` and `audit-agents` gain a staleness signal** (`.claude/skills/audit-skills/SKILL.md`, `.claude/skills/audit-agents/SKILL.md`): a Cross-File Alignment red flag for an API/type/version name that no longer matches the current codebase or package versions.
- **`solid-principles` cross-references `clean-architecture`** (`.claude/skills/solid-principles/SKILL.md`) for layer placement (the reverse link already exists in `clean-architecture`).
- The full set still passes `./scripts/utils/validate-ai-system.sh`.

**Out of scope:** re-auditing the full skill set; changing pipeline stages; any product-repo code.

**Depends on:** QUAL-007 (the change these findings were raised against).

**Done when:** the listed `master` / `tdd-cycle` / `test-quality` / `audit-skills` / `audit-agents` / `solid-principles` edits land and pass `validate-ai-system.sh`; shipped via `/ship-it`; this story is struck in `execution-plan.md`.

---

## QUAL-011 — Consolidate shared design-system tokens into a global stylesheet (kill the recurring scoped-CSS gap)

**As a** frontend developer building new persona screens,
**I want** the shared design-system tokens (`sd-card`, `sd-badge` + tier modifiers, `sd-btn` + variants, `sd-banner`, `sd-field`, `sd-select`, `sd-muted`) defined once in a global stylesheet loaded by every host, instead of duplicated inside each page's Blazor scoped CSS,
**so that** a new page that reuses a token gets it styled automatically, rather than rendering structurally-present-but-visually-broken until someone notices.

**Motivation**
These tokens are currently defined only as Blazor *scoped* CSS on specific pages (`JobOffer.razor.css`, `ActiveJob.razor.css`, `RepIdle.razor.css`), so a `b-<hash>` attribute scope-locks them to those components. Every new page that reuses a token re-discovers that it doesn't apply: it shipped as the FE-011/FE-012 unstyled-map regression, then recurred as **FE-015 finding #1** (unstyled button/select/banner) and **FE-016 finding #1** (unstyled tier badge/card) — three times, each caught only by the `story-ai-reviewer` Check 10c rendered-fidelity analysis, never by the green bUnit suite (which asserts class-string presence, not applied style). Each was patched per-page (a new `.razor.css` redefining the tokens + a `*StyleTests` guard). That works but perpetuates duplication and guarantees the next requester/dispatcher page hits the same wall. Promote the genuinely-shared tokens into one global sheet and delete the per-page copies.

**Acceptance Criteria:**
- A single global stylesheet (e.g. `design-system.css` under `Client.UI/wwwroot`) defines the shared tokens: `sd-card` (+ `sd-card__body`), `sd-badge` + `sd-badge__icon` + `sd-badge--gold` / `--silver` / `--bronze`, `sd-btn` + `--primary` / `--outline` / `--block` / `--lg` + `:disabled`, `sd-banner` + `sd-banner__icon`, `sd-field` + `sd-field__label`, `sd-select`, `sd-muted`.
- The stylesheet is loaded by **all three** host pages (`Web`, `Desktop`, `Mobile` `wwwroot/index.html`) — host parity, with a per-host verification step (the same rule that governs the MudBlazor assets per BUG-020→022).
- The duplicated per-page scoped definitions of those shared tokens (`JobOffer` / `ActiveJob` / `RepIdle` / `SubmitRequest` / `RequesterPending`) are removed in favour of the global sheet; genuinely page-specific rules stay scoped.
- The shared design tokens (`--sd-primary`, `--sd-tier-*`, `--sd-elev-*`, etc.) resolve consistently — no visual change to any already-shipped page.
- **No regression on the already-merged, live-verified pages** (`JobOffer`, `ActiveJob`, `RepIdle`, `SubmitRequest`, `RequesterPending`): re-verify each live (the per-runtime smokes + the relevant Playwright/Appium scenarios) — this is a refactor whose whole risk is silent visual regression.
- The per-page `*StyleTests` guards (`SubmitRequestStyleTests`, the FE-016 equivalent) are retargeted to assert the tokens resolve from the global sheet, or replaced by a single global-coverage guard — kept as a genuine net, not deleted.

**Out of scope:** changing any token *value* or visual design (pure consolidation, not a restyle); non-shared page-specific rules; introducing a second component/CSS framework.

**Depends on:** the pages that consume the tokens (FE-008/011/012/015/016 — all merged). Best taken before the remaining requester/dispatcher screens (FE-003/004/005/006/017/018/019) are built, so they consume the global sheet rather than each re-hitting the gap.

**Done when:** the global stylesheet exists, is loaded by all three hosts, the per-page duplicates are removed, every affected page is re-verified live with no visual regression, and the story is struck in `execution-plan.md`. **Ships via `/master`** (frontend production CSS + host-bootstrapping code with tests + live re-verification — the product-code QUAL case, like QUAL-003/004), **not** `/ship-it`.

---

## QUAL-012 — Route HubConnection internal logging through the host logger in every SignalR hub client (kill silent transport failures)

- **Repo / Area:** Frontend — SignalR hub client services (`SignalRRepHubService`, `SignalRRequesterHubService`; mirrors FE-003's `SignalRVehiclePositionHubService` fix)

**As a** frontend developer debugging a live SignalR issue,
**I want** all three hub client services (`SignalRRepHubService`, `SignalRRequesterHubService`, `SignalRVehiclePositionHubService`) to route the `HubConnection`'s internal transport/dispatch logging through the host's `ILoggerFactory`,
**so that** a client-side connect, handshake, binding, or dispatch failure is visible in the host log instead of vanishing into a `NullLogger`.

**Motivation**
FE-003's live-gate forensics burned two full diagnostic loops on a phantom "hub events don't arrive under XCTest" defect, because the vehicle-hub `HubConnection` was built with **no logger** — every client-side SignalR diagnostic went nowhere, forcing server-side log correlation, raw probe clients, and screenshot archaeology to establish basic facts. FE-003 fixed `SignalRVehiclePositionHubService` (injected `ILoggerFactory`, routed via `ConfigureLogging`, spy-factory guard test) and gave Desktop an `OsLogLoggerProvider` (NSLog → unified log, since the XCTest launcher swallows stdout). The Rep and Requester hub services still build their connections with no logger — the next live SignalR incident on those hubs starts blind again.

**Acceptance Criteria:**
- `SignalRRepHubService` and `SignalRRequesterHubService` inject `ILoggerFactory` and route the `HubConnection`'s internal logging through it, mirroring `SignalRVehiclePositionHubService.BuildConnection` (`ConfigureLogging` → `SetMinimumLevel(Debug)` + host factory), in both the production and test-seam constructors.
- Each service gains a spy-factory guard test (the `GivenAnInjectedLoggerFactory_WhenTheServiceIsConstructed_ThenTheHubConnectionLoggingIsRoutedToTheFactory` pattern) — asserting the factory is genuinely consumed, not merely accepted.
- No behavioural change to connect/back-off semantics (BUG-038 retry loops untouched); existing service tests updated for the new constructor parameter only.
- `ILoggerFactory` resolves from default DI in all three hosts — no host registration changes.

**Out of scope:** new logging sinks (Desktop's `OsLogLoggerProvider` already exists; Web/Mobile keep their defaults); changing log levels or message content; the backend.

**Depends on:** FE-003 (merged — the pattern and the Desktop sink exist).

**Done when:** both services route hub logging through the host factory with spy-factory guards, the offline suite is green, and the story is struck in `execution-plan.md`. **Ships via `/master`** (frontend production code + tests — the product-code QUAL case, like QUAL-011), **not** `/ship-it`.

---

## QUAL-013 — Schematize REST responses in the committed OpenAPI contract (the sync-check currently guards no response shape)

- **Repo / Area:** Backend — Api endpoint response metadata (`TypedResults` / `.Produces<T>()`) + regenerated `contracts/openapi.json`

**As a** frontend or simulator developer binding a backend REST response,
**I want** every endpoint's success response to carry a schema in the committed `contracts/openapi.json`,
**so that** the QUAL-006 contract sync-check actually guards the shapes consumers bind — not just request bodies.

**Motivation**
Verified during FE-003/BE-032: **0 of 24 responses across all 23 paths** in `contracts/openapi.json` carry a schema — every response is an untyped `200 OK`; only request bodies are schematized. The committed contract is documented as the REST wire-contract source of truth (ADR-0011, QUAL-006), and `OpenApiContractTests` faithfully guards it — but the guarded document is silent about the half of the contract consumers actually deserialize. Concretely: BE-032 added `activeRequestTitle` to the `GET /dispatcher/fleet` response and the committed contract needed **no change** — a response-shape drift the sync-check can never catch. The endpoints lack response-type metadata (`Produces<T>`/`TypedResults`), so the generator has nothing to emit.

**Acceptance Criteria:**
- Every REST endpoint declares its success response type via the appropriate metadata (`TypedResults` / `.Produces<T>()` / `[ProducesResponseType]` per the Api layer's conventions), including `GET /dispatcher/fleet` (`DispatcherFleetEntryDto[]`).
- `./scripts/regen-openapi.sh` then emits response schemas for all 2xx responses (0/24 → 24/24 with content), and the regenerated `contracts/openapi.json` is committed.
- `OpenApiContractTests` still passes and now fails on response-shape drift — verified by demonstrating (in a test or documented dry run) that adding/removing a response DTO field produces a contract diff, i.e. replaying the BE-032 class of change is no longer invisible.
- Error responses (4xx) may be typed opportunistically but are not required — success shapes are the deliverable.
- No behavioural change to any endpoint; metadata and contract only.

**Out of scope:** SignalR hub event payloads (explicitly outside OpenAPI per the backend CLAUDE.md — guarded by consumer-side captured-payload tests); generating client code from the contract; versioning.

**Depends on:** QUAL-006 (merged — the committed contract + sync-check exist).

**Done when:** all success responses are schematized in the committed contract, the sync-check demonstrably guards response shapes, the backend suite is green, and the story is struck in `execution-plan.md`. **Ships via `/master`** (backend production metadata + contract + tests — the product-code QUAL case), **not** `/ship-it`.

---

> **QUAL-014 – QUAL-028** were filed on **2026-07-21** from a read-only design investigation of the frontend **shared code** (the `Core` and `UI` projects). They are ordered by importance: **QUAL-014** is the highest-leverage item (a genuine reliability defect), descending to convention/decision items at the end. QUAL-014/015 are defect-flavoured and could alternatively be reclassified as `BUG-`; they are filed here as requested. All are **Frontend product-code** stories and ship via `/master`.

---

## QUAL-014 — Self-healing SignalR reconnect in the frontend hub clients (kill silent, permanent connection death)

- **Repo / Area:** Frontend — SignalR hub client services (`SignalRRepHubService`, `SignalRRequesterHubService`, `SignalRVehiclePositionHubService`)

**As a** ServiceRep, Requester, or Dispatcher whose client holds a live SignalR connection,
**I want** a dropped hub connection to keep trying to reconnect (and to recover its subscriptions) instead of dying permanently after ~42 s of default retries,
**so that** a transient network blip doesn't leave me silently deaf to job offers, tracking updates, or fleet positions for the rest of my session.

**Motivation**
All three hub services build their `HubConnection` with a bare `.WithAutomaticReconnect()`, whose default policy retries only 4 times (`{0,2,10,30}` s) and then transitions to `Closed` **permanently**. None of the three subscribe to `HubConnection.Closed`, `.Reconnecting`, or `.Reconnected`, so once the built-in retries are exhausted the connection is dead forever with no restart path and no surfaced state. The BUG-038 back-off loop only covers the **initial cold connect**, not a post-establishment drop. This is the exact "connection dies silently and stays dead → deaf-but-available client" mechanism being investigated as **BUG-053** on the simulator — the frontend RepHub carries the identical latent defect.

**Acceptance Criteria:**
- Each hub connection is configured with a custom/unbounded `IRetryPolicy` (or a `Closed`-handler that re-invokes the existing back-off connect loop), so a drop after establishment triggers continued reconnection rather than permanent death.
- On `Reconnected`/reconnect, any per-connection server-side subscription state the hub relies on is re-established (verify each hub's `On*` handlers survive a reconnect, or are re-registered).
- Connection-state transitions are observable to the consuming ViewModel/UI (at minimum logged via the QUAL-012 host logger; optionally surfaced as a "reconnecting" state) so a degraded connection is never invisible.
- A test proves that a simulated `Closed` after a successful connect drives a reconnect attempt (spy/fake connection seam), for each of the three services.
- No regression to the BUG-038 cold-connect back-off semantics.

**Out of scope:** the simulator's BUG-053 fix (tracked separately); changing the backend hub contract; adding a UI reconnecting banner beyond what an AC minimally requires.

**Depends on:** best landed **after** QUAL-017 (the shared `ResilientHubConnection` collaborator), so the reconnect policy lives in one place; if QUAL-017 slips, apply per-service.

**Done when:** all three hub clients self-heal after a post-establishment drop with tests proving it, the offline suite is green, the behaviour is live-verified (drop + recover), and the story is struck in `execution-plan.md`. **Ships via `/master`**.

---

## QUAL-015 — Fix the JobOffer RepHub callback leak (discarded subscription `IDisposable`)

- **Repo / Area:** Frontend — `Features/ServiceRep/Pages/JobOffer.razor` (+ `IRepHubService.OnJobOfferExpired` registration contract)

**As a** ServiceRep who navigates to the job-offer screen more than once in a session,
**I want** each visit's SignalR `JobOfferExpired` handler to be unregistered when the component is disposed,
**so that** stale handlers capturing dead component instances don't stack up and fire against disposed state.

**Motivation**
`JobOffer.razor` registers `RepHubService.OnJobOfferExpired(OnJobOfferExpiredAsync)`, which calls `_connection.On(...)`. `_connection.On` returns an `IDisposable` that is **discarded**, and the component's `Dispose` never unregisters it. Because `RepHubService` is **session-scoped**, every visit to `/rep/offer` stacks another handler that captures a now-disposed component's `this`. The `if (_viewModel is null) return` guard doesn't protect against this because `_viewModel` is never nulled on dispose. This is a genuine handler/memory leak, not a style issue.

**Acceptance Criteria:**
- `IRepHubService.OnJobOfferExpired` returns the subscription `IDisposable` (or exposes a paired unsubscribe), and `JobOffer` captures it and disposes it in `Dispose`.
- A test proves that disposing the component unregisters the handler (re-emitting `JobOfferExpired` after dispose does not invoke the old callback), and that navigating to the offer screen N times leaves exactly one live handler.
- The fix pattern is checked against the other hub `On*` registrations (see QUAL-014/017) so no other discarded-`IDisposable` subscriptions remain.

**Out of scope:** the broader observing-component base class (QUAL-018) — this is the targeted defect fix; QUAL-018 would later subsume the pattern.

**Done when:** the subscription is deterministically disposed with a proving test, the offline suite is green, and the story is struck in `execution-plan.md`. **Ships via `/master`**.

---

## QUAL-016 — Enforce ADR-0011 throw-on-unmapped tier across ALL wire types (one `ServiceTierWire.Parse`)

- **Repo / Area:** Frontend — wire DTO → domain mapping boundaries (`RedirectPayload`, `ActiveJobContext`, `DispatcherFleetEntryDto`; consolidate with `JobOfferReceivedWirePayload.ToJobOfferPayload`)

**As a** frontend developer binding a backend tier value to a badge,
**I want** every wire payload carrying a service tier to parse-or-throw at its mapping boundary (per ADR-0011), through one shared helper,
**so that** a drifted or unmapped tier fails loudly at the boundary instead of silently producing an invisible/garbage badge downstream.

**Motivation**
ADR-0011 (frontend CLAUDE.md, "Wire Contract") mandates that a wire enum arriving unmapped/missing must **throw**, never silently default. Today only `JobOfferReceivedWirePayload.ToJobOfferPayload()` honours it. `RedirectPayload.RequesterTier`, `ActiveJobContext.Tier`, and `DispatcherFleetEntryDto.ActiveRequestTier` sidestep the rule by keeping tier as a **raw string that is never parsed to `ServiceTier`** — so it can never throw. Those strings flow straight into `sd-badge--{tier}` (e.g. `ActiveJob.razor`), reproducing exactly the invisible-badge class of failure (**BUG-036**) that ADR-0011 exists to prevent — and the two payloads with no boundary mapper are the most exposed.

**Acceptance Criteria:**
- A single `ServiceTierWire.Parse(string)` (parses-or-throws `InvalidOperationException` naming the drifted value) is the one place tier strings become `ServiceTier`; `JobOfferReceivedWirePayload` is refactored to use it (dedupe, no behaviour change).
- `RedirectPayload`, `ActiveJobContext`, and `DispatcherFleetEntryDto` gain real wire-DTO → domain mappers that call `ServiceTierWire.Parse`, instead of binding the raw string onto the consumed model.
- Each is backed by a captured-payload deserialization test (per the repo's wire-contract test rule) plus a test proving an unmapped tier throws at the boundary.
- No consumer downstream still receives an unparsed tier string.

**Out of scope:** `RepStateColour`'s unknown→offline-grey fallback (a defensible presentation fallback, not a data-binding default); backend changes.

**Done when:** all tier-bearing wire types parse-or-throw through the shared helper with tests, the offline suite is green, and the story is struck in `execution-plan.md`. **Ships via `/master`**.

---

## QUAL-017 — Extract a `ResilientHubConnection` collaborator to kill the ~80% hub-client duplication and unify the connect-idempotency guard (composition, not a base class)

- **Repo / Area:** Frontend — SignalR hub client services (`SignalRRepHubService`, `SignalRRequesterHubService`, `SignalRVehiclePositionHubService`) + a new connection abstraction in `Core/Interfaces`

**As a** maintainer of the frontend hub clients,
**I want** the shared connection lifecycle (build, access-token provider, back-off connect, state guard, stop, dispose) extracted into an injected collaborator that each hub service *has-a*, not a base class each hub service *is-a*,
**so that** a fix or guard applied once holds for all three hubs — without the LSP/fragile-base coupling of inheritance and without the test-seam constructor hack.

**Design note — composition over inheritance.** There is no genuine "`SignalRRepHubService` **is-a** hub-service-base"; what the three share is a *collaborator* (connection resilience), so it is modelled as one. This is the strongest composition case in the batch: it keeps each hub service to a single responsibility (its domain events), puts the QUAL-014 reconnect policy and the QUAL-015 subscription-disposal in exactly one place, and — critically — **removes the current "second internal constructor purely to swap the connection for tests"**, which is the tell that inheritance is fighting testability. Inject the abstraction and pass a fake in tests instead. (Rejected alternative: an `abstract SignalRHubServiceBase` with template-method hooks — tighter coupling, an LSP contract each subclass must honour, and it bundles resilience + domain concerns into one type.)

**Motivation**
The three `SignalR*Service.cs` files are ~190–220 lines each with only ~25 lines unique (hub path constant, event names, `On*` handlers). Everything else — the `InitialConnectBackoff` array, both constructors (public + internal test seam), `BuildConnection`, `ProvideAccessTokenAsync`, `IsConnected`, `StartAsync`, `RetryConnectAsync`, `StopAsync`, `DisposeAsync` — is verbatim. The duplication is already **actively harmful**: `SignalRRequesterHubService.StartAsync` has an FE-019 `Disconnected`-state idempotency guard (gating on `Func<HubConnectionState>`) that **RepHub and VehiclePosition lack** (they gate on `Func<bool> _isConnected`). So calling `StartAsync` on an already-live RepHub throws "cannot be started if not Disconnected", swallowed into a pointless back-off. One shared collaborator collapses this and forces the guard — and the QUAL-014 reconnect fix — to apply uniformly.

**Acceptance Criteria:**
- A `IResilientHubConnection` abstraction (in `Core/Interfaces`) and its concrete implementation own the connection field, back-off array, `BuildConnection`, access-token provider, `State`/`IsConnected` guard, `StartAsync`/`RetryConnectAsync`, `StopAsync`, and `DisposeAsync`. Its `On<T>(method, handler)` **returns the subscription `IDisposable`** (the seam QUAL-015 needs), and it exposes connection-state transitions (`Closed`/`Reconnected`) for QUAL-014.
- Each of the three hub services depends on `IResilientHubConnection` by constructor injection (created per-hub via a factory/named registration supplying that hub's path); the service body is reduced to registering its `On<T>` handlers and exposing its domain methods — no lifecycle code.
- The `StartAsync` idempotency guard (skip when already connected/connecting) lives once in the collaborator and is therefore identical across all three hubs — the RepHub/VehiclePosition drift is eliminated.
- The internal test-seam constructors are **removed**: tests inject a fake/spy `IResilientHubConnection` instead. Existing per-service tests are updated to the injected fake (no behavioural change).
- Hub logging (QUAL-012, already merged) is carried into the collaborator so all three keep host-logger routing.

**Out of scope:** the reconnect behaviour change itself (QUAL-014 — it lands *in* this collaborator); changing the backend hub contract.

**Done when:** the three services compose one `IResilientHubConnection`, the guard is unified, the test-seam constructors are gone, tests green, live-verified across all three hubs, and the story is struck in `execution-plan.md`. **Ships via `/master`**.

---

## QUAL-018 — `INotifyStateChanged` interface (ViewModel side) + an `ObservingComponentBase` (kill the hand-rolled StateChanged/subscribe/dispose triad)

- **Repo / Area:** Frontend — `Core` (`INotifyStateChanged` interface + optional shared notifier) + `UI` component base (subscribe/marshal/unsubscribe)

**As a** maintainer of the frontend UI,
**I want** one shared *contract* for a ViewModel to announce state changes and one shared way for a component to subscribe, marshal to the render thread, and unsubscribe,
**so that** the most-copied code in the repo lives in one place and the "forgot to unsubscribe" leak class is structurally impossible.

**Design note — interface on the VM side, base class only where the framework mandates it.** The two halves get different treatment on purpose:
- **ViewModel side → an interface, not a base class.** Define `INotifyStateChanged { event Action StateChanged; }` so components depend on an *abstraction* (ISP/DIP), not a concrete `ObservableViewModel` parent. VMs raise the event via a tiny reusable notifier field (composition) or a two-line hand-roll — either is fine, and neither forces an inheritance chain onto types that already have other reasons to exist. A base class here would spend the VM's single base slot on a one-event concern.
- **Component side → a base class is acceptable.** Blazor *is* a class hierarchy — every component already inherits `ComponentBase`, and Microsoft ships `OwningComponentBase<T>` for exactly this "manage a per-component lifecycle concern" job. An `ObservingComponentBase<TViewModel>` goes *with* the framework grain; there is no DI-injected mixin for Razor lifecycle, so composing this instead would be less idiomatic, not more SOLID.

**Motivation**
There is no shared observable/state-notification pattern. Five ViewModels each declare their own identical `public event Action? StateChanged;` (`ActiveJobViewModel`, `DispatcherFleetViewModel`, `JobOfferViewModel`, `RequesterTrackingViewModel`, plus `ShellViewModel` as `TitleChanged`); only one bothers with a `RaiseStateChanged()` helper, and the other ViewModels expose no event at all — so there is no rule for **when** a VM needs one. On the UI side every page re-implements the identical triad: subscribe in `OnInitialized`, `OnViewModelStateChanged => InvokeAsync(StateHasChanged)`, unsubscribe in `Dispose` (`DispatcherHome`, `FleetMap.razor.cs`, `ActiveJob`, `RequesterTracking`, …). This is the direct breeding ground for the QUAL-015 leak.

**Acceptance Criteria:**
- An `INotifyStateChanged` interface (in `Core`) declares the `StateChanged` event; the five hand-rolled events are migrated to implement it, raising via a small shared notifier or a minimal hand-roll (no `ObservableViewModel` base class). Core stays free of any UI-framework dependency.
- An `ObservingComponentBase<TViewModel>` in UI (deriving from `ComponentBase`/`OwningComponentBase`) owns subscribe-on-init, `InvokeAsync(StateHasChanged)` marshaling, and unsubscribe-on-dispose against `INotifyStateChanged`; pages that follow the triad derive from it and drop their boilerplate.
- A test proves the base unsubscribes on dispose (no leak) and marshals hub-thread notifications through `InvokeAsync`.
- A short convention note is added (frontend CLAUDE.md or the ViewModels folder) stating when a VM should implement `INotifyStateChanged` (out-of-band/async/hub/timer updates) vs relying on Blazor's post-handler re-render.

**Out of scope:** rewriting ViewModels that legitimately don't need change notification; the `ShellViewModel` `TitleChanged` naming (can be folded in opportunistically).

**Done when:** the interface + component base exist with the triad migrated, tests prove no-leak marshaling, the offline suite is green, and the story is struck in `execution-plan.md`. **Ships via `/master`**.

---

## QUAL-019 — Unify HTTP service response→result handling behind a shared request helper (and fix the empty-2xx-body NRE unwraps)

- **Repo / Area:** Frontend — `Features/*/Services/Http*Service.cs` (all ~12 HTTP service adapters)

**As a** maintainer of the frontend HTTP services,
**I want** one shared, thin helper for turning an HTTP response into a typed `Result`/`Conflict`/collection,
**so that** the same status-mapping isn't copy-pasted three different ways and empty-body responses fail cleanly instead of throwing `NullReferenceException`.

**Motivation**
The ~12 `Http*Service` classes are individually clean thin adapters, but there is no shared convention for response→result mapping — **three** competing styles coexist: `EnsureSuccessStatusCode()` throw-based (4 services), typed `Result` with an explicit `409 → Conflict` (3 services, the 409 branch copy-pasted), and bare `bool`/`Error` (2 services). Two force-unwraps (`HttpAuthService`, `HttpServiceRequestService`) will `NullReferenceException` on an empty 2xx body instead of returning a clean error. The `GET + deserialize + ?? []` shape is triplicated (`HttpDtcService`, `HttpVehicleService`, `HttpDispatcherFleetService`).

**Acceptance Criteria:**
- A small internal helper/extension (e.g. `PostForResultAsync` mapping status→typed result, and a `GetListAsync` for the GET+`?? []` shape) is introduced; the ~12 services adopt it. **Deliberately light** — an extension/helper, not a heavy base class, given how thin these adapters are.
- The `409 → Conflict` mapping is defined once and reused (no per-file copies).
- Empty/short 2xx bodies no longer throw `NullReferenceException`; they return the appropriate typed error/result, proven by a test for each of the two affected services.
- One consistent JSON options convention (the redundant explicit `JsonOptions` in `HttpDispatcherFleetService` reconciled with the `System.Net.Http.Json` Web default).
- No change to the ViewModel-facing `Result` contracts.

**Out of scope:** the `DelegatingHandler` pipeline (already well-designed); SignalR services (QUAL-017).

**Done when:** the services share one response-mapping helper, the empty-body NRE risks are fixed with tests, the offline suite is green, and the story is struck in `execution-plan.md`. **Ships via `/master`**.

---

## QUAL-020 — Single source of truth for rep-state contract strings (`RepStates`)

- **Repo / Area:** Frontend — `Core/Models` (new `RepStates` constants) + consumers (`ActiveJobViewModel`, `RequesterTrackingViewModel`)

**As a** frontend developer comparing an incoming rep state to the backend contract,
**I want** the rep-state strings (`"EnRoute"`, `"Within15Miles"`, `"OnSite"`, …) defined in exactly one place,
**so that** a backend rename can't silently break one screen while the other keeps working.

**Motivation**
The rep-state contract strings are declared independently in `ActiveJobViewModel` and `RequesterTrackingViewModel`, with comments in both warning that they must match the backend — two sources of truth for one wire contract. A drift on the backend would need to be fixed in two places, and missing one is a silent, screen-specific break.

**Acceptance Criteria:**
- A single `RepStates` constants type (or enum with an explicit wire-mapping) in `Core/Models` holds the state strings; both ViewModels reference it, and the duplicate literals + "must match" comments are removed.
- A test asserts the constants match the values the backend/wire tests expect (or references the captured-payload fixtures) so drift is caught by a failing test.

**Out of scope:** changing the backend's state vocabulary; folding in `RepStateColour` (tracked separately if pursued).

**Done when:** the strings live in one place with both consumers migrated and a drift-guard test, the offline suite is green, and the story is struck in `execution-plan.md`. **Ships via `/master`**.

---

## QUAL-021 — Add a `ShellChromeScope` *component* to remove per-page shell-title push/restore duplication (composition by containment)

- **Repo / Area:** Frontend — `Shared/Components` (new `ShellChromeScope` component) + pages that set shell chrome (`SubmitRequest`, `RequesterPending`, `RequesterTracking`, `RequesterComplete`, `ActiveJob`, …)

**As a** maintainer of the persona shell,
**I want** a reusable *component* a page drops in to set the app-bar title/subtitle on entry and restore it on exit,
**so that** every page stops hand-writing the same set-in-init / restore-in-dispose (and the BUG-044 re-apply-on-first-render workaround) boilerplate.

**Design note — composition by containment, not a page base class.** This is deliberately a *component* the page contains (e.g. `<ShellChromeScope Title="…" Subtitle="…" />`), whose own lifecycle sets chrome on init/first-render and restores it on dispose — not a `ShellChromePageBase` that pages inherit. Containment keeps a page free to compose *several* such scoped concerns (chrome, observing, …) without spending its single base slot, and each concern's lifecycle is self-contained. (This one was already component-shaped in the original filing; the note pins it so it doesn't drift into a base class, and detaches it from any shared base with QUAL-018.)

**Motivation**
Every page manually pushes `Shell.SetTitle`/`SetSubtitle` in init and restores `null` in `Dispose`. Worse, the BUG-044 workaround — re-applying chrome in `OnAfterRenderAsync(firstRender)` — is duplicated verbatim across `RequesterTracking` and `RequesterComplete`. This cross-cutting concern is copy-pasted per page and is easy to get subtly wrong (see also QUAL-022's off-thread mutation note).

**Acceptance Criteria:**
- A `ShellChromeScope` component sets the shell title/subtitle on init **and** on first render (subsuming the BUG-044 re-apply) and restores the previous chrome on dispose; pages declare their chrome by placing the component (parameters) once and drop the manual push/restore.
- Shell mutations triggered from hub-thread callbacks are marshaled through `InvokeAsync` (fixes the latent off-render-thread `StateHasChanged` in `RequesterTracking`/`ActiveJob` where `Shell.SetTitle` runs outside `InvokeAsync`).
- A test proves chrome is set on entry and restored on dispose, and that the first-render re-apply still occurs.

**Out of scope:** redesigning `PersonaShell` itself; sharing a base class with QUAL-018 (kept as an independent contained component, per the design note).

**Done when:** pages use the shared component, the BUG-044 duplication is gone, the off-thread mutation is marshaled, tests pass, the offline suite is green, and the story is struck in `execution-plan.md`. **Ships via `/master`**.

---

## QUAL-022 — Extract a shared `TripMap` component for the duplicated ActiveJob/RequesterTracking map-overlay engine

- **Repo / Area:** Frontend — `Features/Maps/Components` (new `TripMap`) consumed by `ActiveJob` and `RequesterTracking`

**As a** maintainer of the trip views,
**I want** the rep-marker + requester-pin + route-polyline overlay logic in one component,
**so that** the ServiceRep and Requester trip screens stay in lock-step instead of drifting between two ~60-line copies.

**Motivation**
`ActiveJob` and `RequesterTracking` share a near-identical map-overlay engine: `UpdateMapOverlaysAsync`, `RoutePoints()`, the marker-id constants, `RequesterPinColour = "#2B2F3A"`, `OnSiteZoom = 15`, and the status/state → `sd-chip--*` switch are duplicated across both. A change to marker behaviour or the on-site collapse must currently be made twice.

**Acceptance Criteria:**
- A `TripMap` component encapsulates the rep marker, requester pin, route polyline, the shared constants, and the on-site collapse/zoom behaviour, wrapping `GoogleMap`; `ActiveJob` and `RequesterTracking` consume it and drop their duplicated overlay code.
- The status/state → chip mapping shared by both is defined once.
- Existing bUnit/interop coverage for both screens passes; a test asserts the shared component renders the expected overlay elements (`data-testid`s) so the QUAL-004 Appium overlay assertions still hold.

**Out of scope:** the `GoogleMap` interop wrapper itself (already well-encapsulated); pixel-level restyling.

**Done when:** both trip screens render through the shared `TripMap`, tests pass, the overlays are live-verified on both screens, and the story is struck in `execution-plan.md`. **Ships via `/master`**.

---

## QUAL-023 — De-duplicate the four `InMemory*Store` classes via a contained `Cell<T>` value-holder (composition) — or leave them

- **Repo / Area:** Frontend — `Core/Services` (`InMemoryClaimedVehicleStore`, `InMemoryJobOfferStore`, `InMemoryRepAssignedStore`, `InMemoryServiceCompletedStore`)

**As a** maintainer of the Core in-memory hand-off stores,
**I want** the shared "hold one nullable `T`; Set; Clear" mechanism factored out (if we touch it at all),
**so that** the store logic isn't maintained in four places — *without* coupling the stores into an inheritance chain.

**Design note — composition (or leave-it), not a base class.** Two honest caveats:
1. **The DRY win is marginal.** These are ~10-line classes and the duplicated body is trivial and stable. This story is a legitimate **leave-it** candidate — flag it, and only proceed if the batch is already touching `Core/Services`.
2. **If we do it, compose, don't inherit.** Rather than an `abstract InMemoryHandoffStore<T>` the stores subclass, give each store a private `Cell<T>` value-holder it *contains* and delegate its domain-named members to it:
   ```csharp
   internal sealed class Cell<T> { public T? Value { get; private set; } public void Set(T v)=>Value=v; public void Clear()=>Value=default; }

   public sealed class InMemoryJobOfferStore : IJobOfferStore
   {
       private readonly Cell<JobOffer> _cell = new();
       public JobOffer? CurrentOffer => _cell.Value;
       public void SetOffer(JobOffer o) => _cell.Set(o);
       public void Clear() => _cell.Clear();
   }
   ```
   The shared mechanism lives in `Cell<T>` (trivially unit-testable in isolation); each store keeps its domain names as thin delegation with no base coupling. The cost is a few lines of delegation per store — the honest composition trade — which is negligible here.

**Motivation**
The four `InMemory*Store` implementations are the same "hold one nullable value, Set, Clear" body three times over (the fourth adds a `DtcTitle` string). The bodies are effectively identical — but small and stable, hence the leave-it caveat above.

**Acceptance Criteria:**
- **If pursued:** a reusable `Cell<T>` value-holder is introduced; each of the four stores *contains* one and delegates its domain-named members to it — no shared base class.
- The **four interfaces stay separate** — they carry distinct payloads and the domain-specific names are worth keeping (do **not** merge them; that would violate the repo's ISP-per-capability convention).
- Existing store tests pass unchanged; `Cell<T>` gets its own focused test.
- Member-naming inconsistency across the store interfaces (`CurrentOffer`/`SetOffer` vs generic `CurrentPayload`/`SetPayload`) is reconciled to one convention as part of the same change.
- **If not pursued:** close as a documented leave-it (the duplication is trivial/stable), with the naming reconciliation optionally still applied.

**Out of scope:** adding locking/thread-safety (Blazor's per-circuit sync context makes it unnecessary for the POC — note it, don't build it); any base class.

**Done when:** the stores either compose a `Cell<T>` (names reconciled, tests pass, suite green) or are closed as a documented leave-it, and the story is struck in `execution-plan.md`. **Ships via `/master`** if code changes.

---

## QUAL-024 — Collapse the three identical `{Success, Conflict}` result enums into one `OperationOutcome`

- **Repo / Area:** Frontend — `Core/Models` (`AcceptOfferResult`, `DeclineOfferResult`, `TakeOverResult`)

**As a** maintainer of the Core result types,
**I want** the three byte-for-byte `{Success, Conflict}` enums unified into one,
**so that** the same two-member outcome isn't defined (and documented) three times.

**Motivation**
`AcceptOfferResult`, `DeclineOfferResult`, and `TakeOverResult` are identical `{ Success, Conflict }` two-member enums with near-copy XML docs. `ReleaseVehicleResult` (`{NothingToRelease, Released, Blocked}`) and `SubmitServiceRequestResult` (a proper closed discriminated union carrying data) are **legitimately distinct** and stay as-is.

**Acceptance Criteria:**
- The three identical enums are replaced by one `enum OperationOutcome { Success, Conflict }`; the three services and their ViewModels/tests are updated to the shared type.
- `ReleaseVehicleResult` and `SubmitServiceRequestResult` are left unchanged.
- The (small) loss of type-distinctness is a conscious trade — noted in the story — because the semantics are genuinely identical (200 vs 409).

**Out of scope:** turning the outcome into a richer `Result<T>` framework — the closed DU (`SubmitServiceRequestResult`) already models the data-carrying case and is the pattern to reach for if a future result needs a payload.

**Done when:** the three enums are unified with consumers migrated, tests pass, the offline suite is green, and the story is struck in `execution-plan.md`. **Ships via `/master`**.

---

## QUAL-025 — Restore DI for the JobOffer view model via an `IJobOfferViewModelFactory`

- **Repo / Area:** Frontend — `Features/ServiceRep/Pages/JobOffer.razor` (+ new factory abstraction in `Core/Interfaces`)

**As a** maintainer of the frontend pages,
**I want** the job-offer ViewModel created through an injected factory instead of `new`-ed in the page,
**so that** `JobOffer` follows the same Dependency-Inversion pattern as every other page.

**Motivation**
`JobOffer` is the only page that constructs its ViewModel with `new`, manually injecting four services into the constructor — every other page `@inject`s its ViewModel. The reason is that the offer is runtime data (`JobOfferPayload`), so a plain DI-resolved singleton/scoped VM doesn't fit; but a factory that takes the runtime payload and resolves the services restores DI consistency.

**Acceptance Criteria:**
- An `IJobOfferViewModelFactory` (in `Core/Interfaces`) creates a `JobOfferViewModel` from the runtime `JobOfferPayload`, resolving the four services via DI; `JobOffer` injects the factory instead of `new`-ing the VM.
- The factory is registered in every host per the register-in-every-host convention.
- A test proves the factory produces a fully-wired ViewModel; existing `JobOffer` tests pass.

**Out of scope:** changing `JobOfferViewModel`'s behaviour; the observing-component base (QUAL-018).

**Done when:** `JobOffer` resolves its VM via the injected factory, tests pass, the offline suite is green, and the story is struck in `execution-plan.md`. **Ships via `/master`**.

---

## QUAL-026 — Consolidate over-segregated ISP interfaces where a single consumer uses both halves

- **Repo / Area:** Frontend — `Core/Interfaces` (`IArriveService`+`ICompleteJobService`; `IJobOfferService`+`IDeclineOfferService`) + their consumers/impls

**As a** maintainer of the Core service contracts,
**I want** interfaces that are only ever consumed together to be merged where the split buys no decoupling,
**so that** ISP serves real consumer isolation instead of adding files, registrations, and mocks for no benefit.

**Motivation**
`IArriveService.ArriveAsync` and `ICompleteJobService.CompleteAsync` are both injected into the **same** `ActiveJobViewModel`; `IJobOfferService.AcceptAsync` and `IDeclineOfferService.DeclineAsync` are both injected into the **same** `JobOfferViewModel`. ISP protects consumers from methods they don't use — but here one consumer uses both halves, so the split buys zero decoupling while adding two extra interfaces, two registrations, and two mocks per test. This is the clearest case where the repo's ISP preference costs more than it returns. **This is a judgement call** and deliberately ranked low — it runs counter to the repo's strong ISP-per-capability convention, so it needs a conscious sign-off.

**Acceptance Criteria:**
- Evaluate (and, if agreed, implement) merging into `IRepJobActionService { ArriveAsync; CompleteAsync }` and `IJobOfferResponseService { AcceptAsync; DeclineAsync }`, updating impls, registrations, ViewModels, and mocks.
- If the team decides the split stays (ISP convention wins), the story is closed as **won't-do** with the rationale recorded — either outcome is acceptable, the point is a deliberate decision rather than drift.
- Any other single-consumer-uses-both interface pairs surfaced during the change are listed.

**Out of scope:** the host-swapped or Core-inward-dependency interfaces (geolocation, token store, HTTP/hub services) — those splits are justified and stay.

**Done when:** the pairs are either merged (with consumers/tests migrated and the suite green) or explicitly kept with rationale, and the story is struck in `execution-plan.md`. **Ships via `/master`** if code changes; closes as a documented decision otherwise.

---

## QUAL-027 — Establish one component code-organization convention (`.razor.cs` vs inline `@code`)

- **Repo / Area:** Frontend — `UI` components + frontend CLAUDE.md (convention) 

**As a** frontend developer,
**I want** one documented rule for when component logic lives in a `.razor.cs` code-behind vs an inline `@code` block,
**so that** components are organized consistently instead of per-author preference.

**Motivation**
No rule is followed: `RequesterPending`/`Complete`/`Submit`/`Home` use `.razor.cs`; `RequesterTracking`/`ActiveJob`/`JobOffer`/`RepIdle`/`DispatcherHome`/`TakeOver` use inline `@code`. `RequesterPending` even splits **both ways** — lifecycle in `.razor.cs`, tier-display logic in the `.razor` `@code`. The inconsistency makes it harder to know where a component's logic lives.

**Acceptance Criteria:**
- A convention is decided and documented in the frontend CLAUDE.md (recommended: `.razor.cs` for anything with lifecycle or non-trivial logic; inline `@code` only for tiny display glue).
- Existing components are migrated to the convention (at minimum, split-both-ways cases like `RequesterPending` are made consistent).
- The `story-implementor`/`story-ai-reviewer` convention references are updated if they need to enforce it (central edit via `/ship-it` if so — mixed-story split noted below).

**Out of scope:** rewriting component behaviour; a lint/analyzer to enforce it automatically.

**Done when:** the convention is documented and existing components conform, the offline suite is green, and the story is struck in `execution-plan.md`. **Frontend code + CLAUDE.md ship via `/master`**; any central pipeline-doc edit ships via `/ship-it` (mixed story — split per this Done-when).

---

## QUAL-028 — Decide and document MudBlazor-first vs raw `sd-*` CSS for the map/trip screens

- **Repo / Area:** Frontend — map/trip screens (`ActiveJob`, `RequesterTracking`, `JobOffer`, `RequesterComplete`) + frontend CLAUDE.md (UI Framework rule)

**As a** maintainer of the frontend UI conventions,
**I want** an explicit, documented decision about where the "MudBlazor-first" rule yields to hand-authored `sd-*` CSS,
**so that** the current mixed styling is a conscious architecture choice rather than silent drift from the CLAUDE.md rule.

**Motivation**
MudBlazor usage is mixed but seemingly deliberate: `RepIdle`/`TakeOver`/`RequesterPending`/`PersonaMenu` use Mud primitives, while the map/trip views (`ActiveJob`, `RequesterTracking`, `JobOffer`, `RequesterComplete`) use raw `sd-*` CSS for pixel-matched mockup chrome. This is consistent per-screen but **contradicts the CLAUDE.md "MudBlazor-first" rule** — it should be a recorded decision, not an implicit exception.

**Acceptance Criteria:**
- The frontend CLAUDE.md "UI Framework" section is amended to state exactly when raw `sd-*` design-system CSS is acceptable in preference to a Mud primitive (e.g. "map/trip overlay chrome that must pixel-match an approved mockup"), or the screens are migrated toward Mud primitives where a component parameter covers the need.
- The decision is consistent with the QUAL-011 shared-token stylesheet already loaded by all three hosts.
- No visual regression on the affected screens (live-verify against the mockups).

**Out of scope:** introducing a second component library (forbidden); re-theming.

**Done when:** the rule is documented (and any agreed migration applied) with the affected screens live-verified, and the story is struck in `execution-plan.md`. **Frontend code + CLAUDE.md ship via `/master`**; a pure CLAUDE.md-only outcome ships via `/ship-it`.
