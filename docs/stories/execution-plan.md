# Execution Plan

> This plan sequences all user stories across the three repos in dependency order. Each phase produces independently testable, runnable increments. Stories within a phase can be worked in parallel within their repo.

---

## Phase 1 — Foundation
**Goal:** Backend is runnable with auth, seeded data, and wired SignalR hubs. Nothing works end-to-end yet, but the skeleton is ready.

| Story | Repo | Description |
|-------|------|-------------|
| ~~[BE-024](backend.md)~~ | ~~Backend~~ | ~~Seed all POC data: 10 DTCs, 8 vehicles, 20 users, 1 simulator account~~ |
| ~~[BE-001](backend.md)~~ | ~~Backend~~ | ~~`POST /auth/login` — JWT with role, tier, dealerId~~ |
| ~~[BE-002](backend.md)~~ | ~~Backend~~ | ~~`GET /users/me`~~ |
| ~~[BE-025](backend.md)~~ | ~~Backend~~ | ~~Wire all 4 SignalR hubs (VehiclePositionHub, DispatchHub, RepHub, RequesterHub)~~ |

**Exit criteria:** `POST /auth/login` returns a valid JWT; all 4 hub endpoints are reachable.

---

## Phase 2 — Vehicle Management
**Goal:** Reps can claim and release vehicles. The simulator can authenticate and stream position updates. Dispatcher can see the fleet.

| Story | Repo | Description |
|-------|------|-------------|
| ~~[BE-003](backend.md)~~ | ~~Backend~~ | ~~`GET /vehicles` (Dispatcher)~~ |
| ~~[BE-004](backend.md)~~ | ~~Backend~~ | ~~`GET /vehicles/available` (ServiceRep)~~ |
| ~~[BE-005](backend.md)~~ | ~~Backend~~ | ~~`POST /vehicles/{id}/claim`~~ |
| ~~[BE-006](backend.md)~~ | ~~Backend~~ | ~~`POST /vehicles/{id}/release`~~ |
| ~~[BE-007](backend.md)~~ | ~~Backend~~ | ~~`POST /vehicles/{id}/force-release` (Dispatcher)~~ |
| ~~[BE-008](backend.md)~~ | ~~Backend~~ | ~~`POST /vehicles/{id}/position` + 15-mile detection + SignalR fan-out~~ |
| ~~[SIM-001](simulator.md)~~ | ~~Simulator~~ | ~~Authenticate per-rep (`rep1…rep8`) + `Simulator`-role position account~~ — merged single-account; per-rep retrofit tracked in **SIM-011** |
| ~~[SIM-002](simulator.md)~~ | ~~Simulator~~ | ~~Connect to `RepHub` per automated rep~~ — merged single-connection; per-rep retrofit tracked in **SIM-011** |
| ~~[SIM-003](simulator.md)~~ | ~~Simulator~~ | ~~Advance vehicles along Iowa route loops~~ |
| ~~[SIM-004](simulator.md)~~ | ~~Simulator~~ | ~~POST position updates every 3 seconds~~ |

**Exit criteria:** The simulator runs and position updates appear in the backend; `GET /vehicles` reflects current positions.

---

## Phase 3 — Service Requests & DTCs
**Goal:** Requesters can submit requests; the matching algorithm produces job offers.

| Story | Repo | Description |
|-------|------|-------------|
| ~~[BE-009](backend.md)~~ | ~~Backend~~ | ~~`GET /dtcs`~~ |
| ~~[BE-010](backend.md)~~ | ~~Backend~~ | ~~`POST /service-requests` + trigger matching~~ |
| ~~[BE-011](backend.md)~~ | ~~Backend~~ | ~~`GET /service-requests` (Dispatcher)~~ |
| ~~[BE-012](backend.md)~~ | ~~Backend~~ | ~~`GET /service-requests/my-active` (ServiceRep)~~ |
| ~~[BE-013](backend.md)~~ | ~~Backend~~ | ~~`GET /service-requests/{id}`~~ |
| ~~[**BUG-001**](bug.md)~~ | ~~Backend~~ | ~~**Bug** — `BE-025`'s `RepHub` event list omits the force-release notification that `BE-007` promises. Add a session-revoked event (e.g. `VehicleForceReleased`) to `BE-025` and name it in `BE-007`'s AC.~~ |
| ~~[**BUG-002**](bug.md)~~ | ~~Frontend~~ | ~~**Bug** — No frontend story for the Dispatcher force-release action that `BE-007` backs (`FE-006` references it but defines no UI). Add new story **FE-022** (force-release: button → confirm dialog → `POST /vehicles/{id}/force-release`) and cross-reference it from `FE-006`.~~ |
| ~~[**BUG-003**](bug.md)~~ | ~~Central~~ | ~~**Bug** — FE-011 cross-references FE-016 for `RedirectReceived`; should be FE-018.~~ |
| ~~[**BUG-004**](bug.md)~~ | ~~Central~~ | ~~**Bug** — Phase 3 exit criterion requires `GET /job-offers/pending` (BE-015, Phase 4); reword to BE-014's `JobOfferReceived`.~~ |
| ~~[**BUG-005**](bug.md)~~ | ~~Central~~ | ~~**Bug** — `data-flow.puml` emits "Almost There (Within15Miles)" on the OnSite step; should be "Arrived".~~ |
| ~~[**BUG-006**](bug.md)~~ | ~~Central~~ | ~~**Bug** — README Skills table omits the `master` skill.~~ |
| ~~[**BUG-007**](bug.md)~~ | ~~Central~~ | ~~**Bug** — `test-all.sh`, `test-simulator.sh`, `mark-story-complete.sh` exist but are undocumented.~~ |
| ~~[**BUG-008**](bug.md)~~ | ~~Central~~ | ~~**Bug** — CLAUDE.md says ship-it "lands all pending changes"; the skill scopes to out-of-pipeline only.~~ |
| ~~[**BUG-009**](bug.md)~~ | ~~Central~~ | ~~**Bug** — story-implementor hardcodes `dotnet test` instead of the repo-appropriate command (breaks FE/SIM).~~ |
| ~~[**BUG-010**](bug.md)~~ | ~~Central~~ | ~~**Bug** — Dispatcher force-release endpoint absent from UI brief & system-overview endpoint lists.~~ |
| ~~[**BUG-011**](bug.md)~~ | ~~Central~~ | ~~**Bug** — Commit/PR attribution conventions disagree across story-pr and ship-it.~~ |
| ~~[**BUG-012**](bug.md)~~ | ~~Central~~ | ~~**Bug** — `BUG-`/`fix/` branch handling missing from story-planner / story-implementor / story-pr.~~ |
| ~~[**BUG-013**](bug.md)~~ | ~~Central~~ | ~~**Bug** — CLAUDE.md "Persona" wording implies a section header the agents don't use.~~ |
| ~~[**BUG-014**](bug.md)~~ | ~~Central~~ | ~~**Bug** — CLAUDE.md `docs/stories/` description omits `parallel-tracks.md` and `README.md`.~~ |
| ~~[**BUG-015**](bug.md)~~ | ~~Central~~ | ~~**Bug** — Stale `.gitkeep` files in populated `scripts/local` and `scripts/utils`.~~ |
| ~~[BE-014](backend.md)~~ | ~~Backend~~ | ~~Matching algorithm: filter → sort → tiebreaker → issue job offer~~ |

**Exit criteria:** Submitting a request via API results in a `JobOfferReceived` event on the backend's RepHub.

---

## Phase 4 — Job Offer Lifecycle
**Goal:** Reps can accept/decline offers; the simulator gains per-rep identities so it can act as each automated rep. Offer expiry runs automatically. (Auto-response itself moves to Phase 7 — it depends on the human-controlled signal.)

| Story | Repo | Description |
|-------|------|-------------|
| ~~[BE-015](backend.md)~~ | ~~Backend~~ | ~~`GET /job-offers/pending`~~ |
| ~~[BE-016](backend.md)~~ | ~~Backend~~ | ~~`POST /job-offers/{id}/accept` + state transitions + SignalR events~~ |
| ~~[BE-017](backend.md)~~ | ~~Backend~~ | ~~`POST /job-offers/{id}/decline` + re-run matching~~ |
| ~~[BE-018](backend.md)~~ | ~~Backend~~ | ~~Background job: expire offers after 60 seconds + re-run matching~~ |
| ~~[SIM-011](simulator.md)~~ | ~~Simulator~~ | ~~Retrofit per-rep identity model — per-rep auth + per-rep `RepHub` connections + rep-aware accept/decline (delivers SIM-001/002's ADR-0009 ACs; prerequisite for SIM-005)~~ |

**Exit criteria:** Pending offers are visible via `GET /job-offers/pending`; the full accept/decline/expire cycle works end-to-end via API; the simulator can authenticate and open a `RepHub` connection as each automated rep and call accept/decline as that rep (SIM-011). Auto-response (SIM-005) lands in Phase 7, once the human-controlled signal exists.

---

## Phase 5 — Rep State Transitions, Resilience & Human Takeover
**Goal:** Reps can arrive and complete jobs. Offline detection re-queues jobs automatically. A human can take over an idle rep+vehicle from a device, and the backend tracks human-controlled presence.

| Story | Repo | Description |
|-------|------|-------------|
| ~~[BE-019](backend.md)~~ | ~~Backend~~ | ~~`POST /rep/arrive`~~ |
| ~~[BE-020](backend.md)~~ | ~~Backend~~ | ~~`POST /rep/complete` + re-run matching for Pending requests~~ |
| ~~[BE-023](backend.md)~~ | ~~Backend~~ | ~~`OnDisconnectedAsync` — offline detection, re-queue (re-match), DispatchHub alert; human reps not re-assumed~~ |
| ~~[BE-026](backend.md)~~ | ~~Backend~~ | ~~`POST /vehicles/{id}/take-over` — idle rep assumes an idle vehicle, supersedes simulator, marks human-controlled~~ |
| ~~[BE-027](backend.md)~~ | ~~Backend~~ | ~~`GET /simulator/fleet-state` — Simulator-role read of per-vehicle rep state + active-request location + human-controlled flag~~ |
| ~~[BE-028](backend.md)~~ | ~~Backend~~ | ~~`POST /rep/heartbeat` + go-off-duty; human-controlled timeout → park + re-match; sim does not re-assume~~ |
| ~~[BE-029](backend.md)~~ | ~~Backend~~ | ~~Background reconciler — re-match `Pending` requests with no active offer (backstop for dropped re-matches; reuses the BE-018 hosted-service pattern)~~ |

**Exit criteria:** A full job lifecycle (submit → match → offer → accept → arrive → complete) works via API calls; re-matching after completion creates a new offer if other requests are pending; a human can take over an idle vehicle (superseding the simulator) and is parked on logout/timeout without the simulator re-assuming them.

---

## Phase 6 — Dispatcher Operations
**Goal:** Dispatchers can see the full fleet and redirect reps.

| Story | Repo | Description |
|-------|------|-------------|
| ~~[BE-021](backend.md)~~ | ~~Backend~~ | ~~`GET /dispatcher/fleet`~~ |
| ~~[BE-022](backend.md)~~ | ~~Backend~~ | ~~`POST /dispatcher/redirect` — eligibility rules, cooldown, displaced-request flow~~ |

**Exit criteria:** Redirect works end-to-end via API: displaced request re-queues, new rep receives `RedirectReceived`, Gold requester receives `RepAssigned`.

---

## Phase 7 — Simulator Job Navigation, Reconciliation & Takeover
**Goal:** The simulator drives every vehicle's position from backend job-state, reconciles each tick, auto-responds to offers for the reps it still operates, yields any rep a human takes over, and gives automated reps a realistic on-site dwell.

| Story | Repo | Description |
|-------|------|-------------|
| ~~[SIM-008](simulator.md)~~ | ~~Simulator~~ | ~~Reconcile against `GET /simulator/fleet-state` each tick; drive all vehicles; operate only non-human reps~~ |
| ~~[SIM-005](simulator.md)~~ | ~~Simulator~~ | ~~Auto-accept (~85%) / auto-decline (~15%) job offers with a 1–5s delay — only for reps the simulator still operates (skips human-controlled, per SIM-008). Moved here from Phase 4: depends on SIM-011 (per-rep identity) and SIM-008 (human-controlled signal)~~ |
| ~~[SIM-006](simulator.md)~~ | ~~Simulator~~ | ~~Navigate toward requester on accept (automated **or** human rep); hold for a human's Arrived/Complete~~ |
| ~~[SIM-007](simulator.md)~~ | ~~Simulator~~ | ~~Return to nearest loop waypoint on job completion~~ |
| ~~[SIM-009](simulator.md)~~ | ~~Simulator~~ | ~~Yield a rep on human takeover; never re-assume it for the run (sticky)~~ |
| ~~[SIM-010](simulator.md)~~ | ~~Simulator~~ | ~~Automated on-site work dwell (randomized 120–240s)~~ |
| ~~[**BUG-016**](bug.md)~~ | ~~Simulator~~ | ~~**Bug** — simulator crashes on startup: `GET /vehicles/available` returns objects `{ vehicleId, registration, equipment }` but `GetAvailableVehicleIdsAsync` deserializes `string[]`. Found by the first headless backend+simulator run. Fix: parse the objects and project `vehicleId`.~~ |
| ~~[**BUG-017**](bug.md)~~ | ~~Simulator~~ | ~~**Bug** — simulator never posts positions: `VehicleWorker`/`IowaRoutes` keyed by registration (`V-001`), but `FleetPositionDriver` looks them up by the backend's fleet-state GUID → every vehicle skipped, `lastPosition` stays null, matching can't select reps. Found by the second headless run. Fix needs a GUID→route mapping decision (sim-only dynamic assignment recommended).~~ |
| ~~[SIM-012](simulator.md)~~ | ~~Simulator~~ | ~~Local config & secrets via gitignored `appsettings.Local.json` (loaded by `DOTNET_ENVIRONMENT=Local`); committed `appsettings.json` holds no creds; `.example` template; pattern for future Development/Test/Production~~ |
| ~~[**BUG-018**](bug.md)~~ | ~~Central~~ | ~~**Bug (reframed)** — the reported `Within15Miles` "navigation stall" was a misdiagnosis: live re-diagnosis confirmed the automated cycle completes end-to-end with monotonic convergence. Real issue: `scripts/local/smoke.sh` falsely timed out (stale idle-vehicle placement → long legs + ~6 min window). Fixed by hardening the smoke harness (short-leg submit + widened window + slow-vs-stall diagnosis); shipped via `/ship-it`. See bug.md.~~ |
| ~~[**BUG-019**](bug.md)~~ | ~~Simulator~~ | ~~**Bug — CANNOT REPRODUCE (environmental).** Suspected per-rep RepHub / heartbeat instability (cold-start all-offers-expire; OnSite mid-job re-queue) seen once on a stale instance. Three clean cold-start cycles all ran healthy → local environment/resource exhaustion, not a defect. Closed. See bug.md.~~ |

**Depends on:** Phase 4 (SIM-011 — per-rep identities), Phase 5 (BE-026/027/028 — takeover, fleet-state read, presence). SIM-005's AC-1 specifically needs BE-027's `human-controlled` flag surfaced via SIM-008.
**Exit criteria:** During a simulated job, vehicle position updates show movement toward the requester's coordinates, then resume loop traversal after the job ends; when a human takes over a rep, the simulator stops deciding for it but keeps driving its position, and never re-assumes it once the human leaves.

---

## Phase 8 — Frontend Foundation
**Goal:** Users can log in and are routed to the correct view. JWT lifecycle is handled.

| Story | Repo | Description |
|-------|------|-------------|
| ~~[FE-001](frontend.md)~~ | ~~Frontend~~ | ~~Login screen → JWT → route by role~~ |
| ~~[**BUG-020**](bug.md)~~ | ~~Frontend~~ | ~~**Bug** — Web client renders unstyled: `AddMudServices()` + providers are wired, but `index.html` never loads `_content/MudBlazor/MudBlazor.min.css`/`.js`, so every `Mud*` component is bare HTML. Found launching the web app after FE-001. Fix: add the MudBlazor CSS/font/JS to the Web host's `index.html`.~~ |
| ~~[**BUG-021**](bug.md)~~ | ~~Frontend~~ | ~~**Bug** — Login screen doesn't match the approved mockup (`login__web-1280x800.png`): labels float inside fields instead of above, no brand mark, no gradient background, button auto-uppercases. FE-001 was built to MudBlazor defaults. Surfaced once BUG-020 made styling load. Fix via `/master`: pixel-match the mockup.~~ |
| ~~[**BUG-022**](bug.md)~~ | ~~Frontend~~ | ~~**Bug** — Desktop & Mobile hosts render unstyled: BUG-020 added MudBlazor's CSS/JS only to the Web host's `index.html`, but each MAUI host ships its own `index.html` and neither loaded the assets. Found tracing the mobile startup→render chain. Fix: add the MudBlazor CSS/font/JS to both `Desktop/wwwroot/index.html` and `Mobile/wwwroot/index.html`.~~ |
| ~~[**BUG-023**](bug.md)~~ | ~~Backend~~ | ~~**Bug** — Web host cannot reach the backend: CORS not configured in `Program.cs`. The Blazor WASM web host (`:5023`) is cross-origin from the backend (`:5180`); the browser blocks every API and SignalR call with `net::ERR_FAILED`. Found running `test-e2e.sh` for the first time. Fix: `AddCors()` + `UseCors()` in `Program.cs` allowing `localhost:5023`.~~ |
| ~~[**BUG-024**](bug.md)~~ | ~~Frontend~~ | ~~**Bug** — `SessionExpiryHttpHandler` fires on the login endpoint's 401, throwing an unhandled exception instead of showing the inline "Invalid email or password." error. Found via `test-e2e.sh`. Fix: skip the handler for `/auth/login` requests.~~ |
| ~~[**BUG-025**](bug.md)~~ | ~~Frontend~~ | ~~**Bug** — Dispatcher `PersonaMenu` never renders after login: `MainLayout.OnInitializedAsync()` sets `Shell.Menu` but Blazor skips re-rendering `PersonaShell` because the `Shell` reference is unchanged. Found via `test-e2e.sh`. Fix: add a `_shellVersion` counter parameter to force the child re-render.~~ |
| ~~[**BUG-026**](bug.md)~~ | ~~Frontend~~ | ~~**Bug** — BUG-025 fix used `OnInitializedAsync`, which only fires once (on `/login`); `Shell.Load` is never called when Blazor navigates to the authenticated route. Found running `test-e2e.sh` after BUG-025 merged. Fix: switch to `OnParametersSetAsync` guarded by `Shell.Menu is null`.~~ |
| ~~[FE-002](frontend.md)~~ | ~~Frontend~~ | ~~JWT expiry detection → redirect to login~~ |
| ~~[FE-021](frontend.md)~~ | ~~Frontend~~ | ~~App shell, navigation menu & logout (per-persona)~~ |

**Depends on:** Phase 1 (BE-001, BE-002)
**Exit criteria:** Each of the three persona accounts can log in and land on their respective view shell.

---

## Phase 9 — Frontend ServiceRep Flow
**Goal:** A ServiceRep can claim a vehicle, receive and respond to job offers, navigate to the requester, and mark the job complete.

| Story | Repo | Description |
|-------|------|-------------|
| ~~[FE-007](frontend.md)~~ | ~~Frontend~~ | ~~Take over an idle vehicle (dropdown) — supersedes the simulator~~ |
| ~~[FE-020](frontend.md)~~ | ~~Frontend~~ | ~~Idle / waiting-for-offers view~~ |
| ~~[FE-008](frontend.md)~~ | ~~Frontend~~ | ~~Job offer screen with 60-second countdown~~ |
| ~~[FE-009](frontend.md)~~ | ~~Frontend~~ | ~~Accept offer → navigate to active job view~~ |
| ~~[FE-010](frontend.md)~~ | ~~Frontend~~ | ~~Decline offer → return to idle~~ |
| ~~[FE-011](frontend.md)~~ | ~~Frontend~~ | ~~Active job map with live (simulator-driven) position and ETA~~ |
| ~~[FE-012](frontend.md)~~ | ~~Frontend~~ | ~~"I've Arrived" button → on-site view~~ |
| ~~[FE-013](frontend.md)~~ | ~~Frontend~~ | ~~"Mark Complete" → return to idle~~ |
| ~~[FE-014](frontend.md)~~ | ~~Frontend~~ | ~~Release vehicle from menu (goes off-duty; vehicle parks)~~ |
| ~~[FE-023](frontend.md)~~ | ~~Frontend~~ | ~~Heartbeat while on duty + clean go-off-duty~~ |
| ~~[**BUG-027**](bug.md)~~ | ~~Backend~~ | ~~**Bug** — `GET /vehicles/available` returned only *unclaimed* vehicles, but the simulator claims all 8, so the rep take-over list was always empty. Found via `test-appium.sh`. Fix: return idle vehicles (unclaimed or claimed-by-idle-rep); add `RepStateRecord.IsOnActiveJob()`.~~ |
| ~~[**BUG-028**](bug.md)~~ | ~~Frontend~~ | ~~**Bug** — Authenticated REST calls sent no `Authorization` header (only `HttpAuthService` attached the JWT), so every data call 401'd after login. Found via `test-appium.sh`. Fix: `AuthTokenHttpHandler` DelegatingHandler in all 3 hosts.~~ |
| ~~[**BUG-029**](bug.md)~~ | ~~Frontend~~ | ~~**Bug** — Brief "unhandled error" flash at startup (root route loads the profile before redirect-to-login; SecureStorage first-launch race). Found via `test-appium.sh`. Fix: resilient shell-load + token-store guards.~~ |
| ~~[**BUG-030**](bug.md)~~ | ~~Frontend~~ | ~~**Bug** — RepHub SignalR connection sent no access token, so the `[Authorize]` hub never joined the rep group and offers/redirects never arrived. Found auditing all calls for auth. Fix: `AccessTokenProvider` from `ITokenStore`.~~ |
| ~~[**BUG-031**](bug.md)~~ | ~~Central/Frontend~~ | ~~**Bug** — Appium E2E suite never ran against the app (7 harness defects: `.app` find depth, wrong password/email, no WEBVIEW context switch, AccessibilityId vs CSS, no binding-commit, no test isolation, MudNavLink inner-click). Fixed; suite now drives the app, 4/9 pass.~~ |
| ~~[**BUG-032**](bug.md)~~ | ~~Central/Frontend~~ | ~~**Bug** — Appium job-offer tests (4) have no service-request precondition so no offer is ever generated; JwtExpiry test (1) is a documented Keychain limitation. Fixed: suite runs backend-only (`SD_SKIP_SIMULATOR=1`) and a `BackendApiHelper` positions the fleet (Simulator account) then submits a Gold request so the offer routes to the taken-over rep; JwtExpiry `[Ignore]`d. Live: 8/9 pass, 1 skipped (frontend PR #39 + central scripts).~~ |
| ~~[**BUG-033**](bug.md)~~ | ~~Frontend~~ | ~~**Bug** — Rep take-over page rendered unstyled (IdleVehicleList/TakeOver had no scoped CSS); idle vehicle card stacked vertically; app bar lacked the vehicle subtitle + equal-size translucent circles. Found comparing the live app to the rep mockups. Fixed via `/master` (PR #36): scoped CSS, equipment chips + friendly labels, scrollable list with pinned CTA, white idle card, app-bar circles.~~ |
| ~~[**BUG-034**](bug.md)~~ | ~~Frontend~~ | ~~**Bug** — Idle view card **and** app-bar subtitle showed a hardcoded vehicle (IA-4471) instead of the one the rep took over (e.g. V-001): the take-over flow never handed the selected vehicle to the idle view. Found via the Appium take-over flow. Fixed via `/master` (PR #37): scoped `IClaimedVehicleStore` hand-off, stub removed, shared `EquipmentLabels` helper for friendly labels everywhere. Model deferred to BUG-035.~~ |
| ~~[**BUG-035**](bug.md)~~ | ~~Backend + Frontend~~ | ~~**Bug** — `AvailableVehicleDto` carries no vehicle model, so take-over rows and the idle card show "V-001" not "IA-4471 · Transit 350" (per the mockups). Deferred from BUG-034 (frontend-only). Fixed via `/master` across two PRs: backend (PR #47) added `Model` to the `Vehicle` entity/seed + `AvailableVehicleDto` + handler; frontend (PR #38) added `Model` to `IdleVehicle` and renders "<reg> · <model>" in the take-over rows and idle card. (Appium scenario for the title deferred to BUG-032's bucket.)~~ |
| ~~[**BUG-036**](bug.md)~~ | ~~Frontend~~ | ~~**Bug** — Job-offer screen: the Gold/Silver/Bronze **tier badge is invisible** (`.sd-badge` white-on-white when `Tier` defaults to `None` — a `JobOfferReceived` wire-contract mismatch); plus a stale "· On shift" subtitle, no elevated content card, and PersonaShell's generic title vs the mockup's "Incoming Job Offer". Fixed via `/master` (PR #45): `JobOfferReceivedWirePayload` DTO maps the backend names/types (fixing the tier badge + map pin), `.sd-card` wrapper, offer-route app-bar chrome. Live Appium `JobOfferTests` 4/4. Mockup's "P0700 ·" DTC code recorded non-authoritative (spec mandates no codes).~~ |
| ~~[**BUG-037**](bug.md)~~ | ~~Frontend~~ | ~~**Bug** — Frontend ignores the backend's `JobOfferExpired` RepHub event: `IRepHubService`/`SignalRRepHubService` register handlers only for `JobOfferReceived` + `RedirectReceived`, so a server-pushed offer expiry is dropped and the offer screen clears only when its local 60 s countdown elapses (or on a 409 if the rep taps Accept first). Found tracing the RepHub event catalogue end-to-end (backend sends 4 events, frontend handles 2). Fix: add `OnJobOfferExpired` + a `JobOfferExpiredPayload`, dismiss the on-screen offer (match on `OfferId`) and stop the countdown; keep the local timer as a fallback.~~ |
| ~~[**BUG-038**](bug.md)~~ | ~~Frontend~~ | ~~**Bug** — Rep idle screen raised Blazor's "An unhandled error has occurred" banner when the RepHub SignalR connection couldn't be established at mount: `RepIdle.OnInitializedAsync` awaited an unguarded `StartAsync` and `.WithAutomaticReconnect()` doesn't cover the initial connect, so an unreachable RepHub threw uncaught. Found via live iOS-simulator debugging. Fixed via `/master` (frontend PR #48): `SignalRRepHubService.StartAsync` catches the initial-connect failure and runs a bounded exponential-backoff retry behind an injectable test seam; added `IRepHubService.IsConnected`; ViewModel swallows-and-logs; `OnInitializedAsync` guard + "Reconnecting…" indicator. Masking-test finding fixed at AI-review cycle 2; component repro test verified red-without-fix; 297 frontend tests green.~~ |
| ~~[**BUG-039**](bug.md)~~ | ~~Frontend~~ | ~~**Bug** — Active-job screen (`/rep/job`) doesn't match the `rep-active-job` mockup: (1) generic PersonaShell app bar instead of "Active Job" / "Navigating to requester" (page never sets a shell title); (2) ETA card shows minutes only — no distance ("ETA · 8.1 MI"), and `ActiveJobContext`/`ActiveJobViewModel` expose no distance value; (3) ETA card pinned top-left instead of centered; (4) "En Route" chip is a solid blue fill instead of the soft tinted pill. Found comparing the live screen to `rep-active-job__mobile-390x844.png`. ("P0700 ·" DTC code is non-authoritative — spec mandates no codes, per BUG-036.) Fix via `/master`: set the shell title, surface a distance (client Haversine or active-job DTO field), center the ETA card, restyle the En Route chip.~~ |
| ~~[**BUG-040**](bug.md)~~ | ~~Backend + Frontend + Central~~ | ~~**Bug** — The `JobOfferExpired` Appium E2E test could never pass: a 15 s throwing `WaitForSignalR` vs the backend's ~60 s server offer-expiry, so the test aborted on its first lap before the event arrived (and the assertion "dismissed while countdown > 0" was unobservable while the local countdown matched the server expiry). Found running `test-appium.sh` after BUG-039 (product wiring was correct; the test was the defect). Fixed via `/master` across three repos: backend made the offer-expiry configurable (`MatchingOptions`, default 60 s; PR #50); `test-appium.sh` shortens it to 15 s for the E2E run via a `JobOfferExpiry__OfferExpirySeconds` env override (central PR #165) so the event fires while the offer screen's fixed 60 s countdown is still high; the test uses a non-throwing `TryWaitForSignalR` so its 80 s loop governs the wait (frontend PR #50). Live-verified, Appium `JobOfferTests` 6/6.~~ |
| ~~[**BUG-041**](bug.md)~~ | ~~Frontend~~ | ~~**Bug** — Release Vehicle (FE-014) never opens its confirmation dialog: `RepIdleViewModel`'s constructor consumes `IClaimedVehicleStore` as a one-shot hand-off and calls `ClearVehicle()`, so by the time the rep taps Release, `ReleaseVehicleAction` reads `CurrentVehicle == null` and silently no-ops — no dialog, drawer stays open. A real user can never release/go off duty. Found via `test-appium.sh` (2 `ReleaseVehicleTests` fail) and live-verified on the iOS sim (product defect, not test/harness; masked by unit tests that mocked the store). Fix via `/master`: make the claimed-vehicle store durable (clear on logout/release, not on idle-view construction); red test must exercise the real composition root.~~ |
| ~~[**BUG-042**](bug.md)~~ | ~~Frontend~~ | ~~**Bug** — Idle screen shows a stale vehicle after a second take-over in one session: `RepIdleViewModel` is `AddScoped` (≈ singleton per BlazorWebView) and caches `Vehicle` once in its constructor, so re-taking a different vehicle doesn't update the idle card / app-bar subtitle (release still targets the correct one). Found during BUG-041 blast-radius analysis. Fix via `/master`: re-hydrate the claimed vehicle from the store on each idle entry.~~ |
| ~~[**BUG-043**](bug.md)~~ | ~~Frontend~~ | ~~**Bug** — Claimed-vehicle store isn't cleared on logout, so a stale claim persists across sessions (surfaced once BUG-041 removes the incidental idle-view clear). Low risk (re-login routes through take-over, which overwrites). Found during BUG-041 blast-radius analysis. Best resolved within **FE-023** (clear `IClaimedVehicleStore` on logout + go-off-duty/timeout alongside heartbeat teardown).~~ |
| ~~[**BUG-044**](bug.md)~~ | ~~Frontend~~ | ~~**Bug** — Requester tracking app bar showed the default "Service Delivery" title instead of the page-set title ("Your technician is on the way" / after redirect "A new technician is on the way"), plus a faint duplicate avatar and a stray hamburger. Root causes: (1) page-set title lost on initial live render (`ShellViewModel.SetTitle` fired no re-render nudge; `MainLayout` only bumps `_shellVersion` while `Menu is null`); (2) `PersonaShell` `appbar-avatar` + `PersonaMenu` `persona-avatar` both rendered, the survivor mispositioned. Found via FE-018 live-E2E rendered-fidelity review; the original defect slipped through because bUnit asserted the ViewModel field, not the rendered DOM. Fixed via `/master` (frontend PR #68): re-apply title from `RequesterTracking.OnAfterRenderAsync(firstRender)` + a `ShellViewModel.TitleChanged` event for post-render changes; render the single avatar in the trailing app-bar slot; gate the hamburger to Drawer style; added composed rendered-DOM bUnit tests + live Playwright title/single-avatar assertions. Live-verified against both mockups.~~ |
| ~~[**BUG-045**](bug.md)~~ | ~~Frontend~~ | ~~**Bug** — Concurrent take-overs collide on the first-listed available vehicle (V-001), so a second assignable rep can't be acquired cleanly on a clean live start — a distinct concurrency/ergonomics facet of the fixed BUG-027. Found during FE-018 redirect E2E setup. Triaged (from a Backend/Simulator label) to the **client retry-on-409** approach and fixed via `/master` (frontend PR #69): `TakeOverViewModel.TakeOverAsync` now bounded-auto-retries the next available candidate on a 409, falling back to a "just taken — pick another" message when the list is exhausted. Backend untouched (the 409 is correct optimistic concurrency); ViewModel unit tests are the guard.~~ |
| ~~[**BUG-046**](bug.md)~~ | ~~Frontend~~ | ~~**Bug** — Appium `ActiveJobTests.GivenRep1AcceptedJob_…GoogleMapContainerIsPresentWithOverlayTestIds` fails with `StaleElementReferenceException`: it reads `map.Displayed` (line 97) on a `[data-testid='google-map']` reference captured before the Google Maps SDK stamps in the rep-marker/requester-pin/route-line overlays, and that DOM churn detaches the captured node. Test-only fragility (the map + overlays render fine), but leaves the QUAL-004 Appium suite 1-red. Found during QUAL-011 live re-verification; **confirmed pre-existing, not a QUAL-011 regression** — fails identically on `main` with QUAL-011 stashed out, and reproduces deterministically in isolation (not the under-load flake family). Fix via `/master`: re-find the element at the assertion point (or assert via `FindElements(...)` count) without weakening the check.~~ |
| ~~[**BUG-047**](bug.md)~~ | ~~Frontend~~ | ~~**Bug** — ActiveJob ETA/distance card (`.sd-eta`, `position: absolute; top: 12px; left: 50%`) sits top-center of the map and overlaps Google's Map/Satellite map-type control, blocking the toggle. Follow-on to BUG-039 (which centered the card from top-left); the real Google map (FE-026) put a native control where the card now lands. Found during QUAL-011 live re-verification; independent of QUAL-011 (which leaves `.sd-eta` scoped/unmoved). Fix via `/master`: relocate the card to **center-bottom** (`bottom: 12px`, keep the horizontal centering), verifying it clears the zoom/logo/ToS controls too.~~ |
| ~~[**BUG-048**](bug.md)~~ | ~~Frontend~~ | ~~**Bug** — Appium shared precondition `TakeOverFirstIdleVehicle()` (`AppiumFixture.cs:319`) flakes under full-suite load: a bare `FindElement('idle-vehicle-row')` races the async idle-list load (REST + SignalR fleet snapshot lands after `Login()` returns), throwing `NoSuchElementException` intermittently and 1-reddening the QUAL-004 suite. The `TakeOverFirstIdleVehicle`-under-load flake family named in BUG-046 / the App-Nap notes — known but never filed. Found during QUAL-011 live re-verification (failed once in the 7m22s full suite, re-ran green 2/2 in isolation → load-dependent, not a QUAL-011 regression). Fix via `/master`: route the async lookups through the existing `WaitForSignalR` bounded poll (as BUG-046 did for `ActiveJobTests`); verify by repeated full-suite-under-load green, not a new isolated red.~~ |

**Depends on:** Phase 8, Phases 2–5 (vehicle + job offer + state transition + takeover/heartbeat endpoints)
**Exit criteria:** A ServiceRep user can take over an idle vehicle and complete a full job end-to-end in the UI with the simulator driving position; going off-duty parks the vehicle without the simulator re-assuming it.

---

## Phase 10 — Frontend Requester Flow
**Goal:** A Requester can submit a request, wait for assignment, and track their rep live.

| Story | Repo | Description |
|-------|------|-------------|
| ~~[FE-015](frontend.md)~~ | ~~Frontend~~ | ~~Request submission form (map + DTC picker)~~ |
| ~~[FE-016](frontend.md)~~ | ~~Frontend~~ | ~~Pending spinner — waiting for rep assignment~~ |
| ~~[FE-017](frontend.md)~~ | ~~Frontend~~ | ~~Live rep tracking map with ETA~~ |
| ~~[FE-018](frontend.md)~~ | ~~Frontend~~ | ~~Redirect notification~~ |
| ~~[FE-019](frontend.md)~~ | ~~Frontend~~ | ~~Service complete screen~~ |

**Depends on:** Phase 8, Phases 3–5 (service request + job offer + state transition endpoints)
**Exit criteria:** A Requester user can submit a request and see a rep moving toward them in real time; redirect and completion notifications display correctly.

---

## Phase 11 — Frontend Dispatcher Flow
**Goal:** A Dispatcher can monitor the full fleet, manage the request queue, redirect reps, and respond to offline alerts.

| Story | Repo | Description |
|-------|------|-------------|
| ~~[FE-003](frontend.md)~~ | ~~Frontend~~ | ~~Live fleet map with colour-coded rep markers~~ |
| ~~[BE-032](backend.md)~~ | ~~Backend~~ | ~~Enrich `GET /dispatcher/fleet` with the active-request DTC title so the FE-003 popover can show it (FE-003 AC-5 follow-up; filed from the FE-003 AI review)~~ |
| ~~[**BUG-050**](bug.md)~~ | ~~Frontend~~ | ~~**Bug** — Cold start with a valid persisted JWT landed on a permanently blank `/` page on every host: `ResolveStartRouteAsync` returned `null` for a valid token and `Home.razor` rendered nothing, while the only launch test asserted just "login not shown" (masking). Exposed by FE-003's Desktop live gate (the `PreferencesTokenStore` fix made authenticated cold starts routine) and reproduced outside Appium. Fixed within FE-003 (frontend PR #76): Core `JwtRoleReader` + `PersonaHomeRoutes` resolve the persona home at launch, `Home.razor` always navigates, per-persona positive routing tests replace the masking negative. Live-verified on Desktop.~~ |
| [**BUG-049**](bug.md) | Frontend | **Bug** — Playwright `RequesterRedirectTests` intermittently 1-reddens full-suite runs: its arrange path depends on event-driven matching re-runs its reactive fleet re-positioning cannot trigger (three observed failure modes; control experiment proved it pre-exists FE-003 on main). Fix via `/master`: condition-driven arrange (poll for an Available in-range qualified rep before submitting), per the BUG-048 lesson — fix the synchronisation, not the timeout. |
| [**BUG-051**](bug.md) | Backend | **Bug** — Unclaimed vehicles are `"Offline"` in the fleet snapshot (map hides them) but `"Unassigned"` in position broadcasts (map shows them grey): hidden on load, grey after the first tick, hidden again on reload. FE-003's cycle-1 review advisory, live-confirmed during the Desktop gate. Needs a product decision (uniformly grey vs uniformly hidden), then a one-word handler alignment via `/master`; the frontend renders both vocabularies correctly today. |
| [FE-004](frontend.md) | Frontend | Active request queue with tier badges |
| [FE-005](frontend.md) | Frontend | Redirect controls with confirmation dialog |
| [FE-006](frontend.md) | Frontend | Rep offline alert banner |

**Depends on:** Phase 8, Phases 2, 5, 6 (vehicle management + state transitions + dispatcher endpoints)
**Exit criteria:** A Dispatcher user can see all 8 simulator vehicles moving on the map in real time, redirect a rep, and receive offline alerts.

---

## Phase 12 — Backend Supplement: Active Job State
**Goal:** Extend the backend with a dedicated polling endpoint for the rep navigation view, making FE-011's live map (AC-1/AC-2/AC-4) work end-to-end against the running system.

| Story | Repo | Description |
|-------|------|-------------|
| ~~[BE-030](backend.md)~~ | ~~Backend~~ | ~~`GET /rep/active-job-state` — rep position, requester location, ETA, rep state for the FE-011 map poll~~ |
| ~~[BE-031](backend.md)~~ | ~~Backend~~ | ~~Add `VehicleRegistration` to the `RepAssigned` broadcast (both emit sites) so FE-017 can show the arriving vehicle~~ |

**Depends on:** Phase 5 (rep state machine), BE-012 (active request read), BE-008 (position storage).
**Exit criteria:** The FE-011 active job navigation view renders a moving rep marker, live ETA, and enables "I've Arrived" at the correct distance — all driven by the running backend with no stubs.

---

## Phase 13 — Real Google Maps
**Goal:** Replace the CSS/SVG placeholder maps with the real Google Maps integration the map stories always specified (`FE-003`/`FE-011`/`FE-015`/`FE-017`). Build one shared map component + per-host SDK/key loading, then swap it into the built ServiceRep screens; the unbuilt dispatcher/requester map screens consume it when they are implemented. See [ADR-0010](../adr/0010-google-maps-for-map-visualization.md).

| Story | Repo | Description |
|-------|------|-------------|
| ~~[FE-025](frontend.md)~~ | ~~Frontend~~ | ~~Load the Google Maps JS SDK + supply the API key per host (Web/Mobile/Desktop); no committed key; graceful fallback~~ |
| ~~[FE-024](frontend.md)~~ | ~~Frontend~~ | ~~Reusable `GoogleMap` Blazor component (JS interop) — markers, polylines, recenter/zoom/fitBounds; state-coloured markers~~ |
| ~~[FE-026](frontend.md)~~ | ~~Frontend~~ | ~~ServiceRep Active Job — replace the placeholder with the real map (live rep marker, requester pin, route, recenter on state)~~ |
| ~~[FE-027](frontend.md)~~ | ~~Frontend~~ | ~~ServiceRep Job Offer — replace the placeholder with the real map (requester location)~~ |
| [FE-028](frontend.md) | Frontend | _(optional / stretch)_ Road-accurate route + Directions-API ETA on the active-job and tracking maps |

**Depends on:** Phase 9 (ServiceRep screens exist), BE-030 (Phase 12, live-position feed — done). The unbuilt map screens — FE-003 (Phase 11), FE-015 / FE-017 (Phase 10) — consume FE-024 when they are built rather than ever shipping another placeholder.
**Exit criteria:** `ActiveJob` and `JobOffer` render a real, interactive Google Map (verified live on the iOS host and by the AI-review render-and-screenshot check); FE-024/FE-025 are in place for the dispatcher and requester map screens to adopt.

---

## Phase 14 — App-Shell Navigation Polish
**Goal:** Sweep up the app-shell chrome defects from FE-021 in one shell-level change: move the ServiceRep hamburger to the left, redesign the drawer (left-anchored, header removed) to honour the iOS safe area (Dynamic Island / home indicator) without clipping, extend the shared app-bar safe-area handling to Requester mobile, and remove the unbacked notification bell from the Dispatcher app bar.

| Story | Repo | Description |
|-------|------|-------------|
| ~~[FE-029](frontend.md)~~ | ~~Frontend~~ | ~~App-bar & nav chrome — ServiceRep left hamburger + left-anchored safe-area drawer (header removed); shared `env(safe-area-inset-*)` top/bottom on all mobile personas; no clipping; design-system tokens; Dispatcher notification bell removed~~ |

**Depends on:** FE-021 (app shell & menu exist). The redesigned `rep-*` / `requester-*` / `dispatcher-*` mockups + shared `design-system.css` are already updated to the target design.
**Exit criteria:** Every ServiceRep screen shows the toggle on the left with the app-bar content below the Dynamic Island; the left-anchored drawer renders fully within the safe area (footer note clears the home indicator); Requester mobile app bars clear the safe area while their web renders are unchanged; the Dispatcher app bar shows no bell — verified live (iOS host) and by the AI-review render-and-screenshot check.

---

## Cross-Cutting — Engineering Quality
**Goal:** Harden the AI pipeline against defect classes that have slipped through. Not tied to a feature phase; runs whenever picked up.

| Story | Repo | Description |
|-------|------|-------------|
| ~~[QUAL-001](quality.md)~~ | ~~Central + Simulator~~ | ~~Catch "masking" tests in AI Review: strengthen `/test-quality` (+ `story-ai-reviewer`) so tests that pass by placeholder reuse / mirroring the code's wrong assumption are flagged; audit the simulator suite for other instances. Motivated by BUG-016/017 shipping green.~~ |
| ~~[QUAL-002](quality.md)~~ | ~~Central~~ | ~~Mockup-driven fidelity: every pipeline stage treats a frontend story's mockup as the visual spec — evaluator gates on its availability, planner reads it into a UI Composition Map, implementor builds to it, AI reviewer adds Check 10 (Mockup Fidelity), master surfaces it at Checkpoint #1. Motivated by BUG-021 (login shipped diverging from its mockup because no stage read it).~~ |
| ~~[QUAL-003](quality.md)~~ | ~~Frontend~~ | ~~Playwright E2E suite (web host) — real-browser coverage of Dispatcher, Requester, and ServiceRep-web flows including Google Maps interop and SignalR events~~ |
| ~~[QUAL-004](quality.md)~~ | ~~Frontend~~ | ~~Appium E2E suite (iOS simulator) — mobile coverage of the ServiceRep flow (take over vehicle → offer → accept → navigate → arrive → complete → release); depends on QUAL-003 overlay-element strategy~~ |
| ~~[QUAL-005](quality.md)~~ | ~~Central~~ | ~~Run the frontend live-integration net early and continuously: a thin per-merge frontend smoke (the browser analogue of `smoke.sh`) + a `story-ai-reviewer`/`master` rule that a frontend story isn't "done" until its QUAL-003/004 scenario runs green against a live system. Motivated by the BUG-023…032 flood (10 latent integration bugs surfacing in one day) vs the simulator catching BUG-016/017 one-at-a-time via `smoke.sh`. Depends on QUAL-003/004.~~ |
| ~~[QUAL-006](quality.md)~~ | ~~Backend + Frontend + Simulator~~ | ~~Wire-contract integrity: one source of truth for cross-repo DTOs (OpenAPI-generated/checked or shared package, recorded in an ADR), fail-loud deserialization (enum mismatch throws, not defaults to `None`), and captured-real-payload contract tests. Motivated by BUG-016 (string[] vs objects), BUG-036 (Tier silently `None` → invisible badge), BUG-028/030 (auth-contract drift).~~ |
| ~~[QUAL-007](quality.md)~~ | ~~Central + Frontend~~ | ~~Frontend tests must exercise the real composition root — DI pipeline, HttpClient handler chain, Blazor lifecycle — not a component in isolation on a convenient route; strengthen `/test-quality` + `story-ai-reviewer` and audit the frontend suite. Motivated by BUG-025/026 (bUnit bypassed the login→navigate lifecycle) and BUG-024/028 (handler-chain interaction untested). Extends QUAL-001 to the frontend.~~ |
| ~~[QUAL-008](quality.md)~~ | ~~Frontend + Backend + Central~~ | ~~Treat each client runtime (browser/WebView/native) as its own integration target: per-runtime smokes for what breaks in only one runtime + a host-parity rule that bootstrapping changes hit all three hosts. Motivated by BUG-023 (CORS browser-only), BUG-031 (WKWebView DOM invisible to native), BUG-020→022 (same asset defect shipped twice). Depends on QUAL-005.~~ |
| ~~[QUAL-009](quality.md)~~ | ~~Frontend~~ | ~~Live E2E verification of the go-off-duty / heartbeat-timeout chain (FE-023 + BE-028 + SIM-009): an Appium scenario for explicit logout/release AND the heartbeat-timeout path (short `HeartbeatTimeout` env override), asserting backend timeout → vehicle parks → simulator does not re-assume → vehicle reappears in the take-over dropdown, plus the positive "heartbeat keeps the rep on-duty through an active job" invariant. Motivated by FE-023's AC-2/AC-4 being E2E-observable only — every layer was verified in isolation, none live. Depends on QUAL-004.~~ |
| ~~[QUAL-010](quality.md)~~ | ~~Central~~ | ~~Resolve the QUAL-007 `/audit-skills` backlog: `/master` documents the `QUAL-`/unmapped-prefix → `/ship-it` redirect (encoded, not remembered); `tdd-cycle` updated to the current bUnit v2 API; `test-quality` notes the lifecycle-hosting precondition, references the precise reviewer check (3b), and trims a redundant restatement; `audit-skills`/`audit-agents` gain a stale-API/version red flag; `solid-principles` back-references `clean-architecture`. Motivated by the `/master` QUAL redirect living only in operator memory. Depends on QUAL-007.~~ |
| ~~[QUAL-011](quality.md)~~ | ~~Frontend~~ | ~~Consolidate the shared design-system tokens (`sd-card`, `sd-badge`+tiers, `sd-btn`+variants, `sd-banner`, `sd-field`, `sd-select`, `sd-muted`) into a global stylesheet loaded by all three hosts, removing the per-page scoped duplicates. Motivated by the recurring scoped-CSS gap that shipped as FE-011/012 and recurred as FE-015 / FE-016 finding #1 — each new page re-discovers the tokens don't apply. Ships via `/master` (frontend production CSS + host bootstrapping; live re-verify all affected pages).~~ |
| [QUAL-012](quality.md) | Frontend | Route `HubConnection` internal logging through the host `ILoggerFactory` in the Rep/Requester hub client services (parity with FE-003's vehicle-hub fix), each with a spy-factory guard test — so a client-side SignalR transport failure is never silent again. Motivated by FE-003's live-gate forensics burning two diagnostic loops on a phantom because hub diagnostics went to a `NullLogger`. Ships via `/master`. |
| [QUAL-013](quality.md) | Backend | Schematize REST responses in the committed OpenAPI contract — 0/24 responses currently carry a schema (request bodies only), so the QUAL-006 sync-check guards nothing consumers actually bind; BE-032's response-field addition produced no contract diff. Add response-type metadata to every endpoint, regen, and demonstrate response-shape drift now fails the sync-check. Ships via `/master`. |

**Depends on:** nothing (process improvement). Central skill/agent edits ship via `/ship-it`; test-only fidelity fixes from the audit ship via `/ship-it` as their own PR; substantive simulator production changes go via `/master`. QUAL-003 and QUAL-004 add test projects to the frontend repo and ship via `/master`.

---

## Dependency Graph

```
Phase 1 (Foundation)
    └── Phase 2 (Vehicles + Simulator positioning)
            └── Phase 3 (Service Requests + Matching)
                    └── Phase 4 (Job Offer Lifecycle + Simulator per-rep identities)
                            └── Phase 5 (Rep State + Resilience + Human Takeover)
                                    └── Phase 6 (Dispatcher Redirect)
                                    └── Phase 7 (Simulator Navigation + Reconciliation + Takeover + Auto-response)
Phase 1
    └── Phase 8 (Frontend Auth)
            └── Phase 9 (Frontend ServiceRep)   ← needs Phases 2–5
            └── Phase 10 (Frontend Requester)   ← needs Phases 3–5
            └── Phase 11 (Frontend Dispatcher)  ← needs Phases 2, 5, 6
Phase 5
    └── Phase 12 (BE-030 active-job-state)      ← unblocks FE-011 AC-1/AC-2/AC-4 end-to-end
Phase 9
    └── Phase 13 (Real Google Maps)             ← FE-024/025 component+key, then FE-026/027 swap-in
    └── Phase 14 (App-shell nav polish)         ← FE-029 left hamburger + safe-area chrome + bell removal (needs FE-021)
```

Frontend phases (8–11) can begin in parallel with Phase 2+ on the backend — the frontend can be built against mock data / a stub API while backend phases progress. Full integration testing starts once the corresponding backend phase is complete.

---

## Story Count Summary

| Repo | Stories | Phases |
|------|---------|--------|
| Backend | BE-001 – BE-032 (32 stories) | 1–6, 11, 12 |
| Simulator | SIM-001 – SIM-012 (12 stories) | 2, 4, 7 |
| Frontend | FE-001 – FE-029 (29 stories) | 8–11, 13, 14 |
| **Total** | **73 stories** | **13 phases** |

Plus **51 bugs** ([`bug.md`](bug.md)) — `BUG-001` – `BUG-051`; all resolved except `BUG-049` and `BUG-051` (open). `BUG-051` (unclaimed vehicles hidden by the fleet snapshot but grey after a position event — a backend snapshot/event vocabulary mismatch awaiting a product decision) was FE-003's review advisory, live-confirmed and filed from its Desktop gate — see Phase 11. `BUG-041`–`BUG-048` (ServiceRep idle/take-over state and concurrency, requester-tracking app-bar fidelity, and Appium E2E timing/under-load flake hardening) were all fixed via `/master` during the Phase 9–10 live-verification and QUAL-011 re-verification work — see their struck rows in Phase 9. `BUG-049` (the Playwright `RequesterRedirectTests` suite-mode arrange flake — three observed failure modes, control-experiment-proven to pre-exist FE-003) is **open**, filed from FE-003's live gate. `BUG-050` (valid-token cold start rendered a permanently blank `/` on every host, hidden by a negative-only masking launch test) was exposed by FE-003's Desktop live gate and fixed in frontend PR #76 — see Phase 11. `BUG-003`–`BUG-015` were central-repo doc/pipeline fixes (shipped via `/ship-it`). `BUG-024`–`BUG-026` were frontend E2E failures found via `test-e2e.sh`. `BUG-027`–`BUG-031` were found via `test-appium.sh` (backend idle-vehicle semantics, frontend REST + SignalR auth headers, startup error, and Appium harness defects); `BUG-032` then made the suite's 4 job-offer tests pass (backend-only run + a fleet-positioning/request precondition) and `[Ignore]`d the JWT-expiry test, taking the Appium suite to **8/9 passing, 1 skipped**. `BUG-033` (rep take-over/idle mockup fidelity, PR #36), `BUG-034` (idle view showed a hardcoded vehicle, PR #37), and `BUG-035` (surface the vehicle model in the DTO and render "<reg> · <model>", backend PR #47 + frontend PR #38) were fixed via `/master`. `BUG-036` (job-offer tier badge invisible + app-bar/card fidelity — a `JobOfferReceived` wire-contract mismatch defaulting `Tier` to `None`) was fixed via `/master` (frontend PR #45), live-verified by the Appium `JobOfferTests` (4/4). `BUG-037` (frontend ignored the `JobOfferExpired` RepHub event) was fixed via `/master` (frontend PR #47). `BUG-038` (idle-screen unhandled-error banner when RepHub can't connect at mount) was fixed via `/master` (frontend PR #48). `BUG-039` (active-job screen mockup-fidelity gaps — app-bar title, ETA-card distance + placement, En Route chip style) was fixed via `/master`: the root cause was the screen reading the impoverished `service-requests/my-active` endpoint instead of the purpose-built `rep/active-job-state` (which carries real rep position, ETA, and — after this fix — distance + tier), so the backend surfaced `DistanceMiles` + `Tier` (backend PR #49) and the frontend repointed the endpoint and closed all four gaps (frontend PR #49), live-verified end-to-end. `BUG-040` (the `JobOfferExpired` Appium E2E test could never pass — a 15 s throwing `WaitForSignalR` vs a ~60 s server offer-expiry, so it aborted on its first lap) was found running `test-appium.sh` after BUG-039 and fixed via `/master` across three repos: backend made the offer-expiry configurable (default 60 s; backend PR #50), `test-appium.sh` shortens it to 15 s for the E2E run via an env override (central PR #165), and the test uses a non-throwing `TryWaitForSignalR` so its loop governs the wait (frontend PR #50) — live-verified, Appium `JobOfferTests` 6/6.

Plus **13 engineering-quality stories** ([`quality.md`](quality.md)) — `QUAL-001` – `QUAL-013`. `QUAL-001`–`QUAL-011` are complete (`QUAL-011` consolidated the shared design-system tokens into a global stylesheet loaded by all three hosts, killing the recurring scoped-CSS gap). `QUAL-012` (route `HubConnection` internal logging through the host logger in the Rep/Requester hub clients — parity with FE-003's vehicle-hub fix) and `QUAL-013` (schematize REST responses in the committed OpenAPI contract, which currently types request bodies only) are **open**, both filed from FE-003's live-gate forensics. They were filed from a retrospective on why integration defects clustered in the frontend (many untestable boundaries + a live net that arrived late) while the backend and simulator stayed clean (one peer, `smoke.sh` from day one). They harden the frontend integration loop: run the live net early (`QUAL-005` — done: `smoke-web.sh` + the `story-ai-reviewer`/`master` live-green rule), enforce wire-contract integrity across repos (`QUAL-006` — done: ADR-0011 + committed backend OpenAPI contract with a sync-check, fail-loud enum deserialization + captured-payload contract tests in the frontend and simulator, and the `/test-quality` captured-payload rule), test the real composition root not isolated components (`QUAL-007` — done: the `/test-quality` Frontend composition-root rule + `story-ai-reviewer` Checks 2/3b referencing it, and a frontend handler-chain composition test that exercises the real `SessionExpiry → AuthToken → network` pipeline), and treat each client runtime as its own integration target (`QUAL-008` — done: a per-runtime smoke set off one entry point [`smoke-web.sh` browser-CORS, `smoke-mobile.sh` WKWebView data-testid reachability, `smoke.sh` headless], the backend CORS regression test, and a host-parity rule in the frontend CLAUDE.md enforced by `story-ai-reviewer` Check 11). `QUAL-009` live-verified the FE-023/BE-028/SIM-009 go-off-duty / heartbeat-timeout chain end-to-end (each layer had been proven only in isolation). `QUAL-010` resolved the backlog from the QUAL-007 `/audit-skills` run — done: `/master` now documents the `QUAL-`/unmapped-prefix → `/ship-it` redirect (no longer reliant on operator memory), `tdd-cycle` tracks the current bUnit v2 API, the audit skills gain a stale-API/version red flag, and the `test-quality`/`solid-principles` consistency nits are closed.
