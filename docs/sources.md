# Sources Registry

> Version-controlled references used across PRs.
> Every PR that cites external sources adds them here for traceability.
> Format: `| Title | URL | PRs | Category | Last Verified |`

## Why track sources?

1. **Reproducibility** — Future agents can re-read the same references
2. **Freshness auditing** — Weekly CI can flag stale or dead links
3. **Knowledge graph** — Shows which PRs built on which research
4. **Onboarding** — New contributors see the project's research lineage

## Source Categories

| Code | Category |
|------|----------|
| `agent-teams` | Claude Code Agent Teams architecture |
| `claude-code` | Claude Code CLI features and releases |
| `api` | Anthropic API and SDK |
| `infra` | Infrastructure, CI/CD, toolchain |
| `ecosystem` | jadecli ecosystem management |

## Registry

| Title | URL | PRs | Category | Last Verified |
|-------|-----|-----|----------|---------------|
| Claude Code Subagents Documentation | https://code.claude.com/docs/en/sub-agents | #3 | agent-teams | 2026-02-07 |
| Claude Code Agent Teams Multi-Agent Orchestration | https://claudefa.st/blog/guide/agents/agent-teams | #3 | agent-teams | 2026-02-07 |

## Adding Sources

When opening a PR that used external references:

1. Add each source to the **Registry** table above
2. List the PR number in the `PRs` column (comma-separated for multiple)
3. Set `Last Verified` to the date you confirmed the link works
4. Include the same sources in your PR's `## Sources` section

When a source appears in multiple PRs, append the new PR number:
```
| Title | URL | #1, #4, #7 | category | date |
```
