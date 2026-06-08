---
description: Validates all pipeline AGENT.md and SKILL.md files for required sections, resolvable Required Reading paths, and intact cross-references. Run before and after any agent or skill edit to catch drift before a story run.
---

# Skill: Validate Pipeline

## Purpose

Detect pipeline drift before a story run discovers it. A broken Required Reading path, a missing `## Output Format` section, or a cross-reference pointing to a renamed skill folder will not produce a visible error — the agent silently skips the missing content or fills the gap with unconstrained output. This skill makes those failures visible and actionable.

Run this skill before and after any edit to an AGENT.md or SKILL.md file.

---

## Process

### Step 1 — Locate all pipeline files

Run from the central repo root (`service-delivery-central/`):

```bash
find .claude/agents -name "AGENT.md" | sort
find .claude/skills -name "SKILL.md" | sort
```

Record the full list. Any agent folder that contains no AGENT.md, and any skill folder that contains no SKILL.md, is itself a **Structural Gap** — record it.

---

### Step 2 — Check each AGENT.md for required sections

For each AGENT.md, verify the following are present:

**Frontmatter (YAML block at the top of the file):**
- `description:` — non-empty string
- `allowed-tools:` — non-empty list

**Body sections (must exist as Markdown headers):**
- A top-level heading (`# <Name>`) followed by a persona paragraph — describes who the agent is and how it approaches its work
- `## Required Reading`
- `## Inputs`
- `## Audit Output`
- `## Process`
- `## Output Format`

Flag each missing field or section as a **Structural Gap** citing the file and the missing item.

---

### Step 3 — Check each SKILL.md for required sections

For each SKILL.md, verify:

**Frontmatter:**
- `description:` — non-empty string

**Body sections:**
- `## Purpose`
- `## Repo Adaptations`

Flag each missing field or section as a **Structural Gap**.

---

### Step 4 — Verify Required Reading paths

For each AGENT.md, read the `## Required Reading` section. For every path listed (e.g. `../.claude/skills/tdd-cycle/SKILL.md`):

1. Strip the leading `../` — agent paths are written relative to the working repo, where `../` resolves to the central repo root. The resulting path is relative to the central repo root (e.g. `.claude/skills/tdd-cycle/SKILL.md`).
2. Check that the file exists:

```bash
ls .claude/skills/tdd-cycle/SKILL.md
```

3. If the file does not exist, flag it as an **Unresolvable Path**, citing the agent file and the verbatim path string from Required Reading.

---

### Step 5 — Verify skill cross-references in SKILL.md files

Scan all SKILL.md files for inline references to other skill files. Look for patterns like:
- `.claude/skills/<name>/SKILL.md`
- `../.claude/skills/<name>/SKILL.md`
- `[[name]]` — a named cross-reference slug

For each reference, confirm the named skill folder exists and contains a SKILL.md. If either is missing, flag it as a **Broken Cross-Reference**.

---

### Step 6 — Verify audit file numbering

For each AGENT.md, read its `## Audit Output` section. If it declares an audit file (not `None`):

1. Confirm the file number matches the expected stage:
   - `01-evaluation.md` → story-evaluator
   - `02-plan.md` → story-planner
   - `03-ai-review.md` → story-ai-reviewer
   - `04-pr.md` → story-pr
2. Confirm no two agents declare the same audit file name.

Flag mismatches or collisions as **Audit File Conflicts**.

---

### Step 7 — Report

**If no findings:**

```
Pipeline validation passed — no structural gaps, unresolvable paths, broken cross-references, or audit file conflicts.
```

**If findings exist:**

```
PIPELINE VALIDATION FAILED

Structural Gaps:
  story-evaluator/AGENT.md — missing section: ## Output Format
  audit-agents/SKILL.md — missing frontmatter field: description

Unresolvable Paths:
  story-planner/AGENT.md — ../.claude/skills/ac-coverge/SKILL.md → NOT FOUND (typo?)

Broken Cross-References:
  tdd-cycle/SKILL.md — .claude/skills/ac-overage/SKILL.md → NOT FOUND

Audit File Conflicts:
  none

Summary: 2 structural gaps · 1 unresolvable path · 1 broken cross-reference · 0 conflicts
All findings must be resolved before running /master.
```

---

## Hard Rules

- A Structural Gap in any AGENT.md is a blocker — do not run `/master` until resolved. An agent missing `## Output Format` or `## Process` will produce unpredictable, inconsistent output with no warning.
- An Unresolvable Required Reading path means the agent silently skips that discipline at runtime — no error, just unconstrained output in place of enforced rules.
- Broken cross-references mislead readers and create silent coverage gaps in AI Review. Fix them before any audit run.
- After editing a file, re-read it before reporting clean — confirm the change actually saved before declaring validation passed.

---

## Repo Adaptations

This skill applies in the **central repo only** (`service-delivery-central`). The working repos (backend, frontend, simulator) contain no AGENT.md or SKILL.md files.

All paths in Step 1 resolve from the central repo root without modification. The `../` prefix in Required Reading paths exists because agents run from inside a working repo where `../` points up to the central repo root. When validating from the central repo, strip that prefix before checking.
