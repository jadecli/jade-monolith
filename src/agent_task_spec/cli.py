"""ATS CLI — manage Agent Task Spec tasks from the command line."""
from __future__ import annotations

import argparse
import json
import sys
from datetime import UTC, datetime
from pathlib import Path

from agent_task_spec.index_generator import generate_index, write_index
from agent_task_spec.parser import ParseError, parse_directory, parse_task


def _find_root(start: Path | None = None) -> Path:
    """Find the .agent-tasks directory, searching upward from start."""
    if start is None:
        start = Path.cwd()
    current = start
    while current != current.parent:
        candidate = current / ".agent-tasks"
        if candidate.is_dir():
            return candidate
        current = current.parent
    # Default: create at project root's .agent-tasks
    return start / ".agent-tasks"


def cmd_init(args: argparse.Namespace) -> int:
    """Initialize an .agent-tasks directory."""
    root = Path(args.root) if args.root else Path.cwd() / ".agent-tasks"
    (root / "tasks").mkdir(parents=True, exist_ok=True)
    (root / "locks").mkdir(parents=True, exist_ok=True)

    # Write initial progress.json
    progress = {
        "lastUpdated": datetime.now(UTC).isoformat().replace("+00:00", "Z"),
        "sessionNotes": "ATS initialized",
    }
    (root / "progress.json").write_text(
        json.dumps(progress, indent=2) + "\n", encoding="utf-8"
    )

    # Generate empty index
    write_index(root)

    print(f"Initialized ATS at {root}")
    return 0


def cmd_list(args: argparse.Namespace) -> int:
    """List all tasks with status."""
    root = _find_root(Path(args.root) if args.root else None)
    tasks = parse_directory(root)

    if not tasks:
        print("No tasks found.")
        return 0

    if args.json:
        index = generate_index(root)
        print(json.dumps(index, indent=2))
        return 0

    # Filter by status if requested
    if args.status:
        tasks = [t for t in tasks if t["frontmatter"].get("status") == args.status]

    # Table output
    print(f"{'ID':<30} {'TYPE':<8} {'STATUS':<12} {'OWNER':<15} SUBJECT")
    print("-" * 100)
    for t in tasks:
        fm = t["frontmatter"]
        print(
            f"{fm.get('id', '?'):<30} "
            f"{fm.get('type', '?'):<8} "
            f"{fm.get('status', '?'):<12} "
            f"{fm.get('owner', '-'):<15} "
            f"{fm.get('subject', '?')}"
        )

    return 0


def cmd_show(args: argparse.Namespace) -> int:
    """Show a single task in detail."""
    root = _find_root(Path(args.root) if args.root else None)
    task_file = root / "tasks" / args.task_id / "TASK.md"

    try:
        task = parse_task(task_file)
    except ParseError as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1

    fm = task["frontmatter"]
    print(f"Task: {fm.get('id', '?')}")
    print(f"Type: {fm.get('type', '?')}")
    print(f"Subject: {fm.get('subject', '?')}")
    print(f"Status: {fm.get('status', '?')}")
    if fm.get("owner"):
        print(f"Owner: {fm['owner']}")
    if fm.get("scope"):
        print(f"Scope: {fm['scope']}")
    if fm.get("blockedBy"):
        print(f"Blocked by: {', '.join(fm['blockedBy'])}")
    if fm.get("criteria"):
        print("\nAcceptance Criteria:")
        for c in fm["criteria"]:
            print(f"  - {c}")
    if task["body"]:
        print(f"\n{task['body']}")

    return 0


def cmd_claim(args: argparse.Namespace) -> int:
    """Claim (lock) a task for an agent."""
    root = _find_root(Path(args.root) if args.root else None)
    locks_dir = root / "locks"
    locks_dir.mkdir(parents=True, exist_ok=True)

    lock_file = locks_dir / f"{args.task_id}.lock.json"
    if lock_file.exists():
        existing = json.loads(lock_file.read_text())
        print(
            f"Task {args.task_id} already locked by {existing['agent']} "
            f"since {existing['lockedAt']}",
            file=sys.stderr,
        )
        return 1

    # Verify task exists and is claimable
    task_file = root / "tasks" / args.task_id / "TASK.md"
    if not task_file.exists():
        print(f"Task {args.task_id} not found", file=sys.stderr)
        return 1

    try:
        task = parse_task(task_file)
    except ParseError as e:
        print(f"Error parsing task: {e}", file=sys.stderr)
        return 1

    status = task["frontmatter"].get("status", "pending")
    if status not in ("pending", "locked"):
        print(f"Task {args.task_id} is {status}, cannot claim", file=sys.stderr)
        return 1

    # Check assignableTo constraint
    assignable = task["frontmatter"].get("assignableTo")
    if assignable and args.agent not in assignable:
        print(
            f"Agent {args.agent} not in assignableTo: {assignable}",
            file=sys.stderr,
        )
        return 1

    # Write lock
    lock = {
        "taskId": args.task_id,
        "agent": args.agent,
        "lockedAt": datetime.now(UTC).isoformat().replace("+00:00", "Z"),
    }
    if args.stale_sec:
        lock["staleSec"] = args.stale_sec

    lock_file.write_text(json.dumps(lock, indent=2) + "\n", encoding="utf-8")
    print(f"Locked {args.task_id} for {args.agent}")

    # Update task status to locked
    _update_task_status(task_file, "locked")

    return 0


def cmd_release(args: argparse.Namespace) -> int:
    """Release (unlock) a task."""
    root = _find_root(Path(args.root) if args.root else None)
    lock_file = root / "locks" / f"{args.task_id}.lock.json"

    if not lock_file.exists():
        print(f"No lock found for {args.task_id}", file=sys.stderr)
        return 1

    lock = json.loads(lock_file.read_text())
    if args.agent and lock["agent"] != args.agent:
        print(
            f"Lock held by {lock['agent']}, not {args.agent}",
            file=sys.stderr,
        )
        return 1

    lock_file.unlink()
    print(f"Released lock on {args.task_id}")

    # Update task status back to pending
    task_file = root / "tasks" / args.task_id / "TASK.md"
    if task_file.exists():
        _update_task_status(task_file, "pending")

    return 0


def cmd_complete(args: argparse.Namespace) -> int:
    """Mark a task as completed and release its lock."""
    root = _find_root(Path(args.root) if args.root else None)

    task_file = root / "tasks" / args.task_id / "TASK.md"
    if not task_file.exists():
        print(f"Task {args.task_id} not found", file=sys.stderr)
        return 1

    _update_task_status(task_file, "completed")

    # Release lock if exists
    lock_file = root / "locks" / f"{args.task_id}.lock.json"
    if lock_file.exists():
        lock_file.unlink()

    # Regenerate index
    write_index(root)

    # Update progress
    _update_progress(root, args.task_id, "completed")

    print(f"Completed {args.task_id}")
    return 0


def cmd_sync(args: argparse.Namespace) -> int:
    """Sync tasks to GitHub issues."""
    from agent_task_spec.github_sync import sync_all_tasks

    root = _find_root(Path(args.root) if args.root else None)

    results = sync_all_tasks(args.repo, root, dry_run=args.dry_run)

    for r in results:
        prefix = "[dry-run] " if args.dry_run else ""
        num = f" (#{r['issue_number']})" if r.get("issue_number") else ""
        print(f"{prefix}{r['action']}: {r['task_id']}{num}")

    return 0


def cmd_index(args: argparse.Namespace) -> int:
    """Regenerate INDEX.json."""
    root = _find_root(Path(args.root) if args.root else None)
    output = write_index(root)
    print(f"Wrote {output}")
    return 0


def _update_task_status(task_file: Path, new_status: str) -> None:
    """Update the status field in a TASK.md frontmatter."""
    import re

    content = task_file.read_text(encoding="utf-8")
    updated = re.sub(
        r"^(status:\s*)(\S+)",
        f"\\g<1>{new_status}",
        content,
        count=1,
        flags=re.MULTILINE,
    )
    task_file.write_text(updated, encoding="utf-8")


def _update_progress(root: Path, task_id: str, action: str) -> None:
    """Append to progress.json."""
    progress_file = root / "progress.json"
    progress = json.loads(progress_file.read_text()) if progress_file.exists() else {}

    progress["lastUpdated"] = datetime.now(UTC).isoformat().replace("+00:00", "Z")

    if action == "completed":
        recently = progress.get("recentlyCompleted", [])
        if task_id not in recently:
            recently.append(task_id)
        progress["recentlyCompleted"] = recently
        if progress.get("currentFocus") == task_id:
            del progress["currentFocus"]

    progress_file.write_text(json.dumps(progress, indent=2) + "\n", encoding="utf-8")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="ats",
        description="Agent Task Spec — manage tasks for AI agent teams",
    )
    parser.add_argument("--root", help="Path to .agent-tasks directory")

    sub = parser.add_subparsers(dest="command")

    # init
    sub.add_parser("init", help="Initialize .agent-tasks directory")

    # list
    p_list = sub.add_parser("list", help="List tasks")
    p_list.add_argument("--status", help="Filter by status")
    p_list.add_argument("--json", action="store_true", help="JSON output")

    # show
    p_show = sub.add_parser("show", help="Show task details")
    p_show.add_argument("task_id", help="Task ID")

    # claim
    p_claim = sub.add_parser("claim", help="Claim a task for an agent")
    p_claim.add_argument("task_id", help="Task ID")
    p_claim.add_argument("--agent", required=True, help="Agent name")
    p_claim.add_argument("--stale-sec", type=int, help="Stale timeout in seconds")

    # release
    p_release = sub.add_parser("release", help="Release a task lock")
    p_release.add_argument("task_id", help="Task ID")
    p_release.add_argument("--agent", help="Agent name (for ownership check)")

    # complete
    p_complete = sub.add_parser("complete", help="Mark task completed")
    p_complete.add_argument("task_id", help="Task ID")

    # sync
    p_sync = sub.add_parser("sync", help="Sync tasks to GitHub issues")
    p_sync.add_argument("--repo", required=True, help="GitHub repo (owner/name)")
    p_sync.add_argument("--dry-run", action="store_true", help="Preview without changes")

    # index
    sub.add_parser("index", help="Regenerate INDEX.json")

    args = parser.parse_args(argv)
    if not args.command:
        parser.print_help()
        return 0

    commands = {
        "init": cmd_init,
        "list": cmd_list,
        "show": cmd_show,
        "claim": cmd_claim,
        "release": cmd_release,
        "complete": cmd_complete,
        "sync": cmd_sync,
        "index": cmd_index,
    }

    return commands[args.command](args)


if __name__ == "__main__":
    sys.exit(main())
