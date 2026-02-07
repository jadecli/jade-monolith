#!/usr/bin/env bash
# git-status-all.sh — Token-efficient JSON status for all jadecli repos
# Usage: git-status-all.sh [--json|--table]
set -euo pipefail

PROJECTS_DIR="$HOME/projects"
FORMAT="${1:---table}"

REPOS=(
  claude-objects dotfiles jade-claude-settings jade-cli jade-dev-assist
  jade-docker jade-ecosystem-assist jade-ide jade-index jade-swarm
  jadecli-codespaces jadecli-infra jadecli-roadmap-and-architecture
  jadeflow-dev-scaffold
)

get_repo_status() {
  local dir="$PROJECTS_DIR/$1"
  [[ -d "$dir/.git" ]] || { echo '{}'; return; }

  cd "$dir"
  git fetch --quiet origin 2>/dev/null || true

  local branch upstream ahead behind untracked modified staged stash worktrees
  branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "DETACHED")
  upstream=$(git rev-parse --abbrev-ref '@{u}' 2>/dev/null || echo "none")

  if [[ "$upstream" != "none" ]]; then
    ahead=$(git rev-list --count '@{u}..HEAD' 2>/dev/null || echo 0)
    behind=$(git rev-list --count 'HEAD..@{u}' 2>/dev/null || echo 0)
  else
    ahead=0; behind=0
  fi

  untracked=$(git ls-files --others --exclude-standard | wc -l)
  modified=$(git diff --name-only | wc -l)
  staged=$(git diff --cached --name-only | wc -l)
  stash=$(git stash list | wc -l)

  # Local branches not tracking a remote
  local untracked_branches
  untracked_branches=$(git for-each-ref --format='%(refname:short) %(upstream)' refs/heads/ \
    | awk '$2 == "" {print $1}' | paste -sd',' - || echo "")

  # Active worktrees (excluding main)
  worktrees=$(git worktree list --porcelain 2>/dev/null | grep -c '^worktree ' || echo 0)
  worktrees=$((worktrees - 1))  # subtract main worktree
  [[ $worktrees -lt 0 ]] && worktrees=0

  printf '{"repo":"%s","branch":"%s","upstream":"%s","ahead":%d,"behind":%d,"untracked":%d,"modified":%d,"staged":%d,"stash":%d,"untracked_branches":"%s","worktrees":%d}' \
    "$1" "$branch" "$upstream" "$ahead" "$behind" "$untracked" "$modified" "$staged" "$stash" "$untracked_branches" "$worktrees"
}

if [[ "$FORMAT" == "--json" ]]; then
  echo "["
  first=true
  for repo in "${REPOS[@]}"; do
    $first || echo ","
    first=false
    get_repo_status "$repo"
  done
  echo "]"
else
  # Human-readable table
  printf "%-30s %-20s %-18s %3s %3s %3s %3s %3s %3s %-30s %s\n" \
    "REPO" "BRANCH" "UPSTREAM" "AHD" "BHD" "UNT" "MOD" "STG" "STH" "UNTRACKED BRANCHES" "WT"
  printf "%s\n" "$(printf '%.0s-' {1..160})"

  for repo in "${REPOS[@]}"; do
    json=$(get_repo_status "$repo")
    [[ "$json" == '{}' ]] && continue

    # Parse JSON with bash (avoid jq dependency for speed)
    branch=$(echo "$json" | grep -oP '"branch":"\K[^"]+')
    upstream=$(echo "$json" | grep -oP '"upstream":"\K[^"]+')
    ahead=$(echo "$json" | grep -oP '"ahead":\K[0-9]+')
    behind=$(echo "$json" | grep -oP '"behind":\K[0-9]+')
    untracked=$(echo "$json" | grep -oP '"untracked":\K[0-9]+')
    modified=$(echo "$json" | grep -oP '"modified":\K[0-9]+')
    staged=$(echo "$json" | grep -oP '"staged":\K[0-9]+')
    stash=$(echo "$json" | grep -oP '"stash":\K[0-9]+')
    untracked_br=$(echo "$json" | grep -oP '"untracked_branches":"\K[^"]*')
    worktrees=$(echo "$json" | grep -oP '"worktrees":\K[0-9]+')

    # Highlight dirty repos
    dirty=""
    [[ "$untracked" -gt 0 || "$modified" -gt 0 || "$staged" -gt 0 ]] && dirty="*"
    [[ "$ahead" -gt 0 ]] && dirty="${dirty}^"

    printf "%-30s %-20s %-18s %3s %3s %3s %3s %3s %3s %-30s %s\n" \
      "${repo}${dirty}" "$branch" "$upstream" "$ahead" "$behind" \
      "$untracked" "$modified" "$staged" "$stash" "$untracked_br" "$worktrees"
  done
fi
