# Data Flow

> **Source diagrams:** [`data-flow.puml`](data-flow.puml) — contains sequence diagrams for position updates, normal request lifecycle, priority redirect, and rep offline flows.

## Real-Time Position Updates

```
Simulator ──POST position──► Backend API
                                  │
                          check 15-mile threshold
                          recalculate ETA
                                  │
                          SignalR broadcast
                         /        |        \
              Dispatchers    Rep (own)   Requester (if assigned)
```

The simulator pushes vehicle position updates every 3 seconds. The backend owns all business logic triggered by position updates — it checks whether any En Route rep has crossed the 15-mile threshold and recalculates ETA for the requester.

---

## Flow 1 — Normal Request Lifecycle

```
Requester submits request
(GPS location + DTC selection)
         │
         ▼
Backend: find nearest qualified rep
(Haversine distance, equipment match,
 Available or En Route state,
 tiebreaker: longest Available)
         │
         ▼
Job offer sent to best rep
(60-second countdown begins)
         │
    ┌────┴────┐
  Accept    Decline/Expire
    │            │
    │        find next best rep
    │        (repeat until accepted
    │         or all exhausted)
    ▼
Request → Assigned
Rep → En Route
Requester sees: rep name, ETA, live map
Dispatcher sees: rep state updated on fleet map
         │
         ▼
Backend detects rep within 15 miles
Rep state → Within 15 Miles
(redirect protection activates)
         │
         ▼
Rep taps "I've Arrived"
Rep → On Site
Request → In Progress
         │
         ▼
Rep taps "Mark Complete"
Rep → Available
Request → Completed
Requester sees: "Your service is complete"
Request disappears from dispatcher map
```

---

## Flow 2 — No Qualified Rep Available

```
Requester submits request
         │
Backend: no qualified rep found
(or all qualified reps declined/expired)
         │
         ▼
Request stays → Pending
Requester sees: spinner ("finding your technician")
Dispatcher receives notification
         │
         ▼
When a rep becomes Available:
backend re-runs matching algorithm
         │
         ▼
Resumes normal Flow 1 from job offer step
```

---

## Flow 3 — Priority Redirect

```
Higher-tier request arrives (e.g. Gold)
         │
Dispatcher sees suggested match:
  best rep is currently En Route to a lower-tier request
         │
Dispatcher confirms redirect
         │
    ┌────┴──────────────────────┐
    │                           │
    ▼                           ▼
Rep receives new destination  Displaced request → Pending
Rep → En Route (new job)      System finds next best rep
Cooldown starts (5 min)       for displaced requester
                               (same matching algorithm)
         │
         ▼
When new rep accepts displaced request:
Displaced requester notified:
"Our apologies, we needed to redirect [name].
 [new name] is heading your way." + new ETA
```

### Redirect Rules Summary

| Situation | Can Redirect? |
|-----------|--------------|
| Rep is Available | N/A — normal assignment, not a redirect |
| Rep is En Route, no cooldown | Yes — any higher tier |
| Rep is En Route, in 5-min cooldown, Silver/Bronze request | No |
| Rep is En Route, in 5-min cooldown, Gold request | Yes — Gold overrides cooldown |
| Rep is Within 15 Miles | No — absolute protection, no tier can override |
| Rep is On Site | No — absolute protection, no tier can override |

---

## Flow 4 — Rep Offline Mid-Job

```
Rep goes Offline (crash or logout)
while En Route or On Site
         │
         ▼
Job → Pending
Dispatcher notified
Vehicle stays Claimed
         │
    ┌────┴────────────────────┐
    │                         │
Rep reconnects           Dispatcher force-releases
and re-logs in           vehicle manually
    │                         │
    ▼                         ▼
Rep reclaims             Vehicle → Unclaimed
vehicle                  Available for another rep
    │
    ▼
System re-runs matching
for the pending job
```

---

## SignalR Hub Responsibilities

| Hub | Publishers | Subscribers |
|-----|-----------|-------------|
| `VehiclePositionHub` | Backend (receives positions from Simulator via REST, fans out) | Dispatchers, Requester (assigned rep only) |
| `DispatchHub` | Backend | Dispatchers |
| `RepHub` | Backend | Individual service rep (by connection); Simulator (subscribes to receive job offers) |
| `RequesterHub` | Backend | Individual requester (by connection) |

All hubs are managed by the backend. The simulator pushes position updates via **REST** (`POST /vehicles/{id}/position`) — not via SignalR. It does subscribe to `RepHub` to receive job offers pushed by the backend.
