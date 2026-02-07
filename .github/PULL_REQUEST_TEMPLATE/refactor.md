<!--
  Refactor PR Template
  Branch: refactor/<description>
  Commits: refactor: <description>
  No behavior changes — structure and clarity only.
-->

## Refactor: <!-- title -->

### Goal
<!-- What structural problem does this solve? -->

### Approach
<!-- What strategy: extract, inline, rename, reorganize? -->

## Agent Team Workflow

| Phase | Agent | Status |
|-------|-------|--------|
| Plan | Architect | <!-- DONE --> |
| Verification Tests | Test Writer | <!-- DONE / EXISTING SUFFICIENT --> |
| Refactor | Implementer | <!-- DONE --> |
| Review | Reviewer | <!-- APPROVED --> |

## Changes

### Modified
-

### Moved/Renamed
-

## Test Plan

- [ ] **Zero behavior change** — all existing tests pass without modification
- [ ] `pytest tests/ -v` — green
- [ ] `ruff check .` — clean
- [ ] `ty check .` — clean

## Sources

-

## Semver Impact

- [x] **None** — Internal restructuring, no API/behavior change

## Future Work

- [ ] <!-- refactor: [title] — [related cleanup deferred] -->

## Checklist

- [ ] Branch: `refactor/<description>`
- [ ] Conventional commits: `refactor: <description>`
- [ ] No behavior changes
- [ ] No new features smuggled in
- [ ] All existing tests pass unmodified
- [ ] Architect plan approved before refactoring
