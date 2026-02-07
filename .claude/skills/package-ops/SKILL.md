---
name: package-ops
description: >
  Package operations for jade-monolith — submodule status, health checks,
  branch sync, and release management across the 14-package ecosystem.
disable-model-invocation: true
argument-hint: "[status|health|sync|releases]"
---

# Package Operations

Run ecosystem operations for jade-monolith. Usage: `/package-ops <command>`

## Available Commands

### `/package-ops status`
Show status of all 14 submodules.
```bash
./scripts/git-status-all.sh
```

### `/package-ops status --json`
Machine-readable status output.
```bash
./scripts/git-status-all.sh --json
```

### `/package-ops health`
Run ecosystem health check — submodule alignment, open issues/PRs, Docker, GPU.
```bash
./scripts/health-check.sh
```

### `/package-ops sync`
Update all submodules to latest main. Preview with `--dry-run`.
```bash
./scripts/update-submodules.sh        # execute
./scripts/update-submodules.sh --dry-run  # preview
```

### `/package-ops releases`
Find and list open release-please PRs across the ecosystem.
```bash
./scripts/merge-releases.sh --dry-run
```

### `/package-ops pr-health`
PR health dashboard — total, unlinked, release-please counts.
```bash
./scripts/pr-health.sh
```

### `/package-ops branches`
Sync pre-main and main branches across all repos. Preview with `--dry-run`.
```bash
./scripts/sync-branches.sh --dry-run
```

## Execution

Based on `$ARGUMENTS`, run the corresponding command above. If no argument
is provided or the argument is not recognized, show the available commands list.

### Safety Rules
- Always use `--dry-run` first for destructive operations
- Never force-push to main branches
- Report results clearly with pass/fail summaries
