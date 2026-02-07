#!/usr/bin/env bash
# Post-edit lint hook — runs after Write|Edit tool calls
# Checks the modified file for lint issues and reports back
set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -z "$FILE_PATH" ]; then
    exit 0
fi

# Only lint if the file exists (Write may have created it)
if [ ! -f "$FILE_PATH" ]; then
    exit 0
fi

ISSUES=""

# Python files: run ruff
if [[ "$FILE_PATH" == *.py ]]; then
    if command -v ruff &>/dev/null; then
        LINT_OUTPUT=$(ruff check "$FILE_PATH" 2>&1 || true)
        if [ -n "$LINT_OUTPUT" ] && [ "$LINT_OUTPUT" != "All checks passed!" ]; then
            ISSUES="ruff: $LINT_OUTPUT"
        fi
    fi
fi

# TypeScript/JavaScript files: check for common issues
if [[ "$FILE_PATH" =~ \.(ts|js|tsx|jsx)$ ]]; then
    # Basic check — ESLint if available
    if command -v npx &>/dev/null && [ -f "$(dirname "$FILE_PATH")/../package.json" ] 2>/dev/null; then
        LINT_OUTPUT=$(npx eslint "$FILE_PATH" 2>/dev/null || true)
        if [ -n "$LINT_OUTPUT" ]; then
            ISSUES="eslint: $LINT_OUTPUT"
        fi
    fi
fi

# Report issues as additional context (non-blocking)
if [ -n "$ISSUES" ]; then
    echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PostToolUse\",\"additionalContext\":\"Lint issues found in $FILE_PATH: $ISSUES\"}}"
fi

exit 0
