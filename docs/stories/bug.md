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

- **Status:** **Fixed** 2026-06-24 (PR #32, `fix/BUG-024-session-expiry-handler-login-401`) — `SessionExpiryHttpHandler` gained a `/auth/login` path guard so a wrong-credential 401 passes through to the inline error, while authenticated-endpoint 401s still trigger session expiry. Covered by a regression unit test (`GivenA401ResponseFromLoginEndpoint_WhenSentThroughHandler_ThenResponseIsPassedThroughWithoutSessionExpiry`) and, since QUAL-007, a composition-root test asserting the same behaviour through the real `SessionExpiry → AuthToken → network` handler chain. (Status field flipped 2026-06-29 — the fix merged 2026-06-24 but this per-bug entry was missed at the time; the bug rollup already listed it resolved.)
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

- **Status:** **Fixed** 2026-06-24 — `_shellVersion` counter and `ShellVersion` parameter on `PersonaShell` added; see BUG-026 for follow-up correction to the lifecycle method.
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

## BUG-026 — `MainLayout` uses `OnInitializedAsync` instead of `OnParametersSetAsync`, so `Shell.Load` is never called on Blazor navigation from `/login`

- **Status:** **Fixed** 2026-06-24 — changed `OnInitializedAsync` to `OnParametersSetAsync` (guarded by `Shell.Menu is null`); all 8 Playwright E2E tests pass.
- **Severity:** High (BUG-025's fix shipped the `_shellVersion` counter increment inside `OnInitializedAsync`, which only runs once — when `MainLayout` first loads on `/login`. Blazor's Router reuses the layout instance across navigations and never calls `OnInitializedAsync` again, so `Shell.Load` was never reached in the normal login flow. The `persona-avatar` never appeared; all three `AppShellNavTests` E2E tests timed out.)
- **Repo / Area:** Frontend — `src/ServiceDelivery.Client.UI/Layout/MainLayout.razor`
- **Related stories:** `FE-021` (app shell + nav drawer), `QUAL-003` (Playwright E2E)
- **Found:** Running `test-e2e.sh` against the live web host (2026-06-24) after BUG-025 was merged — all three `AppShellNavTests` Playwright tests still timed out waiting for `[data-testid='persona-avatar']`. The unit test passed in CI because bUnit renders `MainLayout` directly on a non-login route, bypassing the login→navigate lifecycle entirely.

**Summary**

BUG-025 introduced `_shellVersion` as a counter parameter to force `PersonaShell` to re-render when the profile loads. The counter increment was placed inside `OnInitializedAsync`. When the E2E test opens `/login` first, `MainLayout` initialises with `IsLoginRoute = true` and skips the `Shell.Load` block entirely. After login, `NavigationManager.NavigateTo("/dispatcher")` is called by the app; the Router updates the `Body` parameter on the existing `MainLayout` instance and re-renders, but `OnInitializedAsync` is not called again. `Shell.Load` is never reached, `Menu` stays `null`, and `persona-avatar` never appears.

**Root cause**

`OnInitializedAsync` fires exactly once per component lifetime. In the E2E login flow the layout initialises on `/login`, so the `!IsLoginRoute` guard skips `Shell.Load`. The Blazor Router reuses the layout instance on navigation — it updates parameters (triggering `OnParametersSetAsync`) but does not re-initialise the component.

**Fix**

Replace `OnInitializedAsync` with `OnParametersSetAsync` and guard with `Shell.Menu is null` to avoid redundant calls:

```csharp
protected override async Task OnParametersSetAsync()
{
    if (!IsLoginRoute && Shell.Menu is null)
    {
        var profile = await AuthService.GetCurrentUserAsync();
        Shell.Load(profile);
        _shellVersion++;
    }
}
```

`OnParametersSetAsync` fires on every navigation (the Router updates `Body`), so the shell loads as soon as the user transitions to any authenticated route, regardless of where the app session started.

**Acceptance criteria (bug resolved when):**

- After logging in as `dispatcher1` via the normal login flow (starting at `/login`), the app bar shows the avatar (`[data-testid='persona-avatar']`) within 5 seconds
- All 8 Playwright E2E tests in `tests/ServiceDelivery.Client.E2E/` pass against a locally running system (`start.sh` up, web host running)

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

---

## BUG-027 — `GET /vehicles/available` returns only unclaimed vehicles, so the rep take-over list is always empty while the simulator runs

- **Status:** **Fixed** 2026-06-24 — `GetAvailableVehiclesQueryHandler` now returns vehicles that are unclaimed **or** claimed by an idle rep; added `RepStateRecord.IsOnActiveJob()` (domain) and reused it in `TakeOverVehicleCommandHandler` (DRY). Domain + handler + full backend suite green.
- **Severity:** High (the ServiceRep take-over screen — FE-007 — can never list a vehicle while the simulator is running, so a human can never take over; the entire mobile ServiceRep flow is unreachable end-to-end)
- **Repo / Area:** Backend — `src/ServiceDelivery.Application/Features/Vehicles/Queries/GetAvailableVehiclesQueryHandler.cs`
- **Related stories:** `FE-007` (take over an idle vehicle — supersedes the simulator), `BE-004` (`GET /vehicles/available`), ADR-0009 (human takeover)
- **Found:** Running `test-appium.sh` against the live system. `GET /vehicles/available` returned `[]` because the simulator claims all 8 vehicles at startup (fleet state showed `{Claimed: 8}`).

**Summary**
The handler called `GetUnclaimedByDealerIdAsync`, returning only vehicles with no `ClaimedByRepId`. But per ADR-0009 / FE-007 the human take-over **supersedes the simulator** on idle vehicles, and the simulator claims every vehicle at startup. So the "available" list was permanently empty and the take-over screen always showed "No idle vehicles available."

**Root cause**
Query semantics (`unclaimed only`) contradicted the command semantics: `TakeOverVehicleCommandHandler` already allows taking over a claimed vehicle as long as its rep is not on an active job. The read model never matched the write model.

**Fix**
- Added `RepStateRecord.IsOnActiveJob()` (true for `EnRoute`/`Within15Miles`/`OnSite`) in the domain.
- `GetAvailableVehiclesQueryHandler` now loads all dealer vehicles and includes each one that is unclaimed, or claimed by a rep with no state record, or claimed by a rep not on an active job.
- Refactored `TakeOverVehicleCommandHandler` to reuse `IsOnActiveJob()` instead of its private duplicate predicate.

**Acceptance criteria (bug resolved when):**
- With the simulator running and all vehicles claimed by idle reps, `GET /vehicles/available` returns the idle vehicles (verified: 8 returned).
- A vehicle whose rep is EnRoute/Within15Miles/OnSite is excluded.
- The take-over Appium test (`TakeOverTests`) reaches the idle view.

---

## BUG-028 — Frontend authenticated REST calls send no `Authorization` header (only `HttpAuthService` attached the JWT)

- **Status:** **Fixed** 2026-06-24 — added `AuthTokenHttpHandler` (a `DelegatingHandler`) that attaches the stored JWT as a Bearer header to every outbound request; registered in the Web/Desktop/Mobile pipelines ahead of the network handler. Unit tests added; full frontend suite green.
- **Severity:** High (every authenticated data call — `GET /vehicles/available`, take-over, job-offers, active-job — went out with no token → 401 → `GetFromJsonAsync` threw → a persistent "An unhandled error has occurred" after login; the app was unusable past the login screen)
- **Repo / Area:** Frontend — `src/ServiceDelivery.Client.UI/Features/Authentication/Services/AuthTokenHttpHandler.cs` (new) + host `HttpClient` registrations
- **Related stories:** `FE-007`, `FE-008`–`FE-011`, `FE-020` (all ServiceRep data screens), BUG-024 (same handler pipeline)
- **Found:** Running `test-appium.sh`; the post-login take-over screen showed a persistent error. Confirmed via curl: `GET /vehicles/available` returns 401 with no header, 200 with a Bearer token.

**Summary**
Only `HttpAuthService.GetCurrentUserAsync` attached a token (manually). No `DelegatingHandler` added the JWT to other requests, so every `Http*Service` (`HttpVehicleService`, `HttpJobOfferService`, `HttpDeclineOfferService`, `HttpActiveJobService`) called the API anonymously and got a 401.

**Root cause**
Missing cross-cutting auth handler. Each service used the shared `HttpClient`, but nothing in that client's pipeline injected the bearer token.

**Fix**
- New `AuthTokenHttpHandler` reads `ITokenStore.GetTokenAsync()` and sets `Authorization: Bearer <token>` when no header is already present (leaves explicit headers and the unauthenticated `/auth/login` call untouched).
- Wired into all three hosts: `SessionExpiryHttpHandler` → `AuthTokenHttpHandler` → `HttpClientHandler`.

**Acceptance criteria (bug resolved when):**
- Every authenticated REST call carries the Bearer token automatically (no per-call code).
- The post-login take-over / idle screens load their data without an error banner (verified: 4 Appium auth/navigation tests pass).

---

## BUG-029 — Frontend shows a brief "unhandled error" flash at startup before the login screen

- **Status:** **Fixed** 2026-06-24 — `MainLayout` shell-load is now resilient (try/catch), `SecureStorageTokenStore.GetTokenAsync` swallows the iOS first-launch Keychain race, and `AppStartViewModel` routes to login if the token store throws. Unit tests added; frontend suite green.
- **Severity:** Low/Medium (self-clears once the login screen renders, but it is a real unhandled exception and looks broken on every cold start)
- **Repo / Area:** Frontend — `MainLayout.razor`, `Services/SecureStorageTokenStore.cs` (Mobile), `Core/ViewModels/AppStartViewModel.cs`
- **Related stories:** `FE-001` (login), `FE-002` (JWT expiry), BUG-026 (same layout lifecycle)
- **Found:** Running the Mobile app under `test-appium.sh` and observed live on the simulator.

**Summary**
At the landing route `/`, `MainLayout` treats any non-`/login` route as authenticated and calls `GetCurrentUserAsync()`, which throws on the 401 (no token yet). Separately, `SecureStorage` can throw on first launch before the iOS Keychain is ready. Both surfaced as Blazor's "An unhandled error has occurred" until `Home.razor`'s redirect to `/login` cleared it.

**Root cause**
Unguarded `await` of an auth call during the pre-login layout/startup window.

**Fix**
- `MainLayout.OnParametersSetAsync` wraps the profile load in try/catch (let the redirect-to-login flow route the user).
- `SecureStorageTokenStore.GetTokenAsync` returns `null` on any SecureStorage exception.
- `AppStartViewModel.ResolveStartRouteAsync` returns the login route if the token store throws.

**Acceptance criteria (bug resolved when):**
- A cold launch with no session shows the login screen with no error banner.
- Unit tests cover the token-store-throws path in `AppStartViewModel` and the unauthenticated-startup path in `MainLayout`.

---

## BUG-030 — Frontend RepHub SignalR connection sends no access token, so the rep never receives pushed offers/redirects

- **Status:** **Fixed** 2026-06-24 — `SignalRRepHubService` now sets `HttpConnectionOptions.AccessTokenProvider` from `ITokenStore`, so SignalR appends `?access_token=…` when negotiating the `[Authorize]` RepHub. Unit tests added; frontend suite green.
- **Severity:** High (the RepHub is `[Authorize]`; an unauthenticated connection never joins its `rep:{userId}` group, so `JobOfferReceived` and `RedirectReceived` never arrive — the rep can never get a job offer in the UI)
- **Repo / Area:** Frontend — `src/ServiceDelivery.Client.UI/Features/ServiceRep/Services/SignalRRepHubService.cs`
- **Related stories:** `FE-008` (job offer), `FE-011` (active job redirect), `BE-025` (RepHub), BUG-028 (REST equivalent)
- **Found:** Auditing all outbound calls for the Authorization header (BUG-028 follow-up); the hub connection was built with `.WithUrl(hubUrl)` and no token.

**Summary**
The backend reads the SignalR token from `?access_token=` (websockets can't send an Authorization header) and the RepHub is `[Authorize(Roles="ServiceRep,Simulator")]`. The frontend never provided it, so the connection was rejected/anonymous and never joined the per-rep group.

**Fix**
`new HubConnectionBuilder().WithUrl(hubUrl, options => options.AccessTokenProvider = ProvideAccessTokenAsync)`, where `ProvideAccessTokenAsync` returns `ITokenStore.GetTokenAsync()`. `ITokenStore` is injected (already DI-registered in every host).

**Acceptance criteria (bug resolved when):**
- The RepHub connection carries the JWT as `?access_token=`.
- A unit test verifies the provider yields the stored token.

---

## BUG-031 — Appium E2E suite never ran against the app: multiple harness defects

- **Status:** **Fixed** 2026-06-24 — corrected all harness defects; the suite now drives the live app and **4/9 tests pass** (login, take-over, idle view, app-shell nav). The remaining 5 are tracked in BUG-032.
- **Severity:** High (the entire Appium suite — QUAL-004 — failed at the first step and had never actually exercised the app)
- **Repo / Area:** Central — `scripts/local/test-appium.sh`; Frontend — `tests/ServiceDelivery.Client.Appium/*`
- **Related stories:** `QUAL-004` (Appium suite), BUG-023 (same wrong-password class), ADR-0009
- **Found:** First real run of `test-appium.sh`.

**Summary & fixes (each a distinct defect):**
1. `test-appium.sh` `find -maxdepth 2` missed the `.app` (3 levels deep) → `-maxdepth 3`.
2. Default rep password was `Password1!`; seed is `Password123!` → corrected (same class as BUG-023).
3. Tests used `MobileBy.AccessibilityId`, but MAUI Blazor renders inside a `WKWebView` whose HTML is invisible to the native accessibility tree → switch to the `WEBVIEW` context in `SetUp` and use `By.CssSelector("[data-testid=…]")`.
4. Login used the username `rep1`; the API expects the email `rep1@dealer.com` → corrected.
5. `SendKeys` did not commit MudTextField's `@bind-Value` (it binds on the `change` event, which `SendKeys` doesn't raise) → `FillInput` dispatches `input`+`change` via JS (mirrors Playwright `FillAsync`), so login no longer submits empty/partial credentials ("Invalid email or password").
6. No test isolation: the JWT persists in the iOS Keychain across Appium's `noReset` sessions, auto-authenticating later tests → `SetUp` now terminates+relaunches the app and runs `EnsureLoggedOut` (drives the app's own logout) so each test starts logged out.
7. The drawer logout item is a MudNavLink whose click handler sits on the inner `.mud-nav-link`, not the `data-testid` wrapper → click the inner element.
8. Added an optional `--filter` passthrough to `test-appium.sh` for single-class runs.

**Acceptance criteria (bug resolved when):**
- `test-appium.sh` builds, installs, and drives the app, locating elements by `data-testid` in the WEBVIEW context.
- The auth/navigation tests (login → take over → idle → app-shell nav) pass (4/9).

---

## BUG-032 — Appium job-offer tests have no service-request precondition; JwtExpiry test is a documented platform limitation

- **Status:** **Fixed** 2026-06-25 (frontend PR #39 + central scripts) — the Appium suite now runs **backend-only** (`SD_SKIP_SIMULATOR=1`, central `start.sh`/`test-appium.sh`) so the human-taken-over rep is the sole match candidate, and a new `BackendApiHelper` establishes the offer precondition: it **positions the dealer fleet** (as the seeded `Simulator` account, via `GET /simulator/fleet-state` + `POST /vehicles/{id}/position`) then submits one Gold-tier request for DTC-001 at the same site. The fleet-positioning step was the missing piece — matching ignores vehicles with no position (`GetAvailableByDealerAsync` inner-joins on `LastLatitude/LastLongitude != null`), and a backend-only run has no simulator posting positions, so earlier "submit a request" attempts found zero candidates and timed out (verified by API repro before the fix). The JwtExpiry test is `[Ignore]`d with the documented Keychain limitation. **Verified live on the iOS simulator: 8 passed, 1 skipped, 0 failed (was 4/9).**
- **Severity:** Medium (5 of the 9 Appium tests cannot pass as written; the underlying app flows work, but the tests lack the data setup to exercise them)
- **Repo / Area:** Frontend — `tests/ServiceDelivery.Client.Appium/{JobOfferTests,ActiveJobTests,JwtExpiryTests}.cs`
- **Related stories:** `QUAL-004`, `BE-014` (matching → job offer), `FE-008`/`FE-011`
- **Found:** Full Appium run after BUG-027–031 fixes (4/9 passing).

**Summary**
The 4 job-offer/active-job tests take over a vehicle and then wait for a `JobOfferReceived` push, but **nothing creates a service request** (the simulator does not submit requests, and there are 0 open requests), so no offer is ever generated and the tests time out after 15s. The `JwtExpiryTests` case relies on `ExpireStoredToken()`, which is a documented no-op because the iOS Keychain token is not reachable from the WebView DOM.

**Proposed fix (follow-up)**
- Job-offer tests: add an Arrange step that submits a matching service request (Requester token) positioned to route to the taken-over rep — or introduce a deterministic test-support seed/endpoint so matching reliably targets that rep. Requires care given the simulator continuously moves vehicles.
- JwtExpiry test: wire a real expiry trigger (debug deep link to clear the Keychain token, or a backend signing-key rotation), or mark `[Ignore]` with the documented reason until such a hook exists.

**Acceptance criteria (bug resolved when):**
- A job offer is reliably pushed to the taken-over rep in the test, and the accept/decline/active-job assertions pass.
- The JWT-expiry scenario is either driven by a real expiry trigger or explicitly skipped with a recorded reason.

---

## BUG-033 — Rep take-over page renders unstyled (missing scoped CSS); minor idle-page app-bar fidelity gaps

- **Status:** **Fixed** 2026-06-24 (PR #36, via `/master`) — added scoped CSS for the take-over list (bordered card, styled rows, equipment chips + friendly labels) plus a bounded scrollable list region keeping the CTA visible; idle vehicle card is now a white card with a horizontal icon-left row; app bar shows the "Vehicle … · On shift" subtitle and equal-size translucent-circle hamburger + persona avatar. All visually verified on the simulator; 207 frontend unit tests green. (The take-over rows still show registration only, not model/loop — Gap 4 was out of scope; folded into BUG-034.)
- **Severity:** Medium (the take-over screen — the first authenticated ServiceRep screen — looks broken: cramped, unstyled rows with run-together equipment text; the idle screen is close but the app bar differs from the mockup)
- **Repo / Area:** Frontend — `src/ServiceDelivery.Client.UI/Features/ServiceRep/Components/IdleVehicleList.razor` (+ a new scoped `.razor.css`), `Features/ServiceRep/Pages/TakeOver.razor`; shared `Shared/Components/PersonaShell.razor` for the app-bar fidelity
- **Related stories:** `FE-007` (take-over screen), `FE-020` (idle view), `BUG-021` (login mockup fidelity — same class of fix)
- **Found:** Comparing the live Mobile app against `docs/ui-mockups/images/rep-takeover__mobile-390x844.png` and `rep-idle__mobile-390x844.png` (captured via the now-working Appium harness).

**Summary**
The app styles each page with **scoped CSS** (`Login.razor.css`, `RepIdle.razor.css`, `JobOffer.razor.css`, `ActiveJob.razor.css`). `IdleVehicleList.razor` (the take-over list) and `TakeOver.razor` have **no** `.razor.css`, so the `sd-card` / `sd-listitem` / `sd-equip` classes they use are undefined for those components (the matching rules in `RepIdle.razor.css` are Blazor-scoped to RepIdle and do not apply elsewhere). The take-over list therefore renders as raw HTML.

**Take-over page gaps (vs mockup):**
1. List is unstyled — no bordered card container, no row layout/spacing; rows are cramped. (Root cause: no scoped CSS for `IdleVehicleList`.)
2. Equipment renders as run-together raw text ("HydraulicToolElectricalDiagnosticKit+4") instead of spaced chips ("Hydraulics", "Coolant", "+4").
3. Equipment uses raw enum names (`HydraulicTool`) instead of friendly labels (`Hydraulics`). Needs a label map (frontend) since the DTO returns enum names.
4. Each row lacks the vehicle model and a "loop · idle" subtitle (mockup: "IA-4471 · Transit 350" / "Des Moines loop · idle"). `IdleVehicle`/`AvailableVehicleDto` carry only registration + equipment — surfacing model/loop needs a backend DTO addition (separate, optional).
5. App bar shows "Service Delivery / Service Rep" + hamburger only; mockup shows "Take Over a Vehicle / Signed in as Rep 3" + an "R3" avatar.

**Idle page gaps (vs mockup):** the body conforms well (green check, "You're available", Available pill, vehicle card). Remaining:
1. App-bar subtitle should read "Vehicle IA-4471 · On shift" (currently "Service Rep").
2. App bar is missing the persona avatar (mockup shows "RA" alongside the hamburger).

**Proposed fix (via `/master`)**
- Add scoped CSS for the take-over list (new `IdleVehicleList.razor.css` and/or `TakeOver.razor.css`) matching the card/row/chip styling already proven in `RepIdle.razor.css`; render equipment as chips with a friendly-label map.
- Align the PersonaShell app bar (title/subtitle + avatar) with the rep mockups.
- (Optional, separate) extend `AvailableVehicleDto`/`IdleVehicle` with model + home-loop so rows can show "IA-4471 · Transit 350" / "Des Moines loop · idle".

**Acceptance criteria (bug resolved when):**
- The take-over list renders as a bordered card with styled rows and equipment chips, matching `rep-takeover__mobile-390x844.png` (human-verified on the simulator).
- The idle app bar shows the vehicle/"On shift" subtitle and the persona avatar, matching `rep-idle__mobile-390x844.png`.
- bUnit tests cover `IdleVehicleList` rendering equipment as chips with the friendly labels and overflow count.

---

## BUG-034 — Idle view (card + app-bar subtitle) shows a hardcoded vehicle, not the one the rep took over

- **Status:** **Fixed** 2026-06-24 (PR #37, via `/master`) — added a scoped `IClaimedVehicleStore` (mirrors `IJobOfferStore`): `TakeOverViewModel` deposits the selected vehicle on success, `RepIdleViewModel` reads-and-clears it; the hardcoded `ClaimedVehicle("IA-4471")` stub is removed and the store registered in all 3 hosts. The idle card and app-bar subtitle now show the actually-taken-over vehicle (empty-store degrades to a neutral vehicle, no NRE). Folded in a Checkpoint #2 fix: extracted the friendly equipment-label map to a shared Core `EquipmentLabels` helper used by both the take-over list and the idle card. Simulator-verified (take over V-001 → card "V-001" + friendly labels, subtitle "Vehicle V-001 · On shift"); 235 frontend unit tests green. Model deferred to [[BUG-035]].
- **Severity:** High (after taking over vehicle **V-001**, the idle screen and the app-bar subtitle both show **"IA-4471 · Transit 350"** — a hardcoded demo vehicle. The rep sees the wrong vehicle for their entire shift; misleading in the core ServiceRep flow.)
- **Repo / Area:** Frontend — `src/ServiceDelivery.Client.Mobile/MauiProgram.cs` (hardcoded `ClaimedVehicle` registration), `Core/ViewModels/TakeOverViewModel.cs` + `RepIdleViewModel.cs`, `Features/Authentication/Services/BlazorPersonaNavigator.cs`, `Features/ServiceRep/Pages/RepIdle.razor`. Likely also Backend — `AvailableVehicleDto` / a claimed-vehicle read endpoint (for the model field).
- **Related stories:** `FE-007` (take-over), `FE-020` (idle view), `BUG-033` (idle/take-over fidelity — folds in its Gap 4: model/loop subtitle)
- **Found:** Running the Appium take-over flow — selected V-001 but the idle page rendered IA-4471.

**Summary**
`RepIdleViewModel.Vehicle` is injected from a hardcoded `ClaimedVehicle(Guid.Empty, "IA-4471", "Transit 350", …)` registered in `MauiProgram.cs`. The take-over flow never carries the selected vehicle forward — `BlazorPersonaNavigator.NavigateToRepIdleView()` takes no arguments and `TakeOverResult` is success/conflict only. So the idle screen always shows the demo truck regardless of what was taken over. This was a documented POC shortcut in FE-020 ("wiring the real take-over hand-off … is a follow-on"). Because `RepIdle.razor` builds the app-bar subtitle from the same `ViewModel.Vehicle` (`Shell.SetVehicleContext($"Vehicle {reg} · On shift")`), the **subtitle under "Service Delivery" is wrong too** — it must show the selected vehicle.

**Root cause**
No hand-off of the claimed vehicle from take-over to the idle view; the idle VM depends on a static stub. Additionally, the available-vehicle data the take-over screen has (`IdleVehicle`: registration + equipment) lacks the **model** ("Transit 350"), so showing the full "reg · model" needs the model surfaced too.

**Proposed fix (via `/master`)**
- Carry the selected vehicle from `TakeOverViewModel` to the idle view — either a shared scoped store (mirroring the existing `IJobOfferStore` hand-off pattern) populated on successful take-over, or have the idle view fetch the rep's claimed vehicle from the backend.
- Drive both the idle vehicle **card** and the **app-bar subtitle** ("Vehicle <reg> · On shift") from the real claimed vehicle.
- Surface the vehicle **model** so the card/subtitle can show "<reg> · <model>": add `model` to `AvailableVehicleDto`/`IdleVehicle` (backend) or to a claimed-vehicle read endpoint. (Subsumes BUG-033 Gap 4.)
- Remove the hardcoded `ClaimedVehicle` DI registration once the real hand-off exists.

**Acceptance criteria (bug resolved when):**
- After taking over a specific vehicle, the idle view's vehicle card shows that vehicle's registration (and model, once surfaced) — not a hardcoded one.
- The app-bar subtitle reads "Vehicle <selected-reg> · On shift" for the vehicle actually taken over.
- The hardcoded `ClaimedVehicle` stub is gone.
- Unit tests cover the take-over→idle hand-off (the idle VM reflects the selected vehicle) and the subtitle derivation.

> **Scope note (2026-06-24):** split during `/master`. The **model** sub-clause is deferred to **BUG-035** (needs a backend DTO field). BUG-034 ships the frontend registration hand-off (card + subtitle show the real vehicle's registration + equipment, stub removed).

---

## BUG-035 — `AvailableVehicleDto` carries no vehicle model, so the rep idle card can't show "<reg> · <model>"

- **Status:** **Fixed** 2026-06-24 (backend PR #47 + frontend PR #38, both via `/master`) — backend half added `Model` to the `Vehicle` entity + seed data, `AvailableVehicleDto`, and the handler (`GET /vehicles/available` now returns each vehicle's model). Frontend half added `Model` to `IdleVehicle` (bound by `[JsonPropertyName("model")]`), routed it through the take-over hand-off (`TakeOverViewModel` no longer hardcodes empty), and renders "<reg> · <model>" with an empty-guard in both the take-over rows (`IdleVehicleList.razor`) and the idle card (`RepIdle.razor`, already wired). The BUG-034 deferral masking test (`...ThenStoredModelIsEmptyString`) was deleted and replaced with a real-value assertion. 549 backend + 241 frontend unit tests green. AI Review was BLOCKED solely on a missing Appium scenario for the new title; developer-overridden because the `"<reg> · <model>"` render is fully covered by a bUnit component test and so needs no E2E scenario under the lowest-sufficient-level rule (the BLOCK exposed the old mechanical E2E gate — since corrected in `story-ai-reviewer` + `test-quality`). The 4/9 Appium baseline is unchanged; the 5 failing tests are the pre-existing, unrelated [[BUG-032]] precondition defects.
- **Severity:** Low (cosmetic — the idle card and take-over rows show registration + equipment but not the model "Transit 350" the mockups depict; no functional impact)
- **Repo / Area:** Backend — `src/ServiceDelivery.Application/Features/Vehicles/Queries/GetAvailableVehiclesQuery.cs` (`AvailableVehicleDto`) and its handler; the `Vehicle` entity / seed data must carry a model. Then Frontend — add `Model` to `IdleVehicle`/`ClaimedVehicle` and render "<reg> · <model>".
- **Related stories:** `BUG-033` (Gap 4), `BUG-034` (registration hand-off — this surfaces the model that BUG-034 deferred), `BE-004` (`GET /vehicles/available`), `FE-007`/`FE-020`
- **Found:** During BUG-034 evaluation — `AvailableVehicleDto` is `(Guid VehicleId, string Registration, IReadOnlyList<string> Equipment)`; no model field, so a frontend-only fix can't show the model (it would deserialize null).

**Summary**
The take-over list and idle card show "V-001" but the mockups show "IA-4471 · Transit 350". The model is not in the backend DTO or the frontend model, so it cannot be displayed without a backend change. Deferred from BUG-034 (which is frontend-only).

**Proposed fix (via `/master`)**
- Ensure the `Vehicle` entity / seed data has a model (e.g. "Transit 350", "Sprinter").
- Add `Model` to `AvailableVehicleDto` and emit it from `GetAvailableVehiclesQueryHandler`.
- Add `Model` to the frontend `IdleVehicle` (and `ClaimedVehicle`); render "<reg> · <model>" in the take-over rows and the idle card.

**Acceptance criteria (bug resolved when):**
- `GET /vehicles/available` returns each vehicle's model.
- The take-over rows and the idle card show "<registration> · <model>" matching the mockups.
- Backend + frontend unit tests cover the new field end to end.

---

## BUG-036 — Job-offer screen: tier badge is invisible, plus app-bar / card fidelity gaps vs the rep mockup

- **Status:** **Fixed** 2026-06-26 (frontend PR #45, via `/master`) — root cause was a wire-contract mismatch on the RepHub `JobOfferReceived` event: the backend sends `RequesterTier` (enum-name string), `Latitude`/`Longitude`, and `EtaMinutes` (double), but the event was deserialized straight into `JobOfferPayload` (`Tier`/`Lat`/`Lng`, `EtaMinutes` int). System.Text.Json matched by name, so `Tier` fell back to `None` → `.sd-badge` got no colour modifier → white-on-white invisible badge (AC-1), and `Lat`/`Lng` fell back to `0` → broken map pin. Fix: a `JobOfferReceivedWirePayload` DTO (Core) mirrors the backend names/types and `ToJobOfferPayload()` parses the tier (case-insensitive) and rounds the ETA; mapped at the SignalR boundary in `SignalRRepHubService` (`JobOfferPayload` unchanged). Also: wrapped the requester/tier/fault/metrics block in an elevated `.sd-card` (AC-3); the offer route sets app-bar chrome on init — title "Incoming Job Offer", hidden hamburger, drops RepIdle's "· On shift" subtitle suffix — and restores it on dispose (AC-2/AC-4) via new `ShellViewModel.Title`/`SetTitle` + `IsMenuAffordanceVisible`/`SetMenuAffordanceVisible` (both default to current behaviour). 280 unit/bUnit green; **live Appium `JobOfferTests` 4/4** on the iPhone 17 Pro confirmed a visible GOLD pill. **AC-5** satisfied by this note: the mockup's "P0700 ·" DTC prefix is **non-authoritative** — `persona-views.md` mandates human-readable titles with **no technical codes**, so the implementation ("Hydraulic system fault") is correct and future fidelity checks should not re-flag the missing code; the PNG itself is left as-is. *(Scope note: `DistanceMiles` and `EtaMinutes` share the same field name across both contracts, so they were never zeroed by the mismatch — `DistanceMiles` always deserialized correctly; the `EtaMinutes` double→int change only hardens against a fractional ETA, which would previously have thrown. The "0.0 MILES / 0 MIN ETA" seen in captures is the co-located-test-data artifact noted below, not a defect.)*
- **Severity:** High (the Gold/Silver/Bronze tier badge — the visual anchor of the whole priority system — does not render visibly on the offer screen; supporting fidelity gaps are Medium/Low)
- **Repo / Area:** Frontend — `src/ServiceDelivery.Client.UI/Features/ServiceRep/Pages/JobOffer.razor` (+ its scoped `JobOffer.razor.css`), the `JobOfferReceived` SignalR deserialization in `SignalRRepHubService` / the `JobOfferPayload.Tier` contract, and the `PersonaShell` app-bar context on this route.
- **Related stories:** `FE-008` (job-offer screen), `FE-009`/`FE-010` (accept/decline), `BE-017`/`BE-019` (RepHub `JobOfferReceived` event), `BUG-033`/`BUG-034`/`BUG-035` (same class — rep-screen mockup fidelity)
- **Found:** Comparing the live iOS-simulator offer screen against [`docs/ui-mockups/images/rep-job-offer__mobile-390x844.png`](../ui-mockups/images/rep-job-offer__mobile-390x844.png). Confirmed on a **clean rebuild** via the Appium `JobOfferTests` flow with `SD_SHOT_DIR` set (so it is not a stale deploy).

**Summary**
On the rendered offer screen the service tier badge does not appear at all. `JobOffer.razor:38–40` always emits `<span class="sd-badge @TierBadgeClass">★<TIER></span>`, but on the device the requester line reads only "Gold User 1" with no `★ GOLD` pill — even though the offer is genuinely Gold tier (the Appium scenario submits a Gold request from "Gold User 1"). Scoped CSS is otherwise loading (the countdown ring, metric tiles, and green Accept button are all styled), so this is not a missing-stylesheet bundle. Alongside the badge, the screen diverges from the mockup on the app bar and content grouping.

**Likely root cause (badge)**
`.sd-badge` (scoped) sets `color:#fff` with **no default background**; the coloured background comes only from the `--gold`/`--silver`/`--bronze` modifier, which `TierBadgeClass` applies only when `_viewModel.Tier` is a real tier. `ServiceTier` is `None, Bronze, Silver, Gold`. If `Tier` arrives as `None` (e.g. an enum string-vs-number mismatch between the backend `RepHub` event and the frontend `HubConnection` JSON protocol, or any deserialization fallback to default `0`), then `TierBadgeClass` is empty → no background → **white star + white text on a white page = invisible badge**. The TDD pipeline should confirm the actual `Tier` wire value first, then fix the deserialization and/or make the badge robust (a real tier must always produce a visible, coloured pill).

**Findings (each is an AC below)**
1. **Tier badge invisible (primary).** A Gold offer must render a visible Gold pill (`★ GOLD`); Silver/Bronze likewise. The badge must never be white-on-white for a real tier.
2. **Stale "· On shift" subtitle.** `JobOffer.razor` never sets its own shell context, so `PersonaShell` shows whatever `RepIdle.razor` last set (`Vehicle V-001 · On shift`). The offer screen should not claim the rep is "On shift" — it should show vehicle context appropriate to an incoming offer (or no stale suffix).
3. **No elevated content card.** The mockup groups requester / tier / fault / metrics inside a white elevated card; `JobOffer.razor` uses `.sd-card__title`/`.sd-card__body` but has **no `.sd-card` container**, so the content sits flat on the page.
4. **App-bar title divergence (fidelity).** The mockup app bar reads "Incoming Job Offer" with a vehicle subtitle and **no** menu/close affordance; the live screen shows PersonaShell's generic "Service Delivery" title plus a hamburger and avatar. `persona-views.md` does not mandate a custom header, so this is a mockup-fidelity gap, not a spec violation — confirm intended chrome before changing PersonaShell behaviour for this route.

**Explicitly NOT in scope / not defects**
- **DTC code prefix.** The mockup shows "P0700 · Transmission Control Fault", but `persona-views.md` (Job Offer Screen, and §"DTC dropdown … no technical codes shown") specifies **human-readable titles with no technical codes**. The implementation ("Hydraulic system fault") is correct; the **mockup is the outlier** — fix the mockup, do not add a code to the UI.
- **`0.0 MILES` / `0 MIN ETA` in the screenshot.** Distance/ETA were zero in the capture, but the Appium scenario's positioning makes this a test-data artifact, not a confirmed compute defect. Note only; verify distance/ETA populate for a positioned vehicle but do not assume a bug.

**Proposed fix (via `/master`)**
- Reproduce the `Tier` value arriving on `JobOfferReceived` (failing test), then correct the enum (de)serialization so a Gold offer yields `ServiceTier.Gold`; harden `.sd-badge` so a real tier always renders a visible coloured pill.
- Have `JobOffer.razor` set an appropriate shell context (or clear the stale "· On shift" suffix) on init.
- Wrap the requester/tier/fault/metrics block in an elevated `.sd-card` matching the mockup.
- Reconcile the app-bar title/chrome with the intended design (confirm whether the offer route should override PersonaShell's title and suppress the menu).

**Acceptance criteria (bug resolved when):**
- A Gold (resp. Silver, Bronze) job offer renders a visible, correctly-coloured tier pill with the tier label — verified by a component/bUnit test asserting both the tier text and the applied modifier class, and by a fresh Appium screenshot showing the pill.
- The offer screen no longer shows a stale "· On shift" subtitle.
- The requester/tier/fault/metrics content is grouped in an elevated card consistent with the mockup.
- The app-bar chrome on `/rep/offer` matches the agreed design.
- The mockup `rep-job-offer__mobile-390x844.png` is corrected to drop the "P0700 ·" DTC code (or a note recorded that it is non-authoritative), so future fidelity checks don't re-flag a non-defect.

---

## BUG-037 — Frontend ignores the `JobOfferExpired` RepHub event; the offer screen only clears on its own local countdown

- **Status:** **Open**
- **Severity:** Medium (the offer screen self-clears when its local 60 s timer runs out, so the rep is never *permanently* stuck — but until then they sit on an offer the backend has already retired, and can accept it only to hit a 409. The push that should dismiss it immediately is dropped on the floor.)
- **Repo / Area:** Frontend — `src/ServiceDelivery.Client.Core/Interfaces/IRepHubService.cs`, `src/ServiceDelivery.Client.UI/Features/ServiceRep/Services/SignalRRepHubService.cs`, `Core/ViewModels/JobOfferViewModel.cs`, `Features/ServiceRep/Pages/JobOffer.razor`
- **Related stories:** `FE-008` (job-offer screen), `FE-009`/`FE-010` (accept/decline), `BE-018` (offer expiry / `ExpiredJobOfferSweeper`), `BE-025` (RepHub event catalogue), `BUG-030` (RepHub auth — same hub wiring)
- **Found:** Tracing the RepHub event catalogue end-to-end — the backend publishes four client events but the frontend hub service registers handlers for only two.

**Summary**
The backend's `RepHubService.SendJobOfferExpiredAsync` (`service-delivery-backend/src/ServiceDelivery.Api/Services/RepHubService.cs:21`) sends a **`"JobOfferExpired"`** client event with payload `JobOfferExpiredPayload(Guid OfferId)` whenever the background `ExpiredJobOfferSweeper` transitions a pending offer to `Expired` (`.../Application/Common/Services/ExpiredJobOfferSweeper.cs:92`). The frontend never subscribes to it. `IRepHubService` declares only `OnJobOfferReceived` and `OnRedirectReceived`, and `SignalRRepHubService` registers `.On<>(…)` only for `"JobOfferReceived"` and `"RedirectReceived"` (`SignalRRepHubService.cs:44,47`). There is **no** `OnJobOfferExpired` registration, so the event is silently discarded by the SignalR client.

The offer screen instead relies entirely on a **client-side 60 s countdown** in `JobOfferViewModel.TickAsync` (`JobOfferViewModel.cs:81–99`): when `SecondsRemaining` hits 0 it calls `NavigateToRepIdleView()`. The only other expiry path is a 409 on accept, which sets `ErrorMessage = "Offer expired"` and routes to idle. Server-driven expiry never reaches the UI.

**Expected**
When the backend pushes `JobOfferExpired` for the offer currently on screen, the rep's device dismisses the offer immediately — stop the countdown and return to the idle/take-over view — rather than waiting out its local timer.

**Actual**
The `JobOfferExpired` event has no registered handler, so it is dropped. The rep keeps staring at an offer the server has already retired until the local 60 s countdown elapses; if they tap **Accept** in that window they get a 409 instead of a clean dismissal. The backend even logs this as an expected fallback: *"countdown UI will fall back to its own timeout"* (`ExpiredJobOfferSweeper.cs:105`).

**Root cause**
Incomplete RepHub event coverage on the frontend: the hub-service contract (`IRepHubService`) and its SignalR implementation were wired for `JobOfferReceived` + `RedirectReceived` only, omitting the catalogued `JobOfferExpired` event. The offer screen was built around a local timer as the sole expiry mechanism, with no path for a server-pushed expiry.

**Proposed fix (via `/master`)**
- Add a frontend `JobOfferExpiredPayload` (carrying `OfferId`) mirroring the backend contract, and an `OnJobOfferExpired(Func<JobOfferExpiredPayload, Task>)` registration to `IRepHubService`.
- Implement it in `SignalRRepHubService` as `_connection.On<JobOfferExpiredPayload>("JobOfferExpired", …)`.
- Have the offer screen / `JobOfferViewModel` react: when an expiry arrives **for the offer currently displayed** (match on `OfferId`), stop the countdown timer and navigate back to the idle view (reuse the existing `NavigateToRepIdleView()` path). Ignore expiries whose `OfferId` does not match the on-screen offer so a stale push can't dismiss a newer offer.
- Keep the local countdown as a fallback (network-loss safety), so behaviour degrades to today's timeout if the event is missed.

**Acceptance criteria (bug resolved when):**
- `IRepHubService` exposes an `OnJobOfferExpired` registration and `SignalRRepHubService` registers a `"JobOfferExpired"` handler (a unit test asserts the handler is wired and invokes the callback with the deserialized `OfferId`).
- When a `JobOfferExpired` event arrives for the offer on screen, the countdown is stopped and the rep is returned to the idle/take-over view — verified by a `JobOfferViewModel` unit test (offer dismissed, navigation invoked) without relying on the 60 s timer.
- An expiry event whose `OfferId` does not match the current offer is ignored (covered by a test).
- The existing local-countdown fallback still returns the rep to idle if no event arrives (existing tests stay green).

## BUG-038 — Idle screen raises an unhandled-error banner when the RepHub SignalR connection can't be established

- **Status:** **Fixed** 2026-06-27 (frontend PR #48, via `/master`) — made the RepHub connect resilient: `SignalRRepHubService.StartAsync` now catches a failed initial connect and runs a bounded exponential-backoff retry (5 attempts) on a cancellable background task behind an injectable test seam; added `IRepHubService.IsConnected`; `RepIdleViewModel.StartAsync` swallows-and-logs; `RepIdle.OnInitializedAsync` has a defensive guard plus a "Reconnecting…" indicator. AI Review BLOCKED at cycle 1 on a masking-test finding (the retry loop had no guarding assertion) and approved at cycle 2 after the loop was put behind a seam and covered by a red-without-the-loop service test. The component repro test `GivenRepHubStartThrows_WhenRepIdleComponentInitialised_ThenNoExceptionEscapesAndComponentRenders` was verified to fail on the pre-fix code and pass after. 297 frontend unit tests green.
- **Severity:** Medium (the rep sees Blazor's red *"An unhandled error has occurred. Reload"* banner and the screen stops working until a manual reload — no live job offers arrive — whenever RepHub is unreachable at the moment the idle screen mounts. It is not data loss, but it is a visible app failure with no recovery short of reloading.)
- **Repo / Area:** Frontend — `src/ServiceDelivery.Client.UI/Features/ServiceRep/Pages/RepIdle.razor` (`OnInitializedAsync`), `Core/ViewModels/RepIdleViewModel.cs` (`StartAsync`), `src/ServiceDelivery.Client.UI/Features/ServiceRep/Services/SignalRRepHubService.cs` (`StartAsync`), `Core/Interfaces/IRepHubService.cs`
- **Related stories:** `FE-020` (idle / waiting-for-offers view), `FE-008` (job-offer screen — the expiry path that re-mounts idle), `BE-025` (RepHub event catalogue), `BUG-030` (RepHub auth — same hub wiring), `BUG-037` (offer-expiry event handling — adjacent RepHub gap)
- **Found:** Live debugging on an iOS simulator — after the Appium suite finished and `stop.sh` tore down the backend, a leftover offer's client-side countdown hit zero, `JobOfferViewModel.TickAsync` navigated to the idle view, and the idle screen rendered with the *"An unhandled error has occurred."* banner. The error lives in the Blazor/WebView layer (not the native app process), so a unified-log scan of the app process alone does not surface it.

**Summary**
When the rep idle view mounts, `RepIdle.OnInitializedAsync` (`RepIdle.razor:68`) awaits `RepIdleViewModel.StartAsync()` (`RepIdleViewModel.cs:43`), which calls `_repHub.StartAsync()`. `SignalRRepHubService.StartAsync()` is a bare `_connection.StartAsync()` with **no error handling** (`SignalRRepHubService.cs:49`). The connection is built `.WithAutomaticReconnect()` (`SignalRRepHubService.cs:31`), but automatic reconnect **does not cover the *initial* connect** — it only retries after an already-established connection drops. So if the backend / RepHub is unreachable on the first connect, `StartAsync()` throws (e.g. connection refused), and because `OnInitializedAsync` has no `try/catch`, the exception propagates uncaught and Blazor renders the `#blazor-error-ui` banner.

**Reproduction (deterministic):** be on the job-offer screen and let the 60 s countdown reach zero (`JobOfferViewModel.TickAsync` → `NavigateToRepIdleView()`, `JobOfferViewModel.cs:95`) while RepHub is unreachable. The idle screen re-mounts, re-opens the hub connection, the connect fails, and the banner appears. Killing the backend right before expiry (as the Appium teardown does) is the cleanest way to trigger it, but any RepHub-unreachable moment does it — backend restart, a network blip, or macOS idle-sleep dropping the websocket (cf. the local-SignalR-host-sleep failure mode).

**Expected**
A momentarily unreachable RepHub should degrade gracefully: the idle screen still renders the Available state and the claimed-vehicle card, surfaces an unobtrusive "connecting…/offline" indicator if anything, and keeps trying to connect — so that once the backend is reachable, job offers flow again. No unhandled-error banner.

**Actual**
The initial `StartAsync()` failure bubbles out of `OnInitializedAsync` as an unhandled exception; Blazor shows *"An unhandled error has occurred. Reload"* and the rep gets no live offers until they reload the app.

**Root cause**
The RepHub connection start is unguarded, and `WithAutomaticReconnect()` is relied on for resilience it does not provide (it excludes the initial connect). Neither `SignalRRepHubService.StartAsync`, `RepIdleViewModel.StartAsync`, nor `RepIdle.OnInitializedAsync` catches a connect failure, so a transient backend outage becomes a fatal UI error.

**Proposed fix (via `/master`)**
- Make the RepHub connect resilient: catch the initial-connect failure in `SignalRRepHubService.StartAsync` (or in `RepIdleViewModel.StartAsync`) and retry with backoff rather than letting it throw — `WithAutomaticReconnect()` only handles drops *after* a successful connect, so the initial attempt needs its own retry loop.
- Surface connection state to the UI (e.g. an `IRepHubService` connection-state callback / property) so the idle screen can show a non-fatal "reconnecting…" indicator instead of throwing; the screen must still render the Available state + claimed-vehicle card while disconnected.
- Ensure `RepIdle.OnInitializedAsync` never lets a hub-connection exception escape (defensive `try/catch` around `StartAsync` with logging) so component init can't trip `#blazor-error-ui`.

**Acceptance criteria (bug resolved when):**
- Mounting `/rep/idle` while RepHub is unreachable does **not** raise an unhandled exception and does **not** render the Blazor `#blazor-error-ui` banner — verified by a `RepIdleViewModel`/component test where `IRepHubService.StartAsync` throws and `StartAsync`/`OnInitializedAsync` swallow-and-log it.
- The idle screen still renders the Available state and the claimed-vehicle card when the hub is down (existing idle-view tests stay green).
- When RepHub becomes reachable again, the connection is (re)established and a subsequent `JobOfferReceived` is handled — the connect path retries rather than giving up after one failure (covered by a test).
- The happy path (hub reachable on first connect) is unchanged and its existing tests stay green.

## BUG-039 — Active-job screen doesn't match the rep mockup (app-bar title, ETA card distance + placement, En Route chip style)

- **Status:** **Open**
- **Severity:** Low/Medium (the screen is functional — the map, route line, ETA, state chip, and the "I've Arrived"/"Mark Complete" actions all work — but its presentation diverges from the `rep-active-job` mockup on several points, the most user-visible being a missing distance on the ETA card and a generic app-bar title.)
- **Repo / Area:** Frontend — `src/ServiceDelivery.Client.UI/Features/ServiceRep/Pages/ActiveJob.razor`, `ActiveJob.razor.css`, `Core/ViewModels/ActiveJobViewModel.cs`, `Core/Models/ActiveJobContext.cs` (distance), and the shared `PersonaShell` title/subtitle wiring
- **Related stories:** `FE-011` (active-job navigation view), `FE-012` (mark-arrived / on-site), `FE-021` (PersonaShell chrome), `BUG-033`/`BUG-036` (same class — rep-screen mockup fidelity), `BUG-035` (precedent for surfacing a value through the active-job DTO)
- **Found:** Comparing the live active-job screen to `docs/ui-mockups/images/rep-active-job__mobile-390x844.png`. Gaps confirmed by reading `ActiveJob.razor` / `ActiveJob.razor.css` and `ActiveJobViewModel`/`ActiveJobContext` (no live render captured — the local stack was down).

**Summary**
The active-job screen (`/rep/job`) renders the right elements but diverges from the mockup on four points:

1. **App-bar title/subtitle is generic.** The mockup app bar reads **"Active Job"** with the subtitle **"Navigating to requester"**. `ActiveJob.razor` never sets a shell title/subtitle (unlike `RepIdle.razor`, which calls `Shell.SetVehicleContext`), so PersonaShell shows its default chrome. (Same class as the BUG-036 "PersonaShell's generic title vs the mockup" gap.)
2. **ETA card omits the distance.** The mockup card reads **"9 min / ETA · 8.1 MI"**; the current card (`.sd-eta`, `data-testid="eta-card"`) renders only `@ViewModel.EtaMinutes min` over the label **"ETA"** — no distance. `ActiveJobContext` and `ActiveJobViewModel` expose **no distance value** at all (only `EtaMinutes`), so the figure cannot be shown without adding one.
3. **ETA card is mis-positioned.** The mockup centers the card horizontally near the top of the map; `ActiveJob.razor.css` pins `.sd-eta` to the top-left (`top:12px; left:12px`).
4. **"En Route" state chip uses the wrong style.** The mockup shows a soft, tinted **light-blue pill** (blue dot + blue text on a pale-blue background); `.sd-chip--enroute` is a **solid blue fill with white text**. (The on-site chip is already a soft tint, so the En Route / Within-15-mi chips are inconsistent with the design.)

**Expected**
The active-job screen matches `rep-active-job__mobile-390x844.png`: app bar titled "Active Job" / "Navigating to requester"; a centered ETA card reading "{n} min / ETA · {distance} MI"; and a soft tinted En Route chip.

**Actual**
Generic app-bar chrome; ETA card shows minutes only and sits top-left; the En Route chip is a solid blue fill.

**Not a gap (explicitly):** the mockup's "P0700 ·" DTC code prefix is **non-authoritative** — the spec mandates no DTC codes (recorded under BUG-036), so the current title-only DTC line is correct.

**Proposed fix (via `/master`)**
- Set the PersonaShell title to "Active Job" and subtitle to "Navigating to requester" from `ActiveJob` (state-appropriate wording is fine — e.g. once on-site).
- Surface a **distance** for the ETA card: either compute it client-side from the rep→requester coordinates (Haversine, mirroring the backend) or add a distance field to the active-job read model (`ActiveJobContext` ← `MyActiveServiceRequestDto`, the BUG-035 precedent). Render "ETA · {distance:0.0} MI" in `.sd-eta`.
- Center the ETA card near the top of the map (CSS).
- Restyle `.sd-chip--enroute` (and align `.sd-chip--within15`) to the soft tinted pill style used by `.sd-chip--onsite`.

**Acceptance criteria (bug resolved when):**
- The app bar on `/rep/job` shows "Active Job" / "Navigating to requester" (component test asserts the title/subtitle are set).
- The ETA card shows the distance alongside the ETA ("{n} min / ETA · {distance} MI"); a unit test covers the distance value the card binds to (computed or DTO-sourced).
- The ETA card is centered per the mockup and the En Route chip uses the soft tinted style (covered by a bUnit render/structure assertion).
- A rendered AI-review screenshot of `/rep/job` is compared against `rep-active-job__mobile-390x844.png` and the four gaps are gone.
- Existing active-job behaviour tests (poll, arrive, on-site transition) stay green.

## BUG-040 — JobOfferExpired Appium E2E test can never pass (15 s wait budget vs ~60 s offer expiry; throws on first lap)

- **Status:** **Fixed** — via `/master`. Backend made the offer-expiry window configurable (`MatchingOptions`, default 60 s; backend PR #50); the Appium run shortens it to 15 s via a `JobOfferExpiry__OfferExpirySeconds` env override in `test-appium.sh` (central PR #165) so the server `JobOfferExpired` fires while the offer screen's 60 s local countdown is still high; and the test now uses a non-throwing `TryWaitForSignalR` so its 80 s loop governs the wait (frontend PR #50). Live-verified: Appium `JobOfferTests` 6/6 (was 5/1). Production expiry default stays 60 s.
- **Severity:** Medium (test-suite defect — the Appium suite reports a persistent failure, eroding trust in the E2E gate. The shipped *product* behaviour appears correct; this is a broken test, not a user-facing regression. But a perpetually-red E2E test masks real future regressions.)
- **Repo / Area:** **Cross-repo.** Primary: **Frontend** — `tests/ServiceDelivery.Client.Appium/JobOfferTests.cs` (the `GivenJobOfferExpired_…` test) and the `WaitForSignalR` helper in `tests/ServiceDelivery.Client.Appium/AppiumFixture.cs`. Likely enabler: **Backend** — make the offer-expiry window configurable (currently a hardcoded ~60 s in `MatchingService`) so the server `JobOfferExpired` event can fire before the offer-screen's local countdown elapses, in the Local/Appium environment.
- **Related stories:** `BUG-037` (wired the `JobOfferExpired` RepHub event to dismiss the offer screen — the product fix this test was meant to guard), `BUG-032` (job-offer Appium precondition: backend-only run + fleet positioning), `BUG-036` (job-offer wire-contract). See also the project note that AI Review is build-only and has twice approved a broken Appium fix — live-verify E2E before shipping.
- **Found:** Running `scripts/local/test-appium.sh` after BUG-039 merged. The suite reported **11 passed / 1 failed / 1 skipped**; the failure reproduced **2/2** (not a flake). The active-job (BUG-039) test passed — this failure is unrelated to BUG-039. Root-caused by reading the test + `WaitForSignalR` + the frontend/backend `JobOfferExpired` wiring.

**Summary**
`GivenJobOfferExpired_WhenServerPushesExpiredEvent_ThenOfferScreenDismissesWithoutWaitingForCountdown` (`JobOfferTests.cs:111`) takes over a vehicle, submits a request so an offer routes to the rep (the `countdown-ring` appears — this step passes), then loops up to an 80 s deadline calling `WaitForSignalR(… available-indicator … .FirstOrDefault())` to detect the offer screen dismissing back to idle.

The helper `WaitForSignalR` (`AppiumFixture.cs:243`) uses `WebDriverWait.Until(…)` with `AppiumConfig.SignalRWait = 15 s`. `Until` **throws** `WebDriverTimeoutException` at 15 s (it never returns null). On the **first** loop pass the offer is still on screen (the backend's `ExpiredJobOfferSweeper` only expires the offer after ~60 s), so `available-indicator` is absent, the helper polls null for 15 s and **throws straight out of the test** — the 80 s retry loop is dead code. Net: the test aborts at 15 s (the observed failure at `JobOfferTests.cs:133`) and can never observe a ~60 s server expiry.

The **product wiring is correct**: frontend subscribes to `"JobOfferExpired"` (`SignalRRepHubService`), `JobOfferViewModel.HandleJobOfferExpiredAsync` matches `OfferId` and navigates to idle; backend emits `"JobOfferExpired"` to group `rep:{repId}` (`RepHubService` / `ExpiredJobOfferSweeper`). Names and targeting match end-to-end. The test simply never gives the product the ~60 s it needs.

**Design subtlety to resolve (not just a budget bump):** the offer-screen's local countdown is driven by the same expiry as the server sweep, so the server `JobOfferExpired` event fires *at or after* the local countdown reaches 0 — meaning the assertion `countdownAtDismissal > 0` ("dismissed by the server event, not the local timer") can never hold on the natural-expiry path. To make "dismiss without waiting for the countdown" observable, the **server offer-expiry must be shorter than the offer-screen's local countdown** in the test environment (or the test must trigger an early, non-timeout expiry).

**Expected**
The `JobOfferExpired` E2E test reliably passes against a live system, genuinely proving the frontend dismisses the offer screen on the server event before the local countdown elapses.

**Actual**
The test throws `WebDriverTimeoutException: Timed out after 15 seconds` on its first wait lap (reproduced 2/2), because a 15 s throwing wait cannot observe a ~60 s server expiry, and the design makes early dismissal unobservable on the natural-expiry path.

**Proposed fix (via `/master`)**
- **Backend:** make the offer-expiry window configurable (e.g. `JobOfferExpiry:OfferExpirySeconds`, default ~60) read by `MatchingService`; set it low for the Local/Appium environment (and lower the sweep poll interval) so the server `JobOfferExpired` fires well before the offer-screen's local countdown — without changing production defaults.
- **Frontend test:** make the dismissal poll non-throwing (catch `WebDriverTimeoutException` and continue, or `FindElements().FirstOrDefault()` under a short implicit wait) so the outer 80 s loop governs; keep the `countdownAtDismissal > 0` assertion meaningful given the shorter server expiry.

**Acceptance criteria (bug resolved when):**
- `GivenJobOfferExpired_WhenServerPushesExpiredEvent_ThenOfferScreenDismissesWithoutWaitingForCountdown` passes against a live system (verified via `scripts/local/test-appium.sh`), and reproducibly (not a one-off).
- The offer-screen dismissal is driven by the server `JobOfferExpired` event while the local countdown is still > 0 (the assertion is genuine, not vacuous).
- Production offer-expiry default behaviour is unchanged (the shorter expiry applies only to the Local/test environment via configuration).
- The `WaitForSignalR` helper (or the test's use of it) no longer aborts the outer retry loop on a single lap timeout.
- The rest of the Appium suite stays green (no new failures); no frontend/backend product-behaviour change beyond the expiry configuration.

## BUG-041 — Release Vehicle never opens its confirmation dialog: the idle view clears the claimed-vehicle store before the release action reads it

- **Status:** **Fixed** — via `/master` (frontend PR #53, squash `3feda91`). Removed the constructor `ClearVehicle()` from `RepIdleViewModel` so `IClaimedVehicleStore` is durable for the session; the idle view now reads without clearing, so `ReleaseVehicleAction` finds the claimed vehicle and opens the dialog. Backed by a RED-verified composition-root integration test (`ClaimedVehicleStoreIntegrationTests`), a flipped `RepIdleViewModelTests` assertion (`ClearVehicle` `Times.Never`), and a corrected `IClaimedVehicleStore` doc comment. **Live-verified:** full Appium suite **16 passed / 0 failed / 1 skipped** (the 2 `ReleaseVehicleTests` now pass; was 14/2/1). Follow-ups filed: **BUG-042** (idle stale-vehicle on second take-over) and **BUG-043** (clear store on logout — fold into FE-023).
- **Severity:** **High** (a core FE-014 user-facing action is completely broken in the real app — a rep can never release their vehicle / go off duty from the device, which is a Phase 9 exit-criterion. Not a test defect: the product is broken for real users.)
- **Repo / Area:** **Frontend.** Root cause: `src/ServiceDelivery.Client.Core/ViewModels/RepIdleViewModel.cs` (constructor calls `IClaimedVehicleStore.ClearVehicle()` as a consume-once hand-off) vs `src/ServiceDelivery.Client.UI/Features/ServiceRep/Services/ReleaseVehicleAction.cs` (reads `IClaimedVehicleStore.CurrentVehicle` later, expecting it to be durable). Store: `src/ServiceDelivery.Client.Core/Services/InMemoryClaimedVehicleStore.cs` / `Interfaces/IClaimedVehicleStore.cs`.
- **Related stories:** `FE-014` (the release feature whose Appium tests fail), `FE-007`/`FE-020` (take-over → idle hand-off that populates the store), `BUG-034`/`BUG-035` (introduced the `IClaimedVehicleStore` hand-off for the idle card), and **`QUAL-007`** (test the real composition root — this defect was masked by unit tests that mocked the store).
- **Found:** Running `scripts/local/test-appium.sh` after FE-013/FE-014 merged. Suite reported **14 passed / 2 failed / 1 skipped**; both failures in `ReleaseVehicleTests` reproduced (not a flake). **Live-verified** product-vs-test via a diagnostic that drove the real iOS app and dumped the WebView DOM + screenshots at each step.

**Summary**
The two failing tests — `GivenRepWithVehicle_WhenReleaseVehicleTapped_ThenConfirmationDialogAppears` and `GivenConfirmationDialogShown_WhenReleaseConfirmed_ThenTakeOverScreenIsDisplayed` (`ReleaseVehicleTests.cs:39,52`) — are **correct**; they catch a genuine product defect.

Live diagnosis (four iOS-simulator boots, isolating the cause):
1. Native tap on "Release vehicle" → item highlights, but **no dialog** renders (`release-dialog-*` absent from the DOM) and the drawer stays open. The 15 s implicit wait is in effect, so it is not a timing miss.
2. A JS-dispatched real DOM `click()` on the same nav-link → **still no dialog** → rules out Appium tap-fidelity (the BUG-031 class).
3. Tapping **"Log out"** (same `MudNavLink` → `OnItemClicked` path) → returns to login → proves the drawer click wiring fires Blazor's `OnClick`; the defect is specific to the *release* path.
4. Instrumenting the null-vehicle branch to navigate to take-over → after the release tap we land on the **take-over screen** → confirms `CurrentVehicle` is **null** at release time.

**Root cause.** `RepIdleViewModel`'s constructor consumes `IClaimedVehicleStore` as a one-shot hand-off and clears it:
```csharp
Vehicle = claimedVehicleStore.CurrentVehicle ?? EmptyVehicle;
claimedVehicleStore.ClearVehicle();   // store is now null
```
Sequence: take-over `SetVehicle(V-001)` → navigate to idle → `RepIdleViewModel` caches V-001 then `ClearVehicle()` → store null → tap Release → `ReleaseVehicleAction.ReleaseAsync` reads `CurrentVehicle == null` → silently returns `NothingToRelease`, dialog never shown. The idle card still shows "V-001" only because the view-model cached it before clearing. It is a contract conflict: the idle view treats the store as an *ephemeral* hand-off (mirroring `IJobOfferStore`), while the release action treats it as *durable* "the vehicle I currently hold."

**Why the unit tests passed (masking).** `ReleaseVehicleActionTests` / `PersonaMenuReleaseItemTests` mock `IClaimedVehicleStore` to always return a vehicle, so they never exercise the real `RepIdleViewModel` construction → `ReleaseAsync` sequence against the real store. The Appium E2E suite, running the real composition root, is what caught it (the `QUAL-007` gap).

**Expected**
Tapping "Release vehicle" on the idle screen (after a take-over) opens the confirmation MudDialog; confirming releases the vehicle and returns the rep to the take-over screen.

**Actual**
Tapping "Release vehicle" does nothing visible — no dialog, drawer stays open — because the claimed-vehicle store was cleared by the idle view, so the release action treats it as "nothing to release."

**Proposed fix (via `/master`)**
- Make `IClaimedVehicleStore` the **durable** source of truth for the currently-held vehicle: stop clearing it in `RepIdleViewModel`'s constructor; clear it instead on the real lifecycle exits (successful release — already done in `ReleaseVehicleAction`; logout / go-off-duty per FE-023). Resolve the original "stale claim on re-navigation" concern that motivated the clear without breaking the release/idle reads (e.g. clear on logout, or re-hydrate from the backend's active vehicle rather than consume-once).
- Keep the failing Appium tests as the live gate — do **not** paper over them with waits or selector changes.
- The red test that drives the fix **must exercise the real composition root**: construct the real `RepIdleViewModel` (which performs the hand-off) and then call `ReleaseAsync` against the real `InMemoryClaimedVehicleStore`, asserting the confirmation is invoked (store still non-null). A pure mocked-store unit test would re-mask this.

**Acceptance criteria (bug resolved when):**
- Both `ReleaseVehicleTests` (`…ThenConfirmationDialogAppears`, `…ThenTakeOverScreenIsDisplayed`) pass against a live system (verified via `scripts/local/test-appium.sh`), reproducibly.
- After a take-over, the idle card still shows the correct vehicle **and** tapping Release opens the confirmation dialog (both consumers see the claimed vehicle).
- A composition-root-level test reproduces the original failure (red without the fix): real `RepIdleViewModel` hand-off followed by `ReleaseAsync` must still find the claimed vehicle.
- No regression to the take-over → idle hand-off (BUG-034/035) or to re-navigation behaviour (no stale claim resurrected).
- The rest of the Appium suite stays green; no unrelated product changes.

## BUG-042 — Idle screen shows a stale vehicle after a second take-over in the same session (`RepIdleViewModel` is scoped-singleton and caches the first vehicle)

- **Status:** **Fixed** — via `/master` (frontend PR #54, squash `25b3ae7`). Two coupled changes in `RepIdleViewModel`: `Vehicle` is now a computed property reading the live `IClaimedVehicleStore` on each access (idle card / app-bar subtitle reflect the current vehicle), and the `OnJobOfferReceived` hub registration moved from `StartAsync` into the constructor — folding in a latent double-subscribe fix (a single offer would otherwise fire `NavigateToJobOffer` twice after re-entering idle; developer approved option (a)). Backed by an AC-2 composition-root real-lifecycle test (two take-overs) + a double-subscribe guard, both RED-verified. 355 unit/integration tests green; **live-verified** full Appium suite 16/0/1 (no regression to offer/accept/release). BUG-041 store-durability invariant preserved.
- **Severity:** **Low** (display-only; the release action still targets the correct current vehicle via the store, and the POC's normal flow is one vehicle per session — so this is rarely hit. But the idle card and app-bar subtitle would show the wrong registration after a release-then-retake-a-different-vehicle in one session.)
- **Repo / Area:** **Frontend.** `src/ServiceDelivery.Client.Core/ViewModels/RepIdleViewModel.cs` (the `Vehicle` property is read-only and set once in the constructor) combined with its registration `builder.Services.AddScoped<RepIdleViewModel>()` in all three hosts (`MauiProgram.cs` / `Program.cs`) — scoped is effectively singleton for a BlazorWebView's lifetime.
- **Related stories:** `BUG-041` (surfaced this during blast-radius analysis), `BUG-034`/`BUG-035` (the idle-card vehicle hand-off), `FE-007`/`FE-020` (take-over → idle).
- **Found:** Tracing the consumers of `IClaimedVehicleStore` while reviewing the BUG-041 fix. Not yet reproduced live (the single-vehicle-per-session happy path never re-constructs the view model), but follows directly from the lifetime + read-only-cache design.

**Summary**
`RepIdleViewModel` exposes `Vehicle` as a read-only property assigned once in its constructor from `IClaimedVehicleStore.CurrentVehicle`. The view model is registered `AddScoped`, which in MAUI Blazor Hybrid means a single instance for the whole BlazorWebView session. So the first navigation to `/rep/idle` (after the first take-over) caches the vehicle, and every later navigation re-uses the same instance with the same cached value. If a rep releases their vehicle and takes over a **different** one in the same session, the idle card (`RepIdle.razor` → `ViewModel.Vehicle.Registration`/`Model`/`EquipmentTypes`) and the app-bar subtitle (`Shell.SetVehicleContext(...)`) still show the **first** vehicle. The release action is unaffected — it reads the live store, which holds the current vehicle.

**Expected**
The idle card and app-bar subtitle reflect the vehicle the rep currently holds, after any take-over in the session.

**Actual**
They show the first vehicle taken over in the session; a second take-over of a different vehicle does not update the idle display.

**Proposed fix (via `/master`)**
Re-hydrate the claimed vehicle from `IClaimedVehicleStore` on each entry to the idle view rather than caching it once at construction — e.g. read it in the page's `OnInitializedAsync`/`OnParametersSetAsync` into a mutable `Vehicle`, or register `RepIdleViewModel` as transient, or expose a `Refresh()` the page calls on load. Add a test that drives two take-overs (different vehicles) through the real view-model lifecycle and asserts the idle display reflects the second.

**Acceptance criteria (bug resolved when):**
- After a release-then-take-over of a different vehicle in the same session, the idle card and app-bar subtitle show the second vehicle.
- A test reproduces the stale-display failure across two take-overs (red before fix, green after) using the real view-model lifecycle, not a one-shot construction.
- No regression to the single-take-over idle display (BUG-034/035) or to BUG-041's release behaviour.

## BUG-043 — Claimed-vehicle store is not cleared on logout, so a stale claim can persist across sessions (surfaced once BUG-041 removes the idle-view clear)

- **Status:** **Fixed** — resolved as part of **FE-023** (frontend PR #55, squash `2f1a45f`). The new `ServiceRepLogoutSideEffect` (replacing `NoOpLogoutSideEffect` at the Mobile composition root) calls `IHeartbeatService.StopAsync()` then `IClaimedVehicleStore.ClearVehicle()` in `RunBeforeTokenClearedAsync`, so `ShellViewModel.LogoutAsync` now clears the claimed vehicle before the JWT is cleared. Proven end-to-end by `HeartbeatSessionIntegrationTests` (real `ServiceRepLogoutSideEffect` + real `InMemoryClaimedVehicleStore` through `ShellViewModel.LogoutAsync`), plus `ServiceRepLogoutSideEffectTests` (stop-before-clear ordering). No BUG-041 regression (release still finds the claimed vehicle in-session; re-login → take-over still works). The go-off-duty/timeout half of the original AC is realized by FE-023's heartbeat teardown + the backend stale-heartbeat sweep (BE-028).
- **Severity:** **Low** (no logout path clears `IClaimedVehicleStore`; a re-login routes through the take-over screen, which overwrites the store via `SetVehicle`, so the stale value is normally replaced before it is read. But the claimed vehicle lingering past logout is incorrect and could leak across reps on a shared device/session.)
- **Repo / Area:** **Frontend.** Logout path — `ShellViewModel.LogoutAsync` / `ILogoutSideEffect` (`NoOpLogoutSideEffect` in the hosts) — does not call `IClaimedVehicleStore.ClearVehicle()`. Store: `src/ServiceDelivery.Client.Core/Services/InMemoryClaimedVehicleStore.cs`.
- **Related stories:** `BUG-041` (removes the incidental idle-view `ClearVehicle()` that was masking this), **`FE-023`** (Stay-on-duty heartbeat + clean go-off-duty — the proper home for clearing claimed/session state on logout/timeout). **Best resolved as part of FE-023** rather than standalone.
- **Found:** BUG-041 blast-radius analysis. Before BUG-041, `RepIdleViewModel`'s constructor incidentally nulled the store after the first idle render; removing that clear (the BUG-041 fix) means the claimed vehicle now persists until something explicitly clears it — and nothing does on logout.

**Summary**
The only in-session clears of `IClaimedVehicleStore` are `ReleaseVehicleAction.ReleaseAsync` (on a successful release) and — until BUG-041 — `RepIdleViewModel`'s constructor. No logout/go-off-duty path clears it. After BUG-041, logging out leaves the previously-claimed vehicle in the store. If another rep logs in on the same app instance (same DI scope, no app restart) the stale claim is present until they take over a vehicle (which overwrites it). The realistic blast radius is small because the rep's home screen is take-over, but the state is semantically wrong and should be cleared on logout and on go-off-duty/timeout.

**Expected**
Logging out (and going off duty / timing out per FE-023) clears `IClaimedVehicleStore` so no claimed vehicle persists into the next session.

**Actual**
The claimed vehicle persists in the store after logout (observable once BUG-041 removes the idle-view clear).

**Proposed fix (via `/master`, ideally folded into FE-023)**
Clear `IClaimedVehicleStore` on logout (in `ShellViewModel.LogoutAsync` or via the `ILogoutSideEffect` seam) and on clean go-off-duty/timeout. Prefer implementing this within **FE-023** so all session-lifecycle teardown (heartbeat stop, off-duty, claimed-vehicle clear) lives together.

**Acceptance criteria (bug resolved when):**
- After logout, `IClaimedVehicleStore.CurrentVehicle` is null (verified by a test on the real logout side-effect / `ShellViewModel.LogoutAsync`).
- Go-off-duty / heartbeat-timeout (FE-023) also clears the store.
- No regression to BUG-041 (release still finds the claimed vehicle during an active session) or to re-login → take-over.

---

## BUG-044 — Requester tracking app-bar shows the default title/subtitle (not the page-set title) and a faint duplicate avatar on live render

- **Status:** **Fixed** — resolved via `/master` (frontend PR #68). The page-set title is now re-applied from `RequesterTracking.OnAfterRenderAsync(firstRender)` (plus a `ShellViewModel.TitleChanged` event `PersonaShell` subscribes to for post-render changes), so the tracking app bar shows "Your technician is on the way" / "A new technician is on the way"; the single avatar renders in the trailing app-bar slot (duplicate suppressed); the stray Requester hamburger is gated to Drawer style. Added composed rendered-DOM bUnit tests + live Playwright title/single-avatar assertions — the original defect slipped through because tests asserted the ViewModel field, not the rendered DOM. Live-verified against both mockups.
- **Severity:** Low (cosmetic — the requester tracking screen's `PersonaShell` app bar shows the generic "Service Delivery / Requester" instead of the page-set title, e.g. "Your technician is on the way" and, after a redirect, "A new technician is on the way"; a faint duplicate-avatar artifact also renders. The feature itself works — banner, map, ETA, and the FE-018 redirect flow are all correct.)
- **Repo / Area:** **Frontend** — `PersonaShell` app-bar title wiring vs. the requester tracking page's `Shell.SetTitle(...)` call (`src/ServiceDelivery.Client.UI/Shared/Components/PersonaShell.razor` and `Features/Requester/Pages/RequesterTracking.razor`). Likely the same `PersonaShell` render-timing family as BUG-025 / BUG-026 (parameter-diff / lifecycle), applied to the page-set title path.
- **Related stories:** `FE-017` (live rep tracking — the baseline screen), `FE-018` (redirect notification — its AC-1 title swap is the case that surfaced this), BUG-025 / BUG-026 (`PersonaShell` re-render lifecycle).
- **Found:** FE-018 live E2E (`test-playwright.sh`) rendered-fidelity review (Check 10c). The redirected tracking screenshot showed the default app-bar title/subtitle rather than the redirect title, plus a faint duplicate avatar. The **identical** artifact appears on the FE-017 baseline tracking screenshot from the same run — so it is a pre-existing tracking-shell rendering matter, **not** an FE-018 regression. FE-018's title-swap logic is correct and asserted at bUnit level; the gap is that the page-set title is not reflected in the live-rendered shell.

**Summary**
On the requester tracking view, the `PersonaShell` app bar renders its default title/subtitle instead of the value the page sets via `Shell.SetTitle(...)`, and a faint second avatar renders over the first. Because the tracking screen sets its title after initial render (and again on redirect), the shell appears not to pick up the page-set title live.

**Expected**
The tracking app bar shows the page-set title — "Your technician is on the way" normally, "A new technician is on the way" after a redirect (FE-018 AC-1) — with a single avatar.

**Actual**
The app bar shows the generic "Service Delivery / Requester" title/subtitle and a faint duplicate avatar, both on the FE-017 baseline and the FE-018 redirected screen.

**Proposed fix (via `/master`, as a small FE fix or folded into a PersonaShell chrome pass)**
Investigate why the requester tracking page's `Shell.SetTitle(...)` is not reflected in the live-rendered `PersonaShell` (parameter-diff / lifecycle, cf. BUG-025/026), and resolve the duplicate-avatar artifact on this route. Add a live/rendered assertion (or Playwright check) that the tracking app-bar title matches the page-set value.

**Acceptance criteria (bug resolved when):**
- On the live requester tracking screen, the app-bar title reflects `Shell.SetTitle(...)` — "Your technician is on the way", and "A new technician is on the way" after a redirect.
- Only one avatar renders in the tracking app bar.
- Verified against the FE-017 tracking and FE-018 redirect mockups on a running app (not bUnit alone).

---

## BUG-045 — Concurrent take-overs collide on the first-listed available vehicle, so a second assignable rep can't be acquired cleanly on a clean live start

- **Status:** **Fixed** — triaged (from the Backend/Simulator label) to the **client retry-on-409** approach and resolved via `/master` (frontend PR #69). `TakeOverViewModel.TakeOverAsync` now bounded-auto-retries the next available candidate on a take-over 409 (guarded by a per-invocation `HashSet<Guid>` — cannot spin), falling back to a "just taken — pick another" message when the list is exhausted. Backend untouched (the 409 is correct optimistic concurrency); ViewModel unit tests are the guard (Conflict-A→Success-B asserts the claim lands on B, never A). AC-2 taken in its lenient reading (the FE-018 E2E helper unchanged). No regression to BUG-027 or single take-over.
- **Severity:** Low–Medium (blocks acquiring multiple distinct idle reps concurrently via the take-over path; surfaced as E2E-setup friction but also affects two humans taking over vehicles at the same time. Single take-over / single assignment is unaffected — this is why single-rep flows like FE-017 tracking pass.)
- **Repo / Area:** **Backend / Simulator** — `GET /vehicles/available` (`src/ServiceDelivery.Application/Features/Vehicles/Queries/GetAvailableVehiclesQueryHandler.cs`) + the take-over/claim path (`TakeOverVehicleCommandHandler`). **Follow-on to BUG-027** (do not contradict it — BUG-027's fix to return unclaimed-or-idle-claimed vehicles is correct; this is a distinct concurrency/ergonomics facet exposed by it).
- **Related stories:** BUG-027 (`/vehicles/available` idle-claimed semantics — Fixed), `FE-007` (take over an idle vehicle), ADR-0009 (human takeover). Surfaced by `FE-018` redirect E2E.
- **Found:** FE-018 redirect E2E setup. A redirect needs a *second* rep to accept the displaced job. When the test tried to acquire spare reps via the take-over path, `GET /vehicles/available` returned the simulator's idle-claimed vehicles with a stable ordering (V-001 first), so concurrent take-over attempts all targeted the same vehicle and all but one returned 409 — effectively only one assignable rep on a clean start. The E2E worked around it by claiming distinct vehicles (V-002 / V-003) directly for the spare reps.

**Summary**
`GET /vehicles/available` correctly (per BUG-027) reports vehicles that are unclaimed or claimed by an idle rep, but gives no signal to distinguish or spread concurrent take-overs. Because the list ordering is stable, multiple simultaneous take-over attempts converge on the first-listed vehicle (V-001) and collide (409), so acquiring several distinct idle reps at once is not reliably possible.

**Root cause (hypothesis — needs backend confirmation)**
The read model (`/vehicles/available`) and the claim command have no reservation/spread mechanism; the 409 on a taken vehicle is correct optimistic-concurrency behaviour, but the deterministic first-listed vehicle makes collisions systematic rather than rare. It is unclear whether the intended fix is server-side (e.g. surface which vehicles are simulator-driven vs. truly free, or a claim-next-available endpoint) or client-side (retry on 409 against the next candidate).

**Expected**
Multiple clients (or an automated harness) can acquire distinct idle vehicles concurrently without systematically colliding on the same first-listed vehicle.

**Actual**
Concurrent take-overs collide on V-001; all but one 409, leaving effectively one assignable rep on a clean live start.

**Proposed fix (via `/master` once triaged)**
Triage whether this is a backend endpoint concern (spread/reserve, or a claim-next-available affordance) or a documented client retry-on-409 pattern; implement and cover with a test that acquires ≥2 distinct idle reps concurrently. Until fixed, tests should claim distinct vehicles explicitly (as the FE-018 E2E now does).

**Acceptance criteria (bug resolved when):**
- Two concurrent take-over requests acquire two *distinct* idle vehicles without a spurious 409, or a documented retry pattern reliably yields distinct vehicles.
- The FE-018 redirect E2E no longer needs to hand-pick V-002 / V-003 to set up a second rep (or the retry pattern is what makes it deterministic).
- No regression to BUG-027 (the take-over list still includes idle-claimed vehicles) or to single take-over.

---

## BUG-046 — Appium `ActiveJobTests.…GoogleMapContainerIsPresentWithOverlayTestIds` fails with `StaleElementReferenceException` (map element read after Maps-SDK DOM churn)

- **Status:** Fixed
- **Severity:** Low (test-only fragility — the feature is fine: the ActiveJob Google map and its rep-marker / requester-pin / route-line overlays all render. But it leaves the QUAL-004 Appium suite permanently 1-red, which erodes the "green suite = healthy" signal and can mask a future real regression on this screen.)
- **Repo / Area:** **Frontend** — Appium E2E test `tests/ServiceDelivery.Client.Appium/ActiveJobTests.cs:97` (`GivenRep1AcceptedJob_WhenActiveJobScreenLoads_ThenGoogleMapContainerIsPresentWithOverlayTestIds`). Part of the QUAL-004 Appium suite. Same live-Appium timing-race family flagged in the App-Nap / WebView notes, but here it reproduces deterministically, not just under load.
- **Related stories:** `FE-026` (real Google map on the active-job screen), `FE-013` (active job / mark complete), `QUAL-004` (Appium end-to-end suite).
- **Found:** QUAL-011 live re-verification (`test-appium.sh`). Confirmed **pre-existing, not a QUAL-011 regression**: the isolated test fails **identically on `main`** with QUAL-011's changes stashed out (same `StaleElementReferenceException`, ~25–26 s, both branches), and QUAL-011 changed only `ActiveJob.razor.css` — no markup, no `data-testid`, no render logic — so it is structurally incapable of causing a DOM-detachment race. Also confirmed it is **not** load-dependent (reproduces in a single-test run, unlike the `TakeOverFirstIdleVehicle`-under-load flake).

**Summary**
The test captures the `[data-testid='google-map']` element (line 91), then polls for three map overlays (`rep-marker`, `requester-pin`, `route-line`, lines 92–94) that the Google Maps SDK stamps into the DOM as it initialises. That SDK-driven DOM churn detaches the originally-captured container node, so reading `map.Displayed` at line 97 throws `StaleElementReferenceException`.

**Expected**
The test reliably asserts the map container is present and displayed alongside its three overlays.

**Actual**
`Assert.That(map.Displayed, Is.True)` throws `OpenQA.Selenium.StaleElementReferenceException: Element is no longer attached to the DOM` because the `map` reference captured before the overlay polling is stale by the time `.Displayed` is read.

**Proposed fix (via `/master`)**
Re-find the element immediately before asserting rather than reading a property on a reference captured several SDK-mutations earlier — e.g. assert presence via `Assert.That(Driver.FindElements(By.CssSelector("[data-testid='google-map']")), Is.Not.Empty)` at the assertion point, or re-query `google-map` and read `.Displayed` on the fresh reference. Keep the overlay assertions (they already re-query). Do not weaken the assertion to a no-op — it must still fail if the map container genuinely disappears.

**Acceptance criteria (bug resolved when):**
- `GivenRep1AcceptedJob_WhenActiveJobScreenLoads_ThenGoogleMapContainerIsPresentWithOverlayTestIds` passes green, both in isolation and in the full Appium suite, across repeated runs.
- The assertion still fails if the `google-map` container (or any of the three overlays) is genuinely absent — verified by a deliberate temporary break.
- No new `StaleElementReferenceException` introduced elsewhere in `ActiveJobTests`.

---

## BUG-047 — ActiveJob ETA/distance card overlaps the Google Map's Map/Satellite controls; relocate it from center-top to center-bottom

- **Status:** Fixed
- **Severity:** Low–Medium (usability — the ETA/distance card sits at the top-center of the active-job map and overlaps Google's map-type (Map / Satellite) control, so the rep cannot toggle the map type. The ETA/distance info itself renders correctly; this is a placement collision, not missing data.)
- **Repo / Area:** **Frontend** — `src/ServiceDelivery.Client.UI/Features/ServiceRep/Pages/ActiveJob.razor.css` (the `.sd-eta` rule, currently `position: absolute; top: 12px; left: 50%; transform: translateX(-50%)`) and its markup in `Features/ServiceRep/Pages/ActiveJob.razor` (`<div class="sd-eta" data-testid="eta-card">`, with `data-testid='eta-minutes'` / `eta-distance`).
- **Related stories:** `FE-013` (active job screen), `FE-026` (real Google map replacing the CSS/SVG placeholder — introduced the map-type control that the card now collides with). Independent of `QUAL-011` (QUAL-011 keeps `.sd-eta` as a page-specific scoped rule and does not move it — this is a pre-existing placement issue, not a consolidation regression).
- **Found:** QUAL-011 live re-verification of the ActiveJob mobile screen — the center-top ETA/distance card overlays the Google Maps Map/Satellite buttons.

**Summary**
`.sd-eta` is absolutely positioned at `top: 12px; left: 50%` (top-center of the map). Google Maps renders its map-type (Map/Satellite) control near the top of the map canvas, so the ETA/distance card covers those buttons and blocks interaction.

**Expected**
The ETA/distance card is visible without obscuring the Google Maps map-type controls (or any other native map control).

**Actual**
The center-top ETA/distance card overlaps the Map/Satellite buttons, making them unreachable.

**Proposed fix (via `/master`)**
Move the ETA/distance card from center-top to **center-bottom** of the map: change `.sd-eta` from `top: 12px` to `bottom: 12px` (keep `left: 50%` + `translateX(-50%)` for horizontal centering). Verify the new position clears Google's bottom controls too — the zoom control (bottom-right), the Google logo (bottom-left), and the Terms/ToS link (bottom-right) — center-bottom should sit between them, but confirm live. Update/keep any bUnit assertion for `data-testid='eta-card'` and add a note that final placement is confirmed live (applied position is only verifiable on a running map).

**Acceptance criteria (bug resolved when):**
- On the live ActiveJob screen, the ETA/distance card renders at center-bottom of the map and does **not** overlap the Map/Satellite control (nor the zoom, Google logo, or ToS controls).
- The ETA minutes and distance values still render correctly (`data-testid='eta-minutes'`, `eta-distance`).
- Verified live on the mobile ServiceRep active-job screen (Appium / manual), not bUnit alone.

---

## BUG-048 — Appium `TakeOverFirstIdleVehicle` precondition flakes under full-suite load: bare `FindElement('idle-vehicle-row')` races the async idle-list load

- **Status:** Fixed
- **Severity:** Low–Medium (test-only fragility — the take-over feature works; but the shared `TakeOverFirstIdleVehicle()` helper is a precondition for several Appium scenarios, so its flake fails whichever test happens to run it under load, intermittently 1-reddening the QUAL-004 Appium suite and eroding the "green suite = healthy" signal. Non-deterministic, so it can mask — or be mistaken for — a real regression).
- **Repo / Area:** **Frontend** — Appium E2E shared helper `tests/ServiceDelivery.Client.Appium/AppiumFixture.cs:319` (`TakeOverFirstIdleVehicle()`), used as a precondition by the FE-020 / FE-008 / FE-011 / QUAL-009 scenarios. Surfaced most recently through `HeartbeatGoOffDutyTests.GivenRepOnDuty_WhenAppIsClosedSoHeartbeatsStop_ThenBackendTimesOutAndVehicleReappears`, which calls it. This is the **`TakeOverFirstIdleVehicle`-under-load flake family** explicitly named in BUG-046 and in the App-Nap / WebView timing-race notes — known and referenced, but never filed until now.
- **Related stories:** `FE-020` (take-over an idle vehicle), `QUAL-004` (Appium end-to-end suite), `QUAL-009` (heartbeat / go-off-duty live E2E), `QUAL-008` (per-runtime integration targets). Related bug: `BUG-046` (a *deterministic* Appium timing bug on the same suite; this one is the load-dependent sibling it contrasts itself against).
- **Found:** QUAL-011 live re-verification (`test-appium.sh`, full suite, 7m22s run). Failed once in the full suite (`NoSuchElementException` at `AppiumFixture.cs:319`); **re-ran green 2/2 in isolation** (single-test run, unloaded host) — confirming it is load-dependent, not a QUAL-011 regression (QUAL-011 is CSS-only and cannot affect whether a native element exists). Same family recorded in prior live runs.

**Summary**
`TakeOverFirstIdleVehicle()` calls `Login()` (which waits only for the take-over screen's `take-over-button` *chrome* to exist), then immediately does a **bare** `Driver.FindElement(By.CssSelector("[data-testid='idle-vehicle-row']")).Click()`. The idle-vehicle rows are populated by a *separate async data load* (REST + SignalR fleet snapshot) that lands **after** the take-over screen mounts, so the row is not guaranteed to be in the DOM the instant `Login()` returns. The bare `FindElement` leans on the implicit wait and races that load; under full-suite load (busy host, WebView render lag, App-Nap timer throttling over a multi-minute run) the row hasn't rendered yet → `NoSuchElementException`. The two follow-on lookups (`take-over-button`, `available-indicator`) are bare `FindElement`s for the same reason.

**Expected**
`TakeOverFirstIdleVehicle()` reliably selects the first idle vehicle and completes take-over, both in isolation and in the full Appium suite under load, across repeated runs.

**Actual**
`OpenQA.Selenium.NoSuchElementException` thrown from `AppiumFixture.cs:319` when the idle-vehicle list has not finished loading before the bare `FindElement` fires — intermittently, only under full-suite load.

**Proposed fix (via `/master`)**
Route the async lookups in `TakeOverFirstIdleVehicle()` through the existing bounded-poll helper `WaitForSignalR()` (a `WebDriverWait`, 15 s budget / 500 ms interval, already ignoring `NoSuchElementException` while polling), exactly as BUG-046 did for every lookup in `ActiveJobTests`:
```csharp
WaitForSignalR(d => d.FindElement(By.CssSelector("[data-testid='idle-vehicle-row']"))).Click();
WaitForSignalR(d => d.FindElement(By.CssSelector("[data-testid='take-over-button']"))).Click();
WaitForSignalR(d => d.FindElement(By.CssSelector("[data-testid='available-indicator']")));
```
Also convert `Login()`'s trailing bare `FindElement("[data-testid='take-over-button']")` wait to `WaitForSignalR` for the same reason. Do **not** widen the implicit wait as a fix (mixing implicit + explicit waits compounds unpredictably — the real fix is the explicit poll). Test-only change; no production code. Because the failure is load-dependent and non-deterministic, the verification gate is **re-running the full Appium suite under load repeatedly (2–3×) and confirming it stays green**, not a new isolated red test.

**Acceptance criteria (bug resolved when):**
- `TakeOverFirstIdleVehicle()` and its dependent scenarios (`HeartbeatGoOffDutyTests`, FE-020/FE-008/FE-011 take-over scenarios) pass green in the **full Appium suite under load**, across repeated runs (2–3 consecutive full-suite runs with no `NoSuchElementException` from this helper).
- The waits remain genuine gates — bounded (they still time out and fail if the element never appears), not no-ops or unbounded sleeps.
- No bare `FindElement` on an async-loaded element remains in `TakeOverFirstIdleVehicle()` / `Login()`; the suite's established `WaitForSignalR` convention is applied consistently.

**Resolution** — Fixed via `/master` (frontend PR #74). Converted the four bare `Driver.FindElement` lookups on async-loaded elements to the existing `WaitForSignalR()` bounded poll (15 s budget / 500 ms interval, ignores `NoSuchElementException` while polling, throws on timeout): `Login()` L282 (`take-over-button`) and `TakeOverFirstIdleVehicle()` L315/316/319 (`idle-vehicle-row`, `take-over-button`, `available-indicator`) — mirroring the pattern BUG-046 applied across `ActiveJobTests`. Test-only change (4 insertions / 4 deletions in `AppiumFixture.cs`); no production code. **AC-1 verified live under load:** the full Appium suite ran **3× consecutively** on a loaded host (`caffeinate` held, ~7.5 min each) — all green at **26 passed / 0 failed / 1 skipped**, with the previously-flaky `HeartbeatGoOffDutyTests` (which calls `TakeOverFirstIdleVehicle()`) passing all three and zero `NoSuchElementException` from the converted lines. Pre-fix the same suite was 25/1/1.
