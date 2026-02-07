# jadebot-v107 Deployment Plan

**Docker-based OpenClaw bot with Ollama (qwen3:8b) + Claude orchestrated swarm**

Target hardware: AMD Ryzen 9 3900X, 128GB RAM, RTX 2080 Ti 11GB, WSL2 Ubuntu

---

## Architecture Overview

```
                          +-----------------------+
                          |   Slack / iMessage     |
                          +-----------+-----------+
                                      |
                          +-----------v-----------+
                          |   OpenClaw Gateway     |
                          |   (port 18789)         |
                          |   + Agent Runtime      |
                          +-----------+-----------+
                                      |
                     +----------------+----------------+
                     |                                 |
           +---------v---------+             +---------v---------+
           |  Ollama (primary)  |             | Anthropic (cloud)  |
           |  qwen3:8b Q4_K_M  |             | claude-sonnet-4-5  |
           |  port 11434        |             | (fallback/override)|
           +--------------------+             +--------------------+
                     |
           +---------v---------+
           |  RTX 2080 Ti 11GB  |
           |  ~15-25 tok/s      |
           +--------------------+
```

## Deployment Stack (Docker Compose)

| Service         | Image                          | Port  | Purpose                       |
|-----------------|--------------------------------|-------|-------------------------------|
| ollama          | ollama/ollama:latest           | 11434 | Local LLM inference (GPU)     |
| openclaw        | openclaw-gateway (built)       | 18789 | Bot gateway + agent runtime   |
| openclaw-cli    | same image                     | -     | One-shot CLI commands         |

---

## Step-by-Step Deployment

### Phase 0: Prerequisites Validation

```bash
# Step 0.1 — Verify Docker is running
docker info > /dev/null 2>&1
# VALIDATE: exit code 0

# Step 0.2 — Verify Docker Compose v2
docker compose version
# VALIDATE: output shows "Docker Compose version v2.x.x" or higher

# Step 0.3 — Verify Node.js 22+
node --version
# VALIDATE: output starts with "v22."

# Step 0.4 — Verify GPU passthrough (WSL2)
nvidia-smi
# VALIDATE: shows RTX 2080 Ti, 11GB VRAM
# NOTE: If this fails, NVIDIA Container Toolkit must be installed first.
#   See: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html
#   On WSL2: the Windows NVIDIA driver handles GPU passthrough.
#   Install the toolkit in WSL2:
#     distribution=$(. /etc/os-release; echo $ID$VERSION_ID)
#     curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
#     curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
#       sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
#       sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
#     sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
#     sudo nvidia-ctk runtime configure --runtime=docker
#     sudo systemctl restart docker

# Step 0.5 — Verify Docker can see the GPU
docker run --rm --gpus all nvidia/cuda:12.2.0-base-ubuntu22.04 nvidia-smi
# VALIDATE: Same GPU info as host nvidia-smi
```

**Checkpoint 0: All 5 checks pass before proceeding.**

---

### Phase 1: Install Ollama (Docker)

```bash
# Step 1.1 — Pull the Ollama Docker image
docker pull ollama/ollama:latest
# VALIDATE: pull completes without error

# Step 1.2 — Create a persistent volume for models
docker volume create ollama_models
# VALIDATE: "ollama_models" appears in `docker volume ls`

# Step 1.3 — Start Ollama with GPU access
docker run -d \
  --name ollama-test \
  --gpus all \
  -p 11434:11434 \
  -v ollama_models:/root/.ollama \
  ollama/ollama:latest
# VALIDATE: container starts, `docker logs ollama-test` shows no errors

# Step 1.4 — Pull the qwen3:8b model
docker exec ollama-test ollama pull qwen3:8b
# VALIDATE: model download completes (~4.9GB for Q4_K_M)
# NOTE: This takes 5-15 minutes depending on network speed.

# Step 1.5 — Test inference
docker exec ollama-test ollama run qwen3:8b "Say hello in one sentence"
# VALIDATE: model responds coherently, no CUDA errors

# Step 1.6 — Test the HTTP API (Anthropic-compatible)
curl -s http://localhost:11434/api/generate \
  -d '{"model":"qwen3:8b","prompt":"Hello","stream":false}' | head -c 200
# VALIDATE: JSON response with "response" field containing text

# Step 1.7 — Test Anthropic Messages API compatibility (Ollama v0.14+)
curl -s http://localhost:11434/v1/messages \
  -H "Content-Type: application/json" \
  -H "x-api-key: ollama" \
  -d '{
    "model": "qwen3:8b",
    "max_tokens": 100,
    "messages": [{"role": "user", "content": "Say hello"}]
  }' | head -c 300
# VALIDATE: JSON response with "content" array containing text block
# NOTE: If this 404s, your Ollama version is < 0.14. Update with:
#   docker pull ollama/ollama:latest && restart the container.

# Step 1.8 — Clean up test container (will be replaced by compose)
docker stop ollama-test && docker rm ollama-test
# VALIDATE: container removed
```

**Checkpoint 1: Ollama serves qwen3:8b on GPU via HTTP API.**

---

### Phase 2: Install OpenClaw

```bash
# Step 2.1 — Install OpenClaw CLI
curl -fsSL https://openclaw.ai/install.sh | bash
# VALIDATE: `openclaw --version` outputs a version string

# Step 2.2 — Verify the binary is in PATH
which openclaw
# VALIDATE: path is returned (typically ~/.local/bin/openclaw or similar)
# If not found, add to PATH:
#   echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc
```

**Checkpoint 2: `openclaw --version` succeeds.**

---

### Phase 3: Create Docker Compose Stack

Create the file at `packages/jade-docker/jadebot-v107/docker-compose.yml`:

```yaml
# docker-compose.yml — jadebot-v107
# OpenClaw gateway + Ollama (qwen3:8b on RTX 2080 Ti)

services:
  ollama:
    image: ollama/ollama:latest
    container_name: jadebot-ollama
    restart: unless-stopped
    ports:
      - "11434:11434"
    volumes:
      - ollama_models:/root/.ollama
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:11434/api/tags"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s

  openclaw-gateway:
    image: openclaw:local
    build:
      context: .
      dockerfile: Dockerfile.openclaw
    container_name: jadebot-gateway
    restart: unless-stopped
    ports:
      - "18789:18789"
    volumes:
      - openclaw_config:/home/node/.openclaw
      - openclaw_workspace:/home/node/.openclaw/workspace
    environment:
      - OPENCLAW_GATEWAY_TOKEN=${OPENCLAW_GATEWAY_TOKEN:-}
    depends_on:
      ollama:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "node", "dist/index.js", "health", "--token", "${OPENCLAW_GATEWAY_TOKEN:-}"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - jadebot

  openclaw-cli:
    image: openclaw:local
    container_name: jadebot-cli
    profiles: ["cli"]
    volumes:
      - openclaw_config:/home/node/.openclaw
      - openclaw_workspace:/home/node/.openclaw/workspace
    networks:
      - jadebot
    entrypoint: ["openclaw"]

volumes:
  ollama_models:
    name: jadebot_ollama_models
  openclaw_config:
    name: jadebot_openclaw_config
  openclaw_workspace:
    name: jadebot_openclaw_workspace

networks:
  jadebot:
    name: jadebot-net
```

```bash
# Step 3.1 — Create the project directory
mkdir -p packages/jade-docker/jadebot-v107

# Step 3.2 — Write docker-compose.yml (content above)
# VALIDATE: `docker compose -f packages/jade-docker/jadebot-v107/docker-compose.yml config`
#   outputs valid YAML without errors

# Step 3.3 — Start Ollama first (it needs to pull the model)
docker compose -f packages/jade-docker/jadebot-v107/docker-compose.yml up -d ollama
# VALIDATE: `docker compose ps` shows ollama as "healthy"

# Step 3.4 — Pull qwen3:8b inside the compose ollama container
docker exec jadebot-ollama ollama pull qwen3:8b
# VALIDATE: model present in `docker exec jadebot-ollama ollama list`

# Step 3.5 — Verify Ollama API from host
curl -s http://localhost:11434/api/tags | python3 -m json.tool
# VALIDATE: JSON output includes "qwen3:8b" in models list
```

**Checkpoint 3: Ollama running in compose with qwen3:8b loaded.**

---

### Phase 4: Configure OpenClaw Gateway

#### 4A: Run the Onboarding Wizard

```bash
# Step 4.1 — If using Docker-based OpenClaw:
docker compose -f packages/jade-docker/jadebot-v107/docker-compose.yml \
  run --rm openclaw-cli onboard
# VALIDATE: wizard completes, creates ~/.openclaw/openclaw.json inside the volume

# Step 4.1-ALT — If using host-installed OpenClaw:
openclaw onboard
# VALIDATE: wizard completes, creates ~/.openclaw/openclaw.json
```

#### 4B: Configure the Gateway Config

Write `~/.openclaw/openclaw.json` (or mount it into the container):

```json5
{
  // === Agent Defaults ===
  agents: {
    defaults: {
      workspace: "~/.openclaw/workspace",

      // Primary: Ollama local model (zero cost, zero rate limits)
      model: {
        primary: "ollama/qwen3:8b",
        fallbacks: ["anthropic/claude-sonnet-4-5-20250929"]
      },

      // Thinking: low by default (qwen3 supports /think tags natively)
      thinkingDefault: "low",
      timeoutSeconds: 600,
      maxConcurrent: 3,

      // Context management
      contextPruning: {
        mode: "adaptive",
        softTrimRatio: 0.3,
        hardClearRatio: 0.5
      },
      compaction: {
        mode: "default",
        memoryFlush: { enabled: true, softThresholdTokens: 4000 }
      }
    }
  },

  // === Model Providers ===
  models: {
    mode: "merge",
    providers: {
      ollama: {
        baseUrl: "http://jadebot-ollama:11434/v1",
        apiKey: "ollama",
        api: "openai-completions",
        models: [{
          id: "qwen3:8b",
          contextWindow: 32768,
          maxTokens: 8192
        }]
      }
      // Anthropic is built-in; set ANTHROPIC_API_KEY env var to enable fallback
    }
  },

  // === Session Management ===
  session: {
    scope: "per-sender",
    reset: {
      mode: "daily",
      atHour: 4,
      idleMinutes: 60
    },
    resetTriggers: ["/new", "/reset"]
  },

  // === Message Handling ===
  messages: {
    responsePrefix: "[jadebot]",
    ackReaction: "eyes",
    queue: {
      mode: "collect",
      debounceMs: 1000,
      cap: 20
    }
  },

  // === Tools ===
  tools: {
    profile: "coding",
    allow: ["group:fs", "group:runtime", "group:web"],
    deny: ["browser"]
  },

  // === Channels (configure per Phase 5/6) ===
  channels: {
    slack: {
      enabled: false
    }
  },

  // === Logging ===
  logging: {
    level: "info",
    redactSensitive: "tools"
  },

  // === Gateway ===
  gateway: {
    port: 18789
  }
}
```

```bash
# Step 4.2 — Validate the config
openclaw doctor
# VALIDATE: no errors, all checks pass

# Step 4.3 — Start the gateway
docker compose -f packages/jade-docker/jadebot-v107/docker-compose.yml up -d openclaw-gateway
# VALIDATE: `docker compose ps` shows openclaw-gateway as "healthy"

# Step 4.4 — Verify gateway is reachable
curl -s http://localhost:18789/ | head -c 100
# VALIDATE: returns HTML or JSON (Control UI)

# Step 4.5 — Check gateway status
openclaw gateway status
# or: docker exec jadebot-gateway openclaw gateway status
# VALIDATE: output shows "running" / "connected"

# Step 4.6 — Test a message through the agent
openclaw message send --target "self" --message "Hello, are you working?"
# VALIDATE: response comes back from qwen3:8b (check logs)

# Step 4.7 — Verify Ollama is being used (not cloud)
docker logs jadebot-ollama --tail 20
# VALIDATE: recent inference request logs visible
```

**Checkpoint 4: Gateway running, routing messages to Ollama.**

---

### Phase 5: Connect Slack Channel

```bash
# Step 5.1 — Create a Slack App at https://api.slack.com/apps
#   - App name: "jadebot"
#   - Enable Socket Mode
#   - Create App-Level Token with connections:write scope -> save as xapp-...
#   - Add Bot Token Scopes:
#     chat:write, channels:history, groups:history, im:history,
#     mpim:history, app_mentions:read, reactions:read, reactions:write,
#     channels:read, groups:read, im:read, users:read
#   - Install to workspace -> save Bot Token as xoxb-...
#   - Subscribe to Events: message.channels, message.groups, message.im,
#     app_mention, reaction_added, reaction_removed
#   - Enable Messages Tab in App Home

# Step 5.2 — Set environment variables
export SLACK_APP_TOKEN="xapp-..."   # App-level token
export SLACK_BOT_TOKEN="xoxb-..."   # Bot User OAuth Token

# Step 5.3 — Add to .env file for Docker Compose
cat >> packages/jade-docker/jadebot-v107/.env << 'EOF'
SLACK_APP_TOKEN=xapp-your-app-token
SLACK_BOT_TOKEN=xoxb-your-bot-token
OPENCLAW_GATEWAY_TOKEN=your-gateway-token
EOF
# VALIDATE: .env file exists with 3 non-empty values
# WARNING: Never commit .env files to git!

# Step 5.4 — Update openclaw.json to enable Slack
# Add to the channels section:
#   channels: {
#     slack: {
#       enabled: true,
#       appToken: "${SLACK_APP_TOKEN}",
#       botToken: "${SLACK_BOT_TOKEN}",
#       groupPolicy: "allowlist",
#       replyToMode: "first"
#     }
#   }

# Step 5.5 — Restart the gateway to pick up channel config
docker compose -f packages/jade-docker/jadebot-v107/docker-compose.yml restart openclaw-gateway
# VALIDATE: `docker logs jadebot-gateway --tail 20` shows Slack connection established

# Step 5.6 — Invite the bot to a Slack channel
#   In Slack: /invite @jadebot
# VALIDATE: bot appears in channel member list

# Step 5.7 — Test: send a message mentioning the bot
#   In Slack: @jadebot hello
# VALIDATE: bot responds (may take 5-15 seconds for first inference)
```

**Checkpoint 5: Slack channel connected and responding.**

---

### Phase 6: Install ClawHub Skills

```bash
# Step 6.1 — Install ClawHub CLI
npm i -g clawhub
# VALIDATE: `clawhub --version` returns a version

# Step 6.2 — Install recommended skills
clawhub install steipete/gog
clawhub install datadrivenconstruction/airflow-dag
clawhub install charantejmandali18/voice-assistant
clawhub install 0xterrybit/postgres
clawhub install alirezarezvani/senior-data-engineer
# VALIDATE: each install completes without error
# VALIDATE: `ls ~/.openclaw/workspace/skills/` shows installed skills

# Step 6.3 — Restart gateway to load new skills
docker compose -f packages/jade-docker/jadebot-v107/docker-compose.yml restart openclaw-gateway
# VALIDATE: `docker logs jadebot-gateway` mentions loading skills

# Step 6.4 — Test a skill via Slack
#   In Slack: @jadebot /skills
# VALIDATE: bot lists available skills including the installed ones
```

**Checkpoint 6: Skills installed and loaded.**

---

### Phase 7: Enable Claude Code Agent Teams Integration

This is already configured in the monolith's `.claude/settings.json`:

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

For orchestrating Claude Code sessions that coordinate with jadebot:

```bash
# Step 7.1 — Verify agent teams is enabled
grep CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS /home/user/jade-monolith/.claude/settings.json
# VALIDATE: value is "1"

# Step 7.2 — Set LLM_MODEL override for cloud-quality tasks
export LLM_MODEL=anthropic/claude-sonnet-4-5-20250929
# NOTE: This only affects CrewAI/litellm routing, not the default Ollama path.
# For day-to-day use, qwen3:8b handles it locally.

# Step 7.3 — Verify Claude Code can reach Ollama for local inference
export ANTHROPIC_AUTH_TOKEN=ollama
export ANTHROPIC_BASE_URL=http://localhost:11434
claude --model qwen3:8b --print "Say hello"
# VALIDATE: response returned from local model
# NOTE: Reset env vars after testing:
#   unset ANTHROPIC_AUTH_TOKEN ANTHROPIC_BASE_URL
```

**Checkpoint 7: Agent teams enabled, Claude Code can use Ollama.**

---

### Phase 8: Production Hardening

```bash
# Step 8.1 — Install gateway as systemd service (runs on boot)
openclaw gateway install
# or for Docker-only:
#   docker compose -f packages/jade-docker/jadebot-v107/docker-compose.yml up -d
#   Ensure restart: unless-stopped is in compose (already set above).
# VALIDATE: `systemctl --user status openclaw-gateway` shows active/running

# Step 8.2 — Enable systemd lingering (survives logout)
sudo loginctl enable-linger $(whoami)
# VALIDATE: `loginctl show-user $(whoami) -p Linger` outputs "Linger=yes"

# Step 8.3 — Configure log rotation
# Docker handles this via its logging driver. Verify:
docker info --format '{{.LoggingDriver}}'
# VALIDATE: "json-file" (default, has built-in rotation)

# Step 8.4 — Set up Ollama model auto-pull on container start (optional)
# Add to docker-compose.yml ollama service:
#   command: >
#     bash -c "ollama serve &
#     sleep 5 &&
#     ollama pull qwen3:8b &&
#     wait"
# This ensures the model is always available after container recreation.

# Step 8.5 — Final health check
curl -sf http://localhost:11434/api/tags > /dev/null && echo "Ollama: OK" || echo "Ollama: FAIL"
curl -sf http://localhost:18789/ > /dev/null && echo "Gateway: OK" || echo "Gateway: FAIL"
openclaw gateway status && echo "OpenClaw: OK" || echo "OpenClaw: FAIL"
# VALIDATE: all three show OK
```

**Checkpoint 8: Production-ready, auto-restarts on boot.**

---

## Quick Reference

### Start/Stop
```bash
# Start everything
docker compose -f packages/jade-docker/jadebot-v107/docker-compose.yml up -d

# Stop everything
docker compose -f packages/jade-docker/jadebot-v107/docker-compose.yml down

# View logs
docker compose -f packages/jade-docker/jadebot-v107/docker-compose.yml logs -f
```

### Switch to Cloud Model
```bash
export LLM_MODEL=anthropic/claude-sonnet-4-5-20250929
# Then restart gateway to pick up the change, or use the config RPC:
openclaw gateway call config.patch --params '{
  "raw": "{ agents: { defaults: { model: { primary: \"anthropic/claude-sonnet-4-5-20250929\" } } } }"
}'
```

### Switch Back to Local
```bash
unset LLM_MODEL
openclaw gateway call config.patch --params '{
  "raw": "{ agents: { defaults: { model: { primary: \"ollama/qwen3:8b\" } } } }"
}'
```

### Monitor Ollama Performance
```bash
# Check GPU utilization during inference
nvidia-smi -l 1

# Check Ollama model list
docker exec jadebot-ollama ollama list

# Check Ollama logs
docker logs jadebot-ollama --tail 50 -f
```

## Failure Modes & Recovery

| Symptom | Cause | Fix |
|---------|-------|-----|
| Bot doesn't respond | Ollama container down | `docker compose up -d ollama` |
| Slow responses (>30s) | Model not on GPU | Check `nvidia-smi` during inference; re-pull model |
| "model not found" | qwen3:8b not pulled | `docker exec jadebot-ollama ollama pull qwen3:8b` |
| Slack disconnects | App token expired | Regenerate at api.slack.com, update .env, restart |
| Gateway crash loop | Bad config | `openclaw doctor --fix`, check `docker logs jadebot-gateway` |
| Out of VRAM | Other GPU processes | `nvidia-smi` to find offenders; kill or reduce batch size |
| Cloud fallback fires | Ollama unreachable | Check Docker network: `docker exec jadebot-gateway curl http://jadebot-ollama:11434/api/tags` |
