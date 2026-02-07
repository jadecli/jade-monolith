---
name: swarm-deploy
description: >
  Launch a deployment swarm for release preparation. Coordinates release manager,
  reviewer, security auditor, and documentation agents to prepare a clean release
  with changelog, security check, and updated docs.
argument-hint: "[version or release description]"
disable-model-invocation: true
context: fork
agent: swarm-orchestrator
allowed-tools: Task, TaskCreate, TaskList, TaskUpdate, TaskGet, Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---

# Deployment Swarm Protocol

Prepare a release for deployment.

## Release
$ARGUMENTS

## Deployment Pipeline

```
security-auditor ─┐
dependency-auditor ┤
license-checker ───┤→ gate → release-manager → changelog-writer → deploy
reviewer ──────────┤
breaking-change-detector ┘
```

### Stage 1: Pre-Release Audit (parallel)
Run all audit agents simultaneously:
- **security-auditor**: scan for vulnerabilities
- **dependency-auditor**: check dependency health
- **license-checker**: verify license compliance
- **reviewer**: general quality check
- **breaking-change-detector**: identify API changes

### Stage 2: Gate Decision
All auditors must PASS before proceeding.
If any FAIL: report issues and stop.

### Stage 3: Release Preparation
- **release-manager**: version bump, tag, release notes
- **changelog-writer**: generate changelog from commits
- **documentation-writer**: update docs for new version

### Stage 4: Final Verification
- Run full test suite
- Verify build succeeds
- Check all docs are current

## Release Report

```markdown
# Release Report: v[version]

## Audit Results
- Security: PASS/FAIL
- Dependencies: PASS/FAIL
- Licenses: PASS/FAIL
- Code Quality: PASS/FAIL
- Breaking Changes: [list or none]

## Changelog
[Generated changelog]

## Tests
- Total: [count]
- Passing: [count]
- Coverage: [percent]

## Ready to Deploy: YES/NO
```
