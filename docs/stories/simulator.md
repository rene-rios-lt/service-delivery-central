# Simulator User Stories

> **Repo:** `service-delivery-simulator`
> These stories cover all behaviours of the .NET 10 Worker Service that drives the POC with 8 simulated vehicles across Iowa.

---

## Epic: Authentication & Startup

### SIM-001 — Authenticate with the backend
**As the** Simulator,
**I want to** authenticate with the backend using the pre-seeded simulator service account credentials on startup,
**so that** all subsequent API calls carry a valid JWT.

**Acceptance Criteria:**
- `POST /auth/login` called with simulator username and password from `SimulatorOptions`
- JWT stored in `BackendApiClient` and sent as `Authorization: Bearer` on every request
- If authentication fails, startup aborts with a clear error log
- If the JWT expires mid-run, re-authentication is attempted before the next API call

---

### SIM-002 — Connect to RepHub on startup
**As the** Simulator,
**I want to** connect to the backend's SignalR `RepHub` after authenticating,
**so that** job offers sent to the simulator service account are received in real time.

**Acceptance Criteria:**
- `HubConnection` built to `{BackendBaseUrl}/hubs/rep` with JWT Bearer token
- Handler registered for the `"JobOfferReceived"` event before any `VehicleWorker` starts
- On disconnect, automatic reconnect is attempted with exponential back-off
- Connection failure logged clearly; workers continue sending position updates independently

---

## Epic: Vehicle Position Updates

### SIM-003 — Advance vehicle along Iowa route loop
**As the** Simulator,
**I want to** advance each of the 8 vehicles along its pre-determined Iowa route waypoints every 3 seconds,
**so that** the backend receives realistic, continuously changing position data.

**Acceptance Criteria:**
- Each vehicle has a distinct ordered waypoint array covering its Iowa loop
- Position advances one waypoint per tick (every 3 seconds)
- When the last waypoint is reached, wrap back to the first (continuous loop)
- Each vehicle runs in its own `VehicleWorker` `BackgroundService`
- Cancellation token respected — worker exits cleanly on shutdown

---

### SIM-004 — POST position update to backend
**As the** Simulator,
**I want to** POST each vehicle's current latitude and longitude to the backend after every position advance,
**so that** dispatchers and requesters see live vehicle movement.

**Acceptance Criteria:**
- `POST /vehicles/{id}/position` called with `{ vehicleId, latitude, longitude }` every 3 seconds per vehicle
- Uses JWT Bearer authentication
- On 401, re-authenticates and retries once before logging an error
- On transient network failure, logs the error and continues on the next tick (does not crash the worker)

---

## Epic: Job Offer Handling

### SIM-005 — Auto-respond to job offers
**As the** Simulator,
**I want to** auto-respond to incoming job offers with approximately 85% acceptance and 15% decline,
**so that** the system exercises both the acceptance and rejection flows during a demo.

**Acceptance Criteria:**
- Decision driven by `AutoDeclineRatePercent` configuration value
- A random delay of 1–5 seconds applied before responding (simulates a real rep reviewing the offer)
- Accept via `POST /job-offers/{id}/accept`
- Decline via `POST /job-offers/{id}/decline`
- On accept, the relevant `VehicleWorker` is notified to begin job navigation
- On decline or expiry, worker continues its normal loop

---

## Epic: Job Navigation

### SIM-006 — Navigate toward requester location when job accepted
**As the** Simulator,
**I want to** deviate a vehicle from its loop route and interpolate its position straight-line toward the requester's location when a job is accepted,
**so that** position updates reflect a rep heading toward the job site.

**Acceptance Criteria:**
- On job acceptance, `VehicleWorker` receives the requester's latitude and longitude
- Each subsequent tick advances the vehicle position linearly toward the requester's coordinates
- Position updates continue to be POSTed to the backend every 3 seconds during navigation
- Normal loop waypoint traversal is suspended for the duration of the job

---

### SIM-007 — Return to loop after job completion
**As the** Simulator,
**I want to** return the vehicle to the nearest loop waypoint after the job is marked complete,
**so that** the vehicle resumes its normal patrol route.

**Acceptance Criteria:**
- On job completion signal, the nearest loop waypoint is identified using Haversine distance
- Vehicle resumes traversal from that waypoint on the next tick
- Job navigation state is cleared; worker returns to standard loop behaviour
