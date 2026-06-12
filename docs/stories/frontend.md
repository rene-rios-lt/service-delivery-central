# Frontend User Stories

> **Repo:** `service-delivery-frontend`
> These stories cover all three persona views (Dispatcher, ServiceRep, Requester). Platform support differs per persona — **Dispatcher: Desktop + Web · ServiceRep: Mobile · Requester: Desktop + Web + Mobile** (see [Persona Platform Support](../architecture/system-overview.md#persona-platform-support)).
>
> **Design:** Full UI context is in the [UI design brief](../ui-design-brief.md). Each story below links its rendered mockup from [`docs/ui-mockups/`](../ui-mockups/README.md); every screen is composed from the shared [`design-system.css`](../ui-mockups/design-system.css) component library (per [ADR-0007](../adr/0007-mudblazor-component-library.md)). A full story→screen map is in [Story ↔ Screen Traceability](#story--screen-traceability) at the bottom.

---

## Epic: Authentication

> **Platforms:** every host each persona supports (Dispatcher: Desktop/Web · ServiceRep: Mobile · Requester: Desktop/Web/Mobile).

### FE-001 — Log in and route to persona view
**As any** user,
**I want to** log in with my username and password and be taken directly to my persona's view,
**so that** I see only the UI relevant to my role.

**Acceptance Criteria:**
- Login screen shown on app launch if no valid JWT is stored
- On success: JWT stored; role claim read; user routed to the correct view (Dispatcher / ServiceRep / Requester)
- On failure: error message shown inline; login form remains
- Behaves identically on every platform the signed-in persona supports (Dispatcher: Desktop/Web; ServiceRep: Mobile; Requester: Desktop/Web/Mobile — see Persona Platform Support)
- No role-selection screen — routing is automatic based on JWT

**Mockup**

| Web / Desktop | Mobile |
|:---:|:---:|
| <img src="../ui-mockups/images/login__web-1280x800.png" alt="Login — web" width="460"> | <img src="../ui-mockups/images/login__mobile-390x844.png" alt="Login — mobile" width="230"> |

---

### FE-002 — Handle JWT expiry
**As any** authenticated user,
**I want to** be automatically redirected to the login screen when my session expires,
**so that** I never make API calls with an invalid token.

**Acceptance Criteria:**
- JWT expiry detected (either from token claim or a `401` response)
- User redirected to login screen; stored JWT cleared
- Pending UI actions (e.g. accepting an offer mid-expiry) are safely cancelled

_No dedicated screen — redirects to the login screen (see FE-001)._

---

## Epic: Dispatcher View

> **Platforms:** **Desktop + Web only** ([ADR-0008](../adr/0008-persona-platform-support.md)). Not built for mobile — no phone layout is designed for this persona.

### FE-003 — Live fleet map
**As a** Dispatcher,
**I want to** see all fleet vehicles on a live Google Map with colour-coded markers,
**so that** I have real-time situational awareness of every rep.

**Acceptance Criteria:**
- Map loads with all vehicle markers on initial `GET /dispatcher/fleet`
- Marker colours reflect rep state: Green = Available, Blue = En Route, Yellow = Within 15 Miles, Red = On Site, Grey = Unclaimed / Offline
- Positions update in real time via `VehiclePositionHub` (every ~3 seconds)
- Clicking a marker shows a popover: rep name, state, vehicle registration, active request title and tier (if assigned)
- A legend maps marker colour → rep state
- Offline reps' markers are removed from the map
- Layout is responsive across Desktop and Web; the map fills available width with the request queue beside it

**Mockup**

| Desktop (1440) | Web (1280) |
|:---:|:---:|
| <img src="../ui-mockups/images/dispatcher-dashboard__desktop-1440x900.png" alt="Dispatcher dashboard — desktop" width="460"> | <img src="../ui-mockups/images/dispatcher-dashboard__web-1280x800.png" alt="Dispatcher dashboard — web" width="460"> |

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
- Queue panel is responsive across Desktop and Web (fixed-width rail beside the map; reflows on narrower web widths)

**Mockup —** _the request queue rail within the Desktop dashboard_

<img src="../ui-mockups/images/dispatcher-dashboard__desktop-1440x900.png" alt="Dispatcher request queue — desktop" width="600">

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
- Dialog is responsive across Desktop and Web

**Mockup —** _Desktop_

<img src="../ui-mockups/images/dispatcher-redirect__desktop-1440x900.png" alt="Dispatcher redirect confirmation dialog" width="600">

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
- Banner carries a **Force-release vehicle** action that opens the force-release flow (see FE-022)
- Banner is responsive across Desktop and Web (spans the map column)

**Mockup —** _the alert banner above the Desktop dashboard map_

<img src="../ui-mockups/images/dispatcher-dashboard__desktop-1440x900.png" alt="Dispatcher offline alert banner — desktop" width="600">

---

### FE-022 — Force-release a vehicle
**As a** Dispatcher,
**I want to** force-release a stuck or offline rep's vehicle from a confirmed action,
**so that** the vehicle returns to the available pool and the rep's request is reassigned without waiting for them to reconnect.

**Acceptance Criteria:**
- A "Force-release vehicle" action is available from the offline-alert banner (FE-006); it is also reachable from the rep marker popover on the fleet map (FE-003)
- Clicking the action opens a confirmation dialog showing: rep name, vehicle registration, the request that will be re-queued, and a warning that the rep's session is revoked (they must claim a vehicle again if they reconnect)
- On confirm: calls `POST /vehicles/{id}/force-release`
- On success: the vehicle marker updates to Unclaimed/Offline (grey), the offline banner is dismissed, and the affected request remains in the queue as `Pending` for reassignment
- On API error (e.g. the rep reconnected and self-released between click and confirm): error shown; the dialog stays open with the confirm button disabled
- Restricted to the Dispatcher role; available on Desktop + Web only (per [ADR-0008](../adr/0008-persona-platform-support.md))
- Dialog is responsive across Desktop and Web
- The affected rep is notified server-side via the `VehicleForceReleased { vehicleId, registration }` event on `RepHub` (BE-007 / BE-025); the dispatcher's own fleet map reflects the now-unclaimed vehicle through the usual `VehiclePositionHub` fleet updates (FE-003)

**Mockup —** _Desktop (force-release confirmation over the offline-alert dashboard)_

<img src="../ui-mockups/images/dispatcher-force-release__desktop-1440x900.png" alt="Dispatcher force-release confirmation dialog" width="600">

---

## Epic: ServiceRep View

> **Platforms:** **Mobile only** ([ADR-0008](../adr/0008-persona-platform-support.md)). Single-task, touch-first field experience — no desktop or web rep view.

### FE-007 — Select and claim a vehicle at login
**As a** ServiceRep,
**I want to** choose a vehicle from a list of available vehicles immediately after logging in,
**so that** I have an active session before I can receive job offers.

**Acceptance Criteria:**
- Vehicle selection screen is the first screen after successful login (before the main rep view)
- List populated from `GET /vehicles/available`; shows registration and equipment list per vehicle
- Tapping a vehicle calls `POST /vehicles/{id}/claim`
- On success, transitions to the idle rep view (waiting for job offers — see FE-020)
- On `409` (race condition — vehicle claimed by another rep), refreshes the list and shows a message

**Mockup —** _Mobile_

<img src="../ui-mockups/images/rep-vehicle-select__mobile-390x844.png" alt="Rep — claim a vehicle" width="240">

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

**Mockup —** _Mobile (final-10-seconds urgent state shown)_

<img src="../ui-mockups/images/rep-job-offer__mobile-390x844.png" alt="Rep — job offer with countdown" width="240">

---

### FE-009 — Accept a job offer
**As a** ServiceRep,
**I want to** tap "Accept" on a job offer,
**so that** I am assigned the job and can start navigating to the requester.

**Acceptance Criteria:**
- Calls `POST /job-offers/{id}/accept`
- On success: transitions to the active job view (FE-011)
- On `409` (offer expired between tap and API call): shows "Offer expired" message; returns to idle view

**Mockup —** _the "Accept" action on the job-offer screen (Mobile)_

<img src="../ui-mockups/images/rep-job-offer__mobile-390x844.png" alt="Rep — accept job offer" width="240">

---

### FE-010 — Decline a job offer
**As a** ServiceRep,
**I want to** tap "Decline" on a job offer,
**so that** the system can find the next best available rep for the requester.

**Acceptance Criteria:**
- Calls `POST /job-offers/{id}/decline`
- On success: offer screen dismisses; returns to idle waiting view (FE-020)
- On `409` (offer expired between tap and API call): same outcome — returns to idle view

**Mockup —** _the "Decline" action on the job-offer screen (Mobile)_

<img src="../ui-mockups/images/rep-job-offer__mobile-390x844.png" alt="Rep — decline job offer" width="240">

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

**Mockup —** _Mobile (En Route)_

<img src="../ui-mockups/images/rep-active-job__mobile-390x844.png" alt="Rep — active job navigation" width="240">

---

### FE-012 — Mark arrived on site
**As a** ServiceRep,
**I want to** tap "I've Arrived" when I reach the requester,
**so that** the request transitions to In Progress and the requester is updated.

**Acceptance Criteria:**
- Button calls `POST /rep/arrive`
- On success: navigation line removed; map zooms to current location; "Mark Complete" button becomes the primary action
- "I've Arrived" button becomes enabled once the rep is within 15 miles (state `Within15Miles`) or at any time once `OnSite`

**Mockup —** _Mobile (On Site — route line removed, "Mark Complete" primary)_

<img src="../ui-mockups/images/rep-on-site__mobile-390x844.png" alt="Rep — on site" width="240">

---

### FE-013 — Mark job complete
**As a** ServiceRep,
**I want to** tap "Mark Complete" when the repair is finished,
**so that** the request is closed, the requester is notified, and I become available for the next job.

**Acceptance Criteria:**
- Button calls `POST /rep/complete`
- On success: returns to idle waiting view (vehicle still claimed — see FE-020)
- A brief confirmation toast shown: "Job marked complete"

**Mockup —** _Mobile (returns to the idle waiting view)_

<img src="../ui-mockups/images/rep-idle__mobile-390x844.png" alt="Rep — returns to idle after completing" width="240">

---

### FE-014 — Release vehicle at end of shift
**As a** ServiceRep,
**I want to** release my vehicle from a menu option,
**so that** it returns to the fleet and I can log out cleanly.

**Acceptance Criteria:**
- "Release Vehicle" option accessible from the navigation menu (not the primary UI — see FE-021)
- Disabled if a job is currently `InProgress`
- On tap: confirmation dialog; on confirm: calls `POST /vehicles/{id}/release`
- On success: returns to vehicle selection screen

**Mockup —** _Mobile_

| Nav menu | Confirm dialog |
|:---:|:---:|
| <img src="../ui-mockups/images/rep-nav-drawer__mobile-390x844.png" alt="Rep — nav menu with Release Vehicle" width="230"> | <img src="../ui-mockups/images/rep-release-vehicle__mobile-390x844.png" alt="Rep — release vehicle confirmation" width="230"> |

---

### FE-020 — Idle / waiting-for-offers view
**As a** ServiceRep,
**I want to** see a clear "you're available, waiting for a job" home screen between jobs,
**so that** I know my session is active and the system can reach me.

**Acceptance Criteria:**
- Shown after claiming a vehicle (FE-007), after declining an offer (FE-010), and after completing a job (FE-013)
- Displays an "Available" state indicator and my claimed vehicle (registration + equipment)
- Remains the resting screen until a `JobOfferReceived` arrives via `RepHub`, which immediately presents the job offer (FE-008)
- Navigation menu (FE-021) is reachable from here without leaving the waiting state
- No manual refresh — transition to an offer is push-driven

**Mockup —** _Mobile_

<img src="../ui-mockups/images/rep-idle__mobile-390x844.png" alt="Rep — idle waiting for offers" width="240">

---

## Epic: Requester View

> **Platforms:** **Desktop + Web + Mobile** ([ADR-0008](../adr/0008-persona-platform-support.md)) — consumer-grade and responsive from phone to desktop.

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
- Responsive from mobile through desktop (single-column on phone; centred, wider layout on web/desktop)

**Mockup**

| Web / Desktop | Mobile |
|:---:|:---:|
| <img src="../ui-mockups/images/requester-submit__web-1280x800.png" alt="Requester submit — web" width="460"> | <img src="../ui-mockups/images/requester-submit__mobile-390x844.png" alt="Requester submit — mobile" width="230"> |

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
- Responsive from mobile through desktop

**Mockup —** _Mobile (layout is responsive on web/desktop)_

<img src="../ui-mockups/images/requester-finding__mobile-390x844.png" alt="Requester — finding a technician" width="240">

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
- Responsive from mobile through desktop (full-bleed map with overlay card)

**Mockup**

| Web / Desktop | Mobile |
|:---:|:---:|
| <img src="../ui-mockups/images/requester-tracking__web-1280x800.png" alt="Requester tracking — web" width="460"> | <img src="../ui-mockups/images/requester-tracking__mobile-390x844.png" alt="Requester tracking — mobile" width="230"> |

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
- Responsive from mobile through desktop

**Mockup**

| Web / Desktop | Mobile |
|:---:|:---:|
| <img src="../ui-mockups/images/requester-redirect__web-1280x800.png" alt="Requester redirect notification — web" width="460"> | <img src="../ui-mockups/images/requester-redirect__mobile-390x844.png" alt="Requester redirect notification — mobile" width="230"> |

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
- Responsive from mobile through desktop

**Mockup —** _Mobile (layout is responsive on web/desktop)_

<img src="../ui-mockups/images/requester-complete__mobile-390x844.png" alt="Requester — service complete" width="240">

---

## Epic: App Shell, Navigation & Session

> **Platforms:** every host each persona supports. The shell adapts per form factor — a slide-in drawer on mobile (ServiceRep), an account menu on Desktop/Web (Dispatcher, Requester).

### FE-021 — App shell, navigation menu & logout
**As any** authenticated user,
**I want to** access a persona-appropriate navigation menu and log out cleanly,
**so that** I can reach secondary actions (e.g. Release Vehicle) and end my session.

**Acceptance Criteria:**
- A persona shell wraps every authenticated view: app bar with title, context (e.g. claimed vehicle), and a menu affordance
- Menu presentation adapts to platform: slide-in drawer on Mobile; dropdown account menu on Desktop/Web
- Menu exposes secondary actions per persona (e.g. ServiceRep: Release Vehicle (FE-014), Job history; Dispatcher: Profile, Settings) and **Log out** for all
- On "Log out": JWT cleared and user returned to the login screen (FE-001); a ServiceRep with a claimed vehicle is prompted/expected to release it first
- Destructive items (Release Vehicle, Log out) are visually distinct

**Mockup**

| Mobile (ServiceRep drawer) | Desktop (Dispatcher account menu) |
|:---:|:---:|
| <img src="../ui-mockups/images/rep-nav-drawer__mobile-390x844.png" alt="ServiceRep navigation drawer" width="230"> | <img src="../ui-mockups/images/dispatcher-nav__desktop-1440x900.png" alt="Dispatcher account menu" width="460"> |

---

## Story ↔ Screen Traceability

| Story | Screen(s) | Platforms rendered |
|-------|-----------|--------------------|
| FE-001 Log in & route | `login` | Web, Mobile |
| FE-002 JWT expiry | _(redirects to `login`)_ | — |
| FE-003 Live fleet map | `dispatcher-dashboard` | Desktop, Web |
| FE-004 Request queue | `dispatcher-dashboard` | Desktop, Web |
| FE-005 Redirect a rep | `dispatcher-redirect` | Desktop |
| FE-006 Rep offline alert | `dispatcher-dashboard` (banner) | Desktop, Web |
| FE-022 Force-release a vehicle | `dispatcher-force-release` | Desktop, Web |
| FE-007 Claim a vehicle | `rep-vehicle-select` | Mobile |
| FE-008 Job offer + countdown | `rep-job-offer` | Mobile |
| FE-009 Accept offer | `rep-job-offer` (action) | Mobile |
| FE-010 Decline offer | `rep-job-offer` (action) → `rep-idle` | Mobile |
| FE-011 Active job navigation | `rep-active-job` | Mobile |
| FE-012 Mark arrived | `rep-on-site` | Mobile |
| FE-013 Mark complete | `rep-idle` (result) | Mobile |
| FE-014 Release vehicle | `rep-nav-drawer`, `rep-release-vehicle` | Mobile |
| FE-015 Submit a request | `requester-submit` | Web, Mobile |
| FE-016 Finding a technician | `requester-finding` | Mobile |
| FE-017 Live rep tracking | `requester-tracking` | Web, Mobile |
| FE-018 Redirect notification | `requester-redirect` | Web, Mobile |
| FE-019 Service complete | `requester-complete` | Mobile |
| FE-020 Idle / waiting view | `rep-idle` | Mobile |
| FE-021 App shell & logout | `rep-nav-drawer`, `dispatcher-nav` | Mobile, Desktop |

> Screens are rendered to PNG by [`docs/ui-mockups/render.mjs`](../ui-mockups/render.mjs) and indexed in the [mockups README](../ui-mockups/README.md). The reusable component library is [`design-system.css`](../ui-mockups/design-system.css).
