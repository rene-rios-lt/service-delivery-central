---
description: Audit all pipeline skills — per-file rating across 8 dimensions, strengths, weaknesses, cross-file inconsistencies and contradictions, and a prioritized improvement backlog.
---

# Skill: Audit Skills

## Purpose

Produce a structured, repeatable audit of every skill in the AI pipeline. Use this skill to assess overall quality, catch cross-file drift, and generate a prioritized backlog of improvements.

---

## Scope

Read every file in:

- `.claude/skills/*/SKILL.md` — all slash-command skills

This includes `audit-skills/SKILL.md` itself. Do not skip it. Do not summarise from memory — read the current file content each time.

---

## Structural Integrity Check

Before rating quality, verify that every skill file is structurally complete. A file missing a required section cannot be meaningfully rated on that section — record the gap and note the affected dimension scores as unreliable.

For each SKILL.md, check:

**Frontmatter:**
- `description:` field present and non-empty

**Required body sections:**
- `## Purpose`
- `## Repo Adaptations`

**Skill cross-references:** for each `.claude/skills/<name>/SKILL.md` reference anywhere in the file body, confirm the path resolves.

Report all gaps in a table before any per-file assessment:

| File | Gap |
|------|-----|
| `ac-coverage/SKILL.md` | Missing section: `## Repo Adaptations` |
| `tdd-cycle/SKILL.md` | Broken cross-reference: `.claude/skills/ac-coverge/SKILL.md` |

If no gaps: write `Structural integrity: all skill files pass.` and proceed.

Every structural gap is automatically added to the improvement backlog. Missing section: Low effort. Broken cross-reference: Low effort.

---

## Per-File Assessment

For every skill file, produce:

### Rating (1–10)

Score against the eight dimensions below. Report each dimension score, then the overall rating.

**Overall rating** = average of all eight dimension scores, **except**: if Security scores below 6, the overall rating is capped at 7 regardless of other scores. Security is a gate dimension.

One-line justification is required for every dimension score.

---

#### Dimension 1 — Completeness

*Does the skill cover every scenario, rule, and edge case it is responsible for governing?*

| Score | Signal |
|-------|--------|
| **9–10** | A senior practitioner (a reader with two or more years of production experience in the domain the skill governs) cannot identify a scenario the skill should govern but doesn't. All rules have explicit edge cases and exceptions stated. Cross-repo variations are addressed in a Repo Adaptations section wherever behaviour differs. |
| **7–8** | Most cases covered. One or two edge cases missing but low-frequency or low-impact. Repo Adaptations present but thin on one repo. |
| **5–6** | The common case is well-covered but exceptions and failure modes are largely absent. A reader following this skill would make wrong decisions on realistic edge cases. |
| **1–4** | Significant gaps that would cause incorrect behaviour on common scenarios. |

**Red flags (automatic −1 each):**
- A rule with no stated exceptions when exceptions clearly exist
- Cross-repo variation unaddressed where the rule differs across BE/FE/SIM
- A concept referenced but not defined within the skill or cross-referenced to where it is defined
- No Repo Adaptations section when the skill's rules differ by repo (every skill in this system is required to have one)
- Missing `description:` frontmatter field (required by CLAUDE.md for all skill files)

---

#### Dimension 2 — Executability

*Every rule resolves to a deterministic action. Language is unambiguous, all conditionals are fully stated, and a reader following this skill makes the same decisions every time.*

| Score | Signal |
|-------|--------|
| **9–10** | Every rule is specific enough to apply without interpretation. Every conditional has explicit criteria. No rule contains "as appropriate", "where relevant", or "use your judgment". Two agents reading this skill independently apply it identically to the same scenario. |
| **7–8** | Nearly all rules are specific. One or two soft conditionals that a trained reader resolves consistently. |
| **5–6** | Multiple rules require interpretation. Two readers would apply the skill differently in at least one scenario. |
| **1–4** | The skill reads as high-level guidance rather than actionable rules — application varies materially across readers. |

**Red flags (automatic −1 each):**
- "as appropriate", "where relevant", or "use your judgment" with no stated criterion
- A conditional with only one branch and no defined default
- A term used before it is defined
- A checklist item with no definition of what passing or failing it looks like

---

#### Dimension 3 — Internal Consistency

*The same term means the same thing throughout. Rules, thresholds, and vocabulary are uniform within the file.*

| Score | Signal |
|-------|--------|
| **9–10** | Every term, label, and threshold is used identically throughout. The skill's own examples follow the rules it teaches. |
| **7–8** | Minor phrasing differences that do not affect how the skill is applied. |
| **5–6** | The same concept is named differently in two sections, or a rule is stated with different thresholds in different sections, creating ambiguity about which takes precedence. |
| **1–4** | The skill contradicts itself — applying both versions of a rule simultaneously is impossible. |

**Red flags (automatic −1 each):**
- A term or label that differs from an earlier definition in the same file
- An example that violates a rule stated elsewhere in the same file
- A threshold or status value stated differently in the rule body vs the checklist

---

#### Dimension 4 — Scope Precision

*The skill covers exactly what it governs — no more, no less. Rules that belong in another skill are not duplicated here.*

| Score | Signal |
|-------|--------|
| **9–10** | Every section directly serves the skill's stated purpose. Rules that belong in another skill are cross-referenced, not restated. Assumptions about what the reader already knows are made explicit. |
| **7–8** | Occasional content that drifts slightly outside the skill's core responsibility, but additive and not conflicting with the governing file. |
| **5–6** | The skill either duplicates significant content from another skill (creating maintenance debt) or omits a large area it should govern. |
| **1–4** | The skill's scope is undefined or so broad it absorbs responsibilities from multiple other skills. |

**Red flags (automatic −1 each):**
- A rule fully restated from another skill without a cross-reference to that skill
- Backend-specific guidance presented as universal without a skip note for other repos
- An implicit assumption about system state or reader prior knowledge that is not documented

---

#### Dimension 5 — Cross-File Alignment

*Consistent with the vocabulary, conventions, and rules of every other skill and agent it will be read alongside. All dependencies are cross-referenced.*

| Score | Signal |
|-------|--------|
| **9–10** | Terminology matches every related file exactly. All skills and agents that depend on this one, or that this one depends on, are named and linked. Status values, severity levels, and naming conventions are identical to those used elsewhere in the pipeline. |
| **7–8** | Minor terminology differences that do not cause incorrect behaviour. One missing cross-reference to a low-dependency file. |
| **5–6** | Uses different terminology for a concept already defined elsewhere, or omits a cross-reference to a file that governs behaviour this skill relies on. |
| **1–4** | Directly conflicts with another skill or agent in the pipeline on a rule, term, or threshold. |

**Red flags (automatic −1 each):**
- A status value or severity label that differs from the definition in another governing file
- A missing cross-reference to a file this skill depends on or that depends on this skill
- A rule that contradicts the equivalent rule in a related skill or agent
- An API, type, or version name that no longer matches the current codebase or its package versions — e.g. an example using a renamed framework type or a tool version the repo has since moved past. A skill can be internally flawless yet teach a stale API; flag the drift against the real code/package, not just against other skills.

---

#### Dimension 6 — Conciseness

*Every sentence earns its place. The skill is as short as it can be while remaining complete.*

| Score | Signal |
|-------|--------|
| **9–10** | No sentence can be removed without losing information or precision. No rule is repeated across sections. Examples are present only where a rule is genuinely ambiguous without one. |
| **7–8** | Occasional restatement of a rule for emphasis, but not enough to meaningfully bloat the file. |
| **5–6** | Noticeable redundancy — the same rule appears in multiple sections, or explanations are provided for things the audience already knows. |
| **1–4** | The file is padded to the point where the signal is buried. A reader must work to extract the actionable content. |

**Red flags (automatic −1 each):**
- A rule restated verbatim in more than one section
- An explanation of WHY a rule exists when the reason is self-evident from context
- More than one example where a single example would suffice

> **Note on interaction with Teachability (Dimension 7):** explaining WHY is required when the reason is non-obvious — Teachability demands it. Conciseness only penalises explaining WHY when the reason is already self-evident. The two dimensions do not conflict.

---

#### Dimension 7 — Teachability

*The skill conveys enough underlying principle that a reader can apply its rules correctly to scenarios not explicitly listed — not just follow a checklist.*

Skills are read as reference material. An agent that reads a skill needs to do more than pattern-match against the listed cases — it needs to understand the model well enough to handle novel situations correctly. A skill that only states WHAT (do X, never Y) without WHY (because...) leaves the reader unable to extrapolate.

| Score | Signal |
|-------|--------|
| **9–10** | Every non-obvious rule includes the principle behind it. A reader can derive the correct answer for a scenario not explicitly listed by reasoning from the principles stated. Exceptions are explained with the reasoning that defines the boundary — so readers can identify other valid exceptions, not just the listed ones. |
| **7–8** | Most rules include their rationale. One or two rules are stated without a principle, but the principle is inferable from surrounding context. |
| **5–6** | Rules are mostly prescriptive without rationale. A reader following this skill mechanically handles listed cases correctly but guesses on novel cases. |
| **1–4** | The skill is a bare checklist. No underlying model is conveyed. Readers cannot extrapolate beyond the explicit examples. |

**Red flags (automatic −1 each):**
- A rule with exceptions but no principle that defines what makes an exception valid
- A prescriptive list with no stated common thread that explains why these items belong together
- "Always do X" or "Never do Y" with no accompanying reasoning that would help identify boundary cases
- An exception stated without explaining why it does not violate the rule's principle

> **Note on overlap with Completeness (Dimension 1):** a missing principle can trigger red flags in both dimensions — Completeness if the gap prevents correct application to known cases, Teachability if it prevents extrapolation to novel ones. When both apply, assign the finding to the dimension whose definition most specifically describes the gap.

> **Scoring guidance:** to apply this dimension, construct two scenarios not explicitly listed in the skill — one typical and one boundary case. Ask: does reasoning from the skill's stated principles produce the correct answer for each, without requiring rules not present in the file? If yes, score 9–10. If the typical case is answerable but the boundary case requires guessing, score 7–8.

---

#### Dimension 8 — Security

*The skill does not instruct dangerous behaviour — no destructive git operations without guards, no bypassing confirmation prompts or hooks, no self-approval.*

Skills propagate to every agent and developer session that reads them. A security flaw in a skill is more severe than the same flaw in an agent — it affects all consumers.

| Score | Signal |
|-------|--------|
| **9–10** | Every instruction involving an irreversible action (commit, push, file deletion, branch deletion) is preceded by an explicit confirmation condition. No instruction leads to `--force`, `--no-verify`, or a direct push to `main` without explicit developer authorisation. No self-approval path exists. |
| **7–8** | One irreversible action with a weak but present guard. |
| **5–6** | One irreversible action with no guard, or an instruction that a reader could follow into a destructive outcome without recognising it. |
| **1–4** | The skill instructs destructive behaviour without safeguards. |

**Red flags (automatic −2 each — security issues are weighted double):**
- An irreversible action (force-push, branch delete, direct main commit) with no guard
- An instruction that could cause `--no-verify` or `--force` without explicit developer authorisation
- A self-approval path — the skill instructs Claude to approve its own output on behalf of the developer

> **Gate rule (Security):** if Security scores below 6, the overall rating is capped at 7 regardless of all other scores.

---

### Strengths

What the skill does well — specific, not generic. "Rules are clear" is weak; "The AC mapping table enforces a five-column format that makes gaps immediately visible during review" is strong.

### Weaknesses

Gaps, ambiguities, missing edge cases, backend-centric bias, missing Repo Adaptations, or missing cross-references. Be specific: cite the section or rule.

---

## Cross-File Analysis

After assessing all skill files individually, produce three sections:

### Inconsistencies

The same concept defined or described differently across skills.

Format:
```
- **[Term/Concept]** — Skill A says X; Skill B says Y. Suggested resolution: <which should win and why>.
```

### Contradictions

Two skills that give conflicting rules for the same scenario — following both simultaneously is impossible.

Format:
```
- **[Scenario]** — Skill A instructs X; Skill B instructs Y. These cannot both be followed. Suggested resolution: <which should win and why>.
```

### Missing Cross-References

Skills that govern related territory but do not reference each other, creating a risk that a reader applies one without knowing the other governs part of the same domain.

Format:
```
- Skill A and Skill B both govern [topic] but neither references the other. Add: [specific cross-reference text].
```

---

## Self-Audit

After completing the standard per-file assessments and cross-file analysis, apply all eight dimensions specifically to this file (`audit-skills/SKILL.md`) and answer the following questions directly:

1. **Completeness** — Are there skill patterns or structures this audit would fail to catch? Are there gaps in what the dimensions cover?
2. **Executability** — Could two auditors score the same skill file and land within 1 point on every dimension? If not, which dimension definitions are too vague?
3. **Internal Consistency** — Do any two dimensions penalise the same flaw twice? Do any two dimensions give conflicting guidance?
4. **Scope Precision** — Does this skill stay in its lane — assessing, not fixing? Does it avoid telling the auditor what the correct fix is (that belongs in the improvement backlog)?
5. **Cross-File Alignment** — Does this skill's vocabulary (dimension names, severity labels, output format) match `audit-agents/SKILL.md`? Are the two audit skills diverging?
6. **Conciseness** — Is any dimension definition longer than it needs to be to produce consistent scoring?
7. **Teachability** — Does this skill explain enough about WHY each dimension matters that an auditor can score a novel skill type it has never seen before?
8. **Security** — Does this skill instruct any dangerous behaviour?

Report findings from the self-audit in the improvement backlog alongside findings from the standard run. Label them `[Self-audit]` so they are distinguishable.

---

## Prioritized Improvement Backlog

Collect all findings — per-file weaknesses, cross-file issues, and self-audit findings — into a single ranked table:

| # | File(s) | Finding | Suggested fix | Effort |
|---|---------|---------|---------------|--------|
| 1 | ... | ... | ... | Low / Med / High |

Rank by impact first (does this cause a reader to apply the rule incorrectly?), then by effort within the same impact tier.

Effort definitions:
- **Low** — a sentence or two added or changed; no structural rework
- **Med** — a new section, a restructured rule set, or changes across 2–3 files
- **High** — a significant rewrite, a new concept introduced, or changes across 4+ files

---

## Output Order

1. Structural integrity check results
2. Per-file assessments (alphabetical by skill folder name — includes `audit-skills/SKILL.md`)
3. Cross-file analysis (Inconsistencies → Contradictions → Missing Cross-References)
4. Self-audit findings for this file specifically
5. Prioritized improvement backlog (per-file + cross-file + self-audit + structural findings combined)
6. Overall system rating — average of all per-file scores, one paragraph summary

---

## Hard Rules

- Read every file fresh — do not use cached assessments from a prior run of this skill.
- Do not conflate inconsistency with contradiction. An inconsistency is a mismatch in wording; a contradiction makes it impossible to follow both files simultaneously.
- Do not suggest improvements outside the scope of what the skill governs.
- Suggestions must be specific enough to act on. "Improve clarity" is not a suggestion. "Add a skip note to the SignalR step for Simulator stories, which have no SignalR events" is.
- When scoring Teachability, judge the skill against novel scenarios in its domain — not just whether examples are present. A skill with many examples but no principles still scores low.
- The self-audit must be honest. If this skill has gaps, they appear in the improvement backlog. Do not soften findings because they apply to the auditor itself.
- For the equivalent audit of agent files, see `.claude/skills/audit-agents/SKILL.md`.

---

## Repo Adaptations

This skill applies in the **central repo only** (`service-delivery-central`). Skill files live in `.claude/skills/` at the central repo root. The working repos (backend, frontend, simulator) contain no SKILL.md files and are not in scope for this audit.
