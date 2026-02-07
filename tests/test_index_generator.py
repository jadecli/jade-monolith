"""Tests for INDEX.json generator."""
from __future__ import annotations

import json
from datetime import UTC, datetime
from pathlib import Path

import jsonschema
import pytest

from agent_task_spec.index_generator import (
    ATS_VERSION,
    generate_index,
    write_index,
)

SCHEMA_DIR = Path(__file__).parent.parent / "docs" / "specs" / "agent-task-spec" / "schema"
EXAMPLES_DIR = Path(__file__).parent.parent / "docs" / "specs" / "agent-task-spec" / "examples"


@pytest.fixture
def index_schema() -> dict:
    return json.loads((SCHEMA_DIR / "index.schema.json").read_text())


@pytest.fixture
def fixed_timestamp() -> datetime:
    return datetime(2026, 2, 6, 12, 0, 0, tzinfo=UTC)


@pytest.fixture
def task_tree(tmp_path: Path) -> Path:
    """Create a minimal .agent-tasks directory with TASK.md files."""
    root = tmp_path / ".agent-tasks"
    tasks_dir = root / "tasks"

    # Task 1: feat, in_progress
    t1 = tasks_dir / "feat-auth" / "TASK.md"
    t1.parent.mkdir(parents=True)
    t1.write_text(
        "---\n"
        "id: feat-auth\n"
        "type: feat\n"
        "subject: Add authentication\n"
        "status: in_progress\n"
        "owner: implementer\n"
        "scope: auth\n"
        "---\n\n## Context\n\nAuth task body.\n"
    )

    # Task 2: fix, completed
    t2 = tasks_dir / "fix-crash" / "TASK.md"
    t2.parent.mkdir(parents=True)
    t2.write_text(
        "---\n"
        "id: fix-crash\n"
        "type: fix\n"
        "subject: Fix null pointer crash\n"
        "status: completed\n"
        "---\n\n## Context\n\nFix body.\n"
    )

    # Task 3: test, pending, with blockedBy
    t3 = tasks_dir / "test-api" / "TASK.md"
    t3.parent.mkdir(parents=True)
    t3.write_text(
        "---\n"
        "id: test-api\n"
        "type: test\n"
        "subject: API integration tests\n"
        "status: pending\n"
        "blockedBy:\n"
        "  - feat-auth\n"
        "---\n\n## Context\n\nTest body.\n"
    )

    return root


@pytest.fixture
def empty_tree(tmp_path: Path) -> Path:
    """Create an empty .agent-tasks directory with no tasks."""
    root = tmp_path / ".agent-tasks"
    (root / "tasks").mkdir(parents=True)
    return root


class TestGenerateIndex:
    def test_generates_valid_index(
        self,
        task_tree: Path,
        index_schema: dict,
        fixed_timestamp: datetime,
    ):
        index = generate_index(task_tree, timestamp=fixed_timestamp)
        jsonschema.validate(index, index_schema)

    def test_version_matches(self, task_tree: Path, fixed_timestamp: datetime):
        index = generate_index(task_tree, timestamp=fixed_timestamp)
        assert index["version"] == ATS_VERSION

    def test_timestamp_format(self, task_tree: Path, fixed_timestamp: datetime):
        index = generate_index(task_tree, timestamp=fixed_timestamp)
        assert index["generatedAt"] == "2026-02-06T12:00:00Z"

    def test_stats_correct(self, task_tree: Path, fixed_timestamp: datetime):
        index = generate_index(task_tree, timestamp=fixed_timestamp)
        stats = index["stats"]
        assert stats["total"] == 3
        assert stats["pending"] == 1
        assert stats["in_progress"] == 1
        assert stats["completed"] == 1
        assert stats["blocked"] == 0
        assert stats["locked"] == 0
        assert stats["review"] == 0
        assert stats["rejected"] == 0

    def test_tasks_count(self, task_tree: Path, fixed_timestamp: datetime):
        index = generate_index(task_tree, timestamp=fixed_timestamp)
        assert len(index["tasks"]) == 3

    def test_task_summaries_have_required_fields(self, task_tree: Path, fixed_timestamp: datetime):
        index = generate_index(task_tree, timestamp=fixed_timestamp)
        for task in index["tasks"]:
            assert "id" in task
            assert "type" in task
            assert "subject" in task
            assert "status" in task

    def test_task_ids_sorted(self, task_tree: Path, fixed_timestamp: datetime):
        index = generate_index(task_tree, timestamp=fixed_timestamp)
        ids = [t["id"] for t in index["tasks"]]
        assert ids == ["feat-auth", "fix-crash", "test-api"]

    def test_optional_fields_preserved(self, task_tree: Path, fixed_timestamp: datetime):
        index = generate_index(task_tree, timestamp=fixed_timestamp)
        auth_task = next(t for t in index["tasks"] if t["id"] == "feat-auth")
        assert auth_task["owner"] == "implementer"
        assert auth_task["scope"] == "auth"

    def test_blocked_by_preserved(self, task_tree: Path, fixed_timestamp: datetime):
        index = generate_index(task_tree, timestamp=fixed_timestamp)
        test_task = next(t for t in index["tasks"] if t["id"] == "test-api")
        assert test_task["blockedBy"] == ["feat-auth"]

    def test_missing_optional_fields_omitted(self, task_tree: Path, fixed_timestamp: datetime):
        index = generate_index(task_tree, timestamp=fixed_timestamp)
        fix_task = next(t for t in index["tasks"] if t["id"] == "fix-crash")
        assert "owner" not in fix_task
        assert "scope" not in fix_task
        assert "blockedBy" not in fix_task


class TestEmptyTree:
    def test_empty_tree_valid(
        self,
        empty_tree: Path,
        index_schema: dict,
        fixed_timestamp: datetime,
    ):
        index = generate_index(empty_tree, timestamp=fixed_timestamp)
        jsonschema.validate(index, index_schema)

    def test_empty_tree_zero_stats(self, empty_tree: Path, fixed_timestamp: datetime):
        index = generate_index(empty_tree, timestamp=fixed_timestamp)
        assert index["stats"]["total"] == 0
        assert index["tasks"] == []

    def test_no_tasks_dir(self, tmp_path: Path, index_schema: dict, fixed_timestamp: datetime):
        root = tmp_path / ".agent-tasks"
        root.mkdir()
        index = generate_index(root, timestamp=fixed_timestamp)
        jsonschema.validate(index, index_schema)
        assert index["stats"]["total"] == 0


class TestWriteIndex:
    def test_writes_file(self, task_tree: Path, fixed_timestamp: datetime):
        output = write_index(task_tree, timestamp=fixed_timestamp)
        assert output.exists()
        assert output.name == "INDEX.json"

    def test_written_json_valid(
        self,
        task_tree: Path,
        index_schema: dict,
        fixed_timestamp: datetime,
    ):
        output = write_index(task_tree, timestamp=fixed_timestamp)
        data = json.loads(output.read_text())
        jsonschema.validate(data, index_schema)

    def test_custom_output_path(self, task_tree: Path, tmp_path: Path, fixed_timestamp: datetime):
        custom = tmp_path / "custom" / "index.json"
        output = write_index(task_tree, output=custom, timestamp=fixed_timestamp)
        assert output == custom
        assert custom.exists()

    def test_roundtrip_matches(self, task_tree: Path, fixed_timestamp: datetime):
        index = generate_index(task_tree, timestamp=fixed_timestamp)
        output = write_index(task_tree, timestamp=fixed_timestamp)
        written = json.loads(output.read_text())
        assert written == index


class TestExamplesIndex:
    def test_example_index_matches_schema(self, index_schema: dict):
        """Verify the hand-written example INDEX.json still validates."""
        data = json.loads((EXAMPLES_DIR / "index.json").read_text())
        jsonschema.validate(data, index_schema)
