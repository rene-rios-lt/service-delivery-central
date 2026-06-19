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

## BUG-018 — Automated job stalls at `Within15Miles`: simulator stops navigating before reaching the requester

- **Status:** Open
- **Severity:** High (an automated job never auto-arrives or completes — the full cycle never closes; blocks the end-to-end demo)
- **Repo / Area:** Simulator — `Services/VehicleDriveResolver` (drive-mode mapping), with `Workers/FleetReconciler` / `Services/ArrivalReporter` / `Workers/VehicleWorker` (navigation→arrival handoff)
- **Related stories:** `SIM-006` (navigate to requester + arrive), `SIM-010` (dwell + complete), `BE-008` (15-mile detection)
- **Found:** Third headless backend+simulator run, after BUG-016 + BUG-017 were fixed (the job now reaches `Within15Miles`, exposing the next layer).

**Summary**
After an automated rep accepts, the truck navigates toward the requester and the backend correctly flips `EnRoute → Within15Miles`. But the truck then **stops closing the final distance** and parks ~1–2 km short of the requester — never reaching the ~50 m arrival threshold — so `ArrivalReporter` never fires `POST /rep/arrive`, the job never reaches `OnSite`, and SIM-010's dwell/`complete` never runs. The request is stuck at `Assigned` indefinitely.

**Evidence (live)**
- Submitted a request at Rep One's position; job went `Pending → Assigned` (accepted) within seconds.
- After 6 min: `GET /dispatcher/fleet` shows Rep One `state: Within15Miles`, `lastPosition ≈ (41.718, -93.586)` vs requester `(41.7308, -93.6064)` — ~1.8 km apart and not moving closer.
- Simulator log: `0` calls to `/rep/arrive` or `/rep/complete`; positions still posting for the fleet.

**Likely root cause (confirm in evaluation/plan)**
`VehicleDriveResolver` appears to return `Navigate` only while the rep is `EnRoute`; once the backend flips the rep to `Within15Miles`, the resolver no longer drives the truck toward the requester, so it never reaches the arrival threshold. Navigation must continue **through `Within15Miles`** until the truck reaches the requester (and an automated rep then auto-arrives).

**Acceptance criteria (bug resolved when):**
- An automated rep continues navigating toward the requester while `Within15Miles` until it reaches the arrival threshold (does not park short).
- On reaching the requester, an automated rep auto-arrives (`POST /rep/arrive`) → `OnSite`, then SIM-010's dwell + `POST /rep/complete` runs.
- A unit test covers the `Within15Miles` drive mode (truck keeps navigating, not held/idle) and the resulting arrival trigger.
- Verified by the headless smoke: a submitted job reaches `Completed`, then the rep returns to the loop (SIM-007).
