# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is the **central governance repository** for the Service Delivery system. It does not contain application code — that lives in the repos below. This repo owns local dev orchestration, AI skill and agent definitions, and system-level documentation.

## System Context

This system is a fleet dispatch platform — "Uber for service reps." When a requester reports an equipment fault (identified by a Diagnostic Trouble Code), the system finds the nearest qualified service vehicle and dispatches the rep. Dispatchers manage the fleet and handle priority escalations (Bronze / Silver / Gold service tiers). Real-time updates flow over SignalR.

**Before working on any cross-cutting concern**, read the architecture docs:
- [`docs/architecture/system-overview.md`](docs/architecture/system-overview.md) — full system description, personas, tech stack, seed data
- [`docs/architecture/state-machines.md`](docs/architecture/state-machines.md) — all rep, request, vehicle, and job offer state machines
- [`docs/architecture/data-flow.md`](docs/architecture/data-flow.md) — end-to-end flows for all scenarios
- [`docs/adr/`](docs/adr/) — all architectural decisions (4-repo structure, SignalR, auth strategy, Haversine distance, simulator design, multi-dealer data model)

## Repositories

| Repo | URL | Purpose |
|------|-----|---------|
| Central (this repo) | [service-delivery-central](https://github.com/rene-rios-lt/service-delivery-central) | Local dev scripts, AI skills/agents, architecture docs |
| Frontend | [service-delivery-frontend](https://github.com/rene-rios-lt/service-delivery-frontend) | .NET MAUI Blazor Hybrid — Desktop, Mobile, Web |
| Backend | [service-delivery-backend](https://github.com/rene-rios-lt/service-delivery-backend) | .NET 10 Clean Architecture API + Azure (Terraform) |
| Simulator | [service-delivery-simulator](https://github.com/rene-rios-lt/service-delivery-simulator) | .NET 10 Worker Service — POC vehicle data simulator |

## System Architecture

```
Simulator ──REST──► Backend (Domain / Application / Infrastructure / Api)
                        │
                   REST + SignalR
                        │
          ┌─────────────┴─────────────┐
       Desktop                  Web / Mobile
  (MAUI Blazor Hybrid)        (Blazor WASM / MAUI)

Azure infrastructure provisioned via Terraform (not active for POC local dev)
```

- **Frontend** — Five-project MAUI Blazor Hybrid solution. `Core` holds models and interfaces; `UI` holds all Razor components and pages; `Desktop`, `Mobile`, and `Web` are thin platform hosts.
- **Backend** — Clean Architecture .NET 10 API. `Domain` → `Application` → `Infrastructure` → `Api`. Azure infrastructure provisioned via Terraform in `terraform/`.
- **Local Dev** — Docker Compose in `scripts/local/` spins up the backend and its dependencies locally. The frontend runs natively and points at the local backend.

## Commands

```bash
# Launch the web client (kills any existing instance, starts the Blazor WASM app, opens browser)
./scripts/local/launchWebPage.sh

# Bring up the full system locally (once scripts are populated)
./scripts/local/start.sh

# Tear down local environment
./scripts/local/stop.sh

# Run a utility script
./scripts/utils/<script-name>.sh
```

All scripts must be runnable from the repo root and must be executable (`chmod +x`).

## Directory Structure

```
ai/
  skills/       # Reusable AI skill definitions (markdown)
  agents/       # AI agent configurations that compose skills
scripts/
  local/        # Docker Compose files and shell scripts for local dev
  utils/        # Shared helper scripts used across local and CI workflows
docs/
  architecture/ # Architecture diagrams and decision context
  adr/          # Architecture Decision Records (ADRs)
  stories/      # Full user story backlog (backend.md, frontend.md, simulator.md) and execution plan
```

## Engineering Standards

All code across the Service Delivery system follows two non-negotiable standards: Test-Driven Development and SOLID design principles. These apply in both the frontend and backend repos. This section states the system-wide intent; each repo's own CLAUDE.md contains repo-specific rules.

### Test-Driven Development

TDD is the default working mode — not optional, not aspirational.

```
Red   → Write a failing test that describes the behaviour you want
Green → Write the minimum production code to make it pass
Refactor → Clean up without breaking the tests
```

**Rules that apply across all repos:**
- No production code without a failing test first
- Tests describe *behaviour*, not implementation — if a test breaks when you rename a private method, it is testing the wrong thing
- A feature is not done until it has tests. A PR without tests for new behaviour will not be merged
- Test names must be readable as plain English specifications (`GivenARequest_WhenSubmitted_ThenConfirmationIsSent`)
- Every test follows Arrange / Act / Assert with each section clearly separated

### SOLID Design Principles

All production code must follow SOLID. The project structures in each repo are designed to make violations obvious:

- **S — Single Responsibility** — One class, one reason to change. If you can describe a class with "and", split it.
- **O — Open/Closed** — Add behaviour by creating new files, not by modifying existing ones.
- **L — Liskov Substitution** — Implementations must fully honour the contracts of their interfaces — no silent no-ops or partial implementations.
- **I — Interface Segregation** — Prefer many small, focused interfaces over one large one. Callers should not depend on methods they do not use.
- **D — Dependency Inversion** — Depend on abstractions. Concrete implementations are registered at the composition root and injected — never instantiated inside business logic.

## Conventions

### AI Skills (`ai/skills/`)

Skills are atomic rule sets. They are never invoked directly — agents reference them.

- One file per skill, named in `kebab-case.md`
- Each skill file must contain: **Purpose**, the rules themselves, and a **Repo Adaptations** section that maps the rules to Backend, Frontend, and Simulator where the behaviour differs
- Skills are self-contained — they must not depend on other skill files

**Existing skills** (do not duplicate — extend in place):

| File | Governs |
|------|---------|
| `tdd-cycle.md` | Red-green-refactor discipline, `GivenA_When_Then` naming, Arrange/Act/Assert |
| `clean-architecture.md` | Layer dependency rules and directory structure per repo |
| `test-quality.md` | Unit vs integration levels, value-add criteria, duplication check |
| `solid-principles.md` | All five SOLID principles mapped per layer per repo |
| `ac-coverage.md` | AC → test mapping process, Configuration ACs, SignalR event ACs |

### AI Agents (`ai/agents/`)

Agents are the executable units. Each is invoked by the Master agent as a pipeline stage.

- One file per agent, named in `kebab-case.md`
- Each agent file must contain: **Persona**, **Skills Used**, **Inputs**, **Audit Output** (the `.stories/<STORY-ID>/NN-<name>.md` file it writes), **Process** (numbered steps), **Output** or **Output Format**, and **Guardrails**
- Agents must write their audit file before returning — it is the contract between pipeline stages

**Existing agents** (do not duplicate — extend in place):

| File | Stage | Audit file written |
|------|-------|--------------------|
| `master.md` | Orchestrator | none — coordinates the pipeline |
| `story-evaluator.md` | 1 — Evaluate | `01-evaluation.md` |
| `story-planner.md` | 2 — Plan | `02-plan.md` |
| `story-implementor.md` | 3 — Implement | none — writes production code and tests |
| `story-ai-reviewer.md` | 4 — AI Review | `03-ai-review.md` |
| `story-reviewer.md` | 5 — Review | `04-review-package.md` |
| `story-pr.md` | 6 — PR | `05-pr.md` |

### Audit Files (`.stories/`)

During story execution, each agent writes a stage file into `.stories/<STORY-ID>/` in the **working repo** (not this repo). These files are ephemeral working memory — never committed, deleted at the start of each new Master execution.

- `.stories/` is listed in `.gitignore` in all three working repos
- Audit files are numbered by stage: `01-evaluation.md`, `02-plan.md`, etc.
- Each agent reads the previous stage's file before writing its own
- Do not create `.stories/` entries in this repo — they belong in the working repos only

### Scripts (`scripts/`)
- Shell scripts only (`.sh`), written for `bash` or `zsh`
- Each script must be idempotent — safe to run more than once
- `scripts/local/` — orchestration only (Docker Compose, service startup/shutdown)
- `scripts/utils/` — reusable helpers (e.g. env setup, token generation) sourced by other scripts

### Architecture Decision Records (`docs/adr/`)
- Named `NNNN-short-title.md` (e.g. `0001-use-clean-architecture.md`)
- Follow the standard ADR format: Title, Status, Context, Decision, Consequences
- Once a decision is `Accepted`, it is never deleted — superseded ADRs are updated to `Superseded` and linked to their replacement

### Architecture Docs (`docs/architecture/`)
- All diagrams **must** be authored as **PlantUML (`.puml`)** source files in `docs/architecture/`
- The `.puml` file is the authoritative source — markdown files may include ASCII art as a quick reference, but the `.puml` is what gets maintained
- File naming: match the companion `.md` (e.g. `state-machines.md` → `state-machines.puml`)
- When adding or changing a diagram: (1) create or update the `.puml` file, (2) reference it in the `.md` with a link or note
- A PR that adds a new diagram to a `.md` without a corresponding `.puml` source will not be merged — enforced via PR checklist
