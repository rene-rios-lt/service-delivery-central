# User Stories

This directory contains the full user story backlog for the Service Delivery system, organised by repo, plus an execution plan that sequences them in dependency order.

| File | Contents |
|------|----------|
| [`simulator.md`](simulator.md) | 12 stories — SIM-001 to SIM-012 |
| [`backend.md`](backend.md) | 29 stories — BE-001 to BE-029 |
| [`frontend.md`](frontend.md) | 29 stories — FE-001 to FE-029 (FE-024–028 = the Google Maps epic, [ADR-0010](../adr/0010-google-maps-for-map-visualization.md); FE-029 = app-bar & nav chrome: left hamburger, safe area, bell removal) |
| [`quality.md`](quality.md) | Cross-cutting engineering-quality stories — QUAL-001+ (product-code QUAL stories carry a **Repo / Area** line and run via `/master`; central-only ones ship via `/ship-it`) |
| [`bug.md`](bug.md) | Bugs — BUG-001 to BUG-018 (BUG-016/017 fixed; BUG-018 open) |
| [`execution-plan.md`](execution-plan.md) | Phase-based plan (+ a Cross-Cutting section) sequencing all stories in dependency order |

## Quick Reference

| ID Range | Epic | Repo |
|----------|------|------|
| SIM-001 | Auth & startup | Simulator |
| SIM-002 | RepHub connection | Simulator |
| SIM-003–004 | Position updates | Simulator |
| SIM-005 | Job offer auto-response (per automated rep) | Simulator |
| SIM-006–007 | Job navigation | Simulator |
| SIM-008–010 | Reconciliation, human-takeover yield, on-site work dwell | Simulator |
| BE-001–002 | Authentication | Backend |
| BE-003–008 | Vehicles | Backend |
| BE-009 | DTCs | Backend |
| BE-010–013 | Service requests | Backend |
| BE-014 | Matching algorithm | Backend |
| BE-015–018 | Job offers | Backend |
| BE-019–020 | Rep state transitions | Backend |
| BE-021–022 | Dispatcher operations | Backend |
| BE-023 | Resilience | Backend |
| BE-024 | Data seeding | Backend |
| BE-025 | SignalR infrastructure | Backend |
| BE-026–028 | Human takeover, simulator fleet-state read, heartbeat/presence | Backend |
| FE-001–002 | Authentication | Frontend |
| FE-003–006, FE-022 | Dispatcher view (incl. force-release) | Frontend |
| FE-007–014, FE-020, FE-023 | ServiceRep view (incl. takeover, idle, heartbeat) | Frontend |
| FE-015–019 | Requester view | Frontend |
| FE-021, FE-029 | App shell, navigation & logout (FE-029 = app-bar & nav chrome: left hamburger, iOS safe area, dispatcher bell removal) | Frontend |
| FE-024–028 | Real Google Maps (component, key/SDK, screen swap-ins, optional Directions) | Frontend |
| BUG-001–015 | Open bugs | Backend / Frontend / Central |
