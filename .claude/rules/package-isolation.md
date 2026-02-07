# Package Isolation Rule

**MANDATORY: Never modify files across multiple packages in a single task.**

## Allowed Scope Per Task

- Files within exactly ONE `packages/<name>/` directory
- Files in `.claude/tasks/` (task status updates only)
- Files in `scripts/` (only if the task is explicitly about monolith tooling)

## Forbidden Actions

- Importing/requiring code from `packages/A/` inside `packages/B/`
- Creating shared libraries that span packages
- Modifying `.gitmodules` without explicit user approval
- Running commands that affect multiple submodules simultaneously (except read-only status scripts)

## Why

Each package is an independent repo with its own history, dependencies, and conventions. Cross-references create coupling that defeats the purpose of the monolith archive. Code sharing happens by copy-paste into the target project, not by import.
