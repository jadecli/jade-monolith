"""Parse TASK.md files with YAML frontmatter."""
from __future__ import annotations

import re
from pathlib import Path
from typing import Any

import yaml

FRONTMATTER_RE = re.compile(r"^---\s*\n(.*?)\n---\s*\n?(.*)", re.DOTALL)


class ParseError(Exception):
    """Raised when a TASK.md file cannot be parsed."""


def parse_frontmatter(content: str) -> dict[str, Any]:
    """Extract YAML frontmatter from markdown content.

    Returns the parsed frontmatter as a dict.
    Raises ParseError if frontmatter is missing or malformed.
    """
    match = FRONTMATTER_RE.match(content)
    if not match:
        raise ParseError("No YAML frontmatter found (expected --- delimiters)")

    yaml_text = match.group(1)
    try:
        data = yaml.safe_load(yaml_text)
    except yaml.YAMLError as e:
        raise ParseError(f"Invalid YAML in frontmatter: {e}") from e

    if not isinstance(data, dict):
        raise ParseError(f"Frontmatter must be a mapping, got {type(data).__name__}")

    return data


def parse_body(content: str) -> str:
    """Extract the markdown body after frontmatter."""
    match = FRONTMATTER_RE.match(content)
    if not match:
        return content
    return match.group(2).strip()


def parse_task(path: Path) -> dict[str, Any]:
    """Parse a single TASK.md file.

    Returns a dict with 'frontmatter' (dict) and 'body' (str) keys.
    Raises ParseError if the file cannot be parsed.
    """
    if not path.exists():
        raise ParseError(f"File not found: {path}")

    content = path.read_text(encoding="utf-8")
    frontmatter = parse_frontmatter(content)
    body = parse_body(content)
    return {"frontmatter": frontmatter, "body": body}


def parse_directory(root: Path) -> list[dict[str, Any]]:
    """Parse all TASK.md files under an .agent-tasks/tasks/ directory.

    Expects structure: root/tasks/{id}/TASK.md
    Returns a list of parsed tasks, each with 'frontmatter', 'body', and 'path' keys.
    """
    tasks_dir = root / "tasks"
    if not tasks_dir.is_dir():
        return []

    results = []
    for task_dir in sorted(tasks_dir.iterdir()):
        task_file = task_dir / "TASK.md"
        if task_file.is_file():
            try:
                parsed = parse_task(task_file)
                parsed["path"] = str(task_file)
                results.append(parsed)
            except ParseError:
                continue  # Skip unparseable files

    return results
