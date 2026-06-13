# State Machines

> **Source diagrams:** [`state-machines.puml`](state-machines.puml) — contains all four state machines as PlantUML source. Render with any PlantUML-compatible tool or the [PlantUML online server](https://www.plantuml.com/plantuml).

## Service Rep States

```
[Offline] ──── claims vehicle ────► [Available]
                                         │
                                   job accepted
                                         │
                                         ▼
                                    [En Route]
                                         │
                              backend detects < 15 mi
                                         │
                                         ▼
                                [Within 15 Miles]
                                         │
                              rep taps "I've Arrived"
                                         │
                                         ▼
                                     [On Site]
                                         │
                               rep taps "Mark Complete"
                                         │
                                         ▼
                                    [Available]
```

| State | Description | Can Be Redirected? |
|-------|-------------|-------------------|
| **Offline** | Rep has not claimed a vehicle (or a human-controlled rep logged out / timed out). Not visible on map, not eligible for dispatch. | N/A |
| **Available** | Rep has claimed a vehicle and has no active job. Eligible for assignment. | N/A — receives new assignments normally |
| **En Route** | Rep accepted a job and is traveling to the requester. | Yes — dispatcher can hard-reassign to a higher-tier request (subject to cooldown rules) |
| **Within 15 Miles** | Backend detected rep is within 15 straight-line miles of destination. | No — protected, no tier can override |
| **On Site** | Rep manually confirmed arrival. | No — protected, no tier can override |

### State Transition Owners

| Transition | Owner |
|-----------|-------|
| Offline → Available | Rep (claims vehicle at session start) |
| Available → En Route | System (rep accepts job offer) |
| En Route → Within 15 Miles | **Backend** (checks Haversine distance on every position update from simulator) |
| Within 15 Miles → On Site | Rep (taps "I've Arrived") |
| On Site → Available | Rep (taps "Mark Complete") |
| Any → Offline (mid-job) | App crash or rep logout — job returns to Pending and is **re-matched** to another available rep, dispatcher notified. **Detection mechanism (POC):** SignalR `OnDisconnectedAsync` callback on the RepHub (plus a heartbeat timeout for human devices). When a rep's connection drops, the backend immediately transitions the rep to Offline, moves any active job back to Pending, and notifies dispatchers. |

### Rep Ownership — Simulated vs. Human

This state machine is identical whether a rep is driven by the simulator or by a human — but *who* drives the transitions differs, and that is tracked by a **human-controlled** marker on the rep (see [ADR-0009](../adr/0009-simulator-operates-rep-identities-and-human-takeover.md)):

| Ownership | Who drives the transitions | Goes Offline? |
|-----------|----------------------------|---------------|
| **Simulator-controlled** (default for `rep1…rep8`) | The simulator: auto-claims a vehicle, auto-accepts/declines, auto-arrives, auto-completes. Position is simulator-driven. | No — the simulator keeps the rep running continuously |
| **Human-controlled** (after takeover) | The human on the device: Accept/Decline, "I've Arrived", "Mark Complete". Position is *still* simulator-driven (navigates after Accept, holds for Arrived). | Yes — on logout or heartbeat timeout, after which the rep+vehicle park and the simulator does **not** re-assume them for the run |

**Takeover transition:** a human assumes an *idle* simulator-controlled rep (no active job) and selects an *idle* vehicle; the rep flips to human-controlled and the simulator relinquishes it. **Redirect applies uniformly** — a dispatcher can redirect an En Route rep whether simulator- or human-controlled (the simulator re-navigates the truck; a human device shows the redirect).

### Redirect Cooldown

After a rep is redirected, a **5-minute cooldown** prevents immediate re-redirect:
- **Silver and Bronze** tier requests must respect the cooldown — cannot redirect a rep in cooldown
- **Gold** tier overrides the cooldown — can redirect even during the 5-minute window
- The cooldown does NOT override Within 15 Miles or On Site protection — those are absolute

---

## Service Request States

```
[Pending] ──── rep accepts offer ────► [Assigned]
    ▲                                       │
    │                              rep reaches On Site
    │                                       │
    │ rep redirected                        ▼
    └──────────────────────────────── [In Progress]
                                            │
                                  rep taps "Mark Complete"
                                            │
                                            ▼
                                       [Completed]
```

| State | Description |
|-------|-------------|
| **Pending** | No rep assigned. Waiting for a match. |
| **Assigned** | A rep accepted the job and is En Route or Within 15 Miles. |
| **In Progress** | Rep has marked themselves On Site. Work is underway. |
| **Completed** | Rep marked the job complete. Request is closed. |

### Rep State → Request State Alignment

| Rep State Change | Request State Change |
|-----------------|---------------------|
| Rep accepts offer | Pending → Assigned |
| Rep reaches Within 15 Miles | Assigned (no change) |
| Rep taps "I've Arrived" (On Site) | Assigned → In Progress |
| Rep taps "Mark Complete" | In Progress → Completed |
| Rep is redirected | Assigned → Pending |
| Rep goes Offline mid-job | Assigned or In Progress → Pending |

---

## Vehicle States

| State | Description |
|-------|-------------|
| **Unclaimed** | No rep has claimed this vehicle for today. Available for selection. |
| **Claimed** | A rep claimed this vehicle at session start. Locked to that rep for the day. |

- Vehicle is claimed by the first rep to select it (first come first served). In the POC the simulator claims a vehicle for each automated rep at startup
- Vehicle is released when the rep explicitly logs out at end of day
- A **human takeover** of an idle vehicle is a release-then-claim: the simulator's claim on that idle vehicle is released and the vehicle is immediately claimed for the human rep (see [ADR-0009](../adr/0009-simulator-operates-rep-identities-and-human-takeover.md))
- If a rep's app crashes, the vehicle stays Claimed until the rep logs back in and releases it, or a dispatcher force-releases it. A vehicle a human took over then parks (the simulator does not re-claim it for the run)
- Dispatcher can force-release any vehicle at any time

---

## Job Offer States

| State | Description |
|-------|-------------|
| **Pending** | Offer sent to rep, awaiting response. 60-second countdown active. |
| **Accepted** | Rep accepted — request moves to Assigned. |
| **Declined** | Rep explicitly declined — system moves to next best qualified rep. |
| **Expired** | 60 seconds elapsed with no response — treated identically to Declined. Rep is permanently skipped for this job. |

If all qualified reps reach Declined or Expired status for a given request, the request returns to Pending and the dispatcher is notified.
