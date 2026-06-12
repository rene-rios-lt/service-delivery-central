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
| ~~[SIM-001](simulator.md)~~ | ~~Simulator~~ | ~~Authenticate and store JWT~~ |
| ~~[SIM-002](simulator.md)~~ | ~~Simulator~~ | ~~Connect to RepHub via SignalR~~ |
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
| [BE-014](backend.md) | Backend | Matching algorithm: filter → sort → tiebreaker → issue job offer |

**Exit criteria:** Submitting a request via API results in a `JobOfferReceived` event on the backend's RepHub.

---

## Phase 4 — Job Offer Lifecycle
**Goal:** Reps can accept/decline offers; the simulator auto-responds. Offer expiry runs automatically.

| Story | Repo | Description |
|-------|------|-------------|
| [BE-015](backend.md) | Backend | `GET /job-offers/pending` |
| [BE-016](backend.md) | Backend | `POST /job-offers/{id}/accept` + state transitions + SignalR events |
| [BE-017](backend.md) | Backend | `POST /job-offers/{id}/decline` + re-run matching |
| [BE-018](backend.md) | Backend | Background job: expire offers after 60 seconds + re-run matching |
| [SIM-005](simulator.md) | Simulator | Auto-accept (~85%) / auto-decline (~15%) job offers with delay |

**Exit criteria:** Pending offers are visible via `GET /job-offers/pending`; the full accept/decline/expire cycle works end-to-end with the simulator responding to offers.

---

## Phase 5 — Rep State Transitions & Resilience
**Goal:** Reps can arrive and complete jobs. Offline detection re-queues jobs automatically.

| Story | Repo | Description |
|-------|------|-------------|
| [BE-019](backend.md) | Backend | `POST /rep/arrive` |
| [BE-020](backend.md) | Backend | `POST /rep/complete` + re-run matching for Pending requests |
| [BE-023](backend.md) | Backend | `OnDisconnectedAsync` — offline detection, re-queue, DispatchHub alert |

**Exit criteria:** A full job lifecycle (submit → match → offer → accept → arrive → complete) works via API calls; re-matching after completion creates a new offer if other requests are pending.

---

## Phase 6 — Dispatcher Operations
**Goal:** Dispatchers can see the full fleet and redirect reps.

| Story | Repo | Description |
|-------|------|-------------|
| [BE-021](backend.md) | Backend | `GET /dispatcher/fleet` |
| [BE-022](backend.md) | Backend | `POST /dispatcher/redirect` — eligibility rules, cooldown, displaced-request flow |

**Exit criteria:** Redirect works end-to-end via API: displaced request re-queues, new rep receives `RedirectReceived`, Gold requester receives `RepAssigned`.

---

## Phase 7 — Simulator Job Navigation
**Goal:** Simulator vehicles deviate toward requesters when jobs are accepted and return to loops on completion.

| Story | Repo | Description |
|-------|------|-------------|
| [SIM-006](simulator.md) | Simulator | Navigate straight-line toward requester on job acceptance |
| [SIM-007](simulator.md) | Simulator | Return to nearest loop waypoint on job completion |

**Exit criteria:** During a simulated job, vehicle position updates show movement toward the requester's coordinates, then resume loop traversal after the job ends.

---

## Phase 8 — Frontend Foundation
**Goal:** Users can log in and are routed to the correct view. JWT lifecycle is handled.

| Story | Repo | Description |
|-------|------|-------------|
| [FE-001](frontend.md) | Frontend | Login screen → JWT → route by role |
| [FE-002](frontend.md) | Frontend | JWT expiry detection → redirect to login |
| [FE-021](frontend.md) | Frontend | App shell, navigation menu & logout (per-persona) |

**Depends on:** Phase 1 (BE-001, BE-002)
**Exit criteria:** Each of the three persona accounts can log in and land on their respective view shell.

---

## Phase 9 — Frontend ServiceRep Flow
**Goal:** A ServiceRep can claim a vehicle, receive and respond to job offers, navigate to the requester, and mark the job complete.

| Story | Repo | Description |
|-------|------|-------------|
| [FE-007](frontend.md) | Frontend | Vehicle selection and claim screen |
| [FE-020](frontend.md) | Frontend | Idle / waiting-for-offers view |
| [FE-008](frontend.md) | Frontend | Job offer screen with 60-second countdown |
| [FE-009](frontend.md) | Frontend | Accept offer → navigate to active job view |
| [FE-010](frontend.md) | Frontend | Decline offer → return to idle |
| [FE-011](frontend.md) | Frontend | Active job map with live position and ETA |
| [FE-012](frontend.md) | Frontend | "I've Arrived" button → on-site view |
| [FE-013](frontend.md) | Frontend | "Mark Complete" → return to idle |
| [FE-014](frontend.md) | Frontend | Release vehicle from menu |

**Depends on:** Phase 8, Phases 2–5 (vehicle + job offer + state transition endpoints)
**Exit criteria:** A ServiceRep user can complete a full job end-to-end in the UI with the simulator driving the other side.

---

## Phase 10 — Frontend Requester Flow
**Goal:** A Requester can submit a request, wait for assignment, and track their rep live.

| Story | Repo | Description |
|-------|------|-------------|
| [FE-015](frontend.md) | Frontend | Request submission form (map + DTC picker) |
| [FE-016](frontend.md) | Frontend | Pending spinner — waiting for rep assignment |
| [FE-017](frontend.md) | Frontend | Live rep tracking map with ETA |
| [FE-018](frontend.md) | Frontend | Redirect notification |
| [FE-019](frontend.md) | Frontend | Service complete screen |

**Depends on:** Phase 8, Phases 3–5 (service request + job offer + state transition endpoints)
**Exit criteria:** A Requester user can submit a request and see a rep moving toward them in real time; redirect and completion notifications display correctly.

---

## Phase 11 — Frontend Dispatcher Flow
**Goal:** A Dispatcher can monitor the full fleet, manage the request queue, redirect reps, and respond to offline alerts.

| Story | Repo | Description |
|-------|------|-------------|
| [FE-003](frontend.md) | Frontend | Live fleet map with colour-coded rep markers |
| [FE-004](frontend.md) | Frontend | Active request queue with tier badges |
| [FE-005](frontend.md) | Frontend | Redirect controls with confirmation dialog |
| [FE-006](frontend.md) | Frontend | Rep offline alert banner |

**Depends on:** Phase 8, Phases 2, 5, 6 (vehicle management + state transitions + dispatcher endpoints)
**Exit criteria:** A Dispatcher user can see all 8 simulator vehicles moving on the map in real time, redirect a rep, and receive offline alerts.

---

## Dependency Graph

```
Phase 1 (Foundation)
    └── Phase 2 (Vehicles + Simulator positioning)
            └── Phase 3 (Service Requests + Matching)
                    └── Phase 4 (Job Offer Lifecycle + Simulator offers)
                            └── Phase 5 (Rep State Transitions + Resilience)
                                    └── Phase 6 (Dispatcher Redirect)
                                    └── Phase 7 (Simulator Navigation)
Phase 1
    └── Phase 8 (Frontend Auth)
            └── Phase 9 (Frontend ServiceRep)   ← needs Phases 2–5
            └── Phase 10 (Frontend Requester)   ← needs Phases 3–5
            └── Phase 11 (Frontend Dispatcher)  ← needs Phases 2, 5, 6
```

Frontend phases (8–11) can begin in parallel with Phase 2+ on the backend — the frontend can be built against mock data / a stub API while backend phases progress. Full integration testing starts once the corresponding backend phase is complete.

---

## Story Count Summary

| Repo | Stories | Phases |
|------|---------|--------|
| Backend | BE-001 – BE-025 (25 stories) | 1–6 |
| Simulator | SIM-001 – SIM-007 (7 stories) | 2, 4, 7 |
| Frontend | FE-001 – FE-021 (21 stories) | 8–11 |
| **Total** | **53 stories** | **11 phases** |

Plus **15 open bugs** ([`bug.md`](bug.md)) — `BUG-001` – `BUG-015` — sequenced in Phase 3 ahead of `BE-014`. `BUG-003`–`BUG-015` are central-repo doc/pipeline fixes (handle via `/ship-it`).
