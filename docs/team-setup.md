# Agent Teams — Team Setup Guide

> Get up and running in 5 minutes.

## Prerequisites

1. Claude Code CLI installed: `npm install -g @anthropic-ai/claude-code`
2. Claude Code authenticated: `claude login`
3. Git clone of this repo
4. tmux installed: `sudo apt install tmux`

## Quick Start

### 1. Enable Agent Teams

Add to your `~/.zshrc` (or `~/.bashrc`):

```bash
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
```

The repo-level `.claude/settings.json` also sets this, but the shell export ensures it's active before Claude Code reads any config.

### 2. Verify setup

```bash
# Check Claude Code version (need 2.1.34+)
claude --version

# Check agent definitions are found
ls .claude/agents/
# Should show: architect.md  implementer.md  reviewer.md  test-writer.md

# Test loading an agent
claude --agent architect --permission-mode plan -p "List the files in this repo"
```

### 3. Start a team session (interactive)

```bash
# Option A: Single terminal with delegate mode
claude --permission-mode delegate

# Option B: tmux with 4 agent panes
bash scripts/start-team.sh
```

### 4. Start a team session (headless / CI)

```bash
# Run the full pipeline on a task
bash scripts/run-team.sh "Add user authentication with JWT tokens"
```

## Available Agents

| Agent | Role | Can modify files? | Model |
|-------|------|-------------------|-------|
| architect | Plans and designs | No (read-only) | Opus |
| implementer | Writes code | Yes | Opus (or Sonnet for cost savings) |
| test-writer | Writes tests first | Yes (test files only) | Opus (or Sonnet) |
| reviewer | Reviews before merge | No (read-only) | Opus (or Haiku) |

## Workflow

1. **You** describe the task to the team lead (or in delegate mode)
2. **Architect** reads code, produces a plan
3. **You** approve or reject the plan
4. **Test Writer** writes failing tests
5. **Implementer** makes tests pass
6. **Reviewer** checks the result
7. **You** merge if approved

## Switching models to save tokens

```bash
# In a Claude Code session:
/model sonnet    # Cheaper for routine work
/model haiku     # Cheapest for simple tasks
/model opus      # Full power for architecture

# Check session cost:
/cost
```

## Troubleshooting

### "Agent not found"
- Make sure you're in the repo root (where `.claude/agents/` lives)
- Check: `ls .claude/agents/*.md`

### Teammate display is cramped
- Ghostty doesn't support split panes for teammates
- Use tmux: `claude --teammate-mode tmux`
- Or navigate teammates with `Shift+Up/Down` in single terminal

### Lead keeps trying to code instead of delegating
- Switch to delegate mode: `Shift+Tab` until you see "Delegate"
- Or start with: `claude --permission-mode delegate`

### Context getting too large
- Run `/compact` when context hits ~70%
- Better: `/clear` between distinct tasks
- Best: dump plan to file, `/clear`, start fresh reading that file
