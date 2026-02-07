#!/usr/bin/env bash
# task-lifecycle.sh — ATS lifecycle hook for TaskCompleted events
# Runs automatically when an agent marks a task complete.
#
# Environment:
#   ATS_ROOT     — path to .agent-tasks directory (default: .agent-tasks)
#   ATS_TASK_ID  — the task that was just completed
#   ATS_AGENT    — the agent that completed it
#   GH_REPO      — GitHub repo for sync (optional, e.g. jadecli/jade-monolith)
#
# Exit codes:
#   0 — success, allow completion
#   2 — reject completion, send feedback to agent (Claude Code hook protocol)

set -euo pipefail

ATS_ROOT="${ATS_ROOT:-.agent-tasks}"
TASK_ID="${ATS_TASK_ID:-}"
AGENT="${ATS_AGENT:-unknown}"

# If no task ID, this isn't an ATS-managed completion — allow it
if [[ -z "$TASK_ID" ]]; then
    exit 0
fi

TASK_FILE="$ATS_ROOT/tasks/$TASK_ID/TASK.md"
LOCK_FILE="$ATS_ROOT/locks/${TASK_ID}.lock.json"

# Verify the task file exists
if [[ ! -f "$TASK_FILE" ]]; then
    echo "WARNING: Task file not found: $TASK_FILE" >&2
    exit 0
fi

# Check acceptance criteria if any
CRITERIA=$(python3 -c "
import yaml, re, sys
content = open('$TASK_FILE').read()
m = re.match(r'^---\s*\n(.*?)\n---', content, re.DOTALL)
if m:
    fm = yaml.safe_load(m.group(1))
    for c in fm.get('criteria', []):
        print(c)
" 2>/dev/null || true)

if [[ -n "$CRITERIA" ]]; then
    echo "=== Acceptance Criteria for $TASK_ID ==="
    echo "$CRITERIA"
    echo "=== Verify these are met before completing ==="
fi

# Release lock if held
if [[ -f "$LOCK_FILE" ]]; then
    rm -f "$LOCK_FILE"
    echo "Released lock on $TASK_ID"
fi

# Regenerate INDEX.json
if command -v python3 &>/dev/null; then
    python3 -m agent_task_spec.cli index --root "$ATS_ROOT" 2>/dev/null || true
fi

# Sync to GitHub if configured
if [[ -n "${GH_REPO:-}" ]] && command -v gh &>/dev/null; then
    echo "Syncing $TASK_ID to GitHub..."
    python3 -m agent_task_spec.cli sync --repo "$GH_REPO" --root "$ATS_ROOT" 2>/dev/null || true
fi

# Check for newly unblocked tasks
if command -v python3 &>/dev/null; then
    UNBLOCKED=$(python3 -c "
import json, yaml, re
from pathlib import Path

root = Path('$ATS_ROOT')
tasks_dir = root / 'tasks'
if not tasks_dir.is_dir():
    exit()

completed_id = '$TASK_ID'
for td in sorted(tasks_dir.iterdir()):
    tf = td / 'TASK.md'
    if not tf.is_file():
        continue
    content = tf.read_text()
    m = re.match(r'^---\s*\n(.*?)\n---', content, re.DOTALL)
    if not m:
        continue
    fm = yaml.safe_load(m.group(1))
    blocked_by = fm.get('blockedBy', [])
    if completed_id in blocked_by and len(blocked_by) == 1:
        print(f\"  UNBLOCKED: {fm.get('id', '?')} — {fm.get('subject', '?')}\")
" 2>/dev/null || true)

    if [[ -n "$UNBLOCKED" ]]; then
        echo ""
        echo "=== Newly Unblocked Tasks ==="
        echo "$UNBLOCKED"
    fi
fi

echo "Task $TASK_ID completed by $AGENT"
exit 0
