---
description: Validates the AI system (agents + skills) for silent drift before a story run hits it — frontmatter and section structure, native subagent registration, resolvable Required Reading paths, intact cross-references, audit-file numbering, and registry consistency between master/CLAUDE.md and the files on disk. Returns blocking findings and non-blocking warnings.
---

# Skill: Validate Ai System

## Purpose

Catch AI system drift **before** a story run discovers it. The dangerous failures here are the ones that throw no error: a renamed skill folder leaves a Required Reading path dangling and the agent silently skips that discipline; a `## Output Format` section goes missing and the agent free-forms its output; an agent's `name:` stops matching its folder and it no longer registers as a subagent; `master` references a stage that no longer exists. None of these surface at load time — they just quietly make `/master` behave wrong.

This skill makes that drift visible and actionable. It validates **internal consistency and runnability**, not just per-file formatting — it cross-checks the orchestrator (`master/SKILL.md`), the documentation (`CLAUDE.md`), and the actual files against each other.

Run it before and after any edit to an `AGENT.md` or `SKILL.md`. It also runs automatically via a PostToolUse hook after any `.claude/` file edit (see Repo Adaptations).

---

## How to run

The checks are implemented deterministically in a single script — there is no manual step-by-step interpretation to do. Run it and relay the output:

```bash
./scripts/utils/validate-ai-system.sh
```

- **Exit 0** — clean (or warnings only). Report the result.
- **Exit 1** — blocking findings exist. Relay them verbatim and stop; do not run `/master` until they are resolved.

The hook invokes the same script with `--quiet` (silent when fully clean). Manual runs and the hook therefore always agree — one engine, no second implementation to drift.

---

## What it checks

**Blocking** (breaks a story run — exit 1):

| # | Check | Silent failure it prevents |
|---|-------|----------------------------|
| 1 | Every agent/skill folder contains its definition file | Empty folder → stage missing at runtime |
| 2 | AGENT.md has `name:`, `description:`, `tools:` | Missing field → subagent fails to register or runs unconstrained |
| 3 | `name:` matches the folder and is unique | Mismatch → subagent registers under the wrong id or not at all |
| 4 | AGENT.md has all required sections (`## Required Reading`, `## Inputs`, `## Audit Output`, `## Process`, `## Output Format`) + persona heading | Missing section → unpredictable agent output |
| 5 | An agent that declares an audit file has `Write` in `tools:` | Declared output it cannot actually produce |
| 6 | SKILL.md has `description:`, `## Purpose`, `## Repo Adaptations` | Malformed skill |
| 7 | Required Reading paths resolve | Dangling path → agent skips that discipline silently |
| 8 | Skill cross-references resolve | Broken `[[link]]`/path misleads readers, hides coverage gaps |
| 9 | Each agent declares its expected stage audit file (`01-evaluation.md` … `05-pr.md`) | Mis-numbered handoff between stages |
| 10 | `master/SKILL.md` references every agent, and every agent it references exists | Orphan stage, or a wired stage that's gone |

**Warning** (drift worth fixing, won't break a run — exit 0):

| Check | Why it's a warning, not a blocker |
|-------|-----------------------------------|
| `tools:` entry outside the known tool roster (likely a typo) | The roster evolves; a real new tool shouldn't fail the build |
| Agent body has a shell block but `tools:` lacks `Bash` | Heuristic — usually right, occasionally a doc-only example |
| An agent/skill folder is undocumented in the `CLAUDE.md` registry tables | Documentation lag, not a runtime fault |

---

## Known-example handling (no false positives)

The governance skills (`validate-ai-system`, `audit-agents`, `audit-skills`) deliberately contain *example* broken references (e.g. `ac-coverge`, `ac-overage`) to illustrate what a failure looks like. The script excludes these so it does not flag its own documentation:

- references inside fenced code blocks are skipped;
- the documented example typos are held in a tiny, explicit ignore-list in the script.

If you add a new illustrative typo to a skill's docs, add it to `EXAMPLE_IGNORE` in `scripts/utils/validate-ai-system.sh` so the validator stays trustworthy — a linter that cries wolf gets ignored.

---

## Hard Rules

- A **blocking** finding is a gate — do not run `/master` until it is resolved. Each one maps to a silent runtime failure, not a style nit.
- **Warnings** do not block a run, but resolve documentation/tool warnings before merging an AI-system change — they are how today's warning becomes tomorrow's drift.
- The script is the single source of truth. Do not re-implement its checks by hand in this file or anywhere else — extend the script and let both the skill and the hook inherit the change.
- After editing an `AGENT.md` or `SKILL.md`, re-run the script before declaring the system clean — confirm the change saved and introduced no new finding.

---

## Repo Adaptations

This skill applies in the **central repo only** (`service-delivery-central`). The working repos (backend, frontend, simulator) contain no `AGENT.md` or `SKILL.md` files.

The script resolves the central repo root from its own location (`scripts/utils/` → repo root), so it runs correctly from any working directory and from the hook, where the cwd is not guaranteed.

**Automatic invocation:** a `PostToolUse` hook in `.claude/settings.json` runs `validate-ai-system.sh --quiet` after any `Edit`/`Write`/`MultiEdit` to a file under `.claude/`. On a clean edit it stays silent; on any finding it surfaces the report immediately, so AI-system drift is caught at the moment it is introduced rather than at the next story run.
