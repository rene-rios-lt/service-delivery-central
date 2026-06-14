# Data Flow

> **Source diagram:** [`data-flow.puml`](data-flow.puml) — contains sequence diagrams for position updates and all 4 request lifecycle flows: normal request, no qualified rep available, priority redirect, and rep offline.

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

The simulator pushes vehicle position updates every 3 seconds, for **every** vehicle — including one a human has taken over. The simulator drives each truck from its rep's backend job-state: looping while idle, navigating straight-line toward the requester once the job is accepted (by an automated rep **or** a human), and holding at the requester until the job completes. The backend owns all business logic triggered by position updates — it checks whether any En Route rep has crossed the 15-mile threshold and recalculates ETA for the requester. (The human's device never reports GPS; it only sends decisions. See [ADR-0009](../adr/0009-simulator-operates-rep-identities-and-human-takeover.md).)

---

## Flow 1 — Normal Request Lifecycle

```
Requester submits request
(GPS location + DTC selection)
         │
         ▼
Backend: find nearest qualified rep
(Haversine distance, equipment match,
 Available state only,
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
Requester sees: "Your rep has arrived" (RepArrived via RequesterHub)
Dispatcher sees: rep state → On Site (RepStateChanged via DispatchHub)
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
Job → Pending  (re-matched to another available rep)
Dispatcher notified
Vehicle stays Claimed (then released — see below)
         │
    ┌────┴────────────────────────────────┐
    │                                      │
Automated (simulator) rep            Human rep "goes home"
    │                                      │
    ▼                                      ▼
Simulator reconciler notices         Rep parks; vehicle goes
and resumes that rep on its          off-duty. The simulator
vehicle (normal loop)                NEVER re-assumes a rep a
    │                                human took over (sticky).
    ▼                                      │
System re-runs matching ◄──────────────────┘
for the pending job (any available rep)
```

**Human takeover is sticky.** When a human-controlled rep drops (logout or heartbeat timeout), the rep goes Offline and its vehicle parks — the simulator does **not** bring that rep/vehicle back for the rest of the run ("gone home for the night"). Any job they abandoned mid-flight is re-matched to another available rep (in practice an automated one). A dispatcher may still `force-release` the parked vehicle. This contrasts with an *automated* rep, which the simulator's reconciler simply keeps driving.

---

## Flow 5 — Human Takeover

```
Human logs in on a device
as a rep account (e.g. rep3)
         │
         ▼
Sees a dropdown of IDLE vehicles
(not en route / not on a job)
         │
   selects one (e.g. V-002)
         │
         ▼
POST /vehicles/{id}/take-over
Backend: release prior (simulator) claim on V-002,
end rep3's prior session, claim V-002 for rep3 (human),
mark rep3 human-controlled
         │
         ▼
Simulator reconciler (next tick) sees rep3 is
human-controlled → relinquishes rep3 and rebalances
its remaining reps onto the freed vehicle
         │
         ▼
From now on, for rep3's truck:
  • the HUMAN makes decisions — Accept/Decline an offer,
    tap "I've Arrived", tap "Mark Complete"
  • the SIMULATOR drives the truck's position from
    rep3's job-state (navigates to requester on Accept,
    then HOLDS until the human taps Arrived)
         │
   device sends periodic heartbeat
         │
         ▼
On logout / heartbeat timeout → rep3 Offline,
V-002 parks; simulator does NOT re-assume (see Flow 4)
```

Eligibility: a human may take over only an **idle** rep (no active job) and an **idle** vehicle. Multiple humans can each take a distinct rep + vehicle concurrently — the single-active-session rule and the vehicle claim mutex keep them from colliding.

---

## SignalR Hub Responsibilities

| Hub | Publishers | Subscribers |
|-----|-----------|-------------|
| `VehiclePositionHub` | Backend (receives positions from Simulator via REST, fans out) | Dispatchers, Requester (assigned rep only) |
| `DispatchHub` | Backend | Dispatchers |
| `RepHub` | Backend | Each service rep by connection — a human on a device, **or** the simulator connected as that automated rep (rep1–rep8) to receive its offers |
| `RequesterHub` | Backend | Individual requester (by connection) |

All hubs are managed by the backend. The simulator pushes position updates via **REST** (`POST /vehicles/{id}/position`, as the `Simulator`-role account) — not via SignalR. For job decisions it connects to `RepHub` once **per automated rep** (logged in as `rep1…rep8`) to receive the offers the matching engine routes to those reps; it stops operating any rep a human has taken over.
