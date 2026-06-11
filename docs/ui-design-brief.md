# UI Design Brief — Service Delivery

> **Purpose:** A single, self-contained brief for generating the UI design of the Service Delivery
> frontend. It synthesizes the persona model, visual system, screen inventory, state model, and
> real-time behavior from the source documents listed at the end. Hand this to a designer or a
> UI-generation tool as the starting point.
>
> **Scope:** The frontend only (`service-delivery-frontend`). Backend, simulator, and infrastructure
> decisions are out of scope except where they shape what the UI must display.

---

## 1. Product in One Paragraph

Service Delivery is an **"Uber for service reps"** — a fleet dispatch platform that connects service
requesters with the nearest qualified field technician. A requester reports an equipment fault
(identified by a Diagnostic Trouble Code, or DTC). The system finds the closest service vehicle
carrying the right equipment, sends the rep a job offer, and — once accepted — gives the requester an
Uber-like live tracking experience. Dispatchers oversee the whole fleet on a live map, manage the
request queue, and handle priority escalations. Updates flow in real time over SignalR.

---

## 2. Personas

The UI serves **three distinct personas**. Login routes each user automatically to their own view
based on a role claim — there is no role-selection screen.

### Dispatcher — command-center operator (Desktop + Web only)
Manages the fleet from a dense, desktop-first dashboard. Sees all vehicles on a live map, monitors the
incoming request queue, redirects En Route reps to higher-priority work, and reacts to reps going
offline. Has override authority. **Information density is high; this is a "wall of glass" operations
view. Not supported on Mobile — no phone layout is designed for this persona.**

### Service Rep — field technician (Mobile only)
Drives a service vehicle. Logs in, claims a vehicle for the day, then waits for job offers. Receives an
offer with a 60-second countdown, accepts or declines, navigates to the requester, marks arrival and
completion, and releases the vehicle at end of shift. **Single-task focus, large touch targets, in-vehicle
glanceability. Mobile only — there is no Desktop or Web rep view.**

### Requester — customer reporting a fault (Desktop + Web + Mobile, consumer-grade)
Submits a request by dropping a map pin and selecting a DTC, then watches a "finding your technician"
spinner, then tracks the assigned rep moving toward them with a live ETA. **Calm, consumer-friendly,
Uber-rider-like.**

---

## 3. Priority Tiers (drive color and ordering everywhere)

Tiers live on the requester account and govern queue order and redirect rights.

| Tier | Rank | Behavior |
|------|------|----------|
| **Bronze** | Lowest | Standard service, normal queue |
| **Silver** | Mid | Trumps Bronze |
| **Gold** | Highest | Trumps Silver and Bronze; the only tier that can override the redirect cooldown |

Any higher tier can redirect an En Route rep serving a lower-tier request. Reps **Within 15 Miles** or
**On Site** are protected from redirect by any tier. Tier badges are color-coded and appear on every
request card, job offer, and tracking view.

---

## 4. Platforms & Form Factors

Each persona is supported on a fixed subset of platforms. **Design only the persona/platform
combinations marked ✅ below — do not produce a mobile Dispatcher layout or a desktop/web Service Rep
layout.**

| Persona | Desktop | Web | Mobile | Design intent |
|---------|:-------:|:---:|:------:|---------------|
| **Dispatcher** | ✅ | ✅ | ❌ | Dense dashboard; live map + request queue side by side |
| **Service Rep** | ❌ | ❌ | ✅ | Touch-first; large actions; one task per screen; in-vehicle glanceability |
| **Requester** | ✅ | ✅ | ✅ | Consumer-grade; responsive from phone to desktop |

| Platform | Host technology |
|----------|-----------------|
| **Desktop** | MAUI Blazor Hybrid |
| **Mobile** | MAUI Blazor Hybrid |
| **Web** | Blazor WASM |

The same Razor component library (`ServiceDelivery.Client.UI`) renders across all three hosts, but each
persona's view is built only for its supported platforms. **Dispatcher must be responsive across desktop
and web; Requester must be responsive from mobile through desktop; Service Rep targets mobile only.**

---

## 5. Visual System & Component Library

**MudBlazor is the mandated component library** (ADR-0007). The design must be expressible in MudBlazor
primitives and theme tokens — not custom CSS — wherever a matching component exists.

- Build from MudBlazor primitives: `MudCard`, `MudChip`, `MudBadge`, `MudDataGrid`, dialogs, buttons,
  bottom sheets, banners, etc.
- Define domain colors **once** in `MudTheme` as named semantic tokens and reference them everywhere.
- Custom CSS only where MudBlazor has a genuine gap. No mixing of other component libraries.
- Consistent theming across Desktop, Web, and Mobile.

### Domain Color Tokens

These two color systems are the visual backbone of the app and must be defined as named theme tokens.

**Rep-state marker colors** (used on the fleet map and anywhere rep state is shown):

| Rep State | Color |
|-----------|-------|
| Available | 🟢 Green |
| En Route | 🔵 Blue |
| Within 15 Miles | 🟡 Yellow |
| On Site | 🔴 Red |
| Unclaimed / Offline | ⚪ Grey (marker removed from map when offline) |

**Tier badge colors:**

| Tier | Color intent |
|------|--------------|
| Bronze | Bronze/brown |
| Silver | Silver/grey |
| Gold | Gold/amber |

---

## 6. Screen Inventory

Each screen below is derived from a frontend user story (FE-xxx) and its acceptance criteria. Treat the
bullets as design requirements — they specify components, states, and interactions.

### 6.1 Shared — Authentication

**Login (FE-001)**
- Shown on app launch when no valid JWT is stored.
- Username + password fields, submit button.
- Success: store JWT, read role claim, route automatically to Dispatcher / ServiceRep / Requester view.
- Failure: inline error message; form remains.
- Behaves identically across the platforms each persona supports (§4). No role-selection screen.

**Session expiry (FE-002)** — not a screen, a behavior
- On JWT expiry or a `401`, redirect to login, clear stored JWT.
- Cancel pending UI actions safely (e.g. an in-flight offer accept).

---

### 6.2 Dispatcher View (Desktop + Web — dashboard)

The dispatcher view is a **single dense dashboard**: live fleet map as the centerpiece, request queue
alongside, and an alert banner area at the top.

**Live fleet map (FE-003)**
- Google Map with a marker per vehicle, loaded from `GET /dispatcher/fleet`.
- Marker color = rep state (see token table in §5).
- Positions update in real time (~every 3 seconds) via `VehiclePositionHub`.
- Clicking a marker opens a popover: rep name, state, vehicle registration, and active request title +
  tier if assigned.
- Offline reps' markers are removed.

**Active request queue (FE-004)**
- Lists all non-Completed requests, ordered **Gold → Silver → Bronze**, then by creation time ascending
  within each tier.
- Each card: requester name, tier badge (color-coded), DTC title, status chip, assigned rep name (or
  "Unassigned"), time since creation.
- Updates in real time via `DispatchHub` (`ServiceRequestPending`, `ServiceRequestAssigned`,
  `ServiceRequestCompleted`). Completed requests disappear immediately.

**Redirect a rep (FE-005)**
- A "Redirect" button appears on a request card when a suggested match is currently En Route to a
  lower-tier request and the redirect is eligible.
- Clicking opens a confirmation dialog: rep name, current job (tier + DTC), new job (tier + DTC), and a
  warning if the rep is in their 5-minute cooldown (Gold overrides).
- On confirm: `POST /dispatcher/redirect`; UI updates optimistically.
- On API error (e.g. rep moved to Within 15 Miles between click and confirm): show error, disable button.
- Ineligible redirects (Within 15 Miles, On Site) show no Redirect button.

**Rep offline alert (FE-006)**
- Alert banner at top of view: `"[Rep name] went offline — [DTC title] request re-queued"`.
- Affected rep's marker removed; affected request returns to queue as Pending.
- Banner is dismissible; a log of recent alerts is accessible from the UI.
- Triggered by `RepOfflineMidJob` from `DispatchHub`.

---

### 6.3 Service Rep View (Mobile only — single-task)

A linear flow: claim vehicle → wait → receive offer → navigate → arrive → complete → release.

**Vehicle selection / claim (FE-007)**
- First screen after login, before the main rep view.
- List from `GET /vehicles/available`: registration + equipment list per vehicle.
- Tapping a vehicle calls `POST /vehicles/{id}/claim`.
- Success → idle "waiting for offers" view.
- On `409` (claimed by another rep): refresh list, show message.

**Job offer with countdown (FE-008)**
- Appears immediately on `JobOfferReceived` (`RepHub`).
- Displays: requester first name, tier badge, DTC title, distance (miles), ETA (minutes), static map pin
  of requester location.
- **Prominent 60-second countdown; turns red in the final 10 seconds.**
- Clear "Accept" and "Decline" buttons.
- At zero, the offer auto-dismisses (expired server-side).
- Payload: `JobOfferReceived { offerId, requesterName, tier, dtcTitle, distanceMiles, etaMinutes, lat, lng }`.

**Accept (FE-009)**
- `POST /job-offers/{id}/accept`. Success → active job view (FE-011).
- On `409` (expired): show "Offer expired", return to idle.

**Decline (FE-010)**
- `POST /job-offers/{id}/decline`. Success → dismiss, return to idle.
- On `409`: same outcome (return to idle).

**Active job navigation (FE-011)**
- Google Map: rep's own position (updates ~every 3s), requester's fixed pin, straight line between them.
- ETA (minutes) shown and updated via `RepPositionUpdated` or polling.
- Bottom sheet: DTC title and requester name.
- "I've Arrived" button shown but **disabled until within 15 miles** (or enabled immediately if already
  within 15 miles on load).
- A `RedirectReceived` event updates the destination in place without a new screen load (see FE-018 on
  the requester side).

**Mark arrived (FE-012)**
- "I've Arrived" → `POST /rep/arrive`.
- Success: remove navigation line, zoom map to current location, promote "Mark Complete" to primary action.
- Button enables once Within 15 Miles, or any time once On Site.

**Mark complete (FE-013)**
- "Mark Complete" → `POST /rep/complete`.
- Success: return to idle view (vehicle stays claimed); show confirmation toast "Job marked complete".

**Release vehicle (FE-014)**
- "Release Vehicle" lives in the navigation menu, **not** the primary UI.
- Disabled while a job is In Progress.
- Tap → confirmation dialog → `POST /vehicles/{id}/release`.
- Success → return to vehicle selection screen.

---

### 6.4 Requester View (consumer-grade — Desktop, Web, and Mobile)

A calm three-state journey: submit → finding → tracking → complete.

**Submit a request (FE-015)**
- Map on load; tap to drop a location pin, or "Use My Location" for device GPS.
- DTC dropdown from `GET /dtcs`: shows code + title.
- "Request Service" enabled only when both location and DTC are set.
- Submit → `POST /service-requests` → pending view.
- On error: inline message, form remains.

**Pending — finding a technician (FE-016)**
- Shown immediately after submission.
- Spinner + "Finding your technician…".
- Auto-transitions to tracking when `RepAssigned` arrives via `RequesterHub`. No manual refresh.

**Live rep tracking (FE-017)**
- Map: requester's fixed pin, rep's moving marker, a line between them.
- Rep name shown above the map.
- ETA updates via `RepPositionUpdated`.
- Status message reflects rep state: "On the way" (En Route), "Almost there" (Within 15 Miles),
  "Arrived" (On Site).
- When On Site: hide ETA, message becomes "Your technician has arrived".

**Redirect notification (FE-018)**
- Notification: `"Our apologies, we needed to redirect [old rep name]. [new rep name] is heading your way."`
- Map updates to the new rep's position and ETA; new rep name replaces the old.
- Triggered by `RepRedirected { oldRepName, newRepName, newEtaMinutes }` from `RequesterHub`.

**Service complete (FE-019)**
- Message: "Your service is complete."
- Hide map and ETA; offer a "submit a new request" option.
- Triggered by `ServiceCompleted` from `RequesterHub`.

---

## 7. State Model the UI Must Reflect

The UI is a window onto a set of state machines. Visual state (marker color, status chip, message,
enabled buttons) must stay aligned with these.

### Rep states
`Offline → Available → En Route → Within 15 Miles → On Site → (back to) Available`

| State | Meaning | Redirect? | UI cues |
|-------|---------|-----------|---------|
| Offline | No vehicle claimed | N/A | Marker removed; rep sees vehicle-selection screen |
| Available | Claimed, no job | Normal assignment | Green marker; rep sees idle "waiting" view |
| En Route | Accepted, traveling | **Yes** (higher tier, cooldown rules apply) | Blue marker; nav view; requester "On the way" |
| Within 15 Miles | Backend detected <15 mi | **No — protected** | Yellow marker; "I've Arrived" enables; requester "Almost there" |
| On Site | Rep confirmed arrival | **No — protected** | Red marker; "Mark Complete" primary; requester "Arrived" |

### Request states
`Pending → Assigned → In Progress → Completed` (redirect or offline returns a request to Pending)

| State | Meaning |
|-------|---------|
| Pending | No rep assigned; waiting for a match (requester sees spinner) |
| Assigned | Rep accepted; En Route or Within 15 Miles |
| In Progress | Rep is On Site; work underway |
| Completed | Closed; disappears from dispatcher queue and map |

### Job offer states
`Pending (60s countdown) → Accepted | Declined | Expired` — Expired is treated identically to Declined.

### Vehicle states
`Unclaimed ↔ Claimed` — claimed first-come-first-served at session start, released on logout or by a
dispatcher force-release.

### Redirect cooldown
After a redirect, a **5-minute cooldown** blocks re-redirect. Silver/Bronze must respect it; **Gold
overrides it**. Cooldown never overrides Within 15 Miles / On Site protection. The redirect confirmation
dialog must surface cooldown state.

---

## 8. Real-Time Behavior (SignalR → UI)

Position updates arrive **every ~3 seconds**. The UI must update live without manual refresh. Each
persona subscribes to specific hubs:

| Hub | Audience | What the UI does with it |
|-----|----------|--------------------------|
| `VehiclePositionHub` | Dispatchers; assigned requester | Move vehicle markers; recompute displayed ETA |
| `DispatchHub` | Dispatchers | Update queue cards; show offline alert banner |
| `RepHub` | Individual rep | Pop the job-offer screen; deliver redirect-received updates |
| `RequesterHub` | Individual requester | Drive the submit → finding → tracking → complete transitions and redirect notice |

Key event-to-UI mappings:
- `JobOfferReceived` → rep offer screen with countdown
- `RepAssigned` → requester transitions from spinner to tracking
- `RepPositionUpdated` → live marker + ETA refresh (rep and requester views)
- `RepRedirected` → requester redirect notification + new rep/ETA
- `ServiceCompleted` → requester completion screen
- `ServiceRequestPending/Assigned/Completed` → dispatcher queue updates
- `RepOfflineMidJob` → dispatcher offline alert banner; marker removed; request re-queued

---

## 9. Key Flows (screen-to-screen)

**Normal request:** Requester submits (FE-015) → spinner (FE-016) → rep gets offer (FE-008) → accepts
(FE-009) → rep navigates (FE-011) while requester tracks (FE-017) → rep arrives (FE-012) → completes
(FE-013) → requester sees complete (FE-019); dispatcher map/queue reflect every transition.

**No rep available:** Request stays Pending; requester holds on the spinner; dispatcher is notified;
when a rep becomes Available the match re-runs and rejoins the normal flow.

**Priority redirect:** A higher-tier request arrives; dispatcher sees a suggested En Route match and
confirms redirect (FE-005); the rep's destination updates in place; the displaced request returns to
Pending and is re-matched; the displaced requester gets the redirect notification (FE-018).

**Rep offline mid-job:** Rep's connection drops; job returns to Pending; dispatcher gets the offline
alert (FE-006); vehicle stays Claimed until the rep re-logs and releases, or the dispatcher
force-releases it.

---

## 10. Geography & Units (for realistic mockups)

- POC operates across the **state of Iowa**; eight vehicles run pre-set statewide road loops.
- Distances use **straight-line (Haversine)**; ETA assumes **60 mph average**. Show **distance in miles**
  and **ETA in minutes**.
- Seed data for realistic mockups: 10 DTCs (each with a human-readable title), 8 vehicles, 2 dispatchers,
  8 reps, 10 requesters (6 Bronze, 3 Silver, 1 Gold).

---

## 11. Source Documents

This brief consolidates:

- [`docs/stories/frontend.md`](stories/frontend.md) — all 19 frontend stories and acceptance criteria (the screen spec)
- [`docs/architecture/system-overview.md`](architecture/system-overview.md) — personas, tiers, tech stack, platforms, seed data, geography
- [`docs/adr/0007-mudblazor-component-library.md`](adr/0007-mudblazor-component-library.md) — component library and theming decision
- [`docs/adr/0008-persona-platform-support.md`](adr/0008-persona-platform-support.md) — which platforms each persona is designed for (the §4 matrix)
- [`docs/architecture/state-machines.md`](architecture/state-machines.md) — rep / request / vehicle / job-offer states
- [`docs/architecture/data-flow.md`](architecture/data-flow.md) — end-to-end flows and SignalR hub responsibilities

When these sources change, update this brief to match.
