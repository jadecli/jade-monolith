#!/usr/bin/env bash
# statusline.sh — Fast statusline for jade-monolith Claude Code sessions
# Shows: branch | dirty state | open issues/PRs across ecosystem (cached)
set -euo pipefail

MONOLITH="$HOME/projects/jade-monolith"
CACHE_FILE="/tmp/jade-monolith-statusline-cache"
CACHE_TTL=300  # 5 minutes

# --- Git state (always live, fast) ---
git_info() {
  cd "$MONOLITH"
  local branch dirty
  branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "detached")

  dirty=""
  [[ -n $(git diff --name-only 2>/dev/null) ]] && dirty+="M"
  [[ -n $(git diff --cached --name-only 2>/dev/null) ]] && dirty+="S"
  [[ -n $(git ls-files --others --exclude-standard 2>/dev/null | head -1) ]] && dirty+="U"

  if [[ -n "$dirty" ]]; then
    echo "$branch [$dirty]"
  else
    echo "$branch"
  fi
}

# --- Ecosystem counts (cached, gh API) ---
ecosystem_counts() {
  # Return cached if fresh enough
  if [[ -f "$CACHE_FILE" ]]; then
    local age=$(( $(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0) ))
    if [[ $age -lt $CACHE_TTL ]]; then
      cat "$CACHE_FILE"
      return
    fi
  fi

  # Fetch in background if stale, return old cache immediately
  if [[ -f "$CACHE_FILE" ]]; then
    cat "$CACHE_FILE"
    _refresh_cache &
    return
  fi

  # No cache at all — do a synchronous fetch (first run only)
  _refresh_cache
  cat "$CACHE_FILE" 2>/dev/null || echo "..."
}

_refresh_cache() {
  local repos=(
    claude-objects dotfiles jade-claude-settings jade-cli jade-dev-assist
    jade-docker jade-ecosystem-assist jade-ide jade-index jade-swarm
    jadecli-codespaces jadecli-infra jadecli-roadmap-and-architecture
    jadeflow-dev-scaffold jade-monolith
  )

  local total_issues=0 total_prs=0
  for repo in "${repos[@]}"; do
    local counts
    counts=$(gh api "repos/jadecli/$repo" --jq '"\(.open_issues_count)"' 2>/dev/null || echo "0")
    total_issues=$((total_issues + counts))
  done

  # open_issues_count includes PRs, so get actual PR count separately
  for repo in "${repos[@]}"; do
    local pr_count
    pr_count=$(gh api "repos/jadecli/$repo/pulls?state=open&per_page=1" --jq 'length' 2>/dev/null || echo "0")
    total_prs=$((total_prs + pr_count))
  done

  total_issues=$((total_issues - total_prs))

  echo "${total_issues}i ${total_prs}pr" > "$CACHE_FILE"
}

# --- Assemble ---
GIT=$(git_info)
ECO=$(ecosystem_counts)

echo "jade-monolith $GIT | $ECO"
