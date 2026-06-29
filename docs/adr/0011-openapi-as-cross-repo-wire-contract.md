# ADR-0011: Backend OpenAPI document as the single source of truth for the cross-repo wire contract

**Status:** Accepted

## Context

The backend, frontend, and simulator are three separate repositories that communicate over REST and SignalR (ADR-0001, ADR-0002). Each consumer (frontend, simulator) **hand-mirrors** the backend's DTOs and event payloads in its own code. There is no shared definition of the wire contract and no check that the mirrors still match. Every wire-drift defect in the bug history traces to this, compounded by `System.Text.Json` **silently** falling back to a default (`null` / `0` / `None`) on a mismatch instead of throwing:

- **BUG-016** — the simulator deserialized `GET /vehicles/available` as `string[]`; the backend returns objects. It threw only at runtime and was invisible to unit tests, which fed the *same wrong shape* the production code assumed (the masking pattern QUAL-001 addresses).
- **BUG-036** — the RepHub `JobOfferReceived` `Tier` arrived as an enum-name string the frontend's model didn't match. `System.Text.Json` **silently defaulted it to `None`**, producing a white-on-white invisible tier badge. No crash, no failing test — just wrong.
- **BUG-028 / BUG-030** — the frontend's REST and SignalR contracts assumed an auth mechanism that was never wired; the mismatch surfaced only as 401s under live E2E.

`QUAL-006` requires a single source of truth for the contract, fail-loud deserialization, and contract tests that feed a **real captured backend payload** through each consumer's deserializer. The backend already emits an OpenAPI document via the .NET 10 built-in `Microsoft.AspNetCore.OpenApi` (`AddOpenApi()` + `MapOpenApi()`), so a canonical machine-readable contract already exists at runtime — it is simply neither exported nor consumed.

Options considered for the source of truth:

- **Commit the backend's OpenAPI document as canonical; consumers keep hand-written models but are pinned to it by captured-payload contract tests and a schema-drift check.** Lowest friction — the backend already produces the document; no new toolchain; no build coupling between the separate repos.
- **Generate consumer client models from the OpenAPI document** (NSwag / openapi-generator). Strongest anti-drift — generated models cannot diverge — but adds a codegen + regeneration step to two repos and replaces the existing hand-written models. Heavier than a POC warrants.
- **A shared contracts package/project** referenced by all three repos. Eliminates mirroring entirely, but the repos are separate with no package feed; it would require a NuGet feed or a git submodule and would couple the three builds.

## Decision

The **backend's generated OpenAPI document is the single source of truth** for the cross-repo wire contract. It is **generated at build time and committed** in the backend repo (`service-delivery-backend/contracts/openapi.json`) with a regeneration script, so the canonical contract is a reviewable artifact that changes visibly in a PR diff whenever a DTO or endpoint changes.

Consumers (frontend, simulator) **keep their hand-written models** — we do **not** introduce client codegen or a shared package for the POC. Instead, each consumer is pinned to the contract by two mechanisms:

1. **Fail-loud deserialization.** Enum deserialization rejects an unmapped or missing value rather than defaulting to `0` / `None`. A strict enum converter (a `JsonConverter` that throws on an unknown name) is registered on every deserializer that reads a backend payload, so a `Tier` drift like BUG-036 **throws** instead of rendering invisibly. This is documented as a convention in each consumer repo's `CLAUDE.md`.
2. **Captured-payload contract tests.** For each consumed endpoint and SignalR event, a test deserializes a **real captured backend payload** (not a hand-written fixture that mirrors the consumer's assumption) and asserts the consumer obtains the expected *typed* values. The regression cases that must be covered are BUG-016 (`GET /vehicles/available`) and BUG-036 (`JobOfferReceived`). Payloads are captured from the running backend (the same document/endpoints the committed OpenAPI describes), not authored by hand.

`/test-quality` is extended with the captured-payload rule as a **positive** testing pattern (the counterpart to QUAL-001's anti-masking guidance), so future cross-process contracts are tested this way by default.

This is explicitly **not** runtime schema negotiation or contract versioning, and it does **not** change any backend response shape — the backend only *exposes* the document it already produces.

## Consequences

- **The contract is reviewable.** A backend DTO or endpoint change shows up as a diff in the committed `openapi.json`, making wire-contract changes visible at review time instead of discovered at runtime.
- **Drift fails as a red test, not a silent wrong value.** A consumer model that diverges from a captured payload, or an enum value the consumer doesn't map, produces a failing contract test / a thrown deserialization — the BUG-016 and BUG-036 drifts would each go red under this scheme.
- **The committed document can go stale.** It is regenerated at build time and a sync-check guards it, but a developer who skips regeneration could commit a stale contract. The build-time generation + check is the mitigation; CI enforcement is a future enhancement (consistent with the no-standing-CI POC posture).
- **Hand-written models remain** — drift is *detected*, not *prevented* at compile time. Full prevention (codegen or a shared package) stays available as a future step if the mirroring cost grows; this ADR would be superseded rather than amended.
- **Captured payloads must be refreshed** when an intentionally changed endpoint's shape changes — the captured fixture is updated from the live backend alongside the committed `openapi.json`. A captured payload is only meaningful if it came from the real backend, so the regeneration path produces both.
- **Applies per consumer repo** — the fail-loud converter and captured-payload tests land in the frontend and simulator via `/master` (product-repo code); the ADR, the backend export, and the `/test-quality` rule are governance/tooling and land via `/ship-it`.
