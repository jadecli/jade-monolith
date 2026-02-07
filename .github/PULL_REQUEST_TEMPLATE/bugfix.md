<!--
  Bug Fix PR Template
  Branch: fix/<description>
  Commits: fix: <description>
-->

## Bug Fix: <!-- title -->

### Problem
<!-- What is broken? Include error messages, stack traces, or reproduction steps. -->

### Root Cause
<!-- What caused the bug? Be specific — file, line, logic error. -->

### Fix
<!-- What does this PR change to resolve it? -->

## Agent Team Workflow

| Phase | Agent | Status |
|-------|-------|--------|
| Diagnosis | Architect | <!-- DONE / HUMAN --> |
| Regression Tests | Test Writer | <!-- DONE --> |
| Fix | Implementer | <!-- DONE --> |
| Review | Reviewer | <!-- APPROVED --> |

## Changes

### Modified
-

## Test Plan

- [ ] Regression test added that fails WITHOUT fix, passes WITH fix
- [ ] `pytest tests/ -v` — all passing
- [ ] `ruff check .` — clean
- [ ] No existing tests broken

## Sources

-

## Semver Impact

- [x] **PATCH** `0.1.x` — Backward-compatible bug fix

## Future Work

<!-- Systemic issues to address in follow-up PRs -->

- [ ] <!-- fix/refactor: [title] — [deeper issue this exposed] -->

## Checklist

- [ ] Branch: `fix/<description>`
- [ ] Conventional commits: `fix: <description>`
- [ ] Regression test written BEFORE fix
- [ ] Fix is minimal — no unrelated changes
