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

#### SignalR Integration Tests

SignalR integration tests live in `Api.Tests`. A unit test that only verifies a mock hub method was called is `Partial`, not `Covered` — the test must assert the event payload was received by a connected test client. See `.claude/skills/ac-coverage/SKILL.md`, SignalR Event ACs.

Use `TaskCompletionSource<T>` to capture the event without an arbitrary delay:

```csharp
[Fact]
public async Task GivenAServiceRequest_WhenSubmitted_ThenDispatchersReceiveServiceRequestPendingEvent()
{
    // Arrange
    await using var app = new CustomWebApplicationFactory();
    var client = app.CreateClient();

    var tcs = new TaskCompletionSource<ServiceRequestPendingPayload>();
    var connection = new HubConnectionBuilder()
        .WithUrl($"{client.BaseAddress}hubs/dispatch", opts =>
            opts.HttpMessageHandlerFactory = _ => app.Server.CreateHandler())
        .Build();
    connection.On<ServiceRequestPendingPayload>("ServiceRequestPending", tcs.SetResult);
    await connection.StartAsync();

    // Act
    await client.PostAsJsonAsync("/service-requests", new SubmitRequestDto { /* ... */ });

    // Assert
    var payload = await tcs.Task.WaitAsync(TimeSpan.FromSeconds(5));
    payload.RequestId.Should().NotBeEmpty();
    payload.Tier.Should().Be(ServiceTier.Gold);
    await connection.StopAsync();
}
```

- `CustomWebApplicationFactory` inherits `WebApplicationFactory<Program>` and seeds required test data.
- `opts.HttpMessageHandlerFactory = _ => app.Server.CreateHandler()` routes the hub connection through the in-process test server — no real network.
- `WaitAsync(TimeSpan.FromSeconds(5))` bounds the test; if the event is never sent, the test fails with `TimeoutException` rather than hanging.
- Assert on the event **payload fields**, not just that the method was called.

---

### Frontend (`service-delivery-frontend`)

```bash
dotnet test tests/ServiceDelivery.Client.Tests
```

Testing libraries: xUnit, bUnit, Moq.

**Cycle order:** complete the ViewModel unit cycle first (pure C# — no bUnit needed), then add the component test Red step. Never write a component test before the ViewModel it depends on is green.

**ViewModel unit test** — standard xUnit, no rendering:

```csharp
[Fact]
public async Task GivenARepAssignedPayload_WhenHandled_ThenViewModelStatusUpdatesToEnRoute()
{
    // Arrange
    var vm = new ServiceRequestViewModel(Mock.Of<IDispatchHubService>());

    // Act
    await vm.HandleRepAssignedAsync(new RepAssignedPayload { RequestId = Guid.NewGuid() });

    // Assert
    vm.Status.Should().Be("En Route");
}
```

**Component test** — bUnit (v2) renders the Razor component in an isolated context. The test class **inherits `BunitContext`**, so `Render<T>()` and `Services` are called directly (bUnit v2 renamed v1's `TestContext` to `BunitContext`):

```csharp
public class ServiceRequestCardTests : BunitContext
{
    [Fact]
    public void GivenAViewModelWithStatusEnRoute_WhenRendered_ThenStatusChipShowsEnRoute()
    {
        // Arrange
        Services.AddSingleton(Mock.Of<IDispatchHubService>());
        var vm = new ServiceRequestViewModel(...) { Status = "En Route" };

        // Act
        var cut = Render<ServiceRequestCard>(p => p.Add(c => c.ViewModel, vm));

        // Assert
        cut.Find("[data-testid='status-chip']").TextContent.Should().Be("En Route");
    }
}
```

**SignalR client-side ACs:** when a story requires a component to update on a received SignalR event, test via the ViewModel — call the ViewModel's event handler directly (simulating the hub callback), assert the ViewModel property changed, then assert the component re-renders. Do not spin up a real hub connection inside a component test.

**MAUI lifecycle:** host-specific lifecycle (`OnAppearing`, `OnDisappearing`) lives in the thin host projects and is not directly tested. Keep lifecycle handlers to a single line delegating to a ViewModel method — the ViewModel method is what gets tested.

### Simulator (`service-delivery-simulator`)

```bash
dotnet test ServiceDelivery.Simulator.slnx
```

Testing libraries: xUnit, Moq. Workers and services are pure C# — standard xUnit applies with no special framework.
