---
description: Implements a user story end-to-end using the TDD pipeline. Invoke with /master <STORY-ID> (e.g. /master BE-010, /master FE-007, /master SIM-003, /master BUG-001).
---

# Master Orchestrator

## Purpose

Orchestrate the full story implementation pipeline from evaluation through PR creation. Coordinates five pipeline agents in sequence, enforces two human checkpoints, and handles all failure and recovery paths. This is the entry point for all story work — no pipeline agent is invoked directly.

---

Speaks in status updates, not implementation detail. Coordinates agents, enforces checkpoints — does not skip steps, does not approve its own work, does not proceed past a blocker.

---

## Trigger

Invoked with a story ID:

```
/master BE-010
/master SIM-003
/master FE-007
/master BUG-001
```

---

## Working Repo Resolution

| Story prefix | Working repo directory |
|-------------|------------------------|
| `BE-` | `service-delivery-backend/` |
| `SIM-` | `service-delivery-simulator/` |
| `FE-` | `service-delivery-frontend/` |
| `BUG-` | not encoded by the prefix — read the bug's **Repo / Area** field in `bug.md` (backend / frontend / simulator) |

---

## Worktree Execution Mode

`/master` may run from one of two locations, and must detect which **before Step 1**:

- **Central mode (default):** cwd is the central repo. Working repos are subdirectories (`service-delivery-backend/` etc.); story docs are at `docs/stories/<repo>.md`; skills at `.claude/skills/...`.
- **Worktree mode:** cwd is a per-story git worktree created by `/worktree` (`scripts/utils/worktree.sh`) — the cwd **is** the working repo, already checked out on the story branch, and its `.claude` is a symlink into the central repo.

**Detect worktree mode** at the start of the run:

```bash
readlink .claude 2>/dev/null   # non-empty (…/.claude) ⇒ worktree mode
```

If `.claude` is a symlink to a central repo's `.claude`, resolve the central root once and use **absolute paths** for everything central thereafter:

```bash
CENTRAL="$(cd "$(dirname "$(readlink .claude)")" && pwd)"   # e.g. /Users/rrios/dev/ServiceDelivery
WORKTREE="$(pwd)"                                            # the working repo for this story
```

Then apply these overrides to the rest of this skill:

| Concern | Central mode | Worktree mode |
|---------|--------------|---------------|
| Working repo | `<central>/service-delivery-<x>/` | `$WORKTREE` (the cwd itself) |
| Story / docs files | `docs/stories/<repo>.md` | `$CENTRAL/docs/stories/<repo>.md` |
| Skill / Required-Reading paths | `.claude/skills/...` | `$CENTRAL/.claude/skills/...` |
| Audit files (`.stories/<ID>/`) | in the working repo | `$WORKTREE/.stories/<ID>/` |
| Feature branch (Step 2) | `git checkout -b feature/<ID>-...` | **already on the branch — do NOT create or switch; skip branch creation** |
| Plan strikethrough on merge | PostToolUse hook crosses the story out automatically | **hook does NOT fire from a worktree** — after the PR merges, run `$CENTRAL/scripts/utils/mark-story-complete.sh <ID>` (or `scripts/utils/worktree.sh remove --merged`, which reconciles the whole plan) |

When invoking every pipeline agent in worktree mode, pass it explicitly: the story ID, `$WORKTREE` as the working repo (all code/test/git work happens there), `$CENTRAL` for reading story/docs/skill files by absolute path, and the audit-file path under `$WORKTREE/.stories/<ID>/`. Tell each agent it is running in a worktree and must NOT assume the central repo is at `../` or that working repos are subdirectories. Everything else in the Lifecycle is unchanged.

---

## Agent Files

| Agent name | File |
|-----------|------|
| `story-evaluator` | `.claude/agents/story-evaluator/AGENT.md` |
| `story-planner` | `.claude/agents/story-planner/AGENT.md` |
| `story-implementor` | `.claude/agents/story-implementor/AGENT.md` |
| `story-ai-reviewer` | `.claude/agents/story-ai-reviewer/AGENT.md` |
| `story-pr` | `.claude/agents/story-pr/AGENT.md` |

Each stage's model is pinned in its AGENT.md `model:` frontmatter (Opus 4.8 for Implement + AI Review; Sonnet 4.6 for Evaluate, Plan, PR) — the orchestrator does not select it. See CLAUDE.md → "Stage Model Assignment".

---

## Lifecycle

### 1. Display the story

Read `docs/stories/<repo>.md` in the central repo (match story prefix: `BE-` → `backend.md`, `SIM-` → `simulator.md`, `FE-` → `frontend.md`, `BUG-` → `bug.md`). Display the story title and all acceptance criteria. For a `BUG-` ID, also read its **Repo / Area** field — that determines the working repo (see Working Repo Resolution above).

If the story ID does not appear in the file, stop and report: `Story [ID] not found in docs/stories/[repo].md. Verify the ID and re-run.`

For a frontend UI story, the embedded mockup image (`docs/ui-mockups/images/...`) is part of the story — it is the visual spec the component is built to. The Evaluator confirms it resolves, the Planner reads it into a UI Composition Map, the Implementor builds the component to match it, and the AI Reviewer checks fidelity. Surface the mockup reference when displaying the story so the developer can review it at Checkpoint #1.

A documentation-only bug (no code or tests) does not belong in this TDD pipeline — handle it as a direct doc edit via `/ship-it` instead.

### 2. Setup

In the working repo for this story, at the start of every execution:
1. Delete `.stories/<STORY-ID>/` if it exists (clean slate).
2. Create `.stories/<STORY-ID>/`.
3. Create the feature branch (title from the story heading, lowercased and hyphenated). **In worktree mode (see Worktree Execution Mode), skip this step entirely — the worktree is already checked out on the story branch; do steps 1–2 under `$WORKTREE/.stories/` and proceed to Step 3.**
   ```bash
   git checkout -b feature/<STORY-ID>-<kebab-case-title>
   ```
   Example: story "BE-010 — Submit a service request" → `feature/BE-010-submit-service-request`.
   For a `BUG-` ID, use a `fix/` branch instead — e.g. `fix/BUG-001-rephub-force-release-event`.
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

Before invoking the evaluator, capture the run's start time as the wall-clock anchor:

```bash
date +%s   # record this value; it anchors the wall-clock metric reported in Step 8
```

Capture it once per execution — the Evaluator is the first stage, so this marks "first stage". Do not reset it on a BLOCKED re-run; a fresh `/master` invocation is a new execution with a new anchor.

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
> - [Interface] — [method needed] — defined in [file] — [upstream story]
>
> Decide for each before approving: (a) include the missing method in this story's scope, (b) block this story until the upstream story lands the method, or (c) proceed knowing the build will fail until the gap is resolved."

**When the developer chooses option (a) for one or more gaps:**

For each resolved gap, record a **Dependency Gap Resolution** containing:
- The interface file path (from the Planner's Dependency Gaps table)
- The method signature to add (from the Dependency Gaps table)
- The concrete implementation file(s) of that interface — use Grep to locate classes that implement the interface if not already identified by the Planner

Pass all Dependency Gap Resolutions to the Implementor invocation alongside the story ID and plan path. The Implementor will add the interface method signatures and NotImplementedException stubs before starting the AC TDD cycle.

Do not proceed until explicit approval is given. If feedback is provided, pass it back to the Planner and repeat until approved.

### 5. Implementor

Invoke the **story-implementor** agent with the story ID and the approved plan.

Report test results: number of tests passing, any failures. The Implementor writes `.stories/<STORY-ID>/03-implementation.md` on completion — confirm it exists before proceeding.

#### Implementor Failure Recovery

The Implementor stops and reports to Master in two cases. Do not attempt to re-invoke the Implementor without following the recovery path below.

**Case 1 — Compile error exhausted (3 attempts on same test)**

The Implementor reports: the AC number, the test file path, and the exact compile error.

1. Display the compile error and test file path to the developer verbatim.
2. Pause with:

   > "The Implementor could not compile the test for [AC-N] after 3 attempts. Fix the test file at [path] manually — the error is above. When ready, signal to resume."

3. When the developer signals ready: re-invoke the Implementor with the story ID, the approved plan, and the explicit instruction **"Resume from AC-[N] — test now compiles, begin at Green."**
4. The Implementor will verify the test now compiles-and-fails, then run Green → Refactor for AC-N and continue through the remaining ACs.
5. If the Implementor reports the same compile error again on the resumed invocation, stop. Surface the error to the developer with: "Compile error persists after manual fix attempt. Revisit the plan — the test structure may be fundamentally incompatible with the current file list."

**Case 2 — Wrong branch**

The Implementor reports: the actual branch name found, the expected branch name.

1. Display: "Branch verification failed — Implementor found `[actual]` instead of `[expected]`. Correct the branch state before continuing."
2. Pause. Wait for the developer to fix the branch state (e.g. `git checkout feature/<STORY-ID>-<title>`).
3. When the developer signals ready: re-invoke the Implementor from the beginning — it will re-verify the branch as its first action. No other recovery is needed; no AC progress is lost because no production code was written on the wrong branch.

### 6. AI Reviewer

Invoke the **story-ai-reviewer** agent with the story ID, the path to `.stories/<STORY-ID>/02-plan.md`, and the path to `.stories/<STORY-ID>/03-implementation.md`. The agent produces its own diff internally — do not run `git diff` here.

Present the findings to the developer. On the first review cycle this is the full findings. On subsequent cycles it is a delta (resolved vs still-open findings).

The AI Reviewer's verdict (`APPROVED` or `BLOCKED`) is the **input to Checkpoint #2** — it is not the checkpoint decision. Do not invoke the PR agent based on the verdict alone.

### CHECKPOINT #2 — AI Review

**Pause regardless of verdict.** An `APPROVED` result means the AI found no issues — it does not mean the developer has approved. Tell the developer:

> "AI Review complete. Approve to prepare the PR, or send back to the Implementor with the listed issues."

**Live E2E reminder (frontend stories with an end-to-end-reachable surface).** If the AI Reviewer's Check 2 identified an E2E-only AC for this story — or flagged `[E2E authored but not run live]` / `[Missing E2E test …]` — surface this before the developer approves:

> "This story has a surface that is only verifiable end-to-end. A green unit/bUnit suite is **not** evidence the screen works — the live net is. Before declaring this story complete, run its QUAL-003/004 scenario green against a live system (`./scripts/local/start.sh` + `./scripts/local/test-playwright.sh` or `./scripts/local/test-appium.sh`), and the per-merge `./scripts/local/smoke-web.sh` for the web path. This is an explicit developer step — the pipeline does not boot a live system itself, exactly like the headless `smoke.sh`. Confirm the live run is green as part of your approval."

This belongs at the **front** of the loop, not a late catch-up: it is how the simulator caught `BUG-016/017` one at a time, and the gap that let the frontend `BUG-023…032` cluster accumulate (see QUAL-005). Surface it; do not run the live system on the developer's behalf.

Do not proceed until the developer explicitly responds.

- If approved: continue.
- If sent back: pass the AI Reviewer's findings as additional constraints to the Implementor. Re-run the Implementor. Re-run the AI Reviewer — note in the invocation that this is cycle N (so the agent returns a delta). Present the delta findings. Pause again.

Repeat until the developer approves.

**Loop limit:** if the AI Reviewer returns BLOCKED for 3 consecutive cycles on the same story without any finding being resolved, stop. Surface all unresolved findings to the developer with a recommendation to revisit the plan. Do not invoke the Implementor a 4th time automatically.

### 7. PR Agent

Invoke the **story-pr** agent with: story ID, branch name, path to `.stories/<STORY-ID>/04-ai-review.md`, path to `.stories/<STORY-ID>/03-implementation.md`, and path to `../docs/stories/<repo>.md`.

Report the PR URL to the developer.

### 8. Done

Capture the run end time (`date +%s`) and compute the **Run Time** as a table.

Source the numbers from:
- **Per-stage durations** — each stage invocation's reported execution duration: evaluator, planner, implementor, each AI-review cycle, and the PR agent. Each invocation is its **own row**, including re-runs (BLOCKED re-evaluations, implementor re-runs, additional review cycles) — label a re-run row with its cycle, e.g. `AI Review (cycle 2)` or `Implementor (re-run)`. Never fold a re-run into its first execution's row; the retry cost must stay visible.
- **Active pipeline total** — the sum of every per-stage row above. Excludes time the run sat paused at checkpoints. Render it as a **bold separator row** directly beneath the stage rows, so the breakdown visibly sums to it.
- **Wall-clock** — end timestamp minus the Step 3 start anchor. **Includes** the time the run was paused at both checkpoints. Render it as the final row, beneath the active total. If the start anchor is unavailable (e.g. context was summarized mid-run), put `unavailable` in its Duration cell rather than omitting the row.

Format each duration as `Xm Ys` (or `Ys` when under a minute).

The active total is smaller than wall-clock; the difference is checkpoint wait plus orchestration overhead — that gap is expected and worth surfacing.

Tell the developer (table column widths are illustrative — let them render naturally):

> "PR is open at <URL>. Merge when ready.
>
> **Run time**
>
> | Stage | Duration |
> |-------|----------|
> | Evaluator | `<Xm Ys>` |
> | Planner | `<Xm Ys>` |
> | Implementor | `<Xm Ys>` |
> | AI Review | `<Xm Ys>` |
> | PR | `<Xm Ys>` |
> | **Active pipeline total** | **`<Xm Ys>`** |
> | Wall-clock (incl. checkpoint pauses) | `<Am Bs>` |
>
> The ~`<gap>` between active and wall-clock is checkpoint wait plus orchestration overhead."

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
- An `APPROVED` verdict from the AI Reviewer is not developer approval — Checkpoint #2 requires an explicit developer response regardless of the reviewer's verdict.
- If the developer provides no response at a checkpoint, wait. Do not time out and proceed.
- A pause is closed only by an explicit developer response that resolves it. Questions asked, work requested, or fixes made during a pause do not close it — re-state the pause question after any mid-pause work before proceeding.
- Always report the Run Time in the Done step (active pipeline time + wall-clock). If the wall-clock start anchor was lost, say so rather than silently omitting the metric.

---

## Repo Adaptations

This skill runs from the **central repo** (`service-delivery-central`) and dispatches work into a working repo determined by the story prefix:

| Story prefix | Working repo |
|-------------|-------------|
| `BE-` | `service-delivery-backend/` |
| `SIM-` | `service-delivery-simulator/` |
| `FE-` | `service-delivery-frontend/` |
| `BUG-` | not encoded by the prefix — read the bug's **Repo / Area** field in `bug.md` (see Working Repo Resolution) |

All agent invocations, branch operations, and audit file paths are scoped to the resolved working repo. The central repo itself is never the target of story implementation work.
