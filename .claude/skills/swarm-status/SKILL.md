---
name: swarm-status
description: >
  Display the status of the 100-agent swarm: agent roster, categories, model
  distribution, tool capabilities, and readiness. Shows which agents are available
  and their configuration.
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Bash
---

# Swarm Status

Display the current state of the 100-agent swarm.

## Instructions

1. List all agent files in `.claude/agents/`
2. Parse each file's frontmatter for name, model, tools, memory
3. Categorize agents by role
4. Display a summary table

## Expected Output Format

```
JADE SWARM STATUS — 100 Agent Roster
=====================================

Category                  Count  Models (opus/sonnet/haiku)
─────────────────────────────────────────────────────────
Orchestration                5   1/2/2
Architecture & Planning      5   1/4/0
Research                    10   1/5/4
Development                 16   0/16/0
Testing                     11   0/11/0
Review & Quality            11   2/6/3
DevOps & Infrastructure     10   1/8/1
Documentation                5   0/4/1
Data & Analytics             5   2/3/0
Specialized                 10   0/10/0
Communication                5   0/4/1
Debugging & Diagnostics     10   3/7/0
─────────────────────────────────────────────────────────
TOTAL                      103

Agent Capabilities:
  Read-only agents: [count] (cannot modify files)
  Write-capable agents: [count] (can create/edit files)
  Web-capable agents: [count] (can search/fetch web)
  Memory-enabled agents: [count] (persistent learning)

Model Distribution:
  opus: [count] agents (complex reasoning)
  sonnet: [count] agents (balanced capability)
  haiku: [count] agents (fast, low-cost)
```

Run `ls .claude/agents/*.md | wc -l` to count agents and then categorize them.
