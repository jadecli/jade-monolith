"""Version compatibility tests — keep agent definitions current with Claude Code.

Strategy: Fetch the latest Claude Code release info from public sources and
compare against the contracts defined in conftest.py.  When Anthropic ships a
new tool, model, or permission mode, these tests FAIL — prompting you to
update conftest.py and your agent definitions.

Run with:  pytest tests/test_version_compat.py -v -m compat
"""

from __future__ import annotations

import json
import re
import subprocess
from pathlib import Path

import pytest

from .conftest import KNOWN_MODELS, KNOWN_PERMISSION_MODES, KNOWN_TOOLS, REPO_ROOT


# --------------------------------------------------------------------------- #
# Claude Code docs contract                                                    #
# --------------------------------------------------------------------------- #


@pytest.mark.compat
class TestVersionTracking:
    """Track Claude Code version and compare to minimum requirements."""

    VERSION_FILE = REPO_ROOT / ".claude" / "CLAUDE_CODE_VERSION"

    def test_version_pinfile_reflects_reality(self, claude_version: str | None):
        """If a pinned version file exists, it should match what's installed."""
        if claude_version is None:
            pytest.skip("Claude Code CLI not installed")
        if not self.VERSION_FILE.exists():
            pytest.skip("No version pin file — create .claude/CLAUDE_CODE_VERSION to enable")
        pinned = self.VERSION_FILE.read_text().strip()
        assert pinned in claude_version, (
            f"Pinned version '{pinned}' doesn't match installed '{claude_version}'. "
            f"Update {self.VERSION_FILE} after verifying compatibility."
        )


@pytest.mark.compat
class TestToolRegistryCompat:
    """Detect new or removed tools in Claude Code by comparing CLI output."""

    @pytest.fixture(scope="class")
    def cli_tools(self, claude_version: str | None) -> set[str] | None:
        """Attempt to discover tools from Claude Code's help or docs output."""
        if claude_version is None:
            return None
        # Claude Code doesn't expose a `--list-tools` flag, so we check the
        # docs or parse `claude --help` for known indicators.
        try:
            result = subprocess.run(
                ["claude", "--help"],
                capture_output=True,
                text=True,
                timeout=15,
            )
            return set(re.findall(r"\b([A-Z][a-z]+(?:[A-Z][a-z]+)+)\b", result.stdout))
        except (FileNotFoundError, subprocess.TimeoutExpired):
            return None

    def test_no_unknown_tools_in_cli(self, cli_tools: set[str] | None):
        """If CLI exposes tool names, check we haven't missed any."""
        if cli_tools is None:
            pytest.skip("Could not discover tools from CLI")
        # This is a heuristic — PascalCase words from --help that look like tools
        potential_new = cli_tools - KNOWN_TOOLS - {
            "Claude", "Code", "Agent", "Teams",  # common false positives
        }
        # We don't fail here — just warn. Actual failures come from schema tests.
        if potential_new:
            pytest.xfail(
                f"Potential new tools detected in CLI output: {potential_new}. "
                f"Investigate and update KNOWN_TOOLS if confirmed."
            )


@pytest.mark.compat
class TestAgentTeamWorkflow:
    """Integration tests for the 4-agent TDD workflow contract.

    These validate that the agent definitions collectively form a valid
    team — the architect plans, test-writer tests, implementer codes,
    reviewer checks.
    """

    def test_architect_is_readonly(self, parsed_agents: list[dict]):
        arch = next((a for a in parsed_agents if a["name"] == "architect"), None)
        assert arch is not None, "architect agent not found"
        disallowed = set(arch.get("disallowedTools") or [])
        assert {"Write", "Edit", "NotebookEdit"} <= disallowed, (
            "architect must disallow Write, Edit, NotebookEdit"
        )

    def test_reviewer_is_readonly(self, parsed_agents: list[dict]):
        rev = next((a for a in parsed_agents if a["name"] == "reviewer"), None)
        assert rev is not None, "reviewer agent not found"
        disallowed = set(rev.get("disallowedTools") or [])
        assert {"Write", "Edit", "NotebookEdit"} <= disallowed, (
            "reviewer must disallow Write, Edit, NotebookEdit"
        )

    def test_implementer_can_write(self, parsed_agents: list[dict]):
        impl = next((a for a in parsed_agents if a["name"] == "implementer"), None)
        assert impl is not None, "implementer agent not found"
        tools = set(impl.get("tools") or [])
        assert {"Write", "Edit"} <= tools, (
            "implementer must have Write and Edit tools"
        )

    def test_test_writer_can_write(self, parsed_agents: list[dict]):
        tw = next((a for a in parsed_agents if a["name"] == "test-writer"), None)
        assert tw is not None, "test-writer agent not found"
        tools = set(tw.get("tools") or [])
        assert {"Write", "Edit"} <= tools, (
            "test-writer must have Write and Edit tools"
        )

    def test_all_agents_have_read_access(self, parsed_agents: list[dict]):
        for agent in parsed_agents:
            tools = set(agent.get("tools") or [])
            assert "Read" in tools, (
                f"{agent['name']}: every agent must have Read tool access"
            )

    def test_all_agents_have_task_tools(self, parsed_agents: list[dict]):
        """Agent Teams coordination requires TaskCreate/List/Update/Get."""
        task_tools = {"TaskCreate", "TaskList", "TaskUpdate", "TaskGet"}
        for agent in parsed_agents:
            tools = set(agent.get("tools") or [])
            missing = task_tools - tools
            assert not missing, (
                f"{agent['name']}: missing task coordination tools {missing}"
            )

    def test_no_agent_has_web_and_write(self, parsed_agents: list[dict]):
        """Safety: agents with WebSearch/WebFetch shouldn't also write files
        (prevents prompt injection -> file modification attacks)."""
        web_tools = {"WebSearch", "WebFetch"}
        write_tools = {"Write", "Edit"}
        for agent in parsed_agents:
            tools = set(agent.get("tools") or [])
            has_web = tools & web_tools
            has_write = tools & write_tools
            if has_web and has_write:
                pytest.fail(
                    f"{agent['name']}: has both web access ({has_web}) and write "
                    f"access ({has_write}). This is a prompt injection risk."
                )


# --------------------------------------------------------------------------- #
# Release tracking via changelog fetch                                         #
# --------------------------------------------------------------------------- #


@pytest.mark.compat
class TestReleaseTracking:
    """Track Claude Code releases and flag when a new version is available."""

    def test_fetch_latest_release_from_npm(self, claude_version: str | None):
        """Check npm registry for latest @anthropic-ai/claude-code version."""
        try:
            result = subprocess.run(
                ["npm", "view", "@anthropic-ai/claude-code", "version"],
                capture_output=True,
                text=True,
                timeout=15,
            )
        except FileNotFoundError:
            pytest.skip("npm not installed")
        except subprocess.TimeoutExpired:
            pytest.skip("npm registry timed out")

        if result.returncode != 0:
            pytest.skip(f"npm view failed: {result.stderr.strip()}")

        latest = result.stdout.strip()
        if claude_version is None:
            pytest.skip(
                f"Claude Code not installed locally. Latest on npm: {latest}"
            )

        # Extract semver from installed version
        installed_match = re.search(r"(\d+\.\d+\.\d+)", claude_version)
        if not installed_match:
            pytest.skip(f"Could not parse installed version: {claude_version}")

        installed = installed_match.group(1)
        if installed != latest:
            pytest.xfail(
                f"Installed Claude Code ({installed}) differs from latest npm "
                f"release ({latest}). Run `npm update -g @anthropic-ai/claude-code` "
                f"and re-run tests to verify compatibility."
            )
