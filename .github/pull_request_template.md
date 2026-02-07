<!--
  Pull Request — Default Template
  Convention: One feature per PR. Reference related ideas in "Future Work".
  Branch naming: <type>/<description> where type = feat|fix|test|docs|refactor|chore
  Commits: Conventional Commits (https://www.conventionalcommits.org/)
-->

## Summary

<!-- 1-3 bullet points. What does this PR do and WHY? -->

-

## Type

<!-- Check ONE. This must match your branch prefix and commit type. -->

- [ ] `feat:` — New feature or capability
- [ ] `fix:` — Bug fix
- [ ] `test:` — Test coverage (no production code changes)
- [ ] `docs:` — Documentation only
- [ ] `refactor:` — Code restructuring (no behavior change)
- [ ] `chore:` — Tooling, CI, dependencies, config

## Agent Team Context

<!-- Which agents contributed to this PR? Check all that apply. -->

- [ ] **Architect** — Produced the implementation plan
- [ ] **Test Writer** — Wrote tests first (TDD)
- [ ] **Implementer** — Wrote production code
- [ ] **Reviewer** — Reviewed before merge
- [ ] **Human** — Direct human authorship

<details>
<summary>Plan reference (if applicable)</summary>

<!-- Paste the architect's plan summary or link to the plan file -->

```
Plan: [title]
Scope: [small/medium/large]
Approved by: [team lead / human]
```

</details>

## Changes

<!-- List files changed, grouped by purpose -->

### Added
-

### Modified
-

### Removed
-

## Test Plan

<!-- How was this tested? Check all that apply. -->

- [ ] `pytest tests/ -v` — all passing
- [ ] `ruff check .` — clean
- [ ] `ty check .` — clean
- [ ] Manual verification: <!-- describe -->
- [ ] CI pipeline green

## Sources

<!-- Version-controlled references used during research and implementation.
     These are tracked so future PRs can build on the same knowledge base.
     Format: - [Short Title](URL) — what it contributed -->

- <!-- [Source Title](https://example.com) — relevance -->

## Semver Impact

<!-- Which version segment does this PR bump? -->

- [ ] **PATCH** `0.1.x` — Backward-compatible fix
- [ ] **MINOR** `0.x.0` — Backward-compatible new functionality
- [ ] **MAJOR** `x.0.0` — Breaking change
- [ ] **None** — No version bump (docs, tests, CI only)

## Future Work

<!-- Related features this PR intentionally did NOT cover.
     Each item here is a candidate for its own future PR.
     One feature per PR — list ideas for others here instead. -->

- [ ] <!-- feat: [description] — [why it's related but separate] -->

## Checklist

- [ ] Branch follows convention: `<type>/<description>` or `claude/<description>`
- [ ] All commits use conventional commit format
- [ ] One feature per PR (no scope creep)
- [ ] Sources section filled if external references were used
- [ ] Future Work lists related ideas deferred to separate PRs
- [ ] Tests written before implementation (TDD)
- [ ] No secrets, credentials, or `.env` files committed
