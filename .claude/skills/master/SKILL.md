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

## Working Repo Resolution

| Story prefix | Working repo directory |
|-------------|------------------------|
| `BE-` | `service-delivery-backend/` |
| `SIM-` | `service-delivery-simulator/` |
| `FE-` | `service-delivery-frontend/` |

---

## Agent Files

| Agent name | File |
|-----------|------|
| `story-evaluator` | `.claude/agents/story-evaluator/AGENT.md` |
| `story-planner` | `.claude/agents/story-planner/AGENT.md` |
| `story-implementor` | `.claude/agents/story-implementor/AGENT.md` |
| `story-ai-reviewer` | `.claude/agents/story-ai-reviewer/AGENT.md` |
| `story-pr` | `.claude/agents/story-pr/AGENT.md` |

---

## Lifecycle

### 1. Display the story

Read `docs/stories/<repo>.md` in the central repo (match story prefix: `BE-` → `backend.md`, `SIM-` → `simulator.md`, `FE-` → `frontend.md`). Display the story title and all acceptance criteria.

If the story ID does not appear in the file, stop and report: `Story [ID] not found in docs/stories/[repo].md. Verify the ID and re-run.`

### 2. Setup

In the working repo for this story, at the start of every execution:
1. Delete `.stories/<STORY-ID>/` if it exists (clean slate).
2. Create `.stories/<STORY-ID>/`.
3. Create the feature branch (title from the story heading, lowercased and hyphenated):
   ```bash
   git checkout -b feature/<STORY-ID>-<kebab-case-title>
   ```
   Example: story "BE-010 — Submit a service request" → `feature/BE-010-submit-service-request`.
   If the branch already exists (prior failed run), check it out instead:
   ```bash
   git checkout feature/<STORY-ID>-<kebab-case-title>
   ```
   Then verify it is not behind `main`:
   ```bash
   git log main..HEAD
   ```
   If unexpected commits are present, report to the developer before continuing.

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

If the plan's **Dependency Gaps** section contains any entries, surface each gap explicitly before pausing:

> "The plan identified [N] dependency gap(s):
> - [Interface] — [method needed] — [action required]
>
> Decide for each before approving: (a) include the missing method in this story's scope — add it to the file list and interfaces section, (b) block this story until the upstream story lands the method, or (c) proceed knowing the build will fail until the gap is resolved."

Do not proceed until explicit approval is given. If feedback is provided, pass it back to the Planner and repeat until approved.

### 5. Implementor

Invoke the **story-implementor** agent with the story ID and the approved plan.

Report test results: number of tests passing, any failures.

### 6. AI Reviewer

Invoke the **story-ai-reviewer** agent with the story ID and the path to `.stories/<STORY-ID>/02-plan.md`. The agent produces its own diff internally — do not run `git diff` here.

Present the findings to the developer. On the first review cycle this is the full findings. On subsequent cycles it is a delta (resolved vs still-open findings).

### CHECKPOINT #2 — AI Review

**Pause.** Tell the developer:

> "AI Review complete. Approve to prepare the PR, or send back to the Implementor with the listed issues."

- If approved: continue.
- If sent back: pass the AI Reviewer's findings as additional constraints to the Implementor. Re-run the Implementor. Re-run the AI Reviewer — note in the invocation that this is cycle N (so the agent returns a delta). Present the delta findings. Pause again.

Repeat until the developer approves.

**Loop limit:** if the AI Reviewer returns BLOCKED for 3 consecutive cycles on the same story without any finding being resolved, stop. Surface all unresolved findings to the developer with a recommendation to revisit the plan. Do not invoke the Implementor a 4th time automatically.

### 7. PR Agent

Invoke the **story-pr** agent with: story ID, branch name, path to `.stories/<STORY-ID>/03-ai-review.md`, and path to `../docs/stories/<repo>.md`.

Report the PR URL to the developer.

### 8. Done

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

---

## Guardrails

- Never skip a checkpoint — checkpoints are the developer's opportunity to catch AI-generated errors before they propagate to later pipeline stages.
- Never proceed to a later phase if an earlier phase returned a blocking result — downstream agents assume their inputs are valid; a blocking result means the assumption is violated.
- Never merge or push to `main` directly.
- Never approve the AI Reviewer's findings on behalf of the developer — AI approval of AI output bypasses the human oversight the checkpoint exists to provide.
- If the developer provides no response at a checkpoint, wait. Do not time out and proceed.
