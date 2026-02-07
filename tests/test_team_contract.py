"""Contract tests for Claude Code Agent Teams integration.

These tests verify that the agent team configuration is compatible
with the installed version of Claude Code.  They validate:

  1. CLI availability and version requirements
  2. Agent loading via `claude --agent <name>`
  3. Settings.json contract (env vars, permissions)
  4. Team lifecycle scripts

Run with:  pytest tests/test_team_contract.py -v -m contract
Requires:  Claude Code CLI installed (`npm install -g @anthropic-ai/claude-code`)
"""

from __future__ import annotations

import json
import re
import subprocess
from pathlib import Path

import pytest

from .conftest import SETTINGS_PATH

# --------------------------------------------------------------------------- #
# CLI availability                                                             #
# --------------------------------------------------------------------------- #

MIN_VERSION = "2.1.0"  # Agent Teams first supported in 2.1.x


def _parse_semver(version_str: str) -> tuple[int, ...]:
    """Extract numeric version parts from a version string like '2.1.34'."""
    match = re.search(r"(\d+\.\d+\.\d+)", version_str)
    if not match:
        return (0, 0, 0)
    return tuple(int(x) for x in match.group(1).split("."))


@pytest.mark.contract
class TestCLIAvailability:
    """Verify Claude Code CLI is installed and meets version requirements."""

    def test_claude_cli_is_installed(self, claude_version: str | None):
        if claude_version is None:
            pytest.skip("Claude Code CLI not installed — skipping contract tests")
        assert claude_version, "claude --version returned empty string"

    def test_claude_cli_meets_minimum_version(self, claude_version: str | None):
        if claude_version is None:
            pytest.skip("Claude Code CLI not installed")
        installed = _parse_semver(claude_version)
        required = _parse_semver(MIN_VERSION)
        assert installed >= required, (
            f"Claude Code {claude_version} is below minimum {MIN_VERSION} "
            f"for Agent Teams support"
        )

    def test_claude_cli_responds_to_help(self):
        """Smoke test: `claude --help` exits cleanly."""
        try:
            result = subprocess.run(
                ["claude", "--help"],
                capture_output=True,
                text=True,
                timeout=30,
            )
        except FileNotFoundError:
            pytest.skip("Claude Code CLI not installed")
        except subprocess.TimeoutExpired:
            pytest.skip("claude --help timed out (slow startup environment)")
        assert result.returncode == 0, f"claude --help failed: {result.stderr}"


# --------------------------------------------------------------------------- #
# Agent loading contract                                                       #
# --------------------------------------------------------------------------- #


@pytest.mark.contract
class TestAgentLoading:
    """Verify Claude Code can discover and load project agent definitions."""

    @pytest.fixture(scope="class")
    def _cli_available(self, claude_version: str | None):
        if claude_version is None:
            pytest.skip("Claude Code CLI not installed")

    @pytest.mark.parametrize("agent_name", [
        "architect", "implementer", "test-writer", "reviewer",
    ])
    def test_agent_loads_via_print_mode(
        self, _cli_available, agent_name: str, repo_root: Path,
    ):
        """Run `claude -p 'echo ok' --agent <name>` and verify it doesn't error
        on agent loading.  We use --max-turns 1 to avoid burning API tokens."""
        try:
            result = subprocess.run(
                [
                    "claude", "-p", "Respond with exactly: OK",
                    "--agent", agent_name,
                    "--max-turns", "1",
                    "--output-format", "json",
                ],
                capture_output=True,
                text=True,
                timeout=60,
                cwd=str(repo_root),
            )
        except subprocess.TimeoutExpired:
            pytest.skip(f"claude timed out loading agent '{agent_name}'")

        # We check that it didn't fail with "agent not found" style errors.
        # The command may still fail if no API key is set — that's fine,
        # we only care that agent *loading* succeeded.
        combined = result.stdout + result.stderr
        agent_errors = [
            "agent not found",
            "no agent",
            "unknown agent",
            "could not find agent",
            "invalid agent",
        ]
        for err in agent_errors:
            assert err not in combined.lower(), (
                f"Agent '{agent_name}' failed to load: {combined[:500]}"
            )


# --------------------------------------------------------------------------- #
# Settings contract                                                            #
# --------------------------------------------------------------------------- #


@pytest.mark.contract
class TestSettingsContract:
    """Validate .claude/settings.json meets Agent Teams requirements."""

    @pytest.fixture(scope="class")
    def settings(self) -> dict:
        assert SETTINGS_PATH.exists(), f"Missing {SETTINGS_PATH}"
        return json.loads(SETTINGS_PATH.read_text())

    def test_agent_teams_env_enabled(self, settings: dict):
        env = settings.get("env", {})
        val = env.get("CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS")
        assert val == "1", (
            "settings.json must set CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1"
        )

    def test_tasks_env_enabled(self, settings: dict):
        env = settings.get("env", {})
        val = env.get("CLAUDE_CODE_ENABLE_TASKS")
        assert val == "true", (
            "settings.json must set CLAUDE_CODE_ENABLE_TASKS=true"
        )

    def test_permissions_has_allow_list(self, settings: dict):
        perms = settings.get("permissions", {})
        allow = perms.get("allow", [])
        assert len(allow) > 0, "settings.json permissions.allow is empty"

    def test_permissions_has_deny_list(self, settings: dict):
        perms = settings.get("permissions", {})
        deny = perms.get("deny", [])
        assert len(deny) > 0, "settings.json permissions.deny should block sensitive files"

    def test_env_files_are_denied(self, settings: dict):
        """Sensitive .env files must be in the deny list."""
        deny = settings.get("permissions", {}).get("deny", [])
        deny_str = " ".join(deny)
        assert ".env" in deny_str, "permissions.deny must block .env files"

    def test_secrets_are_denied(self, settings: dict):
        """secrets/ directory must be in the deny list."""
        deny = settings.get("permissions", {}).get("deny", [])
        deny_str = " ".join(deny)
        assert "secrets" in deny_str, "permissions.deny must block secrets/"


# --------------------------------------------------------------------------- #
# Team scripts                                                                 #
# --------------------------------------------------------------------------- #


@pytest.mark.contract
class TestTeamScripts:
    """Validate team orchestration scripts exist and are well-formed."""

    def test_start_team_script_exists(self, repo_root: Path):
        script = repo_root / "scripts" / "start-team.sh"
        assert script.exists(), f"Missing {script}"

    def test_start_team_script_is_executable(self, repo_root: Path):
        import os
        import stat

        script = repo_root / "scripts" / "start-team.sh"
        if not script.exists():
            pytest.skip("start-team.sh not found")
        mode = os.stat(script).st_mode
        assert mode & stat.S_IXUSR, f"{script} is not executable (chmod +x)"

    def test_start_team_script_sets_agent_teams_env(self, repo_root: Path):
        script = repo_root / "scripts" / "start-team.sh"
        if not script.exists():
            pytest.skip("start-team.sh not found")
        content = script.read_text()
        assert "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS" in content, (
            "start-team.sh must export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS"
        )

    def test_start_team_references_all_agents(self, repo_root: Path):
        script = repo_root / "scripts" / "start-team.sh"
        if not script.exists():
            pytest.skip("start-team.sh not found")
        content = script.read_text()
        for agent in ["architect", "implementer", "test-writer", "reviewer"]:
            assert agent in content, (
                f"start-team.sh missing reference to '{agent}' agent"
            )

    def test_start_team_shellcheck_clean(self, repo_root: Path):
        """If shellcheck is installed, verify start-team.sh passes."""
        script = repo_root / "scripts" / "start-team.sh"
        if not script.exists():
            pytest.skip("start-team.sh not found")
        try:
            result = subprocess.run(
                ["shellcheck", "-S", "warning", str(script)],
                capture_output=True,
                text=True,
                timeout=15,
            )
        except FileNotFoundError:
            pytest.skip("shellcheck not installed")
        assert result.returncode == 0, (
            f"shellcheck warnings in start-team.sh:\n{result.stdout}"
        )
