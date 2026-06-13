# System Overview

> **Source diagram:** [`system-overview.puml`](system-overview.puml) — component diagram showing the 4-repo structure, REST and SignalR communication channels.

## What This System Does

Service Delivery is an "Uber for service reps" — a fleet dispatch platform that connects service requesters with the nearest qualified field technician. When a requester reports a fault on their equipment (identified by a Diagnostic Trouble Code), the system finds the closest service vehicle carrying the right equipment to handle that specific fault, and dispatches the rep. Dispatchers manage the fleet, handle priority escalations, and ensure premium service plans are honored.

## The Four Repos

| Repo | Purpose |
|------|---------|
| **Central** (this repo) | Cross-cutting architecture docs, ADRs, AI skills/agents, local dev orchestration |
| **Backend** | .NET 10 Clean Architecture API — all business logic, SignalR hubs, data model |
| **Frontend** | .NET MAUI Blazor Hybrid — Desktop, Web, and Mobile hosts. Each persona is supported only on a subset of these (see [Persona Platform Support](#persona-platform-support)) |
| **Simulator** | External service that drives the system with simulated vehicle data for the POC. It operates the seeded rep accounts (`rep1…rep8`) as autonomous drivers and posts every vehicle's position, until a human takes one over (see [ADR-0009](../adr/0009-simulator-operates-rep-identities-and-human-takeover.md)) |

## The Three Personas

### Dispatcher
Manages the fleet from a command center view. Sees all service vehicles on a live map, receives incoming service requests, and gets guided to the best available rep. Has override authority to hard-reassign En Route reps to higher-priority requests. Can force-release a vehicle (`POST /vehicles/{id}/force-release`) if a rep is unreachable — distinct from the rep's own end-of-shift `POST /vehicles/{id}/release`.

### Service Rep
A field technician driving a service vehicle. Logs in, claims a vehicle for the day, and receives incoming job offers with full context (requester location, fault description, distance, ETA). Accepts or declines. Manually marks arrival ("I've Arrived") and job completion ("Mark Complete"). Releases their vehicle on daily logout.

### Simulated vs. Human Reps
The eight rep accounts (`rep1…rep8`) are operated by the **simulator** by default — it claims a vehicle for each, auto-responds to offers (~85% accept), drives to the requester, "works" for a couple of minutes, and completes — so the dispatcher map always shows a believable, busy fleet. A presenter can **take over** any *idle* rep from a real device by logging in as that rep account and selecting an *idle* vehicle: the simulator relinquishes that rep and rebalances, and from then on the human makes every decision (Accept/Decline, Arrived, Complete) while the simulator still drives the truck's position on the map. Takeover is sticky — when the human leaves, the rep and vehicle go off-duty and the simulator does not re-assume them. See [ADR-0009](../adr/0009-simulator-operates-rep-identities-and-human-takeover.md) and [Data Flow → Human Takeover](data-flow.md#flow-5--human-takeover).

### Requester
The customer or end-user reporting a fault. Submits a service request with their GPS location and the fault type. Sees an Uber-like tracking experience once a rep is assigned — rep name, ETA, live position on a map. Receives a notification if their rep is redirected to a higher-priority call.

### Priority Tiers (on Requester account)
- **Bronze** — standard service, normal queue
- **Silver** — trumps Bronze
- **Gold** — trumps Silver and Bronze; the only tier that can override the redirect cooldown

Any higher tier can redirect an En Route rep serving a lower-tier request. Reps Within 15 Miles or On Site are protected from redirect by any tier.

## Persona Platform Support

The shared Razor UI is built once and hosted on three platforms, but each persona is **designed and supported only on a subset of them**. The layout differs per platform; the available platforms differ per persona.

| Persona | Desktop | Web | Mobile | Why |
|---------|:-------:|:---:|:------:|-----|
| **Dispatcher** | ✅ | ✅ | ❌ | Dense command-center dashboard (live map + request queue side by side) — a desktop/web ergonomic, not a phone one |
| **Service Rep** | ❌ | ❌ | ✅ | Field technician working from inside a vehicle — mobile only |
| **Requester** | ✅ | ✅ | ✅ | Customer reporting a fault from any device they happen to have |

Login still routes by JWT role on whichever host the user launches. Supporting a persona on a platform outside this matrix is out of scope for the POC.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Backend API | .NET 10, Clean Architecture |
| Real-time | SignalR (WebSocket transport) |
| Frontend | .NET MAUI Blazor Hybrid |
| Map | Google Maps |
| Auth | Simulated JWT (local, no Azure AD for POC) |
| Infrastructure | Azure (Terraform) — not provisioned for POC |

## Seed Data (POC)

| Entity | Count | Notes |
|--------|-------|-------|
| DTCs | 10 | Each with a human-readable title and required equipment type |
| Vehicles | 8 | Each handles 6 of 10 DTCs (intentional variation) |
| Dispatchers | 2 | |
| Service Reps | 8 | `rep1…rep8` — driven by the simulator until a human takes one over |
| Requesters | 10 | 6 Bronze, 3 Silver, 1 Gold |
| Simulator position account | 1 | `Simulator`-role account, used only to post vehicle positions (the simulator logs in as `rep1…rep8` for job decisions — see [ADR-0009](../adr/0009-simulator-operates-rep-identities-and-human-takeover.md)) |

DTC coverage: 4 common DTCs handled by 6–8 vehicles; 6 specialized DTCs handled by 2–3 vehicles each. Every DTC is covered by at least 2 vehicles.

## Geography

The POC operates across the state of Iowa. Eight service vehicles follow pre-determined road route loops spread statewide; the simulator drives every vehicle's position — including one a human has taken over, navigating it toward the requester after the human accepts. All proximity calculations use the Haversine formula (straight-line distance). ETA assumes an average speed of 60 mph.

## Related Documents

- [State Machines](state-machines.md) — Rep and request state transitions
- [Data Flow](data-flow.md) — End-to-end request lifecycle
- [ADR-0001](../adr/0001-four-repo-structure.md) — Why four repos
- [ADR-0002](../adr/0002-signalr-for-realtime-communication.md) — Why SignalR
- [ADR-0003](../adr/0003-simulated-jwt-auth-for-poc.md) — Auth strategy
- [ADR-0004](../adr/0004-haversine-straight-line-distance.md) — Why Haversine distance
- [ADR-0005](../adr/0005-simulator-as-external-actor.md) — Why simulator is a separate repo
- [ADR-0006](../adr/0006-single-dealer-poc-multidealer-ready.md) — Single-dealer POC, multi-dealer data model
- [ADR-0007](../adr/0007-mudblazor-component-library.md) — MudBlazor component library
- [ADR-0008](../adr/0008-persona-platform-support.md) — Persona platform support
- [ADR-0009](../adr/0009-simulator-operates-rep-identities-and-human-takeover.md) — Simulator operates rep identities; human takeover
