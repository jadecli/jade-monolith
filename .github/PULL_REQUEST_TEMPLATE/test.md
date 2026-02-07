<!--
  Test PR Template
  Branch: test/<description>
  Commits: test: <description>
  No production code changes — test infrastructure only.
-->

## Test Coverage: <!-- title -->

### Goal
<!-- What test gap does this close? What confidence does it add? -->

### Test Strategy
<!-- Which test layer(s) does this add to? -->

- [ ] **Schema** — Agent definition validation (`-m schema`)
- [ ] **Smoke** — Fast offline checks (`-m smoke`)
- [ ] **Contract** — CLI integration tests (`-m contract`)
- [ ] **Compat** — Version compatibility tracking (`-m compat`)

## Agent Team Workflow

| Phase | Agent | Status |
|-------|-------|--------|
| Test Design | Test Writer | <!-- DONE --> |
| Review | Reviewer | <!-- APPROVED --> |

## Test Inventory

<!-- List every new test with its purpose -->

| Test | Marker | What it validates |
|------|--------|-------------------|
| `test_` | `@pytest.mark.` | <!-- description --> |

## Changes

### Added
-

### Modified
-

## Verification

- [ ] `pytest tests/ -v` — all new tests passing
- [ ] `pytest tests/ -v --tb=short` — no regressions
- [ ] `ruff check tests/` — clean
- [ ] Tests skip gracefully when dependencies unavailable

## Sources

-

## Semver Impact

- [x] **None** — Tests only, no version bump

## Future Work

- [ ] <!-- test: [title] — [coverage gap still remaining] -->

## Checklist

- [ ] Branch: `test/<description>`
- [ ] Conventional commits: `test: <description>`
- [ ] No production code changes
- [ ] Tests follow existing patterns in `conftest.py`
- [ ] All markers registered in `pyproject.toml`
- [ ] Tests degrade gracefully (pytest.skip, not hard fail)
