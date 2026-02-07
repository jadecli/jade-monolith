<!--
  Feature PR Template
  Branch: feat/<description>
  Commits: feat: <description>
  Rule: ONE feature per PR. Defer related ideas to Future Work.
-->

## Feature: <!-- title -->

### Goal
<!-- 1-2 sentences: what capability does this add and who benefits? -->

### Context
<!-- What exists today? Why is this feature needed now? -->

## Agent Team Workflow

| Phase | Agent | Status |
|-------|-------|--------|
| Plan | Architect | <!-- DONE / SKIPPED / N/A --> |
| Plan Approval | Team Lead | <!-- APPROVED / MODIFIED --> |
| Tests | Test Writer | <!-- DONE / SKIPPED --> |
| Implementation | Implementer | <!-- DONE --> |
| Review | Reviewer | <!-- APPROVED / CHANGES REQUESTED --> |

<details>
<summary>Architect Plan</summary>

```markdown
# Plan: [Title]

## Goal
[1-2 sentences]

## Changes
[Files and modifications]

## Tests (written BEFORE implementation)
[Test names and descriptions]

## Acceptance Criteria
- [ ] [criterion]

## Scope: [small/medium/large]
```

</details>

## Changes

### Added
-

### Modified
-

## Test Plan

- [ ] `pytest tests/ -v -m <marker>` — all passing
- [ ] `ruff check .` — clean
- [ ] `ty check .` — clean
- [ ] New tests cover: happy path, edge cases, error conditions
- [ ] No existing tests broken or weakened

## Sources

<!-- References used during research. Tracked for reproducibility.
     Format: - [Title](URL) — what it contributed to this PR -->

-

## Semver Impact

- [x] **MINOR** `0.x.0` — New backward-compatible functionality

## Breaking Changes

<!-- If MAJOR bump: describe what breaks and migration path -->

None.

## Future Work

<!-- One feature per PR. List related features that should be SEPARATE PRs.
     These are ideas surfaced during this work — not scope for this PR. -->

- [ ] <!-- feat: [title] — [why related, why deferred] -->

## Checklist

- [ ] Branch: `feat/<description>`
- [ ] Conventional commits: `feat: <description>`
- [ ] Architect plan approved before implementation
- [ ] Tests written FIRST (TDD)
- [ ] One feature only — no scope creep
- [ ] Sources documented if external references used
- [ ] No secrets, credentials, or `.env` files committed
