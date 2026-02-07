# Using Agent Teams with the Anthropic API

> Claude Code CLI is the default and recommended way to use Agent Teams.
> This document covers the alternative: using agent definitions with the Anthropic API directly.

## When to use API vs CLI

| Use Case | Recommended |
|----------|-------------|
| Interactive development | Claude Code CLI |
| CI/CD pipelines | API (headless) |
| Automated code review | API (headless) or CLI headless mode |
| Custom orchestration | API with Claude SDK |
| Cost-sensitive batch work | API with model selection |
| Team of 3+ engineers | Claude Code CLI with Agent Teams |

## Option 1: Claude Code CLI headless mode (simplest)

Claude Code supports headless execution with `-p` (print mode) that works with your existing agent definitions:

```bash
# Run architect agent headlessly
claude -p "Analyze the authentication module and produce an implementation plan" \
  --agent architect \
  --permission-mode plan \
  --output-format json

# Run implementer against a specific task
claude -p "Implement task #3: add user registration endpoint" \
  --agent implementer \
  --output-format json

# Run reviewer on recent changes
claude -p "Review all changes in the last commit against the approved plan" \
  --agent reviewer \
  --permission-mode plan \
  --output-format json
```

### CI/CD integration

```yaml
# .github/workflows/agent-review.yml
name: Agent Code Review

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Claude Code
        run: npm install -g @anthropic-ai/claude-code

      - name: Run reviewer agent
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          claude -p "Review all changes in this PR against the project conventions. \
            Check for: spec conformance, test coverage, security issues, scope creep. \
            Output your verdict as a GitHub PR comment." \
            --agent reviewer \
            --permission-mode plan \
            --output-format json > review.json

          # Post review as PR comment
          gh pr comment ${{ github.event.pull_request.number }} \
            --body "$(cat review.json | jq -r '.result')"
```

## Option 2: Anthropic Python SDK

Use the agent definitions as system prompts with the Anthropic SDK:

```bash
# Install
uv add anthropic
```

```python
#!/usr/bin/env python3
"""Use agent definitions with the Anthropic API."""

import os
from pathlib import Path
from anthropic import Anthropic

def load_agent(agent_name: str) -> dict:
    """Load an agent definition from .claude/agents/{name}.md"""
    agent_path = Path(".claude/agents") / f"{agent_name}.md"
    content = agent_path.read_text()

    # Split YAML frontmatter from body
    parts = content.split("---", 2)
    if len(parts) >= 3:
        import yaml
        metadata = yaml.safe_load(parts[1])
        instructions = parts[2].strip()
    else:
        metadata = {}
        instructions = content

    return {
        "name": metadata.get("name", agent_name),
        "description": metadata.get("description", ""),
        "model": metadata.get("model", "claude-sonnet-4-5-20250929"),
        "instructions": instructions,
    }

def run_agent(agent_name: str, task: str) -> str:
    """Run an agent with a task using the Anthropic API."""
    client = Anthropic()  # Uses ANTHROPIC_API_KEY env var
    agent = load_agent(agent_name)

    # Map agent model names to API model IDs
    model_map = {
        "opus": "claude-opus-4-6",
        "sonnet": "claude-sonnet-4-5-20250929",
        "haiku": "claude-haiku-4-5-20251001",
    }
    model_id = model_map.get(agent["model"], agent["model"])

    response = client.messages.create(
        model=model_id,
        max_tokens=16384,
        system=agent["instructions"],
        messages=[{"role": "user", "content": task}],
    )

    return response.content[0].text

# Example usage
if __name__ == "__main__":
    # Run architect to analyze
    plan = run_agent("architect", "Analyze the src/ directory and suggest improvements")
    print(f"Architect plan:\n{plan}")

    # Run reviewer on a diff
    import subprocess
    diff = subprocess.run(["git", "diff", "HEAD~1"], capture_output=True, text=True).stdout
    review = run_agent("reviewer", f"Review this diff:\n\n{diff}")
    print(f"Review:\n{review}")
```

## Option 3: Anthropic TypeScript SDK

```bash
# Install
npm install @anthropic-ai/sdk
```

```typescript
// scripts/run-agent.ts
import Anthropic from "@anthropic-ai/sdk";
import { readFileSync } from "fs";
import { parse } from "yaml";

interface AgentDef {
  name: string;
  description: string;
  model: string;
  instructions: string;
}

function loadAgent(agentName: string): AgentDef {
  const content = readFileSync(`.claude/agents/${agentName}.md`, "utf-8");
  const [, frontmatter, ...body] = content.split("---");

  const metadata = parse(frontmatter);
  return {
    name: metadata.name ?? agentName,
    description: metadata.description ?? "",
    model: metadata.model ?? "sonnet",
    instructions: body.join("---").trim(),
  };
}

const MODEL_MAP: Record<string, string> = {
  opus: "claude-opus-4-6",
  sonnet: "claude-sonnet-4-5-20250929",
  haiku: "claude-haiku-4-5-20251001",
};

async function runAgent(agentName: string, task: string): Promise<string> {
  const client = new Anthropic(); // Uses ANTHROPIC_API_KEY env var
  const agent = loadAgent(agentName);

  const response = await client.messages.create({
    model: MODEL_MAP[agent.model] ?? agent.model,
    max_tokens: 16384,
    system: agent.instructions,
    messages: [{ role: "user", content: task }],
  });

  return response.content[0].type === "text" ? response.content[0].text : "";
}

// Example: run reviewer on latest commit
async function main() {
  const { execSync } = await import("child_process");
  const diff = execSync("git diff HEAD~1").toString();
  const review = await runAgent("reviewer", `Review this diff:\n\n${diff}`);
  console.log(review);
}

main();
```

## API key configuration

```bash
# Set your API key (never commit this)
export ANTHROPIC_API_KEY="sk-ant-..."

# Or use Claude Code's built-in auth (no separate key needed)
claude login
```

### Cost comparison

| Agent | Model | Input (1M tokens) | Output (1M tokens) |
|-------|-------|-------------------|-------------------|
| Architect | Opus 4.6 | $15.00 | $75.00 |
| Implementer | Opus 4.6 | $15.00 | $75.00 |
| Implementer | Sonnet 4.5 | $3.00 | $15.00 |
| Test Writer | Sonnet 4.5 | $3.00 | $15.00 |
| Reviewer | Haiku 4.5 | $0.80 | $4.00 |

**Cost optimization**: Use Opus only for the Architect. Switch Implementer and Test Writer to Sonnet. Use Haiku for the Reviewer.

To override the model per agent at runtime:
```bash
# CLI: override agent's default model
claude -p "task description" --agent implementer --model sonnet
```

```python
# SDK: override at call time
response = client.messages.create(
    model="claude-sonnet-4-5-20250929",  # Override opus default
    ...
)
```

## Headless orchestration script

```bash
#!/usr/bin/env bash
# scripts/run-team.sh — Run the 4-agent pipeline headlessly
set -euo pipefail

TASK="$1"

echo "=== Step 1: Architect produces plan ==="
PLAN=$(claude -p "$TASK" --agent architect --permission-mode plan --output-format stream-json 2>/dev/null | jq -r '.result // empty' | tail -1)
echo "$PLAN" > /tmp/plan.md

echo "=== Step 2: Test Writer creates tests ==="
claude -p "Read this plan and write failing tests:\n\n$(cat /tmp/plan.md)" \
  --agent test-writer --output-format stream-json 2>/dev/null

echo "=== Step 3: Implementer builds ==="
claude -p "Implement this plan. Tests already exist:\n\n$(cat /tmp/plan.md)" \
  --agent implementer --output-format stream-json 2>/dev/null

echo "=== Step 4: Reviewer checks ==="
REVIEW=$(claude -p "Review all changes against this plan:\n\n$(cat /tmp/plan.md)" \
  --agent reviewer --permission-mode plan --output-format stream-json 2>/dev/null | jq -r '.result // empty' | tail -1)
echo "$REVIEW"

echo "=== Pipeline complete ==="
```
