"""Tests for the TASK.md frontmatter parser."""
from __future__ import annotations

from pathlib import Path

import pytest

from agent_task_spec.parser import ParseError, parse_body, parse_frontmatter, parse_task

EXAMPLES_DIR = Path(__file__).parent.parent / "docs" / "specs" / "agent-task-spec" / "examples"


class TestParseFrontmatter:
    def test_valid_frontmatter(self):
        content = "---\nid: test\ntype: feat\n---\nBody here"
        result = parse_frontmatter(content)
        assert result == {"id": "test", "type": "feat"}

    def test_multiline_description(self):
        content = "---\nid: test\ndescription: >\n  Line 1\n  Line 2\n---\nBody"
        result = parse_frontmatter(content)
        assert "Line 1" in result["description"]
        assert "Line 2" in result["description"]

    def test_missing_frontmatter_raises(self):
        with pytest.raises(ParseError, match="No YAML frontmatter"):
            parse_frontmatter("No frontmatter here")

    def test_malformed_yaml_raises(self):
        with pytest.raises(ParseError, match="Invalid YAML"):
            parse_frontmatter("---\n: invalid: yaml: [[\n---\n")

    def test_non_mapping_raises(self):
        with pytest.raises(ParseError, match="must be a mapping"):
            parse_frontmatter("---\n- list\n- items\n---\n")

    def test_empty_frontmatter(self):
        # Empty YAML returns None from safe_load, which is not a dict
        with pytest.raises(ParseError, match="must be a mapping"):
            parse_frontmatter("---\n\n---\nBody")


class TestParseBody:
    def test_extracts_body(self):
        content = "---\nid: test\n---\n\n## Context\n\nSome body text"
        body = parse_body(content)
        assert "## Context" in body
        assert "Some body text" in body

    def test_no_frontmatter_returns_content(self):
        content = "Just plain text"
        assert parse_body(content) == "Just plain text"

    def test_empty_body(self):
        content = "---\nid: test\n---\n"
        assert parse_body(content) == ""


class TestParseTask:
    def test_parse_example_file(self):
        result = parse_task(EXAMPLES_DIR / "feat-user-auth.md")
        assert result["frontmatter"]["id"] == "feat-user-auth"
        assert result["frontmatter"]["type"] == "feat"
        assert "## Context" in result["body"]

    def test_all_examples_parseable(self):
        for name in ["feat-user-auth", "fix-null-deref", "test-api-coverage"]:
            result = parse_task(EXAMPLES_DIR / f"{name}.md")
            assert "id" in result["frontmatter"]
            assert "type" in result["frontmatter"]

    def test_file_not_found_raises(self):
        with pytest.raises(ParseError, match="File not found"):
            parse_task(Path("/nonexistent/TASK.md"))
