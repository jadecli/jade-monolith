---
name: agent-teams
description: Claude Agent Teams operations reference and workflow patterns
---

# Agent Teams Quick Reference

## Enable Agent Teams
```bash
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
```

## Permission modes (cycle with Shift+Tab)
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
claude --agent architect         # Load architect agent definition
claude --agent implementer       # Load implementer agent definition
claude --agent test-writer       # Load test-writer agent definition
claude --agent reviewer          # Load reviewer agent definition
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

## Token Cost Management
- Opus: architecture decisions only
- Sonnet: 80% of implementation (switch with /model sonnet)
- Haiku: linting, quick questions (switch with /model haiku)
- Run /compact when context exceeds 70%
- Run /cost to check session spending
- Keep CLAUDE.md under 300 lines
