# Parallel Tracks

> 34 stories remain across 3 repos, plus 15 open bugs. This document shows which work can proceed simultaneously so multiple developers can make progress without blocking each other.

**Status snapshot:** Phases 1–2 complete; Phase 3 partially complete (BE-014 still pending). 19 of 53 stories done. 15 open bugs ([`bug.md`](bug.md)) are sequenced ahead of BE-014 (BUG-001/002 from the backend/frontend cross-check; BUG-003–015 from the full-repo audit — all doc/pipeline fixes).

---

## Start Now — No Blockers

These items have all dependencies satisfied today:

| Story | Repo | Description | Why unblocked |
|-------|------|-------------|---------------|
| **BUG-001** | Backend | Add force-release event to BE-025 / BE-007 | Doc fix; no code dependencies |
| **BUG-002** | Frontend | Add FE-022 force-release story + cross-ref FE-006 | Doc fix; no code dependencies |
| **BE-014** | Backend | Matching algorithm | BE-010 (POST requests) is done |
| **FE-001** | Frontend | Login screen → route by role | BE-001 (POST /auth/login) is done |
| **FE-002** | Frontend | JWT expiry detection | BE-001 done; pure client-side logic |
| **FE-021** | Frontend | App shell, nav menu & logout | BE-002 done; per-persona shell |

The two bugs are documentation-only fixes (handle via `/ship-it`, not the TDD pipeline) and can be done anytime. BE-014 is independent of the frontend work; FE-001, FE-002, and FE-021 are also independent of each other. *(BE-013 — `GET /service-requests/{id}` — is now done.)*

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

### Wave 3 — Phase 5: Rep State Transitions & Resilience (unblocked when Phase 4 done)

| Story | Description | Depends on |
|-------|-------------|------------|
| BE-019 | `POST /rep/arrive` (EnRoute → OnSite) | Phase 4 |
| BE-020 | `POST /rep/complete` + re-run matching for pending requests | Phase 4 |
| BE-023 | `OnDisconnectedAsync` — offline detection, re-queue, DispatchHub alert | Phase 4 |

**All three can run in parallel.**

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
| FE-007 | Vehicle selection and claim screen | BE-004/005 ✓ — live now |
| FE-020 | Idle / waiting-for-offers view | BE-015 (pending offer) — stub now, live Phase 4 |
| FE-014 | Release vehicle from menu | BE-006 ✓ — live now |
| FE-008 | Job offer screen with 60s countdown | Phase 4 backend |
| FE-009 | Accept offer → navigate to active job view | Phase 4 backend |
| FE-010 | Decline offer → return to idle | Phase 4 backend |
| FE-011 | Active job map with live position and ETA | Phase 4 + Phase 5 backend |
| FE-012 | "I've Arrived" button → on-site view | Phase 5 backend (BE-019) |
| FE-013 | "Mark Complete" → return to idle | Phase 5 backend (BE-020) |

FE-007 and FE-014 can go live immediately. FE-008–FE-013 can be scaffolded against stubs; integrate with live backend once Phase 4 is done.

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
| SIM-005 | Auto-accept (~85%) / auto-decline (~15%) job offers | Phase 4 backend (BE-015, BE-016, BE-017) |
| SIM-006 | Navigate straight-line toward requester on job acceptance | Phase 5 backend (BE-019) + SIM-005 |
| SIM-007 | Return to nearest loop waypoint on job completion | Phase 5 backend (BE-020) + SIM-006 |

SIM-005 can begin once Phase 4 backend is in progress (implement the handler, test against live when Phase 4 completes). SIM-006 and SIM-007 are sequential — SIM-007 is the cleanup step after SIM-006.

---

## Integration Gate Summary

| Gate | Unblocks |
|------|----------|
| BE-014 done | Phase 4 backend (BE-015–018), FE-016 stubs can be finalized |
| Phase 4 done | Phase 5 backend, SIM-005 live, FE-008–FE-010 live, FE-016–FE-017 live |
| Phase 5 done | Phase 6 backend, SIM-006+007, FE-011–FE-013 live, FE-019 live, FE-006 live |
| Phase 6 done | FE-005 live, FE-018 live |

---

## Story Count

| Track | Stories | Remaining |
|-------|---------|-----------|
| Track A — Backend | 10 | BE-014, BE-015–018, BE-019–020, BE-023, BE-021–022 |
| Track C — Simulator | 3 | SIM-005, SIM-006, SIM-007 |
| Track B — Frontend Auth + Shell | 3 | FE-001, FE-002, FE-021 |
| Track B — ServiceRep | 9 | FE-007–FE-014, FE-020 |
| Track B — Requester | 5 | FE-015–FE-019 |
| Track B — Dispatcher | 4 | FE-003–FE-006 |
| **Total** | **34** | |
| Open bugs | 15 | BUG-001 – BUG-015 (see `bug.md`) |
