---
name: quality-gate
description: >
  Quality gate standards for jade-monolith packages. Defines lint, type-check,
  and test requirements. Preloaded by implementer, test-writer, and reviewer agents.
user-invocable: false
---

# Quality Gate Standards

All code changes must pass these quality gates before a task can be marked complete.

## Python Packages

### Required Checks
```bash
# Linting (BLOCKING — must pass)
ruff check .

# Type checking (WARNING — should pass, non-blocking for now)
ty check .

# Tests (BLOCKING — must pass)
pytest
```

### Ruff Configuration
- Follow existing `pyproject.toml` or `ruff.toml` in the package
- If no config exists, use defaults with line-length 100
- Auto-fix is allowed: `ruff check --fix .`

### Ty Configuration
- Follow existing config in the package
- Warnings are non-blocking but should be addressed
- New code should not introduce new type errors

## Node.js / TypeScript Packages

### Required Checks
```bash
# Tests (BLOCKING — must pass)
npm test

# Or with vitest directly
npx vitest run
```

### If ESLint is configured
```bash
npx eslint .
```

## Quality Gate Workflow

### Before Starting Implementation
1. Run existing tests to establish baseline: `pytest` or `npm test`
2. Note any pre-existing failures (not your responsibility)
3. Your changes must not introduce NEW failures

### During Implementation
1. Run lint after each file edit: `ruff check <file>`
2. Fix lint issues immediately — don't accumulate them
3. Run tests periodically, not just at the end

### Before Marking Task Complete
1. Run full quality gate:
   ```bash
   # Python
   ruff check . && ty check . && pytest

   # Node.js
   npm test
   ```
2. ALL blocking checks must pass
3. If checks fail, fix issues before marking complete
4. If pre-existing failures exist, document them — don't fix unrelated code

## Commit Standards

- Use conventional commits: `feat:`, `fix:`, `test:`, `docs:`, `chore:`, `refactor:`
- Co-author line: `Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>`
- Reference task ID in commit body when applicable

## What Passes vs What Blocks

| Check | Blocks Completion | Action on Failure |
|-------|-------------------|-------------------|
| `ruff check` | YES | Fix lint errors |
| `ty check` | NO (warning) | Fix if possible, document if not |
| `pytest` | YES | Fix failing tests |
| `npm test` | YES | Fix failing tests |
| Pre-existing failures | NO | Document, don't fix |
