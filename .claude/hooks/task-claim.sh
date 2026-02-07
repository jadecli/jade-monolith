#!/usr/bin/env bash
# task-claim.sh — ATS claim validation hook
# Called before an agent begins working on a task.
#
# Environment:
#   ATS_ROOT     — path to .agent-tasks directory
#   ATS_TASK_ID  — the task being claimed
#   ATS_AGENT    — the agent claiming it
#
# Exit codes:
#   0 — allow the claim
#   2 — reject with feedback

set -euo pipefail

ATS_ROOT="${ATS_ROOT:-.agent-tasks}"
TASK_ID="${ATS_TASK_ID:-}"
AGENT="${ATS_AGENT:-unknown}"

if [[ -z "$TASK_ID" ]]; then
    exit 0
fi

TASK_FILE="$ATS_ROOT/tasks/$TASK_ID/TASK.md"
LOCK_FILE="$ATS_ROOT/locks/${TASK_ID}.lock.json"

# Check task exists
if [[ ! -f "$TASK_FILE" ]]; then
    echo "REJECT: Task $TASK_ID not found at $TASK_FILE" >&2
    exit 2
fi

# Check not already locked by another agent
if [[ -f "$LOCK_FILE" ]]; then
    LOCK_AGENT=$(python3 -c "import json; print(json.load(open('$LOCK_FILE'))['agent'])" 2>/dev/null || echo "unknown")
    if [[ "$LOCK_AGENT" != "$AGENT" ]]; then
        echo "REJECT: Task $TASK_ID already locked by $LOCK_AGENT" >&2
        exit 2
    fi
fi

# Check task is claimable (pending or locked by same agent)
STATUS=$(python3 -c "
import yaml, re
content = open('$TASK_FILE').read()
m = re.match(r'^---\s*\n(.*?)\n---', content, re.DOTALL)
if m:
    fm = yaml.safe_load(m.group(1))
    print(fm.get('status', 'pending'))
else:
    print('unknown')
" 2>/dev/null || echo "unknown")

if [[ "$STATUS" != "pending" && "$STATUS" != "locked" ]]; then
    echo "REJECT: Task $TASK_ID has status '$STATUS', must be 'pending' or 'locked'" >&2
    exit 2
fi

# Check blockedBy — are all blocking tasks completed?
BLOCKED=$(python3 -c "
import yaml, re
from pathlib import Path

content = open('$TASK_FILE').read()
m = re.match(r'^---\s*\n(.*?)\n---', content, re.DOTALL)
if not m:
    exit()
fm = yaml.safe_load(m.group(1))
blocked_by = fm.get('blockedBy', [])

root = Path('$ATS_ROOT')
for dep_id in blocked_by:
    dep_file = root / 'tasks' / dep_id / 'TASK.md'
    if not dep_file.is_file():
        print(f'MISSING:{dep_id}')
        continue
    dep_content = dep_file.read_text()
    dm = re.match(r'^---\s*\n(.*?)\n---', dep_content, re.DOTALL)
    if dm:
        dep_fm = yaml.safe_load(dm.group(1))
        if dep_fm.get('status') != 'completed':
            print(f'PENDING:{dep_id}={dep_fm.get(\"status\", \"unknown\")}')
" 2>/dev/null || true)

if [[ -n "$BLOCKED" ]]; then
    echo "REJECT: Task $TASK_ID has unresolved dependencies:" >&2
    echo "$BLOCKED" >&2
    exit 2
fi

# Check assignableTo constraint
ASSIGNABLE_CHECK=$(python3 -c "
import yaml, re
content = open('$TASK_FILE').read()
m = re.match(r'^---\s*\n(.*?)\n---', content, re.DOTALL)
if m:
    fm = yaml.safe_load(m.group(1))
    assignable = fm.get('assignableTo', [])
    if assignable and '$AGENT' not in assignable:
        print(f'NOT_ASSIGNABLE:allowed={assignable}')
" 2>/dev/null || true)

if [[ -n "$ASSIGNABLE_CHECK" ]]; then
    echo "REJECT: Agent $AGENT not in assignableTo for task $TASK_ID" >&2
    echo "$ASSIGNABLE_CHECK" >&2
    exit 2
fi

echo "Task $TASK_ID claimed by $AGENT"
exit 0
