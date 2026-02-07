# OpenClaw Swarm Bot Deployment Guide

Deploy an OpenClaw bot with the 100-agent swarm system. Each step below has been validated on Ubuntu Linux with Node 22.

## Prerequisites

| Requirement | Minimum | Verified |
|-------------|---------|----------|
| Node.js | 22+ | `node --version` |
| npm | 10+ | `npm --version` |
| RAM | 2 GB | `free -h` |
| Disk | 5 GB | `df -h` |
| Anthropic API key | Required | `console.anthropic.com` |

## Step 1: Install OpenClaw

```bash
npm install -g openclaw@latest
openclaw --version  # Should show 2026.2.x
```

**Validation**: `openclaw --version` prints a version number.

## Step 2: Initialize Config

```bash
# Create workspace directories
mkdir -p ~/.openclaw/workspace/skills
mkdir -p ~/.openclaw/agents/main/agent
mkdir -p ~/.openclaw/agents/main/sessions
mkdir -p ~/.openclaw/credentials
mkdir -p ~/.openclaw/workspace/memory

# Fix permissions
chmod 700 ~/.openclaw
```

Run the doctor to auto-generate config:
```bash
openclaw doctor --fix
```

**Validation**: `openclaw doctor` shows no "Config invalid" errors.

## Step 3: Set Gateway Mode

```bash
openclaw config set gateway.mode local
openclaw config set gateway.port 18789
openclaw config set gateway.auth.mode password
openclaw config set gateway.auth.password "YOUR-STRONG-PASSWORD"
```

**Validation**: `openclaw config get gateway` shows your settings.

## Step 4: Configure Anthropic API Key

Set via environment variable (recommended):
```bash
export ANTHROPIC_API_KEY="sk-ant-your-key-here"
```

**Validation**: `ANTHROPIC_API_KEY=your-key openclaw models` shows:
```
- anthropic effective=env:sk-ant-...
```

## Step 5: Install Swarm Skills

Copy the 6 swarm skills to the OpenClaw workspace:

```bash
# From this repository
cp -r skills/* ~/.openclaw/workspace/skills/
```

Skills installed:
| Skill | Purpose |
|-------|---------|
| `/swarm` | Full 100-agent orchestration |
| `/swarm-research` | Multi-angle parallel research |
| `/swarm-develop` | TDD development workflow |
| `/swarm-review` | Multi-perspective code review |
| `/swarm-debug` | Competing-hypothesis debugging |
| `/swarm-status` | Display swarm roster |

**Validation**: `openclaw doctor` shows `Eligible: 13+` under Skills status.

## Step 6: Start the Gateway

### Option A: Foreground (testing)
```bash
ANTHROPIC_API_KEY="your-key" openclaw gateway run --port 18789 --verbose
```

### Option B: Docker (production)
```bash
cp .env.example .env
# Edit .env with your ANTHROPIC_API_KEY

docker compose up -d
docker compose logs -f
```

### Option C: systemd (Linux production)
```bash
openclaw gateway install
openclaw gateway start
openclaw gateway status
```

**Validation**:
```bash
openclaw gateway health    # Should show "OK"
openclaw gateway probe     # Should show "Reachable: yes"
curl http://127.0.0.1:18789/health  # Should return the Control UI HTML
```

## Step 7: Configure Channels (Optional)

### WebChat (built-in)
Open `http://127.0.0.1:18789` in a browser. The OpenClaw Control UI is served automatically.

### Telegram
```bash
openclaw config set channels.telegram.botToken "YOUR_BOT_TOKEN"
openclaw gateway restart
```

### Discord
```bash
openclaw config set channels.discord.botToken "YOUR_BOT_TOKEN"
openclaw gateway restart
```

### WhatsApp
```bash
openclaw channels login --channel whatsapp
# Scan QR code with WhatsApp Business app
```

## Step 8: Verify End-to-End

Send a test message through any configured channel:
```
/status          # Check model and token usage
/swarm-status    # Should display the 100-agent roster
```

## Security Hardening

1. **Bind to loopback only**: Gateway defaults to `127.0.0.1` (not exposed to network)
2. **Use password auth**: Set a strong password in `gateway.auth.password`
3. **Restrict permissions**: `chmod 700 ~/.openclaw && chmod 600 ~/.openclaw/openclaw.json`
4. **Use Tailscale** for remote access instead of exposing port publicly
5. **Run as non-root**: Use the Docker image which runs as `openclaw` user
6. **Disable ClawHub**: Set `clawhub.enabled: false` to prevent automatic skill installation
7. **Audit regularly**: Run `openclaw security audit --deep`

## Docker Quick Start

```bash
cd deploy/openclaw

# Create .env from example
cp .env.example .env
nano .env  # Set ANTHROPIC_API_KEY

# Build and run
docker compose up -d

# Check health
docker compose exec openclaw-swarm openclaw gateway health

# View logs
docker compose logs -f

# Stop
docker compose down
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "Missing env var ANTHROPIC_API_KEY" | Set `export ANTHROPIC_API_KEY=...` |
| "gateway already running" | `pkill -f openclaw-gateway` or `openclaw gateway stop` |
| "Port 18789 in use" | Kill existing process: `fuser -k 18789/tcp` |
| Skills not loading | Check `~/.openclaw/workspace/skills/*/SKILL.md` exist |
| "Config invalid" | Run `openclaw doctor --fix` |
| "systemd unavailable" | Use `openclaw gateway run` (foreground) in containers |

## File Structure

```
deploy/openclaw/
├── Dockerfile           # Production Docker image
├── docker-compose.yml   # Docker Compose orchestration
├── openclaw.json        # Base config (copied to container)
├── boot.sh              # Container entrypoint script
├── .env.example         # Environment variable template
├── DEPLOY.md            # This guide
└── skills/              # Swarm skills
    ├── swarm/SKILL.md
    ├── swarm-research/SKILL.md
    ├── swarm-develop/SKILL.md
    ├── swarm-review/SKILL.md
    ├── swarm-debug/SKILL.md
    └── swarm-status/SKILL.md
```
