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

### Near-Zero (0 issues, 0 PRs, no pre-main branch)

These repos are already clean on GitHub but not yet added as jade-monolith submodules. Simplest to onboard.

- [ ] agent-skills — Agent Skills for Neon Serverless Postgres.
- [ ] agent-skills-1 — Agent Skills for Neon Serverless Postgres (duplicate?).
- [ ] ai2plans-gui — (no description).
- [ ] claude-code-plugins — (no description).
- [ ] claude-plugins — (no description).
- [ ] claude-plugins-1 — (no description).
- [ ] CLAUDE_CUSTOM_INSTRUCTIONS_PROJECTS — (no description).
- [ ] gordon-workspace — (no description).
- [ ] jade-dotfiles — Org dotfiles, architecture docs, Claude Code plugins.
- [ ] jade-swarm-superpowers — Agentic skills framework (upstream of jade-swarm).
- [ ] macos-claude-assist — (no description).
- [ ] parallel-ai-mcp — (no description).
- [ ] private_forks — (no description).
- [ ] public-repo-to-private-fork — (no description).
- [ ] wsl2-dotfiles-for-claude — WSL2 dotfiles scaffold for Claude Code.

### Low Debt (1-2 issues/PRs)

- [ ] claude-cli-assist — 0 issues, 2 PRs.
- [ ] jade-dotfiles-dev — 0 issues, 1 PR.
- [ ] jadecli-claudellama-docker — 0 issues, 1 PR. Default branch: `master`.
- [ ] jadecli-docker-claude-experimentation — 0 issues, 1 PR.
- [ ] jadecli_platform_claude — 1 issue, 0 PRs.
- [ ] mac-audit — 0 issues, 1 PR. Default branch: `staging`.

### Medium Debt (3-10 issues/PRs)

- [ ] 26-04-wslg-build-template — 0 issues, 8 PRs.
- [ ] jadecli — 1 issue, 7 PRs.

### High Debt (10+ issues/PRs)

- [ ] jadeflow — 46 issues, 19 PRs. Tracked separately as jadeflow ecosystem.

## Onboarding Process

For each repo to reach zero debt:

1. **Assess** — Check open issues/PRs, determine if they're stale or actionable
2. **Triage** — Close stale issues/PRs, merge valid work, resolve conflicts
3. **Branch setup** — Create `pre-main` branch if missing, sync with `main`
4. **Submodule** — Add as git submodule in `jade-monolith/packages/`
5. **Release** — Merge any release-please PRs, cut versions if applicable
6. **Verify** — Run `scripts/health-check.sh` to confirm zero debt

## Priority Order (Recommended)

Grouped by effort, simplest first:

### Batch 1: Near-Zero (15 repos, ~5 min each)
Already clean, just need submodule addition and branch setup.
See "Near-Zero" list above.

### Batch 2: Low Debt (6 repos, ~15 min each)
1-2 PRs/issues to triage before onboarding.
See "Low Debt" list above.

### Batch 3: Medium Debt (2 repos, ~30 min each)
Multiple PRs need assessment.

### Batch 4: High Debt (1 repo)
jadeflow has 65 open items — separate project.
