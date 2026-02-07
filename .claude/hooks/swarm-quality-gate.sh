#!/usr/bin/env bash
# Swarm Quality Gate — TaskCompleted hook
# Validates that agents have met quality standards before marking tasks complete.
# Used as a TaskCompleted hook to enforce quality gates across the swarm.
#
# Exit 0: task completion allowed
# Exit 2: task completion blocked (stderr fed back to agent)
set -euo pipefail

INPUT=$(cat)
TASK_SUBJECT=$(echo "$INPUT" | jq -r '.task_subject // empty')
TASK_DESC=$(echo "$INPUT" | jq -r '.task_description // empty')
TEAMMATE=$(echo "$INPUT" | jq -r '.teammate_name // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // "."')

# Check if this is a code task (not a research/planning task)
IS_CODE_TASK=false
if echo "$TASK_SUBJECT $TASK_DESC" | grep -qiE '(implement|fix|create|write|build|add|update|refactor|migrate)'; then
    IS_CODE_TASK=true
fi

if [ "$IS_CODE_TASK" = true ]; then
    # Check for uncommitted changes
    if cd "$CWD" 2>/dev/null; then
        DIRTY=$(git diff --name-only 2>/dev/null | head -5)
        if [ -n "$DIRTY" ]; then
            echo "Task '$TASK_SUBJECT' has uncommitted changes. Commit your work before marking complete." >&2
            echo "Uncommitted files: $DIRTY" >&2
            exit 2
        fi
    fi

    # Check for staged Python files needing lint
    STAGED_PY=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null | grep '\.py$' || true)
    if [ -n "$STAGED_PY" ]; then
        if command -v ruff &>/dev/null; then
            if ! ruff check $STAGED_PY 2>/dev/null; then
                echo "Lint check failed for task '$TASK_SUBJECT'. Fix ruff errors before completing." >&2
                exit 2
            fi
        fi
    fi
fi

# All checks passed
exit 0
