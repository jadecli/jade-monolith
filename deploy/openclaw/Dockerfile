FROM node:22-slim

LABEL maintainer="jadecli" \
      description="OpenClaw bot with 100-agent swarm skills"

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    ca-certificates \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Install OpenClaw
RUN npm install -g openclaw@2026.2.6

# Create non-root user
RUN groupadd -r openclaw && useradd -r -g openclaw -m -s /bin/bash openclaw

# Create directories with correct permissions
RUN mkdir -p /home/openclaw/.openclaw/workspace/skills \
             /home/openclaw/.openclaw/agents/main/agent \
             /home/openclaw/.openclaw/agents/main/sessions \
             /home/openclaw/.openclaw/credentials \
             /home/openclaw/.openclaw/workspace/memory \
    && chown -R openclaw:openclaw /home/openclaw/.openclaw \
    && chmod 700 /home/openclaw/.openclaw

# Copy config
COPY --chown=openclaw:openclaw openclaw.json /home/openclaw/.openclaw/openclaw.json
RUN chmod 600 /home/openclaw/.openclaw/openclaw.json

# Copy swarm skills
COPY --chown=openclaw:openclaw skills/ /home/openclaw/.openclaw/workspace/skills/

# Copy boot script
COPY --chown=openclaw:openclaw boot.sh /home/openclaw/boot.sh
RUN chmod +x /home/openclaw/boot.sh

USER openclaw
WORKDIR /home/openclaw

EXPOSE 18789

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s \
    CMD curl -sf http://127.0.0.1:18789/health || exit 1

ENTRYPOINT ["/home/openclaw/boot.sh"]
