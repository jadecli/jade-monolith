# Agent Task Spec (ATS) v0.1.0

A specification for standardizing the unit of work in AI agent team systems.

## Problem

Long-running AI agent teams need a standardized way to:
1. Define, decompose, and assign work
2. Coordinate who is working on what (prevent collisions)
3. Track progress across context window boundaries
4. Sync work items to external trackers (GitHub Issues/Projects)
5. Garbage-collect agent memory when work completes

## Design Principles

- **TASK.md is the atomic unit**: One file per task, YAML frontmatter + markdown body
- **File-system is the source of truth**: No database required, git-native
- **Lock files prevent collisions**: Agents claim tasks with `.lock.json` files
- **INDEX.json is derived**: Regenerated from TASK.md files, never hand-edited
- **Hooks automate lifecycle**: Shell scripts fire on claim/complete events
- **GitHub sync is bidirectional**: Tasks sync to Issues, Issues sync back to tasks

## Directory Layout

```
.agent-tasks/
  tasks/
    {task-id}/
      TASK.md           # Source of truth — YAML frontmatter + markdown
  locks/
    {task-id}.lock.json  # Agent lock files (transient)
  INDEX.json             # Generated summary of all tasks
  progress.json          # Session progress tracker
```

## TASK.md Format

```yaml
---
id: feat-user-auth            # kebab-case, unique
type: feat                     # conventional commit type
subject: Add user authentication  # max 80 chars
status: pending                # pending|locked|in_progress|blocked|review|completed|rejected
owner: implementer             # which agent owns it
scope: auth                    # module scope
breaking: false
blockedBy: [fix-dep]           # task IDs that must complete first
blocks: [feat-next]            # tasks this unblocks
assignableTo: [implementer, auth-dev]  # which agents can claim
criteria:                      # acceptance criteria
  - All tests pass
  - ruff check clean
tools: [Read, Write, Bash]     # tools the agent should use
maxTurns: 25                   # context budget
testFirst: true                # TDD flag
---

## Context
Detailed description and implementation notes.
```

## Task Lifecycle

```
pending ──claim──> locked ──start──> in_progress ──review──> review ──approve──> completed
   |                  |                   |                              |
   |                  └──release──> pending                   └──reject──> in_progress
   |
   └──block──> blocked ──unblock──> pending
```

### Hooks

| Event | Hook | Trigger |
|-------|------|---------|
| Claim | `task-claim.sh` | Agent requests a task |
| Complete | `task-lifecycle.sh` | Agent marks task done |
| TeammateIdle | `swarm-teammate-idle.sh` | Agent finishes and idles |

### Claim Protocol (Lock Files)

1. Agent checks `locks/{task-id}.lock.json` — if exists and held by another agent, pick a different task
2. Agent writes lock file with `taskId`, `agent`, `lockedAt`
3. Agent updates task status to `locked` then `in_progress`
4. On completion: lock file is removed, status set to `completed`
5. Stale locks (older than `staleSec`) can be reclaimed

## GitHub Sync

Tasks sync bidirectionally with GitHub Issues:

```bash
# Push all tasks to GitHub Issues
ats sync --repo jadecli/jade-monolith

# Preview without changes
ats sync --repo jadecli/jade-monolith --dry-run
```

Each synced issue contains an `[ATS:{task-id}]` marker in its body for identification.

### Mapping

| ATS Field | GitHub Field |
|-----------|-------------|
| `subject` | Issue title |
| `type` | Issue label (feat->enhancement, fix->bug, etc.) |
| `status` completed/rejected | Issue state closed |
| `criteria` | Checklist in body |
| `body` | Issue body |

## CLI Reference

```bash
ats init                           # Create .agent-tasks directory
ats list                           # List all tasks
ats list --status pending          # Filter by status
ats list --json                    # JSON output
ats show {task-id}                 # Show task details
ats claim {task-id} --agent impl   # Claim task for an agent
ats release {task-id}              # Release a lock
ats complete {task-id}             # Mark task completed
ats index                          # Regenerate INDEX.json
ats sync --repo owner/name         # Sync to GitHub Issues
```

## Integration with Claude Code Agent Teams

ATS integrates with the 100-agent swarm system:

1. **Swarm orchestrator** decomposes work into TASK.md files
2. **Agent teams** claim tasks via lock files (git-native, prevents races)
3. **Hooks** fire on TaskCompleted/TeammateIdle to automate lifecycle
4. **GitHub sync** maintains external visibility and audit trail
5. **INDEX.json** gives each new agent session a quick status overview
6. **progress.json** bridges context windows (per Anthropic's long-running agent pattern)

## JSON Schemas

- `schema/task.schema.json` — TASK.md frontmatter validation
- `schema/index.schema.json` — INDEX.json structure
- `schema/lock.schema.json` — Lock file structure
- `schema/progress.schema.json` — Progress tracker structure
