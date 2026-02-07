#!/usr/bin/env bash
# Quality gate — runs before commit to ensure code meets standards
# Install: cp .claude/hooks/quality-gate.sh .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
set -euo pipefail

echo "=== Quality Gate ==="

STAGED_PY=$(git diff --cached --name-only --diff-filter=ACM | grep '\.py$' || true)
STAGED_JS=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(ts|js|tsx|jsx)$' || true)

EXIT_CODE=0

if [ -n "$STAGED_PY" ]; then
    echo "Python files staged: $(echo "$STAGED_PY" | wc -l)"

    echo "  Running ruff check..."
    if ! ruff check $STAGED_PY; then
        echo "  FAIL: ruff check found issues"
        EXIT_CODE=1
    else
        echo "  PASS: ruff check"
    fi

    echo "  Running ty check..."
    if ! ty check $STAGED_PY 2>/dev/null; then
        echo "  WARN: ty check found issues (non-blocking)"
    else
        echo "  PASS: ty check"
    fi
fi

if [ -n "$STAGED_JS" ]; then
    echo "JS/TS files staged: $(echo "$STAGED_JS" | wc -l)"

    if [ -f "package.json" ] && command -v npm &>/dev/null; then
        echo "  Running npm test..."
        if ! npm test --if-present 2>/dev/null; then
            echo "  FAIL: npm test found issues"
            EXIT_CODE=1
        else
            echo "  PASS: npm test"
        fi
    fi
fi

if [ $EXIT_CODE -eq 0 ]; then
    echo "=== Quality Gate PASSED ==="
else
    echo "=== Quality Gate FAILED ==="
    echo "Fix issues above before committing."
fi

exit $EXIT_CODE
