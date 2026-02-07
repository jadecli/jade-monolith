# Task-Gated Changes Rule

**MANDATORY: All code changes must be authorized by a task in `.claude/tasks/tasks.json`.**

## Before Writing Any Code

1. Read `.claude/tasks/tasks.json`
2. Find the task you are executing by ID
3. Verify `status` is `pending` or `in_progress`
4. Verify `blocked_by` is empty
5. Verify the task's `package` field matches the directory you will modify
6. Set status to `in_progress`

## Violations

If you cannot find a matching task:
- **STOP.** Do not write code.
- Create a new task in tasks.json describing the needed work.
- Ask the user for approval before proceeding.

If a task targets a different package than the files you need to modify:
- **STOP.** This is a cross-package violation.
- Split the work into separate per-package tasks.

## After Completing Work

1. Run linter/tests if the package has them
2. Commit with conventional commit referencing the task ID
3. Set task status to `completed`
4. Update `blocked_by` on any tasks this unblocks
