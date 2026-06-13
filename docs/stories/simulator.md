# Simulator User Stories

> **Repo:** `service-delivery-simulator`
> These stories cover all behaviours of the .NET 10 Worker Service that drives the POC across Iowa. Per [ADR-0009](../adr/0009-simulator-operates-rep-identities-and-human-takeover.md), the simulator operates the seeded rep accounts (`rep1…rep8`) as autonomous drivers and holds a `Simulator`-role account used only to post positions. A human can take over any idle rep from a real device, after which the simulator drives that truck's position but the human makes the decisions.

---

## Epic: Authentication & Startup

### SIM-001 — Authenticate as the rep accounts and the position account
**As the** Simulator,
**I want to** authenticate on startup as each seeded rep account (`rep1…rep8`) and as the `Simulator`-role position account,
**so that** I can make job decisions on behalf of automated reps and post vehicle positions.

**Acceptance Criteria:**
- `POST /auth/login` is called for each operated rep (`rep1@dealer.com`…`rep8@dealer.com`, shared `RepPassword`) and once for the `Simulator`-role account; each JWT is stored and sent as `Authorization: Bearer` on that identity's requests
- The `Simulator`-role token is used for position posts and the fleet-state read; each rep token is used for that rep's claim, offers, and accept/arrive/complete
- If any authentication fails, startup logs a clear error; the position account failing aborts startup, a single rep failing skips that rep
- If a JWT expires mid-run, re-authentication is attempted before the next API call on that identity

---

### SIM-002 — Connect to RepHub per automated rep
**As the** Simulator,
**I want to** open a `RepHub` SignalR connection for each automated rep after authenticating,
**so that** job offers the matching engine routes to those reps are received in real time.

**Acceptance Criteria:**
- One `HubConnection` to `{BackendBaseUrl}/hubs/rep` per operated rep, each carrying that rep's JWT (so the connection joins that rep's `rep:{repId}` group)
- A `"JobOfferReceived"` handler is registered per connection before that rep begins driving
- On disconnect, automatic reconnect is attempted with exponential back-off
- A rep currently controlled by a human is **not** operated by the simulator — no offer handling for it (see SIM-009)
- Connection failure is logged clearly; position updates continue independently

---

### SIM-011 — Retrofit the per-rep identity model (reconcile SIM-001/SIM-002)
**As the** Simulator,
**I want to** replace the single `Simulator`-account authentication and shared `RepHub` connection with the per-rep identity model that SIM-001 and SIM-002 already specify,
**so that** the simulator can act as each `rep1…rep8` individually — the prerequisite for auto-responding to job offers (SIM-005) and yielding cleanly to human takeover (SIM-008 / SIM-009).

> **Why this exists:** SIM-001/SIM-002 were implemented and merged against an earlier single-service-account design, then their acceptance criteria were rewritten for the ADR-0009 per-rep model — but the code was never brought along. As merged: `SimulatorOptions` carries only `SimulatorEmail`/`SimulatorPassword`; `BackendApiClient` stores one JWT and sets a single global bearer header; `JobOfferPayload` carries no rep id; `SignalRClient` holds one shared `/hubs/rep` connection; and `AcceptJobOfferAsync`/`DeclineJobOfferAsync` are no-identity stubs. This story delivers SIM-001/SIM-002's (already-correct) per-rep ACs without rewriting their merged history.

**Acceptance Criteria:**
- `SimulatorOptions` carries the operated rep accounts (`rep1@dealer.com`…`rep8@dealer.com`) with a shared `RepPassword`, alongside the existing `Simulator`-role position account
- A per-rep identity/session abstraction stores one JWT per rep (plus the `Simulator` token) and re-authenticates each identity independently on expiry (SIM-001)
- The `Simulator`-role token is used only for position posts and the fleet-state read; each rep's token is used for that rep's offers and accept/decline (SIM-001)
- One `RepHub` connection per operated rep, each carrying that rep's JWT (joining its `rep:{repId}` group), with a per-connection `JobOfferReceived` handler that attributes each offer to the owning rep (SIM-002)
- `IBackendApiClient.AcceptJobOfferAsync` / `DeclineJobOfferAsync` take the responding rep's identity and call `POST /job-offers/{id}/accept` | `/decline` with that rep's bearer token — replacing the current no-identity stubs (so accept/decline satisfies the backend's JWT `NameIdentifier` rep resolution)
- Position posting continues to work unchanged for every vehicle on the `Simulator` token
- A single rep's auth or connection failure skips only that rep; the position account failing aborts startup (SIM-001 / SIM-002)

---

## Epic: Vehicle Position Updates (Position Engine)

### SIM-003 — Advance an idle vehicle along its Iowa route loop
**As the** Simulator,
**I want to** advance each idle vehicle along its pre-determined Iowa route waypoints every 3 seconds,
**so that** the backend receives realistic, continuously changing position data while reps wait for work.

**Acceptance Criteria:**
- Each vehicle has a distinct ordered waypoint array covering its Iowa loop
- While the vehicle's rep is idle (no active job), position advances one waypoint per tick (every 3 seconds), wrapping from the last waypoint to the first
- The position engine drives **every** vehicle — whether its rep is simulator- or human-controlled (see SIM-006 for the active-job case)
- Cancellation token respected — the engine exits cleanly on shutdown

---

### SIM-004 — POST position updates for all vehicles
**As the** Simulator,
**I want to** POST each vehicle's current latitude and longitude every 3 seconds as the `Simulator`-role account,
**so that** dispatchers and requesters see live movement for the whole fleet.

**Acceptance Criteria:**
- `POST /vehicles/{id}/position` called with `{ vehicleId, latitude, longitude }` every 3 seconds for every vehicle, using the `Simulator`-role token
- Positions are **simulator-pushed**, not backend-derived; this holds for human-controlled trucks too (the device never posts GPS)
- On 401, re-authenticates the position account and retries once before logging an error
- On transient network failure, logs the error and continues on the next tick (does not crash)

---

## Epic: Job Offer Handling (Auto-Decision Engine)

### SIM-005 — Auto-respond to job offers for automated reps
**As the** Simulator,
**I want to** auto-respond to job offers for the reps I operate with ~85% acceptance and ~15% decline,
**so that** the demo fleet exercises both the acceptance and rejection flows without a human.

**Acceptance Criteria:**
- Applies **only** to reps the simulator currently operates — a rep a human has taken over is skipped entirely (the human decides)
- Decision driven by `AutoDeclineRatePercent`; a random 1–5 second delay precedes the response (simulates a rep reviewing the offer)
- Accept via `POST /job-offers/{id}/accept`, decline via `POST /job-offers/{id}/decline`, called as that rep's identity
- On accept, the position engine begins navigating that rep's vehicle toward the requester (see SIM-006)
- On decline or expiry, the vehicle continues its normal loop

---

## Epic: Job Navigation

### SIM-006 — Navigate a vehicle toward the requester on an accepted job
**As the** Simulator,
**I want to** drive a vehicle straight-line toward the requester once its rep's job is accepted — whether the rep is automated or human-controlled,
**so that** position updates reflect a rep heading to the job site.

**Acceptance Criteria:**
- The position engine reads each rep's job-state from the backend fleet-state read (see SIM-008); when a rep is `EnRoute` with an active request, its vehicle interpolates toward the requester's lat/lng each 3-second tick
- For an **automated** rep, on reaching the requester the simulator auto-marks arrival and completion (see SIM-010)
- For a **human-controlled** rep, on reaching the requester the vehicle **holds position and waits** — the simulator never calls arrive/complete for a human; the human taps "I've Arrived" / "Mark Complete"
- Normal loop traversal is suspended for the duration of the job
- If a rep is redirected (by a dispatcher), the engine re-navigates toward the new destination from the updated job-state — for automated and human reps alike

---

### SIM-007 — Return to loop after job completion
**As the** Simulator,
**I want to** return a vehicle to its nearest loop waypoint once its job completes,
**so that** the vehicle resumes its normal patrol route.

**Acceptance Criteria:**
- When a rep's active request completes (auto-completed by the simulator, or marked complete by a human), the nearest loop waypoint is identified using Haversine distance
- The vehicle resumes loop traversal from that waypoint on the next tick
- Job navigation state is cleared for that vehicle
- Does not apply to a vehicle a human has since gone off-duty on — that vehicle parks (see SIM-009)

---

## Epic: Reconciliation & Human Takeover

### SIM-008 — Reconcile against backend fleet state each tick
**As the** Simulator,
**I want to** read authoritative fleet/job-state from the backend every tick and drive each vehicle accordingly,
**so that** the simulator always reflects the real state of claims, jobs, and human takeovers.

**Acceptance Criteria:**
- Each tick the simulator calls the `Simulator`-role fleet-state read (e.g. `GET /simulator/fleet-state`) to learn, per vehicle: claiming rep, rep state, active request location, and whether the rep is `human-controlled`
- The position engine drives every vehicle from that state (idle loop / navigate / hold)
- The auto-decision engine operates only reps **not** marked `human-controlled`
- At startup the simulator claims a vehicle for each automated rep so they are dispatchable `Available` reps; it rebalances its operated reps onto free vehicles as availability changes

---

### SIM-009 — Yield a rep on human takeover (sticky)
**As the** Simulator,
**I want to** relinquish a rep the moment a human takes it over and never re-assume it for the rest of the run,
**so that** a human operator is never fought over or overridden by the simulator.

**Acceptance Criteria:**
- When the fleet-state read shows a rep is `human-controlled`, the simulator stops operating that rep's decisions immediately (no offers, no accept/arrive/complete)
- The simulator continues to drive that rep's truck **position** from job-state (navigate after the human accepts; hold for the human's Arrived/Complete)
- When the human goes off-duty (logout or heartbeat timeout) and the rep parks, the simulator does **not** re-assume that rep or re-claim that vehicle for the remainder of the run ("gone home for the night")
- Reps and vehicles freed by a human takeover are excluded from the simulator's rebalancing for the rest of the run

---

### SIM-010 — Automated on-site work dwell
**As the** Simulator,
**I want to** keep an automated rep on-site for a randomized 2–4 minutes before completing,
**so that** viewers see realistic "mechanic at work" dwell time on the map.

**Acceptance Criteria:**
- On reaching the requester, an automated rep calls `POST /rep/arrive`, then after a randomized **120–240 second** dwell calls `POST /rep/complete`
- The dwell is randomized per job so completions stagger across the fleet
- The 120–240s window is a code constant (no config-file knob)
- Applies to automated reps only — a human controls their own arrive/complete timing
