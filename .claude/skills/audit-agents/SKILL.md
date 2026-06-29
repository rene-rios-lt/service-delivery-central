---
description: Audit all pipeline agents — per-file rating across 9 dimensions, strengths, weaknesses, cross-file inconsistencies, contradictions, and a prioritized improvement backlog.
---

# Skill: Audit Agents

## Purpose

Produce a structured, repeatable audit of every agent in the AI pipeline. Use this skill to assess overall quality, catch cross-file drift, and generate a prioritized backlog of improvements.

---

## Scope

Read every file in:

- `.claude/agents/*/AGENT.md` — all pipeline agents

Do not skip any file. Do not summarise from memory — read the current file content each time.

---

## Structural Integrity Check

Before rating quality, verify that every agent file is structurally complete. A file missing a required section cannot be meaningfully rated on that section — record the gap and note the affected dimension scores as unreliable.

For each AGENT.md, check:

**Frontmatter:**
- `name:` field present and non-empty (kebab-case, matches the agent folder)
- `description:` field present and non-empty
- `tools:` field present and non-empty

**Required body sections:**
- Top-level heading (`# <Name>`) followed by a persona paragraph
- `## Required Reading`
- `## Inputs`
- `## Audit Output`
- `## Process`
- `## Output Format`

**Required Reading paths:** for each path listed under `## Required Reading`, strip the leading `../` and confirm the file exists from the central repo root (e.g. `../.claude/skills/tdd-cycle/SKILL.md` → `.claude/skills/tdd-cycle/SKILL.md`).

**Skill cross-references:** for each `.claude/skills/<name>/SKILL.md` reference anywhere in the file body, confirm the path resolves.

Report all gaps in a table before any per-file assessment:

| File | Gap |
|------|-----|
| `story-evaluator/AGENT.md` | Missing section: `## Output Format` |
| `story-planner/AGENT.md` | Unresolvable Required Reading: `../.claude/skills/ac-coverge/SKILL.md` |

If no gaps: write `Structural integrity: all agent files pass.` and proceed.

Every structural gap is automatically added to the improvement backlog. Missing section: Low effort. Broken path: Low effort.

---

## Per-File Assessment

For every agent file, produce:

### Rating (1–10)

Score against the nine dimensions below. Report each dimension score, then the overall rating.

**Overall rating** = average of all nine dimension scores, **except**: if Security or Subagent Compatibility scores below 6, the overall rating is capped at 7 regardless of other scores. Both are gate dimensions.

One-line justification is required for every dimension score.

---

#### Dimension 1 — Completeness

*Does the file handle every scenario, edge case, failure mode, and cross-repo variation it is responsible for?*

| Score | Signal |
|-------|--------|
| **9–10** | A senior practitioner cannot identify an unhandled path. All edge cases, failure modes, and exceptional conditions are addressed. Boundary conditions (missing files, ambiguous input, prior failed runs) are explicit. |
| **7–8** | Most cases covered. One or two edge cases are missing but they are low-frequency or low-impact. |
| **5–6** | The happy path is well-covered but failure modes are largely absent. The agent would break or behave unpredictably on realistic inputs it doesn't handle. |
| **1–4** | Significant gaps that would cause incorrect or undefined behaviour on common inputs. |

**Red flags (automatic −1 each):**
- No error path defined for a step that can fail
- Cross-repo variation (BE/FE/SIM) unaddressed where agent behaviour differs
- A step that says "as needed" or "if applicable" with no criteria for when it applies
- Any of the six required sections missing: Persona, Required Reading, Inputs, Audit Output, Process, Output Format
- Missing `description:` or `tools:` frontmatter fields

---

#### Dimension 2 — Executability

*Every instruction resolves to a deterministic action. Language is unambiguous, control flow is fully branched, and no step leaves an agent to choose between valid paths.*

This dimension unifies two concerns that fail together:
- **Language precision** — instructions are specific enough that two agents reading the file independently behave identically
- **Control flow completeness** — every conditional has explicit criteria; every branch terminates; every optional step has a stated trigger condition

| Score | Signal |
|-------|--------|
| **9–10** | Every instruction is specific enough to auto-execute. Every conditional has exact criteria. Every optional step states when it applies. No instruction contains "as appropriate", "where relevant", or "use your judgment". A cold-start agent with no prior context runs this file to completion without guessing. |
| **7–8** | Nearly all branch points are explicit. One or two soft conditionals that a trained agent would resolve consistently across runs. |
| **5–6** | Multiple instructions require interpretation. Two agents would diverge at one or more decision points. Vague conditionals appear without criteria. |
| **1–4** | The file reads as guidelines rather than a procedure — execution varies materially across agents and runs. |

**Red flags (automatic −1 each):**
- "use your judgment", "as appropriate", or "where relevant" with no definition of when the condition is met
- A conditional with only one branch and no defined default for the other case
- "if applicable" or "as needed" without a stated applicability criterion
- A term used before it is defined in the file
- An example that contradicts the rule it illustrates
- A Persona that creates the wrong mindset for the agent's pipeline role — e.g. a "collaborative helper" framing on a skeptical reviewer, or a "neutral analyst" framing on an agent whose job is to block non-compliant work

---

#### Dimension 3 — Internal Consistency

*The same term means the same thing throughout. Numbering, severity levels, status values, and vocabulary are uniform within the file.*

| Score | Signal |
|-------|--------|
| **9–10** | Every term, label, status value, and severity level is used identically throughout. Step numbering is correct and sequential. The file's own examples follow the rules it teaches. |
| **7–8** | Minor inconsistencies in phrasing that do not affect agent behaviour. |
| **5–6** | The same concept is named differently in two sections, or a rule is stated with different thresholds in different sections, creating ambiguity about which takes precedence. |
| **1–4** | The file actively contradicts itself — following both instructions simultaneously is impossible. |

**Red flags (automatic −1 each):**
- A step number that is out of sequence or duplicated
- A status value or severity label that differs from an earlier definition in the same file
- An example that violates a rule stated elsewhere in the same file

---

#### Dimension 4 — Scope Precision

*The file covers exactly what this agent governs — no more, no less. No content belongs in a different file. No implicit assumptions go unstated.*

| Score | Signal |
|-------|--------|
| **9–10** | Every section directly serves the agent's stated purpose. Content that belongs in a skill file is not duplicated here — it is cross-referenced instead. Assumptions about context are explicitly stated. |
| **7–8** | Occasional content that drifts slightly outside the agent's core responsibility, but it is additive and does not conflict with the governing skill. |
| **5–6** | The file either duplicates significant content from a skill (creating maintenance debt) or omits a large area it should govern. |
| **1–4** | The file's scope is undefined or so broad that it absorbs responsibilities from other agents or skills. |

**Red flags (automatic −1 each):**
- A rule that is fully restated from a skill without a cross-reference to that skill
- Backend-specific guidance presented as universal without a skip note for other repos
- An implicit assumption about system state that is not documented
- A process step that performs work belonging to an adjacent pipeline stage (e.g. the Planner writing production code, the Implementor producing a PR)

---

#### Dimension 5 — Cross-File Alignment

*Consistent with the vocabulary, conventions, and rules of every skill and agent it will be read alongside. All dependencies are cross-referenced.*

| Score | Signal |
|-------|--------|
| **9–10** | Terminology matches every related file exactly. All skills this agent depends on are named and linked in Required Reading. Status values, severity levels, and naming conventions are identical to those used elsewhere in the pipeline. |
| **7–8** | Minor terminology differences that do not cause incorrect behaviour. One missing cross-reference to a low-dependency file. |
| **5–6** | Uses different terminology for a concept already defined in a skill, or omits a cross-reference to a skill that governs behaviour this agent relies on. |
| **1–4** | Directly conflicts with another agent or skill in the pipeline on a rule, term, or process step. |

**Red flags (automatic −2 each — silent context loss is weighted double):**
- A skill that governs behaviour this agent relies on but is absent from Required Reading — the subagent will never read it and will produce wrong output with no error

**Red flags (automatic −1 each):**
- A status value or severity label that differs from the definition in the governing skill
- A process step that contradicts the equivalent step in a related agent or skill
- A cross-reference that names a skill or agent by the wrong path or folder name
- An API, type, or version name that no longer matches the current codebase or its package versions — e.g. an example or instruction naming a renamed framework type or a tool version the repo has since moved past. An agent can be internally flawless yet drive a stale API; flag the drift against the real code/package, not just against other files.

---

#### Dimension 6 — Conciseness

*Every sentence earns its place. The file is as short as it can be while remaining complete.*

| Score | Signal |
|-------|--------|
| **9–10** | No sentence can be removed without losing information or precision. No rule is repeated across sections. Examples are present only where a rule is genuinely ambiguous without one. |
| **7–8** | Occasional restatement of a rule for emphasis, but not enough to meaningfully bloat the file. |
| **5–6** | Noticeable redundancy — the same rule appears in multiple sections, or explanations are provided for things the audience already knows. Reading time is materially longer than it needs to be. |
| **1–4** | The file is padded to the point where the signal is buried. A reader must work to extract the actionable content. |

**Red flags (automatic −1 each):**
- A rule restated verbatim in more than one section
- An explanation of WHY a rule exists when the reason is self-evident from context
- More than one example where a single example would suffice

> **Note on interaction with Teachability (Dimension 7):** explaining WHY is required when the reason is non-obvious — Teachability demands it. Conciseness only penalises explaining WHY when the reason is already self-evident. The two dimensions do not conflict.

---

#### Dimension 7 — Output Contract

*The agent's outputs are precisely specified: exact file path, required fields, result vocabulary, and what the next pipeline stage is entitled to assume without reading this file.*

| Score | Signal |
|-------|--------|
| **9–10** | Every output is named (file path, required fields, result states). The vocabulary of result values is enumerated (e.g. READY / BLOCKED / APPROVED). A downstream agent or Master can be written against this contract without reading this agent's process steps. |
| **7–8** | Most outputs are specified. One field or result state is implied rather than declared, but inferrable without reading the process steps. |
| **5–6** | The agent produces output but the format is loosely described. A downstream consumer must read this agent's process steps to know what to expect. |
| **1–4** | No output contract. Downstream stages depend on informal convention that could change silently. |

**Red flags (automatic −1 each):**
- An output file path that is not stated explicitly
- A result state used by a downstream file (e.g. Master) but not defined or enumerated here
- Required fields described in prose ("include the findings") rather than as a named list
- No distinction between required and optional output fields

---

#### Dimension 8 — Security

*Least-privilege tool access, prompt injection guards present, no paths to destructive behaviour through adversarial or accidental input.*

| Score | Signal |
|-------|--------|
| **9–10** | `tools` is minimal — no tool listed that isn't required by a named process step. Prompt injection guard is present and correctly scoped. Irreversible actions (commit, push, PR creation, file deletion) are preceded by an explicit confirmation condition. No path through the file leads to `--force`, `--no-verify`, or a direct push to `main`. |
| **7–8** | One excess tool in `tools` or one irreversible action with a weak but present guard. No injection surface unaddressed. |
| **5–6** | Missing prompt injection guard on a file that reads external content, or one irreversible action with no guard. `tools` contains tools that serve no documented step. |
| **1–4** | The file can be trivially manipulated into a destructive action, or `tools` grants broad access (e.g. unrestricted Bash) without justification. |

**Red flags (automatic −2 each — security issues are weighted double):**
- No prompt injection guard on an agent that reads story files, diffs, or review packages
- An irreversible action (force-push, branch delete, direct main commit) with no guard
- `Bash` in `tools` without a documented step that requires it
- Any instruction that could cause `--no-verify` or `--force` without explicit developer authorisation

> **Gate rule (Security):** if Security scores below 6, the overall rating is capped at 7 regardless of all other scores.

---

#### Dimension 9 — Subagent Compatibility

*The file makes no assumptions about capabilities, state, or context that a Claude Code subagent does not have.*

Subagents run in isolated context windows. Each invocation starts clean — no memory of prior conversations, no access to the main conversation history, no ability to address the user directly. Instructions that assume otherwise fail silently at runtime with no error.

| Score | Signal |
|-------|--------|
| **9–10** | Every instruction is compatible with a clean-context, isolated subagent. No assumed prior state. All context the agent needs is either in Required Reading or passed as explicit named Inputs. Output is addressed to the orchestrator, not the user. Every tool called in a process step appears in `tools`. |
| **7–8** | One minor assumption that a well-configured invocation would satisfy — e.g. an implicit reference to the story ID that is passed as an input even if not explicitly named as such. |
| **5–6** | One or more instructions that silently fail for subagents: assumes prior context, asks the user a question directly, or calls a tool not in `tools`. |
| **1–4** | The file fundamentally cannot execute as a subagent — it requires conversational context, user interaction, or capabilities that isolated subagents do not have. |

**Red flags (automatic −2 each — silent runtime failures are weighted double):**
- "refer back to your earlier [decision / analysis / output]" — subagents have no prior context
- Any instruction to "ask the user", "confirm with the developer", or "wait for input"
- A tool called in a process step that is absent from `tools`
- Context assumed from a prior agent that is not listed as an explicit named Input
- An instruction that depends on the subagent knowing which story or repo it is operating in, when that is not passed as an explicit input
- Missing `tools:` frontmatter — tool access is unconstrained at load time, making the agent's actual tool scope undefined

> **Gate rule (Subagent Compatibility):** if Subagent Compatibility scores below 6, the overall rating is capped at 7 regardless of all other scores. A file that cannot execute as a subagent is not fit for purpose.

---

### Strengths

What the agent does well — specific, not generic. "Process is clearly defined" is weak; "Check 0 gates the entire review on a passing test suite before any other check runs" is strong.

### Weaknesses

Gaps, ambiguities, missing coverage, backend-centric bias, undefined edge cases, stale phrasing, or missing cross-references. Be specific: cite the section or step number.

---

## Cross-File Analysis

After assessing all agent files individually, produce three sections:

### Inconsistencies

The same concept defined or described differently across agents. Examples: a status value named differently in two agents, a rule stated with different thresholds, a term used in two different ways.

Format:
```
- **[Term/Concept]** — Agent A says X; Agent B says Y. Suggested resolution: <which should win and why>.
```

### Contradictions

Two agents that give conflicting instructions for the same scenario — following both simultaneously is impossible.

Format:
```
- **[Scenario]** — Agent A instructs X; Agent B instructs Y. These cannot both be followed. Suggested resolution: <which should win and why>.
```

### Missing Cross-References

Agents that govern related territory but do not reference each other or the relevant skill, creating a risk that a reader follows one without knowing the other exists.

Format:
```
- Agent A and Agent B (or Skill X) both govern [topic] but neither references the other. Add: [specific cross-reference text].
```

---

## Self-Audit

After completing the standard per-file assessments and cross-file analysis, apply all nine dimensions specifically to this file (`audit-agents/SKILL.md`) and answer the following questions directly:

1. **Completeness** — Are there agent patterns or structures this audit would fail to catch? Are there gaps in what the nine dimensions cover?
2. **Executability** — Could two auditors score the same agent file and land within 1 point on every dimension? If not, which dimension definitions are too vague?
3. **Internal Consistency** — Do any two dimensions penalise the same flaw twice? Do any two dimensions give conflicting guidance?
4. **Scope Precision** — Does this skill stay in its lane — assessing, not fixing? Does it avoid telling the auditor what the correct fix is (that belongs in the improvement backlog)?
5. **Cross-File Alignment** — Does this skill's vocabulary (dimension names, severity labels, output format) match `audit-skills/SKILL.md`? Are the two audit skills diverging?
6. **Conciseness** — Is any dimension definition longer than it needs to be to produce consistent scoring?
7. **Teachability** — Does this skill explain enough about WHY each dimension matters that an auditor can score a novel agent type it has never seen before?
8. **Security** — Does this skill instruct any dangerous behaviour?
9. **Subagent Compatibility** — Are there subagent-specific patterns this audit's Subagent Compatibility dimension would fail to catch in a novel agent type?

Report findings from the self-audit in the improvement backlog alongside findings from the standard run. Label them `[Self-audit]` so they are distinguishable.

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

1. Structural integrity check results
2. Per-file assessments (alphabetical by agent folder name)
3. Cross-file analysis (Inconsistencies → Contradictions → Missing Cross-References)
4. Self-audit findings for this file specifically
5. Prioritized improvement backlog (per-file + cross-file + self-audit + structural findings combined)
6. Overall system rating — average of all per-file scores, one paragraph summary

---

## Hard Rules

- Read every file fresh — do not use cached assessments from a prior run of this skill.
- Do not conflate inconsistency with contradiction. An inconsistency is a mismatch in wording; a contradiction makes it impossible to follow both files simultaneously.
- Do not suggest improvements outside the scope of what the agent governs. An agent that covers implementation should not be criticised for not covering PR creation.
- Suggestions must be specific enough to act on. "Improve clarity" is not a suggestion. "Add a definition of 'behavioral finding' vs 'structural finding' to the When Sent Back section" is.
- For the equivalent audit of skill files, see `.claude/skills/audit-skills/SKILL.md`.

---

## Repo Adaptations

This skill applies in the **central repo only** (`service-delivery-central`). Agent files live in `.claude/agents/` at the central repo root. The working repos (backend, frontend, simulator) contain no AGENT.md files and are not in scope for this audit. (The one exception: the Cross-File Alignment staleness red flag may require reading a working repo to confirm an API/type/version an agent cites against the real code or package — those repos still hold no AGENT.md, so this is a read-only spot-check, not an audit of their contents.)
