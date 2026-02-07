---
name: swarm-debug
description: >
  Launch a debugging swarm to investigate issues with competing hypotheses.
  Multiple diagnostic agents test different theories in parallel, share findings,
  and converge on the root cause through adversarial debate.
argument-hint: "[bug description or error message]"
disable-model-invocation: true
context: fork
agent: swarm-orchestrator
allowed-tools: Task, TaskCreate, TaskList, TaskUpdate, TaskGet, Read, Edit, Glob, Grep, Bash, AskUserQuestion
---

# Debug Swarm Protocol

Launch a multi-hypothesis debugging investigation.

## Bug Report
$ARGUMENTS

## Available Diagnostic Agents

| Agent | Specialty | Model | Can Edit |
|-------|-----------|-------|----------|
| debugger | General debugging, logging | opus | Yes (Edit only) |
| log-analyzer | Log parsing & correlation | sonnet | No |
| error-tracker | Error categorization | sonnet | No |
| memory-profiler | Heap & allocation | sonnet | No |
| cpu-profiler | CPU hotspots & threads | sonnet | No |
| network-debugger | HTTP, DNS, TLS | sonnet | No |
| race-condition-detector | Concurrency bugs | opus | No |
| deadlock-detector | Lock contention | sonnet | No |
| regression-detective | Git bisect, behavioral | sonnet | No |
| root-cause-analyzer | 5-why, fault tree | opus | No |

## Competing Hypotheses Strategy (Kimi K2-inspired)

This swarm uses **adversarial debugging**:

1. **Form hypotheses** — each diagnostic agent proposes a theory
2. **Test in parallel** — each agent investigates its own theory
3. **Challenge each other** — agents try to disprove competing theories
4. **Converge** — the theory that survives scrutiny is the root cause
5. **Fix** — the debugger agent implements the minimal fix

## Execution

### Phase 1: Triage
1. Read the error/bug report
2. Identify the domain (memory, network, concurrency, logic, etc.)
3. Select 3-5 diagnostic agents

### Phase 2: Hypothesis Generation
Each agent independently:
- Examines the evidence
- Forms a hypothesis about the root cause
- Identifies what evidence would confirm or disprove it

### Phase 3: Parallel Investigation
Agents investigate simultaneously:
- Read relevant code
- Analyze logs and error output
- Run diagnostic commands
- Collect evidence for/against their hypothesis

### Phase 4: Debate
Agents share findings and challenge each other:
- Present evidence
- Identify weaknesses in other hypotheses
- Refine or abandon theories based on counter-evidence

### Phase 5: Convergence
- Select the hypothesis with strongest evidence
- Identify the root cause with specific file:line reference
- Propose minimal fix

### Phase 6: Fix
The debugger agent implements the minimal fix:
- Add strategic logging if needed
- Apply the code fix
- Run tests to verify

## Debug Report Template

```markdown
# Debug Report

## Bug
[Original description]

## Root Cause
[file:line] — [explanation]

## Hypotheses Tested
1. [Hypothesis] — [CONFIRMED/DISPROVED] — [evidence]
2. [Hypothesis] — [CONFIRMED/DISPROVED] — [evidence]

## Fix Applied
[Description of fix, files modified]

## Verification
- Tests: PASS/FAIL
- Reproduction: [can no longer reproduce]

## Prevention
[How to prevent this class of bug in the future]
```
