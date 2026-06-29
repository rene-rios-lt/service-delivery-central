---
description: Unit vs integration test level requirements, value-add criteria, and duplication checks — used during AI Review to evaluate whether the test suite is fit for purpose.
---

# Skill: Test Quality

## Purpose

Define what constitutes a valuable test suite — at both unit and integration levels — and provide the criteria for identifying low-value or duplicated tests. Use this skill during AI Review to evaluate whether the test suite is fit for purpose.

---

## Two Required Levels

Any story that touches the Application or Infrastructure layers requires tests at **both** levels. A story that has only unit tests or only integration tests cannot pass AI Review.

### Unit Tests

- Test a **single unit of behaviour** in isolation.
- All external dependencies (repositories, services, SignalR hubs) are **mocked**.
- No I/O, no network, no database.
- Fast — the full suite should run in seconds.
- Live in `ServiceDelivery.Domain.Tests` and `ServiceDelivery.Application.Tests`.

**What they verify:** business logic, domain rules, command handler behaviour given controlled inputs.

### Integration Tests

- Test a unit's interaction with a **real dependency**.
- Use an in-memory database, test containers, or a real test HTTP server (`WebApplicationFactory`).
- Slower — acceptable, but not needlessly bloated. A single integration test should complete within 5 seconds. If it exceeds this on three consecutive cold runs, investigate: is it fetching more data than needed? Is the test database over-seeded? Scope test data to the minimum required for the assertion. If the root cause cannot be fixed within the story scope, raise an **Advisory** finding in the AI Review output: `Advisory: Integration test [name] exceeds 5s on cold runs — investigate test data scope.`
- Live in `ServiceDelivery.Infrastructure.Tests` and `ServiceDelivery.Api.Tests`.

**What they verify:** EF Core queries produce correct results, endpoints return correct status codes, SignalR events are sent to the right groups.

---

## Lowest Sufficient Test Level

Cover every behaviour at the **lowest test level that can fully exercise it**. A higher, slower level is required only when no lower level can give correct coverage — never as a default "to be safe."

E2E tests (Playwright for Web/Desktop, Appium for Mobile) sit at the top of this hierarchy: slowest, most brittle, and most expensive to run (a live system + a real browser or booted simulator). They are **not** required for every UI change. Decide per behaviour:

- **If a unit or integration test can fully cover it → that level is the requirement; an E2E test is not.** Most UI work lives here: component rendering, string/label formatting, conditional display, and list rendering are covered by bUnit component tests; ViewModel logic and state by ViewModel unit tests; service↔backend wire/serialization contracts by integration tests or the headless smoke. Do not demand an E2E test for behaviour a component or integration test already proves.
- **If neither a unit nor an integration test can cover it → an E2E test is the only sufficient level, and is therefore required.** A behaviour is E2E-only when it depends on real runtime integration the lower levels mock out or cannot instantiate: the native host actually launching, real platform navigation / lifecycle / deep links / permissions, real browser DOM and routing, a live SignalR transport delivering to a rendered client, or auth headers travelling over a real HTTP round-trip into the UI.

The test pyramid is the goal: many fast unit tests, fewer integration tests, and only the handful of E2E tests that cover what nothing below them can. Pushing coverage that a unit test could carry up into the E2E suite makes the suite slow and flaky for no added protection. (This is the rule the AI Review's Frontend E2E test check applies — see `story-ai-reviewer`.)

---

## Value-Add Check

Each test must assert something that would **catch a real regression**. Evaluate every test against this criterion:

**Low-value tests (flag these):**

- Verify-only: the test only asserts that a mock method was called, with no assertion on state or return value.
  ```csharp
  // Low-value — only verifies the call, not the outcome
  mockRepo.Verify(r => r.SaveAsync(It.IsAny<ServiceRequest>()), Times.Once);
  ```

- Trivial getter: the test only asserts that a property returns the value it was constructed with — no logic involved.

**Exception — fire-and-forget side effects:** mock-verify is acceptable as the *primary* assertion when the behaviour under test is a side effect with no return value or observable state change (e.g. sending an email, publishing a domain event, broadcasting a SignalR message in a unit test). Verifying the call IS the correct assertion. These are not flagged as low-value.

```csharp
// Acceptable — sending an email is a side effect with no return value to assert on
mockEmailService.Verify(e => e.SendAsync(It.Is<Email>(m => m.To == "rep@example.com")), Times.Once);
```

For the criteria that distinguish Partial from Covered on SignalR AC bullets specifically, see the ac-coverage skill (`../.claude/skills/ac-coverage/SKILL.md`, SignalR Event ACs section).

- Happy-path only with no edge case coverage: if the story's AC includes a `409`, `400`, or `422` scenario, a test that only covers the success path is incomplete.

**High-value tests (look for these):**

- Assert on the state of the system after the action (entity fields changed, status transitioned).
- Assert on the response body and status code together.
- Cover the failure paths and boundary conditions called out in the AC.
- Would fail if the business rule they cover were accidentally removed.

---

## Anti-Masking Rule

A **masking test** passes by coincidence: it would *still pass against the wrong or old contract*, so it guards nothing. A green suite full of masking tests gives false confidence — this is exactly how `BUG-016` and `BUG-017` shipped behind 150 passing simulator unit tests. Flag every masking test; a masking test provides no protection and must be called out even if it asserts on state.

Two patterns to hunt for:

**1. Placeholder reuse collapsing two distinct identities.** A test reuses one literal for two conceptually different things, so an assertion that *should* prove the code picked the right one passes trivially.

```csharp
// MASKING — route registration and the backend GUID are the SAME literal,
// so this assertion passes whether the worker posts the registration OR the GUID.
var route = new VehicleRoute { VehicleId = "V-TEST", ... };
var row   = new FleetStateRow("V-TEST", "rep-1", ...);   // ← same value, two identities
...
Assert.Equal(route.VehicleId, post.VehicleId);           // proves nothing (BUG-017)

// FAITHFUL — distinct values for distinct concepts; the assertion now has teeth.
const string RouteRegistration = "V-TEST";
const string BackendGuid       = "30000000-0000-0000-0000-000000000001";
var route = new VehicleRoute { VehicleId = RouteRegistration, ... };
var row   = new FleetStateRow(BackendGuid, "rep-1", ...);
...
Assert.Equal(BackendGuid, post.VehicleId);
Assert.NotEqual(RouteRegistration, post.VehicleId);      // would FAIL on the wrong contract
```

**2. Fixtures mirroring the code's own wrong assumption.** A request/response fixture is shaped to match what the production code *expects* rather than what the real API actually returns, so the test confirms the bug instead of catching it.

```csharp
// MASKING — production wrongly deserializes string[]; the fixture feeds string[] too,
// so the test is green while the real API returns objects (BUG-016).
var json = """["V-001","V-002"]""";

// FAITHFUL — fixture mirrors the REAL contract: GET /vehicles/available returns
// objects { vehicleId, registration, equipment }. A wrong deserialization now fails.
var json = """[{"vehicleId":"...","registration":"V-001","equipment":["..."]}]""";
```

**The rule:**
- Use realistic, contract-faithful, **distinct** identifiers. Never reuse one placeholder for two distinct concepts (backend GUID vs registration string, route id vs fleet-state row id, request id vs offer id).
- Request/response fixtures must match the **real** API shape — verify against the actual backend DTO / endpoint, not against what the code under test happens to parse.
- Litmus test for every assertion: *would this test still pass if the production code mirrored the wrong/old contract?* If yes, it is masking — flag it.

### Mocked unit tests cannot verify a cross-process contract

A mocked unit test can never verify a cross-process **wire or identity contract** — the mock answers whatever the test tells it to, so it agrees with the code's assumption by construction (both masking patterns above live here). Serialization shape, field names, GUID-vs-registration keying, and HTTP status semantics across the simulator↔backend boundary are only proven by an integration run.

The **headless smoke is the integration net**: `scripts/local/start.sh` (full system up) followed by `scripts/local/smoke.sh` (drives one job end-to-end by API). Run it before declaring a repo "done" — a repo whose only evidence is a green mocked unit suite has **not** verified its wire contracts. `BUG-016` and `BUG-017` were both caught only by this smoke, never by unit tests.

### Captured-payload contract tests — the positive pattern (QUAL-006)

The anti-masking rule above is stated as prohibitions; this is its positive counterpart. **Every consumed cross-process contract — a REST endpoint or a SignalR event — should be backed by a captured-payload contract test.** The pattern:

- **Real captured payload.** Feed a payload in the **real backend wire shape** (camelCase; enums as the backend serializes them — a *string* for SignalR `JobOfferReceived`, a *number* for REST `/users/me`), captured from the running backend or the committed OpenAPI contract — **never** hand-shaped to the consumer's assumption.
- **Through the production path.** Deserialize via the **same path the consumer uses at runtime** — `ReadFromJsonAsync` / the `HubConnection`'s `JsonSerializerDefaults.Web` / the client's own `JsonSerializerOptions` — not a hand-built model object and not a re-declared options bag that can drift from production.
- **Assert typed values with distinct per-field values**, so a field-name or ordinal drift cannot pass coincidentally (the same distinctness the anti-masking rule demands).
- **Pair with fail-loud deserialization.** A wire enum that arrives unmapped/missing/integer must **throw**, never silently default (a `ServiceTier` to `None`, a `RepState` to `Offline`). That is the BUG-036 invisible-badge / BUG-016 wrong-shape failure mode turned into a red test.

This is the unit-level proof that complements the integration smoke, and the default for any new cross-process contract. Central **ADR-0011** records the wire-contract source of truth (the committed backend OpenAPI doc); reference implementations live in the simulator (`BackendApiClientContractTests`) and frontend (`JobOfferReceivedDeserializationTests`). Litmus: *does a test deserialize a real backend payload through the consumer's own deserializer and assert distinct typed values, and does a drifted enum throw?* If a consumed contract has no such test, call it out.

### Frontend composition-root rule — exercise the real DI / handler-chain / lifecycle (QUAL-007)

The masking patterns above are about *data shape*; this is the **frontend** instance of the same disease about *integration*. A frontend test masks when it renders a component in a vacuum or stubs the handler chain away, so a defect in the real composition stays green. A green bUnit suite must mean "the integrated app works," not "an isolated widget renders on a convenient route." This is exactly how the `OnInitializedAsync`-vs-`OnParametersSetAsync` defect (BUG-025/026), the startup auth-flash (BUG-029), and the handler-pipeline gaps (BUG-024 session-expiry firing on the login 401; BUG-028 missing bearer handler) all passed unit tests while the real screen was broken.

**The rule:** for behaviour that depends on **(a)** the DI pipeline / composition root, **(b)** the `HttpClient` `DelegatingHandler` chain, or **(c)** the Blazor render/navigation lifecycle (`OnInitialized` vs `OnParametersSet`, parameter-diffing, the Router reusing a layout instance across navigations), the test **must exercise that real composition**. Rendering a component on a non-representative route, or stubbing the handler chain away, is a **masking test** and must be called out — even if it asserts on rendered state.

*(In the bUnit examples below, `ctx` is a v2 `BunitContext` instance — `ctx.Render` / `ctx.Services`. A test class may equivalently inherit `BunitContext` and call `Render` / `Services` directly, the style shown in `.claude/skills/tdd-cycle/SKILL.md`.)*

**Trap 1 — testing a layout/lifecycle on a non-representative route (BUG-025/026/029).** The real flow starts at `/login` and then navigates to an authenticated route; the Router **reuses** the layout instance, so on that transition `OnInitializedAsync` does **not** fire again — only `OnParametersSetAsync` does. A test that renders the layout *directly* on the authenticated route exercises the once-only init path production never takes, and a fresh render always re-renders its children so it can't see the parameter-diffing skip either.

```csharp
// MASKING — renders MainLayout straight onto an authenticated route with auth primed.
// Shell loads, avatar appears, test is green — but it ran OnInitializedAsync (fires once),
// the path the real login→navigate flow never re-runs. The OnParametersSetAsync /
// router-reuse defect (BUG-026) is invisible here.
ctx.Services.AddSingleton<NavigationManager>(new FakeNavigationManager("/dispatcher"));
var cut = ctx.Render<MainLayout>();
cut.WaitForElement("[data-testid='persona-avatar']");          // proves nothing about navigation

// FAITHFUL — start at /login, render, THEN navigate, asserting the shell loaded *after*
// the navigation. This exercises OnParametersSetAsync and the Router reusing the layout.
var nav = ctx.Services.GetRequiredService<FakeNavigationManager>();   // starts at /login
var cut = ctx.Render<MainLayout>();
nav.NavigateTo("/dispatcher");                                  // the real transition
cut.WaitForElement("[data-testid='persona-avatar']");           // would FAIL on the BUG-026 lifecycle
```

*Hosting precondition for the faithful test:* `NavigateTo` re-drives `OnParametersSetAsync` **only** if `MainLayout` is rendered under a context that propagates the location change — the bUnit `FakeNavigationManager` wired so the layout's parameters are re-set on navigation. Rendered standalone, `NavigateTo` won't re-invoke the lifecycle and the test silently reverts to a no-op. Confirm it: the post-navigation assertion must actually **fail** when the lifecycle is wrong (render at `/login`, navigate, assert) — if it passes with the layout's `OnParametersSetAsync` stubbed out, the test isn't exercising the transition it claims to.

**Trap 2 — asserting a handler in isolation when the defect is its position/interaction in the pipeline (BUG-024/028).** A `DelegatingHandler` is correct in isolation but wrong *in the chain*. BUG-024: `SessionExpiryHttpHandler` throws on any 401 — fine alone, but it sits in the **login** `HttpClient`'s pipeline, so it fires on the login-failure 401 before `HttpAuthService` can read it. BUG-028: no handler attached the bearer token to the shared pipeline, so every authenticated call went out anonymous — a service tested with a hand-fed token never proves the *composed* client sends the header.

```csharp
// MASKING — SessionExpiryHttpHandler in a vacuum with a stub inner handler returning 401.
// Asserts it throws SessionExpiredException. Green — but it is never placed in the login
// pipeline, so it cannot see that it wrongly fires on the /auth/login 401 (BUG-024).
var handler = new SessionExpiryHttpHandler(expiry) { InnerHandler = new Stub401() };
await Assert.ThrowsAsync<SessionExpiredException>(() => Send(handler, "/anything"));

// FAITHFUL — build the chain in the order the host registers it
// (SessionExpiryHttpHandler → AuthTokenHttpHandler → HttpClientHandler), or resolve the
// configured HttpClient from the host's DI, then assert the *interaction*:
//   • a 401 from /auth/login does NOT throw (BUG-024), and
//   • an authenticated request carries Authorization: Bearer <token> with no per-call code (BUG-028).
var client = BuildHostHttpClient(captureInner);                 // real registered chain
await client.PostAsync("/auth/login", badCreds);                // does not throw — login owns its 401
await client.GetAsync("/vehicles/available");
Assert.Equal("Bearer " + token, captureInner.Last.Headers.Authorization?.ToString());
```

- **Test through the real route/lifecycle** (the render-then-navigate pattern of Trap 1): never render already-authenticated on the destination route. Where the defect is a parameter-diffing skip, mutate the shared ViewModel's inner state **without** swapping the reference and assert the child re-rendered.
- **Test through the real handler chain:** assemble the `DelegatingHandler`s in the host's registration order (or resolve the configured `HttpClient`/`IHttpClientFactory` client from DI) and assert the cross-handler interaction — never a single handler with a stubbed inner handler when the defect is its position.
- **Litmus:** *does this test exercise the real DI wiring / handler chain / navigation lifecycle, or a convenient stand-in (direct route, isolated handler, hand-built client)?* If the integrated composition is stubbed away, it is masking — flag it. This rule is referenced by `story-ai-reviewer` (Checks 2 and 3b) for every frontend story.

---

## Duplication Check

Two tests are duplicates if they exercise the **same code path** with the **same inputs** and assert the **same outputs**. Duplicates add noise without adding coverage.

**How to identify:** for each pair of tests in the same file, ask:
1. Do they call the same method/endpoint?
2. Do they use equivalent inputs?
3. Do they assert the same thing?

If yes to all three, one of them is redundant. Flag it.

**Not duplicates:** two tests that call the same method but with different inputs (e.g. one for Bronze tier, one for Gold tier) are testing distinct behaviours and are both valuable.

---

## AC Mapping Requirement

Every acceptance criterion bullet in the story must be traceable to at least one test. This is a strict requirement, not a guideline.

Cross-reference with the `ac-coverage` skill to produce the mapping table during AI Review.

---

## Domain-Only Stories

A story that touches only the Domain layer (e.g. a pure value object, an entity invariant, a domain event) requires unit tests in `Domain.Tests` only. No integration tests are required. The "both levels required" rule applies only when Application or Infrastructure layers are touched.

---

## AI Review Quick Reference

This is a quick reference. Each item is governed by its own skill — consult the linked skill before raising a finding.

| Checklist item | Governing skill |
|----------------|----------------|
| Unit and integration tests present | this skill (Two Required Levels) |
| Every test asserts on state or output | this skill (Value-Add Check) |
| No masking tests (placeholder reuse / fixtures mirroring the wrong contract) | this skill (Anti-Masking Rule) |
| Each consumed cross-process contract has a captured-payload contract test + fail-loud deserialization | this skill (Captured-payload contract tests) |
| Frontend lifecycle/handler/DI-dependent behaviour tested through the real composition, not a widget in a vacuum | this skill (Frontend composition-root rule) |
| No duplicate tests | this skill (Duplication Check) |
| Every AC maps to a test | ac-coverage skill |
| `GivenA_When_Then` naming | tdd-cycle skill |
| Arrange / Act / Assert structure | tdd-cycle skill |

For each test file, verify:

- [ ] Both unit and integration tests present (if Application or Infrastructure layer touched — see Repo Adaptations below for the equivalent check per repo)
- [ ] Every test method asserts on state or output, not only on mock interactions
- [ ] No masking tests — distinct identifiers for distinct concepts; fixtures match the real API shape; every assertion would fail against the wrong/old contract
- [ ] Each consumed REST endpoint / SignalR event has a captured-payload contract test (real payload through the production deserializer) and fail-loud enum deserialization (drift throws, never defaults)
- [ ] Frontend lifecycle/handler/DI-dependent behaviour is tested through the real composition — rendered from `/login` then navigated (not directly on the destination route); the real `DelegatingHandler` chain assembled in host order (not a handler in isolation)
- [ ] No two tests are duplicates
- [ ] Every AC bullet maps to at least one test
- [ ] All test methods follow `GivenA_When_Then` naming
- [ ] All tests follow Arrange / Act / Assert structure

---

## Repo Adaptations

The two-level rule (unit + integration) applies to all repos but the projects differ.

### Backend (`service-delivery-backend`)

| Level | Projects |
|-------|---------|
| Unit | `Domain.Tests`, `Application.Tests` |
| Integration | `Infrastructure.Tests`, `Api.Tests` |

Both levels required for stories touching Application or Infrastructure. Domain-only stories need `Domain.Tests` only.

### Frontend (`service-delivery-frontend`)

All tests live in `ServiceDelivery.Client.Tests`. There is no separate integration test project.

| Test type | What it tests | Tools |
|-----------|--------------|-------|
| ViewModel unit test | Pure C# logic in `Core/ViewModels/` | xUnit (no bUnit needed) |
| Component test | Razor component rendering and interaction | xUnit + bUnit (`Render<T>()`) |
| Service contract test | Interface implementations in host `Services/` folders | xUnit with mocked dependencies |

Both ViewModel unit tests and component tests are required for any story that adds a ViewModel AND a component. A story that only adds a component does not need a ViewModel test if no ViewModel is involved.

**High-value component tests** assert that:
- A specific rendered element (button, status chip, label) reflects a ViewModel property value.
- A user interaction (button click, form submit) triggers the correct ViewModel method or state change.
- Conditional rendering shows or hides an element based on ViewModel state.

**Low-value component tests** — flag these:
- Asserts only that a ViewModel method was called, with no assertion on the rendered output.
- Asserts markup structure (e.g. the component renders a `div`) with no behavioural content.

**SignalR client-side ACs:** stories that require the UI to update on a received SignalR event are covered by ViewModel unit tests that simulate the event callback directly (calling the handler method that the hub `On<T>` registration would invoke), plus component tests that assert the re-render. A test that only verifies the `On<T>` registration was wired up — not that the rendered output changed — is flagged as low-value. For the canonical test pattern, see the Frontend section of `.claude/skills/tdd-cycle/SKILL.md`.

**Composition-root behaviour:** when a frontend behaviour depends on the DI pipeline, the `HttpClient` `DelegatingHandler` chain, or the Blazor render/navigation lifecycle, the bUnit/ViewModel test alone is not enough — it must exercise the **real composition** per the **Frontend composition-root rule** (Anti-Masking Rule, above). A layout test rendered on a non-`/login` route, or a handler tested in isolation, is a masking test of this class.

### Simulator (`service-delivery-simulator`)

All tests live in `ServiceDelivery.Simulator.Tests`. Unit tests for workers and services use mocked `IBackendApiClient` and `ISignalRClient`. There are no integration tests (the Simulator is integration-tested end-to-end by running it against the real backend). The two-level rule does not apply — unit-level tests only.
