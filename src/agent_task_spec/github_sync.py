"""Sync ATS tasks to GitHub Issues and Projects via gh CLI."""
from __future__ import annotations

import json
import subprocess
from pathlib import Path
from typing import Any

from agent_task_spec.parser import parse_directory

# Map ATS status to GitHub issue state
_STATUS_TO_STATE = {
    "pending": "open",
    "locked": "open",
    "in_progress": "open",
    "blocked": "open",
    "review": "open",
    "completed": "closed",
    "rejected": "closed",
}

# Map ATS type to GitHub label
_TYPE_TO_LABEL = {
    "feat": "enhancement",
    "fix": "bug",
    "docs": "documentation",
    "test": "testing",
    "perf": "performance",
    "refactor": "refactor",
    "chore": "chore",
    "ci": "ci/cd",
    "build": "build",
    "style": "style",
    "revert": "revert",
}


def _run_gh(*args: str, check: bool = True) -> subprocess.CompletedProcess[str]:
    """Run a gh CLI command and return the result."""
    return subprocess.run(
        ["gh", *args],
        capture_output=True,
        text=True,
        check=check,
    )


def _find_existing_issue(repo: str, task_id: str) -> int | None:
    """Find an existing GitHub issue for a task ID by searching for the ATS marker."""
    result = _run_gh(
        "issue", "list",
        "--repo", repo,
        "--search", f"[ATS:{task_id}] in:body",
        "--json", "number,body",
        "--state", "all",
        "--limit", "5",
        check=False,
    )
    if result.returncode != 0:
        return None

    issues = json.loads(result.stdout) if result.stdout.strip() else []
    marker = f"[ATS:{task_id}]"
    for issue in issues:
        if marker in issue.get("body", ""):
            return issue["number"]
    return None


def _build_issue_body(task: dict[str, Any]) -> str:
    """Build GitHub issue body from a parsed task."""
    fm = task["frontmatter"]
    body_text = task.get("body", "")

    parts = [f"<!-- [ATS:{fm['id']}] — do not remove this marker -->"]
    parts.append("")

    if fm.get("owner"):
        parts.append(f"**Owner:** `{fm['owner']}`")
    if fm.get("scope"):
        parts.append(f"**Scope:** `{fm['scope']}`")
    if fm.get("assignableTo"):
        agents = ", ".join(f"`{a}`" for a in fm["assignableTo"])
        parts.append(f"**Assignable to:** {agents}")
    if fm.get("blockedBy"):
        blocked = ", ".join(f"`{b}`" for b in fm["blockedBy"])
        parts.append(f"**Blocked by:** {blocked}")
    if fm.get("criteria"):
        parts.append("")
        parts.append("### Acceptance Criteria")
        for c in fm["criteria"]:
            parts.append(f"- [ ] {c}")

    if body_text:
        parts.append("")
        parts.append("---")
        parts.append("")
        parts.append(body_text)

    return "\n".join(parts)


def sync_task_to_issue(
    repo: str,
    task: dict[str, Any],
    dry_run: bool = False,
) -> dict[str, Any]:
    """Sync a single ATS task to a GitHub issue.

    Returns a dict with keys: task_id, action (created|updated|skipped), issue_number.
    """
    fm = task["frontmatter"]
    task_id = fm["id"]
    task_type = fm.get("type", "chore")
    status = fm.get("status", "pending")

    title = f"[{task_type}] {fm['subject']}"
    body = _build_issue_body(task)
    label = _TYPE_TO_LABEL.get(task_type, "chore")
    state = _STATUS_TO_STATE.get(status, "open")

    existing = _find_existing_issue(repo, task_id)

    if dry_run:
        action = "would_update" if existing else "would_create"
        return {"task_id": task_id, "action": action, "issue_number": existing}

    if existing:
        # Update existing issue
        _run_gh(
            "issue", "edit", str(existing),
            "--repo", repo,
            "--title", title,
            "--body", body,
        )
        # Update state
        if state == "closed":
            _run_gh("issue", "close", str(existing), "--repo", repo, check=False)
        else:
            _run_gh("issue", "reopen", str(existing), "--repo", repo, check=False)

        return {"task_id": task_id, "action": "updated", "issue_number": existing}
    else:
        # Create new issue
        result = _run_gh(
            "issue", "create",
            "--repo", repo,
            "--title", title,
            "--body", body,
            "--label", label,
        )
        # Parse issue number from output URL
        issue_url = result.stdout.strip()
        issue_number = int(issue_url.rstrip("/").split("/")[-1]) if issue_url else 0

        # Close if already completed/rejected
        if state == "closed" and issue_number:
            _run_gh("issue", "close", str(issue_number), "--repo", repo, check=False)

        return {"task_id": task_id, "action": "created", "issue_number": issue_number}


def sync_all_tasks(
    repo: str,
    root: Path,
    dry_run: bool = False,
) -> list[dict[str, Any]]:
    """Sync all ATS tasks under root to GitHub issues.

    Args:
        repo: GitHub repo in owner/name format (e.g. "jadecli/jade-monolith").
        root: The .agent-tasks directory containing tasks/.
        dry_run: If True, don't actually create/update issues.

    Returns:
        List of sync result dicts.
    """
    tasks = parse_directory(root)
    results = []
    for task in tasks:
        result = sync_task_to_issue(repo, task, dry_run=dry_run)
        results.append(result)
    return results


def sync_issue_to_task(
    repo: str,
    issue_number: int,
    output_dir: Path,
) -> Path | None:
    """Pull a GitHub issue and create/update a local TASK.md.

    This enables bidirectional sync: changes on GitHub flow back to local tasks.
    Returns the path to the written TASK.md, or None if the issue has no ATS marker.
    """
    result = _run_gh(
        "issue", "view", str(issue_number),
        "--repo", repo,
        "--json", "title,body,state,labels",
    )
    issue = json.loads(result.stdout)

    body = issue.get("body", "")
    # Extract task ID from ATS marker
    import re
    marker_match = re.search(r"\[ATS:([a-z0-9-]+)\]", body)
    if not marker_match:
        return None

    task_id = marker_match.group(1)
    state = issue.get("state", "OPEN")

    # Map GitHub state back to ATS status (conservative: only update open/closed)
    status_map = {"OPEN": "pending", "CLOSED": "completed"}
    status = status_map.get(state, "pending")

    # Extract type from title pattern "[type] subject"
    title = issue.get("title", "")
    type_match = re.match(r"\[(\w+)\]\s*(.*)", title)
    task_type = type_match.group(1) if type_match else "chore"
    subject = type_match.group(2) if type_match else title

    # Write TASK.md
    task_dir = output_dir / "tasks" / task_id
    task_dir.mkdir(parents=True, exist_ok=True)
    task_file = task_dir / "TASK.md"

    import yaml
    frontmatter = {
        "id": task_id,
        "type": task_type,
        "subject": subject[:80],
        "status": status,
    }

    # Strip the ATS marker and metadata from body for the markdown section
    clean_body = re.sub(r"<!--.*?-->", "", body, flags=re.DOTALL).strip()
    # Remove the metadata header lines
    clean_body = re.sub(r"\*\*(Owner|Scope|Assignable to|Blocked by):\*\*[^\n]*\n?", "", clean_body)
    clean_body = clean_body.strip().lstrip("-").strip()

    content = "---\n" + yaml.dump(frontmatter, default_flow_style=False).strip() + "\n---\n\n"
    if clean_body:
        content += clean_body + "\n"

    task_file.write_text(content, encoding="utf-8")
    return task_file
