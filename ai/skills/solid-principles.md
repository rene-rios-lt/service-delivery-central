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

**Exception (scaffolding only):** `NotImplementedException` is acceptable as a temporary stub during active development within a single TDD cycle — it must be resolved before the story's AI Review gate.

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

**In Api:** `Program.cs` is the composition root — the only place where concrete classes are registered against interfaces. This is the one place where `new` on infrastructure types is permitted.

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
| D | `new ConcreteType()` inside Domain or Application | Inject the interface; register in `Program.cs` |
