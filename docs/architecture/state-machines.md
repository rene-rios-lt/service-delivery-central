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
| **Offline** | Rep has not claimed a vehicle. Not visible on map, not eligible for dispatch. | N/A |
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
| Any → Offline (mid-job) | App crash or rep logout — job returns to Pending, dispatcher notified. **Detection mechanism (POC):** SignalR `OnDisconnectedAsync` callback on the RepHub. When a rep's connection drops, the backend immediately transitions the rep to Offline, moves any active job back to Pending, and notifies dispatchers. |

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

- Vehicle is claimed by the first rep to select it (first come first served)
- Vehicle is released when the rep explicitly logs out at end of day
- If a rep's app crashes, the vehicle stays Claimed until the rep logs back in and releases it, or a dispatcher force-releases it
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
