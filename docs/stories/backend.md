# Backend User Stories

> **Repo:** `service-delivery-backend`
> These stories cover all REST endpoints, SignalR hubs, background jobs, and the matching and redirect engines.

---

## Epic: Authentication

### BE-001 — Login and receive JWT
**As any** user (Dispatcher, ServiceRep, Requester, or Simulator),
**I want to** `POST /auth/login` with my credentials and receive a signed JWT,
**so that** I can make authenticated API calls.

**Acceptance Criteria:**
- Accepts `{ username, password }`
- Returns a signed JWT containing: `sub` (userId), `role` (Dispatcher / ServiceRep / Requester / Simulator), `tier` (Bronze / Silver / Gold / None), `dealerId`
- Returns `401` for invalid credentials
- JWT expiry configured via `appsettings.json`

---

### BE-002 — Get my profile
**As any** authenticated user,
**I want to** `GET /users/me` to retrieve my profile,
**so that** the frontend can display my name and role without decoding the JWT client-side.

**Acceptance Criteria:**
- Returns `{ userId, name, role, tier, dealerId }`
- Scoped to the authenticated user's `sub` claim
- Returns `401` if unauthenticated

---

## Epic: Vehicles

### BE-003 — List all fleet vehicles (Dispatcher)
**As a** Dispatcher,
**I want to** `GET /vehicles` to see every vehicle in my dealer's fleet with its current state and position,
**so that** I have full fleet visibility on the map.

**Acceptance Criteria:**
- Returns all vehicles scoped to the authenticated user's `dealerId`
- Each vehicle includes: `vehicleId`, `registration`, `state` (Unclaimed / Claimed), `currentRepId`, `equipment[]`, `lastPosition { lat, lng, updatedAt }`
- Requires Dispatcher role

---

### BE-004 — List available vehicles (ServiceRep)
**As a** ServiceRep,
**I want to** `GET /vehicles/available` to see only unclaimed vehicles in my dealer's fleet,
**so that** I can choose a vehicle to claim at the start of my shift.

**Acceptance Criteria:**
- Returns only `Unclaimed` vehicles for the rep's `dealerId`
- Each vehicle includes: `vehicleId`, `registration`, `equipment[]`
- Requires ServiceRep role

---

### BE-005 — Claim a vehicle
**As a** ServiceRep,
**I want to** `POST /vehicles/{id}/claim` to take ownership of a vehicle,
**so that** I have an active session and can receive job offers.

**Acceptance Criteria:**
- Vehicle transitions `Unclaimed → Claimed`
- Active rep session created linking the rep to the vehicle
- Returns `409` if the vehicle is already claimed
- Returns `409` if the rep already has an active session on another vehicle
- Uses optimistic concurrency to prevent two reps claiming the same vehicle simultaneously

---

### BE-006 — Release a vehicle
**As a** ServiceRep,
**I want to** `POST /vehicles/{id}/release` to return my vehicle to the fleet,
**so that** another rep can claim it.

**Acceptance Criteria:**
- Vehicle transitions `Claimed → Unclaimed`
- Rep's active session closed
- Returns `400` if the vehicle is not claimed by the authenticated rep
- Cannot release while an active job is `InProgress`

---

### BE-007 — Force-release a vehicle (Dispatcher)
**As a** Dispatcher,
**I want to** `POST /vehicles/{id}/force-release` to unclaim a stuck vehicle regardless of who holds it,
**so that** it becomes available to the fleet again.

**Acceptance Criteria:**
- Vehicle transitions `Claimed → Unclaimed` regardless of which rep claimed it
- Affected rep's session closed
- Requires Dispatcher role
- If the affected rep is online, they receive a SignalR notification via `DispatchHub`

---

### BE-008 — POST vehicle position (Simulator)
**As the** Simulator service account,
**I want to** `POST /vehicles/{id}/position` with the vehicle's current coordinates,
**so that** the backend can fan out position updates and enforce the 15-mile threshold.

**Acceptance Criteria:**
- Persists `{ lat, lng, timestamp }` against the vehicle
- If the vehicle's rep has an active `Assigned` request and rep state is `EnRoute`:
  - Recalculates Haversine distance to requester's location
  - If distance < 15 miles → transitions rep state to `Within15Miles`
  - Recalculates ETA using Haversine at 60 mph assumed speed
- Broadcasts `VehiclePositionUpdated { repId, vehicleId, lat, lng, state }` to all dispatchers via `VehiclePositionHub`
- Broadcasts `RepPositionUpdated { lat, lng, etaMinutes, state }` to the assigned requester via `RequesterHub` (only if request is `Assigned`)
- Requires Simulator role

---

## Epic: DTCs

### BE-009 — List diagnostic trouble codes
**As a** ServiceRep or Requester,
**I want to** `GET /dtcs` to retrieve all available Diagnostic Trouble Codes,
**so that** I can select the relevant fault when submitting or reviewing a request.

**Acceptance Criteria:**
- Returns all 10 DTCs scoped to the authenticated user's `dealerId`
- Each DTC includes: `id`, `code`, `title`, `requiredEquipment`

---

## Epic: Service Requests

### BE-010 — Submit a service request
**As a** Requester,
**I want to** `POST /service-requests` with my GPS location and selected DTC,
**so that** the system can find and dispatch the nearest qualified rep.

**Acceptance Criteria:**
- Creates a `ServiceRequest` with status `Pending`
- Request is scoped to the requester's `dealerId` and `tier`
- Triggers the matching algorithm immediately
- Returns `{ requestId, status }`
- Requires Requester role

---

### BE-011 — List active service requests (Dispatcher)
**As a** Dispatcher,
**I want to** `GET /service-requests` to see all active requests for my dealer,
**so that** I can monitor the queue and spot escalations.

**Acceptance Criteria:**
- Returns all non-`Completed` requests for the authenticated dispatcher's `dealerId`
- Each request includes: `requestId`, `requesterName`, `tier`, `dtcTitle`, `status`, `assignedRepId`, `assignedRepName`, `createdAt`
- Requires Dispatcher role

---

### BE-012 — Get my active request (ServiceRep)
**As a** ServiceRep,
**I want to** `GET /service-requests/my-active` to see my currently assigned request,
**so that** I know where I'm going and what I'm fixing.

**Acceptance Criteria:**
- Returns the single active request (`Assigned` or `InProgress`) for the authenticated rep
- Returns `404` if the rep has no active request
- Requires ServiceRep role

---

### BE-013 — Get request detail
**As any** authenticated user,
**I want to** `GET /service-requests/{id}` to retrieve the full details of a specific request,
**so that** all parties can see the current state.

**Acceptance Criteria:**
- Returns full detail: `requestId`, `requesterName`, `tier`, `dtcTitle`, `requesterLocation { lat, lng }`, `status`, `assignedRep`, `createdAt`, `offerHistory[]`
- Scoped to the authenticated user's `dealerId`
- Returns `404` if not found or out of scope

---

## Epic: Matching Algorithm

### BE-014 — Run the matching algorithm
**As the** system,
**I want to** run the matching algorithm whenever a request is created or a `Pending` request has no rep and a rep transitions to `Available`,
**so that** requesters are always matched to the best available rep as quickly as possible.

**Acceptance Criteria:**
- **Filter 1:** Reps must belong to the same `dealerId` as the request
- **Filter 2:** Rep's vehicle must carry the equipment required by the request's DTC
- **Filter 3:** Rep must be in state `Available` or `EnRoute` (not `Offline`, `Within15Miles`, or `OnSite`)
- **Filter 4:** Reps previously declined or whose offer expired for this request are excluded
- **Sort:** Ascending Haversine distance from rep's last known position to requester's location
- **Tiebreaker:** If distances are equal, the rep who has been `Available` the longest wins
- If a match is found: create a `JobOffer` (status `Pending`) and send `JobOfferReceived` to the rep via `RepHub`
- If no match is found: request stays `Pending`; broadcast `ServiceRequestPending` to dispatchers via `DispatchHub`
- When a rep completes a job (`POST /rep/complete`), re-run matching for all `Pending` requests

---

## Epic: Job Offers

### BE-015 — View pending job offer (ServiceRep)
**As a** ServiceRep,
**I want to** `GET /job-offers/pending` to see my current pending job offer,
**so that** I can review it even if the push notification was missed.

**Acceptance Criteria:**
- Returns at most one `Pending` offer for the authenticated rep
- Includes: `offerId`, `requesterName`, `tier`, `dtcTitle`, `distanceMiles`, `etaMinutes`, `requesterLocation { lat, lng }`, `expiresAt`
- Returns `404` if no pending offer
- Requires ServiceRep role

---

### BE-016 — Accept a job offer
**As a** ServiceRep (or the Simulator),
**I want to** `POST /job-offers/{id}/accept` to take the job,
**so that** I can start navigating to the requester.

**Acceptance Criteria:**
- `JobOffer` transitions `Pending → Accepted`
- `ServiceRequest` transitions `Pending → Assigned`
- Rep state transitions to `EnRoute`
- Broadcasts `RepAssigned { repId, repName, etaMinutes, lat, lng }` to the requester via `RequesterHub`
- Broadcasts `ServiceRequestAssigned` and `RepStateChanged` to dispatchers via `DispatchHub`
- Returns `409` if the offer has already `Expired` or been `Declined`

---

### BE-017 — Decline a job offer
**As a** ServiceRep (or the Simulator),
**I want to** `POST /job-offers/{id}/decline` to refuse the job,
**so that** the system can find the next best rep.

**Acceptance Criteria:**
- `JobOffer` transitions `Pending → Declined`
- The rep is permanently skipped for this request (excluded from future matching runs for this job)
- System immediately re-runs the matching algorithm for the next best rep
- Returns `409` if the offer has already `Accepted` or `Expired`

---

### BE-018 — Expire job offers after 60 seconds
**As the** system,
**I want to** automatically expire pending job offers that go unanswered after 60 seconds,
**so that** requests don't stall waiting indefinitely for a rep to respond.

**Acceptance Criteria:**
- A background process (or scheduled job) monitors pending offers
- After 60 seconds without a response, `JobOffer` transitions `Pending → Expired`
- `Expired` is treated as `Declined` for all business purposes: rep is permanently skipped
- System re-runs matching for the next best rep
- `JobOfferExpired` event sent to the rep via `RepHub` (to dismiss the countdown UI)

---

## Epic: Rep State Transitions

### BE-019 — Mark arrived on site
**As a** ServiceRep,
**I want to** `POST /rep/arrive` to signal I have reached the requester's location,
**so that** the request transitions to `InProgress`.

**Acceptance Criteria:**
- Rep state transitions `EnRoute` or `Within15Miles` → `OnSite`
- `ServiceRequest` transitions `Assigned → InProgress`
- Broadcasts `RepStateChanged` to dispatchers via `DispatchHub`
- Broadcasts updated state to the requester via `RequesterHub`
- Returns `400` if rep has no active assigned request

---

### BE-020 — Mark job complete
**As a** ServiceRep,
**I want to** `POST /rep/complete` to close the job,
**so that** my vehicle becomes available for the next request and the requester is notified.

**Acceptance Criteria:**
- Rep state transitions `OnSite → Available`
- `ServiceRequest` transitions `InProgress → Completed`
- Vehicle remains `Claimed` (rep keeps their vehicle between jobs)
- Broadcasts `ServiceCompleted` to the requester via `RequesterHub`
- Broadcasts `RepStateChanged` and request removal to dispatchers via `DispatchHub`
- Re-runs the matching algorithm for any remaining `Pending` requests
- Returns `400` if rep has no active `InProgress` request

---

## Epic: Dispatcher Operations

### BE-021 — Get full fleet state (Dispatcher)
**As a** Dispatcher,
**I want to** `GET /dispatcher/fleet` to see every rep, their state, position, and active request in one call,
**so that** I have complete situational awareness on page load.

**Acceptance Criteria:**
- Returns all reps for the dispatcher's `dealerId`
- Each entry includes: `repId`, `name`, `state`, `vehicleId`, `registration`, `lastPosition { lat, lng }`, `activeRequestId`, `activeRequestTier`
- Requires Dispatcher role

---

### BE-022 — Redirect a rep (Dispatcher)
**As a** Dispatcher,
**I want to** `POST /dispatcher/redirect` with a rep ID and target request ID,
**so that** a Gold (or higher-tier) requester receives faster service by displacing the lower-tier job.

**Acceptance Criteria:**
- **Eligibility checks (all must pass):**
  - Rep is `EnRoute` (not `Available`, `Within15Miles`, `OnSite`, or `Offline`)
  - New request tier is strictly higher than the rep's current job tier, OR new request is `Gold` (which overrides the 5-minute cooldown)
  - Rep is NOT within 15 miles of their current requester (absolute protection — no tier can override)
  - Rep is NOT `OnSite` (absolute protection)
- **On success:**
  - Displaced request → `Pending`; its previous rep assignment cleared
  - Rep hard-assigned to the new request (no accept/decline required)
  - 5-minute redirect cooldown starts for this rep
  - `JobOffer` for displaced request immediately re-runs matching
  - `RedirectReceived { newRequestId, tier, dtcTitle, distanceMiles, etaMinutes, lat, lng }` sent to rep via `RepHub`
  - `RepAssigned` sent to Gold requester via `RequesterHub`
  - `RepRedirected { oldRepName, newRepName, newEtaMinutes }` sent to displaced requester via `RequesterHub` **only after** the new rep accepts
- Returns `422` with reason if any eligibility check fails
- Requires Dispatcher role

---

## Epic: Resilience

### BE-023 — Detect rep offline mid-job
**As the** system,
**I want to** detect when a rep's SignalR connection drops while they have an active job,
**so that** the job is re-queued and the dispatcher can take action.

**Acceptance Criteria:**
- `OnDisconnectedAsync` on `RepHub` triggers rep state → `Offline`
- Active job → `Pending` (vehicle stays `Claimed`)
- Broadcasts `RepOfflineMidJob { repId, requestId, repName, dtcTitle }` to dispatchers via `DispatchHub`
- Broadcasts the requester back to a `Pending` spinner state via `RequesterHub`
- Re-runs matching for the re-queued request
- When the rep reconnects and re-logs in, they can see their vehicle is still claimed and either reclaim it or the dispatcher can force-release

---

## Epic: Data Seeding

### BE-024 — Seed POC data on startup
**As a** developer,
**I want** the database seeded with the full POC data set on first run,
**so that** the system is ready to demo without manual setup.

**Acceptance Criteria:**
- **10 DTCs** with codes, titles, and required equipment mappings (as defined in `docs/domain-model.md`)
- **8 vehicles** with registration numbers and correct equipment combinations covering all DTC requirements
- **2 Dispatchers** (dealer A)
- **8 ServiceReps** (dealer A) with varied equipment authorisations
- **10 Requesters** — 6 Bronze, 3 Silver, 1 Gold (dealer A)
- **1 Simulator service account** (role: Simulator)
- Seeding is idempotent — safe to run on every startup; does not duplicate records

---

## Epic: SignalR Infrastructure

### BE-025 — Configure all 4 SignalR hubs
**As the** system,
**I want** all 4 SignalR hubs wired and running,
**so that** real-time events flow correctly to each subscriber group.

**Acceptance Criteria:**

| Hub | Path | Publishes | Subscribes |
|-----|------|-----------|------------|
| `VehiclePositionHub` | `/hubs/position` | `VehiclePositionUpdated` | All dispatchers |
| `DispatchHub` | `/hubs/dispatch` | `ServiceRequestPending`, `ServiceRequestAssigned`, `ServiceRequestCompleted`, `RepStateChanged`, `RepOfflineMidJob`, `FleetPositionUpdate` | All dispatchers |
| `RepHub` | `/hubs/rep` | `JobOfferReceived`, `JobOfferExpired`, `RedirectReceived` | Individual rep (by connection); Simulator service account |
| `RequesterHub` | `/hubs/requester` | `RepAssigned`, `RepPositionUpdated`, `RepRedirected`, `ServiceCompleted` | Individual requester (by connection) |

- All hubs require JWT Bearer authentication
- Hub connections scoped to `dealerId` — cross-dealer leakage is not possible
- Individual rep and requester events targeted by `userId` connection group, not broadcast to all
