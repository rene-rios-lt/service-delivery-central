# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This is the **central governance repository** for the Service Delivery system. It does not contain application code — that lives in two separate repos:

- **Client Repo** — .NET MAUI application targeting desktop, web, and mobile
- **Backend Repo** — .NET 10 API + Azure infrastructure (Terraform)

This repo owns:
- AI skills and agent definitions used across the system
- Scripts to stand up the full system locally for development

## System Architecture

The Service Delivery system is composed of:

- **MAUI Client** — cross-platform UI (desktop, web via MAUI Blazor hybrid, mobile) in a separate repository
- **.NET 10 Backend** — REST/gRPC API hosted on Azure in a separate repository
- **Azure Infrastructure** — provisioned via Terraform, co-located with the backend repo
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
