# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is the **central governance repository** for the Service Delivery system. It does not contain application code — that lives in the repos below. This repo owns local dev orchestration, AI skill and agent definitions, and system-level documentation.

## System Context

This system is a fleet dispatch platform — "Uber for service reps." When a requester reports an equipment fault (identified by a Diagnostic Trouble Code), the system finds the nearest qualified service vehicle and dispatches the rep. Dispatchers manage the fleet and handle priority escalations (Bronze / Silver / Gold service tiers). Real-time updates flow over SignalR. For the POC, the simulator operates the seeded rep accounts (`rep1…rep8`) to make job decisions and a position-only `Simulator` account to drive all trucks; a human can log in as any idle rep and take it over from a device (see ADR-0009, "Human Takeover").

**Before working on any cross-cutting concern**, read the architecture docs:
- [`docs/architecture/system-overview.md`](docs/architecture/system-overview.md) — full system description, personas, tech stack, seed data
- [`docs/architecture/state-machines.md`](docs/architecture/state-machines.md) — all rep, request, vehicle, and job offer state machines
- [`docs/architecture/data-flow.md`](docs/architecture/data-flow.md) — end-to-end flows for all scenarios
- [`docs/adr/`](docs/adr/) — all architectural decisions (4-repo structure, SignalR, auth strategy, Haversine distance, simulator design, multi-dealer data model, simulator rep identities / human takeover (ADR-0009))

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

# Build the MAUI frontend (ServiceDelivery.Client.Mobile) and deploy + launch it on an iOS simulator.
# Both boot the device (preferring one already booted), open Simulator.app, then build/deploy/run;
# they block streaming the app console (Ctrl-C to stop). They do NOT start the backend (see start.sh).
./scripts/local/startInPhone.sh    # iPhone 17 Pro
./scripts/local/startInTablet.sh   # iPad mini (A17 Pro)

# Run all backend tests
./scripts/local/test-backend.sh

# Run all simulator tests
./scripts/local/test-simulator.sh

# Run all frontend tests
./scripts/local/test-frontend.sh

# Run the full test suite (backend + frontend + simulator) with a live results table
./scripts/local/test-all.sh

# Bring up the full system locally (backend on HTTP profile + simulator; exports DOTNET_ENVIRONMENT=Local so the simulator loads appsettings.Local.json)
./scripts/local/start.sh

# Drive one service-delivery job end-to-end by API (requires start.sh already running) — the headless integration smoke
./scripts/local/smoke.sh

# Tear down local environment
./scripts/local/stop.sh

# Run a utility script
./scripts/utils/<script-name>.sh
```

`scripts/utils/mark-story-complete.sh` crosses a merged story/bug ID out in `docs/stories/execution-plan.md`. It usually runs unattended — fired by a PostToolUse hook after `gh pr merge` succeeds — but it also accepts an explicit ID (`mark-story-complete.sh SIM-008`) for cases the hook can't catch. **The hook does not fire when a PR is merged from a `/worktree` session** (the worktree is a separate project dir, so central's project-scoped hook is inactive there). `scripts/utils/reconcile-plan.sh` is the backstop: it lists merged PRs across all repos and crosses out every merged story — run it directly, or let `scripts/utils/worktree.sh remove --merged` run it for you during worktree cleanup.

`scripts/utils/run-on-simulator.sh` is the shared helper behind `startInPhone.sh` / `startInTablet.sh` — it takes a simulator device name (e.g. `"iPhone 17 Pro"`), resolves an available device (preferring one already booted), boots it, and builds + deploys + launches the MAUI Mobile app on it. The two `startIn*.sh` scripts are thin wrappers that pass the device name.

All scripts must be runnable from the repo root and must be executable (`chmod +x`).

## Directory Structure

```
.claude/
  skills/       # Claude Code skills — slash-invocable rule sets (one folder per skill, SKILL.md inside)
  agents/       # Claude Code subagents — isolated pipeline stages (one folder per agent, AGENT.md inside)
scripts/
  local/        # Docker Compose files and shell scripts for local dev
  utils/        # Shared helper scripts used across local and CI workflows
docs/
  architecture/ # Architecture diagrams and decision context
  adr/          # Architecture Decision Records (ADRs)
  stories/      # Full user story backlog (backend.md, frontend.md, simulator.md), engineering-quality backlog (quality.md, QUAL-), bug backlog (bug.md), execution plan (execution-plan.md), parallel-tracks.md, and a stories README.md
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

### AI Skills (`.claude/skills/`)

Skills are Claude Code slash commands — each lives in `.claude/skills/<name>/SKILL.md` and is invocable as `/<name>`. Skills load into the current conversation context when invoked. Subagents read skill files directly as required reading at the start of their process.

- One folder per skill: `.claude/skills/<name>/SKILL.md`
- Each SKILL.md must have a `description:` frontmatter field (shown in autocomplete and used for auto-invocation)
- Each SKILL.md must contain: **Purpose**, the rules themselves, and a **Repo Adaptations** section
- Skills are self-contained — they must not depend on other skill files

**Existing skills** (do not duplicate — extend in place):

| Folder | Slash command | Governs |
|--------|--------------|---------|
| `tdd-cycle/` | `/tdd-cycle` | Red-green-refactor discipline, `GivenA_When_Then` naming, Arrange/Act/Assert |
| `clean-architecture/` | `/clean-architecture` | Layer dependency rules and directory structure per repo |
| `test-quality/` | `/test-quality` | Unit vs integration levels, value-add criteria, duplication check |
| `solid-principles/` | `/solid-principles` | All five SOLID principles mapped per layer per repo |
| `ac-coverage/` | `/ac-coverage` | AC → test mapping process, Configuration ACs, SignalR event ACs |
| `master/` | `/master` | Story pipeline orchestrator — invoke as `/master <STORY-ID>` |
| `audit-agents/` | `/audit-agents` | Full audit of all pipeline agents — ratings across 9 dimensions, strengths, weaknesses, inconsistencies, contradictions, improvement backlog |
| `audit-skills/` | `/audit-skills` | Full audit of all pipeline skills — ratings across 8 dimensions, strengths, weaknesses, inconsistencies, contradictions, improvement backlog |
| `validate-ai-system/` | `/validate-ai-system` | Pipeline health check — required sections, resolvable Required Reading paths, intact cross-references in all AGENT.md and SKILL.md files |
| `ship-it/` | `/ship-it` | Branch, commit, push, PR, and merge in one shot — lands out-of-pipeline changes (docs/config/housekeeping); story commits/PRs go through `/master` |
| `worktree/` | `/worktree` | Create/tear down per-story git worktrees under `.worktrees/<ID>` (with a `.claude` symlink so the pipeline resolves there) and open a Terminal.app session per story that runs `/master <ID>` in worktree mode; backed by `scripts/utils/worktree.sh` |

### AI Agents (`.claude/agents/`)

Agents are Claude Code subagents — each runs in an isolated context window with its own tool set. The master skill delegates to them as pipeline stages.

- One folder per agent: `.claude/agents/<name>/AGENT.md`
- Each AGENT.md must have `name:`, `description:`, and `tools:` frontmatter fields
- Each AGENT.md must contain: a persona paragraph (who the agent is, immediately under the `# <Name>` heading — not a `## Persona` header), **Required Reading** (skill file paths to read first), **Inputs**, **Audit Output** (the `.stories/<STORY-ID>/NN-<name>.md` file it writes), **Process** (numbered steps), and **Output Format**
- Agents must write their audit file before returning — it is the contract between pipeline stages

**Existing agents** (do not duplicate — extend in place):

| Folder | Stage | Audit file written |
|--------|-------|--------------------|
| `story-evaluator/` | 1 — Evaluate | `01-evaluation.md` |
| `story-planner/` | 2 — Plan | `02-plan.md` |
| `story-implementor/` | 3 — Implement | `03-implementation.md` |
| `story-ai-reviewer/` | 4 — AI Review | `04-ai-review.md` |
| `story-pr/` | 5 — PR | `05-pr.md` |

### Audit Files (`.stories/`)

During story execution, each agent writes a stage file into `.stories/<STORY-ID>/` in the **working repo** (not this repo). These files are ephemeral working memory — never committed, deleted at the start of each new Master execution.

- `.stories/` is listed in `.gitignore` in all three working repos
- Audit files are numbered by stage: `01-evaluation.md`, `02-plan.md`, etc.
- Each agent reads the previous stage's file before writing its own
- Do not create `.stories/` entries in this repo — they belong in the working repos only

### Scripts (`scripts/`)
- Shell scripts only (`.sh`), written for `bash` or `zsh`
- Each script must be idempotent — safe to run more than once
- `scripts/local/` — orchestration and test runners (Docker Compose, service startup/shutdown, test execution)
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
