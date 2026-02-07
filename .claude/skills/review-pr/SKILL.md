---
name: review-pr
description: >
  Review a GitHub pull request with structured analysis. Fetches PR diff,
  comments, and changed files. Runs in a forked Explore context.
context: fork
agent: Explore
allowed-tools: Bash(gh *), Read, Grep, Glob
disable-model-invocation: true
argument-hint: "[PR-number-or-URL]"
---

# Review Pull Request

Review the pull request specified by `$ARGUMENTS`.

## Gather Context

Fetch the PR data:
- PR diff: !`gh pr diff $ARGUMENTS 2>/dev/null || echo "Could not fetch diff"`
- PR description: !`gh pr view $ARGUMENTS 2>/dev/null || echo "Could not fetch PR"`
- Changed files: !`gh pr diff $ARGUMENTS --name-only 2>/dev/null || echo "Could not list files"`

## Review Checklist

For each changed file, check:

### Correctness
- Does the change do what the PR description says?
- Are there any logic errors or off-by-one bugs?
- Are edge cases handled?

### Security (OWASP Top 10)
- No injection vulnerabilities (SQL, command, XSS)
- No exposed secrets or credentials
- No sensitive data in logs
- Input validation at system boundaries

### Quality
- Code follows existing patterns in the codebase
- No unnecessary complexity
- Error handling is appropriate (not over/under-engineered)
- No dead code or commented-out code

### Tests
- Are tests included for new behavior?
- Do tests cover edge cases?
- Are existing tests still valid?

### Scope
- Does the PR contain only related changes?
- Any scope creep or unrelated refactoring?

## Output Format

Provide a structured review:

```markdown
## PR Review: #[number]

### Summary
[1-2 sentence overview of what the PR does]

### Verdict: [APPROVE / REQUEST CHANGES / COMMENT]

### Issues Found
1. **[severity]** `file:line` — [description]
2. **[severity]** `file:line` — [description]

### Positive Observations
- [things done well]

### Suggestions (non-blocking)
- [optional improvements]
```

Severity levels: `critical` (must fix), `major` (should fix), `minor` (nice to fix), `nit` (style only)
