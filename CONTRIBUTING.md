# Contributing — Onboarding a Repo into jade-monolith

Standardized workflow for adding a new project to the monolith and getting all its code into a clean `pre-main` staging branch. This replicates the process used to onboard the original 14 repos.

## Prerequisites

- `gh` CLI authenticated with access to the `jadecli` org
- Scripts in `scripts/` are executable (`chmod +x scripts/*.sh`)
- HTTPS remotes for jadecli org repos (SSH uses wrong key — known issue)

## Phase 1: Add the Submodule

```bash
cd ~/projects/jade-monolith

# Add submodule pinned to the default branch
git submodule add https://github.com/jadecli/<repo>.git packages/<repo>

# Verify it cloned
ls packages/<repo>/
```

## Phase 2: Clean the Working Tree

Run status check first to see what needs attention:

```bash
cd packages/<repo>
git status --short
git stash list
git worktree list
```

### 2a. Commit Untracked and Modified Files

Handle each category in separate conventional commits:

```bash
# If .gitignore needs updates (build artifacts, secrets, caches)
echo ".coverage"       >> .gitignore
echo ".jade-index/"    >> .gitignore
echo "__pycache__/"    >> .gitignore
git add .gitignore
git commit -m "chore: update gitignore for build artifacts

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"

# Group remaining files by purpose
git add src/new-feature/
git commit -m "feat: add new feature module

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"

git add tests/
git commit -m "test: add integration tests

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"

git add docs/
git commit -m "docs: add design documents

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

**Critical checks before committing:**

- Never commit `.env` files — add to `.gitignore` first
- Never commit `**/secrets/**`, `id_rsa`, `*.pem`
- Check `git diff --cached` before each commit to review what's staged

### 2b. Resolve Stashes

```bash
git stash list
# Compare stash contents to working tree
git stash show -p stash@{0}
# If stash is outdated (same files already committed with newer content):
git stash drop stash@{0}
# If stash has unique work:
git stash pop
# Resolve any conflicts, then commit
```

### 2c. Clean Up Worktrees

```bash
git worktree list
# For each non-main worktree:
# 1. Check for uncommitted work
git -C /path/to/worktree status
git -C /path/to/worktree log --oneline -3
# 2. Create a tracking issue
gh issue create --repo jadecli/<repo> \
  --title "chore: recover and remove worktree at <path>" \
  --body "Worktree at <path> on branch <branch>. Recovering any unsaved commits before removal."
# 3. Recover commits to a branch if needed
git branch recovered-worktree-work <commit-hash>
# 4. Remove worktree
git worktree remove /path/to/worktree
# 5. Close issue
gh issue close <number> --repo jadecli/<repo>
```

### 2d. Push Diverged Branches

```bash
# If branch is ahead AND behind origin (diverged):
git pull --rebase origin <branch>
# Resolve conflicts if any, then:
git push origin <branch>

# If branch is only ahead:
git push origin <branch>
```

### 2e. Push Untracked Local Branches

```bash
# List local branches without upstream
git branch -vv | grep -v '\[origin'

# For each untracked branch:
git checkout <branch>
git fetch origin
git rebase origin/<base-branch>   # rebase onto main or jadecli-main
git push -u origin <branch>

# Create a PR
gh pr create --repo jadecli/<repo> \
  --title "<conventional-commit-prefix>: <description>" \
  --base <base-branch> \
  --body "$(cat <<'EOF'
## Summary
- <what this branch adds>

## Test plan
- [ ] Verify changes work as expected

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

### Verification

```bash
# From monolith root — check this repo specifically:
./scripts/git-status-all.sh --json | jq '.[] | select(.repo == "<repo>") | select(.untracked > 0 or .modified > 0)'
# Expected: empty (no output)
```

## Phase 3: Link PRs to Issues

Every PR should have a linked GitHub issue for tracking.

```bash
# Preview what would be created
./scripts/create-issues-for-prs.sh <repo> --dry-run

# Execute (creates issues, updates PR bodies via REST API)
./scripts/create-issues-for-prs.sh <repo>
```

**Known issue:** `gh pr edit --body` fails with classic GitHub projects due to a GraphQL deprecation error. The script uses the REST API workaround:

```bash
# REST API approach (what the script does internally)
gh api repos/jadecli/<repo>/pulls/<number> -X PATCH -f body="$new_body"
```

### Verification

```bash
./scripts/pr-health.sh --json | jq '.[] | select(.repo == "<repo>")'
# Check: unlinked should be 0
```

## Phase 4: Create pre-main Staging Branch

```bash
cd packages/<repo>

# Determine base branch
# Most repos: main
# jade-ide, jade-swarm: jadecli-main
BASE="main"

git fetch origin
git checkout -b pre-main origin/$BASE
git push -u origin pre-main
```

### Retarget PRs to pre-main

```bash
# List open PRs (skip release-please)
gh pr list --repo jadecli/<repo> --json number,title,headRefName \
  | jq -c '.[] | select(.title | startswith("chore(main): release") | not)'

# Retarget each to pre-main
gh pr edit <number> --repo jadecli/<repo> --base pre-main

# If retarget fails (duplicate head/base pair), document and skip
```

**Rule:** Release-please PRs stay targeting `main` — never retarget these.

## Phase 5: Merge PRs into pre-main

### Classify PRs

1. **Clean merges** — no conflicts, tests pass. Merge directly.
2. **Draft PRs** — run `gh pr ready <number>` first, then merge.
3. **Conflicting PRs** — need manual resolution (see below).
4. **Superseded PRs** — one PR is a superset of others. Close the subsets.

### Merge clean PRs

```bash
gh pr merge <number> --repo jadecli/<repo> --merge
```

### Resolve conflicts

```bash
git checkout pre-main
git merge --no-ff origin/<feature-branch>
# Resolve conflicts manually
git add <resolved-files>
git commit   # accept or edit the merge commit message
git push origin pre-main
gh pr close <number> --repo jadecli/<repo> --comment "Merged manually into pre-main"
```

### Supersession analysis

When multiple PRs touch the same files, check if one is a superset:

```bash
# Compare file lists
gh pr diff <pr-a> --repo jadecli/<repo> --name-only
gh pr diff <pr-b> --repo jadecli/<repo> --name-only
# If PR-A contains all changes from PR-B plus more:
gh pr close <pr-b> --repo jadecli/<repo> \
  --comment "Superseded by #<pr-a> which includes all these changes plus additional work."
```

### Cherry-pick strategy (for heavily diverged branches)

When a PR has too many conflicts to merge cleanly but contains valuable new files:

```bash
git checkout pre-main
git cherry-pick --no-commit <commit-hash>
# Or selectively copy files:
git checkout <feature-branch> -- path/to/new/file.py path/to/new/test.py
git add path/to/new/
git commit -m "feat: cherry-pick <description> from <branch>

Selectively added new files from PR #<number>. Full merge had too many
conflicts in existing files.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
git push origin pre-main
```

## Phase 6: Update Submodule Ref in Monolith

After all work is merged into `pre-main` inside the submodule:

```bash
cd ~/projects/jade-monolith
cd packages/<repo>
git checkout pre-main
git pull origin pre-main
cd ../..
git add packages/<repo>
git commit -m "chore: update <repo> submodule to latest pre-main

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
git push origin pre-main
```

## Phase 7: Register and Seed Tasks

### Add to projects.json

Edit `~/.jade/projects.json` and add the new entry:

```json
{"name": "<repo>", "alias": "<short>", "language": "<lang>", "base_branch": "main", "staging_branch": "pre-main"}
```

### Add tasks to tasks.json

Edit `.claude/tasks/tasks.json` and add tasks following this schema:

```json
{
  "id": "<package-name>/<task-slug>",
  "title": "Human-readable title",
  "description": "What to do and acceptance criteria",
  "package": "<package-name>",
  "status": "pending",
  "complexity": "S|M|L|XL",
  "blocked_by": [],
  "labels": ["feat|fix|test|docs|chore"],
  "created_at": "YYYY-MM-DD"
}
```

Standard tasks for every new package:
1. `<pkg>/review-pre-main` — verify pre-main state, run linter/tests
2. `<pkg>/triage-issues` — assess open issues for relevance

## Guardrails Checklist

Before any code change, verify:

- [ ] A task exists in `.claude/tasks/tasks.json` for this work
- [ ] The task targets exactly one package
- [ ] Task status is set to `in_progress`
- [ ] No other task is `in_progress` for the same package
- [ ] Changes stay within `packages/<name>/` (no cross-package edits)

After completing work:

- [ ] Linter/tests pass (if the package has them)
- [ ] Committed with conventional commit format
- [ ] Task status set to `completed`
- [ ] Submodule ref updated in monolith root

## Tools Reference

| Script | Purpose | Usage |
|--------|---------|-------|
| `scripts/git-status-all.sh` | 14-repo status in one command | `--json` or `--table` |
| `scripts/pr-health.sh` | PR health dashboard | `--json` or `--table` |
| `scripts/create-issues-for-prs.sh` | Auto-link PRs to issues | `<repo> [--dry-run]` |

| Shell Alias | Expands To |
|-------------|------------|
| `jade-git-status` | `scripts/git-status-all.sh --table` |
| `jade-pr-health` | `scripts/pr-health.sh --table` |
| `jade-link-prs` | `scripts/create-issues-for-prs.sh` |

## Known Issues

| Issue | Workaround |
|-------|------------|
| `gh pr edit --body` fails with classic GitHub projects | Use REST API: `gh api repos/jadecli/<repo>/pulls/<N> -X PATCH -f body="..."` |
| SSH push uses wrong key (`azhoukuw`) for jadecli org | Use HTTPS remotes: `git remote set-url origin https://github.com/jadecli/<repo>.git` |
| `gh pr merge` fails on draft PRs | Run `gh pr ready <N>` before merge |
| `gh issue create --label X` fails if label doesn't exist | Script falls back to creating issue without labels |
| jade-ide PR retarget fails on duplicate head/base pair | Document and skip — close manually if needed |
| commitlint rejects non-standard types (e.g. `wip:`) | Use `chore:` instead |
