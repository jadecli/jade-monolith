#!/usr/bin/env bash
# swarm-status.sh — Display the status of the 100-agent swarm
# Usage: ./scripts/swarm-status.sh [--json]
set -euo pipefail

AGENTS_DIR="$(cd "$(dirname "$0")/.." && pwd)/.claude/agents"
FORMAT="${1:-table}"

if [ ! -d "$AGENTS_DIR" ]; then
    echo "ERROR: Agents directory not found at $AGENTS_DIR" >&2
    exit 1
fi

# Count agents
TOTAL=$(ls "$AGENTS_DIR"/*.md 2>/dev/null | wc -l)

# Parse agent metadata
declare -A CATEGORY_COUNT
declare -A MODEL_COUNT
READONLY=0
WRITABLE=0
WEB_CAPABLE=0
MEMORY_ENABLED=0

for agent_file in "$AGENTS_DIR"/*.md; do
    [ -f "$agent_file" ] || continue
    name=$(basename "$agent_file" .md)

    # Extract model from frontmatter
    model=$(sed -n '/^---$/,/^---$/p' "$agent_file" | grep '^model:' | head -1 | awk '{print $2}')
    model=${model:-inherit}

    # Count models
    MODEL_COUNT[$model]=$(( ${MODEL_COUNT[$model]:-0} + 1 ))

    # Check if read-only (has Write or Edit in disallowedTools)
    if sed -n '/^---$/,/^---$/p' "$agent_file" | grep -q 'disallowedTools' && \
       sed -n '/^---$/,/^---$/p' "$agent_file" | grep -A 20 'disallowedTools' | grep -qE '^\s*-\s*(Write|Edit)'; then
        READONLY=$((READONLY + 1))
    else
        WRITABLE=$((WRITABLE + 1))
    fi

    # Check web capability
    if sed -n '/^---$/,/^---$/p' "$agent_file" | grep -q 'WebSearch\|WebFetch'; then
        if ! sed -n '/^---$/,/^---$/p' "$agent_file" | grep -A 20 'disallowedTools' | grep -qE '^\s*-\s*Web(Search|Fetch)'; then
            WEB_CAPABLE=$((WEB_CAPABLE + 1))
        fi
    fi

    # Check memory
    if sed -n '/^---$/,/^---$/p' "$agent_file" | grep -q '^memory:'; then
        MEMORY_ENABLED=$((MEMORY_ENABLED + 1))
    fi

    # Categorize by name prefix/role
    case "$name" in
        swarm-*|task-*|context-*|progress-*|conflict-*)
            cat="Orchestration" ;;
        architect|domain-*|api-designer|schema-*|migration-*|dependency-architect)
            cat="Architecture" ;;
        *researcher*|codebase-explorer|library-evaluator|competitor-analyst)
            cat="Research" ;;
        *-dev|implementer|fullstack-dev)
            cat="Development" ;;
        *tester*|test-writer|fuzzer|e2e-*|load-*|mutation-*|contract-*)
            cat="Testing" ;;
        reviewer|*-auditor|*-reviewer|*-enforcer|*-analyzer|*-checker|*-detector|license-*)
            cat="Review & Quality" ;;
        devops-*|ci-cd-*|container-*|cloud-*|monitoring-*|incident-*|capacity-*|release-*|environment-*|infrastructure-*)
            cat="DevOps" ;;
        *-writer|*-doc-*)
            cat="Documentation" ;;
        data-*|ml-*|analytics-*)
            cat="Data & Analytics" ;;
        i18n-*|a11y-*|seo-*|compliance-*|gdpr-*|*-optimizer|*-strategist|bundle-*|query-*|cache-*|memory-optimizer|performance-optimizer)
            cat="Specialized" ;;
        tech-writer|stakeholder-*|sprint-*|retrospective-*|decision-*)
            cat="Communication" ;;
        debugger|log-*|error-*|*-profiler|network-*|race-*|deadlock-*|regression-*|root-cause-*)
            cat="Debugging" ;;
        *)
            cat="Other" ;;
    esac

    CATEGORY_COUNT[$cat]=$(( ${CATEGORY_COUNT[$cat]:-0} + 1 ))
done

if [ "$FORMAT" = "--json" ]; then
    echo "{"
    echo "  \"total\": $TOTAL,"
    echo "  \"categories\": {"
    first=true
    for cat in "${!CATEGORY_COUNT[@]}"; do
        if [ "$first" = true ]; then first=false; else echo ","; fi
        printf "    \"%s\": %d" "$cat" "${CATEGORY_COUNT[$cat]}"
    done
    echo ""
    echo "  },"
    echo "  \"models\": {"
    first=true
    for model in "${!MODEL_COUNT[@]}"; do
        if [ "$first" = true ]; then first=false; else echo ","; fi
        printf "    \"%s\": %d" "$model" "${MODEL_COUNT[$model]}"
    done
    echo ""
    echo "  },"
    echo "  \"capabilities\": {"
    echo "    \"read_only\": $READONLY,"
    echo "    \"writable\": $WRITABLE,"
    echo "    \"web_capable\": $WEB_CAPABLE,"
    echo "    \"memory_enabled\": $MEMORY_ENABLED"
    echo "  }"
    echo "}"
else
    echo "JADE SWARM STATUS — $TOTAL Agent Roster"
    echo "========================================"
    echo ""
    printf "%-28s %s\n" "Category" "Count"
    echo "────────────────────────────────────"
    for cat in "Orchestration" "Architecture" "Research" "Development" "Testing" "Review & Quality" "DevOps" "Documentation" "Data & Analytics" "Specialized" "Communication" "Debugging" "Other"; do
        count=${CATEGORY_COUNT[$cat]:-0}
        if [ "$count" -gt 0 ]; then
            printf "%-28s %d\n" "$cat" "$count"
        fi
    done
    echo "────────────────────────────────────"
    printf "%-28s %d\n" "TOTAL" "$TOTAL"
    echo ""
    echo "Model Distribution:"
    for model in "opus" "sonnet" "haiku" "inherit"; do
        count=${MODEL_COUNT[$model]:-0}
        if [ "$count" -gt 0 ]; then
            printf "  %-10s %d agents\n" "$model" "$count"
        fi
    done
    echo ""
    echo "Capabilities:"
    printf "  Read-only:      %d agents\n" "$READONLY"
    printf "  Write-capable:  %d agents\n" "$WRITABLE"
    printf "  Web-capable:    %d agents\n" "$WEB_CAPABLE"
    printf "  Memory-enabled: %d agents\n" "$MEMORY_ENABLED"
fi
