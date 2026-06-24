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
**I want** a Playwright test suite that drives the three persona flows in a real browser against the running backend,
**so that** broken navigation targets, failed JavaScript interop (Google Maps, SignalR), and UI regressions that unit tests cannot catch are detected before merge.

**Motivation**
The unit and bUnit suites verify code structure and component rendering in isolation but cannot exercise the full browser stack. During FE-011 a broken FE-009 navigation target and unverified Google Maps JS interop were flagged only after merge — the gap between "all tests green" and "feature actually works" was exposed. Every frontend story that involves JS interop, SignalR events, or multi-page navigation has the same blind spot. Playwright fills it by running the app as a real user would.

**Acceptance Criteria:**
- A `tests/ServiceDelivery.Client.E2E/` project is added to the frontend repo targeting the Web host (`ServiceDelivery.Client.Web`); uses `Microsoft.Playwright.NUnit` or `Microsoft.Playwright.MSTest`
- `scripts/local/test-e2e.sh` starts the backend (`start.sh`), waits for `:5180` to be ready, runs `dotnet test` on the E2E project, and tears down on exit; it is idempotent and safe to run more than once
- `scripts/local/test-all.sh` is updated to include the E2E suite in its results table
- The suite covers the following flows end-to-end in a headless Chromium browser:
  - **Dispatcher:** login → fleet map loads with at least one vehicle marker → request queue shows at least one card (requires the simulator to be running)
  - **Requester:** login → submit a service request (place pin + select DTC + submit) → pending spinner shown → (simulator assigns a rep) → tracking map with moving rep marker
  - **ServiceRep (web):** login → take-over screen shown with idle vehicle list → select a vehicle → idle waiting view → (simulator sends a job offer) → job offer screen with countdown → accept → active job map renders with rep marker, requester pin, and route line → ETA shown and updates → "I've Arrived" button disabled until within 15 miles
- Each test flow is independent: it creates its own seeded state via the API (or relies on `start.sh` seed data) and does not depend on other tests having run first
- Tests assert on DOM-observable outcomes (element presence, text content, `data-testid` attributes) — not on pixel screenshots
- Google Maps is allowed to render in the test browser; assertions target the overlay elements (`[data-testid="rep-marker"]`, `[data-testid="requester-pin"]`, `[data-testid="route-line"]`), not the underlying Google Maps tile layer
- SignalR assertions use `page.WaitForSelector` with a generous timeout (≥ 10 s) to allow real hub events to arrive
- The suite must pass against a locally running system (`start.sh` up, simulator running) before this story is considered done
- `test-all.sh` output distinguishes E2E pass/fail from unit pass/fail so a flaky E2E does not mask a unit failure

**Out of scope:** CI pipeline integration (that is an infrastructure decision); visual regression / screenshot diffing; Cypress (Playwright is the chosen tool per this story); mobile/MAUI testing (see QUAL-004).

**Done when:** `tests/ServiceDelivery.Client.E2E/` exists, `test-e2e.sh` runs the suite green against a live system, `test-all.sh` includes E2E results, and this story is struck in `execution-plan.md`.

---

## QUAL-004 — Appium end-to-end test suite (mobile host)

**As a** developer on the Service Delivery system,
**I want** an Appium test suite that drives the ServiceRep mobile flow on an iOS simulator,
**so that** MAUI-specific rendering issues, touch interactions, and mobile-only navigation paths are caught before merge and cannot hide behind the Playwright web suite.

**Motivation**
The ServiceRep persona is **mobile-only** (ADR-0008) — no web or desktop host. Playwright (QUAL-003) covers the web host but cannot reach the MAUI iOS app. All ServiceRep stories (FE-007 through FE-014, FE-020, FE-021, FE-023) land in the Mobile host; a Google Maps render failure, a tap-target too small to register, or a MAUI lifecycle event mishandled on iOS are invisible to bUnit and Playwright alike. Appium exercises the running app on a booted iOS simulator at the same layer a human tester would.

**Acceptance Criteria:**
- An `tests/ServiceDelivery.Client.Appium/` project is added to the frontend repo using `Appium.WebDriver` (NUnit or MSTest); targets `XCUITest` on iOS
- `scripts/local/test-appium.sh` boots the target iOS simulator (preferring one already booted, matching `startInPhone.sh`'s `"iPhone 17 Pro"` target), builds and installs the Mobile app, starts the Appium server, runs `dotnet test` on the Appium project, and tears down on exit; it must not require the app to already be installed
- `scripts/local/test-all.sh` is updated to include the Appium suite in its results table, distinguished from unit and Playwright E2E results
- The suite covers the following flows end-to-end on the iOS simulator:
  - **Take over a vehicle:** app launches → login screen → enter `rep1` credentials → submit → take-over screen → idle vehicle dropdown populated → select first vehicle → confirm → idle waiting view shown
  - **Job offer:** (simulator sends a job offer to `rep1`) → job offer screen appears with countdown → countdown decrements in real time → "Accept" and "Decline" buttons visible
  - **Accept and navigate:** tap "Accept" → active job map screen loads → rep marker and requester pin visible → ETA shown → "I've Arrived" button present (disabled or enabled based on distance)
  - **Arrive and complete:** (simulator drives rep to within 15 miles) → "I've Arrived" button becomes enabled → tap it → on-site view shown with "Mark Complete" button → tap it → idle waiting view returns
  - **Release vehicle:** open nav drawer → tap "Release Vehicle" → confirmation dialog → confirm → take-over screen shown
- Each test flow is independent and can be run in isolation; tests use `rep1`–`rep8` seed accounts and rely on `start.sh` seed data
- Assertions target `accessibilityIdentifier` / `name` attributes set on key interactive elements in the Razor components (add these where missing as part of this story's implementation scope)
- Google Maps renders in the simulator; assertions target the overlay elements added for QUAL-003 (shared `data-testid` strategy via `accessibilityId` in MAUI BlazorWebView) rather than the tile layer
- SignalR assertions use polling with a generous timeout (≥ 15 s) to allow real hub events to arrive over the simulator network stack
- The suite must pass against a locally running system (`start.sh` up, simulator running) before this story is considered done
- `scripts/utils/run-on-simulator.sh` is the authoritative device-boot helper; `test-appium.sh` must reuse it rather than duplicating boot logic

**Out of scope:** CI pipeline integration; Android testing; physical device testing; screenshot diffing; coverage of the Dispatcher or Requester flows (those are on the web host and covered by QUAL-003).

**Depends on:** QUAL-003 (the `accessibilityId` / overlay-element strategy established there is reused here); `startInPhone.sh` and `run-on-simulator.sh` (the device-boot pattern is already defined).

**Done when:** `tests/ServiceDelivery.Client.Appium/` exists, `test-appium.sh` runs the suite green on an iOS simulator against a live system, `test-all.sh` includes Appium results, and this story is struck in `execution-plan.md`.
