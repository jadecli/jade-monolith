#!/usr/bin/env bash
set -euo pipefail

# update-submodules.sh - Update all jade-monolith submodules to latest main branch

# Default monolith directory (script's parent's parent)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MONOLITH_DIR="${MONOLITH_DIR:-$(dirname "$SCRIPT_DIR")}"

# Dry run mode
DRY_RUN=false

# Submodule repositories
REPOS=(
  "claude-objects"
  "dotfiles"
  "jade-claude-settings"
  "jade-cli"
  "jade-dev-assist"
  "jade-docker"
  "jade-ecosystem-assist"
  "jade-ide"
  "jade-index"
  "jade-swarm"
  "jadecli-codespaces"
  "jadecli-infra"
  "jadecli-roadmap-and-architecture"
  "jadeflow-dev-scaffold"
)

# Parse arguments
for arg in "$@"; do
  case $arg in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    *)
      echo "Unknown option: $arg"
      echo "Usage: $0 [--dry-run]"
      exit 1
      ;;
  esac
done

# Change to monolith directory
cd "$MONOLITH_DIR"

echo "Updating submodules in: $MONOLITH_DIR"
if [ "$DRY_RUN" = true ]; then
  echo "DRY RUN MODE - no changes will be made"
fi
echo ""

# Track updates
updated_count=0
updated_repos=()

# Process each repository
for repo in "${REPOS[@]}"; do
  submodule_path="packages/$repo"

  if [ ! -d "$submodule_path" ]; then
    echo "⚠️  Skipping $repo (directory not found)"
    continue
  fi

  echo "Checking $repo..."

  # Enter submodule directory
  cd "$submodule_path"

  # Fetch latest from origin/main
  if ! git fetch origin main 2>/dev/null; then
    echo "  ⚠️  Failed to fetch from origin/main"
    cd "$MONOLITH_DIR"
    continue
  fi

  # Get current and latest SHAs
  current_sha=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
  latest_sha=$(git rev-parse origin/main 2>/dev/null || echo "unknown")

  # Check if update is needed
  if [ "$current_sha" = "$latest_sha" ]; then
    echo "  ✓ Already up to date"
  else
    short_current="${current_sha:0:7}"
    short_latest="${latest_sha:0:7}"

    if [ "$DRY_RUN" = true ]; then
      echo "  → Would update: $short_current → $short_latest"
      ((updated_count++))
      updated_repos+=("$repo")
    else
      # Perform update
      if git checkout main 2>/dev/null && git pull origin main 2>/dev/null; then
        echo "  ✓ Updated: $short_current → $short_latest"
        ((updated_count++))
        updated_repos+=("$repo")
      else
        echo "  ✗ Failed to update"
      fi
    fi
  fi

  # Return to monolith directory
  cd "$MONOLITH_DIR"
  echo ""
done

# Stage changes if updates were made
if [ "$DRY_RUN" = false ] && [ $updated_count -gt 0 ]; then
  echo "Staging submodule updates..."
  git add packages/
  echo ""

  echo "Summary of updated submodules:"
  for repo in "${updated_repos[@]}"; do
    echo "  - $repo"
  done
  echo ""
fi

# Print final summary
total_repos="${#REPOS[@]}"
if [ $updated_count -eq 0 ]; then
  echo "✓ All submodules up to date ($total_repos/$total_repos)"
elif [ "$DRY_RUN" = true ]; then
  echo "→ Would update $updated_count/$total_repos submodules"
else
  echo "✓ Updated $updated_count/$total_repos submodules"
  echo ""
  echo "Next steps:"
  echo "  1. Review changes: git status"
  echo "  2. Commit: git commit -m 'chore: update submodules to latest main'"
  echo "  3. Push: git push"
fi
