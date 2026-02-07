#!/usr/bin/env bash
# swarm-launch.sh — Launch a swarm session with proper configuration
# Usage: ./scripts/swarm-launch.sh [swarm-type] [args...]
#
# Swarm types:
#   research  - Research swarm (read-only investigation)
#   develop   - Development swarm (TDD workflow)
#   review    - Review swarm (multi-perspective code review)
#   debug     - Debug swarm (competing hypotheses)
#   deploy    - Deployment swarm (release preparation)
#   full      - Full 100-agent swarm (orchestrator selects agents)
#
# Examples:
#   ./scripts/swarm-launch.sh research "How does the auth module work?"
#   ./scripts/swarm-launch.sh develop "Add user profile API endpoint"
#   ./scripts/swarm-launch.sh review "PR #42"
#   ./scripts/swarm-launch.sh debug "Users report 500 errors on login"
#   ./scripts/swarm-launch.sh full "Refactor the entire notification system"
set -euo pipefail

SWARM_TYPE="${1:-full}"
shift || true
ARGS="$*"

# Validate swarm type
case "$SWARM_TYPE" in
    research|develop|review|debug|deploy|full)
        ;;
    *)
        echo "Unknown swarm type: $SWARM_TYPE" >&2
        echo "Valid types: research, develop, review, debug, deploy, full" >&2
        exit 1
        ;;
esac

# Map swarm type to skill
case "$SWARM_TYPE" in
    research) SKILL="swarm-research" ;;
    develop)  SKILL="swarm-develop" ;;
    review)   SKILL="swarm-review" ;;
    debug)    SKILL="swarm-debug" ;;
    deploy)   SKILL="swarm-deploy" ;;
    full)     SKILL="swarm" ;;
esac

echo "=== Jade Swarm Launcher ==="
echo "Type:   $SWARM_TYPE"
echo "Skill:  /$SKILL"
echo "Args:   $ARGS"
echo ""

# Check prerequisites
if ! command -v claude &>/dev/null; then
    echo "ERROR: claude CLI not found. Install Claude Code first." >&2
    exit 1
fi

# Verify agent teams are enabled
SETTINGS_FILE="$(cd "$(dirname "$0")/.." && pwd)/.claude/settings.json"
if [ -f "$SETTINGS_FILE" ]; then
    TEAMS_ENABLED=$(jq -r '.env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS // "0"' "$SETTINGS_FILE")
    if [ "$TEAMS_ENABLED" != "1" ]; then
        echo "WARNING: Agent teams not enabled in settings.json" >&2
        echo "Add CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 to env" >&2
    fi
fi

# Count available agents
AGENTS_DIR="$(cd "$(dirname "$0")/.." && pwd)/.claude/agents"
AGENT_COUNT=$(ls "$AGENTS_DIR"/*.md 2>/dev/null | wc -l)
echo "Agents: $AGENT_COUNT available"
echo ""

# Launch claude with the swarm skill
echo "Launching swarm..."
echo "Run: /$SKILL $ARGS"
echo ""

# Use the swarm-orchestrator agent as the main agent
exec claude --agent swarm-orchestrator -p "/$SKILL $ARGS"
