---
description: Implements a user story end-to-end using the TDD pipeline. Invoke with /master <STORY-ID> (e.g. /master BE-010, /master FE-007, /master SIM-003).
---

# Master Orchestrator

Orchestrates the full story implementation pipeline. Speaks in status updates, not implementation detail. Coordinates agents, enforces checkpoints — does not skip steps, does not approve its own work, does not proceed past a blocker.

---

## Trigger

Invoked with a story ID:

```
/master BE-010
/master SIM-003
/master FE-007
```

---

## Lifecycle

### 1. Display the story

Read `docs/stories/<repo>.md` in the central repo (match story prefix: `BE-` → `backend.md`, `SIM-` → `simulator.md`, `FE-` → `frontend.md`). Display the story title and all acceptance criteria.

### 2. Setup

In the working repo for this story, at the start of every execution:
1. Delete `.stories/<STORY-ID>/` if it exists (clean slate).
2. Create `.stories/<STORY-ID>/`.
3. Create the feature branch: `git checkout -b feature/<STORY-ID>-<kebab-case-title>` where the title comes from the story heading, lowercased and hyphenated. Example: story "BE-010 — Submit a service request" → `feature/BE-010-submit-service-request`. If the branch already exists, check it out and verify it is not behind `main`.

### 3. Evaluator

Invoke the **story-evaluator** agent with the story ID.

- If result is `BLOCKED`: display the blockers, stop. Do not proceed until blockers are resolved and the developer re-runs.
- If result is `READY`: continue.

### 4. Planner

Invoke the **story-planner** agent with the story ID and Evaluator output.

Present the plan to the developer.

### CHECKPOINT #1 — Plan Review

**Pause.** Tell the developer:

> "Plan ready for review. Approve to begin implementation, or provide feedback to revise the plan."

Do not proceed until explicit approval is given. If feedback is provided, pass it back to the Planner and repeat until approved.

### 5. Implementor

Invoke the **story-implementor** agent with the story ID and the approved plan.

Report test results: number of tests passing, any failures.

### 6. AI Reviewer

Invoke the **story-ai-reviewer** agent with the story ID and the full diff from the Implementor.

Present the full findings to the developer.

### CHECKPOINT #2 — AI Review

**Pause.** Tell the developer:

> "AI Review complete. Approve to prepare the PR, or send back to the Implementor with the listed issues."

- If approved: continue.
- If sent back: pass the AI Reviewer's findings as additional constraints to the Implementor. Re-run the Implementor. Re-run the AI Reviewer. Present the new findings. Pause again.

Repeat until the developer approves.

### 7. Story Reviewer

Invoke the **story-reviewer** agent with the story ID, the full diff, and the AI Reviewer output.

### 8. PR Agent

Invoke the **story-pr** agent with the story ID, the branch name, and the Story Reviewer output.

Report the PR URL to the developer.

### 9. Done

Tell the developer:

> "PR is open at <URL>. Merge when ready."

---

## Repo Layout

The central repo root contains the working repos as subdirectories:

```
ServiceDelivery/              ← central repo root (this repo)
  .claude/
    skills/                   ← skill files (you are here)
    agents/                   ← subagent definitions
  docs/stories/               ← user story backlogs
  docs/architecture/          ← architecture docs and ADRs
  service-delivery-backend/   ← backend working repo
  service-delivery-simulator/ ← simulator working repo
  service-delivery-frontend/  ← frontend working repo
```

From any working repo, the central repo root is at `../` (one level up).
Skills are at `../.claude/skills/<name>/SKILL.md` from a working repo.

## Working Repo Resolution

| Story prefix | Working repo directory |
|-------------|------------------------|
| `BE-` | `service-delivery-backend/` |
| `SIM-` | `service-delivery-simulator/` |
| `FE-` | `service-delivery-frontend/` |

---

## Guardrails

- Never skip a checkpoint.
- Never proceed to a later phase if an earlier phase returned a blocking result.
- Never merge or push to `main` directly.
- Never approve the AI Reviewer's findings on behalf of the developer — that is a human decision.
- If the developer provides no response at a checkpoint, wait. Do not time out and proceed.
