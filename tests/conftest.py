"""Shared fixtures for Agent Teams integration tests."""

from __future__ import annotations

import subprocess
from pathlib import Path

import pytest
import yaml

REPO_ROOT = Path(__file__).resolve().parent.parent
AGENTS_DIR = REPO_ROOT / ".claude" / "agents"
SETTINGS_PATH = REPO_ROOT / ".claude" / "settings.json"

# --------------------------------------------------------------------------- #
# Claude Code known tool/model/mode contracts (update when Claude Code ships  #
# breaking changes — the compat tests will catch drift automatically).        #
# --------------------------------------------------------------------------- #

KNOWN_TOOLS: set[str] = {
    # Core read
    "Read", "Glob", "Grep",
    # Core write
    "Write", "Edit", "NotebookEdit",
    # Execution
    "Bash",
    # Web
    "WebSearch", "WebFetch",
    # Task / subagent
    "Task",
    # Agent Teams task management
    "TaskCreate", "TaskList", "TaskUpdate", "TaskGet",
    # User interaction
    "AskUserQuestion",
    # MCP tools are dynamic — validated separately
}

KNOWN_MODELS: set[str] = {"opus", "sonnet", "haiku", "inherit"}

KNOWN_PERMISSION_MODES: set[str] = {
    "default", "acceptEdits", "dontAsk", "bypassPermissions", "plan",
}

REQUIRED_FRONTMATTER_FIELDS: set[str] = {"name", "description"}


# --------------------------------------------------------------------------- #
# Fixtures                                                                     #
# --------------------------------------------------------------------------- #


@pytest.fixture(scope="session")
def repo_root() -> Path:
    return REPO_ROOT


@pytest.fixture(scope="session")
def agents_dir() -> Path:
    return AGENTS_DIR


@pytest.fixture(scope="session")
def agent_files() -> list[Path]:
    """Return all .md files in .claude/agents/."""
    return sorted(AGENTS_DIR.glob("*.md"))


@pytest.fixture(scope="session")
def parsed_agents(agent_files: list[Path]) -> list[dict]:
    """Parse YAML frontmatter + body from every agent .md file."""
    agents = []
    for path in agent_files:
        content = path.read_text()
        parts = content.split("---", 2)
        if len(parts) >= 3:
            meta = yaml.safe_load(parts[1]) or {}
            body = parts[2].strip()
        else:
            meta = {}
            body = content
        meta["_path"] = path
        meta["_body"] = body
        agents.append(meta)
    return agents


@pytest.fixture(scope="session")
def claude_version() -> str | None:
    """Return installed Claude Code CLI version, or None if not installed."""
    try:
        result = subprocess.run(
            ["claude", "--version"],
            capture_output=True,
            text=True,
            timeout=10,
        )
        if result.returncode == 0:
            return result.stdout.strip()
    except (FileNotFoundError, subprocess.TimeoutExpired):
        pass
    return None
