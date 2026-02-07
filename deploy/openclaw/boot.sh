#!/usr/bin/env bash
# OpenClaw Swarm Bot — Boot Script
# Validates config, sets up auth, and starts the gateway.
set -euo pipefail

echo "=== OpenClaw Swarm Bot ==="
echo "Version: $(openclaw --version)"
echo "Time:    $(date -u +%Y-%m-%dT%H:%M:%SZ)"

# Step 1: Validate required env vars
MISSING=0
for var in ANTHROPIC_API_KEY; do
    if [ -z "${!var:-}" ]; then
        echo "ERROR: Required env var $var is not set" >&2
        MISSING=1
    fi
done
if [ "$MISSING" -eq 1 ]; then
    echo "Set required env vars and retry." >&2
    exit 1
fi
echo "PASS: Required env vars present"

# Step 2: Write auth profile from env vars
AUTH_FILE="$HOME/.openclaw/agents/main/agent/auth-profiles.json"
cat > "$AUTH_FILE" <<AUTHEOF
{
  "anthropic": {
    "type": "api-key",
    "apiKey": "$ANTHROPIC_API_KEY"
  }
}
AUTHEOF
chmod 600 "$AUTH_FILE"
echo "PASS: Auth profile written"

# Step 3: Validate config
if ! openclaw doctor 2>&1 | grep -q "Config invalid"; then
    echo "PASS: Config valid"
else
    echo "WARN: Config has issues (non-blocking)"
fi

# Step 4: Count skills
SKILL_COUNT=$(find "$HOME/.openclaw/workspace/skills" -name "SKILL.md" 2>/dev/null | wc -l)
echo "PASS: $SKILL_COUNT skills loaded"

# Step 5: Start gateway in foreground
echo ""
echo "Starting OpenClaw gateway on port ${OPENCLAW_PORT:-18789}..."
echo "================================"
exec openclaw gateway run --port "${OPENCLAW_PORT:-18789}" --verbose --allow-unconfigured
