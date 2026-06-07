---
description: Audit all agents and skills — per-file rating, strengths, weaknesses, cross-file inconsistencies and contradictions, and a prioritized improvement backlog.
---

# Skill: Audit Pipeline

## Purpose

Produce a structured, repeatable audit of every agent and skill in the AI pipeline. Use this skill to assess overall quality, catch cross-file drift, and generate a prioritized backlog of improvements.

---

## Scope

Read every file in these directories:

- `.claude/agents/*/AGENT.md` — all pipeline agents
- `.claude/skills/*/SKILL.md` — all slash-command skills

Do not skip any file. Do not summarise from memory — read the current file content each time.

---

## Per-File Assessment

For every file, produce:

### Rating (1–10)

Score against these five dimensions, then average:

| Dimension | What it measures |
|-----------|-----------------|
| **Completeness** | Does it cover all the scenarios it needs to? Are edge cases handled? |
| **Clarity** | Are instructions unambiguous? Could two agents read this and behave differently? |
| **Internal consistency** | Does the file contradict itself? Are terms used consistently throughout? |
| **Scope precision** | Is the file appropriately scoped — not too broad, not missing relevant territory? |
| **Cross-file alignment** | Does it align with the conventions, terminology, and cross-references the rest of the pipeline uses? |

Report the average as the file's rating. One-line justification is required.

### Strengths

What the file does well — specific, not generic. "Process is clearly defined" is weak; "Check 0 gates the entire review on a passing test suite before other checks run" is strong.

### Weaknesses

Gaps, ambiguities, missing coverage, backend-centric bias, undefined edge cases, stale phrasing, or missing cross-references. Be specific: cite the section or line.

---

## Cross-File Analysis

After assessing all files individually, produce three sections:

### Inconsistencies

The same concept defined or described differently across files. Examples: a status value named differently in two files, a rule stated with different thresholds, a term used in two different ways.

Format:
```
- **[Term/Concept]** — File A says X; File B says Y. Suggested resolution: <which should win and why>.
```

### Contradictions

Two files that give conflicting instructions for the same scenario — following both simultaneously is impossible.

Format:
```
- **[Scenario]** — File A instructs X; File B instructs Y. These cannot both be followed. Suggested resolution: <which should win and why>.
```

### Missing Cross-References

Files that govern related territory but do not reference each other, creating a risk that an agent reads one without knowing the other exists.

Format:
```
- File A and File B both govern [topic] but neither references the other. Add: [specific cross-reference text].
```

---

## Prioritized Improvement Backlog

Collect all findings — per-file weaknesses plus cross-file issues — into a single ranked table:

| # | File(s) | Finding | Suggested fix | Effort |
|---|---------|---------|---------------|--------|
| 1 | ... | ... | ... | Low / Med / High |

Rank by impact first (does this cause incorrect agent behaviour?), then by effort (low-effort wins go first within the same impact tier).

Effort definitions:
- **Low** — a sentence or two added or changed; no structural rework
- **Med** — a new section, a restructured process, or changes across 2–3 files
- **High** — a significant rewrite, a new concept introduced, or changes across 4+ files

---

## Output Order

1. Per-file assessments (agents first, then skills, alphabetical within each group)
2. Cross-file analysis (Inconsistencies → Contradictions → Missing Cross-References)
3. Prioritized improvement backlog
4. Overall system rating — average of all per-file scores, one paragraph summary

---

## Hard Rules

- Read every file fresh — do not use cached assessments from a prior run of this skill.
- Do not conflate inconsistency with contradiction. An inconsistency is a mismatch in wording; a contradiction makes it impossible to follow both files simultaneously.
- Do not suggest improvements outside the scope of what the file governs. A skill that covers TDD should not be criticised for not covering clean architecture.
- Suggestions must be specific enough to act on. "Improve clarity" is not a suggestion. "Add a definition of 'behavioral finding' vs 'structural finding' to the When Sent Back section" is.
