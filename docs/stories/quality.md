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
