---
name: swarm-review
description: >
  Launch a review swarm for comprehensive code review. Spawns multiple specialized
  reviewers who examine code from different angles simultaneously: security,
  performance, accessibility, test coverage, and spec conformance.
argument-hint: "[PR number or file paths]"
disable-model-invocation: true
context: fork
agent: swarm-orchestrator
allowed-tools: Task, TaskCreate, TaskList, TaskUpdate, TaskGet, Read, Glob, Grep, Bash, AskUserQuestion
---

# Review Swarm Protocol

Launch a multi-perspective code review.

## Review Target
$ARGUMENTS

## Available Review Agents

| Agent | Focus | Model | Read-Only |
|-------|-------|-------|-----------|
| reviewer | General quality & spec | opus | Yes |
| security-auditor | OWASP, CWE, secrets | opus | Yes |
| performance-reviewer | Complexity, memory, N+1 | sonnet | Yes |
| accessibility-reviewer | WCAG 2.1 AA | sonnet | Yes |
| documentation-reviewer | Doc accuracy | haiku | Yes |
| api-conformance-checker | API standards | sonnet | Yes |
| style-enforcer | Code style | haiku | Yes |
| complexity-analyzer | Cyclomatic/cognitive | sonnet | Yes |
| dependency-auditor | Dep vulnerabilities | sonnet | Yes |
| license-checker | License compliance | haiku | Yes |
| breaking-change-detector | API breakage | sonnet | Yes |

## Execution

1. **Determine review scope** — which files changed, what domains are affected
2. **Select 3-5 review agents** based on the change domain
3. **Always include**: reviewer (general)
4. **Add specialists** based on what changed:
   - Auth/data code → security-auditor
   - UI components → accessibility-reviewer
   - Public API → breaking-change-detector, api-conformance-checker
   - Dependencies → dependency-auditor, license-checker
   - Performance-sensitive → performance-reviewer
5. **Run all reviewers in parallel** — they examine code independently
6. **Synthesize findings** — merge, deduplicate, prioritize

## Review Report Template

```markdown
# Review Report

## Summary
- Files Reviewed: [count]
- Issues Found: [critical] critical, [major] major, [minor] minor
- Verdict: APPROVED / CHANGES REQUESTED

## Critical Issues (must fix)
1. [file:line] — [description] — Found by [agent]

## Major Issues (should fix)
1. [file:line] — [description] — Found by [agent]

## Minor Issues (consider)
1. [file:line] — [description] — Found by [agent]

## Quality Gates
- Lint: PASS/FAIL
- Types: PASS/FAIL
- Tests: PASS/FAIL
- Security: PASS/FAIL

## Agent Reports
### [Agent Name]: [PASS/FAIL]
[Summary of findings]
```
