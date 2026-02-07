#!/usr/bin/env bash
set -euo pipefail

# merge-releases.sh - Find and merge all open release-please PRs across jadecli ecosystem

ORG="jadecli"
REPOS=(
  claude-objects
  dotfiles
  jade-claude-settings
  jade-cli
  jade-dev-assist
  jade-docker
  jade-ecosystem-assist
  jade-ide
  jade-index
  jade-monolith
  jade-swarm
  jadecli-codespaces
  jadecli-infra
  jadecli-roadmap-and-architecture
  jadeflow-dev-scaffold
)

DRY_RUN=false
MERGED_COUNT=0
FAILED_COUNT=0
REPOS_WITH_MERGES=0

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Usage: $0 [--dry-run]" >&2
      exit 1
      ;;
  esac
done

if [[ "$DRY_RUN" == true ]]; then
  echo "DRY RUN MODE - no merges will be performed"
  echo ""
fi

# Sync pre-main branch to match main after successful merge
sync_pre_main() {
  local repo=$1

  # Get the SHA of main branch
  local main_sha
  main_sha=$(gh api "repos/$ORG/$repo/git/ref/heads/main" --jq '.object.sha' 2>/dev/null || echo "")

  if [[ -z "$main_sha" ]]; then
    echo "  Warning: Could not get main branch SHA for $repo, skipping pre-main sync"
    return 1
  fi

  # Check if pre-main exists
  local pre_main_exists
  pre_main_exists=$(gh api "repos/$ORG/$repo/git/ref/heads/pre-main" 2>/dev/null && echo "true" || echo "false")

  if [[ "$pre_main_exists" == "false" ]]; then
    echo "  Info: pre-main branch does not exist in $repo, skipping sync"
    return 0
  fi

  # Update pre-main to match main SHA with force
  if gh api --method PATCH "repos/$ORG/$repo/git/refs/heads/pre-main" \
    --input - <<< "{\"sha\":\"$main_sha\",\"force\":true}" >/dev/null 2>&1; then
    echo "  ✓ Synced pre-main to match main"
    return 0
  else
    echo "  Warning: Failed to sync pre-main for $repo"
    return 1
  fi
}

# Process each repository
for repo in "${REPOS[@]}"; do
  # Find all open PRs with release-please head branch
  prs=$(gh pr list --repo "$ORG/$repo" --state open \
    --json number,title,headRefName,mergeable \
    --jq '.[] | select(.headRefName | startswith("release-please"))' 2>/dev/null || echo "")

  if [[ -z "$prs" ]]; then
    continue
  fi

  # Process each release-please PR
  repo_had_merge=false
  while IFS= read -r pr_json; do
    if [[ -z "$pr_json" ]]; then
      continue
    fi

    pr_number=$(echo "$pr_json" | jq -r '.number')
    pr_title=$(echo "$pr_json" | jq -r '.title')
    pr_mergeable=$(echo "$pr_json" | jq -r '.mergeable')

    if [[ "$pr_mergeable" != "MERGEABLE" ]]; then
      echo "⚠ $repo PR#$pr_number: Not mergeable (state: $pr_mergeable)"
      ((FAILED_COUNT++))
      continue
    fi

    if [[ "$DRY_RUN" == true ]]; then
      echo "Would merge $repo PR#$pr_number: $pr_title"
      ((MERGED_COUNT++))
      repo_had_merge=true
    else
      if gh pr merge "$pr_number" --repo "$ORG/$repo" --merge >/dev/null 2>&1; then
        echo "✓ $repo PR#$pr_number: $pr_title"
        ((MERGED_COUNT++))
        repo_had_merge=true
      else
        echo "✗ $repo PR#$pr_number: merge failed"
        ((FAILED_COUNT++))
      fi
    fi
  done <<< "$(echo "$prs" | jq -c '.')"

  # Sync pre-main after successful merges (skip in dry-run)
  if [[ "$repo_had_merge" == true ]]; then
    ((REPOS_WITH_MERGES++))
    if [[ "$DRY_RUN" == false ]]; then
      sync_pre_main "$repo"
    fi
  fi
done

# Print summary
echo ""
echo "Merged: $MERGED_COUNT release PRs across $REPOS_WITH_MERGES repos. Failed: $FAILED_COUNT"

exit 0
