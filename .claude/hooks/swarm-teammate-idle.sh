#!/usr/bin/env bash
# Swarm Teammate Idle Hook — TeammateIdle hook
# Checks if a teammate has unfinished tasks before allowing it to go idle.
# Prevents agents from stopping before their work is done.
#
# Exit 0: teammate can go idle
# Exit 2: teammate must continue (stderr fed back as instruction)
set -euo pipefail

INPUT=$(cat)
TEAMMATE=$(echo "$INPUT" | jq -r '.teammate_name // empty')
TEAM=$(echo "$INPUT" | jq -r '.team_name // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // "."')

# Check for uncommitted changes in the working directory
if cd "$CWD" 2>/dev/null; then
    DIRTY=$(git status --porcelain 2>/dev/null | head -5)
    if [ -n "$DIRTY" ]; then
        echo "You have uncommitted changes. Commit or stash your work before going idle." >&2
        echo "Modified files: $DIRTY" >&2
        exit 2
    fi
fi

# Teammate can go idle
exit 0
