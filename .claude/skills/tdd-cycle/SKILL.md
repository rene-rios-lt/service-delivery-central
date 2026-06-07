---
description: Red-green-refactor TDD discipline, GivenA_When_Then test naming, and Arrange/Act/Assert structure — applies to all repos in this system.
---

# Skill: TDD Cycle

## Purpose

Define the red-green-refactor discipline precisely as it applies in this codebase. Every agent that writes production code must follow this cycle without exception.

---

## The Cycle

### Red — Write a failing test

1. Pick **one** AC bullet. Write **one** test method that would fail if that behaviour does not exist.
2. Run the test suite. The new test must fail.
3. Confirm the failure is an **assertion failure** — not a compile error, not a missing dependency. A compile error means the test is not yet testing anything; fix the structure first.
4. Do not write another test until this one is green.

### Green — Write the minimum production code

1. Write the smallest amount of production code that makes the failing test pass.
2. No more. If the test passes with a hardcoded return value, that is fine — the next test will force the real implementation.
3. Do not add code that is not driven by the currently failing test.
4. Run the full test suite. All previously passing tests must still pass.

### Refactor — Clean up without breaking tests

1. Rename variables and methods for clarity.
2. Extract private helpers if a method is doing more than one thing.
3. Remove duplication introduced during the Green phase.
4. Run the full test suite after every change. All tests must stay green throughout.
5. Do not change behaviour during refactor — only structure.

Repeat for the next AC bullet.

---

## Test Method Naming

All test methods must follow `GivenA_When_Then`:

```
GivenAServiceRequest_WhenSubmitted_ThenStatusIsPending
GivenAJobOffer_WhenDeclined_ThenRepIsExcludedFromFutureMatching
GivenARepOnSite_WhenRedirectAttempted_ThenReturns422
```

- `GivenA` — the starting state or precondition
- `When` — the action or event
- `Then` — the expected outcome

---

## Test Structure

Every test must follow Arrange / Act / Assert with each section clearly separated by a blank line:

```csharp
[Fact]
public async Task GivenAValidCredential_WhenLoginCalled_ThenJwtIsReturned()
{
    // Arrange
    var command = new LoginCommand { Username = "rep1", Password = "pass" };

    // Act
    var result = await _handler.Handle(command, CancellationToken.None);

    // Assert
    result.Token.Should().NotBeNullOrEmpty();
}
```

> **Note on comments:** the `// Arrange`, `// Act`, `// Assert` section-separator comments are an intentional exception to the system-wide no-comments rule. They mark test structure, not implementation detail. They are required in all test methods.

---

## Parameterized Tests

When multiple AC bullets differ only in input values (e.g. Bronze / Silver / Gold tier, or multiple HTTP error codes), use `[Theory]` + `[InlineData]` to avoid duplicating test structure while keeping each case explicit:

```csharp
[Theory]
[InlineData("Bronze", 1)]
[InlineData("Silver", 2)]
[InlineData("Gold", 3)]
public async Task GivenATierRequest_WhenSubmitted_ThenTierLevelIsCorrect(string tier, int expectedLevel)
{
    // Arrange
    var command = new SubmitRequestCommand { Tier = tier };

    // Act
    var result = await _handler.Handle(command, CancellationToken.None);

    // Assert
    result.TierLevel.Should().Be(expectedLevel);
}
```

Use this pattern only when the logic path is identical and only the data varies. If behaviour differs per case, write separate named test methods.

---

## Integration Test Timing

For stories that require integration tests (any story touching the Application or Infrastructure layer), the cycle runs at two levels:

1. Complete the full Red-Green-Refactor cycle at the unit level first — all unit tests passing.
2. Then add the integration test Red step: write a failing integration test that verifies the unit-tested behaviour against a real dependency (database, real HTTP server, real hub).
3. Write the minimum production code (if any — often the unit-level Green phase already satisfies it) to make the integration test pass.
4. Refactor. Run both suites. All tests must stay green.

The unit cycle always runs first. An integration test should never be the first test written for a behaviour.

---

## Hard Rules

- Never write production code for a behaviour that has no failing test first.
- Never write two tests before going green on the first.
- Never let a test pass for the wrong reason (e.g. swallowed exception, wrong assertion).
- Never skip the refactor phase — accumulating debt here breaks the next Red phase. "Never skip" means never skip the *inspection*: if the code is already clean after Green, inspect it, confirm no change is needed, and record that confirmation. A cycle that produces no code change is valid when the code is already clean.
- A feature is not done until every AC bullet has a passing test — for the mapping table that operationalises this rule at review time, see `.claude/skills/ac-coverage/SKILL.md`.

---

## Repo Adaptations

The TDD discipline and naming conventions are identical across all repos. Only the test runner command and testing library differ.

### Backend (`service-delivery-backend`)

```bash
dotnet test                                      # all projects
dotnet test tests/ServiceDelivery.Api.Tests      # integration only
dotnet test tests/ServiceDelivery.Application.Tests  # unit only
```

Testing libraries: xUnit, Moq, FluentAssertions, WebApplicationFactory.

### Frontend (`service-delivery-frontend`)

```bash
dotnet test tests/ServiceDelivery.Client.Tests
```

Testing libraries: xUnit, bUnit (Razor component testing). `Render<TComponent>()` is the bUnit entry point. Arrange/Act/Assert structure applies — Act is typically `cut.Find("button").Click()` or a service method call; Assert is `cut.Find("p").MarkupMatches(...)` or a ViewModel property assertion.

### Simulator (`service-delivery-simulator`)

```bash
dotnet test ServiceDelivery.Simulator.slnx
```

Testing libraries: xUnit, Moq. Workers and services are pure C# — standard xUnit applies with no special framework.
