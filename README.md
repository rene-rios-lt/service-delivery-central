# Service Delivery Central

Central repository for the Service Delivery system. Owns local dev orchestration, AI skill and agent definitions, and system-level documentation.

## Repositories

| Repo | Purpose |
|------|---------|
| [service-delivery-central](https://github.com/rene-rios-lt/service-delivery-central) | This repo — scripts, AI skills/agents, architecture docs |
| [service-delivery-frontend](https://github.com/rene-rios-lt/service-delivery-frontend) | .NET MAUI Blazor Hybrid — Desktop, Mobile, Web |
| [service-delivery-backend](https://github.com/rene-rios-lt/service-delivery-backend) | .NET 10 Clean Architecture API + Azure (Terraform) |
| [service-delivery-simulator](https://github.com/rene-rios-lt/service-delivery-simulator) | .NET 10 Worker Service — POC vehicle data simulator |

## AI Agent System

The `ai/` directory contains an agent system for implementing user stories with enforced TDD, SOLID, and Clean Architecture discipline. A single Master agent orchestrates the full pipeline from story evaluation through PR creation.

### Usage

Invoke the Master agent with a story ID:

```
/master BE-010
/master SIM-003
/master FE-007
```

The Master runs the full pipeline and pauses at two human checkpoints:

```
Master → Evaluator   → READY or BLOCKED
       → Planner     → implementation plan
       → CHECKPOINT #1: approve plan
       → Implementor → TDD cycle per AC bullet → passing tests
       → AI Reviewer → 8-dimension quality gate
       → CHECKPOINT #2: approve or send back
       → Reviewer    → PR description package
       → PR Agent    → branch, commit, push, PR created
```

### Agents

| Agent | File | Role |
|-------|------|------|
| Master | `ai/agents/master.md` | Orchestrator — single entry point, enforces both checkpoints |
| Story Evaluator | `ai/agents/story-evaluator.md` | Gatekeeper — checks upstream dependencies and AC testability before a line is written |
| Story Planner | `ai/agents/story-planner.md` | Senior engineer — produces the file list, interface definitions, and named test scenarios per AC bullet |
| Story Implementor | `ai/agents/story-implementor.md` | TDD craftsperson — red-green-refactor, one AC bullet at a time |
| Story AI Reviewer | `ai/agents/story-ai-reviewer.md` | Impartial reviewer — 8 checks: tests pass, AC coverage, test levels, value, duplication, SOLID, Clean Architecture, dead code |
| Story Reviewer | `ai/agents/story-reviewer.md` | Communicator — produces the PR description with AC→test table and checklist |
| Story PR | `ai/agents/story-pr.md` | Executor — branch, commit, push, PR creation |

### Skills

Skills are atomic, self-contained rule sets that agents apply. They are not invoked directly.

| Skill | File | Governs |
|-------|------|---------|
| TDD Cycle | `ai/skills/tdd-cycle.md` | Red-green-refactor discipline, test naming (`GivenA_When_Then`), Arrange/Act/Assert |
| Clean Architecture | `ai/skills/clean-architecture.md` | Layer dependency rules, directory structure, violation patterns — Backend and Frontend |
| Test Quality | `ai/skills/test-quality.md` | Unit vs integration levels, value-add criteria, duplication check — all three repos |
| SOLID Principles | `ai/skills/solid-principles.md` | All five principles mapped per layer — Backend, Frontend, and Simulator |
| AC Coverage | `ai/skills/ac-coverage.md` | AC → test mapping process, Configuration AC handling, SignalR event testing |

### Audit Files

Each agent writes a stage file to `.stories/<STORY-ID>/` in the working repo (gitignored, deleted at the start of each new execution). These files are session-scoped working memory — they are never committed.

```
.stories/BE-010/
  01-evaluation.md
  02-plan.md
  03-ai-review.md
  04-review-package.md
  05-pr.md
```

---

## Local Development

### Launch the web client

From the repo root:

```bash
./scripts/local/launchWebPage.sh
```

This will kill any existing instance on port 5023, start the Blazor WASM web app, and open it in your browser at `http://localhost:5023`.
