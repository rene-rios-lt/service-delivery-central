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
- Slower — acceptable, but not needlessly bloated.
- Live in `ServiceDelivery.Infrastructure.Tests` and `ServiceDelivery.Api.Tests`.

**What they verify:** EF Core queries produce correct results, endpoints return correct status codes, SignalR events are sent to the right groups.

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

- Happy-path only with no edge case coverage: if the story's AC includes a `409`, `400`, or `422` scenario, a test that only covers the success path is incomplete.

**High-value tests (look for these):**

- Assert on the state of the system after the action (entity fields changed, status transitioned).
- Assert on the response body and status code together.
- Cover the failure paths and boundary conditions called out in the AC.
- Would fail if the business rule they cover were accidentally removed.

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

## Checklist for AI Review

For each test file, verify:

- [ ] Both unit and integration tests present (if Application or Infrastructure layer touched — see Repo Adaptations below for the equivalent check per repo)
- [ ] Every test method asserts on state or output, not only on mock interactions
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

### Simulator (`service-delivery-simulator`)

All tests live in `ServiceDelivery.Simulator.Tests`. Unit tests for workers and services use mocked `IBackendApiClient` and `ISignalRClient`. There are no integration tests (the Simulator is integration-tested end-to-end by running it against the real backend). The two-level rule does not apply — unit-level tests only.
