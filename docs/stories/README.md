# User Stories

This directory contains the full user story backlog for the Service Delivery system, organised by repo, plus an execution plan that sequences them in dependency order.

| File | Contents |
|------|----------|
| [`simulator.md`](simulator.md) | 10 stories — SIM-001 to SIM-010 |
| [`backend.md`](backend.md) | 28 stories — BE-001 to BE-028 |
| [`frontend.md`](frontend.md) | 23 stories — FE-001 to FE-023 |
| [`bug.md`](bug.md) | Bugs — BUG-001 to BUG-015 (all fixed) |
| [`execution-plan.md`](execution-plan.md) | 11-phase plan sequencing all 61 stories |

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
| FE-021 | App shell, navigation & logout | Frontend |
| BUG-001–015 | Open bugs | Backend / Frontend / Central |
