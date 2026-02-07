#!/usr/bin/env bash
# Task completion gate — runs when a task is being marked complete
# Verifies quality gate before allowing completion
set -euo pipefail

INPUT=$(cat)
TASK_SUBJECT=$(echo "$INPUT" | jq -r '.task_subject // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

# Check for staged but uncommitted changes
UNCOMMITTED=$(git -C "$CWD" diff --cached --name-only 2>/dev/null || true)
MODIFIED=$(git -C "$CWD" diff --name-only 2>/dev/null || true)

if [ -n "$UNCOMMITTED" ] || [ -n "$MODIFIED" ]; then
    # Check if any modified files are Python
    PY_FILES=$(echo -e "$UNCOMMITTED\n$MODIFIED" | grep '\.py$' || true)
    if [ -n "$PY_FILES" ]; then
        if command -v ruff &>/dev/null; then
            LINT=$(ruff check $PY_FILES 2>&1 || true)
            if [ -n "$LINT" ] && [[ "$LINT" != *"All checks passed"* ]]; then
                echo "Lint issues found. Fix before completing task '$TASK_SUBJECT': $LINT" >&2
                exit 2
            fi
        fi
    fi
fi

exit 0
