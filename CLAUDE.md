# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is the **central governance repository** for the Service Delivery system. It does not contain application code — that lives in the repos below. This repo owns local dev orchestration, AI skill and agent definitions, and system-level documentation.

## Repositories

| Repo | URL | Purpose |
|------|-----|---------|
| Central (this repo) | [service-delivery-central](https://github.com/rene-rios-lt/service-delivery-central) | Local dev scripts, AI skills/agents, architecture docs |
| Frontend | [service-delivery-frontend](https://github.com/rene-rios-lt/service-delivery-frontend) | .NET MAUI Blazor Hybrid — Desktop, Mobile, Web |
| Backend | [service-deliver-backend](https://github.com/rene-rios-lt/service-deliver-backend) | .NET 10 Clean Architecture API + Azure (Terraform) |

## System Architecture

```
Frontend (Core / UI / Desktop / Mobile / Web)
         ↕ HTTP
Backend  (Domain / Application / Infrastructure / Api)
         ↕ Terraform
Azure Infrastructure
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
- One file per skill, named in `kebab-case.md`
- Each skill file defines: purpose, trigger conditions, inputs, outputs, and constraints
- Skills are self-contained — they must not depend on other skill files

### AI Agents (`ai/agents/`)
- One file per agent, named in `kebab-case.md`
- Each agent composes one or more skills from `ai/skills/` by reference
- Agent files define: scope, persona, referenced skills, and behavioral guardrails

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
- Diagrams should be stored as source files (e.g. `.drawio`, `.puml`) alongside exported images
- Each diagram should have a brief accompanying `.md` file explaining what it shows and when it was last updated
