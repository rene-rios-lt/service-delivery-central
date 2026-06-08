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

Skills and agents in `.claude/` implement user stories with enforced TDD, SOLID, and Clean Architecture discipline. The `/master` skill orchestrates the full pipeline from story evaluation through PR creation.

### Usage

Invoke the Master skill with a story ID:

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
       → AI Reviewer → 9-check quality gate
       → CHECKPOINT #2: approve or send back
       → PR Agent    → compose description, stage, commit, push, PR created
```

### Agents

| Agent | Folder | Role |
|-------|--------|------|
| Story Evaluator | `.claude/agents/story-evaluator/` | Gatekeeper — checks upstream dependencies and AC testability before a line is written |
| Story Planner | `.claude/agents/story-planner/` | Senior engineer — produces the file list, interface definitions, and named test scenarios per AC bullet |
| Story Implementor | `.claude/agents/story-implementor/` | TDD craftsperson — red-green-refactor, one AC bullet at a time |
| Story AI Reviewer | `.claude/agents/story-ai-reviewer/` | Impartial reviewer — 9 checks: tests pass, AC coverage, test levels, value, duplication, SOLID, Clean Architecture, dead code, hallucination guard |
| Story PR | `.claude/agents/story-pr/` | Executor — composes PR description from AI review output, then stages, commits, pushes, and creates the PR |

### Skills

Skills are Claude Code slash commands invocable as `/<name>`. Agents read the relevant skill files at the start of each pipeline stage.

| Skill | Slash command | Governs |
|-------|--------------|---------|
| TDD Cycle | `/tdd-cycle` | Red-green-refactor discipline, test naming (`GivenA_When_Then`), Arrange/Act/Assert |
| Clean Architecture | `/clean-architecture` | Layer dependency rules, directory structure, violation patterns — Backend and Frontend |
| Test Quality | `/test-quality` | Unit vs integration levels, value-add criteria, duplication check — all three repos |
| SOLID Principles | `/solid-principles` | All five principles mapped per layer — Backend, Frontend, and Simulator |
| AC Coverage | `/ac-coverage` | AC → test mapping process, Configuration AC handling, SignalR event testing |
| Audit Agents | `/audit-agents` | Full audit of all pipeline agents — ratings across 9 dimensions, improvement backlog |
| Audit Skills | `/audit-skills` | Full audit of all pipeline skills — ratings across 8 dimensions, improvement backlog |
| Validate AI System | `/validate-ai-system` | Pipeline health check — required sections, Required Reading paths, cross-references in all AGENT.md and SKILL.md files |

### Audit Files

Each agent writes a stage file to `.stories/<STORY-ID>/` in the working repo (gitignored, deleted at the start of each new execution). These files are session-scoped working memory — they are never committed.

```
.stories/BE-010/
  01-evaluation.md
  02-plan.md
  03-ai-review.md
  04-pr.md
```

---

## Local Development

### Launch the web client

From the repo root:

```bash
./scripts/local/launchWebPage.sh
```

This will kill any existing instance on port 5023, start the Blazor WASM web app, and open it in your browser at `http://localhost:5023`.
