# ADR-0005: Simulator as a Separate External Actor

**Status:** Accepted

## Context

The POC requires simulated vehicle data — moving positions, automatic job offer responses, and realistic fleet behavior — to demonstrate the full dispatch system without real field hardware. This simulation logic needs to live somewhere. Options:

- **Embed simulator in the backend** — simulator runs as part of the API, generating fake data internally
- **Simulator as a separate repo/service** — simulator is an independent process that calls the backend API

## Decision

The simulator is a **separate repository and service** that calls the backend's public API — the same API that a real Telematics integration would call.

The backend contains zero simulation logic. It does not know or care whether it is receiving data from the simulator or from real hardware.

The simulator:
- Authenticates with a pre-seeded service account JWT (same auth as all other users)
- Pushes vehicle position updates every 3 seconds via the backend's position update endpoint
- Receives job offers over SignalR and auto-accepts them (~85%) or auto-declines (~15%)
- Deviates from pre-determined route loops when a vehicle is assigned to a job, navigating toward the requester

## Consequences

- The backend is production-ready code from day one — no simulation logic to surgically remove later
- Replacing the simulator with a real Telematics integration is a **configuration change**, not a code change: swap the simulator's credentials for the Telematics provider's credentials and point to the real data source
- The simulator acts as an integration test for the backend API — if the simulator can drive the full end-to-end flow, a real client can too
- The simulator repo has its own lifecycle and can be deprecated cleanly when the real system goes live
