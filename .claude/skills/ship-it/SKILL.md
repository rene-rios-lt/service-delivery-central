---
description: Branch, commit, push, PR, and merge in one shot — for out-of-pipeline changes (docs, config, housekeeping). Story work goes through /master, which handles commits and PRs via the story-pr agent.
---

# Skill: Ship It

## Purpose

Automate the full local-to-merged workflow for changes that live **outside the story pipeline**: doc fixes, config updates, ADR additions, execution-plan housekeeping, or any change that doesn't warrant a full evaluate → plan → implement → review cycle.

For story work (`BE-`, `FE-`, `SIM-` prefixed), use `/master` instead — the `story-pr` agent at the end of that pipeline handles branching, committing, pushing, and PR creation with a structured description.

Invoke `/ship-it` when there are pending local changes (uncommitted or unpushed) that need to land on `main` without going through the full story pipeline.

---

## Process

### Step 0 — Resolve the target repo

Check all four repos for pending changes:

```bash
git -C /Users/rrios/dev/ServiceDelivery status --short
git -C /Users/rrios/dev/ServiceDelivery log --oneline origin/main..HEAD

git -C /Users/rrios/dev/ServiceDelivery/service-delivery-backend status --short
git -C /Users/rrios/dev/ServiceDelivery/service-delivery-backend log --oneline origin/main..HEAD

git -C /Users/rrios/dev/ServiceDelivery/service-delivery-frontend status --short
git -C /Users/rrios/dev/ServiceDelivery/service-delivery-frontend log --oneline origin/main..HEAD

git -C /Users/rrios/dev/ServiceDelivery/service-delivery-simulator status --short
git -C /Users/rrios/dev/ServiceDelivery/service-delivery-simulator log --oneline origin/main..HEAD
```

**When checking the central repo** (`/Users/rrios/dev/ServiceDelivery/`), ignore the `??` untracked entries for `service-delivery-backend/`, `service-delivery-frontend/`, and `service-delivery-simulator/` — those are separate git repos, not untracked files.

Determine which repos have pending changes (uncommitted files or unpushed commits). Then:

- **Exactly one repo has changes** → use that repo as the target; proceed to Step 1.
- **Multiple repos have changes** → list each repo and its pending changes, then ask the developer which one to ship. Wait for an explicit answer before proceeding.
- **No repo has changes** → report: `Nothing to ship — all repos are clean and in sync with origin.` and stop.

All subsequent git commands in Steps 1–7 must be scoped to the resolved target repo using `git -C <repo-path>` (or by running from that directory). Never mix paths across repos in a single run.

---

### Step 1 — Assess current state

Run the following against the **target repo** resolved in Step 0:

```bash
git -C <repo-path> status --short
git -C <repo-path> diff --stat
git -C <repo-path> log --oneline origin/main..HEAD
```

Identify what is pending:
- **Unstaged or staged changes** — files modified but not yet committed
- **Committed-but-unpushed commits** — commits on local `main` ahead of `origin/main`
- **Both** — mixed state; handle each in order (commit first, then push)

---

### Step 2 — Derive branch name and commit message

Read the changed files and diffs to understand what the changes do. Do not ask the developer — infer from content.

**Branch name:** `<type>/<short-kebab-description>`
- Types: `feat`, `fix`, `refactor`, `docs`, `chore`
- Example: `refactor/validate-ai-system-terminology`

**Bug fixes — name the branch `fix/BUG-NNN-<short-kebab-description>`.** If the shipment resolves a tracked bug from `docs/stories/bug.md`, the branch name **must** contain the `BUG-NNN` ID. The post-merge `mark-story-complete.sh` hook keys off the branch name to cross the bug out in `execution-plan.md` — a `docs/…` branch without the ID will not be struck.
- Identify the bug ID from the diff: a bug fix typically flips that bug's **Status: Open → Fixed** in `bug.md` and/or applies its documented **Fix**. Use that `BUG-NNN`.
- Example: `fix/BUG-005-data-flow-arrived-message`.
- If one shipment resolves several bugs, use the lowest-numbered `BUG-NNN` in the branch and list the rest in the commit body. (The hook strikes the IDs found in the branch name.)
- If you cannot confidently identify which bug a change resolves, this is one of the rare cases to ask the developer for the ID before branching.

**Other tracked items shipped via `/ship-it`** — the same branch-name rule applies to any `execution-plan.md` row completed out-of-pipeline: **central-only** engineering-quality stories (**`QUAL-NNN`** in `docs/stories/quality.md` with **no Repo / Area line**). When a shipment completes such a story, put its ID in the branch name (e.g. `feat/QUAL-001-flag-masking-tests`) so the post-merge hook strikes it. (The hook recognises `BE`/`FE`/`SIM`/`BUG`/`QUAL` IDs.) **Product-code QUAL stories** — those carrying a **Repo / Area** line in `quality.md` (e.g. QUAL-012 → frontend, QUAL-013 → backend) — are **not** shipped this way: they run the full pipeline via `/master` (or `/worktree`), which uses the same `feat/QUAL-NNN-<kebab>` branch shape. Feature stories `BE-`/`FE-`/`SIM-` likewise go through `/master`.

**Commit message:**
- Subject line: `<type>: <imperative summary>` — for a bug fix use `fix:` and reference the ID, e.g. `fix: correct OnSite requester message (BUG-005)`
- Body: 1–2 sentences of context if needed (skip if the subject is self-explanatory)
- Always append: `Co-Authored-By: Claude Code <noreply@anthropic.com>`

---

### Step 3 — Create the feature branch

```bash
git -C <repo-path> checkout -b <branch-name> origin/main
```

If pending changes include already-committed local commits (ahead of origin/main), bring them onto the new branch:

```bash
git -C <repo-path> cherry-pick <sha> [<sha> ...]
```

Skip merge commits when cherry-picking. If committed changes include only the target commit and no unpushed file edits, proceed directly to Step 4.

If there are uncommitted file changes, they carry over automatically when the branch is created from `origin/main`. Stage and commit them:

```bash
git -C <repo-path> add <files>
git -C <repo-path> commit -m "..."
```

---

### Step 4 — Push

```bash
git -C <repo-path> push -u origin <branch-name>
```

---

### Step 5 — Open PR

Determine the correct GitHub repo slug from the target repo path:

| Repo path | GitHub slug |
|-----------|-------------|
| `/Users/rrios/dev/ServiceDelivery` | `rene-rios-lt/service-delivery-central` |
| `/Users/rrios/dev/ServiceDelivery/service-delivery-backend` | `rene-rios-lt/service-delivery-backend` |
| `/Users/rrios/dev/ServiceDelivery/service-delivery-frontend` | `rene-rios-lt/service-delivery-frontend` |
| `/Users/rrios/dev/ServiceDelivery/service-delivery-simulator` | `rene-rios-lt/service-delivery-simulator` |

```bash
gh pr create \
  --repo <github-slug> \
  --title "<type>: <summary>" \
  --head <branch-name> \
  --base main \
  --body "$(cat <<'EOF'
## Summary

<1–3 bullet points describing what changed and why.>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

---

### Step 6 — Merge

```bash
gh pr merge <pr-number> --merge --delete-branch --repo <github-slug>
```

---

### Step 7 — Sync local main

```bash
git -C <repo-path> checkout main
git -C <repo-path> pull origin main
```

---

### Step 8 — Prune merged local branches (smart cleanup)

Squash-merges (this project's default) are **not** recognised by `git branch -d` — the branch tip never becomes an ancestor of `main` — so merged branches silently pile up unless cleaned explicitly. After syncing `main`, tidy the **target repo only** (never reach into the other three).

1. Prune stale remote-tracking refs so "gone" upstreams are detected accurately:

   ```bash
   git -C <repo-path> fetch --prune origin
   ```

2. Delete the branch this run just created. Step 6's `--delete-branch` removes it on the remote, but the local copy lingers because the merge ran while it was the checked-out branch:

   ```bash
   git -C <repo-path> branch -D <branch-name>
   ```

3. Smart-delete any **other** local branch whose upstream is **gone** — it was pushed, merged, and its remote branch deleted. A gone upstream is the safe signal that distinguishes a merged-and-cleaned branch from local-only work. Never `main`:

   ```bash
   git -C <repo-path> for-each-ref --format '%(refname:short) %(upstream:track)' refs/heads/ \
     | awk '$2 == "[gone]" { print $1 }' \
     | grep -vx main \
     | xargs -r -n1 git -C <repo-path> branch -D
   ```

**Leave untouched** — these are not safe to assume merged:
- `main` and the currently checked-out branch.
- Branches with **no** upstream (never pushed) — may be unpushed local work.
- Branches whose upstream **still exists** on the remote — an open or unmerged PR.

This is conservative by design: it removes only branches git can prove are merged-and-remote-deleted, so it is safe to run on every shipment.

---

### Step 9 — Report

Report to the developer:
- The PR URL.
- The local branches pruned in Step 8 (or "no merged branches to prune" if none qualified).

---

## Hard Rules

- Never force-push.
- Never push directly to `main` — always go through a branch and PR.
- Never cherry-pick merge commits.
- If any step fails, stop and report the exact error — do not retry silently with different flags.
- If the working tree has changes in unrelated files alongside the intended changes, stage only the relevant files and note what was left unstaged.
- Never delete `main` or the currently checked-out branch.
- Step 8 cleanup may force-delete only the branch this run just merged, or branches whose upstream is **gone** (merged + remote-deleted). Never force-delete a branch with a live upstream (open PR) or no upstream (unpushed local work).

---

## Repo Adaptations

This skill applies to any repo in the Service Delivery system, including the **central repo** (`service-delivery-central`). Branch protection requiring PRs is enforced on all four repos — the branch-and-PR path is always required, never a direct push.

**Central repo working directory:** `/Users/rrios/dev/ServiceDelivery/` (one level above the working repos). When invoked from the central repo, assess changes there — do not descend into `service-delivery-backend/`, `service-delivery-frontend/`, or `service-delivery-simulator/` subdirectories, as those are separate git repos.
