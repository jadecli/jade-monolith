---
name: task-workflow
description: >
  Task lifecycle management for jade-monolith. Defines task schema, status
  transitions, and guardrail checkpoints. Preloaded by team-lead and architect agents.
user-invocable: false
---

# Task Workflow

All work in jade-monolith is task-gated. No code changes without a task.

## Task Registry

Tasks live in `.claude/tasks/tasks.json`. The schema:

```json
{
  "id": "package-name/task-slug",
  "title": "Human-readable title",
  "description": "What to do and acceptance criteria",
  "package": "package-name",
  "status": "pending|in_progress|completed|blocked",
  "complexity": "S|M|L|XL",
  "blocked_by": [],
  "labels": ["feat", "fix", "test", "docs", "chore"],
  "created_at": "YYYY-MM-DD"
}
```

## Task Lifecycle

```
pending → in_progress → completed
   ↓                       ↑
blocked ──────────────────→─┘ (when blocker resolves)
```

### Status Rules
- **pending** — Ready to work. `blocked_by` must be empty.
- **in_progress** — Agent is actively working. Only ONE task per package at a time.
- **completed** — Work done, committed, quality gate passed.
- **blocked** — Cannot proceed. `blocked_by` lists blocking task IDs.

## Guardrail Checkpoints

### Before ANY Code Change
1. Verify a task exists in tasks.json for this work
2. Verify the task targets exactly ONE package
3. Set task status to `in_progress`
4. Confirm no other task is `in_progress` for the same package

### If No Task Exists
- **STOP.** Do not write code.
- Create a new task in tasks.json describing the needed work.
- Get approval before proceeding.

### After Completing Work
1. Run the package's linter/tests (see quality-gate skill)
2. Commit with conventional commit format
3. Set task status to `completed`
4. Check for newly unblocked tasks (tasks whose `blocked_by` now resolves)

## Package Isolation (STRICT)

- Every task targets exactly ONE `packages/<name>/` directory
- Never modify files in two different packages in the same task
- No cross-references between packages
- The only shared files are in `scripts/` (read-only) and `.claude/tasks/` (status only)

## Task Creation Template

When creating a new task:
```json
{
  "id": "<package>/<verb>-<noun>",
  "title": "Clear, action-oriented title",
  "description": "What: [specific deliverable]\nWhy: [context]\nAcceptance: [criteria]",
  "package": "<target-package>",
  "status": "pending",
  "complexity": "S",
  "blocked_by": [],
  "labels": ["feat"],
  "created_at": "YYYY-MM-DD"
}
```

## Complexity Guide

| Size | Scope | Typical Duration |
|------|-------|-----------------|
| S | Single file, well-defined change | < 1 session |
| M | Multiple files, moderate logic | 1 session |
| L | Cross-cutting within a package | 1-2 sessions |
| XL | Architectural change | Multiple sessions, requires architect plan |

## Context Handoff

When approaching 170K tokens of context:
1. Stop starting new tasks
2. Write 500-token summary to `.claude/tasks/context-handoff.md`
3. Commit all work
4. Update task statuses in tasks.json
