---
name: start-team
description: >
  Start a Claude Code agent team for a development task. Creates the team with
  appropriate agents based on the task type. Invoke with /start-team.
disable-model-invocation: true
argument-hint: "[task-description]"
---

# Start Agent Team

Start a development team for: **$ARGUMENTS**

## Team Configuration

Create an agent team with these specialists:

### For Feature Development (default)
Spawn a full team:
1. **Architect** (opus, plan mode) — analyze requirements and create implementation plan
2. **Test-writer** (sonnet, acceptEdits) — write failing tests per the plan (TDD)
3. **Implementer** (sonnet, acceptEdits) — write code to make tests pass
4. **Reviewer** (sonnet, plan mode) — final quality and security review

### For Research / Investigation
Spawn research teammates:
1. Spawn 2-3 research agents with distinct angles
2. Have them share findings and challenge each other
3. Synthesize into a final report

### For Quick Fix
Spawn minimal team:
1. **Implementer** — make the fix
2. **Reviewer** — verify the fix

## Workflow

1. Analyze the task to determine team composition
2. Create tasks in the shared task list
3. Spawn teammates with clear context in their spawn prompts
4. Require plan approval for complex changes
5. Monitor progress and synthesize results
6. Clean up the team when done

## Pre-flight Checks

Before starting the team:
- Verify `.claude/tasks/tasks.json` has a task for this work
- Run `git status` to ensure clean working tree
- Check that agent teams are enabled (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`)

## Spawn Prompts

Give each teammate specific context when spawning:

```
Spawn an architect teammate with the prompt: "Analyze [task] in [package].
Read the relevant source files and create an implementation plan.
The plan must include: files to change, tests to write, acceptance criteria."
```

```
Spawn a test-writer teammate with the prompt: "Write tests for [feature] per
the approved plan. Create failing tests that define the acceptance criteria.
Tests should cover happy paths, edge cases, and error conditions."
```

## Post-Team Cleanup

After all tasks complete:
1. Verify all tasks are marked completed
2. Run full quality gate
3. Commit with conventional commit message
4. Ask the lead to clean up the team
