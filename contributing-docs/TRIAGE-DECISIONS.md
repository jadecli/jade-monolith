# Triage Decisions — 2026-02-07

24 repos assessed across 4 batches. Decisions: 5 ONBOARD, 1 MERGE+ARCHIVE, 18 ARCHIVE.

```
╔══════════════════════════════════════════════════════════════════════════════╗
║                    JADE-MONOLITH TRIAGE DECISION MAP                       ║
╚══════════════════════════════════════════════════════════════════════════════╝

  24 repos in packages-triage/ ──> 3 possible outcomes:

  ┌─────────┐     ┌─────────────┐     ┌───────────┐
  │ ONBOARD │     │ MERGE then  │     │  ARCHIVE  │
  │ move to │     │ ARCHIVE     │     │  (delete) │
  │packages/│     │             │     │           │
  └────┬────┘     └──────┬──────┘     └─────┬─────┘
       │                 │                   │
       ▼                 ▼                   ▼
   5 repos            1 repo             18 repos


═══════════════════════════════════════════════════════════════════════════════
 BATCH 1 — Near-zero effort (7 repos)
═══════════════════════════════════════════════════════════════════════════════

  ai2plans-gui ························ ARCHIVE  (160MB, superseded by jade-index)
  wsl2-dotfiles-for-claude ············ ARCHIVE  (staging repo, purpose fulfilled)
  CLAUDE_CUSTOM_INSTRUCTIONS_PROJECTS · ARCHIVE  (empty, 0KB)
  gordon-workspace ···················· ARCHIVE  (duplicate infra stack, 2 commits)
  private_forks ······················· ARCHIVE  (170MB personal experiments)
  public-repo-to-private-fork ········· ARCHIVE  (empty, 0KB)
  jade-dotfiles ······················· MERGE ──┐
                                                │
                    ┌───────────────────────────┘
                    │  migrate 3 things before archiving:
                    │
                    ├─► ARCH-000..004 docs ──► jadecli-roadmap-and-architecture
                    ├─► marketplace.json ────► jade-claude-settings
                    └─► mise config ────────► dotfiles

═══════════════════════════════════════════════════════════════════════════════
 BATCH 2 — Stale branches (8 repos)
═══════════════════════════════════════════════════════════════════════════════

  agent-skills ························ ARCHIVE  (unmodified fork of neondatabase)
  agent-skills-1 ······················ ARCHIVE  (exact duplicate of above)
  claude-code-plugins ················· ARCHIVE  (unmodified fork of astral-sh)
  claude-plugins ······················ ARCHIVE  (unmodified fork of docker)
  claude-plugins-1 ···················· ARCHIVE  (exact duplicate of above)
  jade-swarm-superpowers ·············· ARCHIVE  (superseded by jade-swarm)

  macos-claude-assist ················· ONBOARD ★  React Ink + MCP, 300 tests
  parallel-ai-mcp ···················· ONBOARD ★  11K lines, 40+ MCP tools

═══════════════════════════════════════════════════════════════════════════════
 BATCH 3 — Low debt (6 repos)
═══════════════════════════════════════════════════════════════════════════════

  claude-cli-assist ··················· ARCHIVE  (overlaps jade-dev-assist)
  jade-dotfiles-dev ··················· ARCHIVE  (168MB legacy monorepo)
  jadecli-claudellama-docker ·········· ARCHIVE  (overlaps jade-index + infra)
  jadecli-docker-claude-experimentation ARCHIVE  (67 bytes of code)
  jadecli_platform_claude ············· ARCHIVE  (single README, no code)

  mac-audit ··························· ONBOARD ★  21 security scan agents, v1.1.1

═══════════════════════════════════════════════════════════════════════════════
 BATCH 4 + UNLISTED (3 repos)
═══════════════════════════════════════════════════════════════════════════════

  jadecli ····························· ARCHIVE  (7 stale PRs, 0 merged ever)

  26-04-wslg-build-template ··········· ONBOARD ★  WSL2 env validation, rename
                                                    to jade-wslg
  jadecli-marketplace ················· ONBOARD ★  plugin registry (critical
                                                    infrastructure)


═══════════════════════════════════════════════════════════════════════════════
 AFTER EXECUTION — packages/ would contain:
═══════════════════════════════════════════════════════════════════════════════

  packages/                          packages/                (NEW)
  ├── claude-objects        ✓        ├── macos-claude-assist   ★
  ├── dotfiles              ✓        ├── parallel-ai-mcp      ★
  ├── jade-claude-settings  ✓        ├── mac-audit            ★
  ├── jade-cli              ✓        ├── jade-wslg            ★  (renamed)
  ├── jade-dev-assist       ✓        └── jadecli-marketplace  ★
  ├── jade-docker           ✓
  ├── jade-ecosystem-assist ✓        14 existing + 5 new = 19 total
  ├── jade-ide              ✓
  ├── jade-index            ✓        packages-triage/  ──► DELETED
  ├── jade-swarm            ✓        (all 24 repos removed after
  ├── jadecli-codespaces    ✓         decisions executed)
  ├── jadecli-infra         ✓
  ├── jadecli-roadmap-...   ✓
  └── jadeflow-dev-scaffold ✓


═══════════════════════════════════════════════════════════════════════════════
 BEFORE YOU ARCHIVE — extract these ideas first:
═══════════════════════════════════════════════════════════════════════════════

  claude-cli-assist ──────────► jade-dev-assist issue:
                                "MCP token-budget LRU caching"

  jadecli-claudellama-docker ─► jade-index issues:
                                "Context7 symbol addressing"
                                "Colin lineage tracking"

  jade-dotfiles ──────────────► 3-way content migration (see Batch 1)

  jadecli ────────────────────► close 7 PRs with redirect notes
```
