# Context Management Rule

## Model Configuration

- **Model:** claude-opus-4-6 with adaptive thinking (default)
- **max_turns:** 25 per agent, 15 for retries
- **Context window:** 200K tokens standard

## Wrap-Up Protocol (170K Threshold)

When context usage approaches 170K tokens:

1. **Finish current task only.** Do not start new tasks.
2. **Write handoff summary** (max 500 tokens) to `.claude/tasks/context-handoff.md`:
   ```markdown
   # Context Handoff — <date>
   ## Completed
   - task-id-1: one-line summary
   - task-id-2: one-line summary
   ## Remaining
   - task-id-3: status + blocker if any
   ## Modified Files
   - packages/foo/src/bar.ts
   ## Decisions Made
   - Chose X over Y because Z
   ```
3. **Commit all uncommitted work.**
4. **Update task statuses** in tasks.json.
5. **Signal session end** — do not attempt more work.

## Session Start Protocol

1. Read `.claude/tasks/context-handoff.md` if it exists
2. Read `.claude/tasks/tasks.json` for current task state
3. Run `./scripts/git-status-all.sh --json` for repo health
4. Pick the highest-priority unblocked task

## Agent Retry Protocol

- **Failure 1:** Retry with full 25 turns + 500-token failure summary
- **Failure 2:** Retry with 15 turns + compressed context
- **Failure 3:** Write diagnostic to task description, set status to `blocked`, escalate to human
