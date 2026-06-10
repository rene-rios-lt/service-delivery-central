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

### Step 1 — Assess current state

```bash
git status
git diff --stat
git log --oneline origin/main..HEAD
```

Identify what is pending:
- **Unstaged or staged changes** — files modified but not yet committed
- **Committed-but-unpushed commits** — commits on local `main` ahead of `origin/main`
- **Both** — mixed state; handle each in order (commit first, then push)

If the working tree is clean and there are no unpushed commits, report: `Nothing to ship — working tree is clean and local main is in sync with origin.` and stop.

---

### Step 2 — Derive branch name and commit message

Read the changed files and diffs to understand what the changes do. Do not ask the developer — infer from content.

**Branch name:** `<type>/<short-kebab-description>`
- Types: `feat`, `fix`, `refactor`, `docs`, `chore`
- Example: `refactor/validate-ai-system-terminology`

**Commit message:**
- Subject line: `<type>: <imperative summary>`
- Body: 1–2 sentences of context if needed (skip if the subject is self-explanatory)
- Always append: `Co-Authored-By: Claude Code <noreply@anthropic.com>`

---

### Step 3 — Create the feature branch

```bash
git checkout -b <branch-name> origin/main
```

If pending changes include already-committed local commits (ahead of origin/main), bring them onto the new branch:

```bash
git cherry-pick <sha> [<sha> ...]
```

Skip merge commits when cherry-picking. If committed changes include only the target commit and no unpushed file edits, proceed directly to Step 4.

If there are uncommitted file changes, they carry over automatically when the branch is created from `origin/main`. Stage and commit them:

```bash
git add <files>
git commit -m "..."
```

---

### Step 4 — Push

```bash
git push -u origin <branch-name>
```

---

### Step 5 — Open PR

```bash
gh pr create \
  --title "<type>: <summary>" \
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
gh pr merge --merge --delete-branch
```

---

### Step 7 — Sync local main

```bash
git checkout main
git pull
```

Report the PR URL to the developer.

---

## Hard Rules

- Never force-push.
- Never push directly to `main` — always go through a branch and PR.
- Never cherry-pick merge commits.
- If any step fails, stop and report the exact error — do not retry silently with different flags.
- If the working tree has changes in unrelated files alongside the intended changes, stage only the relevant files and note what was left unstaged.

---

## Repo Adaptations

This skill applies to any repo in the Service Delivery system, including the **central repo** (`service-delivery-central`). Branch protection requiring PRs is enforced on all four repos — the branch-and-PR path is always required, never a direct push.

**Central repo working directory:** `/Users/rrios/dev/ServiceDelivery/` (one level above the working repos). When invoked from the central repo, assess changes there — do not descend into `service-delivery-backend/`, `service-delivery-frontend/`, or `service-delivery-simulator/` subdirectories, as those are separate git repos.
