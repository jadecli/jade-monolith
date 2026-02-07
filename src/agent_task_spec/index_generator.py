"""Generate INDEX.json from parsed TASK.md files."""
from __future__ import annotations

import json
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

from agent_task_spec.parser import parse_directory

ATS_VERSION = "0.1.0"

VALID_STATUSES = ("pending", "locked", "in_progress", "blocked", "review", "completed", "rejected")

SUMMARY_FIELDS = (
    "id",
    "type",
    "subject",
    "status",
    "owner",
    "scope",
    "breaking",
    "blockedBy",
    "blocks",
    "assignableTo",
)


def _extract_summary(frontmatter: dict[str, Any]) -> dict[str, Any]:
    """Extract TaskSummary fields from a task frontmatter dict."""
    summary: dict[str, Any] = {}
    for field in SUMMARY_FIELDS:
        if field in frontmatter:
            summary[field] = frontmatter[field]
    return summary


def _compute_stats(tasks: list[dict[str, Any]]) -> dict[str, int]:
    """Compute aggregate status counts from task summaries."""
    stats = {status: 0 for status in VALID_STATUSES}
    stats["total"] = len(tasks)
    for task in tasks:
        status = task.get("status", "pending")
        if status in stats:
            stats[status] += 1
    return stats


def generate_index(root: Path, timestamp: datetime | None = None) -> dict[str, Any]:
    """Generate an INDEX.json dict from all TASK.md files under root.

    Args:
        root: The .agent-tasks directory containing tasks/.
        timestamp: Override for generatedAt (defaults to now UTC).

    Returns:
        A dict conforming to index.schema.json.
    """
    if timestamp is None:
        timestamp = datetime.now(UTC)

    parsed_tasks = parse_directory(root)
    summaries = [_extract_summary(t["frontmatter"]) for t in parsed_tasks]
    stats = _compute_stats(summaries)

    return {
        "version": ATS_VERSION,
        "generatedAt": timestamp.isoformat().replace("+00:00", "Z"),
        "stats": stats,
        "tasks": summaries,
    }


def write_index(root: Path, output: Path | None = None, timestamp: datetime | None = None) -> Path:
    """Generate and write INDEX.json to disk.

    Args:
        root: The .agent-tasks directory containing tasks/.
        output: Path for the output file. Defaults to root/INDEX.json.
        timestamp: Override for generatedAt.

    Returns:
        The path to the written file.
    """
    if output is None:
        output = root / "INDEX.json"

    index = generate_index(root, timestamp)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(index, indent=2) + "\n", encoding="utf-8")
    return output
