#!/usr/bin/env bash
set -euo pipefail

# jade-monolith ecosystem health check script
# Checks submodules, GitHub issues/PRs, Docker services, and GPU availability

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MONOLITH_DIR="${MONOLITH_DIR:-$(dirname "$SCRIPT_DIR")}"
JSON_OUTPUT=false

# Parse flags
while [[ $# -gt 0 ]]; do
  case $1 in
    --json)
      JSON_OUTPUT=true
      shift
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Usage: $0 [--json]" >&2
      exit 1
      ;;
  esac
done

# GitHub org and repos
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

CORE_REPOS=(
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
)

# Check submodules
check_submodules() {
  local total=0
  local on_main=0
  local behind=0
  local detached_list=()
  local behind_list=()

  cd "$MONOLITH_DIR"

  # Count submodules in packages/
  if [[ -d packages ]]; then
    while IFS= read -r submodule; do
      ((total++))
      local name=$(basename "$submodule")

      cd "$submodule"

      # Check if on main branch
      local current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "detached")

      if [[ "$current_branch" == "main" ]]; then
        # Check if behind origin/main
        git fetch origin main --quiet 2>/dev/null || true
        local local_commit=$(git rev-parse HEAD 2>/dev/null || echo "")
        local remote_commit=$(git rev-parse origin/main 2>/dev/null || echo "")

        if [[ -n "$local_commit" && -n "$remote_commit" && "$local_commit" == "$remote_commit" ]]; then
          ((on_main++))
        else
          ((behind++))
          behind_list+=("$name")
        fi
      else
        detached_list+=("$name")
      fi

      cd "$MONOLITH_DIR"
    done < <(find packages -mindepth 1 -maxdepth 1 -type d 2>/dev/null || true)
  fi

  echo "$total|$on_main|$behind|${detached_list[*]:-}|${behind_list[*]:-}"
}

# Check GitHub issues and PRs
check_github() {
  local total_issues=0
  local total_prs=0
  local core_issues=0
  local core_prs=0

  for repo in "${REPOS[@]}"; do
    local is_core=false
    for core_repo in "${CORE_REPOS[@]}"; do
      if [[ "$repo" == "$core_repo" ]]; then
        is_core=true
        break
      fi
    done

    # Check issues
    local issues=$(gh api "repos/$ORG/$repo/issues?state=open&per_page=100" --jq 'length' 2>/dev/null || echo "0")
    # Check PRs (PRs are also issues, so subtract them)
    local prs=$(gh api "repos/$ORG/$repo/pulls?state=open&per_page=100" --jq 'length' 2>/dev/null || echo "0")
    local actual_issues=$((issues - prs))

    ((total_issues += actual_issues))
    ((total_prs += prs))

    if [[ "$is_core" == true ]]; then
      ((core_issues += actual_issues))
      ((core_prs += prs))
    fi
  done

  echo "$total_issues|$total_prs|$core_issues|$core_prs"
}

# Check Docker services
check_docker() {
  local postgres="false"
  local mongodb="false"
  local dragonfly="false"

  # Check PostgreSQL (port 5432)
  if timeout 2 nc -z localhost 5432 2>/dev/null; then
    postgres="true"
  fi

  # Check MongoDB (port 27017)
  if timeout 2 nc -z localhost 27017 2>/dev/null; then
    mongodb="true"
  fi

  # Check Dragonfly (port 6379)
  if timeout 2 nc -z localhost 6379 2>/dev/null; then
    dragonfly="true"
  fi

  echo "$postgres|$mongodb|$dragonfly"
}

# Check GPU
check_gpu() {
  local available="false"
  local name="none"

  if command -v nvidia-smi &>/dev/null; then
    if nvidia-smi &>/dev/null; then
      available="true"
      name=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -n1 || echo "unknown")
      local memory=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null | head -n1 || echo "0")
      if [[ -n "$memory" && "$memory" != "0" ]]; then
        local memory_gb=$((memory / 1024))
        name="$name (${memory_gb}GB)"
      fi
    fi
  fi

  echo "$available|$name"
}

# Gather all checks
submodule_result=$(check_submodules)
github_result=$(check_github)
docker_result=$(check_docker)
gpu_result=$(check_gpu)

# Parse results
IFS='|' read -r sub_total sub_on_main sub_behind sub_detached sub_behind_list <<< "$submodule_result"
IFS='|' read -r gh_issues gh_prs gh_core_issues gh_core_prs <<< "$github_result"
IFS='|' read -r docker_postgres docker_mongodb docker_dragonfly <<< "$docker_result"
IFS='|' read -r gpu_available gpu_name <<< "$gpu_result"

# Determine overall health
healthy=true
if [[ "$sub_on_main" -ne "$sub_total" ]]; then
  healthy=false
fi
if [[ "$gh_core_issues" -gt 0 || "$gh_core_prs" -gt 0 ]]; then
  healthy=false
fi

# Output
if [[ "$JSON_OUTPUT" == true ]]; then
  cat <<EOF
{
  "submodules": {
    "total": $sub_total,
    "on_main": $sub_on_main,
    "behind": $sub_behind
  },
  "github": {
    "issues": $gh_issues,
    "prs": $gh_prs,
    "core_issues": $gh_core_issues,
    "core_prs": $gh_core_prs
  },
  "docker": {
    "postgres": $docker_postgres,
    "mongodb": $docker_mongodb,
    "dragonfly": $docker_dragonfly
  },
  "gpu": {
    "available": $gpu_available,
    "name": "$gpu_name"
  },
  "healthy": $healthy
}
EOF
else
  echo "=== Ecosystem Health Check ==="
  echo ""

  # Submodules
  if [[ "$sub_on_main" -eq "$sub_total" ]]; then
    echo "Submodules: $sub_on_main/$sub_total on main ✓"
  else
    echo "Submodules: $sub_on_main/$sub_total on main ✗"
    if [[ -n "$sub_detached" ]]; then
      echo "  Detached: $sub_detached"
    fi
    if [[ -n "$sub_behind_list" ]]; then
      echo "  Behind: $sub_behind_list"
    fi
  fi

  # GitHub
  if [[ "$gh_core_issues" -eq 0 && "$gh_core_prs" -eq 0 ]]; then
    echo "Issues/PRs: $gh_core_issues issues, $gh_core_prs PRs (core) ✓"
  else
    echo "Issues/PRs: $gh_core_issues issues, $gh_core_prs PRs (core) ✗"
  fi

  # Docker
  echo -n "Docker:     "
  if [[ "$docker_postgres" == "true" ]]; then
    echo -n "PostgreSQL ✓  "
  else
    echo -n "PostgreSQL ✗  "
  fi
  if [[ "$docker_mongodb" == "true" ]]; then
    echo -n "MongoDB ✓  "
  else
    echo -n "MongoDB ✗  "
  fi
  if [[ "$docker_dragonfly" == "true" ]]; then
    echo "Dragonfly ✓"
  else
    echo "Dragonfly ✗"
  fi

  # GPU
  if [[ "$gpu_available" == "true" ]]; then
    echo "GPU:        $gpu_name ✓"
  else
    echo "GPU:        Not available"
  fi

  echo ""
  if [[ "$healthy" == true ]]; then
    echo "Overall: HEALTHY"
  else
    echo "Overall: DEGRADED"
  fi
fi

# Exit with appropriate code
if [[ "$healthy" == true ]]; then
  exit 0
else
  exit 1
fi
