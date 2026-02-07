#!/usr/bin/env bash
set -euo pipefail

# Sync pre-main and main branches across all jadecli repos using GitHub API

ORG="jadecli"
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
  "jade-monolith"
  "jade-swarm"
  "jadecli-codespaces"
  "jadecli-infra"
  "jadecli-roadmap-and-architecture"
  "jadeflow-dev-scaffold"
)

# Parse flags
DRY_RUN=false
REVERSE=false

for arg in "$@"; do
  case $arg in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --reverse)
      REVERSE=true
      shift
      ;;
    *)
      echo "Unknown flag: $arg"
      echo "Usage: $0 [--dry-run] [--reverse]"
      exit 1
      ;;
  esac
done

# Determine merge direction
if [ "$REVERSE" = true ]; then
  SOURCE="main"
  TARGET="pre-main"
else
  SOURCE="pre-main"
  TARGET="main"
fi

echo "Syncing $SOURCE → $TARGET across $ORG repos"
if [ "$DRY_RUN" = true ]; then
  echo "(DRY RUN MODE)"
fi
echo ""

# Counters
merged_count=0
uptodate_count=0
conflict_count=0

for repo in "${REPOS[@]}"; do
  # Check if source is ahead of target
  ahead_by=$(gh api "repos/$ORG/$repo/compare/$TARGET...$SOURCE" --jq '.ahead_by' 2>/dev/null || echo "error")

  if [ "$ahead_by" = "error" ]; then
    echo "✗ $repo: failed to compare branches (check if branches exist)"
    ((conflict_count++))
    continue
  fi

  if [ "$ahead_by" -eq 0 ]; then
    echo "✓ $repo: up to date"
    ((uptodate_count++))
    continue
  fi

  # Source is ahead, attempt merge
  if [ "$DRY_RUN" = true ]; then
    echo "→ $repo: would merge $ahead_by commit(s)"
    ((merged_count++))
  else
    merge_json=$(cat <<EOF
{
  "base": "$TARGET",
  "head": "$SOURCE",
  "commit_message": "Merge $SOURCE into $TARGET"
}
EOF
)

    merge_result=$(gh api -X POST "repos/$ORG/$repo/merges" --input - <<< "$merge_json" 2>&1 || echo "conflict")

    if echo "$merge_result" | grep -q "Merge conflict"; then
      echo "✗ $repo: merge conflict — resolve locally"
      ((conflict_count++))
    elif echo "$merge_result" | grep -q "HTTP 409"; then
      echo "✗ $repo: merge conflict — resolve locally"
      ((conflict_count++))
    elif [ "$merge_result" = "conflict" ]; then
      echo "✗ $repo: merge conflict — resolve locally"
      ((conflict_count++))
    else
      echo "✓ $repo: merged ($ahead_by commit(s))"
      ((merged_count++))
    fi
  fi
done

# Print summary
echo ""
echo "Summary:"
echo "  Merged: $merged_count"
echo "  Up to date: $uptodate_count"
echo "  Conflicts: $conflict_count"

if [ $conflict_count -gt 0 ]; then
  exit 1
fi
