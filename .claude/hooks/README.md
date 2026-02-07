# Claude Code Hooks

## quality-gate.sh

Pre-commit quality gate that checks staged files:

- **Python** (.py): runs `ruff check` (blocking) and `ty check` (warning)
- **JS/TS** (.ts, .js, .tsx, .jsx): runs `npm test` (blocking)

### Install as git hook

```bash
cp .claude/hooks/quality-gate.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

### Run manually

```bash
bash .claude/hooks/quality-gate.sh
```
