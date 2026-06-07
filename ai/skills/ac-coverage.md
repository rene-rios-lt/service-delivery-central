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

Produce a mapping table:

| # | Acceptance Criterion | Test Method(s) | Status |
|---|---------------------|----------------|--------|
| AC-1 | Accepts `{ username, password }` | `GivenValidCredentials_WhenLoginCalled_ThenJwtIsReturned` | Covered |
| AC-2 | Returns JWT with role, tier, dealerId claims | `GivenValidCredentials_WhenLoginCalled_ThenJwtContainsRoleTierDealerId` | Covered |
| AC-3 | Returns 401 for invalid credentials | `GivenInvalidCredentials_WhenLoginCalled_ThenReturns401` | Covered |
| AC-4 | JWT expiry configured via appsettings.json | — | **UNCOVERED** |

---

## When Planning (Story Planner)

- Work through every AC bullet and write a named test method for each.
- Ensure that the method name reads as a plain-English specification of the behaviour.
- Distinguish unit-level tests (Application.Tests) from integration-level tests (Api.Tests) in the table.
- Any AC you cannot translate into a specific test method name is a signal that the AC is too vague — flag it for the Evaluator.

## When Reviewing (Story AI Reviewer)

- Read the actual test files in the repository.
- Map each AC bullet to the test methods found.
- If a bullet has no test, it is **UNCOVERED** — this is a blocking finding.
- If a bullet is covered only at unit level but the behaviour requires real infrastructure to verify (e.g. a SignalR event was actually sent), it is **partially covered** — flag it.

---

## Hard Rules

- Every AC bullet must map to at least one test. No exceptions.
- "The happy path is tested" is not sufficient if the AC also specifies error conditions.
- A test that exists in the wrong test project (e.g. a database persistence test in `Application.Tests` using mocks) does not count as an integration test for that criterion.
