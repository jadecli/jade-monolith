---
name: swarm-develop
description: >
  Launch a development swarm for feature implementation. Coordinates architect,
  test-writer, implementer(s), and reviewer agents in a TDD workflow. Each agent
  owns specific files to prevent conflicts.
argument-hint: "[feature description]"
disable-model-invocation: true
context: fork
agent: swarm-orchestrator
allowed-tools: Task, TaskCreate, TaskList, TaskUpdate, TaskGet, Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---

# Development Swarm Protocol

Launch a coordinated development team for feature implementation.

## Feature
$ARGUMENTS

## Development Workflow (TDD)

```
architect → test-writer → implementer(s) → reviewer → merge
   ↓            ↓              ↓              ↓
  plan      tests (fail)    code (pass)    verdict
```

### Stage 1: Architecture (architect agent)
- Analyze requirements
- Design implementation plan
- Define file boundaries per agent
- Submit plan for approval

### Stage 2: Test Writing (test-writer agent)
- Read approved plan
- Write failing tests for all acceptance criteria
- Commit tests: `test: add tests for [feature]`

### Stage 3: Implementation (specialist dev agents)
Select from available development agents based on the feature domain:
- frontend-dev, backend-dev, fullstack-dev, database-dev
- api-dev, cli-dev, sdk-dev, ui-component-dev
- state-management-dev, data-pipeline-dev, realtime-dev
- auth-dev, search-dev, notification-dev, config-dev

Rules:
- Each agent owns specific files — NO overlap
- Implement to make tests pass
- Run quality gates before marking complete
- Commit with conventional commits

### Stage 4: Review (reviewer + specialists)
Select review agents based on the feature:
- reviewer (always)
- security-auditor (if auth/data/network involved)
- performance-reviewer (if performance-sensitive)
- accessibility-reviewer (if UI involved)
- breaking-change-detector (if public API changed)

### Stage 5: Quality Gates
```bash
ruff check .        # Python linting
ty check .          # Python type checking
pytest              # Python tests
npm test            # Node.js tests
```

## Agent Selection Guide

| Feature Type | Dev Agent | Extra Review |
|-------------|-----------|--------------|
| React UI | frontend-dev, ui-component-dev | accessibility-reviewer |
| REST API | backend-dev, api-dev | api-conformance-checker |
| Database | database-dev | query-optimizer |
| Auth | auth-dev | security-auditor |
| CLI tool | cli-dev | — |
| SDK/library | sdk-dev | breaking-change-detector |
| Real-time | realtime-dev | performance-reviewer |
| Search | search-dev | performance-reviewer |
| Config | config-dev | — |

## Output

Report final status:
```
DEVELOPMENT SWARM REPORT
========================
Feature: [description]
Agents: [list]
Tests: [pass/total]
Quality Gate: PASS/FAIL
Commits: [list of commit SHAs]
Files Modified: [count]
```
