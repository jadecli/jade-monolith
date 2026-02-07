# Jade 100-Agent Swarm

A 100+ agent swarm system for Claude Code, inspired by Kimi K2's PARL (Parallel-Agent Reinforcement Learning) architecture. Uses Claude Code's agent teams, subagents, skills, hooks, and persistent memory to orchestrate complex multi-agent workflows.

## Quick Start

```bash
# Launch the full swarm orchestrator
claude --agent swarm-orchestrator

# Or use swarm skills directly
/swarm "Build a user authentication system"
/swarm-research "How does WebSocket scaling work?"
/swarm-develop "Add REST API for user profiles"
/swarm-review "PR #42"
/swarm-debug "500 errors on the login endpoint"
/swarm-deploy "v2.0.0 release"
/swarm-status
```

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                    SWARM ORCHESTRATOR                         │
│  Decomposes tasks → Selects agents → Monitors → Synthesizes │
└────────────────────────────┬─────────────────────────────────┘
                             │
         ┌───────────────────┼───────────────────┐
         │                   │                   │
    ┌────┴────┐        ┌─────┴────┐        ┌────┴────┐
    │Research │        │  Build   │        │ Quality │
    │ Swarm   │        │  Swarm   │        │  Swarm  │
    │10 agents│        │32 agents │        │22 agents│
    └─────────┘        └──────────┘        └─────────┘
```

### Key Principles (from Kimi K2)

1. **Critical-Steps Metric**: Wall-clock time = orchestration overhead + slowest concurrent agent
2. **Dynamic Agent Selection**: Only spawn agents needed for the task, not all 100
3. **No Serial Collapse**: Prefer parallel execution when tasks are independent
4. **No Spurious Parallelism**: Don't spawn agents for tasks that don't benefit from parallelism
5. **File Ownership**: No two agents edit the same file simultaneously

## Agent Roster (100+ agents, 11 categories)

### Orchestration (5 agents)
| Agent | Model | Purpose |
|-------|-------|---------|
| swarm-orchestrator | opus | Central coordinator, task decomposition |
| task-decomposer | sonnet | Breaks tasks into parallelizable subtasks |
| context-manager | haiku | Manages context handoffs between sessions |
| progress-tracker | haiku | Monitors progress, detects bottlenecks |
| conflict-resolver | sonnet | Resolves file and decision conflicts |

### Architecture & Planning (6 agents)
| Agent | Model | Purpose |
|-------|-------|---------|
| architect | opus | Implementation planning, plan approval |
| domain-modeler | sonnet | DDD, entity modeling, bounded contexts |
| api-designer | sonnet | REST/GraphQL/gRPC API design |
| schema-designer | sonnet | Database schema, normalization, indexing |
| migration-planner | sonnet | Zero-downtime migration planning |
| dependency-architect | sonnet | Module boundaries, dependency graphs |

### Research (10 agents)
| Agent | Model | Purpose |
|-------|-------|---------|
| deep-researcher | opus | Multi-source synthesis research |
| codebase-explorer | haiku | Fast codebase navigation |
| api-researcher | sonnet | API patterns and documentation |
| library-evaluator | sonnet | Library fitness assessment |
| benchmark-researcher | sonnet | Performance benchmarking |
| standards-researcher | haiku | Industry standards (RFC, W3C) |
| security-researcher | sonnet | CVE research, vulnerability scanning |
| performance-researcher | sonnet | Runtime performance analysis |
| ux-researcher | sonnet | UX patterns and guidelines |
| competitor-analyst | sonnet | Competitive analysis |

### Development (16 agents)
| Agent | Model | Purpose |
|-------|-------|---------|
| implementer | opus | General implementation to plan spec |
| frontend-dev | sonnet | React, CSS, responsive design |
| backend-dev | sonnet | APIs, services, server logic |
| fullstack-dev | sonnet | Cross-stack implementation |
| database-dev | sonnet | SQL, migrations, schemas |
| api-dev | sonnet | REST/GraphQL endpoint development |
| cli-dev | sonnet | CLI tool development |
| sdk-dev | sonnet | SDK/library development |
| ui-component-dev | sonnet | Component library development |
| state-management-dev | sonnet | Redux, Zustand, signals |
| data-pipeline-dev | sonnet | ETL, streaming pipelines |
| realtime-dev | sonnet | WebSocket, SSE, pub/sub |
| auth-dev | sonnet | Authentication/authorization |
| search-dev | sonnet | Full-text, semantic, vector search |
| notification-dev | sonnet | Notification systems |
| config-dev | sonnet | Configuration management |

### Testing (11 agents)
| Agent | Model | Purpose |
|-------|-------|---------|
| test-writer | opus | TDD test-first methodology |
| integration-tester | sonnet | Module interaction testing |
| e2e-tester | sonnet | Browser/UI end-to-end tests |
| load-tester | sonnet | Performance under stress |
| security-tester | sonnet | Security-focused tests |
| accessibility-tester | sonnet | WCAG compliance tests |
| api-tester | sonnet | API contract testing |
| visual-regression-tester | sonnet | CSS/visual snapshot testing |
| mutation-tester | sonnet | Test quality verification |
| contract-tester | sonnet | Consumer-driven contracts |
| fuzzer | sonnet | Property-based/fuzz testing |

### Review & Quality (11 agents)
| Agent | Model | Purpose |
|-------|-------|---------|
| reviewer | opus | General code review |
| security-auditor | opus | OWASP/CWE security audit |
| performance-reviewer | sonnet | Complexity, memory, N+1 |
| accessibility-reviewer | sonnet | WCAG 2.1 AA compliance |
| documentation-reviewer | haiku | Doc accuracy and completeness |
| api-conformance-checker | sonnet | API standards compliance |
| style-enforcer | haiku | Code style enforcement |
| complexity-analyzer | sonnet | Cyclomatic/cognitive complexity |
| dependency-auditor | sonnet | Dependency health and security |
| license-checker | haiku | License compliance |
| breaking-change-detector | sonnet | API breakage detection |

### DevOps & Infrastructure (10 agents)
| Agent | Model | Purpose |
|-------|-------|---------|
| devops-engineer | sonnet | CI/CD, build systems |
| ci-cd-specialist | sonnet | Pipeline optimization |
| container-specialist | sonnet | Docker, multi-stage builds |
| cloud-architect | sonnet | Cloud services, scaling |
| monitoring-engineer | sonnet | Logging, metrics, alerting |
| incident-responder | opus | Incident triage, postmortems |
| capacity-planner | sonnet | Resource forecasting |
| release-manager | sonnet | Versioning, release notes |
| environment-manager | sonnet | Dev/staging/prod environments |
| infrastructure-auditor | sonnet | Infrastructure security |

### Documentation (5 agents)
| Agent | Model | Purpose |
|-------|-------|---------|
| documentation-writer | sonnet | Technical documentation |
| api-doc-writer | sonnet | OpenAPI specs, API docs |
| tutorial-writer | sonnet | Tutorials and guides |
| changelog-writer | haiku | Changelog from git history |
| architecture-doc-writer | sonnet | ADRs, system design docs |

### Data & Analytics (5 agents)
| Agent | Model | Purpose |
|-------|-------|---------|
| data-scientist | opus | Statistical analysis, visualization |
| data-engineer | sonnet | ETL, data warehousing |
| ml-engineer | opus | Model training, MLOps |
| analytics-engineer | sonnet | dbt, data marts, KPIs |
| data-quality-engineer | sonnet | Data validation, quality |

### Specialized (10 agents)
| Agent | Model | Purpose |
|-------|-------|---------|
| i18n-specialist | sonnet | Internationalization |
| a11y-specialist | sonnet | Accessibility implementation |
| seo-specialist | sonnet | SEO optimization |
| compliance-checker | sonnet | SOC2, HIPAA compliance |
| gdpr-specialist | sonnet | GDPR, privacy compliance |
| performance-optimizer | sonnet | Bundle, render optimization |
| memory-optimizer | sonnet | Memory leak detection |
| bundle-optimizer | sonnet | Webpack/Vite optimization |
| query-optimizer | sonnet | Database query optimization |
| cache-strategist | sonnet | Caching strategy design |

### Communication (5 agents)
| Agent | Model | Purpose |
|-------|-------|---------|
| tech-writer | sonnet | Technical writing, RFCs |
| stakeholder-communicator | sonnet | Non-technical communication |
| sprint-planner | sonnet | Sprint capacity, backlog |
| retrospective-facilitator | sonnet | Session retrospectives |
| decision-logger | haiku | ADR writing, decision tracking |

### Debugging & Diagnostics (10 agents)
| Agent | Model | Purpose |
|-------|-------|---------|
| debugger | opus | Root cause analysis, fixes |
| log-analyzer | sonnet | Log parsing, correlation |
| error-tracker | sonnet | Error categorization |
| memory-profiler | sonnet | Heap analysis, leak detection |
| cpu-profiler | sonnet | CPU hotspots, threads |
| network-debugger | sonnet | HTTP, DNS, TLS debugging |
| race-condition-detector | opus | Concurrency bug detection |
| deadlock-detector | sonnet | Lock contention analysis |
| regression-detective | sonnet | Git bisect, regression detection |
| root-cause-analyzer | opus | 5-why, fault tree analysis |

## Skills

| Skill | Purpose | Agent |
|-------|---------|-------|
| `/swarm` | Full orchestration | swarm-orchestrator |
| `/swarm-research` | Multi-angle research | swarm-orchestrator |
| `/swarm-develop` | TDD development workflow | swarm-orchestrator |
| `/swarm-review` | Multi-perspective review | swarm-orchestrator |
| `/swarm-debug` | Competing-hypothesis debug | swarm-orchestrator |
| `/swarm-deploy` | Release preparation | swarm-orchestrator |
| `/swarm-status` | Roster and status display | (inline) |

## Hooks

| Hook | Event | Purpose |
|------|-------|---------|
| `swarm-quality-gate.sh` | TaskCompleted | Blocks completion if uncommitted changes or lint errors |
| `swarm-teammate-idle.sh` | TeammateIdle | Blocks idle if uncommitted changes |
| `swarm-file-guard.sh` | PreToolUse (Write/Edit) | Protects critical files and enforces file locks |

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/swarm-status.sh` | Display swarm roster, model distribution, capabilities |
| `scripts/swarm-launch.sh` | Launch specific swarm types from the command line |

## Model Distribution

| Model | Count | Use Case |
|-------|-------|----------|
| opus | ~10 | Complex reasoning: architecture, security, debugging |
| sonnet | ~80 | Balanced: implementation, testing, review, research |
| haiku | ~10 | Fast tasks: exploration, style enforcement, logging |

## Token Cost Strategy

- **opus** agents: Reserve for architecture decisions, security audits, root cause analysis
- **sonnet** agents: Use for 80% of work — implementation, testing, review
- **haiku** agents: Use for fast, focused tasks — codebase exploration, style checking
- Run `/compact` when context exceeds 70%
- Use subagents for context isolation (results summarized back)
- Use agent teams for sustained parallel work with inter-agent communication
