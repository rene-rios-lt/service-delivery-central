# ADR-0009: Simulator Operates Real Rep Identities, With Human Takeover

**Status:** Accepted

**Supersedes (in part):** [ADR-0005](0005-simulator-as-external-actor.md) — the "single pre-seeded service account that auto-accepts offers" portions. The external-actor principle of ADR-0005 still holds.

## Context

The POC demo needs to show a believable fleet of *many* service reps moving and working across Iowa, while also letting a presenter pick up a **real device, log in as a service rep, and personally drive a job** — receiving an offer, accepting it, and tapping "I've Arrived" / "Mark Complete" as the truck moves.

The original design (ADR-0005) had the simulator authenticate as one `Simulator`-role service account and "receive job offers over SignalR and auto-accept ~85%." That cannot work against the backend as built: the matching algorithm only ever offers a job to a **rep that has claimed a vehicle and is `Available`** — candidates are inner-joined on an active `RepSession` (`MatchingService.cs`, `RepStateRepository`). A `Simulator`-role account never claims a vehicle and is never a candidate, so it would never receive an offer. The single-account model also has no way to represent "a human has taken over one of the simulated reps."

## Decision

The simulator operates the **real seeded rep accounts** (`rep1…rep8`) as autonomous drivers, and a human can **take over** any idle one from a real device.

**Identity model**
- For *job decisions*, the simulator logs in as each real rep account (`rep1…rep8`, role `ServiceRep`), claims a vehicle, connects to `RepHub`, and auto-responds to offers **as that rep**. These are ordinary `Available` reps, so matching dispatches to them normally.
- For *position updates*, the simulator additionally holds the `Simulator`-role account and posts every vehicle's position via `POST /vehicles/{id}/position` (that endpoint is `Simulator`-role and has no per-vehicle ownership check, so one account drives all trucks). **Vehicle position is simulator-pushed, not backend-derived.**

**Human takeover**
- A human logs in **as one of the same rep accounts** on a real device and selects an **idle** vehicle from a dropdown. A takeover marks that rep **human-controlled** on the backend; the device sends a periodic heartbeat.
- The simulator is **reconciliation-driven**: each tick it reads authoritative fleet state and operates only the reps *not* marked human-controlled, rebalancing its remaining reps onto free vehicles. The human's selection therefore supersedes whatever the simulator had assigned.
- Eligibility: a human may take over only an **idle rep** (no active job) and an **idle vehicle** (not EnRoute / Within15Miles / OnSite).
- While a human drives, the simulator still drives that truck's **position** from backend job-state — navigating to the requester after the human taps Accept, then **holding** until the human taps Arrived / Complete. The human owns all decisions (Accept/Decline, Arrived, Complete); the device never reports GPS.

**Lifecycle**
- Takeover is **sticky**: when the human logs out or their heartbeat times out, the rep goes Offline and the vehicle parks — the simulator **never re-assumes** that rep+vehicle for the remainder of the run ("gone home for the night").
- If the human was mid-job when they dropped, the abandoned request is **re-matched** to another available rep (in practice, an automated one).
- A dispatcher may **redirect** a human-controlled rep on the same terms as an automated one; the simulator re-navigates the truck from the updated job-state and the device shows the redirect (hard reassignment).

**Automated reps** run the full cycle unattended: accept ~85% / decline ~15% after a 1–5s delay, drive to the requester, auto-arrive, **work a randomized 120–240 seconds** (so viewers see real "mechanic at work" dwell time), auto-complete, and resume their loop.

## Consequences

- The matching engine is exercised end-to-end with no special-casing — simulated reps are real `Available` reps, indistinguishable to the backend from human ones.
- The backend stays simulation-agnostic in spirit: the only new backend surface is a takeover endpoint, a `human-controlled` marker + heartbeat, and a `Simulator`-role read of fleet job-state for position driving — no auto-pilot business logic.
- Replacing the simulator with real Telematics is still a credentials/data swap for *positions*; the automated-decision behavior is simulator-only and simply goes away when real reps use the app.
- The simulator gains real coordination concerns (multi-identity auth, reconciliation, yield-on-takeover) that did not exist in the single-account model. This is the deliberate cost of a compelling, interactive demo.
- ADR-0003's auth model is unchanged in mechanism but now spans `rep1…rep8` plus the `Simulator` account (see that ADR's amendment note).
