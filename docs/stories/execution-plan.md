# Execution Plan

> This plan sequences all user stories across the three repos in dependency order. Each phase produces independently testable, runnable increments. Stories within a phase can be worked in parallel within their repo.

---

## Phase 1 — Foundation
**Goal:** Backend is runnable with auth, seeded data, and wired SignalR hubs. Nothing works end-to-end yet, but the skeleton is ready.

| Story | Repo | Description |
|-------|------|-------------|
| ~~BE-024~~ | ~~Backend~~ | ~~Seed all POC data: 10 DTCs, 8 vehicles, 20 users, 1 simulator account~~ |
| ~~BE-001~~ | ~~Backend~~ | ~~`POST /auth/login` — JWT with role, tier, dealerId~~ |
| ~~BE-002~~ | ~~Backend~~ | ~~`GET /users/me`~~ |
| ~~BE-025~~ | ~~Backend~~ | ~~Wire all 4 SignalR hubs (VehiclePositionHub, DispatchHub, RepHub, RequesterHub)~~ |

**Exit criteria:** `POST /auth/login` returns a valid JWT; all 4 hub endpoints are reachable.

---

## Phase 2 — Vehicle Management
**Goal:** Reps can claim and release vehicles. The simulator can authenticate and stream position updates. Dispatcher can see the fleet.

| Story | Repo | Description |
|-------|------|-------------|
| ~~BE-003~~ | ~~Backend~~ | ~~`GET /vehicles` (Dispatcher)~~ |
| ~~BE-004~~ | ~~Backend~~ | ~~`GET /vehicles/available` (ServiceRep)~~ |
| BE-005 | Backend | `POST /vehicles/{id}/claim` |
| BE-006 | Backend | `POST /vehicles/{id}/release` |
| BE-007 | Backend | `POST /vehicles/{id}/force-release` (Dispatcher) |
| BE-008 | Backend | `POST /vehicles/{id}/position` + 15-mile detection + SignalR fan-out |
| SIM-001 | Simulator | Authenticate and store JWT |
| SIM-002 | Simulator | Connect to RepHub via SignalR |
| SIM-003 | Simulator | Advance vehicles along Iowa route loops |
| SIM-004 | Simulator | POST position updates every 3 seconds |

**Exit criteria:** The simulator runs and position updates appear in the backend; `GET /vehicles` reflects current positions.

---

## Phase 3 — Service Requests & DTCs
**Goal:** Requesters can submit requests; the matching algorithm produces job offers.

| Story | Repo | Description |
|-------|------|-------------|
| BE-009 | Backend | `GET /dtcs` |
| BE-010 | Backend | `POST /service-requests` + trigger matching |
| BE-011 | Backend | `GET /service-requests` (Dispatcher) |
| BE-012 | Backend | `GET /service-requests/my-active` (ServiceRep) |
| BE-013 | Backend | `GET /service-requests/{id}` |
| BE-014 | Backend | Matching algorithm: filter → sort → tiebreaker → issue job offer |

**Exit criteria:** Submitting a request via API results in a `JobOfferReceived` event on the backend's RepHub; offer visible via `GET /job-offers/pending`.

---

## Phase 4 — Job Offer Lifecycle
**Goal:** Reps can accept/decline offers; the simulator auto-responds. Offer expiry runs automatically.

| Story | Repo | Description |
|-------|------|-------------|
| BE-015 | Backend | `GET /job-offers/pending` |
| BE-016 | Backend | `POST /job-offers/{id}/accept` + state transitions + SignalR events |
| BE-017 | Backend | `POST /job-offers/{id}/decline` + re-run matching |
| BE-018 | Backend | Background job: expire offers after 60 seconds + re-run matching |
| SIM-005 | Simulator | Auto-accept (~85%) / auto-decline (~15%) job offers with delay |

**Exit criteria:** Full accept/decline/expire cycle works end-to-end with the simulator responding to offers.

---

## Phase 5 — Rep State Transitions & Resilience
**Goal:** Reps can arrive and complete jobs. Offline detection re-queues jobs automatically.

| Story | Repo | Description |
|-------|------|-------------|
| BE-019 | Backend | `POST /rep/arrive` |
| BE-020 | Backend | `POST /rep/complete` + re-run matching for Pending requests |
| BE-023 | Backend | `OnDisconnectedAsync` — offline detection, re-queue, DispatchHub alert |

**Exit criteria:** A full job lifecycle (submit → match → offer → accept → arrive → complete) works via API calls; re-matching after completion creates a new offer if other requests are pending.

---

## Phase 6 — Dispatcher Operations
**Goal:** Dispatchers can see the full fleet and redirect reps.

| Story | Repo | Description |
|-------|------|-------------|
| BE-021 | Backend | `GET /dispatcher/fleet` |
| BE-022 | Backend | `POST /dispatcher/redirect` — eligibility rules, cooldown, displaced-request flow |

**Exit criteria:** Redirect works end-to-end via API: displaced request re-queues, new rep receives `RedirectReceived`, Gold requester receives `RepAssigned`.

---

## Phase 7 — Simulator Job Navigation
**Goal:** Simulator vehicles deviate toward requesters when jobs are accepted and return to loops on completion.

| Story | Repo | Description |
|-------|------|-------------|
| SIM-006 | Simulator | Navigate straight-line toward requester on job acceptance |
| SIM-007 | Simulator | Return to nearest loop waypoint on job completion |

**Exit criteria:** During a simulated job, vehicle position updates show movement toward the requester's coordinates, then resume loop traversal after the job ends.

---

## Phase 8 — Frontend Foundation
**Goal:** Users can log in and are routed to the correct view. JWT lifecycle is handled.

| Story | Repo | Description |
|-------|------|-------------|
| FE-001 | Frontend | Login screen → JWT → route by role |
| FE-002 | Frontend | JWT expiry detection → redirect to login |

**Depends on:** Phase 1 (BE-001, BE-002)
**Exit criteria:** Each of the three persona accounts can log in and land on their respective view shell.

---

## Phase 9 — Frontend ServiceRep Flow
**Goal:** A ServiceRep can claim a vehicle, receive and respond to job offers, navigate to the requester, and mark the job complete.

| Story | Repo | Description |
|-------|------|-------------|
| FE-007 | Frontend | Vehicle selection and claim screen |
| FE-008 | Frontend | Job offer screen with 60-second countdown |
| FE-009 | Frontend | Accept offer → navigate to active job view |
| FE-010 | Frontend | Decline offer → return to idle |
| FE-011 | Frontend | Active job map with live position and ETA |
| FE-012 | Frontend | "I've Arrived" button → on-site view |
| FE-013 | Frontend | "Mark Complete" → return to idle |
| FE-014 | Frontend | Release vehicle from menu |

**Depends on:** Phase 8, Phases 2–5 (vehicle + job offer + state transition endpoints)
**Exit criteria:** A ServiceRep user can complete a full job end-to-end in the UI with the simulator driving the other side.

---

## Phase 10 — Frontend Requester Flow
**Goal:** A Requester can submit a request, wait for assignment, and track their rep live.

| Story | Repo | Description |
|-------|------|-------------|
| FE-015 | Frontend | Request submission form (map + DTC picker) |
| FE-016 | Frontend | Pending spinner — waiting for rep assignment |
| FE-017 | Frontend | Live rep tracking map with ETA |
| FE-018 | Frontend | Redirect notification |
| FE-019 | Frontend | Service complete screen |

**Depends on:** Phase 8, Phases 3–5 (service request + job offer + state transition endpoints)
**Exit criteria:** A Requester user can submit a request and see a rep moving toward them in real time; redirect and completion notifications display correctly.

---

## Phase 11 — Frontend Dispatcher Flow
**Goal:** A Dispatcher can monitor the full fleet, manage the request queue, redirect reps, and respond to offline alerts.

| Story | Repo | Description |
|-------|------|-------------|
| FE-003 | Frontend | Live fleet map with colour-coded rep markers |
| FE-004 | Frontend | Active request queue with tier badges |
| FE-005 | Frontend | Redirect controls with confirmation dialog |
| FE-006 | Frontend | Rep offline alert banner |

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
| Frontend | FE-001 – FE-019 (19 stories) | 8–11 |
| **Total** | **51 stories** | **11 phases** |
