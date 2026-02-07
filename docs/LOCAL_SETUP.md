# Local Development Setup — 2026 Optimized

Bootstrap guide for the jadecli ecosystem, optimized for AI-assisted development with Claude Code agent teams, Gemini CLI, Codex CLI, Cursor IDE, and VS Code.

## Quick Start

```bash
# Clone with all 14 submodules
git clone --recurse-submodules git@github.com:jadecli/jade-monolith.git
cd jade-monolith

# Run the bootstrap script
./scripts/setup-local.sh          # Full install
./scripts/setup-local.sh --check  # Audit what's installed
./scripts/setup-local.sh --dry-run # Preview without installing
```

## What Gets Installed

| Tool | Install Method | Purpose |
|---|---|---|
| Claude Code CLI | Native binary | Primary AI agent, agent teams |
| Gemini CLI | npm | Google AI agent, GCP integration |
| Codex CLI | npm | OpenAI agent |
| Docker (OrbStack) | brew cask | Container runtime for agent isolation |
| VS Code extensions | code CLI | IDE integration |

## CLI Tools

### Claude Code CLI

```bash
curl -fsSL https://claude.ai/install.sh | bash
claude auth login
claude doctor   # verify installation
```

**Agent teams** (parallel Claude instances on shared codebase):

```bash
claude config set env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS 1
```

Or add to `~/.claude/settings.json`:

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

Key insight from [Anthropic's C compiler project](https://www.anthropic.com/engineering/building-c-compiler): 16 parallel agents produced 100K lines of Rust across 2,000 sessions. The critical success factor was test harness quality, not prompt engineering.

**Agent teams best practices:**
- Each agent should own different files to avoid merge conflicts
- Use file-based locks (`current_tasks/`) to prevent duplicate work
- Maintain progress docs that agents update frequently
- Use deterministic test subsampling per-agent, random across VMs
- Start read-only (code review) before letting agents write code
- Run agents in containers, never with `--dangerously-skip-permissions` on host

### Gemini CLI

```bash
npm install -g @google/gemini-cli
gemini          # OAuth login on first run
```

Configuration:
- Project context: create `GEMINI.md` in project root (run `gemini /init`)
- Global config: `~/.gemini/settings.json`
- API key: `export GEMINI_API_KEY="..."` or `~/.gemini/.env`
- Free tier: 60 req/min, 1000 req/day with Google account

### Codex CLI (OpenAI)

```bash
npm install -g @openai/codex
codex           # sign in with ChatGPT account
```

### Docker

**Recommended: OrbStack** (lightweight, fast on macOS):
```bash
brew install --cask orbstack
```

**Alternative: Colima** (CLI-first, no GUI):
```bash
brew install colima docker docker-compose
colima start --cpu 4 --memory 8 --disk 60 \
  --vm-type vz --vz-rosetta --mount-type virtiofs
```

**For agent teams containers** (per the C compiler pattern):
```bash
git init --bare /tmp/upstream.git
docker run -d --name agent-1 \
  -v /tmp/upstream.git:/upstream:ro \
  -w /workspace your-dev-image
```

## IDE Configuration

### VS Code

**Extensions** (installed by `setup-local.sh`):
- `anthropic.claude-code` — Claude Code integration
- `eamodio.gitlens` — Git blame/history inline
- `usernamehw.errorlens` — Inline error display
- `ms-azuretools.vscode-docker` — Container management
- `dbaeumer.vscode-eslint` — Linting
- `esbenp.prettier-vscode` — Formatting

**Recommended settings** (`settings.json`):

```json
{
  "editor.inlineSuggest.enabled": true,
  "editor.formatOnSave": true,
  "editor.bracketPairColorization.enabled": true,
  "terminal.integrated.scrollback": 10000,
  "files.autoSave": "afterDelay",
  "files.autoSaveDelay": 1000,
  "security.workspace.trust.enabled": true
}
```

### Cursor IDE

Download from [cursor.com](https://cursor.com).

**Project rules** — create `.cursor/rules/` with modular `.mdc` files:

```
.cursor/rules/
├── general.mdc      # Universal coding standards
├── monolith.mdc     # Package isolation rules
├── testing.mdc      # Test conventions
└── agents.mdc       # AI agent interaction patterns
```

**Key settings:**
- Enable **Plan Mode** — research/clarify/plan before coding
- Disable **Auto Run Mode** — review commands before execution
- Enable **Privacy Mode** for sensitive projects
- Configure MCP servers for external tool access

## Environment Variables

Add to `~/.zshrc`:

```bash
# AI CLI API keys
export ANTHROPIC_API_KEY="sk-ant-..."
export GEMINI_API_KEY="..."
export OPENAI_API_KEY="sk-..."

# Claude Code agent teams
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1

# Docker (if using Colima instead of OrbStack)
# export DOCKER_HOST="unix://${HOME}/.colima/default/docker.sock"

# Path
export PATH="$HOME/.claude/bin:$HOME/.local/bin:$PATH"
```

## macOS Optimization

### Spotlight

Exclude dev directories from Spotlight indexing:

```bash
sudo mdutil -i off ~/projects
```

Or: System Settings > Siri & Spotlight > Spotlight Privacy > add folders.

### File Descriptors

```bash
# Add to ~/.zshrc
ulimit -n 10240
```

### Multi-CLI Workflow Strategy

| Task | Best Tool |
|---|---|
| Complex refactoring, agent teams | Claude Code (Opus 4.6) |
| Quick inline completion | Cursor |
| Google Cloud / Firebase work | Gemini CLI |
| OpenAI ecosystem, ChatGPT integration | Codex CLI |
| Code review, plan mode | Claude Code in VS Code |

## Verification

After setup, verify everything works:

```bash
# Check all tools
./scripts/setup-local.sh --check

# Check ecosystem health
./scripts/health-check.sh

# Check all 14 repos
./scripts/git-status-all.sh
```

## References

- [Claude Code Docs](https://code.claude.com/docs/en/setup)
- [Agent Teams Guide](https://code.claude.com/docs/en/agent-teams)
- [Building a C Compiler with Agent Teams](https://www.anthropic.com/engineering/building-c-compiler)
- [Gemini CLI Docs](https://geminicli.com/docs/get-started/)
- [Codex CLI Docs](https://developers.openai.com/codex/cli/)
- [Cursor Best Practices](https://github.com/digitalchild/cursor-best-practices)
