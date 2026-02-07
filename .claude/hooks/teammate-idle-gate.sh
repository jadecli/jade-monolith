#!/usr/bin/env bash
# Teammate idle gate — runs when a teammate is about to go idle
# Checks for uncommitted work and incomplete tasks
set -euo pipefail

INPUT=$(cat)
TEAMMATE_NAME=$(echo "$INPUT" | jq -r '.teammate_name // "unknown"')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

# Check for uncommitted changes
if [ -n "$CWD" ]; then
    DIRTY=$(git -C "$CWD" status --porcelain 2>/dev/null || true)
    if [ -n "$DIRTY" ]; then
        DIRTY_COUNT=$(echo "$DIRTY" | wc -l | tr -d ' ')
        echo "Teammate '$TEAMMATE_NAME' has $DIRTY_COUNT uncommitted file(s). Commit your work before going idle." >&2
        exit 2
    fi
fi

exit 0
