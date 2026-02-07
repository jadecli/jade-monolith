---
name: agent-teams
description: Claude Agent Teams operations reference, 100-agent swarm workflow patterns, and team coordination guide
---

# Agent Teams & Swarm Quick Reference

## Enable Agent Teams
```bash
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
```

## Permission Modes (cycle with Shift+Tab)
- **Normal** — standard permissions, ask for approval
- **Auto-Accept** — approve all tool uses automatically
- **Plan** — read-only, cannot modify files
- **Delegate** — coordination only, cannot write code (requires active team)

## Start with a specific agent
```bash
claude --agent swarm-orchestrator   # Launch the 100-agent swarm orchestrator
claude --agent architect            # Architecture planning
claude --agent implementer          # Code implementation
claude --agent test-writer          # TDD test writing
claude --agent reviewer             # Code review
claude --agent debugger             # Debugging specialist
```

## Swarm Skills (invoke with /)
| Skill | Purpose |
|-------|---------|
| /swarm | Full 100-agent swarm orchestration |
| /swarm-research | Multi-agent research investigation |
| /swarm-develop | TDD development workflow |
| /swarm-review | Multi-perspective code review |
| /swarm-debug | Competing-hypothesis debugging |
| /swarm-deploy | Release preparation pipeline |
| /swarm-status | Display swarm roster and status |

## Swarm Architecture (Kimi K2-inspired)

```
                    ┌─────────────────────┐
                    │  swarm-orchestrator  │  (Lead, Delegate Mode)
                    │   task-decomposer   │
                    │   context-manager   │
                    └────────┬────────────┘
                             │
            ┌────────────────┼────────────────┐
            │                │                │
    ┌───────┴──────┐  ┌──────┴──────┐  ┌──────┴──────┐
    │  Research     │  │ Development │  │   Review    │
    │  10 agents   │  │  16 agents  │  │  11 agents  │
    └──────────────┘  └─────────────┘  └─────────────┘
            │                │                │
    ┌───────┴──────┐  ┌──────┴──────┐  ┌──────┴──────┐
    │  Testing     │  │   DevOps    │  │  Debugging  │
    │  11 agents   │  │  10 agents  │  │  10 agents  │
    └──────────────┘  └─────────────┘  └─────────────┘
```

## 100-Agent Roster by Category

### Orchestration (5)
swarm-orchestrator, task-decomposer, context-manager, progress-tracker, conflict-resolver

### Architecture & Planning (6)
architect, domain-modeler, api-designer, schema-designer, migration-planner, dependency-architect

### Research (10)
deep-researcher, codebase-explorer, api-researcher, library-evaluator, benchmark-researcher,
standards-researcher, security-researcher, performance-researcher, ux-researcher, competitor-analyst

### Development (16)
implementer, frontend-dev, backend-dev, fullstack-dev, database-dev, api-dev, cli-dev, sdk-dev,
ui-component-dev, state-management-dev, data-pipeline-dev, realtime-dev, auth-dev, search-dev,
notification-dev, config-dev

### Testing (11)
test-writer, integration-tester, e2e-tester, load-tester, security-tester, accessibility-tester,
api-tester, visual-regression-tester, mutation-tester, contract-tester, fuzzer

### Review & Quality (11)
reviewer, security-auditor, performance-reviewer, accessibility-reviewer, documentation-reviewer,
api-conformance-checker, style-enforcer, complexity-analyzer, dependency-auditor, license-checker,
breaking-change-detector

### DevOps & Infrastructure (10)
devops-engineer, ci-cd-specialist, container-specialist, cloud-architect, monitoring-engineer,
incident-responder, capacity-planner, release-manager, environment-manager, infrastructure-auditor

### Documentation (5)
documentation-writer, api-doc-writer, tutorial-writer, changelog-writer, architecture-doc-writer

### Data & Analytics (5)
data-scientist, data-engineer, ml-engineer, analytics-engineer, data-quality-engineer

### Specialized (10)
i18n-specialist, a11y-specialist, seo-specialist, compliance-checker, gdpr-specialist,
performance-optimizer, memory-optimizer, bundle-optimizer, query-optimizer, cache-strategist

### Communication (5)
tech-writer, stakeholder-communicator, sprint-planner, retrospective-facilitator, decision-logger

### Debugging & Diagnostics (10)
debugger, log-analyzer, error-tracker, memory-profiler, cpu-profiler, network-debugger,
race-condition-detector, deadlock-detector, regression-detective, root-cause-analyzer

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

## Swarm Hooks (Automatic)

| Hook | Event | Purpose |
|------|-------|---------|
| swarm-quality-gate.sh | TaskCompleted | Validates uncommitted changes and lint |
| swarm-teammate-idle.sh | TeammateIdle | Ensures agents commit before idle |
| swarm-file-guard.sh | PreToolUse (Write/Edit) | Prevents modifying protected files |

## Token Cost Management
- Opus: architecture, security audit, debugging only
- Sonnet: 80% of implementation (switch with /model sonnet)
- Haiku: exploration, linting, quick tasks (switch with /model haiku)
- Run /compact when context exceeds 70%
- Run /cost to check session spending
