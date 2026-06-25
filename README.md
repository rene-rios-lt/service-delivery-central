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
| Master | `/master` | Story pipeline orchestrator — invoke as `/master <STORY-ID>` to run a story end-to-end |
| Audit Agents | `/audit-agents` | Full audit of all pipeline agents — ratings across 9 dimensions, improvement backlog |
| Audit Skills | `/audit-skills` | Full audit of all pipeline skills — ratings across 8 dimensions, improvement backlog |
| Validate AI System | `/validate-ai-system` | Pipeline health check — required sections, Required Reading paths, cross-references in all AGENT.md and SKILL.md files |
| Ship It | `/ship-it` | Branch, commit, push, PR, and merge in one shot |

### Audit Files

Each agent writes a stage file to `.stories/<STORY-ID>/` in the working repo (gitignored, deleted at the start of each new execution). These files are session-scoped working memory — they are never committed.

```
.stories/BE-010/
  01-evaluation.md
  02-plan.md
  03-implementation.md
  04-ai-review.md
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

### Run the app on an iOS simulator (iPhone / iPad)

```bash
./scripts/local/startInPhone.sh    # iPhone 17 Pro
./scripts/local/startInTablet.sh   # iPad mini (A17 Pro)
```

Each builds the MAUI Mobile app (`ServiceDelivery.Client.Mobile`) and deploys + launches it on the named simulator (booting it and opening Simulator.app if needed). They block streaming the app console — Ctrl-C to stop. Both are thin wrappers over `scripts/utils/run-on-simulator.sh`, which resolves a device by name (preferring one already booted) and does the build/deploy/run.

### Run all backend tests

```bash
./scripts/local/test-backend.sh
```

Runs `dotnet test` across all backend test projects (Domain, Application, Infrastructure, Api, Architecture).

### Run all simulator tests

```bash
./scripts/local/test-simulator.sh
```

Runs `dotnet test` against the simulator repo.

### Run all frontend tests

```bash
./scripts/local/test-frontend.sh
```

Runs `dotnet test` against the frontend repo.

### Run the unit + integration suite (offline)

```bash
./scripts/local/test-unit-and-integration.sh
```

Runs the backend, frontend, and simulator unit + integration suites with a live results table. No live system required.

### Run the end-to-end suite (live system)

```bash
./scripts/local/test-e2e.sh        # Playwright (web) then Appium (iOS) — runs both
./scripts/local/test-playwright.sh  # Playwright suite alone
./scripts/local/test-appium.sh      # Appium suite alone (needs Appium installed)
```

Each script boots and tears down its own live system (backend, web host, simulator, iOS sim as needed).

### Run the complete test suite

```bash
./scripts/local/test-all.sh
```

Runs the offline unit + integration suite, then the end-to-end suite (Playwright + Appium). Boots a live system for the E2E phase.

### Bring up the full system locally

```bash
./scripts/local/start.sh
```

Starts the backend (HTTP profile, `http://localhost:5180`) and the simulator as background processes, exporting `DOTNET_ENVIRONMENT=Local` so both load `appsettings.Local.json` for local credentials. The backend seeds its data on startup. Logs: `/tmp/sd-backend.log`, `/tmp/sd-sim.log`.

### Bring up the full demo (backend + sim + all three clients)

```bash
./scripts/local/startSystem.sh
```

One command for a live multi-persona demo: runs `start.sh` (backend + simulator), then opens a separate Terminal.app window for each frontend client — **Dispatcher** on Web, **ServiceRep** on the iPhone simulator, **Requester** on the iPad simulator. Idempotent (skips `start.sh` if `:5180` is already up). Three distinct host surfaces means three independent login sessions with no token collision.

### Drive one job end-to-end (headless smoke)

```bash
./scripts/local/smoke.sh
```

Logs in as a dispatcher + requester, submits a service request near an available rep, and watches the automated cycle (offer → accept → en route → arrive → dwell → complete) over the API — the integration check that exercises the backend↔simulator contract without the frontend.

### Tear down

```bash
./scripts/local/stop.sh
```

Stops the backend and simulator.

To tear down the **full demo** brought up by `startSystem.sh` (backend + simulator **plus** the web client and the iPhone/iPad simulator apps):

```bash
./scripts/local/stopSystem.sh
```

The inverse of `startSystem.sh`: runs `stop.sh`, frees the web client port (`:5023`), kills the mobile build/deploy sessions, and shuts down the demo simulators (leaving any other booted simulators alone).

### `mark-story-complete.sh` (automated)

`scripts/utils/mark-story-complete.sh` is not run by hand. A PostToolUse hook fires it after `gh pr merge` succeeds; it extracts the story/bug ID from the merged branch name and crosses that row out in `docs/stories/execution-plan.md`.
