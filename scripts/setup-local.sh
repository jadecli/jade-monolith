#!/usr/bin/env bash
# setup-local.sh — Bootstrap local development environment for jadecli ecosystem
# Installs and configures: Claude Code, Gemini CLI, Codex CLI, Docker, VS Code extensions
# Based on Anthropic engineering best practices and agent teams patterns
#
# Usage:
#   ./scripts/setup-local.sh              # Full install
#   ./scripts/setup-local.sh --check      # Check what's installed
#   ./scripts/setup-local.sh --dry-run    # Preview without installing

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DRY_RUN=false
CHECK_ONLY=false

for arg in "$@"; do
  case "$arg" in
    --dry-run)  DRY_RUN=true ;;
    --check)    CHECK_ONLY=true ;;
    -h|--help)
      echo "Usage: $0 [--check|--dry-run]"
      echo "  --check    Check what's already installed"
      echo "  --dry-run  Preview actions without executing"
      exit 0
      ;;
  esac
done

ok()   { echo -e "  ${GREEN}[OK]${NC}   $1"; }
warn() { echo -e "  ${YELLOW}[MISS]${NC} $1"; }
info() { echo -e "  ${BLUE}[INFO]${NC} $1"; }
step() { echo -e "\n${BLUE}==>${NC} $1"; }

# ─── Check prerequisites ──────────────────────────────────────────────────────

check_command() {
  local cmd="$1"
  local label="${2:-$1}"
  if command -v "$cmd" &>/dev/null; then
    local ver
    ver=$("$cmd" --version 2>/dev/null | head -1 || echo "installed")
    ok "$label: $ver"
    return 0
  else
    warn "$label: not found"
    return 1
  fi
}

step "Checking system prerequisites"

OS="$(uname -s)"
ARCH="$(uname -m)"
info "Platform: $OS / $ARCH"

# Detect package manager
if [[ "$OS" == "Darwin" ]]; then
  if ! command -v brew &>/dev/null; then
    warn "Homebrew not found"
    if [[ "$CHECK_ONLY" == false && "$DRY_RUN" == false ]]; then
      info "Installing Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
  else
    ok "Homebrew: $(brew --version | head -1)"
  fi
fi

# ─── Node.js (required by Gemini CLI, Codex CLI) ──────────────────────────────

step "Checking Node.js"

if command -v node &>/dev/null; then
  NODE_VER=$(node --version)
  NODE_MAJOR=$(echo "$NODE_VER" | sed 's/^v//' | cut -d. -f1)
  if [[ "$NODE_MAJOR" -ge 20 ]]; then
    ok "Node.js: $NODE_VER (>= 20 required)"
  else
    warn "Node.js $NODE_VER is too old (>= 20 required)"
    if [[ "$CHECK_ONLY" == false && "$DRY_RUN" == false && "$OS" == "Darwin" ]]; then
      info "Installing Node.js 22 LTS via Homebrew..."
      brew install node@22
    fi
  fi
else
  warn "Node.js: not found"
  if [[ "$CHECK_ONLY" == false && "$DRY_RUN" == false && "$OS" == "Darwin" ]]; then
    info "Installing Node.js 22 LTS via Homebrew..."
    brew install node@22
  fi
fi

# ─── Claude Code CLI ──────────────────────────────────────────────────────────

step "Checking Claude Code CLI"

if check_command claude "Claude Code"; then
  : # already installed
elif [[ "$CHECK_ONLY" == false ]]; then
  if [[ "$DRY_RUN" == true ]]; then
    info "[DRY RUN] Would install Claude Code via: curl -fsSL https://claude.ai/install.sh | bash"
  else
    info "Installing Claude Code..."
    curl -fsSL https://claude.ai/install.sh | bash
  fi
fi

# ─── Gemini CLI ────────────────────────────────────────────────────────────────

step "Checking Gemini CLI"

if check_command gemini "Gemini CLI"; then
  : # already installed
elif [[ "$CHECK_ONLY" == false ]]; then
  if [[ "$DRY_RUN" == true ]]; then
    info "[DRY RUN] Would install: npm install -g @google/gemini-cli"
  else
    info "Installing Gemini CLI..."
    npm install -g @google/gemini-cli
  fi
fi

# ─── Codex CLI (OpenAI) ───────────────────────────────────────────────────────

step "Checking Codex CLI"

if check_command codex "Codex CLI"; then
  : # already installed
elif [[ "$CHECK_ONLY" == false ]]; then
  if [[ "$DRY_RUN" == true ]]; then
    info "[DRY RUN] Would install: npm install -g @openai/codex"
  else
    info "Installing Codex CLI..."
    npm install -g @openai/codex
  fi
fi

# ─── Docker ────────────────────────────────────────────────────────────────────

step "Checking Docker"

if check_command docker "Docker CLI"; then
  # Check if daemon is running
  if docker info &>/dev/null 2>&1; then
    ok "Docker daemon: running"
  else
    warn "Docker daemon: not running"
  fi
else
  if [[ "$CHECK_ONLY" == false && "$OS" == "Darwin" ]]; then
    if [[ "$DRY_RUN" == true ]]; then
      info "[DRY RUN] Would install Docker via: brew install --cask orbstack"
    else
      info "Installing OrbStack (lightweight Docker for macOS)..."
      brew install --cask orbstack
    fi
  fi
fi

check_command docker-compose "Docker Compose"

# ─── Git ───────────────────────────────────────────────────────────────────────

step "Checking Git"

check_command git "Git"
check_command gh "GitHub CLI"

# ─── VS Code Extensions ───────────────────────────────────────────────────────

step "Checking VS Code"

if check_command code "VS Code CLI"; then
  VSCODE_EXTENSIONS=(
    "anthropic.claude-code"
    "eamodio.gitlens"
    "usernamehw.errorlens"
    "ms-azuretools.vscode-docker"
    "dbaeumer.vscode-eslint"
    "esbenp.prettier-vscode"
  )

  INSTALLED_EXTS=$(code --list-extensions 2>/dev/null || echo "")

  for ext in "${VSCODE_EXTENSIONS[@]}"; do
    if echo "$INSTALLED_EXTS" | grep -qi "$ext"; then
      ok "VS Code ext: $ext"
    else
      warn "VS Code ext: $ext"
      if [[ "$CHECK_ONLY" == false ]]; then
        if [[ "$DRY_RUN" == true ]]; then
          info "[DRY RUN] Would install: code --install-extension $ext"
        else
          code --install-extension "$ext" --force 2>/dev/null || warn "Failed to install $ext"
        fi
      fi
    fi
  done
else
  warn "VS Code CLI not found (install VS Code and enable shell command)"
fi

# ─── Claude Code configuration ────────────────────────────────────────────────

step "Checking Claude Code configuration"

CLAUDE_SETTINGS="$HOME/.claude/settings.json"
if [[ -f "$CLAUDE_SETTINGS" ]]; then
  ok "Claude settings: $CLAUDE_SETTINGS exists"
else
  if [[ "$CHECK_ONLY" == false ]]; then
    if [[ "$DRY_RUN" == true ]]; then
      info "[DRY RUN] Would create $CLAUDE_SETTINGS with agent teams config"
    else
      mkdir -p "$HOME/.claude"
      cat > "$CLAUDE_SETTINGS" << 'SETTINGS'
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  },
  "permissions": {
    "allow": ["Read", "Glob", "Grep", "WebSearch", "WebFetch"],
    "deny": []
  }
}
SETTINGS
      ok "Created $CLAUDE_SETTINGS with agent teams enabled"
    fi
  fi
fi

# ─── Gemini configuration ─────────────────────────────────────────────────────

step "Checking Gemini configuration"

GEMINI_DIR="$HOME/.gemini"
if [[ -d "$GEMINI_DIR" ]]; then
  ok "Gemini config dir: $GEMINI_DIR exists"
else
  if [[ "$CHECK_ONLY" == false ]]; then
    if [[ "$DRY_RUN" == true ]]; then
      info "[DRY RUN] Would create $GEMINI_DIR"
    else
      mkdir -p "$GEMINI_DIR"
      ok "Created $GEMINI_DIR"
    fi
  fi
fi

# ─── API Keys check ───────────────────────────────────────────────────────────

step "Checking API keys (environment variables)"

check_env() {
  local var="$1"
  if [[ -n "${!var:-}" ]]; then
    ok "$var: set (${#!var} chars)"
  else
    warn "$var: not set"
  fi
}

check_env ANTHROPIC_API_KEY
check_env GEMINI_API_KEY
check_env OPENAI_API_KEY

# ─── Submodules ────────────────────────────────────────────────────────────────

step "Checking jade-monolith submodules"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MONOLITH_ROOT="$(dirname "$SCRIPT_DIR")"

if [[ -f "$MONOLITH_ROOT/.gitmodules" ]]; then
  TOTAL=$(grep -c '\[submodule' "$MONOLITH_ROOT/.gitmodules" 2>/dev/null || echo 0)
  INITIALIZED=$(git -C "$MONOLITH_ROOT" submodule status 2>/dev/null | grep -cv '^-' || echo 0)
  if [[ "$INITIALIZED" -eq "$TOTAL" ]]; then
    ok "Submodules: $INITIALIZED/$TOTAL initialized"
  else
    warn "Submodules: $INITIALIZED/$TOTAL initialized"
    if [[ "$CHECK_ONLY" == false ]]; then
      if [[ "$DRY_RUN" == true ]]; then
        info "[DRY RUN] Would run: git submodule update --init --recursive"
      else
        info "Initializing submodules..."
        git -C "$MONOLITH_ROOT" submodule update --init --recursive
      fi
    fi
  fi
else
  warn "Not inside jade-monolith (no .gitmodules found)"
fi

# ─── macOS optimizations ──────────────────────────────────────────────────────

if [[ "$OS" == "Darwin" ]]; then
  step "macOS optimizations"

  # Check Spotlight exclusion for dev dirs
  info "Tip: Exclude dev directories from Spotlight to reduce CPU usage:"
  info "  sudo mdutil -i off ~/projects"
  info "  Or: System Settings > Siri & Spotlight > Spotlight Privacy > add folders"

  # Check file descriptor limits
  CURRENT_LIMIT=$(ulimit -n 2>/dev/null || echo "unknown")
  if [[ "$CURRENT_LIMIT" != "unknown" && "$CURRENT_LIMIT" -lt 10240 ]]; then
    warn "File descriptor limit: $CURRENT_LIMIT (recommend >= 10240)"
    info "Add to ~/.zshrc: ulimit -n 10240"
  else
    ok "File descriptor limit: $CURRENT_LIMIT"
  fi
fi

# ─── Summary ───────────────────────────────────────────────────────────────────

step "Setup complete"
echo ""
echo "Next steps:"
echo "  1. Set API keys in ~/.zshrc:"
echo "     export ANTHROPIC_API_KEY=\"sk-ant-...\""
echo "     export GEMINI_API_KEY=\"...\""
echo "     export OPENAI_API_KEY=\"sk-...\""
echo ""
echo "  2. Authenticate CLIs:"
echo "     claude auth login"
echo "     gemini              # triggers OAuth"
echo "     codex               # sign in with ChatGPT"
echo ""
echo "  3. Run health check:"
echo "     ./scripts/health-check.sh"
echo ""
echo "  4. Start agent teams:"
echo "     ./scripts/start-team.sh"
echo ""
