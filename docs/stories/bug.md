# Bugs

> Defects and spec inconsistencies found after stories were written or completed. Each bug is sequenced in [`execution-plan.md`](execution-plan.md) like a story; fix it where it sits in the plan.
>
> **ID convention:** `BUG-NNN`. **Status:** Open → In Progress → Fixed.

---

## BUG-001 — `RepHub` is missing the force-release notification event

- **Status:** Fixed
- **Severity:** Medium
- **Repo / Area:** Backend — SignalR infrastructure (`BE-025`), Vehicles (`BE-007`)
- **Related stories:** `BE-007`, `BE-025`
- **Found:** Cross-checking backend stories against the updated frontend stories.

**Summary**
`BE-007` (force-release a vehicle) states: *"If the affected rep is online, they receive a SignalR notification via `RepHub`."* But `BE-025`'s `RepHub` event catalogue lists only `JobOfferReceived`, `JobOfferExpired`, and `RedirectReceived` — there is **no force-release / session-revoked event defined**.

**Expected**
`BE-025`'s `RepHub` publishes a session-revoked event, and `BE-007` names it.

**Actual**
No such event exists in `BE-025`; the notification `BE-007` promises has no defined event name or payload.

**Impact**
A force-released rep's client has no specified event to react to — it can't reliably clear the active job and return to vehicle selection. Implementers may omit the notification entirely because it isn't catalogued.

**Proposed fix**
- Add a `RepHub` event to `BE-025`, e.g. `VehicleForceReleased { vehicleId, byDispatcher: true, reason? }`.
- Reference that event by name in `BE-007`'s acceptance criteria.

**Acceptance criteria (bug resolved when):**
- `BE-025`'s `RepHub` row lists the force-release event with a defined payload.
- `BE-007` references the event by name.
- The event is consistent with how `FE-014` / the rep shell expect to be notified.

---

## BUG-002 — No frontend story for the Dispatcher force-release action

- **Status:** Fixed
- **Severity:** Medium
- **Repo / Area:** Frontend — Dispatcher (relates to `FE-006`)
- **Related stories:** `BE-007`, `FE-006`, new `FE-022`
- **Found:** Cross-checking backend stories against the updated frontend stories.

**Summary**
`BE-007` implements `POST /vehicles/{id}/force-release`, and `FE-006` (rep offline alert) narrates the dispatcher's decision — *"decide whether to force-release the vehicle or wait for the rep to reconnect."* But **no frontend story or acceptance criterion defines the UI to actually invoke force-release** (no button, no confirmation dialog).

**Expected**
A frontend story specifying the force-release action, plus a cross-reference from `FE-006`.

**Actual**
Force-release is unreachable from the UI as currently specified; the backend endpoint has no frontend consumer story.

**Impact**
A dispatcher cannot recover a stuck/offline rep's vehicle through the UI, despite the backend supporting it. The offline-alert flow (`FE-006`) dead-ends at "decide" with no follow-through.

**Proposed fix**
- Add new story **FE-022 — Force-release a vehicle (Dispatcher)** with full acceptance criteria:
  - Force-release action available from the offline-alert banner (`FE-006`) and/or the rep marker popover (`FE-003`).
  - Confirmation dialog → calls `POST /vehicles/{id}/force-release`.
  - On success: vehicle marker updates to Unclaimed/Offline; request handling reflects the re-queue.
  - Restricted to Dispatcher; Desktop + Web only (per ADR-0008).
- Cross-reference `FE-022` from `FE-006`.
- Update the Story ↔ Screen Traceability table; optionally render a force-release confirm-dialog mockup to match the "every story has a visual" pattern.

**Acceptance criteria (bug resolved when):**
- `FE-022` exists in [`frontend.md`](frontend.md) with full acceptance criteria.
- `FE-006` cross-references `FE-022`.
- Traceability table updated (and mockup rendered if that option is taken).

---

> **BUG-003 – BUG-015** were filed from a full-repo consistency audit. They are all **central-repo documentation / AI-pipeline corrections** (handle via `/ship-it`, not the TDD pipeline). Compact format below: Issue → Fix → Done-when.

---

## BUG-003 — FE-011 cross-references the wrong story for `RedirectReceived`

- **Status:** Fixed · **Severity:** Medium · **Area:** Central docs — frontend stories · **Related:** `FE-011`, `FE-016`, `FE-018`
- **Issue:** `frontend.md:213` says *"Receiving a `RedirectReceived` event … (see FE-016)"*, but FE-016 is the requester "finding a technician" spinner. The redirect story is **FE-018**.
- **Fix:** Change "(see FE-016)" → "(see FE-018)".
- **Done when:** FE-011 points to FE-018.

## BUG-004 — Phase 3 exit criterion depends on a Phase 4 endpoint

- **Status:** Fixed · **Severity:** Medium · **Area:** Central docs — execution plan · **Related:** `BE-014`, `BE-015`
- **Issue:** `execution-plan.md` Phase 3 exit criteria require *"offer visible via `GET /job-offers/pending`"*, but that endpoint is **BE-015 (Phase 4)** — it does not exist at Phase 3 completion.
- **Fix:** Reword Phase 3 exit to stop at the `JobOfferReceived` event (BE-014's deliverable); move the `/job-offers/pending` clause to Phase 4.
- **Done when:** Phase 3 exit criteria reference only Phase 3 deliverables.

## BUG-005 — `data-flow.puml` mis-wires requester status messages

- **Status:** Fixed · **Severity:** Medium · **Area:** Central docs — architecture diagram · **Related:** `data-flow.puml`, `state-machines.md`, `FE-017`
- **Issue:** `data-flow.puml:76` emits `"Almost There" (Within15Miles)` on the `/rep/arrive` → OnSite step (`:73-74`). Per `state-machines.md` and the UI brief, OnSite should read "Arrived" / "Your technician has arrived", and "Almost there" belongs on the Within-15-Miles transition (`:71`).
- **Fix:** Emit "Almost there" at the Within15Miles transition and "Arrived" on `/rep/arrive`.
- **Done when:** The puml messages match the state→message mapping in the brief / state machine.

## BUG-006 — README Skills table omits the `master` skill

- **Status:** Fixed · **Severity:** Medium · **Area:** Central docs — README · **Related:** `README.md`, `CLAUDE.md`
- **Issue:** `README.md:54-64` lists 9 skills and omits `master`, which `CLAUDE.md:126-137` and the filesystem include.
- **Fix:** Add a `master` row to the README Skills table.
- **Done when:** The README Skills table lists all 10 skills.

## BUG-007 — Existing scripts are undocumented

- **Status:** Fixed · **Severity:** Medium · **Area:** Central docs — CLAUDE.md / README · **Related:** `CLAUDE.md`, `README.md`, `scripts/`
- **Issue:** `scripts/local/test-all.sh`, `scripts/local/test-simulator.sh`, and `scripts/utils/mark-story-complete.sh` exist but appear in neither the CLAUDE.md Commands section nor the README.
- **Fix:** Document the three scripts.
- **Done when:** All real scripts are listed in the command documentation.

## BUG-008 — `ship-it` scope contradiction (CLAUDE.md vs the skill)

- **Status:** Fixed · **Severity:** Medium · **Area:** Central docs — CLAUDE.md / ship-it skill · **Related:** `CLAUDE.md:137`, `ship-it/SKILL.md`
- **Issue:** CLAUDE.md says ship-it "lands all pending local changes on main", but the skill scopes itself to *out-of-pipeline* changes and routes story work to `/master`.
- **Fix:** Update CLAUDE.md:137 to "lands out-of-pipeline changes (docs/config/housekeeping); story commits/PRs go through `/master`."
- **Done when:** CLAUDE.md matches the skill's stated scope.

## BUG-009 — `story-implementor` hardcodes `dotnet test`

- **Status:** Fixed · **Severity:** Medium · **Area:** Central — AI pipeline (story-implementor) · **Related:** `story-implementor/AGENT.md`
- **Issue:** Lines 37, 145, 154 use bare `dotnet test`, but the agent elsewhere mandates a "repo-appropriate test command" with per-repo paths (`:134,178,214-220`) — wrong scope for Frontend/Simulator.
- **Fix:** Replace bare `dotnet test` at 37/145/154 with "the repo-appropriate test command (see Repo-Specific Test Commands)."
- **Done when:** No bare `dotnet test` remains where a repo-specific command is required.

## BUG-010 — Dispatcher force-release endpoint is under-documented

- **Status:** Fixed · **Severity:** Medium · **Area:** Central docs — UI brief / system-overview · **Related:** `BE-007`, `BUG-002`/`FE-022`, `ui-design-brief.md`, `system-overview.puml`
- **Issue:** `POST /vehicles/{id}/force-release` (BE-007, `data-flow.puml:212`) is absent from the UI brief's endpoint references and the system-overview endpoint group; only the rep self-release `/vehicles/{id}/release` is surfaced.
- **Fix:** Document the dispatcher `force-release` endpoint in the brief and system-overview, distinct from rep `release`. (FE consumer story is tracked by `BUG-002`.)
- **Done when:** force-release appears in the brief + system-overview endpoint references.

## BUG-011 — Inconsistent commit/PR attribution conventions

- **Status:** Fixed · **Severity:** Low · **Area:** Central — AI pipeline (story-pr, ship-it) · **Related:** `story-pr/AGENT.md`, `ship-it/SKILL.md`
- **Issue:** story-pr commit trailer = `Co-Authored-By: Claude Code <noreply@anthropic.com>`; ship-it PR body = `🤖 Generated with [Claude Code]`; story-pr PR body has no attribution line — conventions disagree.
- **Fix:** Choose one attribution convention for commit trailers and one for PR bodies; apply consistently to story-pr and ship-it.
- **Done when:** All commit/PR templates use the same attribution.

## BUG-012 — `BUG-`/`fix/` branch handling incomplete downstream of master

- **Status:** Fixed · **Severity:** Low · **Area:** Central — AI pipeline · **Related:** `story-planner`, `story-implementor`, `story-pr`
- **Issue:** `master` / `story-evaluator` carry the `BUG-`→Repo/Area resolution and `fix/` branch convention, but `story-planner` (arch-doc table), `story-implementor`, and `story-pr` only show `feature/<BE-…>` examples and no `fix/` / Repo-Area note.
- **Fix:** Add one-line `BUG-`/`fix/` notes to those three agents.
- **Done when:** All pipeline agents handle `BUG-` consistently.

## BUG-013 — CLAUDE.md "Persona" wording implies a section that doesn't exist

- **Status:** Fixed · **Severity:** Low · **Area:** Central docs — CLAUDE.md · **Related:** `CLAUDE.md:148`, all `AGENT.md`, `validate-ai-system`
- **Issue:** `CLAUDE.md:148` lists "**Persona**" as a required AGENT.md section, implying a `## Persona` header; agents use an unlabeled paragraph, and `validate-ai-system` checks for a paragraph.
- **Fix:** Reword `CLAUDE.md:148` to "a persona paragraph" (or add `## Persona` headers to all 5 agents).
- **Done when:** CLAUDE.md wording matches the agents and the validator.

## BUG-014 — CLAUDE.md `docs/stories/` description omits files

- **Status:** Fixed · **Severity:** Low · **Area:** Central docs — CLAUDE.md · **Related:** `CLAUDE.md:79`
- **Issue:** The `docs/stories/` directory description lists the backlog + `bug.md` + execution plan but omits `parallel-tracks.md` and `README.md`.
- **Fix:** Add `parallel-tracks.md` and `README.md` to the description (or generalize the wording).
- **Done when:** The description reflects the directory's actual contents.

## BUG-015 — Stale `.gitkeep` files in populated script directories

- **Status:** Fixed · **Severity:** Low · **Area:** Central — scripts · **Related:** `scripts/local/.gitkeep`, `scripts/utils/.gitkeep`
- **Issue:** Both directories now contain real scripts, so the `.gitkeep` placeholders are obsolete.
- **Fix:** Remove `scripts/local/.gitkeep` and `scripts/utils/.gitkeep`.
- **Done when:** Both `.gitkeep` files are gone.

---

## BUG-016 — Simulator crashes on startup: `/vehicles/available` response shape mismatch

- **Status:** Open
- **Severity:** High (simulator cannot start — blocks any end-to-end run)
- **Repo / Area:** Simulator — `BackendApiClient.GetAvailableVehicleIdsAsync` / `IBackendApiClient` / `FleetClaimCoordinator`
- **Related stories:** `SIM-008` (fleet reconciliation / initial vehicle claim), `BE-004` (`GET /vehicles/available`)
- **Found:** First headless end-to-end run (backend + simulator together). Caught by integration, not unit tests — both repos were tested against their own mock of this call, so the wire-contract drift was invisible until they ran together.

**Summary**
On startup, `FleetClaimCoordinator.ClaimInitialVehiclesAsync` calls `GET /vehicles/available` and the simulator deserializes the response as `IReadOnlyList<string>` (an array of bare vehicle-id strings). The backend (`BE-004`) actually returns an array of **objects**: `{ vehicleId, registration, equipment[] }`. Deserialization throws and the host crashes before the simulator can operate any rep.

**Exact error**
```
System.Text.Json.JsonException: The JSON value could not be converted to System.String. Path: $[0]
  ---> Cannot get the value of a token type 'StartObject' as a string.
  at ServiceDelivery.Simulator.Services.BackendApiClient.GetJsonAsync[T](...)  // BackendApiClient.cs:131
  at ServiceDelivery.Simulator.Services.FleetClaimCoordinator.ClaimOneFreeVehicleAsync(...)  // FleetClaimCoordinator.cs:54
  at ServiceDelivery.Simulator.Workers.SimulatorStartupService.StartAsync(...)  // SimulatorStartupService.cs:81
```

**Expected**
The simulator parses the `GET /vehicles/available` response and obtains the available vehicle ids to claim.

**Actual**
`GetAvailableVehicleIdsAsync` requests `GetJsonAsync<string>` against an endpoint that returns objects; the JSON value `{...}` cannot be read as a `string`, so the call throws and the simulator process exits on startup.

**Root cause**
Contract drift between repos: the simulator assumed `GET /vehicles/available` returns `["id", ...]`; the backend returns `[{ "vehicleId": "...", "registration": "...", "equipment": [...] }, ...]`. Note the id field is `vehicleId`, not `id`.

**Proposed fix (simulator-side)**
- Deserialize `GET /vehicles/available` into the object shape and project out `vehicleId`, returning the list of ids from `GetAvailableVehicleIdsAsync` (keep the public `IReadOnlyList<string>` contract its callers rely on).
- Add a small model record mirroring the backend's available-vehicle item (`VehicleId`, `Registration`, `Equipment`) rather than reusing `GetJsonAsync<string>`.

**Acceptance criteria (bug resolved when):**
- A unit test deserializes a realistic `GET /vehicles/available` JSON body (array of `{ vehicleId, registration, equipment }`) and asserts `GetAvailableVehicleIdsAsync` returns the expected ids.
- `FleetClaimCoordinator.ClaimInitialVehiclesAsync` no longer throws on that response shape.
- The simulator starts cleanly against the running backend and claims initial vehicles (verified by the headless smoke: reps reach `Available` with a posted position).

---

## BUG-017 — Simulator never posts positions: VehicleWorker keyed by registration, fleet-state uses GUIDs

- **Status:** Open
- **Severity:** High (no vehicle position is ever driven/posted — the fleet never moves, reps never get a position, so matching cannot select them; blocks any end-to-end run and the whole visual demo)
- **Repo / Area:** Simulator — `Workers/FleetPositionDriver`, `Models/IowaRoutes`, `Workers/VehicleWorker` (possible Backend touch: `GET /simulator/fleet-state` payload)
- **Related stories:** `SIM-003`/`SIM-004` (route loops + position posting), `SIM-006`/`SIM-008` (fleet-state-driven position), `BE-008`/`BE-027` (position endpoint / fleet-state read)
- **Found:** Second headless backend+simulator run, immediately after BUG-016 was fixed (the simulator now starts and claims, exposing the next layer).

**Summary**
`FleetPositionDriver` holds one `VehicleWorker` per `IowaRoutes` entry, keyed by `VehicleWorker.VehicleId` — which is the **registration string** (`"V-001"`…`"V-008"`). Each tick it looks up the worker for a fleet-state row by `row.VehicleId`, but the backend's `GET /simulator/fleet-state` identifies vehicles by **GUID** (`30000000-…-01`). The key never matches, so every vehicle is skipped and **no position is ever posted**.

**Exact symptom (live log, repeated every tick for all 8 vehicles)**
```
warn: ServiceDelivery.Simulator.Workers.FleetPositionDriver[0]
      No VehicleWorker registered for vehicle 30000000-0000-0000-0000-000000000001; skipping drive.
```
Consequence verified via `GET /dispatcher/fleet`: all reps are `Available` (claims succeeded) but every `lastPosition` is `null`.

**Root cause**
Vehicle-identity mismatch. The simulator's hardcoded routes/workers key off registration strings; the backend identifies vehicles by GUID everywhere (fleet-state, claim, position endpoint). `FleetStateRow` carries `VehicleId` (GUID) but **no registration**, so the simulator currently has no field to bridge GUID → route.

**Design decision required (surface at Checkpoint #1)**
- **(A) Simulator-only — recommended:** assign `IowaRoutes` to vehicle **GUIDs dynamically** as they appear in fleet-state (route choice is cosmetic — each Iowa loop is an arbitrary patrol pattern, so it doesn't matter which GUID drives which route). Key `FleetPositionDriver` by the GUID. No backend change.
- **(B) Backend-assisted:** add `registration` to the `GET /simulator/fleet-state` payload and key/map routes by registration. Requires a backend change (cross-repo) and only matters if a vehicle must always drive its "named" territory — not needed for the POC.

**Acceptance criteria (bug resolved when):**
- `FleetPositionDriver` resolves a worker/route for every fleet-state row by the backend's vehicle GUID (no `No VehicleWorker registered` warnings).
- Each operated vehicle's position is posted every tick; `GET /dispatcher/fleet` shows `lastPosition != null` for operated reps.
- A unit test feeds GUID-keyed fleet-state rows and asserts each row maps to a route/worker and a position is driven (no silent skip).
- Verified by the headless smoke: the warm-up gate passes (reps reach `Available` **with** a posted position) and a submitted request matches and runs through the cycle.

---

## BUG-018 — Headless smoke can falsely time out: long navigate legs + on-site dwell exceed the observation window

- **Status:** **Fixed** 2026-06-20 — `smoke.sh` hardened (short-leg submit + widened window + slow-vs-stall diagnosis); validated end-to-end. (Reframed 2026-06-19 — the original "navigation stall" was a misdiagnosis; see below.)
- **Severity:** Medium (no product defect — the automated cycle completes end-to-end; but `smoke.sh` can report a false failure, which undermines the integration net that QUAL-001 relies on)
- **Repo / Area:** Central — `scripts/local/smoke.sh` (requester placement + watch-window). Simulator route/speed tuning is a *separate, optional* POC decision (see notes), **not** a bug fix. **No navigation defect exists.**
- **Related stories:** `SIM-006` (navigate to requester + arrive), `SIM-010` (dwell + complete), `BE-008` (15-mile detection)
- **Found:** Third headless run flagged an apparent stall at `Within15Miles`. Re-diagnosed via live runs 2026-06-19 — the stall does not exist (see root cause).

**Summary**
The original report claimed an automated job "stalls ~1–2 km short of the requester, never auto-arrives, never completes." A live re-diagnosis disproved this: navigation converges correctly and the full cycle (`accept → en route → arrive → dwell → complete`) runs end-to-end. The real issue is that `smoke.sh` can **falsely time out**: it places the requester at a *stale* idle-vehicle position and watches for only ~6 min, but a matched rep can start a job up to ~12 km away — a leg that, plus the 120–240 s on-site dwell, can exceed the watch window even though everything is working.

**Root cause — CONFIRMED via live runs (2026-06-19)**
Three independent end-to-end completions observed (two at the stock 65 mph, one via `smoke.sh` at a temporary 200 mph debug speed):
- **No navigation stall.** The posted position advances **monotonically at ~87 m/tick (65 mph)** the entire leg — verified over 100+ consecutive ticks. `ArrivalReporter` fires `POST /rep/arrive` at the ~50 m threshold (`vstate → OnSite`, request `→ InProgress`), SIM-010's dwell runs (~228 s observed, within 120–240 s), then `POST /rep/complete` lands (request `→ Completed`, rep `→ Available`). The earlier "1.8 km after 6 min, not moving closer" was simply where the original observation window *ended* on a ~10 km leg that was still closing at 87 m/tick.
- **Why legs are long & the smoke is flaky:** idle vehicles **teleport between sparse Iowa loop waypoints** (`VehicleWorker.PostLoopPositionAsync` posts the *next waypoint* each tick; waypoints are ~6–12 km apart). `smoke.sh` samples an Available rep's `lastPosition`, then submits a request there — but by the next tick that vehicle has jumped to its next waypoint, so the matched rep can be ~10 km from the fixed requester point. At 65 mph that leg ≈ 6 min; plus the dwell it can exceed `smoke.sh`'s 120-tick (~6 min) watch loop.
- Both prior "ruled out" hypotheses (resolver halting at `Within15Miles`; fleet-state dropping `ActiveRequestLocation`) remain correctly ruled out — confirmed by the live trace (vehicle stayed in `Navigate` with a valid target throughout).

**Acceptance criteria (bug resolved when):**
- `smoke.sh` deterministically reaches `Completed` and then sees the rep return to the loop (SIM-007), without false timeouts. Achieve this by some combination of: (a) submitting the request near the matched vehicle's *current* position (re-read position immediately before submit, or accept a short fixed leg), and/or (b) widening the watch window to cover the worst-case leg + max dwell, and logging elapsed time so a slow-but-working run is distinguishable from a real failure.
- A run that genuinely fails (no arrive, or no completion) is still reported as a failure — the fix must not mask real regressions (it widens tolerance for *known* slow paths only).

**Notes**
- **Delivery:** this is a `scripts/local/smoke.sh` change in the **central** repo → ships via `/ship-it`, not `/master` (the pipeline never targets central). No simulator production change is required.
- **Optional POC tuning (separate decision, not part of this fix):** raising the navigation speed and/or densifying the loop waypoints would shrink legs and make the demo snappier. A temporary 200 mph bump was validated as a debug accelerant (`smoke.sh` completed in 135 s) then reverted — it is **not** the official speed. The on-site dwell (120–240 s) is the remaining floor on cycle time.
- **Status of the smoke fix:** **landed** 2026-06-20. [`BUG-019`](#bug-019) (the offer-path flakiness that briefly blocked it) was found to be environmental and closed cannot-reproduce, so the hardened `smoke.sh` was validated against a healthy cold-started system and shipped.

---

## BUG-019 — Simulator intermittently never accepts offers / drops an OnSite job (suspected RepHub or heartbeat instability)

- **Status:** **Closed — CANNOT REPRODUCE (environmental).** Three clean cold-start cycles (2026-06-20) all ran healthy; symptom never recurred. See Resolution.
- **Severity:** ~~High *if real*~~ — n/a; not a product defect on a clean slate.

**Resolution (2026-06-20)**
After a guaranteed-clean slate (no stale `dotnet` processes, port 5180 free), three consecutive cold starts (`stop.sh` → `start.sh` → cold submit) were driven to completion:
- **Cycle 1:** accepted on the first offer at 6 s, navigating normally (cut mid-leg) — no cold-start no-accept.
- **Cycle 2:** accepted @9 s → OnSite @126 s → **Completed @360 s** (dwell ~234 s). No revert.
- **Cycle 3:** accepted @6 s → **Completed @222 s**. No revert.

The original symptoms (cold-start all-offers-expire; `OnSite` job re-queued mid-dwell) appeared **only** on a simulator instance left running through long idle waits in a long session, and never recurred on a clean slate — so the cause was the **local host, not a simulator defect**. The offer/RepHub path is reliable from cold.

**Most likely mechanism — host idle sleep / App Nap.** During the failing run the machine sat idle for many minutes (12-min smoke runs, multi-minute waits, no mouse/keyboard activity). macOS idle sleep / App Nap suspends the Terminal-launched `dotnet` processes and tears down the simulator's **SignalR (RepHub) websockets**. A dropped RepHub while a rep is `OnSite` trips the backend's offline detection (`BE-023`) → the job re-queues (**symptom 2**); on wake the sim doesn't reliably re-subscribe → subsequent offers are never received and **expire** (**symptom 1**, and consistent with the observed `0` `/job-offers` calls). This also explains the intermittency: the three clean repro cycles were short and attended, so no idle-sleep window landed mid-run.

**Mitigation applied (2026-06-20):** `scripts/local/start.sh` now holds a `caffeinate -i` assertion for the lifetime of the local system (released by `stop.sh`), so the host can't idle-sleep during a run. The follow-up below (per-rep RepHub lifecycle logging + sim-side reconnect robustness) is retained as a *non-blocking* observability/robustness improvement — worthwhile if real telematics ever runs over flaky links, but not a bug fix.
- **Repo / Area:** Simulator — per-rep RepHub connection lifecycle, auto-decision (`Services/*SignalR*`, `JobOfferDecisionEngine`), and heartbeat for operated reps. Possibly interacts with backend `BE-023` (offline-detection re-queue) / `BE-028` (heartbeat timeout). **To be narrowed once reproduced.**
- **Related stories:** `SIM-005` (auto-accept), `SIM-002`/`SIM-011` (per-rep RepHub), `BE-018` (offer expiry), `BE-023` (offline re-queue), `BE-028` (heartbeat timeout)
- **Found:** 2026-06-20, while validating the BUG-018 smoke fix — on a simulator instance started after several rebuilds/restarts in a long session.

**Symptoms (observed live, one sim instance)**
1. **Cold-start: no acceptance.** For ~7 min after startup every job offer `Expired`; the sim made **zero** `POST /job-offers/*` calls (no accept/decline) — the per-rep RepHub offer path was not delivering offers, while position-posting (the `Simulator` account) worked normally. `offerHistory` showed 9 offers cycled across all 8 reps, all `Expired` (not `Declined`) → the sim never responded. Later in the same instance's life acceptance worked (a fresh request was accepted on the first offer within 9 s).
2. **Mid-job drop.** A request that was accepted, navigated cleanly to the requester, and reached `OnSite` (`InProgress`) dwelled ~162 s, then **reverted to `Pending`** (re-queued, unassigned) instead of completing; subsequent offers expired again. Consistent with the rep's RepHub disconnecting (`BE-023` re-queue) or a missing/late heartbeat (`BE-028` timeout).

**Why it might NOT be a product bug (do not over-commit):** three earlier end-to-end runs in the *same session* completed cleanly; only this 4th instance (after many rebuilds/restarts) was flaky. Could be local resource/state exhaustion rather than a defect.

**How to confirm**
- Clean restart: `scripts/local/stop.sh`, verify no stale `dotnet` processes, `scripts/local/start.sh`; wait for claims + hub connect; run `scripts/local/smoke.sh`. Repeat several times from cold. If offers expire on cold start, or an `OnSite` job re-queues with no human-takeover/decline cause, it is real.
- The sim currently logs **no** RepHub connect/disconnect/reconnect lifecycle at info level — add that logging; it is needed to diagnose either way (and is a gap regardless).
- Check whether the sim sends `POST /rep/heartbeat` for operated reps and whether `BE-028`'s timeout could fire during a 120–240 s dwell.

**Acceptance criteria (resolved when)**
- Across N consecutive cold starts the sim reliably connects every operated rep's RepHub and accepts offers (no all-expire window); a started job is never re-queued while its automated rep is actively on it.
- The sim logs per-rep RepHub connect/disconnect/reconnect so this is diagnosable.
- The BUG-018 headless-smoke fix then passes reliably from a cold start (unblocks landing it).

**Notes**
- **Blocks** finishing BUG-018's `smoke.sh` fix (held until this is understood).
- **Delivery:** if a real sim defect → `/master` (simulator); if backend heartbeat/offline tuning → `/master` (backend); logging-only or smoke harness changes → `/ship-it`. Decide after the root cause is confirmed.

---

## BUG-020 — Web client renders unstyled: MudBlazor stylesheet/JS not loaded in `index.html`

- **Status:** **Fixed** 2026-06-20 — added the MudBlazor CSS, Roboto font, and JS to the Web host's `index.html`; verified the assets resolve (200) and the login page renders styled.
- **Severity:** Medium (no broken behaviour — auth/routing work — but every `Mud*` component renders as bare unstyled HTML, so the UI is visually broken on Web)
- **Repo / Area:** Frontend — Web host bootstrapping (`src/ServiceDelivery.Client.Web/wwwroot/index.html`)
- **Related stories:** `FE-001` (login screen), ADR-0007 (MudBlazor)
- **Found:** Manual launch of `scripts/local/launchWebPage.sh` after FE-001 merged — the login page appeared unstyled.

**Summary**
The Web host registers MudBlazor services (`AddMudServices()` in `Program.cs`) and the providers are present in `MainLayout.razor`, but `wwwroot/index.html` never links MudBlazor's stylesheet or script. Without `_content/MudBlazor/MudBlazor.min.css`, every MudBlazor component (`MudCard`, `MudTextField`, `MudButton`, …) renders as unstyled HTML — the login page has no card, no Material styling, no theme.

**Root cause**
Incomplete MudBlazor wiring in the Web host: services + providers were set up, but the required static assets (CSS, Roboto font, JS) were missing from `index.html`. This is host-bootstrapping config, not component logic — no test covers it (hosts are bootstrapping-only per the frontend CLAUDE.md).

**Fix**
- Add to `<head>`: the Roboto font and `<link href="_content/MudBlazor/MudBlazor.min.css" rel="stylesheet" />`.
- Add before `</body>`: `<script src="_content/MudBlazor/MudBlazor.min.js"></script>`.

**Acceptance criteria (bug resolved when):**
- `index.html` references `_content/MudBlazor/MudBlazor.min.css` and `.min.js`, and both resolve (HTTP 200) when the app is served.
- The login page renders with MudBlazor styling (centered card, Material text fields, themed primary button).

---

## BUG-021 — Login screen does not match the approved mockup (FE-001 fidelity gap)

- **Status:** **Fixed** 2026-06-20 — restyled `Login.razor` to pixel-match the mockup (gradient background, 🛰️ brand mark, bold title, labels-above-fields, sentence-case rounded button) via a shared `AppTheme` + scoped `Login.razor.css`; verified visually against both mockups (web + mobile). Shipped via `/master` (frontend PR #16).
- **Severity:** Medium (login works, but the implemented UI diverges substantially from the approved design — wrong field-label placement, no brand mark, no background, wrong button styling)
- **Repo / Area:** Frontend — `src/ServiceDelivery.Client.UI/Features/Authentication/Pages/Login.razor` (+ MudTheme / brand asset; possibly `MainLayout.razor` background)
- **Related stories:** `FE-001` (login screen), ADR-0007 (MudBlazor), `docs/ui-mockups/images/login__web-1280x800.png` and `login__mobile-390x844.png` (the authoritative design)
- **Found:** Visual comparison of the running web client against `docs/ui-mockups/images/login__web-1280x800.png` after BUG-020 made MudBlazor styling load. Surfaced only after BUG-020 — before that everything was unstyled.

**Summary**
With MudBlazor now loading (BUG-020), the login page renders as default MudBlazor Material rather than the approved mockup. FE-001 was implemented to component defaults and never reproduced the design.

**Differences (live vs. `login__web-1280x800.png`)**
| Aspect | Approved mockup | Live |
|--------|-----------------|------|
| Page background | Soft lavender→grey gradient | Flat white |
| Brand logo | Purple rounded-square mark above the title | Absent |
| Title | "Service Delivery" bold, near-black | Light-grey, regular weight |
| Field labels | Bold labels **above** each input | Floating placeholder **inside** the field |
| Inputs | Clean bordered box, label outside | Material outlined input with garbled glyph artifacts at the right edge |
| Button | "Sign in" sentence case, pill-rounded | "SIGN IN" (auto-uppercased), standard radius |
| Card | Pronounced soft shadow | Faint shadow |

**Expected** — Pixel-match the approved mockup (web + mobile):
- Light gradient page background behind a centered white card with a soft shadow.
- A brand mark above the title (no logo asset exists in `docs/ui-mockups/images/` — render it from a MudBlazor icon inside a rounded primary-coloured square, or add a committed asset).
- Title "Service Delivery" in bold near-black; "Sign in to continue" sub-caption.
- "Username" / "Password" as static labels **above** their inputs; inputs are bordered boxes with no floating-label-inside and no stray adornment glyphs.
- Primary "Sign in" button, sentence case (disable MudBlazor's uppercase), full-width, rounded.
- Keep all existing `data-testid` hooks and the LoginViewModel binding/behaviour intact.

**Acceptance criteria (bug resolved when):**
- The web login renders to match `login__web-1280x800.png`: gradient background, brand mark, bold title, labels-above-fields, sentence-case rounded primary button, no glyph artifacts.
- The mobile login matches `login__mobile-390x844.png`.
- No regression to login behaviour: existing LoginViewModel tests and component tests still pass; `data-testid` hooks (`login-card`, `email-input`, `password-input`, `sign-in-button`, `login-error`) are preserved.
- Any new conditional/render logic is covered by a bUnit test (pure styling needs no test, per the frontend CLAUDE.md).

---

## BUG-024 — `SessionExpiryHttpHandler` fires on login's 401, causing unhandled exception instead of inline error

- **Status:** **Open**
- **Severity:** High (entering wrong credentials on the web login screen produces an unhandled exception and a Blazor error banner instead of the inline "Invalid email or password." message; the sign-in button stays permanently disabled until the page is reloaded; the login error E2E test also fails as a result)
- **Repo / Area:** Frontend — `src/ServiceDelivery.Client.UI/Features/Authentication/Services/SessionExpiryHttpHandler.cs`
- **Related stories:** `FE-002` (JWT expiry), `FE-001` (login), `QUAL-003` (Playwright E2E)
- **Found:** Running `test-e2e.sh` against the live web host (2026-06-24) after BUG-023 was fixed. Browser console showed: `Unhandled exception rendering component: The session has expired; the in-flight request was aborted. SessionExpiredException at SessionExpiryHttpHandler.SendAsync`.

**Summary**

`SessionExpiryHttpHandler` intercepts every HTTP response with status 401 and throws `SessionExpiredException`. This is correct for authenticated requests where a stored JWT has expired mid-session. However, the handler is also attached to the same `HttpClient` used by `HttpAuthService.LoginAsync` — which deliberately uses 401 as the "wrong credentials" signal. When a user enters bad credentials, the backend returns 401, `SessionExpiryHttpHandler` fires before `HttpAuthService` can inspect the status code, and throws an unhandled exception. `LoginViewModel.LoginAsync` never reaches the `if (response is null) { ErrorMessage = ...; }` branch. Blazor's global error handler surfaces the exception as a crash rather than an inline validation message. The `IsBusy = false` finally-block runs but `StateHasChanged()` is never called (the exception prevents it), so the button stays disabled permanently.

**Root cause**

The handler's 401 guard has no exception for the login endpoint:

```csharp
if (response.StatusCode == HttpStatusCode.Unauthorized)
{
    await _expiryHandler.HandleExpiredSessionAsync();
    throw new SessionExpiredException(); // fires for /auth/login too
}
```

**Fix**

Add a path guard so the handler only fires on authenticated endpoints (not the login endpoint itself):

```csharp
if (response.StatusCode == HttpStatusCode.Unauthorized
    && !request.RequestUri!.AbsolutePath.Contains("/auth/login", StringComparison.OrdinalIgnoreCase))
{
    await _expiryHandler.HandleExpiredSessionAsync();
    throw new SessionExpiredException();
}
```

**Acceptance criteria (bug resolved when):**

- Entering wrong credentials on the login screen shows the inline `MudAlert` with "Invalid email or password." (the `[data-testid='login-error']` element is visible in the DOM)
- The sign-in button is re-enabled after a failed login attempt
- `SessionExpiryHttpHandler` still fires correctly for authenticated endpoint 401s (verify via a unit test that the handler is a no-op for `/auth/login`)
- `GivenInvalidCredentials_WhenLoginSubmitted_ThenInlineErrorIsShown` Playwright E2E test passes

---

## BUG-025 — Dispatcher app-shell menu (`PersonaMenu`) does not render after login: Blazor skips child re-render when parent parameter reference is unchanged

- **Status:** **Open**
- **Severity:** Medium (after logging in as a Dispatcher, the `PersonaMenu` (avatar + account dropdown) never appears in the DOM even though the user profile loads successfully; Dispatcher cannot log out or access the menu via the web host; two AppShellNav Playwright E2E tests fail as a result)
- **Repo / Area:** Frontend — `src/ServiceDelivery.Client.UI/Layout/MainLayout.razor`
- **Related stories:** `FE-021` (app shell + nav drawer), `QUAL-003` (Playwright E2E)
- **Found:** Running `test-e2e.sh` against the live web host (2026-06-24) after BUG-023 was fixed. Browser network inspection confirmed both `POST /auth/login` (200) and `GET /users/me` (200) succeed, but `[data-testid='persona-avatar']` is never in the DOM.

**Summary**

After login, `MainLayout.razor.OnInitializedAsync()` calls `AuthService.GetCurrentUserAsync()`, receives the `UserProfile`, and calls `Shell.Load(profile)` to set `ShellViewModel.Menu`. `PersonaMenu.razor` is conditionally rendered (`@if (ViewModel.Menu is not null)`). However, `PersonaMenu` never renders because Blazor skips re-rendering `PersonaShell` and its children: when `MainLayout` re-renders after `OnInitializedAsync()` completes, it passes the same `ShellViewModel` reference (`Shell`) to `PersonaShell.ViewModel`. Blazor's parameter-diffing optimisation sees an unchanged reference and does not re-render `PersonaShell` or `PersonaMenu`, so `ViewModel.Menu is not null` is never re-evaluated.

**Root cause**

`ShellViewModel.Menu` is a mutable property on an injected scoped service. Blazor does not track inner property changes on reference-type parameters — it only detects that the `ShellViewModel` reference itself has not changed, and therefore skips the child component's render cycle.

**Fix**

In `MainLayout.razor`, introduce a local state variable that changes when the profile loads, forcing `PersonaShell` to see a changed parameter and re-render:

```csharp
private int _shellVersion = 0;

protected override async Task OnInitializedAsync()
{
    if (!IsLoginRoute)
    {
        var profile = await AuthService.GetCurrentUserAsync();
        Shell.Load(profile);
        _shellVersion++; // signals PersonaShell that state has changed
    }
}
```

And in `MainLayout.razor`'s template:
```razor
<PersonaShell ViewModel="Shell" Body="@Body" ShellVersion="@_shellVersion" />
```

With a corresponding `[Parameter] public int ShellVersion { get; set; }` added to `PersonaShell.razor` (unused in template — its only role is to change on load so Blazor re-renders the child).

**Acceptance criteria (bug resolved when):**

- After logging in as `dispatcher1`, the app bar shows the avatar (`[data-testid='persona-avatar']`) within 5 seconds of the dispatcher dashboard appearing
- Clicking the avatar opens the account panel (`[data-testid='persona-menu-account-panel']`)
- Clicking "Log out" navigates back to the login screen
- `GivenAuthenticatedDispatcher_WhenAvatarClicked_ThenAccountMenuPanelIsVisible` and `GivenAuthenticatedDispatcher_WhenLogoutClicked_ThenRedirectedToLoginScreen` Playwright E2E tests pass

---

## BUG-023 — Web host cannot reach the backend: CORS not configured in `Program.cs`

- **Status:** **Open**
- **Severity:** High (the Blazor WASM web host at `:5023` cannot make any API or SignalR calls to the backend at `:5180` from a browser; login always fails with `net::ERR_FAILED`; all Playwright E2E tests fail as a result)
- **Repo / Area:** Backend — `src/ServiceDelivery.Api/Program.cs` (composition root)
- **Related stories:** `QUAL-003` (Playwright E2E suite), `FE-001` (login)
- **Found:** Running `test-e2e.sh` for the first time (2026-06-24). All 7 Playwright tests failed with `net::ERR_FAILED` on the POST `/auth/login` call. Browser network inspection confirmed a CORS block — no `Access-Control-Allow-Origin` header returned by the backend. `curl` from the terminal succeeds (curl does not enforce CORS); only browser contexts are affected.

**Summary**

`Program.cs` has no CORS middleware — `AddCors()` and `UseCors()` are absent. The Blazor WASM web host is served from `http://localhost:5023` and makes cross-origin requests to `http://localhost:5180`. The browser blocks every request because the backend returns no `Access-Control-Allow-Origin` header. MAUI Desktop and Mobile apps are unaffected (native `HttpClient` does not enforce CORS).

**Root cause**

CORS was never added to `Program.cs` when the web host was introduced. The system was developed and tested via `curl`, `smoke.sh`, and MAUI native clients — none of which enforce CORS — so the gap went undetected until the first Playwright browser-based E2E run.

**Fix**

In `src/ServiceDelivery.Api/Program.cs`, add a CORS policy that permits the local frontend origins before `builder.Build()`:

```csharp
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.WithOrigins("http://localhost:5023", "https://localhost:7058")
              .AllowAnyHeader()
              .AllowAnyMethod()
              .AllowCredentials(); // required for SignalR
    });
});
```

Then call `app.UseCors()` after `app.UseRouting()` (or at the top of the middleware pipeline, before `app.UseAuthentication()`).

**Acceptance criteria (bug resolved when):**

- `POST http://localhost:5180/auth/login` returns `Access-Control-Allow-Origin: http://localhost:5023` when called from a browser context at `localhost:5023`
- Login succeeds in the Blazor WASM web host when accessed via a browser at `http://localhost:5023`
- All 7 Playwright E2E tests in `tests/ServiceDelivery.Client.E2E/` pass against a locally running system (`start.sh` up, web host running)
- SignalR connections from the web host to `/hubs/*` succeed (CORS with `AllowCredentials` is required for SignalR WebSocket upgrade)

---

## BUG-022 — Desktop & Mobile hosts render unstyled: MudBlazor assets not loaded in their `index.html`

- **Status:** **Fixed** 2026-06-20 — added the MudBlazor CSS, Roboto font, and JS to both the Mobile and Desktop host `index.html` files; verified all three hosts now reference the assets.
- **Severity:** Medium (auth/routing work, but every `Mud*` component renders as bare unstyled HTML on the MAUI hosts, so the UI is visually broken on Desktop and Mobile)
- **Repo / Area:** Frontend — Desktop & Mobile host bootstrapping (`src/ServiceDelivery.Client.Desktop/wwwroot/index.html`, `src/ServiceDelivery.Client.Mobile/wwwroot/index.html`)
- **Related stories:** `FE-001` (login screen), ADR-0007 (MudBlazor), `BUG-020` (same fix, Web host only)
- **Found:** Tracing the MAUI mobile startup→render chain after BUG-020/BUG-021. BUG-020 fixed only the **Web** host's `index.html`; each host has its own, and the two MAUI BlazorWebView hosts were never updated.

**Summary**
`BUG-020` added the MudBlazor stylesheet/font/JS to `ServiceDelivery.Client.Web/wwwroot/index.html`, but the Desktop and Mobile hosts each ship their **own** `wwwroot/index.html` (the BlazorWebView `HostPage`), and neither links `_content/MudBlazor/MudBlazor.min.css`/`.min.js` or the Roboto font. Services (`AddMudServices()`) and the providers in `MainLayout.razor` are wired on all hosts, but on Desktop/Mobile the static assets are absent, so every MudBlazor component renders unstyled — same defect class as BUG-020, just on the other two hosts.

**Root cause**
Per-host `index.html`: the BUG-020 fix was scoped to the Web host only and not propagated to the two MAUI hosts. Host-bootstrapping config, not component logic — no test covers it (hosts are bootstrapping-only per the frontend CLAUDE.md).

**Fix**
- In both `Desktop/wwwroot/index.html` and `Mobile/wwwroot/index.html`, add to `<head>`: the Roboto font and `<link href="_content/MudBlazor/MudBlazor.min.css" rel="stylesheet" />`; and after the `blazor.webview.js` script: `<script src="_content/MudBlazor/MudBlazor.min.js"></script>`.

**Acceptance criteria (bug resolved when):**
- Both the Desktop and Mobile host `index.html` reference `_content/MudBlazor/MudBlazor.min.css` and `.min.js` (matching the Web host).
- All three hosts are consistent in how they load MudBlazor's assets.
- The login screen renders styled when the Desktop or Mobile host is run (human-verified on a simulator/desktop window).
