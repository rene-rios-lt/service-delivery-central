---
description: Acceptance criterion to test mapping process — produces a 5-column coverage table showing every AC bullet, its test method(s), test level, and coverage status.
---

# Skill: AC Coverage

## Purpose

Define the process for verifying that every acceptance criterion in a user story is covered by at least one test. Produce a mapping table that makes coverage gaps immediately visible. Used by the Story Planner (to plan tests) and the Story AI Reviewer (to verify coverage).

---

## Process

### Step 1 — Extract every AC bullet

Read the story's **Acceptance Criteria** section. Each bullet point is an AC item. Number them:

```
AC-1: Accepts { username, password }
AC-2: Returns a signed JWT containing role, tier, dealerId
AC-3: Returns 401 for invalid credentials
AC-4: JWT expiry configured via appsettings.json
```

Do not summarise or merge bullets. Each bullet is a distinct requirement.

### Step 2 — Identify the test(s) for each AC

For each AC item, identify the test method(s) that would **fail** if that criterion were violated:

- If the test does not exist yet (planning phase): write the test method name that should be created.
- If the tests do exist (review phase): write the method name(s) as found in the test files.

### Step 3 — Flag uncovered criteria

If an AC bullet has no corresponding test — either planned or existing — mark it **UNCOVERED**. Uncovered criteria are a blocker at both Checkpoint #1 (plan review) and the AI Review gate.

---

## Output Format

Produce a 5-column mapping table. Use this format consistently — in planning output, in AI Review output, and in the PR description:

| # | Acceptance Criterion | Test Method(s) | Level | Status |
|---|---------------------|----------------|-------|--------|
| AC-1 | Accepts `{ username, password }` | `GivenAValidCredential_WhenLoginCalled_ThenJwtIsReturned` | Unit | Covered |
| AC-2 | Returns JWT with role, tier, dealerId claims | `GivenAValidCredential_WhenLoginCalled_ThenJwtContainsRoleTierDealerId` | Unit | Covered |
| AC-3 | Returns 401 for invalid credentials | `GivenAnInvalidCredential_WhenLoginCalled_ThenReturns401` | Integration | Covered |
| AC-4 | JWT expiry configured via appsettings.json | `GivenDefaultConfig_WhenAppStarts_ThenJwtExpiryIsSet` | Integration | Config |

Valid Status values: **Planned** (planning phase — test not yet written), **Covered** (review phase — test exists and passes), **Partial** (covered at one level but not both where required), **Config** (configuration-only AC — see below), **UNCOVERED** (blocking).

> The example table above uses **Covered** because it represents review-phase output. In planning-phase output (Story Planner), all Status values are **Planned**.

---

## When Planning (Story Planner)

- Work through every AC bullet and write a named test method for each.
- Ensure that the method name reads as a plain-English specification of the behaviour.
- Distinguish unit-level tests (Application.Tests) from integration-level tests (Api.Tests) in the table.
- Any AC you cannot translate into a specific test method name is a signal that the AC is too vague — flag it for the Evaluator.
- Use **Planned** as the Status value for every row in the planning table. Tests do not exist yet; "Covered" would be misleading.

## When Reviewing (Story AI Reviewer)

- Read the actual test files in the repository.
- Map each AC bullet to the test methods found.
- If a bullet has no test, it is **UNCOVERED** — this is a blocking finding.
- If a bullet is covered only at unit level but the behaviour requires real infrastructure to verify (e.g. a SignalR event was actually sent), it is **partially covered** — flag it.

---

## Configuration ACs

Some AC bullets describe a configuration value rather than a runtime behaviour (e.g. "JWT expiry configured via appsettings.json"). These cannot be tested with a unit test asserting business logic. Cover them with an integration test that reads the configuration and asserts the key is present and correctly typed. Mark the status as **Config**. Config ACs are not hard UNCOVERED blockers, but they must still have an integration test. If the integration test is missing at AI Review, flag it as "Config — test missing" — an advisory finding that must be resolved before APPROVED.

## SignalR Event ACs

AC bullets that require a SignalR event to be sent (e.g. "broadcasts `RepAssigned` to the requester via `RequesterHub`") must be covered by integration tests in `Api.Tests` using `WebApplicationFactory` with a real SignalR hub connection. A unit test that only verifies a mock hub method was called does not count — the test must assert the event payload was received by a connected test client. Mark these as **Partial** if only mock verification exists.

For the reasoning behind why mock-only SignalR assertions are flagged as Partial rather than Covered — and for the side-effect exception that applies to other mock-verify scenarios — see the test-quality skill (`../.claude/skills/test-quality/SKILL.md`, Value-Add Check section).

---

## Hard Rules

- Every AC bullet must map to at least one test. No exceptions.
- "The happy path is tested" is not sufficient if the AC also specifies error conditions.
- A test that exists in the wrong test project (e.g. a database persistence test in `Application.Tests` using mocks) does not count as an integration test for that criterion.
- Configuration ACs marked **Config** are not blockers, but they must still have an integration test.
