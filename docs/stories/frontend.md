# Frontend User Stories

> **Repo:** `service-delivery-frontend`
> These stories cover all three persona views (Dispatcher, ServiceRep, Requester) across Desktop, Mobile, and Web.

---

## Epic: Authentication

### FE-001 — Log in and route to persona view
**As any** user,
**I want to** log in with my username and password and be taken directly to my persona's view,
**so that** I see only the UI relevant to my role.

**Acceptance Criteria:**
- Login screen shown on app launch if no valid JWT is stored
- On success: JWT stored; role claim read; user routed to the correct view (Dispatcher / ServiceRep / Requester)
- On failure: error message shown inline; login form remains
- Works identically on Desktop, Mobile, and Web
- No role-selection screen — routing is automatic based on JWT

---

### FE-002 — Handle JWT expiry
**As any** authenticated user,
**I want to** be automatically redirected to the login screen when my session expires,
**so that** I never make API calls with an invalid token.

**Acceptance Criteria:**
- JWT expiry detected (either from token claim or a `401` response)
- User redirected to login screen; stored JWT cleared
- Pending UI actions (e.g. accepting an offer mid-expiry) are safely cancelled

---

## Epic: Dispatcher View

### FE-003 — Live fleet map
**As a** Dispatcher,
**I want to** see all fleet vehicles on a live Google Map with colour-coded markers,
**so that** I have real-time situational awareness of every rep.

**Acceptance Criteria:**
- Map loads with all vehicle markers on initial `GET /dispatcher/fleet`
- Marker colours reflect rep state: Green = Available, Blue = En Route, Yellow = Within 15 Miles, Red = On Site, Grey = Unclaimed / Offline
- Positions update in real time via `VehiclePositionHub` (every ~3 seconds)
- Clicking a marker shows a popover: rep name, state, vehicle registration, active request title and tier (if assigned)
- Offline reps' markers are removed from the map

---

### FE-004 — Active request queue
**As a** Dispatcher,
**I want to** see the active service request queue alongside the map,
**so that** I can prioritise escalations and monitor unassigned requests.

**Acceptance Criteria:**
- Queue lists all non-`Completed` requests for the dealer, ordered: Gold → Silver → Bronze, then by `createdAt` ascending within each tier
- Each card shows: requester name, tier badge (colour-coded), DTC title, status chip, assigned rep name (or "Unassigned"), time since creation
- Queue updates in real time via `DispatchHub` events (`ServiceRequestPending`, `ServiceRequestAssigned`, `ServiceRequestCompleted`)
- Completed requests disappear from the queue immediately

---

### FE-005 — Redirect a rep to a higher-priority request
**As a** Dispatcher,
**I want to** redirect an En Route rep to a higher-priority request with a single confirmed action,
**so that** Gold requesters receive faster service without manual coordination.

**Acceptance Criteria:**
- A "Redirect" button appears on a request card when a suggested match is currently `EnRoute` to a lower-tier request and redirect is eligible
- Clicking "Redirect" opens a confirmation dialog showing: rep name, current job (tier + DTC), new job (tier + DTC), and a warning if the rep is in their 5-minute cooldown (Gold overrides)
- On confirm: calls `POST /dispatcher/redirect`; UI updates optimistically
- On API error (e.g. rep moved to Within15Miles between click and confirm): error shown; button disabled
- Ineligible redirects (Within 15 Miles, On Site) do not show the Redirect button

---

### FE-006 — Rep offline alert
**As a** Dispatcher,
**I want to** be alerted immediately when a rep goes offline mid-job,
**so that** I can decide whether to force-release the vehicle or wait for the rep to reconnect.

**Acceptance Criteria:**
- Alert banner appears at the top of the Dispatcher view: `"[Rep name] went offline — [DTC title] request re-queued"`
- Affected rep's marker removed from the map
- Affected request returns to the queue with status `Pending`
- Alert dismissible; a log of recent alerts accessible from the UI
- Triggered by `RepOfflineMidJob` event from `DispatchHub`

---

## Epic: ServiceRep View

### FE-007 — Select and claim a vehicle at login
**As a** ServiceRep,
**I want to** choose a vehicle from a list of available vehicles immediately after logging in,
**so that** I have an active session before I can receive job offers.

**Acceptance Criteria:**
- Vehicle selection screen is the first screen after successful login (before the main rep view)
- List populated from `GET /vehicles/available`; shows registration and equipment list per vehicle
- Tapping a vehicle calls `POST /vehicles/{id}/claim`
- On success, transitions to the idle rep view (waiting for job offers)
- On `409` (race condition — vehicle claimed by another rep), refreshes the list and shows a message

---

### FE-008 — Receive and display a job offer with countdown
**As a** ServiceRep,
**I want to** see an incoming job offer with a live 60-second countdown as soon as it arrives,
**so that** I can make an informed accept/decline decision before the offer expires.

**Acceptance Criteria:**
- Job offer screen appears immediately when `JobOfferReceived` is received via `RepHub`
- Displays: requester first name, tier badge, DTC title, distance in miles, ETA in minutes, static map pin of requester location
- 60-second countdown timer displayed prominently; turns red in the final 10 seconds
- "Accept" and "Decline" buttons clearly visible
- On countdown reaching zero, the offer screen dismisses automatically (offer has expired server-side)
- Triggered by `JobOfferReceived { offerId, requesterName, tier, dtcTitle, distanceMiles, etaMinutes, lat, lng }`

---

### FE-009 — Accept a job offer
**As a** ServiceRep,
**I want to** tap "Accept" on a job offer,
**so that** I am assigned the job and can start navigating to the requester.

**Acceptance Criteria:**
- Calls `POST /job-offers/{id}/accept`
- On success: transitions to the active job view (FE-011)
- On `409` (offer expired between tap and API call): shows "Offer expired" message; returns to idle view

---

### FE-010 — Decline a job offer
**As a** ServiceRep,
**I want to** tap "Decline" on a job offer,
**so that** the system can find the next best available rep for the requester.

**Acceptance Criteria:**
- Calls `POST /job-offers/{id}/decline`
- On success: offer screen dismisses; returns to idle waiting view
- On `409` (offer expired between tap and API call): same outcome — returns to idle view

---

### FE-011 — Active job navigation view
**As a** ServiceRep,
**I want to** see my active job on a live Google Map with my position and the requester's pin,
**so that** I know exactly where I'm going and my current ETA.

**Acceptance Criteria:**
- Map shows: my vehicle's current position (updated every ~3 seconds), requester's location as a fixed pin, a straight line between the two
- ETA (minutes) shown and updated as my position changes via `RepPositionUpdated` or position polling
- DTC title and requester name shown in a bottom sheet
- "I've Arrived" button shown but disabled until rep is within 15 miles (or always enabled if within 15 miles on load)
- Receiving a `RedirectReceived` event updates the map destination without requiring a new screen load (see FE-016)

---

### FE-012 — Mark arrived on site
**As a** ServiceRep,
**I want to** tap "I've Arrived" when I reach the requester,
**so that** the request transitions to In Progress and the requester is updated.

**Acceptance Criteria:**
- Button calls `POST /rep/arrive`
- On success: navigation line removed; map zooms to current location; "Mark Complete" button becomes the primary action
- "I've Arrived" button becomes enabled once the rep is within 15 miles (state `Within15Miles`) or at any time once `OnSite`

---

### FE-013 — Mark job complete
**As a** ServiceRep,
**I want to** tap "Mark Complete" when the repair is finished,
**so that** the request is closed, the requester is notified, and I become available for the next job.

**Acceptance Criteria:**
- Button calls `POST /rep/complete`
- On success: returns to idle waiting view (vehicle still claimed)
- A brief confirmation toast shown: "Job marked complete"

---

### FE-014 — Release vehicle at end of shift
**As a** ServiceRep,
**I want to** release my vehicle from a menu option,
**so that** it returns to the fleet and I can log out cleanly.

**Acceptance Criteria:**
- "Release Vehicle" option accessible from the navigation menu (not the primary UI)
- Disabled if a job is currently `InProgress`
- On tap: confirmation dialog; on confirm: calls `POST /vehicles/{id}/release`
- On success: returns to vehicle selection screen

---

## Epic: Requester View

### FE-015 — Submit a service request
**As a** Requester,
**I want to** submit a service request by setting my location on a map and selecting the relevant DTC,
**so that** a qualified rep can be dispatched to me.

**Acceptance Criteria:**
- Map shown on load; requester can tap to place a location pin or tap "Use My Location" to use device GPS
- DTC dropdown populated from `GET /dtcs`; shows code and title
- "Request Service" button enabled only when both location and DTC are set
- On submit: calls `POST /service-requests`; transitions to pending view (FE-016)
- On API error: error message shown inline; form remains

---

### FE-016 — Pending state — finding a technician
**As a** Requester,
**I want to** see a "finding your technician" spinner while my request is `Pending`,
**so that** I know the system is actively searching for a rep.

**Acceptance Criteria:**
- Shown immediately after successful request submission
- Spinner and message: "Finding your technician…"
- Transitions automatically to the tracking view (FE-017) when `RepAssigned` is received via `RequesterHub`
- No manual refresh needed

---

### FE-017 — Live rep tracking
**As a** Requester,
**I want to** see my assigned rep moving toward me on a live map with a real-time ETA,
**so that** I know exactly when help is arriving.

**Acceptance Criteria:**
- Map shows: my location pin (fixed), rep's position as a moving marker, a line between the two
- Rep name shown above the map
- ETA (minutes) shown and updated as rep's position changes via `RepPositionUpdated`
- Status message reflects rep state: "On the way" (EnRoute), "Almost there" (Within15Miles), "Arrived" (OnSite)
- When rep state becomes `OnSite`, ETA hidden; message updates to "Your technician has arrived"

---

### FE-018 — Redirect notification
**As a** Requester,
**I want to** be notified when my originally assigned rep has been redirected to a higher-priority job,
**so that** I understand why the rep on my map changed.

**Acceptance Criteria:**
- Notification shown: `"Our apologies, we needed to redirect [old rep name]. [new rep name] is heading your way."`
- Map updates to show the new rep's position and updated ETA
- New rep's name replaces the old one in the UI
- Triggered by `RepRedirected { oldRepName, newRepName, newEtaMinutes }` from `RequesterHub`

---

### FE-019 — Service complete
**As a** Requester,
**I want to** see a completion message when my service is done,
**so that** I know the job is finished and I can close the app.

**Acceptance Criteria:**
- Message shown: "Your service is complete."
- Map and ETA components hidden
- Option to submit a new request shown
- Triggered by `ServiceCompleted` from `RequesterHub`
