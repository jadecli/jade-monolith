#!/usr/bin/env bash
# Stop check — runs when Claude finishes responding
# Prevents stopping if there are in_progress tasks that should be completed
set -euo pipefail

INPUT=$(cat)
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')

# Prevent infinite loops — if stop hook already active, allow stopping
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
    exit 0
fi

CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
TASKS_FILE="$CWD/.claude/tasks/tasks.json"

# Check for in_progress tasks
if [ -f "$TASKS_FILE" ]; then
    IN_PROGRESS=$(jq -r '[.tasks[] | select(.status == "in_progress")] | length' "$TASKS_FILE" 2>/dev/null || echo "0")
    if [ "$IN_PROGRESS" -gt 0 ]; then
        TASK_NAMES=$(jq -r '[.tasks[] | select(.status == "in_progress") | .title] | join(", ")' "$TASKS_FILE" 2>/dev/null || echo "unknown")
        echo "{\"decision\":\"block\",\"reason\":\"There are $IN_PROGRESS task(s) still in_progress: $TASK_NAMES. Complete or update them before stopping.\"}"
        exit 0
    fi
fi

exit 0
