"""Tests for TASK.md frontmatter validation against task.schema.json."""
from __future__ import annotations

import json
from pathlib import Path

import jsonschema
import pytest
import yaml

SCHEMA_DIR = Path(__file__).parent.parent / "docs" / "specs" / "agent-task-spec" / "schema"
EXAMPLES_DIR = Path(__file__).parent.parent / "docs" / "specs" / "agent-task-spec" / "examples"


@pytest.fixture
def task_schema() -> dict:
    return json.loads((SCHEMA_DIR / "task.schema.json").read_text())


@pytest.fixture
def index_schema() -> dict:
    return json.loads((SCHEMA_DIR / "index.schema.json").read_text())


@pytest.fixture
def lock_schema() -> dict:
    return json.loads((SCHEMA_DIR / "lock.schema.json").read_text())


@pytest.fixture
def progress_schema() -> dict:
    return json.loads((SCHEMA_DIR / "progress.schema.json").read_text())


def _load_frontmatter(path: Path) -> dict:
    content = path.read_text()
    parts = content.split("---", 2)
    return yaml.safe_load(parts[1])


# === Example validation ===
class TestExamplesValidate:
    @pytest.mark.parametrize("name", ["feat-user-auth", "fix-null-deref", "test-api-coverage"])
    def test_example_validates(self, task_schema: dict, name: str):
        fm = _load_frontmatter(EXAMPLES_DIR / f"{name}.md")
        jsonschema.validate(fm, task_schema)

    def test_example_index_validates(self, index_schema: dict):
        data = json.loads((EXAMPLES_DIR / "index.json").read_text())
        jsonschema.validate(data, index_schema)


# === Minimal task ===
class TestMinimalTask:
    def test_minimal_task_validates(self, task_schema: dict):
        task = {"id": "fix-typo", "type": "docs", "subject": "Fix typo", "status": "pending"}
        jsonschema.validate(task, task_schema)


# === Required fields ===
class TestRequiredFields:
    @pytest.mark.parametrize("missing_field", ["id", "type", "subject", "status"])
    def test_missing_required_field_fails(self, task_schema: dict, missing_field: str):
        task = {"id": "test-task", "type": "feat", "subject": "Test", "status": "pending"}
        del task[missing_field]
        with pytest.raises(jsonschema.ValidationError):
            jsonschema.validate(task, task_schema)


# === Type enum ===
class TestTypeEnum:
    @pytest.mark.parametrize(
        "valid_type",
        [
            "feat",
            "fix",
            "docs",
            "style",
            "refactor",
            "perf",
            "test",
            "build",
            "ci",
            "chore",
            "revert",
        ],
    )
    def test_valid_type_accepted(self, task_schema: dict, valid_type: str):
        task = {"id": "t", "type": valid_type, "subject": "Test", "status": "pending"}
        jsonschema.validate(task, task_schema)

    def test_invalid_type_fails(self, task_schema: dict):
        task = {"id": "t", "type": "invalid", "subject": "Test", "status": "pending"}
        with pytest.raises(jsonschema.ValidationError):
            jsonschema.validate(task, task_schema)


# === Status enum ===
class TestStatusEnum:
    @pytest.mark.parametrize(
        "valid_status",
        ["pending", "locked", "in_progress", "blocked", "review", "completed", "rejected"],
    )
    def test_valid_status_accepted(self, task_schema: dict, valid_status: str):
        task = {"id": "t", "type": "feat", "subject": "Test", "status": valid_status}
        jsonschema.validate(task, task_schema)

    def test_invalid_status_fails(self, task_schema: dict):
        task = {"id": "t", "type": "feat", "subject": "Test", "status": "bogus"}
        with pytest.raises(jsonschema.ValidationError):
            jsonschema.validate(task, task_schema)


# === ID pattern ===
class TestIdPattern:
    def test_uppercase_rejected(self, task_schema: dict):
        task = {"id": "UpperCase", "type": "feat", "subject": "Test", "status": "pending"}
        with pytest.raises(jsonschema.ValidationError):
            jsonschema.validate(task, task_schema)

    def test_spaces_rejected(self, task_schema: dict):
        task = {"id": "has spaces", "type": "feat", "subject": "Test", "status": "pending"}
        with pytest.raises(jsonschema.ValidationError):
            jsonschema.validate(task, task_schema)

    def test_special_chars_rejected(self, task_schema: dict):
        task = {"id": "has_underscore", "type": "feat", "subject": "Test", "status": "pending"}
        with pytest.raises(jsonschema.ValidationError):
            jsonschema.validate(task, task_schema)

    def test_hyphenated_accepted(self, task_schema: dict):
        task = {"id": "feat-user-auth", "type": "feat", "subject": "Test", "status": "pending"}
        jsonschema.validate(task, task_schema)


# === Subject length ===
class TestSubjectLength:
    def test_max_length_accepted(self, task_schema: dict):
        task = {"id": "t", "type": "feat", "subject": "x" * 80, "status": "pending"}
        jsonschema.validate(task, task_schema)

    def test_over_max_length_rejected(self, task_schema: dict):
        task = {"id": "t", "type": "feat", "subject": "x" * 81, "status": "pending"}
        with pytest.raises(jsonschema.ValidationError):
            jsonschema.validate(task, task_schema)

    def test_empty_subject_rejected(self, task_schema: dict):
        task = {"id": "t", "type": "feat", "subject": "", "status": "pending"}
        with pytest.raises(jsonschema.ValidationError):
            jsonschema.validate(task, task_schema)


# === Boolean fields ===
class TestBooleanFields:
    def test_breaking_boolean_accepted(self, task_schema: dict):
        task = {"id": "t", "type": "feat", "subject": "Test", "status": "pending", "breaking": True}
        jsonschema.validate(task, task_schema)

    def test_breaking_string_rejected(self, task_schema: dict):
        task = {
            "id": "t",
            "type": "feat",
            "subject": "Test",
            "status": "pending",
            "breaking": "yes",
        }
        with pytest.raises(jsonschema.ValidationError):
            jsonschema.validate(task, task_schema)

    def test_test_first_boolean(self, task_schema: dict):
        task = {
            "id": "t",
            "type": "feat",
            "subject": "Test",
            "status": "pending",
            "testFirst": True,
        }
        jsonschema.validate(task, task_schema)


# === Array fields ===
class TestArrayFields:
    def test_blocked_by_unique_items(self, task_schema: dict):
        task = {
            "id": "t",
            "type": "feat",
            "subject": "Test",
            "status": "pending",
            "blockedBy": ["a", "a"],
        }
        with pytest.raises(jsonschema.ValidationError):
            jsonschema.validate(task, task_schema)

    def test_criteria_accepted(self, task_schema: dict):
        task = {
            "id": "t",
            "type": "feat",
            "subject": "Test",
            "status": "pending",
            "criteria": ["All tests pass", "ruff check clean"],
        }
        jsonschema.validate(task, task_schema)

    def test_related_issues_integers(self, task_schema: dict):
        task = {
            "id": "t",
            "type": "feat",
            "subject": "Test",
            "status": "pending",
            "relatedIssues": [12, 15],
        }
        jsonschema.validate(task, task_schema)


# === Metadata extensibility ===
class TestMetadata:
    def test_arbitrary_metadata_accepted(self, task_schema: dict):
        task = {
            "id": "t",
            "type": "feat",
            "subject": "Test",
            "status": "pending",
            "metadata": {"custom_key": "value", "priority": "high", "sprintId": 3},
        }
        jsonschema.validate(task, task_schema)


# === Full featured task ===
class TestFullFeaturedTask:
    def test_all_optional_fields(self, task_schema: dict):
        task = {
            "id": "feat-full-example",
            "type": "feat",
            "subject": "Add complete feature",
            "status": "in_progress",
            "description": "A detailed description",
            "owner": "implementer",
            "scope": "auth",
            "breaking": False,
            "branch": "feat/full-example",
            "blockedBy": ["fix-dep"],
            "blocks": ["feat-next"],
            "activeForm": "Implementing feature",
            "estimatedTokens": 50000,
            "maxTurns": 25,
            "testFirst": True,
            "assignableTo": ["implementer"],
            "permissionMode": "default",
            "tools": ["Read", "Write", "Bash"],
            "disallowedTools": ["WebSearch"],
            "skills": ["issues"],
            "mcpServers": [],
            "criteria": ["All tests pass", "ruff check clean"],
            "traceId": "trace-abc123",
            "relatedIssues": [12, 15],
            "relatedSkills": ["issues"],
            "metadata": {"priority": "high"},
        }
        jsonschema.validate(task, task_schema)


# === Lock schema ===
class TestLockSchema:
    def test_valid_lock(self, lock_schema: dict):
        lock = {
            "taskId": "feat-user-auth",
            "agent": "implementer",
            "lockedAt": "2026-02-06T12:00:00Z",
        }
        jsonschema.validate(lock, lock_schema)

    def test_lock_missing_taskid_fails(self, lock_schema: dict):
        lock = {"agent": "implementer", "lockedAt": "2026-02-06T12:00:00Z"}
        with pytest.raises(jsonschema.ValidationError):
            jsonschema.validate(lock, lock_schema)

    def test_lock_stale_sec_minimum(self, lock_schema: dict):
        lock = {
            "taskId": "t",
            "agent": "a",
            "lockedAt": "2026-02-06T12:00:00Z",
            "staleSec": 30,
        }
        with pytest.raises(jsonschema.ValidationError):
            jsonschema.validate(lock, lock_schema)

    def test_lock_commit_sha_pattern(self, lock_schema: dict):
        lock = {
            "taskId": "t",
            "agent": "a",
            "lockedAt": "2026-02-06T12:00:00Z",
            "commitSha": "abc123f",
        }
        jsonschema.validate(lock, lock_schema)

    def test_lock_invalid_sha_rejected(self, lock_schema: dict):
        lock = {
            "taskId": "t",
            "agent": "a",
            "lockedAt": "2026-02-06T12:00:00Z",
            "commitSha": "not-hex!",
        }
        with pytest.raises(jsonschema.ValidationError):
            jsonschema.validate(lock, lock_schema)


# === Progress schema ===
class TestProgressSchema:
    def test_valid_progress(self, progress_schema: dict):
        progress = {
            "lastUpdated": "2026-02-06T12:00:00Z",
            "currentFocus": "feat-user-auth",
            "recentlyCompleted": ["fix-null-deref"],
            "blocked": [
                {
                    "taskId": "feat-profile",
                    "blockedBy": ["feat-user-auth"],
                    "since": "2026-02-06T10:00:00Z",
                }
            ],
            "nextUp": ["refactor-db"],
            "sessionNotes": "OAuth done, JWT pending",
        }
        jsonschema.validate(progress, progress_schema)

    def test_minimal_progress(self, progress_schema: dict):
        progress = {"lastUpdated": "2026-02-06T12:00:00Z"}
        jsonschema.validate(progress, progress_schema)

    def test_blocked_requires_task_id(self, progress_schema: dict):
        progress = {
            "lastUpdated": "2026-02-06T12:00:00Z",
            "blocked": [{"blockedBy": ["x"]}],
        }
        with pytest.raises(jsonschema.ValidationError):
            jsonschema.validate(progress, progress_schema)
