# jadecli Repo Checklist

39 repositories in `github.com/jadecli` (excluding jade-monolith itself).

**Zero debt** = 0 open issues, 0 open PRs, pre-main = main, included as jade-monolith submodule.

## Zero Debt (15/39)

These repos are fully triaged, all branches synced, and tracked as jade-monolith submodules.

- [x] claude-objects — FastMCP servers, agents (Python). Released 0.3.0.
- [x] dotfiles — chezmoi-managed dotfiles with age encryption.
- [x] jade-claude-settings — Claude Code plugins, research docs, WSL2 setup. Released 0.4.0.
- [x] jade-cli — React Ink CLI task manager. Released 0.2.0.
- [x] jade-dev-assist — JADE Developer Assistant plugin. Released 1.2.0.
- [x] jade-docker — Docker configs.
- [x] jade-ecosystem-assist — Ecosystem context and scaffolds. Released 0.4.0.
- [x] jade-ide — VS Code fork for jadecli. Release 0.2.0 pending (PR #8).
- [x] jade-index — Merkle tree codebase indexer (Python/GPU). Released 0.2.0.
- [x] jade-swarm — Swarm orchestration skills (fork of obra/superpowers). Released 4.3.0.
- [x] jadecli-codespaces — Shared Codespace for Claude agent collaboration.
- [x] jadecli-infra — Docker Compose stack. Released 1.2.0.
- [x] jadecli-roadmap-and-architecture — ADRs and architecture diagrams. Released 1.2.0.
- [x] jadeflow-dev-scaffold — Scaffold governance. 1 issue (jadeflow ecosystem, tracked separately).

## Needs Triage (24/39)

### Batch 1: Near-Zero — 0 issues, 0 PRs, minimal branches (9 repos)

Simplest to onboard. Only need `pre-main` branch + submodule addition. Some may be candidates for archiving.

| Repo | Branches | Description | Notes |
|------|----------|-------------|-------|
| ai2plans-gui | 1 (`main`) | (no description) | Single branch, likely minimal |
| CLAUDE_CUSTOM_INSTRUCTIONS_PROJECTS | 1 (`main`) | (no description) | Single branch |
| gordon-workspace | 1 (`main`) | (no description) | Single branch |
| jade-dotfiles | 2 (`main`, `claude/research-vscode-fork-6Xiv5`) | Org dotfiles, arch docs, Claude Code plugins | 1 stale feature branch |
| jade-swarm-superpowers | 16 branches | Agentic skills framework (upstream of jade-swarm) | Heavy branching: `jadecli-main`, `dev`, `enable-codex`, `opencode-native-skills`, etc. Needs branch cleanup |
| private_forks | 1 (`main`) | (no description) | Single branch |
| public-repo-to-private-fork | 1 (`main`) | (no description) | Single branch |
| wsl2-dotfiles-for-claude | 1 (`main`) | WSL2 dotfiles scaffold for Claude Code | Single branch |

### Batch 2: Near-Zero with feature branches — 0 issues, 0 PRs, multiple branches (6 repos)

Clean on GitHub but have stale feature branches to clean up.

| Repo | Branches | Description | Branch Details |
|------|----------|-------------|----------------|
| agent-skills | 5 | Neon Serverless Postgres skills | `jadecli-main`, `danieltprice-patch-1`, `refactor/rename-skill-neon-postgres`, `update-neon-urls` |
| agent-skills-1 | 5 | Neon skills (duplicate of above?) | Identical branch structure to agent-skills |
| claude-code-plugins | 10 | (no description) | `jadecli-main` + 8 feature branches (`zb/*`, `skill/ruff`) |
| claude-plugins | 5 | (no description) | `jadecli-main`, `mcp-toolkit-beta-plugin`, `slim/cleanup-naming`, `task/marketplace-bootstrap` |
| claude-plugins-1 | 5 | (no description) | Identical branch structure to claude-plugins |
| macos-claude-assist | 4 | (no description) | `claude/migrate-jadecli-org`, `docs/update-documentation`, `fix/restore-package-name` |

### Batch 3: Low Debt — 1-2 issues/PRs (6 repos)

| Repo | Issues | PRs | Branches | Description | Branch Details |
|------|--------|-----|----------|-------------|----------------|
| claude-cli-assist | 0 | 2 | 5 | (no description) | `claude/*` agent branches, `feat/multi-agent`, `release-please--*` |
| jade-dotfiles-dev | 0 | 1 | 2 | (no description) | `feature/taskmaster-tasks` |
| jadecli-claudellama-docker | 0 | 1 | 3 | (no description) | Default: `master`. `claude/research-*`, `feat/fastmcpp3-*` |
| jadecli-docker-claude-experimentation | 0 | 1 | 3 | (no description) | `claude/add-implementation-plan`, `feature/multi-agent-research` |
| jadecli_platform_claude | 1 | 0 | 1 | (no description) | Just `main` |
| mac-audit | 0 | 1 | 4 | (no description) | Default: `staging`. Has `release-please--*` branch |

### Batch 4: Medium Debt — 3-10 issues/PRs (2 repos)

| Repo | Issues | PRs | Branches | Description | Branch Details |
|------|--------|-----|----------|-------------|----------------|
| 26-04-wslg-build-template | 0 | 8 | 13 | (no description) | `copilot/*`, `docs/*`, `feat/wsl-*` (8 feature branches), `staging` |
| jadecli | 1 | 7 | 9 | (no description) | All `claude/*` agent branches + `feat/claude-context-codespaces` |

### Batch 5: High Debt (1 repo)

| Repo | Issues | PRs | Branches | Description | Branch Details |
|------|--------|-----|----------|-------------|----------------|
| jadeflow | 46 | 19 | 20 | (no description) | `claude/*` research branches, `feat/*`, `test/*`. Separate project. |

### Batch 6: Stale/Feature-heavy — 0 issues, 0 PRs, many branches (1 repo)

| Repo | Branches | Description | Branch Details |
|------|----------|-------------|----------------|
| parallel-ai-mcp | 10 | (no description) | 7 `01-31-feat_indexer_*` branches, `coderabbitai/*`, `release-please--*` |

## Duplicate Candidates

These pairs appear to be duplicates and should be assessed for archiving:

| Original | Duplicate | Evidence |
|----------|-----------|----------|
| agent-skills | agent-skills-1 | Identical description, identical branch structure |
| claude-plugins | claude-plugins-1 | Identical branch structure |
| jade-swarm (zero-debt) | jade-swarm-superpowers | jade-swarm is the private fork; superpowers is upstream |
| dotfiles (zero-debt) | jade-dotfiles | Both manage dotfiles |
| dotfiles (zero-debt) | wsl2-dotfiles-for-claude | WSL2-specific dotfiles |

## Archive Candidates

Repos that appear to be one-off experiments or superseded:

| Repo | Reason |
|------|--------|
| CLAUDE_CUSTOM_INSTRUCTIONS_PROJECTS | Likely superseded by jade-claude-settings |
| gordon-workspace | Unknown purpose, single branch |
| private_forks | Utility repo, may not need tracking |
| public-repo-to-private-fork | Utility repo, may not need tracking |
| jade-dotfiles-dev | Likely superseded by dotfiles |

## Onboarding Process

For each repo to reach zero debt:

1. **Assess** — Check open issues/PRs, determine if they're stale or actionable
2. **Triage** — Close stale issues/PRs, merge valid work, resolve conflicts
3. **Branch cleanup** — Delete stale feature branches
4. **Branch setup** — Create `pre-main` branch if missing, sync with `main`
5. **Submodule** — Add as git submodule in `jade-monolith/packages/`
6. **Release** — Merge any release-please PRs, cut versions if applicable
7. **Verify** — Run `scripts/health-check.sh` to confirm zero debt

## Recommended Approach

1. **Human review** — Decide which repos to archive vs onboard (this PR)
2. **Batch 1** — Onboard the ~9 simplest repos (parallel, automated)
3. **Batch 2** — Clean branches + onboard 6 repos
4. **Batch 3** — Triage 1-2 PRs each for 6 repos
5. **Batch 4+** — Tackle medium/high debt repos individually
