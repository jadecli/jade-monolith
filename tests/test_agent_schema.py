"""Schema validation tests for .claude/agents/ definitions.

These tests ensure every agent definition file conforms to the Claude Code
subagent specification (https://code.claude.com/docs/en/sub-agents).

Run with:  pytest tests/test_agent_schema.py -v
"""

from __future__ import annotations

from pathlib import Path

import pytest

from .conftest import (
    KNOWN_MODELS,
    KNOWN_PERMISSION_MODES,
    KNOWN_TOOLS,
    REQUIRED_FRONTMATTER_FIELDS,
)


# --------------------------------------------------------------------------- #
# Discovery                                                                    #
# --------------------------------------------------------------------------- #


@pytest.mark.schema
class TestAgentDiscovery:
    """Verify the agent directory and its files exist."""

    def test_agents_directory_exists(self, agents_dir: Path):
        assert agents_dir.is_dir(), f"Missing directory: {agents_dir}"

    def test_at_least_one_agent_defined(self, agent_files: list[Path]):
        assert len(agent_files) > 0, "No agent .md files found in .claude/agents/"

    def test_expected_team_agents_exist(self, agents_dir: Path):
        expected = {"architect.md", "implementer.md", "test-writer.md", "reviewer.md"}
        actual = {p.name for p in agents_dir.glob("*.md")}
        missing = expected - actual
        assert not missing, f"Missing team agents: {missing}"


# --------------------------------------------------------------------------- #
# Frontmatter schema                                                           #
# --------------------------------------------------------------------------- #


@pytest.mark.schema
class TestFrontmatterSchema:
    """Validate YAML frontmatter against Claude Code subagent spec."""

    def test_has_yaml_frontmatter(self, parsed_agents: list[dict]):
        for agent in parsed_agents:
            path: Path = agent["_path"]
            assert "name" in agent, (
                f"{path.name}: missing YAML frontmatter (no 'name' field)"
            )

    def test_required_fields_present(self, parsed_agents: list[dict]):
        for agent in parsed_agents:
            path: Path = agent["_path"]
            for field in REQUIRED_FRONTMATTER_FIELDS:
                assert field in agent, f"{path.name}: missing required field '{field}'"

    def test_name_matches_filename(self, parsed_agents: list[dict]):
        """Agent name in frontmatter should match the file's stem."""
        for agent in parsed_agents:
            path: Path = agent["_path"]
            assert agent["name"] == path.stem, (
                f"{path.name}: name '{agent['name']}' != filename stem '{path.stem}'"
            )

    def test_description_is_nonempty_string(self, parsed_agents: list[dict]):
        for agent in parsed_agents:
            path: Path = agent["_path"]
            desc = agent.get("description", "")
            assert isinstance(desc, str) and len(desc.strip()) > 10, (
                f"{path.name}: description must be a meaningful string (>10 chars)"
            )

    def test_model_is_valid(self, parsed_agents: list[dict]):
        for agent in parsed_agents:
            path: Path = agent["_path"]
            model = agent.get("model")
            if model is not None:
                assert model in KNOWN_MODELS, (
                    f"{path.name}: model '{model}' not in {KNOWN_MODELS}"
                )

    def test_permission_mode_is_valid(self, parsed_agents: list[dict]):
        for agent in parsed_agents:
            path: Path = agent["_path"]
            mode = agent.get("permissionMode")
            if mode is not None:
                assert mode in KNOWN_PERMISSION_MODES, (
                    f"{path.name}: permissionMode '{mode}' not in {KNOWN_PERMISSION_MODES}"
                )


# --------------------------------------------------------------------------- #
# Tool validation                                                              #
# --------------------------------------------------------------------------- #


@pytest.mark.schema
class TestToolPermissions:
    """Validate tool lists in agent definitions."""

    def test_tools_are_known(self, parsed_agents: list[dict]):
        for agent in parsed_agents:
            path: Path = agent["_path"]
            tools = agent.get("tools", [])
            if isinstance(tools, str):
                tools = [t.strip() for t in tools.split(",")]
            unknown = set(tools) - KNOWN_TOOLS
            assert not unknown, (
                f"{path.name}: unknown tools {unknown}. "
                f"Update KNOWN_TOOLS in conftest.py if Claude Code added new tools."
            )

    def test_disallowed_tools_are_known(self, parsed_agents: list[dict]):
        for agent in parsed_agents:
            path: Path = agent["_path"]
            disallowed = agent.get("disallowedTools", [])
            if isinstance(disallowed, str):
                disallowed = [t.strip() for t in disallowed.split(",")]
            unknown = set(disallowed) - KNOWN_TOOLS
            assert not unknown, (
                f"{path.name}: unknown disallowedTools {unknown}. "
                f"Update KNOWN_TOOLS in conftest.py if Claude Code added new tools."
            )

    def test_no_tool_in_both_allowed_and_disallowed(self, parsed_agents: list[dict]):
        for agent in parsed_agents:
            path: Path = agent["_path"]
            tools = set(agent.get("tools") or [])
            disallowed = set(agent.get("disallowedTools") or [])
            overlap = tools & disallowed
            assert not overlap, (
                f"{path.name}: tools in BOTH allowed and disallowed: {overlap}"
            )

    def test_readonly_agents_cannot_write(self, parsed_agents: list[dict]):
        """Agents described as 'read-only' must not have Write/Edit tools."""
        write_tools = {"Write", "Edit", "NotebookEdit"}
        for agent in parsed_agents:
            path: Path = agent["_path"]
            desc = (agent.get("description") or "").lower()
            if "read-only" in desc or "read only" in desc:
                tools = set(agent.get("tools") or [])
                disallowed = set(agent.get("disallowedTools") or [])
                # Write tools must either be absent from tools or present in disallowed
                has_write = tools & write_tools
                blocked = disallowed & write_tools
                unblocked_writes = has_write - blocked
                assert not unblocked_writes, (
                    f"{path.name}: described as read-only but has unblocked write tools: "
                    f"{unblocked_writes}"
                )


# --------------------------------------------------------------------------- #
# System prompt body                                                           #
# --------------------------------------------------------------------------- #


@pytest.mark.schema
class TestAgentBody:
    """Validate the markdown body (system prompt) of each agent."""

    def test_body_is_nonempty(self, parsed_agents: list[dict]):
        for agent in parsed_agents:
            path: Path = agent["_path"]
            assert len(agent["_body"]) > 50, (
                f"{path.name}: system prompt body is too short (<50 chars)"
            )

    def test_body_contains_responsibilities(self, parsed_agents: list[dict]):
        """Every agent should document its responsibilities."""
        for agent in parsed_agents:
            path: Path = agent["_path"]
            body_lower = agent["_body"].lower()
            assert "responsibilit" in body_lower or "workflow" in body_lower, (
                f"{path.name}: body should contain 'Responsibilities' or 'Workflow' section"
            )

    def test_body_contains_constraints(self, parsed_agents: list[dict]):
        """Every agent should document its constraints."""
        for agent in parsed_agents:
            path: Path = agent["_path"]
            body_lower = agent["_body"].lower()
            assert "constraint" in body_lower or "must not" in body_lower, (
                f"{path.name}: body should contain 'Constraints' or 'MUST NOT' rules"
            )
