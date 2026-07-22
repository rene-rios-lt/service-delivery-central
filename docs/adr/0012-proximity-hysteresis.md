# ADR-0012: Bidirectional rep proximity transition with hysteresis (En Route ⇄ Within 15 Miles)

**Status:** Accepted

## Context

A rep assigned to a request moves through the proximity states `En Route → Within 15 Miles` as its vehicle closes on the requester (see `state-machines.md`). The backend recomputes this on every position update from the simulator using a straight-line Haversine distance against a 15-mile threshold.

The original implementation made the transition **one-way**: `UpdateVehiclePositionCommandHandler` recomputed proximity **only while the rep was already `En Route`**, so once a rep reached `Within 15 Miles` no later position update could move it back — it was a permanent latch for the remainder of the assignment.

This surfaced as a hard blocker (BUG-059, discovered via the BUG-055 redirect-test investigation):

- **`POST /dispatcher/redirect` is an `En Route`-only action** (`RedirectRepCommandHandler` — a `Within 15 Miles` rep is proximity-protected, no tier can override). With the one-way latch, a rep is redirect-eligible only during the window before it first crosses 15 mi, and **never again** — even if the vehicle is later demonstrably far away.
- The simulator's `VehicleWorker` **Navigate** driver steps every `En Route` truck toward its request every ~3 s, so a rep assigned to a nearby request reaches `Within 15 Miles` almost immediately and is then permanently un-redirectable. This made the `RequesterRedirectTests` redirect precondition **impossible to arrange from the frontend** (three failed live gates — see BUG-055).

The proximity state should reflect the vehicle's **actual current distance**, not a latched historical minimum.

A naive symmetric fix (single 15-mile threshold both directions) reintroduces a real problem: a rep hovering right at ~15 mi — from GPS jitter, a brief detour, or the discrete ~3 s position tick — would **flap** between `En Route` and `Within 15 Miles` on successive updates, toggling redirect-eligibility and emitting repeated state-change events over SignalR.

Options considered:

- **Symmetric single threshold (15 mi both directions).** Simplest (a one-line guard change). Rejected as the committed behaviour because of boundary flapping.
- **Hysteresis — separate enter and exit thresholds.** Enter `Within 15 Miles` at `< 15` mi; return to `En Route` only at `≥ 17` mi; the 15–17 mi band holds the current state. Prevents flapping while making the transition bidirectional. Costs one extra constant and a state-dependent computation.
- **Backend-only, no re-eligibility (leave the latch, change nothing).** Rejected — it is the defect; it makes redirect permanently impossible for nearby-assigned reps and does not reflect reality.

## Decision

The rep proximity transition is **bidirectional with hysteresis**, recomputed on **every** position update for any assigned rep in `En Route` **or** `Within 15 Miles`:

- **Enter:** `En Route → Within 15 Miles` when Haversine distance `< 15` mi (`ThresholdMiles = 15.0`) — unchanged forward behaviour.
- **Exit:** `Within 15 Miles → En Route` when Haversine distance `≥ 17` mi (`ExitThresholdMiles = 17.0`).
- **Dead-band:** in the 15–17 mi band the rep **stays in its current state** — no transition — so boundary noise cannot flap it.

A rep that moves back out past 17 mi returns to `En Route` and thereby **becomes redirect-eligible again** — this is the intended, more-correct behaviour: redirect eligibility tracks where the vehicle actually is. The redirect-eligibility guards in `RedirectRepCommandHandler` are **unchanged**; they clear naturally once the state returns to `En Route`. A rep that *is* `Within 15 Miles` at the moment of a redirect call is still rejected.

The logic is kept **inline** in `UpdateVehiclePositionCommandHandler` (the cohesive owner of the proximity rule); no separate policy class is introduced for a two-branch computation used by a single handler.

## Consequences

- A rep is redirect-eligible whenever its vehicle is genuinely `≥ 17` mi from its request, not only before it first crosses 15 mi. This unblocks the redirect flow in the live system and makes BUG-055's frontend redirect arrange achievable (reach tracking with the fleet at the requester, then move the assigned rep back out → it returns to `En Route` → redirect succeeds).
- The 2-mile dead-band means a rep is not considered "within 15 miles" again until it re-closes below 15 mi, and is not considered "en route" again until it passes 17 mi — a deliberate asymmetry callers should be aware of when reasoning about the exact state near the boundary.
- `Within 15 Miles` is no longer terminal-until-complete. Consumers must not assume it is a latch. Confirmed unaffected: `/rep/arrive` (`ArriveCommandHandler` reads state at tap time, not a latch) and arrival reporting.
- The two thresholds (15 / 17 mi) are constants in `UpdateVehiclePositionCommandHandler`; tuning the dead-band is a one-line change. The straight-line Haversine model (ADR — Haversine distance) is unchanged.
- `state-machines.md` and `state-machines.puml` are updated with the reverse `Within 15 Miles → En Route` transition and the hysteresis note.
