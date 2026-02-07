# Tasks — Checkpoint 2026-02-07T09:30Z

44 tasks completed. 0 onboarding issues open (all 24 repos resolved).
19 submodules in packages/. 19 repos archived. 12 releases cut.

## Ecosystem Status

| Package | GitHub Repo | Status |
|---------|-------------|--------|
| claude-objects | [jadecli/claude-objects](https://github.com/jadecli/claude-objects) | Clean — released 0.3.0 |
| dotfiles | [jadecli/dotfiles](https://github.com/jadecli/dotfiles) | Clean |
| jade-claude-settings | [jadecli/jade-claude-settings](https://github.com/jadecli/jade-claude-settings) | Clean — released 0.4.0 |
| jade-cli | [jadecli/jade-cli](https://github.com/jadecli/jade-cli) | Clean — released 0.2.0 |
| jade-dev-assist | [jadecli/jade-dev-assist](https://github.com/jadecli/jade-dev-assist) | Clean — released 1.2.0 |
| jade-docker | [jadecli/jade-docker](https://github.com/jadecli/jade-docker) | Clean |
| jade-ecosystem-assist | [jadecli/jade-ecosystem-assist](https://github.com/jadecli/jade-ecosystem-assist) | Clean — released 0.4.0 |
| jade-ide | [jadecli/jade-ide](https://github.com/jadecli/jade-ide) | Clean — released 0.2.0 |
| jade-index | [jadecli/jade-index](https://github.com/jadecli/jade-index) | Clean — released 0.2.0 |
| jade-swarm | [jadecli/jade-swarm](https://github.com/jadecli/jade-swarm) | Clean — released 4.3.0 |
| jadecli-codespaces | [jadecli/jadecli-codespaces](https://github.com/jadecli/jadecli-codespaces) | Clean |
| jadecli-infra | [jadecli/jadecli-infra](https://github.com/jadecli/jadecli-infra) | Clean — released 1.2.0 |
| jadecli-roadmap | [jadecli/jadecli-roadmap-and-architecture](https://github.com/jadecli/jadecli-roadmap-and-architecture) | Clean — released 1.2.0 |
| jadeflow-dev-scaffold | [jadecli/jadeflow-dev-scaffold](https://github.com/jadecli/jadeflow-dev-scaffold) | Clean |
| jade-wslg | [jadecli/26-04-wslg-build-template](https://github.com/jadecli/26-04-wslg-build-template) | Onboarded |
| mac-audit | [jadecli/mac-audit](https://github.com/jadecli/mac-audit) | Onboarded |
| macos-claude-assist | [jadecli/macos-claude-assist](https://github.com/jadecli/macos-claude-assist) | Onboarded |
| parallel-ai-mcp | [jadecli/parallel-ai-mcp](https://github.com/jadecli/parallel-ai-mcp) | Onboarded |
| jadecli-marketplace | [jadecli/jade-swarm-superpowers](https://github.com/jadecli/jade-swarm-superpowers) | Onboarded |
| jade-monolith | [jadecli/jade-monolith](https://github.com/jadecli/jade-monolith) | Clean |

## Session 4 Tasks — Triage Execution

| Task ID | Title | Status | Resolution |
|---------|-------|--------|------------|
| monolith/triage-assess | Assess all 24 triage repos (batches 1–4) | Done | 5 ONBOARD, 18 ARCHIVE, 1 MERGE+ARCHIVE |
| monolith/triage-backup | Save backup branch with all 24 submodules | Done | feat/triage-submodules branch + TRIAGE-DECISIONS.md |
| monolith/extract-preservation | Create GitHub issues for content worth preserving | Done | jade-dev-assist #17, #18; jade-index #16, #17 |
| monolith/migrate-dotfiles | Migrate jade-dotfiles content to 3 target repos | Done | roadmap#16, settings#22, dotfiles#7 merged |
| monolith/close-jadecli-prs | Close 7 stale PRs on jadecli repo | Done | PRs #1–#3, #5–#8 closed with redirect comments |
| monolith/close-batch34-items | Close open items on batch 3/4 repos | Done | 15 items closed across 7 repos |
| monolith/onboard-5-repos | Add 5 repos as submodules in packages/ | Done | PR#27 merged — 19 total submodules |
| monolith/archive-18-repos | Archive 18 repos on GitHub | Done | 3 migration PRs merged, 25 branches deleted, 18 repos archived |
| monolith/remove-triage | Remove packages-triage/ local directory | Done | Local-only dir removed, no commit needed |
| monolith/close-onboarding-issues | Close all 23 onboarding issues (#3–#25) | Done | All closed with resolution comments |
| monolith/update-tasks-4 | Update TASKS.md and REGISTRY.md | Done | This update |

## Session 3 Tasks

| Task ID | Title | Status | Resolution |
|---------|-------|--------|------------|
| monolith/agent-teams-config | Port Agent Teams config from jadeflow PR #31 | Done | PR#26 — 4 agents, tests, PR templates, 26 files |
| monolith/repo-audit | Audit all 39 repos, create REGISTRY + CHECKLIST | Done | PR#2 — contributing-docs/, 23 issues (#3–#25) |
| monolith/onboarding-issues | Create GitHub issues for 24 non-zero-debt repos | Done | Issues #3–#25 with batch/status/action labels |
| monolith/jade-ide-release | Merge jade-ide release PR #8 (v0.2.0) | Done | Released 0.2.0, pre-main synced |
| monolith/sync-pre-main-3 | Sync pre-main with main after merges | Done | pre-main = main at 349524c |
| monolith/branch-cleanup-3 | Delete merged feature branches | Done | feat/agent-teams-config, research/repo-audit |
| monolith/update-settings | Merge agent teams env/permissions into settings.json | Done | .claude/settings.json updated |
| monolith/update-tasks-3 | Update TASKS.md with session 3 work | Done | This update |

## Monolith Tasks (Session 2)

| Task ID | Title | Status | Resolution |
|---------|-------|--------|------------|
| monolith/statusline | Add Claude Code statusline | Done | scripts/statusline.sh + .claude/settings.json |
| monolith/sync-submodules | Update all 14 submodules to latest main | Done | 13 updated, jade-docker already current |
| monolith/merge-roadmap-release | Merge jadecli-roadmap release-please PR #15 | Done | v1.2.0 released, pre-main synced |
| monolith/submodule-update-script | Batch submodule update script | Done | scripts/update-submodules.sh |
| monolith/pre-main-sync-script | Pre-main/main sync script | Done | scripts/sync-branches.sh |
| monolith/release-merge-script | Batch release-please merge script | Done | scripts/merge-releases.sh |
| monolith/ecosystem-health-script | Ecosystem health check script | Done | scripts/health-check.sh |

## Triage Tasks (Session 1)

| Task ID | Package | Title | Resolution |
|---------|---------|-------|------------|
| monolith/initial-commit | _monolith | Initial commit of jade-monolith scaffolding | Committed |
| monolith/update-projects-json | _monolith | Add jade-monolith to ~/.jade/projects.json | Done |
| claude-objects/review-pre-main | claude-objects | Review and validate pre-main state | All PRs merged, 0 open issues |
| dotfiles/review-pre-main | dotfiles | Review pre-main; triage issues | All issues closed |
| jade-claude-settings/merge-pr-14 | jade-claude-settings | Merge commitlint + husky | PR#14 closed (bloated), PR#19 merged as clean replacement |
| jade-claude-settings/triage-issues | jade-claude-settings | Triage issues #3–#5 | All closed |
| jade-cli/triage-issues | jade-cli | Triage issues #11–#14 | All closed |
| jade-cli/review-pre-main | jade-cli | Review pre-main after PR #7 merge | PR#7 merged, release 0.2.0 cut |
| jade-dev-assist/triage-issues | jade-dev-assist | Triage issues #11–#13 | All closed |
| jade-dev-assist/review-pre-main | jade-dev-assist | Review pre-main after PRs #5, #9 merge | Both merged, release 1.2.0 cut |
| jade-docker/review-pre-main | jade-docker | Review and validate pre-main state | Clean |
| jade-ecosystem-assist/triage-issues | jade-ecosystem-assist | Triage issues #2–#4, #12 | All closed; #3 resolved by PR#14 |
| jade-ide/assess-prs | jade-ide | Assess PR #2 and PR #3 | Both closed (superseded by PR#4) |
| jade-index/triage-issues | jade-index | Triage issues #9–#14 (Neon roadmap) | All closed |
| jade-index/review-pre-main | jade-index | Review pre-main after cherry-pick | Release 0.2.0 cut |
| jade-swarm/triage-issues | jade-swarm | Triage issues #5–#7 | All closed (PRs merged) |
| jadecli-codespaces/triage-issues | jadecli-codespaces | Triage issues #9–#12 | All closed |
| jadecli-infra/resolve-issue-6 | jadecli-infra | Assess issue #6 (e2e smoke test) | Closed — PR#5 merged |
| jadecli-roadmap/close-tracking-issue | jadecli-roadmap | Close issue #13 | Closed |
| jadecli-roadmap/triage-issues | jadecli-roadmap | Triage issues #9–#12 | All closed |
| jadeflow-dev-scaffold/triage-issues | jadeflow-dev-scaffold | Triage issues #1, #2 | Open (separate jadeflow ecosystem) |

## Releases Cut

| Package | Version | PR |
|---------|---------|-----|
| jade-index | 0.2.0 | PR#2 |
| jade-cli | 0.2.0 | PR#6 |
| jade-claude-settings | 0.3.0 → 0.4.0 | PR#13, PR#20 |
| jade-swarm | 4.3.0 | PR#1 |
| jade-ecosystem-assist | 0.3.0 → 0.4.0 | PR#7, PR#15 |
| jadecli-infra | 1.2.0 | PR#4 |
| claude-objects | 0.3.0 | PR#5 |
| jade-dev-assist | 1.2.0 | PR#3 |
| jadecli-roadmap | 1.2.0 | PR#15 |
| jade-ide | 0.2.0 | PR#8 |

## Monolith Scripts

| Script | Purpose |
|--------|---------|
| `scripts/statusline.sh` | Claude Code statusline (branch + ecosystem counts) |
| `scripts/git-status-all.sh` | 14-repo git status (table/JSON) |
| `scripts/pr-health.sh` | PR health dashboard |
| `scripts/create-issues-for-prs.sh` | Auto-link PRs to issues |
| `scripts/update-submodules.sh` | Batch update submodules to latest main |
| `scripts/sync-branches.sh` | Sync pre-main/main across 15 repos |
| `scripts/merge-releases.sh` | Batch merge release-please PRs |
| `scripts/health-check.sh` | Ecosystem health check (submodules, GitHub, Docker, GPU) |
| `scripts/start-team.sh` | tmux 4-pane Agent Teams launcher |

## Onboarding Backlog — COMPLETE

All 24 repos resolved. 23 onboarding issues (#3–#25) closed.

| Batch | Decision | Repos |
|-------|----------|-------|
| 1: Near-zero (7) | 7 archived | ai2plans-gui, wsl2-dotfiles-for-claude, CLAUDE_CUSTOM_INSTRUCTIONS_PROJECTS, gordon-workspace, private_forks, public-repo-to-private-fork, jade-dotfiles |
| 2: Branch cleanup (8) | 5 archived, 3 onboarded | Archived: agent-skills, agent-skills-1, claude-code-plugins, claude-plugins, claude-plugins-1. Onboarded: macos-claude-assist, parallel-ai-mcp, jade-swarm-superpowers→jadecli-marketplace |
| 3: Low debt (6) | 4 archived, 2 onboarded | Archived: claude-cli-assist, jade-dotfiles-dev, jadecli-claudellama-docker, jadecli-docker-claude-experimentation, jadecli_platform_claude. Onboarded: mac-audit→jade-wslg |
| 4: Medium debt (2) | 1 archived, 1 onboarded | Archived: jadecli. Onboarded: 26-04-wslg-build-template→jade-wslg |

## Out of Scope (jadeflow ecosystem)

The jadeflow repos have their own task backlog. Tracked separately.
