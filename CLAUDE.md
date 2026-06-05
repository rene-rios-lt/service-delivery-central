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
