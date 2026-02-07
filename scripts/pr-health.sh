#!/usr/bin/env bash
# pr-health.sh — Show PR health across all jadecli repos
# Usage: pr-health.sh [--json|--table]
set -euo pipefail

FORMAT="${1:---table}"

REPOS=(
  claude-objects dotfiles jade-claude-settings jade-cli jade-dev-assist
  jade-docker jade-ecosystem-assist jade-ide jade-index jade-swarm
  jadecli-codespaces jadecli-infra jadecli-roadmap-and-architecture
  jadeflow-dev-scaffold
)

ORG="jadecli"

get_pr_health() {
  local repo="$1"
  local total=0 unlinked=0 release_please=0

  local prs
  prs=$(gh pr list --repo "$ORG/$repo" --state open --json number,title,body,headRefName,baseRefName 2>/dev/null) || { echo '{}'; return; }

  total=$(echo "$prs" | jq 'length')
  [[ "$total" -eq 0 ]] && {
    printf '{"repo":"%s","total":0,"unlinked":0,"release_please":0,"wrong_base":0,"prs":[]}' "$repo"
    return
  }

  # Count release-please PRs
  release_please=$(echo "$prs" | jq '[.[] | select(.headRefName | startswith("release-please"))] | length')

  # Count unlinked (no issue reference in body or title)
  unlinked=$(echo "$prs" | jq '[.[] | select(
    (.headRefName | startswith("release-please")) | not
  ) | select(
    ((.body // "") | test("#[0-9]+|[Cc]loses|[Ff]ixes|[Rr]esolves") | not)
    and ((.title // "") | test("#[0-9]+|[Cc]loses|[Ff]ixes|[Rr]esolves") | not)
  )] | length')

  # Build PR list for JSON output
  local pr_list
  pr_list=$(echo "$prs" | jq -c '[.[] | {number, title: .title[0:60], head: .headRefName, base: .baseRefName}]')

  printf '{"repo":"%s","total":%d,"unlinked":%d,"release_please":%d,"prs":%s}' \
    "$repo" "$total" "$unlinked" "$release_please" "$pr_list"
}

if [[ "$FORMAT" == "--json" ]]; then
  echo "["
  first=true
  for repo in "${REPOS[@]}"; do
    $first || echo ","
    first=false
    get_pr_health "$repo"
  done
  echo "]"
else
  printf "%-35s %5s %8s %8s\n" "REPO" "TOTAL" "UNLINKED" "REL-PLS"
  printf "%s\n" "$(printf '%.0s-' {1..60})"

  total_all=0 unlinked_all=0

  for repo in "${REPOS[@]}"; do
    json=$(get_pr_health "$repo")
    [[ "$json" == '{}' ]] && continue

    total=$(echo "$json" | jq '.total')
    unlinked=$(echo "$json" | jq '.unlinked')
    rp=$(echo "$json" | jq '.release_please')

    total_all=$((total_all + total))
    unlinked_all=$((unlinked_all + unlinked))

    [[ "$total" -eq 0 ]] && continue

    marker=""
    [[ "$unlinked" -gt 0 ]] && marker=" !"

    printf "%-35s %5d %8d %8d%s\n" "$repo" "$total" "$unlinked" "$rp" "$marker"
  done

  printf "%s\n" "$(printf '%.0s-' {1..60})"
  printf "%-35s %5d %8d\n" "TOTALS" "$total_all" "$unlinked_all"
fi
