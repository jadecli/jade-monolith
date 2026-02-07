---
name: agent-teams
description: >
  Claude Agent Teams operations reference — team lifecycle, messaging, plan approval,
  shutdown, worktree setup, and token cost management. Use when coordinating
  multi-agent teams or when the user asks about team operations.
user-invocable: false
---

# Agent Teams Quick Reference

## Enable Agent Teams
```bash
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
```

Or in `.claude/settings.json`:
```json
{ "env": { "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1" } }
```

## Permission Modes (cycle with Shift+Tab)
- **Normal** — standard permissions, ask for approval
- **Auto-Accept** — approve all tool uses automatically
- **Plan** — read-only, cannot modify files
- **Delegate** — coordination only, cannot write code (requires active team)

## Start with delegate mode
```bash
claude --permission-mode delegate
```

## Start with a specific agent
```bash
claude --agent team-lead        # Coordinator (delegate mode)
claude --agent architect        # Read-only planner
claude --agent implementer      # Production code writer
claude --agent test-writer      # TDD test writer
claude --agent reviewer         # Read-only code reviewer
```

## Standard Team Workflow
```
User Request → Team Lead → Architect (plan)
                         → Test-writer (failing tests)
                         → Implementer (make tests pass)
                         → Reviewer (quality check)
                         → Team Lead (synthesize & report)
```

## TeammateTool Operations (13 total)

### Team Lifecycle
| Operation | Purpose |
|-----------|---------|
| spawnTeam | Create team, caller becomes leader |
| discoverTeams | List available teams |
| requestJoin | Request to join a team |
| approveJoin | Leader accepts join request |
| rejectJoin | Leader declines join request |
| cleanup | Remove team directories and task files |

### Messaging
| Operation | Purpose |
|-----------|---------|
| write | Direct message to one teammate |
| broadcast | Message ALL teammates (cost: N messages) |

### Plan Approval
| Operation | Purpose |
|-----------|---------|
| approvePlan | Leader approves teammate's plan |
| rejectPlan | Leader rejects with feedback |

### Shutdown
| Operation | Purpose |
|-----------|---------|
| requestShutdown | Leader requests teammate exit |
| approveShutdown | Teammate accepts shutdown |
| rejectShutdown | Teammate declines shutdown |

## Worktree Setup (one per agent)
```bash
git worktree add ../jade-architect -b review/architecture
git worktree add ../jade-implement -b feat/implementation
git worktree add ../jade-tests -b test/coverage
git worktree add ../jade-review -b review/code

cd ../jade-architect && claude --agent architect
cd ../jade-implement && claude --agent implementer
cd ../jade-tests && claude --agent test-writer
cd ../jade-review && claude --agent reviewer
```

## In-Process Mode (no tmux required)
- **Shift+Up/Down** — select a teammate
- **Enter** — view a teammate's session
- **Escape** — interrupt teammate's current turn
- **Ctrl+T** — toggle the task list
- **Ctrl+B** — background a running task

## Token Cost Management
| Model | Use For | Cost |
|-------|---------|------|
| Opus (4.6) | Architecture decisions, team lead | Highest |
| Sonnet | 80% of implementation, testing, review | Medium |
| Haiku | Linting, quick questions, exploration | Lowest |

- Run `/compact` when context exceeds 70%
- Run `/cost` to check session spending
- Keep CLAUDE.md under 300 lines
- Use subagents for high-volume operations to isolate context

## Agent Model Assignments
| Agent | Model | Rationale |
|-------|-------|-----------|
| team-lead | opus | Critical coordination decisions |
| architect | opus | Design quality matters most |
| implementer | sonnet | Fast, high-volume code writing |
| test-writer | sonnet | Fast, focused test creation |
| reviewer | sonnet | Efficient analysis |
