---
description: All five SOLID principles mapped per layer for Backend (Domain/Application/Infrastructure/Api), Frontend, and Simulator — violation signals and fixes.
---

# Skill: SOLID Principles

## Purpose

Define how each of the five SOLID principles applies in this specific codebase, layer by layer. Use this skill during planning and AI review to identify violations and propose fixes.

---

## S — Single Responsibility

> One class, one reason to change.

**In Domain:** An entity holds state and enforces domain invariants for one aggregate. It does not send emails, does not log, does not call the database.

**In Application:** A command handler handles one command. A query handler handles one query. If a handler does two distinct things that could change for different reasons, split it.

**In Infrastructure:** A repository implementation persists one aggregate. An external service client calls one external system.

**How to spot a violation:** if you can describe a class with "and" — "it validates the request and sends the SignalR event and updates the database" — it has more than one responsibility.

> **Qualifier:** the "and" smell applies when responsibilities would change for *different reasons*. A domain aggregate that validates state, transitions state, and raises domain events is cohesive — all three change for the same domain reason. Ask: "if business rule A changed, would I also modify this class for an unrelated reason B?" If yes, split. If no, the class is cohesive.

**Fix:** extract each responsibility into its own class with a focused interface.

---

## O — Open / Closed

> Open for extension, closed for modification.

**In Application:** new features get new files under `Features/<FeatureName>/`. Adding a new command means adding a new handler file, not modifying existing ones.

**In Domain:** new business rules for a new entity type do not touch existing entity code.

**How to spot a violation:** a PR that modifies an existing handler to add a new, unrelated capability.

**Fix:** create a new handler for the new capability. If shared logic is needed, extract it to a domain service or a common behaviour, not into the existing handler.

---

## L — Liskov Substitution

> Implementations must fully honour the contracts of their interfaces.

**In Domain/Application:** anything that implements an interface (`IServiceRequestRepository`, `IMatchingService`) must implement every method fully and correctly. A method that throws `NotImplementedException` or silently does nothing violates this principle.

**In Infrastructure:** repository implementations must return accurate results. Returning an empty list when records exist, or skipping persistence, breaks Liskov.

**Exception (scaffolding only):** `NotImplementedException` is acceptable as a temporary stub during active development within a single TDD cycle — it must be resolved before the story's AI Review gate. The single-cycle boundary is defined in `.claude/skills/tdd-cycle/SKILL.md`.

**How to spot a violation:**
- A method body that is `throw new NotImplementedException()` in production code.
- A method that silently no-ops (empty body, always returns `null`) when the interface contract implies a meaningful result.
- An implementation that works for some inputs but throws on valid inputs the interface makes no restriction about.

**Fix:** implement the method fully, or remove the method from the interface if it is not needed.

---

## I — Interface Segregation

> Callers should not depend on methods they do not use.

**In Domain:** repository interfaces are focused per aggregate — `IVehicleRepository` does not contain methods for `ServiceRequest`. If a handler only needs to read vehicles, it should not be forced to depend on an interface that also writes requests.

**In Application:** application service interfaces are narrow per capability. An `IMatchingService` exposes only matching operations. An `IJobOfferService` exposes only offer operations. Never combine unrelated operations into one interface because it is convenient.

**How to spot a violation:** a handler constructor that takes a large interface but only calls one or two of its methods.

**Fix:** split the interface at the method level callers actually use; create adapter interfaces if needed.

---

## D — Dependency Inversion

> Depend on abstractions. Concrete implementations are injected, never instantiated inside business logic.

**In Application:** handlers receive interfaces via constructor injection. They never call `new ConcreteRepository()`, `new HttpClient()`, or `new SignalRConnection()` inside business logic.

**In Domain:** entities do not have constructors that accept concrete infrastructure types.

**In Api:** `Program.cs` is the composition root — the only place where concrete types are *registered* against interfaces. The DI container performs the actual instantiation. Do not manually call `new ConcreteType()` in application code — register the concrete in `Program.cs` and let the container inject it.

> For **which layer** each abstraction and its concrete belong in (the interface in Domain/Application, the implementation in Infrastructure, the registration at the Api composition root), see `.claude/skills/clean-architecture/SKILL.md` — it governs layer placement; this skill governs the dependency direction between them.

**How to spot a violation:**
- `new` on any infrastructure type (EF `DbContext`, `HttpClient`, `SignalRHubContext`) inside a Domain or Application class.
- A handler that directly instantiates a repository.

**Fix:** add a constructor parameter for the interface; register the concrete type in `Program.cs`.

---

## Quick Reference Table

| Principle | Violation signal | Fix |
|-----------|-----------------|-----|
| S | Class described with "and"; handler does two things | Split into focused classes |
| O | Existing handler modified to add unrelated capability | New file under `Features/<Name>/` |
| L | `NotImplementedException` or silent no-op in production | Fully implement the method |
| I | Handler depends on a large interface, uses 1–2 methods | Split interface to what the caller actually needs |
| D | `new ConcreteType()` inside Domain or Application | Inject the interface; register the concrete in `Program.cs` (container instantiates, not you) |

---

## Value Objects and Domain Events

**Value objects (SRP):** Value objects are immutable by design — their state cannot change after construction. This satisfies SRP structurally: a value object has one reason to change (the definition of the value it represents). No additional SRP analysis is required for well-formed value objects.

**Domain events (ISP):** Domain events should have a single clear trigger and carry only the data the subscriber needs. Do not attach the entire aggregate to the event payload. If two subscribers need different fields, consider two separate events rather than one event with a superset payload.

---

## Repo Adaptations

SOLID applies in all repos. The vocabulary differs per repo — map the principles to the actual constructs used.

### Frontend (`service-delivery-frontend`)

| Principle | Frontend application |
|-----------|---------------------|
| S | A Razor component renders one thing. If it also fetches data and transforms it, extract the data access to a ViewModel and the transformation to Core logic. |
| O | New features → new files under `UI/Features/<FeatureName>/`. Never add new routes or UI logic to an existing unrelated feature folder. |
| L | Every service implementation in a host's `Services/` folder must fully honour its `Core/Interfaces/` contract. No silent no-ops. If a platform cannot support a feature, return a typed "unsupported" result — do not silently return null. |
| I | Interfaces in `Core/Interfaces/` are narrow per capability (e.g. `IAuthService`, `IVehicleService`). A component that only reads vehicles should not depend on an interface that also creates and deletes them. |
| D | Components depend on interfaces from Core, never on concrete implementations from host `Services/` folders. Register concretes in the host bootstrapper: Desktop and Mobile use `MauiProgram.cs`; Web uses `Program.cs`. |

### Simulator (`service-delivery-simulator`)

| Principle | Simulator application |
|-----------|----------------------|
| S | `VehicleWorker` moves vehicles and POSTs positions — one responsibility. `BackendApiClient` calls the HTTP API — one responsibility. `SignalRClient` manages the hub — one responsibility. Never combine two of these into one class. |
| O | Add new simulator behaviours (e.g. smarter routing) by extending `VehicleWorker` or creating a new helper — never by modifying `BackendApiClient` or `SignalRClient`. |
| L | `BackendApiClient` and `SignalRClient` must fully implement `IBackendApiClient` and `ISignalRClient`. No `NotImplementedException` in production. |
| I | `IBackendApiClient` exposes only operations `VehicleWorker` needs (auth, position POST, offer accept/decline). `ISignalRClient` exposes only connection management. Keep them separate. |
| D | `VehicleWorker` depends on `IBackendApiClient` and `ISignalRClient`. Register concretes in `Program.cs`. Never instantiate `BackendApiClient` or `SignalRClient` directly inside a worker. |
