# System Overview

## What This System Does

Service Delivery is an "Uber for service reps" — a fleet dispatch platform that connects service requesters with the nearest qualified field technician. When a requester reports a fault on their equipment (identified by a Diagnostic Trouble Code), the system finds the closest service vehicle carrying the right equipment to handle that specific fault, and dispatches the rep. Dispatchers manage the fleet, handle priority escalations, and ensure premium service plans are honored.

## The Four Repos

| Repo | Purpose |
|------|---------|
| **Central** (this repo) | Cross-cutting architecture docs, ADRs, AI skills/agents, local dev orchestration |
| **Backend** | .NET 10 Clean Architecture API — all business logic, SignalR hubs, data model |
| **Frontend** | .NET MAUI Blazor Hybrid — Desktop, Web, and Mobile views for all three personas |
| **Simulator** | External service that drives the system with simulated vehicle data for the POC |

## The Three Personas

### Dispatcher
Manages the fleet from a command center view. Sees all service vehicles on a live map, receives incoming service requests, and gets guided to the best available rep. Has override authority to hard-reassign En Route reps to higher-priority requests. Can force-release a vehicle if a rep is unreachable.

### Service Rep
A field technician driving a service vehicle. Logs in, claims a vehicle for the day, and receives incoming job offers with full context (requester location, fault description, distance, ETA). Accepts or declines. Manually marks arrival ("I've Arrived") and job completion ("Mark Complete"). Releases their vehicle on daily logout.

### Requester
The customer or end-user reporting a fault. Submits a service request with their GPS location and the fault type. Sees an Uber-like tracking experience once a rep is assigned — rep name, ETA, live position on a map. Receives a notification if their rep is redirected to a higher-priority call.

### Priority Tiers (on Requester account)
- **Bronze** — standard service, normal queue
- **Silver** — trumps Bronze
- **Gold** — trumps Silver and Bronze; the only tier that can override the redirect cooldown

Any higher tier can redirect an En Route rep serving a lower-tier request. Reps Within 15 Miles or On Site are protected from redirect by any tier.

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
| Service Reps | 8 | |
| Requesters | 10 | 6 Bronze, 3 Silver, 1 Gold |
| Simulator account | 1 | Pre-seeded service account |

DTC coverage: 4 common DTCs handled by 6–8 vehicles; 6 specialized DTCs handled by 2–3 vehicles each. Every DTC is covered by at least 2 vehicles.

## Geography

The POC operates across the state of Iowa. Eight service vehicles follow pre-determined road route loops spread statewide. All proximity calculations use the Haversine formula (straight-line distance). ETA assumes an average speed of 60 mph.

## Related Documents

- [State Machines](state-machines.md) — Rep and request state transitions
- [Data Flow](data-flow.md) — End-to-end request lifecycle
- [ADR-0001](../adr/0001-four-repo-structure.md) — Why four repos
- [ADR-0002](../adr/0002-signalr-for-realtime-communication.md) — Why SignalR
- [ADR-0003](../adr/0003-simulated-jwt-auth-for-poc.md) — Auth strategy
- [ADR-0004](../adr/0004-haversine-straight-line-distance.md) — Why Haversine distance
- [ADR-0005](../adr/0005-simulator-as-external-actor.md) — Why simulator is a separate repo
- [ADR-0006](../adr/0006-single-dealer-poc-multidealer-ready.md) — Single-dealer POC, multi-dealer data model
