---
description: Break complex tasks into verifiable subtasks; main window orchestrates, subagents execute one at a time. Trigger words: loop, use loop, loop mode.
---

# Loop Tool

> Tool boundaries: see `<SYSTEM_SKILL_ROOT>/references/tool-boundaries.md` | Shared rules: see `<SYSTEM_SKILL_ROOT>/references/shared-rules.md`

Break complex work into executable atomic tasks, advancing them sequentially in the Task system. The main window only orchestrates; each time it dispatches a single subtask to a subagent for execution.

## Core Principles

- **Context isolation**: Each task runs in a subagent to prevent main window context explosion
- **Atomic tasks**: Each task should be independently executable and verifiable
- **Clean handoff**: Subagents execute one task and return; main window continues dispatching the next

## Tool Contract

### Use when

- Task is complex and needs splitting into multiple verifiable subtasks
- Need long-running continuous progress (main window continues based on task state)
- Need context isolation to prevent main window bloat

### Failure fallback

- `init-loop.sh` fails: stop and return error with fix suggestions
- `Task` system error: stop and output recovery suggestions (retry / reduce task scope / manual wrap-up)
- Cannot achieve "single-task executable" granularity: keep splitting or add context

---

## Phase 0: Simple Task Check

**Goal**: Assess task complexity to avoid unnecessary process overhead for simple tasks

**Actions**:
1. If the task meets all of these, **recommend completing directly**: only 1-2 files involved, scope is clear with no exploration needed, one task can finish it
2. Suggest to the user: "This task looks simple; completing it directly will be faster. Do you want to do it now or use a loop?"
3. User chooses direct completion -> do not start loop; user insists -> continue to Phase 1

---

## Phase 1: Initialize

**Goal**: Prepare the loop directory before task splitting

**Actions**:
1. Run the init script (do not use `run_in_background: true`; subsequent steps need `LOOP_DIR` immediately):
```
bash <SYSTEM_SKILL_ROOT>/tools/loop/scripts/init-loop.sh <slug>
```
2. **slug**: a short English identifier (e.g., `snake-game`, `auth-module`)
3. Remember the `LOOP_DIR` from the script output:
```
LOOP_DIR=.claude/skills/pensieve/loop/2026-01-27-login
```

---

## Phase 2: Capture Context

**Goal**: Document the conversation context before task generation, ensuring task splitting is based on consensus rather than assumptions

**Actions**:
1. Create `LOOP_DIR/_context.md` with the following summary fields:
   - **Interaction History**: turns / model attempts / user feedback (table)
   - **Final Consensus**: goal, scope, constraints
   - **Understanding & Assumptions**: expected modules, implementation approach, difficulties
   - **Document References**: requirements doc / design doc / plan doc (path or "none")
   - **Context Links** (optional): Based on / Leads to / Related (`[[link]]` format)
2. Present the context summary to the user and **confirm before proceeding**
3. Create documents as needed (only when the following conditions trigger):

   | Condition | Needed | Template |
   |-----------|--------|----------|
   | Requirements unclear (goal/scope/constraints unconfirmed) | requirements doc | `loop/REQUIREMENTS.template.md` |
   | Implementation not obvious | design doc | `loop/DESIGN.template.md` |

4. If the loop may produce a `decision` or `pipeline`, pre-fill context links (rules in `<SYSTEM_SKILL_ROOT>/references/shared-rules.md` section "Semantic Link Rules")

---

## Phase 3: Generate Tasks

**Goal**: Break work into atomic, executable tasks (prerequisite: user confirmed in Phase 2)

**Actions**:
1. Read all project maxims under `<USER_DATA_ROOT>/maxims/*.md`; use maxims to constrain task boundaries and acceptance criteria
2. Read all `*.md` under `<USER_DATA_ROOT>/pipelines/` and check whether any contain a task blueprint (`## Task Blueprint` or ordered `### Task 1/2/3...` headings)
   - Blueprint exists -> create runtime tasks with 1:1 ordered mapping
   - No blueprint -> split by granularity standard
3. **Granularity standard**: Can a subagent execute without asking questions? Each task must specify target files/components and include concrete build/modify/test actions
4. Ensure acceptance criteria align with maxims
5. Create tasks in the Claude Task system (a markdown checklist is not the same as task creation; only tasks created in the Task system count)
6. Present a brief snapshot (task id + subject), then create/run the first task

---

## Phase 4: Main Window Continuation

**Goal**: Continue progress until all tasks are complete

**Actions**:
1. After the first task is created, the main window picks the next pending task and dispatches one subagent at a time
2. No hooks or background processes are relied upon; the main window actively polls task state

---

## Phase 5: Execute Tasks

**Goal**: Execute tasks one by one via isolated subagents

**Actions**:
1. Launch a general-purpose subagent for the first pending task:
```
Task(
  subagent_type: "general-purpose",
  prompt: "Read .claude/skills/pensieve/loop/{date}-{slug}/_agent-prompt.md and execute task_id={id}"
)
```
   `_agent-prompt.md` (generated by init-loop.sh) includes role definition, loop context directory path, maxims paths, and execution constraints.
2. Subagent: TaskGet -> execute -> return
3. Main window checks task state and dispatches the next pending task

---

## Phase 6: Wrap Up

**Goal**: Complete knowledge capture and writing

**Actions**:
1. All tasks complete -> ask whether to run self-improve (`tools/self-improve/_self-improve.md`)
2. If the loop produced a `decision` or `pipeline`, ensure the output includes links (see `<SYSTEM_SKILL_ROOT>/references/shared-rules.md`)

---

## Phase Selection Guide

| Task characteristics | Phase combination |
|---------------------|-------------------|
| Clear, small scope | generate tasks directly |
| Need code understanding | plan -> tasks |
| Need technical design | plan -> design -> tasks |
| Unclear requirements | plan -> requirements -> design -> tasks |

---

## Related Files

- `tools/loop/README.md` -- Detailed documentation
- `<SYSTEM_SKILL_ROOT>/tools/loop/scripts/init-loop.sh` -- Initialize loop directory
