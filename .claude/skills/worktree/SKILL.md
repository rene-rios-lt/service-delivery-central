---
description: Create or tear down per-story git worktrees and launch a Claude session for each — `/worktree BE-030 BE-031` spins up parallel story work in one command. Invoke for "worktree", "new worktree", "parallel stories", or cleanup of merged worktrees.
---

# Skill: Worktree

## Purpose

Spin up isolated, ready-to-work environments for one or more stories in a single command, and tear them down just as fast. Each worktree is a real `git worktree` of the story's working repo, created on a correctly-named branch off the latest `origin/main`, placed inside the central repo at `.worktrees/<STORY-ID>`. On creation the script symlinks central's `.claude` into the worktree (so `/master` and the `story-*` agents are discoverable there), opens a Terminal.app window with Claude running in the worktree, and sends `/master <STORY-ID>` as typed text once the session is up — so parallel story work starts without hand-typing branch names, `cd`-ing between directories, or launching sessions by hand. (`/master` runs in **worktree mode**: it operates on the worktree as the working repo and reads story/docs from central.)

Use this for out-of-session worktree management. It is the fast path for the otherwise fragile manual sequence (create branch → add worktree → open terminal → cd → launch claude → run `/master`).

## When to use

- "Create a worktree for BE-030" / "set up worktrees for BE-030 and BE-031"
- "Start these stories in parallel"
- "Clean up the BE-028 worktree" / "remove all merged worktrees"

For the story implementation itself, the spawned session runs `/master` — this skill only manages the worktree + session lifecycle.

## Process

All work is done by `scripts/utils/worktree.sh` (from the central repo). The skill's job is to resolve intent to the right verb and ids, run the script, and report.

1. **Parse the request** into a verb and one or more story ids:
   - Bare ids (`/worktree BE-030 BE-031`) → **create**.
   - `create <ids…>` → create. `remove <ids…>` → remove. `remove --merged` → sweep merged worktrees.
2. **Validate ids** look like `BE-### / FE-### / SIM-### / BUG-### / QUAL-###`. A `QUAL-` id must be a **product-code** QUAL story (one with a **Repo / Area** line in `quality.md`) — the script refuses a central-only QUAL id with a pointer to `/ship-it`. The script itself errors out if an id is not in the backlog (typo guard), so do not pre-invent ids.
3. **Run the script** from the central repo root:
   ```bash
   scripts/utils/worktree.sh create BE-030 BE-031
   scripts/utils/worktree.sh remove BE-030
   scripts/utils/worktree.sh remove --merged
   ```
4. **Report** per id: the worktree path, the branch, and that a Terminal window launched `/master <id>` (or, for remove, what was torn down and whether a branch was kept because it was unmerged).
5. **On a dirty-worktree removal failure**, surface it and confirm with the developer before re-running with `SD_WORKTREE_FORCE=1` — never force-discard uncommitted work silently.

## Guardrails

- Always create branches off freshly fetched `origin/main` (the script fetches first).
- Worktrees live **only** under `.worktrees/` inside the central repo — never as siblings or inside a working repo.
- `.worktrees/` is gitignored and excluded from AI analysis (`.claude/settings.json`). Do **not** try to Read, Grep, or Glob into `.worktrees/` — operate on it through git/the script only. The spawned session, rooted inside its own worktree, analyses that code normally.
- Never delete an unmerged branch: removal uses `git branch -d` (safe) and keeps the branch if it is not fully merged.
- Confirm before `SD_WORKTREE_FORCE=1`; never touch `main` directly.
- Story implementation, commits, and PRs belong to `/master` (the spawned session) — this skill does not commit.

## Repo Adaptations

This skill runs from the **central repo** and operates on the working repos by absolute path. Story prefix selects the working repo:

| Prefix | Working repo | Branch prefix |
|--------|--------------|---------------|
| `BE-`  | `service-delivery-backend/`   | `feature/` |
| `FE-`  | `service-delivery-frontend/`  | `feature/` |
| `SIM-` | `service-delivery-simulator/` | `feature/` |
| `BUG-` | resolved from the bug's **Repo / Area** line in `docs/stories/bug.md` | `fix/` |
| `QUAL-` | resolved from the story's **Repo / Area** line in `docs/stories/quality.md` — no line ⇒ central-only, refused (ships via `/ship-it`) | `feat/` |

The branch slug is derived from the story heading in `docs/stories/<repo>.md` (or `bug.md` / `quality.md`) — e.g. `### BE-028 — Rep heartbeat & go-off-duty` → `feature/BE-028-rep-heartbeat-go-off-duty`. A product-code `QUAL-` story branches as `feat/QUAL-NNN-<kebab-title>` — the same shape `/ship-it` uses for central QUAL shipments, so the post-merge hook strikes the plan row either way. Worktree directories are named by bare id (`.worktrees/BE-028`). Each worktree gets a `.claude` symlink to central's so the pipeline resolves there; `/master` detects this and runs in worktree mode. Terminal launching is macOS / Terminal.app specific (via `osascript`): it opens Claude bare and sends `/master <id>` after a delay (`SD_WORKTREE_LAUNCH_DELAY`, default 6s — if a first-run trust prompt appears, type the command yourself). Set `SD_WORKTREE_NO_LAUNCH=1` to create the worktree without opening a window.
