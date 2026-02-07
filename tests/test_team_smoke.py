"""Smoke tests — fast, no API calls, no network.

These tests run in CI and pre-commit to catch obvious misconfigurations
before burning API tokens.

Run with:  pytest tests/test_team_smoke.py -v -m smoke
"""

from __future__ import annotations

import json
import os
import stat
from pathlib import Path

import pytest
import yaml

from .conftest import AGENTS_DIR, REPO_ROOT, SETTINGS_PATH


# --------------------------------------------------------------------------- #
# File integrity                                                               #
# --------------------------------------------------------------------------- #


@pytest.mark.smoke
class TestFileIntegrity:
    """Ensure all configuration files parse cleanly."""

    def test_settings_json_is_valid(self):
        content = SETTINGS_PATH.read_text()
        data = json.loads(content)
        assert isinstance(data, dict), "settings.json root must be an object"

    def test_agent_files_have_valid_yaml(self):
        for path in AGENTS_DIR.glob("*.md"):
            content = path.read_text()
            parts = content.split("---", 2)
            assert len(parts) >= 3, (
                f"{path.name}: must have YAML frontmatter delimited by ---"
            )
            try:
                meta = yaml.safe_load(parts[1])
            except yaml.YAMLError as e:
                pytest.fail(f"{path.name}: invalid YAML frontmatter: {e}")
            assert isinstance(meta, dict), (
                f"{path.name}: YAML frontmatter must be a mapping"
            )

    def test_no_trailing_whitespace_in_agent_names(self):
        for path in AGENTS_DIR.glob("*.md"):
            content = path.read_text()
            parts = content.split("---", 2)
            if len(parts) >= 3:
                meta = yaml.safe_load(parts[1]) or {}
                name = meta.get("name", "")
                assert name == name.strip(), (
                    f"{path.name}: agent name has trailing whitespace: '{name}'"
                )


# --------------------------------------------------------------------------- #
# Team completeness                                                            #
# --------------------------------------------------------------------------- #


@pytest.mark.smoke
class TestTeamCompleteness:
    """Verify the 4-agent team is fully defined and consistent."""

    TEAM = {
        "architect": {"readonly": True, "model": "opus"},
        "implementer": {"readonly": False, "model": "opus"},
        "test-writer": {"readonly": False, "model": "opus"},
        "reviewer": {"readonly": True, "model": "opus"},
    }

    def _load_agent(self, name: str) -> dict:
        path = AGENTS_DIR / f"{name}.md"
        content = path.read_text()
        parts = content.split("---", 2)
        return yaml.safe_load(parts[1]) if len(parts) >= 3 else {}

    def test_all_four_agents_defined(self):
        for name in self.TEAM:
            path = AGENTS_DIR / f"{name}.md"
            assert path.exists(), f"Missing agent definition: {name}.md"

    def test_readonly_agents_have_correct_disallowed_tools(self):
        write_tools = {"Write", "Edit", "NotebookEdit"}
        for name, spec in self.TEAM.items():
            if spec["readonly"]:
                meta = self._load_agent(name)
                disallowed = set(meta.get("disallowedTools") or [])
                assert write_tools <= disallowed, (
                    f"{name}: read-only agent must disallow {write_tools}, "
                    f"has {disallowed}"
                )

    def test_writable_agents_have_write_tools(self):
        for name, spec in self.TEAM.items():
            if not spec["readonly"]:
                meta = self._load_agent(name)
                tools = set(meta.get("tools") or [])
                assert "Write" in tools and "Edit" in tools, (
                    f"{name}: writable agent must have Write and Edit tools"
                )

    def test_all_agents_use_expected_model(self):
        for name, spec in self.TEAM.items():
            meta = self._load_agent(name)
            model = meta.get("model", "inherit")
            assert model == spec["model"], (
                f"{name}: expected model '{spec['model']}', got '{model}'"
            )


# --------------------------------------------------------------------------- #
# Documentation consistency                                                    #
# --------------------------------------------------------------------------- #


@pytest.mark.smoke
class TestDocumentation:
    """Verify docs reference the correct agents and configuration."""

    def test_team_setup_doc_exists(self):
        doc = REPO_ROOT / "docs" / "team-setup.md"
        assert doc.exists(), "docs/team-setup.md missing"

    def test_team_setup_references_all_agents(self):
        doc = REPO_ROOT / "docs" / "team-setup.md"
        if not doc.exists():
            pytest.skip("docs/team-setup.md not found")
        content = doc.read_text().lower()
        for agent in ["architect", "implementer", "test-writer", "reviewer"]:
            assert agent in content, (
                f"docs/team-setup.md missing reference to '{agent}'"
            )

    def test_api_usage_doc_exists(self):
        doc = REPO_ROOT / "docs" / "api-usage.md"
        assert doc.exists(), "docs/api-usage.md missing"
