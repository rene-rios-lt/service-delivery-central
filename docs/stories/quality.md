# Engineering-Quality Stories (`QUAL-`)

> Cross-cutting enhancements to the AI pipeline and engineering practice — not feature work for a single product repo. Tracked in [`execution-plan.md`](execution-plan.md) under **Cross-Cutting — Engineering Quality**. Central skill/agent changes ship via `/ship-it` (the `/master` pipeline never targets the central repo); any product-repo code changes (e.g. a test-suite audit's fixes) go through `/master`.

---

## QUAL-001 — Catch "masking" tests in AI Review (strengthen `/test-quality`)

**As a** maintainer of the TDD pipeline,
**I want** the AI Reviewer to flag tests that pass by coincidence — placeholder reuse, or mirroring the production code's own wrong assumption — and to lean on integration runs for cross-process contracts,
**so that** wire/identity-contract bugs can't hide behind a green unit suite.

**Motivation**
`BUG-016` (sim deserialized `/vehicles/available` as `string[]`; test fed the same wrong shape) and `BUG-017` (sim keyed workers by registration; tests reused one value as both the route id and the fleet-state row id) both shipped with 150 green simulator unit tests. Same root cause both times — tests that did not mirror the real contract — and both were caught only by the headless smoke, never by unit tests. See memory `feedback-masking-tests`.

**Acceptance Criteria:**
- The `/test-quality` skill (`.claude/skills/test-quality/SKILL.md`) gains an explicit **anti-masking rule**: tests must use realistic, contract-faithful, **distinct** identifiers; never reuse one placeholder for two distinct concepts (e.g. backend GUID vs registration string); request/response fixtures must match the **real** API shape. A test that would still pass against the wrong/old contract provides no protection and must be called out.
- The `story-ai-reviewer` agent's test-value check references this rule so masking tests are flagged on every story (not just when remembered).
- The `/test-quality` skill notes that mocked unit tests **cannot** verify a cross-process wire/identity contract — the headless smoke (`scripts/local/start.sh` + `scripts/local/smoke.sh`) is the integration net for that, and should be run before a repo is declared "done."
- The **simulator test suite is audited** for other masking instances (placeholder reuse collapsing two identities, or fixtures mirroring the code's assumption); each finding is either fixed or logged as a `BUG-`.
- Demonstrated: the strengthened guidance would have flagged the `BUG-016`/`BUG-017`-style tests as masking.

**Out of scope:** changing the pipeline's stages or adding a CI system; this is guidance + an audit, not new tooling.

**Done when:** the `/test-quality` skill and `story-ai-reviewer` agent are updated and shipped via `/ship-it`; the simulator-suite audit is complete with findings fixed or logged; this story is struck in `execution-plan.md`.

---

## QUAL-002 — Pipeline builds frontend UI stories to their mockup (mockup-driven fidelity)

**As a** maintainer of the TDD pipeline,
**I want** every pipeline stage to treat a frontend story's mockup image as the visual spec — verified, read, composed, built-to, and fidelity-checked —
**so that** an implemented UI component reproduces its approved design instead of MudBlazor defaults.

**Motivation**
`BUG-021` (the login screen shipped from FE-001 diverged sharply from `login__web-1280x800.png` — floating labels instead of labels-above-fields, no brand mark, no gradient, auto-uppercased button) was caused by the pipeline having **no step that reads the mockup**. FE-001 passed evaluation, planning, implementation, and AI review without any stage ever looking at the design image. The fix worked only because a human eyeballed the rendered page against the mockup at the checkpoint. The same gap would recur on every `FE-` UI story. (These changes were drafted during the BUG-021 run and are shipped here as a tracked, reviewed item rather than bundled into the bug fix.)

**Acceptance Criteria:**
- `story-evaluator` gains a **mockup-availability** gate (Step 4a): a frontend UI story that describes a visible surface but references no mockup, or references a missing image, is BLOCKED; behaviour-only frontend stories (e.g. FE-002 JWT expiry) are exempt.
- `story-planner` reads the referenced mockup PNG(s) and `docs/ui-mockups/design-system.css` and emits a **UI Composition Map** (one row per visible element → MudBlazor component / design-system class → bound data → AC) plus layout/states/variants/tokens prose.
- `story-implementor` builds to the Composition Map ("reproduce, don't reinvent"), still TDD-first, and reports which mockup it built to.
- `story-ai-reviewer` adds **Check 10 — Mockup Fidelity**: 10a (AC-bound elements present in markup *and* asserted by a bUnit test) is blocking; 10b (non-AC visual/structural drift) is advisory; pixel-level differences are explicitly not flagged.
- `master/SKILL.md` surfaces the mockup reference when displaying a UI story so the developer reviews it at Checkpoint #1.
- All five edited files pass `./scripts/utils/validate-ai-system.sh` with no blocking findings or warnings.

**Out of scope:** changing the number of pipeline stages or the checkpoint structure; adding image-diffing tooling (fidelity stays human-verified at the checkpoint, AI-assisted by Check 10's structural comparison).

**Done when:** the four agents + `master/SKILL.md` are updated and shipped via `/ship-it`; the validator passes; this story is struck in `execution-plan.md`.
