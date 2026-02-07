#!/usr/bin/env bash
# create-issues-for-prs.sh — Create GitHub issues for unlinked PRs
# Usage: create-issues-for-prs.sh <repo> [--dry-run]
set -euo pipefail

REPO="${1:?Usage: create-issues-for-prs.sh <repo> [--dry-run]}"
DRY_RUN="${2:-}"
ORG="jadecli"

echo "Processing $ORG/$REPO..."

prs=$(gh pr list --repo "$ORG/$REPO" --state open \
  --json number,title,body,headRefName,baseRefName 2>/dev/null) || {
  echo "  Skipped: could not list PRs"
  exit 0
}

total=$(echo "$prs" | jq 'length')
[[ "$total" -eq 0 ]] && { echo "  No open PRs"; exit 0; }

echo "$prs" | jq -c '.[]' | while IFS= read -r pr; do
  number=$(echo "$pr" | jq -r '.number')
  title=$(echo "$pr" | jq -r '.title')
  body=$(echo "$pr" | jq -r '.body // ""')
  head=$(echo "$pr" | jq -r '.headRefName')

  # Skip release-please PRs
  if [[ "$head" == release-please* ]]; then
    echo "  PR #$number: skip (release-please)"
    continue
  fi

  # Check if already linked to an issue
  if echo "$body" | grep -qiP '(closes|fixes|resolves)\s+#[0-9]+'; then
    echo "  PR #$number: skip (already linked)"
    continue
  fi
  if echo "$title" | grep -qiP '#[0-9]+'; then
    echo "  PR #$number: skip (issue ref in title)"
    continue
  fi

  # Derive issue title from PR title
  issue_title="$title"

  # Derive label from conventional commit prefix
  label=""
  case "$title" in
    feat:*|feat\(*) label="enhancement" ;;
    fix:*|fix\(*)   label="bug" ;;
    docs:*|docs\(*) label="documentation" ;;
    test:*|test\(*) label="testing" ;;
    chore:*|chore\(*|refactor:*|refactor\(*) label="chore" ;;
    audit:*|audit\(*) label="audit" ;;
  esac

  # Build issue body
  issue_body="Tracking issue for PR #$number.

## Context
Branch: \`$head\`
PR: #$number"

  if [[ "$DRY_RUN" == "--dry-run" ]]; then
    echo "  PR #$number: would create issue '$issue_title' (label: ${label:-none})"
    continue
  fi

  # Create issue (try with label first, fallback without)
  if [[ -n "$label" ]]; then
    issue_url=$(gh issue create --repo "$ORG/$REPO" \
      --title "$issue_title" \
      --body "$issue_body" \
      --label "$label" 2>&1) || \
    issue_url=$(gh issue create --repo "$ORG/$REPO" \
      --title "$issue_title" \
      --body "$issue_body" 2>&1) || {
      echo "  PR #$number: ERROR creating issue: $issue_url"
      continue
    }
  else
    issue_url=$(gh issue create --repo "$ORG/$REPO" \
      --title "$issue_title" \
      --body "$issue_body" 2>&1) || {
      echo "  PR #$number: ERROR creating issue: $issue_url"
      continue
    }
  fi

  # Extract issue number from URL
  issue_num=$(echo "$issue_url" | grep -oP '[0-9]+$')

  # Update PR body to link issue (use REST API to avoid classic projects bug)
  if [[ -n "$body" ]]; then
    new_body="${body}

Closes #${issue_num}"
  else
    new_body="Closes #${issue_num}"
  fi

  gh api "repos/$ORG/$REPO/pulls/$number" -X PATCH -f body="$new_body" --jq '.number' >/dev/null 2>&1 || {
    echo "  PR #$number: created issue #$issue_num but failed to update PR body"
    continue
  }

  echo "  PR #$number -> Issue #$issue_num ($issue_url)"
done

echo "Done: $ORG/$REPO"
