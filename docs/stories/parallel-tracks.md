# Parallel Tracks

> 41 stories remain across 3 repos. This document shows which work can proceed simultaneously so multiple developers can make progress without blocking each other.

**Status snapshot:** Phases 1–3 complete (auth, seed, hubs, vehicles, requests, DTCs, matching) and all 15 bugs fixed. 20 of 61 stories done. The remaining 41 span Phases 4–11, now including the **Human Takeover** stories added by [ADR-0009](../adr/0009-simulator-operates-rep-identities-and-human-takeover.md): BE-026/027/028, SIM-008/009/010, FE-023.

---

## Start Now — No Blockers

Phases 1–3 and all 15 bugs are complete (including BE-014, the matching algorithm). The items unblocked today are the start of Phase 4 backend and the frontend foundation:

| Story | Repo | Description | Why unblocked |
|-------|------|-------------|---------------|
| **BE-015–018** | Backend | Job offer lifecycle (pending/accept/decline/expire) | BE-014 done |
| **FE-001** | Frontend | Login screen → route by role | BE-001 (POST /auth/login) is done |
| **FE-002** | Frontend | JWT expiry detection | BE-001 done; pure client-side logic |
| **FE-021** | Frontend | App shell, nav menu & logout | BE-002 done; per-persona shell |

FE-001, FE-002, and FE-021 are independent of each other and of the backend Phase 4 work.

---

## Three Parallel Tracks

```
TIME ──────────────────────────────────────────────────────────────────►

TRACK A: BACKEND ─────────────────────────────────────────────────────
 [NOW]  BE-014 → Phase 4 ───────────────────────────────────────
                  BE-015 ┐                                       │
                  BE-016 │ (parallel within phase)               │
                  BE-017 │                                       │
                  BE-018 ┘                                       │
                           → Phase 5 ──────────────────          │
                             BE-019 ┐                  │         │
                             BE-020 │ (parallel)       │         │
                             BE-023 ┘                  │         │
                                      → Phase 6        │         │
                                        BE-021 ┐       │         │
                                        BE-022 ┘       │         │
                                                       ▼         ▼

TRACK B: FRONTEND ────────────────────────────────────────────────────
 [NOW] FE-001 ┐
 [NOW] FE-002 │
 [NOW] FE-021 ┘ (app shell)
               → ServiceRep sub-track (FE-007, FE-014, FE-020 immediately;
               │  FE-008–FE-013 after Phase 4 + 5 backend)
               → Requester sub-track (FE-015 immediately;
               │  FE-016–FE-019 after Phase 4 + 5 backend)
               → Dispatcher sub-track (FE-003, FE-004 immediately;
                  FE-005, FE-006 after Phase 5 + 6 backend)

TRACK C: SIMULATOR ───────────────────────────────────────────────────
                  SIM-005 (when Phase 4 backend starts)
                           → SIM-006 ┐ (after Phase 5 backend done)
                              SIM-007 ┘ (SIM-006 and SIM-007 sequential)
```

---

## Track A — Backend Critical Path

Each wave unlocks the next. Stories within the same wave are independent and can be worked in parallel.

### Wave 1 — Phase 3 Tail (unblocked now)

| Story | Description | Depends on |
|-------|-------------|------------|
| ~~BE-013~~ | ~~`GET /service-requests/{id}`~~ — done ✓ | BE-011 ✓ |
| BE-014 | Matching algorithm: filter → sort → tiebreaker → job offer | BE-010 ✓ |

**BE-013 is done.** BE-014 remains and is the more critical story — it unlocks all of Phase 4.

---

### Wave 2 — Phase 4: Job Offer Lifecycle (unblocked when BE-014 done)

| Story | Description | Depends on |
|-------|-------------|------------|
| BE-015 | `GET /job-offers/pending` | BE-014 |
| BE-016 | `POST /job-offers/{id}/accept` + state transitions + SignalR | BE-014 |
| BE-017 | `POST /job-offers/{id}/decline` + re-run matching | BE-014 |
| BE-018 | Background job: expire offers after 60s + re-run matching | BE-014 |

**All four can run in parallel.** BE-016 and BE-017 are the most complex (state transitions, SignalR events).

---

### Wave 3 — Phase 5: Rep State, Resilience & Human Takeover (unblocked when Phase 4 done)

| Story | Description | Depends on |
|-------|-------------|------------|
| BE-019 | `POST /rep/arrive` (EnRoute → OnSite) | Phase 4 |
| BE-020 | `POST /rep/complete` + re-run matching for pending requests | Phase 4 |
| BE-023 | `OnDisconnectedAsync` — offline detection, re-queue (re-match), DispatchHub alert | Phase 4 |
| BE-026 | `POST /vehicles/{id}/take-over` — idle rep assumes idle vehicle, supersedes simulator | Phase 2 (claim/release) |
| BE-027 | `GET /simulator/fleet-state` — Simulator-role fleet/job-state read | Phase 4 (job state) |
| BE-028 | `POST /rep/heartbeat` + go-off-duty + human-controlled timeout | BE-026 |

**All can run in parallel within the wave.** BE-026/027/028 underpin the human-takeover flow and unblock the Phase 7 simulator reconciliation stories.

---

### Wave 4 — Phase 6: Dispatcher Operations (unblocked when Phase 5 done)

| Story | Description | Depends on |
|-------|-------------|------------|
| BE-021 | `GET /dispatcher/fleet` — full fleet state snapshot | Phase 5 |
| BE-022 | `POST /dispatcher/redirect` — eligibility, cooldown, displaced-request flow | Phase 5 |

**Both can run in parallel.** BE-022 is the most complex story in the entire backend.

---

## Track B — Frontend

FE-001 and FE-002 are unblocked now. Once auth is wired, all three persona sub-tracks can be scaffolded in parallel — build screens against stubs first, then cut over to live backend at each integration gate.

### Foundation (unblocked now)

| Story | Description | Depends on |
|-------|-------------|------------|
| FE-001 | Login screen → route by role | BE-001 ✓ |
| FE-002 | JWT expiry detection → redirect to login | BE-001 ✓ |
| FE-021 | App shell, navigation menu & logout (per-persona) | BE-002 ✓ |

---

### ServiceRep Sub-track (FE-007 and FE-014 unblock immediately after FE-001)

| Story | Description | Integration gate |
|-------|-------------|-----------------|
| FE-007 | Take over an idle vehicle (dropdown) — supersedes simulator | BE-026 (take-over) |
| FE-020 | Idle / waiting-for-offers view | BE-015 (pending offer) — stub now, live Phase 4 |
| FE-014 | Release vehicle from menu (go off-duty; vehicle parks) | BE-006 ✓ — live now |
| FE-023 | Heartbeat while on duty + clean go-off-duty | BE-028 (heartbeat) |
| FE-008 | Job offer screen with 60s countdown | Phase 4 backend |
| FE-009 | Accept offer → navigate to active job view | Phase 4 backend |
| FE-010 | Decline offer → return to idle | Phase 4 backend |
| FE-011 | Active job map with live (simulator-driven) position and ETA | Phase 4 + Phase 5 backend |
| FE-012 | "I've Arrived" button → on-site view | Phase 5 backend (BE-019) |
| FE-013 | "Mark Complete" → return to idle | Phase 5 backend (BE-020) |

FE-014 can go live immediately. FE-007 + FE-023 need the takeover/heartbeat endpoints (BE-026/028, Phase 5). FE-008–FE-013 can be scaffolded against stubs; integrate with live backend once Phase 4 is done.

---

### Requester Sub-track (FE-015 unblocks immediately after FE-001)

| Story | Description | Integration gate |
|-------|-------------|-----------------|
| FE-015 | Request submission form (map + DTC picker) | BE-009/010 ✓ — live now |
| FE-016 | Pending spinner — waiting for rep assignment | Phase 4 backend (BE-014 triggers matching) |
| FE-017 | Live rep tracking map with ETA | Phase 4 backend |
| FE-018 | Redirect notification | Phase 6 backend (BE-022) |
| FE-019 | Service complete screen | Phase 5 backend (BE-020) |

FE-015 can go live immediately. FE-016 and FE-017 need Phase 4 backend.

---

### Dispatcher Sub-track (FE-003 and FE-004 unblock immediately after FE-001)

| Story | Description | Integration gate |
|-------|-------------|-----------------|
| FE-003 | Live fleet map with colour-coded markers | BE-003 ✓ for initial load; full state (in-job reps) needs Phase 4+ |
| FE-004 | Active request queue with tier badges | BE-011 ✓ for initial load; Phase 4 for full lifecycle states |
| FE-006 | Rep offline alert banner | Phase 5 backend (BE-023) |
| FE-005 | Redirect controls + confirmation dialog | Phase 6 backend (BE-022) |

FE-003 and FE-004 can display partial data now (vehicles + requests are seeded); full fidelity once Phases 4–6 are done.

---

## Track C — Simulator

| Story | Description | Depends on |
|-------|-------------|------------|
| SIM-005 | Auto-accept (~85%) / auto-decline (~15%) per automated rep | Phase 4 backend (BE-015, BE-016, BE-017) |
| SIM-006 | Navigate toward requester on accept (automated **or** human); hold for a human's Arrived/Complete | Phase 5 backend (BE-019) + SIM-005 + BE-027 |
| SIM-007 | Return to nearest loop waypoint on job completion | Phase 5 backend (BE-020) + SIM-006 |
| SIM-008 | Reconcile against `GET /simulator/fleet-state` each tick; operate only non-human reps | BE-027 |
| SIM-009 | Yield a rep on human takeover; never re-assume for the run | BE-026/028 + SIM-008 |
| SIM-010 | Automated on-site work dwell (randomized 120–240s) | SIM-006 |

SIM-005 can begin once Phase 4 backend is in progress. SIM-008 (reconciliation) is the backbone the others build on and needs BE-027; SIM-009 (yield) needs the takeover/heartbeat endpoints. SIM-006/007/010 are the navigation + dwell behaviors.

---

## Integration Gate Summary

| Gate | Unblocks |
|------|----------|
| BE-014 done ✓ | Phase 4 backend (BE-015–018), FE-016 stubs can be finalized |
| Phase 4 done | Phase 5 backend, SIM-005 live, FE-008–FE-010 live, FE-016–FE-017 live |
| BE-026/027/028 done | FE-007 takeover + FE-023 heartbeat live, SIM-008/009 reconciliation+yield |
| Phase 5 done | Phase 6 backend, SIM-006+007+010, FE-011–FE-013 live, FE-019 live, FE-006 live |
| Phase 6 done | FE-005 live, FE-018 live |

---

## Story Count

| Track | Stories | Remaining |
|-------|---------|-----------|
| Track A — Backend | 12 | BE-015–018, BE-019–020, BE-023, BE-021–022, BE-026–028 |
| Track C — Simulator | 6 | SIM-005–010 |
| Track B — Frontend Auth + Shell | 3 | FE-001, FE-002, FE-021 |
| Track B — ServiceRep | 10 | FE-007–FE-014, FE-020, FE-023 |
| Track B — Requester | 5 | FE-015–FE-019 |
| Track B — Dispatcher | 5 | FE-003–FE-006, FE-022 |
| **Total** | **41** | |
| Open bugs | 0 | BUG-001 – BUG-015 all fixed (see `bug.md`) |
