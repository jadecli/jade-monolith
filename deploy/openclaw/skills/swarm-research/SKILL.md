---
name: swarm-research
description: >
  Launch a research swarm to investigate a topic from multiple angles simultaneously.
  Spawns research specialists who explore independently, share findings, and challenge
  each other's conclusions. Returns a synthesized research report.
argument-hint: "[research question or topic]"
disable-model-invocation: true
context: fork
agent: swarm-orchestrator
allowed-tools: Task, TaskCreate, TaskList, TaskUpdate, TaskGet, Read, Glob, Grep, Bash, WebSearch, WebFetch, AskUserQuestion
---

# Research Swarm Protocol

Launch a multi-agent research investigation.

## Research Topic
$ARGUMENTS

## Available Research Agents

| Agent | Specialty | Model |
|-------|-----------|-------|
| deep-researcher | Multi-source synthesis | opus |
| codebase-explorer | Codebase navigation | haiku |
| api-researcher | API patterns & docs | sonnet |
| library-evaluator | Library fitness | sonnet |
| benchmark-researcher | Performance data | sonnet |
| standards-researcher | Industry standards | haiku |
| security-researcher | Security vulnerabilities | sonnet |
| performance-researcher | Runtime analysis | sonnet |
| ux-researcher | UX patterns | sonnet |
| competitor-analyst | Competitive analysis | sonnet |

## Execution Strategy

1. **Analyze the research question** — determine which angles need investigation
2. **Select 3-7 research agents** based on the question domain
3. **Assign each agent a distinct angle** — avoid duplicate investigation
4. **Run agents in parallel** — each explores independently
5. **Cross-pollinate findings** — have agents challenge each other's conclusions
6. **Synthesize** — produce a unified research report with citations

## Research Report Template

```markdown
# Research Report: [Topic]

## Executive Summary
[2-3 sentences]

## Key Findings
1. [Finding with evidence]
2. [Finding with evidence]
3. [Finding with evidence]

## Detailed Analysis
### [Angle 1 — Agent Name]
[Findings, evidence, confidence level]

### [Angle 2 — Agent Name]
[Findings, evidence, confidence level]

## Competing Perspectives
[Where agents disagreed and why]

## Recommendations
1. [Actionable recommendation]
2. [Actionable recommendation]

## Confidence Assessment
- High confidence: [areas]
- Medium confidence: [areas]
- Low confidence / needs more research: [areas]

## Sources
- [Source 1]
- [Source 2]
```
