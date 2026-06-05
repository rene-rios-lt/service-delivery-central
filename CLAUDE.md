# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This is the **central governance repository** for the Service Delivery system. It does not contain application code — that lives in three separate repos:

- **Frontend** — [service-delivery-frontend](https://github.com/rene-rios-lt/service-delivery-frontend) — .NET MAUI Blazor Hybrid client targeting Desktop (macOS/Windows), Mobile (iOS/Android), and Web (Blazor WASM)
- **Backend** — [service-deliver-backend](https://github.com/rene-rios-lt/service-deliver-backend) — .NET 10 Clean Architecture API + Azure infrastructure (Terraform)
- **Central** — [service-delivery-central](https://github.com/rene-rios-lt/service-delivery-central) — this repo

This repo owns:
- AI skills and agent definitions used across the system
- Scripts to stand up the full system locally for development

## System Architecture

The Service Delivery system is composed of:

- **Frontend** ([repo](https://github.com/rene-rios-lt/service-delivery-frontend)) — five-project structure: `Core` (models/interfaces/ViewModels), `UI` (all Razor components and pages), `Desktop` (macOS/Windows MAUI host), `Mobile` (iOS/Android MAUI host), `Web` (Blazor WASM host)
- **Backend** ([repo](https://github.com/rene-rios-lt/service-deliver-backend)) — Clean Architecture: `Domain` → `Application` → `Infrastructure` → `Api`; Terraform infrastructure under `terraform/` targeting Azure
- **Local Dev Orchestration** — Docker Compose managed from `scripts/local/` in this repo

## Directory Structure

- `ai/skills/` — reusable AI skill definitions governing agent behavior across the system
- `ai/agents/` — AI agent configurations and personas
- `scripts/local/` — Docker Compose files and shell scripts to spin up the full system locally
- `scripts/utils/` — shared helper scripts used across local and CI workflows
- `docs/architecture/` — architecture diagrams and decision context
- `docs/adr/` — Architecture Decision Records (ADRs)

## Local Development

Local environment orchestration scripts live in `scripts/local/`. Once populated, the canonical command to bring up the full system will be documented here. Scripts should be runnable from the repo root.

## AI Skills & Agents

Skills in `ai/skills/` are markdown-based definitions. Agents in `ai/agents/` reference skills and define scoped behaviors. Follow existing conventions when adding new skills or agents.
