# ADR-0001: Four-Repo Structure

**Status:** Accepted

## Context

The Service Delivery system spans multiple distinct layers: a governance/orchestration layer, a backend API, a cross-platform frontend, and a data simulator for the POC. These layers have different deployment lifecycles, team concerns, and long-term destinies. The simulator in particular is a temporary stand-in for a real Telematics integration and should never be entangled with production code.

## Decision

Split the system into four separate repositories:

| Repo | Role |
|------|------|
| `service-delivery-central` | Local dev orchestration, AI skills/agents, architecture docs, ADRs |
| `service-deliver-backend` | .NET 10 Clean Architecture API |
| `service-delivery-frontend` | .NET MAUI Blazor Hybrid (Desktop, Web, Mobile) |
| Simulator repo (TBD) | POC data simulator — external actor, separate deployment |

## Consequences

- Each repo can be versioned, deployed, and owned independently
- The simulator repo contains no production logic — replacing it with real Telematics is a configuration change, not a code change, because the simulator calls the same backend API any real integration would
- Engineers working in one repo do not need to clone or understand the others to do their work
- The central repo owns cross-cutting concerns (docs, ADRs, local dev scripts) so they have a single authoritative home
