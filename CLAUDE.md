# jade-monolith

Consolidated archive of 14 jadecli ecosystem repos. Each package is a git submodule pinned to its `pre-main` branch — the best integrated state of all work.

## Purpose

This is a **reference archive** for browsing and cherry-picking code into new projects. Each package is independent — do not cross-reference between packages.

## Structure

```
jade-monolith/
├── packages/                          # 14 git submodules (pre-main)
│   ├── claude-objects/                # FastMCP servers, agents (Python)
│   ├── dotfiles/                      # Dev environment (chezmoi)
│   ├── jade-claude-settings/          # Plugins & research (Markdown)
│   ├── jade-cli/                      # Terminal UI (TypeScript/React Ink)
│   ├── jade-dev-assist/               # Task orchestrator (JavaScript)
│   ├── jade-docker/                   # Docker configs
│   ├── jade-ecosystem-assist/         # Ecosystem context & scaffolds
│   ├── jade-ide/                      # VS Code fork (TypeScript)
│   ├── jade-index/                    # Semantic search (Python/GPU)
│   ├── jade-swarm/                    # Skills/superpowers (Markdown)
│   ├── jadecli-codespaces/            # Agent framework (Python)
│   ├── jadecli-infra/                 # Docker infrastructure
│   ├── jadecli-roadmap-and-architecture/ # ADRs & diagrams
│   └── jadeflow-dev-scaffold/         # Scaffold governance
├── scripts/                           # Reusable ecosystem utilities
│   ├── git-status-all.sh              # 14-repo status (JSON/table)
│   ├── pr-health.sh                   # PR health dashboard
│   └── create-issues-for-prs.sh       # Auto-link PRs to issues
├── .claude/
│   ├── tasks/tasks.json               # Task registry
│   └── rules/                         # Guardrail rules
└── CLAUDE.md                          # This file
```

## Package Isolation Rules (STRICT)

**These rules are mandatory. Violations must be flagged and blocked.**

1. **One package at a time.** Every task targets exactly one `packages/<name>/`. Never modify files in two different packages in the same task.
2. **No cross-references.** Do not import, require, or reference code from another package. Each package is self-contained.
3. **No shared state.** Do not create files outside `packages/` that bridge packages. The only shared files are in `scripts/` (read-only utilities) and `.claude/` (task management).
4. **Task-gated changes.** Only make changes that are explicitly described in a task from `.claude/tasks/tasks.json`. If work is needed that isn't in a task, create the task first, get approval, then execute.
5. **Submodule commits stay local.** Commit inside the submodule, push to the submodule's origin. Then update the submodule ref in the monolith root.

## Agent Configuration

All agents use:
- **Model:** `claude-opus-4-6` (adaptive thinking enabled by default — do NOT use manual/extended thinking)
- **max_turns:** 25 per agent (15 for retries)
- **Context budget:** 200K standard, wrap-up at 170K tokens

### Context Wrap-Up Protocol (170K threshold)

When approaching 170K tokens of context:
1. **Stop starting new tasks.** Finish the current task only.
2. **Write a 500-token summary** of what was accomplished and what remains.
3. **Save summary** to `.claude/tasks/context-handoff.md` with:
   - Tasks completed (IDs + one-line status)
   - Tasks remaining (IDs + blockers if any)
   - Files modified in this session
   - Any gotchas or decisions made
4. **Commit all work** before the session ends.
5. **Next session** reads `context-handoff.md` first to restore context.

### Retry Budget

On task failure:
- First retry: full 25 turns with 500-token failure summary from previous attempt
- Second retry: 15 turns with compressed context
- Third failure: escalate to human with diagnostic summary

## Task Format

Tasks live in `.claude/tasks/tasks.json`. Schema:

```json
{
  "tasks": [
    {
      "id": "package-name/task-slug",
      "title": "Human-readable title",
      "description": "What to do and acceptance criteria",
      "package": "package-name",
      "status": "pending|in_progress|completed|blocked",
      "complexity": "S|M|L|XL",
      "blocked_by": [],
      "labels": ["feat", "fix", "test", "docs", "chore"],
      "created_at": "2026-02-06"
    }
  ]
}
```

### Task Lifecycle

1. **pending** — Ready to work. Check `blocked_by` is empty.
2. **in_progress** — Agent is actively working. Only one task per package at a time.
3. **completed** — Work done, committed, pushed.
4. **blocked** — Cannot proceed. `blocked_by` lists the blocking task IDs.

### Guardrail Checkpoints

Before ANY code change, the agent MUST:
1. Verify a task exists in tasks.json for this work
2. Verify the task targets exactly one package
3. Set task status to `in_progress`
4. Confirm no other task is `in_progress` for the same package

After completing work:
1. Run the package's linter/tests if available
2. Commit with conventional commit format
3. Set task status to `completed`
4. Check for newly unblocked tasks

## Scripts

### `scripts/git-status-all.sh`
Token-efficient status for all 14 repos. Run from monolith root.
```bash
./scripts/git-status-all.sh          # table view
./scripts/git-status-all.sh --json   # JSON for programmatic use
```

### `scripts/pr-health.sh`
PR health dashboard — total, unlinked, release-please counts.
```bash
./scripts/pr-health.sh               # table view
./scripts/pr-health.sh --json        # JSON output
```

### `scripts/create-issues-for-prs.sh`
Auto-create GitHub issues for unlinked PRs and update PR bodies.
```bash
./scripts/create-issues-for-prs.sh <repo-name>           # execute
./scripts/create-issues-for-prs.sh <repo-name> --dry-run  # preview
```

## Conventions

- **Commits:** Conventional commits (`feat:`, `fix:`, `test:`, `docs:`, `chore:`)
- **Co-author:** `Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>`
- **Branches:** Work on `pre-main` within each submodule
- **GitHub org:** `jadecli`

## Claude Code Plugins

6 marketplaces, 10 plugins enabled. Configured in `~/.claude/settings.json`.

### Marketplaces

| Marketplace | Source |
|---|---|
| claude-plugins-official | GitHub (anthropics) |
| taskmaster | GitHub (eyaltoledano) |
| docker | GitHub (docker) |
| neon-agent-skills | GitHub (neondatabase) |
| astral-sh | GitHub (astral-sh) |
| jadecli | Local (~/projects/jadecli-marketplace) |

### Plugins

| Plugin | Marketplace | Scope |
|---|---|---|
| superpowers | claude-plugins-official | project |
| code-review | claude-plugins-official | project |
| pr-review-toolkit | claude-plugins-official | project |
| code-simplifier | claude-plugins-official | project |
| taskmaster | taskmaster | project |
| mcp-toolkit | docker | project |
| neon-postgres | neon-agent-skills | project |
| astral | astral-sh | user |
| jade-swarm-superpowers | jadecli | user |
| jade-dev-assist | jadecli | user |

### jadecli Marketplace (local symlinks)

The `jadecli` marketplace at `~/projects/jadecli-marketplace/` uses local symlinks because the plugin repos are currently private. Inline `_TODO` comments mark the GitHub source configs ready to swap in.

**Tracking issues:**
- [jadeflow#72](https://github.com/jadecli/jadeflow/issues/72) — Make jade-swarm public
- [jadeflow#73](https://github.com/jadecli/jadeflow/issues/73) — Make jade-dev-assist public

After making repos public, update `marketplace.json` to replace `"source": "./..."` with the `_TODO_source_github` values, remove the symlinks and `_TODO` fields, then run `claude plugin marketplace update jadecli`.

## Hardware Context

- CPU: AMD Ryzen 9 3900X (12c/24t)
- RAM: 128GB (96GB WSL2 allocation)
- GPU: RTX 2080 Ti 11GB VRAM
- Platform: WSL2 Ubuntu 26.04
