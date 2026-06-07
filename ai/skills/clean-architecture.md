# Skill: Clean Architecture

## Purpose

Encode the exact dependency rules for the backend's Clean Architecture layers. Use this skill to determine where new code belongs and to identify layer boundary violations.

---

## Layer Map

```
Domain  ←  Application  ←  Infrastructure
                ↑
               Api
```

Dependencies flow inward only. A layer may reference layers closer to the centre, never further out.

| Layer | Project | May reference |
|-------|---------|--------------|
| Domain | `ServiceDelivery.Domain` | Nothing outside .NET BCL |
| Application | `ServiceDelivery.Application` | Domain only |
| Infrastructure | `ServiceDelivery.Infrastructure` | Domain + Application |
| Api | `ServiceDelivery.Api` | Application + Infrastructure (composition root only) |

---

## Domain Layer

**What belongs here:**
- Entities and aggregates (e.g. `ServiceRequest`, `Vehicle`, `Rep`)
- Value objects (e.g. `GpsCoordinate`, `ServiceTier`)
- Domain events (e.g. `JobOfferExpiredEvent`)
- Repository interfaces (e.g. `IServiceRequestRepository`)
- Domain exceptions

**Hard rules:**
- No EF Core, no HTTP, no SignalR, no external package references.
- No `using Microsoft.*` except BCL types.
- Repository interfaces return domain types only — never DTOs.

---

## Application Layer

**What belongs here:**
- CQRS commands and queries: `Features/<FeatureName>/Commands/` and `Features/<FeatureName>/Queries/`
- Command and query handlers
- Application service interfaces: `Common/Interfaces/` (e.g. `IMatchingService`, `IJobOfferService`)
- Pipeline behaviours: `Common/Behaviors/` (e.g. validation, logging)
- DTOs / response models used by handlers

**Hard rules:**
- References Domain only — never Infrastructure or Api.
- Handlers call repository interfaces from Domain — never concrete implementations.
- Business logic lives here (or in Domain), not in Infrastructure or Api.

---

## Infrastructure Layer

**What belongs here:**
- EF Core `DbContext` and entity configurations: `Persistence/`
- Repository implementations: `Repositories/`
- External service clients (HTTP, SignalR hub sends): `Services/`
- Migrations

**Hard rules:**
- Implements interfaces defined in Domain and Application — never defines its own contracts.
- Never referenced by Domain or Application (enforced by `.csproj` project references).

---

## Api Layer

**What belongs here:**
- ASP.NET Core controllers or minimal API endpoints
- `Program.cs` — the composition root (DI wiring only)
- Middleware registrations
- Request/response model mapping at the boundary

**Hard rules:**
- No business logic. Controllers call Application handlers — nothing else.
- DI wiring is the only reason Infrastructure is referenced here.
- No direct repository access.

---

## Violation Patterns to Flag

| Pattern | Violation | Fix |
|---------|-----------|-----|
| `DbContext` injected into a controller | Api → Infrastructure boundary | Move query to an Application handler |
| Business rule in a controller action | Business logic in Api | Extract to a command handler in Application |
| `new ConcreteRepository()` inside a handler | DI violation (D in SOLID) | Inject the interface; register the concrete at the composition root |
| Repository interface defined in Infrastructure | Wrong layer for abstraction | Move interface to Domain |
| Infrastructure package imported in Application | Application → Infrastructure boundary | Define a thin interface in Application; implement in Infrastructure |

---

## Directory Structure Reference

```
src/
  ServiceDelivery.Domain/
    Entities/
    ValueObjects/
    Events/
    Interfaces/          ← repository interfaces live here
  ServiceDelivery.Application/
    Features/
      Auth/
        Commands/LoginCommand.cs
        Commands/LoginCommandHandler.cs
      Vehicles/
        Queries/GetFleetQuery.cs
        Queries/GetFleetQueryHandler.cs
    Common/
      Interfaces/        ← application service interfaces
      Behaviors/
  ServiceDelivery.Infrastructure/
    Persistence/
    Repositories/
    Services/
  ServiceDelivery.Api/
    Controllers/
    Program.cs
tests/
  ServiceDelivery.Domain.Tests/
  ServiceDelivery.Application.Tests/
  ServiceDelivery.Infrastructure.Tests/
  ServiceDelivery.Api.Tests/
```
