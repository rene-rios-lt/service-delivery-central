# ADR-0005: Simulator as a Separate External Actor

**Status:** Accepted — **superseded in part by [ADR-0009](0009-simulator-operates-rep-identities-and-human-takeover.md)**

> **Note:** The core decision below — the simulator is a separate external actor that calls the backend's public API, with zero simulation logic in the backend — still holds. However, the specifics of *how* the simulator authenticates and responds to offers have been superseded by ADR-0009: the simulator no longer uses a single auto-accepting service account. It now operates the real seeded rep accounts (`rep1…rep8`) for job decisions and holds a `Simulator`-role account only to post positions, and a human can take over any idle rep. Read the affected bullets below in light of ADR-0009.

## Context

The POC requires simulated vehicle data — moving positions, automatic job offer responses, and realistic fleet behavior — to demonstrate the full dispatch system without real field hardware. This simulation logic needs to live somewhere. Options:

- **Embed simulator in the backend** — simulator runs as part of the API, generating fake data internally
- **Simulator as a separate repo/service** — simulator is an independent process that calls the backend API

## Decision

The simulator is a **separate repository and service** that calls the backend's public API — the same API that a real Telematics integration would call.

The backend contains zero simulation logic. It does not know or care whether it is receiving data from the simulator or from real hardware.

The simulator (as revised by [ADR-0009](0009-simulator-operates-rep-identities-and-human-takeover.md)):
- Authenticates with pre-seeded accounts the same way every other user does — now the real rep accounts `rep1…rep8` (for job decisions) plus a `Simulator`-role account (for position updates). *(Originally: a single service account.)*
- Pushes every vehicle's position every 3 seconds via the backend's position update endpoint (using the `Simulator`-role account)
- Auto-responds to job offers **as each automated rep** (~85% accept / ~15% decline) — only for reps not currently controlled by a human. *(Originally: the single service account received and auto-accepted offers, which the matching engine could never actually route to it.)*
- Drives every vehicle's position from backend job-state: deviates toward the requester when a job is accepted (by an automated rep **or** a human), then returns to the loop on completion

## Consequences

- The backend is production-ready code from day one — no simulation logic to surgically remove later
- Replacing the simulator with a real Telematics integration is a **configuration change**, not a code change: swap the simulator's credentials for the Telematics provider's credentials and point to the real data source
- The simulator acts as an integration test for the backend API — if the simulator can drive the full end-to-end flow, a real client can too
- The simulator repo has its own lifecycle and can be deprecated cleanly when the real system goes live
