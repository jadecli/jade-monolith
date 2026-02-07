#!/usr/bin/env bash
# scripts/start-team.sh — Start a 4-agent tmux session for development
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "$(pwd)")"
SESSION_NAME="jade-team"

# Check prerequisites
command -v tmux >/dev/null 2>&1 || { echo "tmux required: sudo apt install tmux"; exit 1; }
command -v claude >/dev/null 2>&1 || { echo "claude required: npm install -g @anthropic-ai/claude-code"; exit 1; }

# Kill existing session if present
tmux kill-session -t "$SESSION_NAME" 2>/dev/null || true

# Ensure Agent Teams is enabled
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1

# Source project tmux config if available
TMUX_CONF="${REPO_ROOT}/.tmux.conf"
if [ -f "$TMUX_CONF" ]; then
    TMUX_OPTS="-f $TMUX_CONF"
else
    TMUX_OPTS=""
fi

echo "Starting Agent Teams session: $SESSION_NAME"
echo "Repo: $REPO_ROOT"
echo ""
echo "Pane layout:"
echo "  +--------------+---------------+"
echo "  |  Architect   |  Implementer  |"
echo "  +--------------+---------------+"
echo "  | Test Writer  |   Reviewer    |"
echo "  +--------------+---------------+"
echo ""

# Create 4-pane tmux session
tmux new-session -d -s "$SESSION_NAME" -n agents -c "$REPO_ROOT"
tmux split-window -h -t "${SESSION_NAME}:agents" -c "$REPO_ROOT"
tmux split-window -v -t "${SESSION_NAME}:agents.0" -c "$REPO_ROOT"
tmux split-window -v -t "${SESSION_NAME}:agents.1" -c "$REPO_ROOT"

# Label panes and start agents
tmux send-keys -t "${SESSION_NAME}:agents.0" "echo '=== ARCHITECT (read-only) ===' && claude --agent architect --permission-mode plan" Enter
tmux send-keys -t "${SESSION_NAME}:agents.1" "echo '=== IMPLEMENTER ===' && claude --agent implementer" Enter
tmux send-keys -t "${SESSION_NAME}:agents.2" "echo '=== TEST WRITER ===' && claude --agent test-writer" Enter
tmux send-keys -t "${SESSION_NAME}:agents.3" "echo '=== REVIEWER (read-only) ===' && claude --agent reviewer --permission-mode plan" Enter

echo "Session '$SESSION_NAME' created. Attaching..."
echo "Detach: Ctrl+B, D | Switch panes: Ctrl+B, Arrow keys"
echo ""

tmux attach -t "$SESSION_NAME"
