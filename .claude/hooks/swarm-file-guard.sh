#!/usr/bin/env bash
# Swarm File Guard — PreToolUse hook for Write/Edit
# Prevents agents from modifying files outside their assigned scope.
# Checks against a .claude/swarm-file-locks.json if it exists.
#
# Exit 0: file modification allowed
# Exit 2: file modification blocked
set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // "."')

# Only check Write and Edit operations
if [[ "$TOOL_NAME" != "Write" && "$TOOL_NAME" != "Edit" ]]; then
    exit 0
fi

# If no file path, skip
if [ -z "$FILE_PATH" ]; then
    exit 0
fi

# Block modifications to critical config files
PROTECTED_FILES=(
    ".claude/settings.json"
    ".claude/tasks/tasks.json"
    ".gitmodules"
    "CLAUDE.md"
)

for protected in "${PROTECTED_FILES[@]}"; do
    if [[ "$FILE_PATH" == *"$protected" ]]; then
        echo "Protected file: $FILE_PATH cannot be modified by swarm agents. Only the orchestrator or human can modify this file." >&2
        exit 2
    fi
done

# Block modifications to .env files
if [[ "$FILE_PATH" == *".env"* ]]; then
    echo "Environment files cannot be modified by swarm agents." >&2
    exit 2
fi

# If swarm file locks exist, check ownership
LOCK_FILE="$CWD/.claude/swarm-file-locks.json"
if [ -f "$LOCK_FILE" ]; then
    # Check if the file is locked by another agent
    LOCK_OWNER=$(jq -r --arg path "$FILE_PATH" '.[$path] // empty' "$LOCK_FILE" 2>/dev/null)
    if [ -n "$LOCK_OWNER" ]; then
        CURRENT_AGENT=$(echo "$INPUT" | jq -r '.permission_mode // empty')
        if [ "$LOCK_OWNER" != "$CURRENT_AGENT" ]; then
            echo "File $FILE_PATH is locked by agent '$LOCK_OWNER'. Contact them or the orchestrator." >&2
            exit 2
        fi
    fi
fi

exit 0
