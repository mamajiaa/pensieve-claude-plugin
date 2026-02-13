---
description: Auto-loop task execution. Trigger when user says "use loop", "loop mode", or similar.
---

# Loop Pipeline

You are orchestrating an automated task execution loop. Break complex work into discrete tasks, then execute them via subagents while the Stop Hook handles continuation.

## Core Principles

- **Context isolation**: Each task runs in a subagent to prevent main window context explosion
- **Atomic tasks**: Each task should be independently executable and verifiable
- **User confirmation**: Always confirm context understanding before generating tasks
- **Clean handoff**: Subagents execute one task and return; Stop Hook triggers next
- **Linkable outputs**: If a loop output becomes `decision` or `pipeline`, include at least one `[[...]]` link via `Based on/Leads to/Related`

## Tool Contract

### Use when

- Task is complex and needs splitting into multiple verifiable subtasks
- Need long-running auto-continuation (Stop Hook drives rhythm)
- Need context isolation to prevent main window bloat

### Do not use when

- Task involves only 1-2 files and can be done in a single step
- Goal is unclear or constraints are unconfirmed (clarify first, do not jump into loop)
- User explicitly asks to "work directly in the main window, no subagents"

### Required inputs

- Confirmed goal/scope/constraints (Phase 2 must confirm)
- `<SYSTEM_SKILL_ROOT>` and `<USER_DATA_ROOT>` paths
- `LOOP_DIR` (output by `init-loop.sh`)

### Output contract

- Phase 2 must output a context summary and get confirmation first
- Phase 3 must present the task list and get confirmation before creating the first real task
- During execution, advance only one task at a time; subagent returns immediately after completion

### Failure fallback

- `init-loop.sh` fails: stop and return error with fix suggestions — do not create tasks
- `Task` system error or taskListId lost: stop auto-continuation, prompt manual `end-loop.sh` or rebind
- Cannot achieve "single-task executable" granularity: keep splitting or add context — do not force-start

### Negative examples

- "Change 1 copy file, might as well loop" -> over-engineering, just do it directly
- "Haven't confirmed requirements, create 10 tasks first" -> forbidden, must complete Phase 2 confirmation first

> **Path notes**: The script paths below are relative to the plugin root (parent of `skills/pensieve/`). Scripts self‑locate and can run from any working directory.
>
> **Important**: In real installations, the plugin lives in Claude Code's plugin cache, not inside your repo.
> The SessionStart hook injects the absolute system skill path into context.
>
> Terms used below:
> - `<SYSTEM_SKILL_ROOT>`: injected system skill path (e.g. `/.../plugins/.../skills/pensieve`)
> - `<USER_DATA_ROOT>`: project user data directory (e.g. `<project>/.claude/pensieve`)

---

## Phase 0: Simple Task Check

**Before starting the loop, assess task complexity.**

If the task meets all of these, **recommend completing directly**:
- Only 1–2 files involved
- Scope is clear, no exploration needed
- Likely 1 task to finish

**Suggested phrasing**:
> This looks simple; finishing directly will be faster. Do you want to do it now or run a loop?

If user chooses direct completion → do not run loop
If user insists on loop → continue to Phase 1

---

## Phase 1: Initialize

**Goal**: Prepare the loop directory before task splitting

**Actions**:
1. Run the init script in prepare-only mode:
   ```
   bash <SYSTEM_SKILL_ROOT>/tools/loop/scripts/init-loop.sh <slug>
   ```
   **slug**: a short English identifier based on the task (e.g., `snake-game`, `auth-module`).

   **IMPORTANT**: Do **not** run this with `run_in_background: true`. You need the `LOOP_DIR` output immediately for Phase 2.

   Script output (remember `LOOP_DIR`):
   ```
   LOOP_DIR=.claude/pensieve/loop/2026-01-27-login
   ```

---

## Phase 2: Capture Context

**Goal**: Document the conversation context before task generation

**Actions**:
1. Create and write `LOOP_DIR/_context.md` (Phase 1 no longer creates a template file to avoid "Read before Write" friction):

```markdown
# Conversation Context

## Pre-Context

### Interaction History
| Turn | Model Attempt | User Feedback |
|------|----------------|---------------|
| 1 | ... | ... |

### Final Consensus
- Goal: XXX
- Scope: YYY
- Constraints: ZZZ

### Understanding & Assumptions
- Expected modules involved
- Expected implementation approach
- Expected difficulties

### Document References
| Type | Path |
|------|------|
| requirements | none / path |
| design | none / path |
| plan | none / path |
```

2. **Present the context summary to the user and confirm understanding before proceeding**

3. **Create requirements/design docs as needed** (use templates):

   | Condition | Needed | Template |
   |----------|--------|----------|
   | 6+ tasks / multi‑day / multi‑module | requirements | `loop/REQUIREMENTS.template.md` |
   | Multiple options / decision impacts later work | design | `loop/DESIGN.template.md` |

   After creation, fill the paths into `_context.md` under "Document References".

---

## Phase 3: Generate Tasks

**Goal**: Break down work into atomic, executable tasks

**CRITICAL**: Do not proceed without user confirmation from Phase 2.

### Load maxims first (mandatory)

Before splitting tasks, read project maxims from:
- `<USER_DATA_ROOT>/maxims/custom.md` (if present)
- Any other maxim files under `<USER_DATA_ROOT>/maxims/`

Use maxims to shape task boundaries and acceptance criteria.

**Hard rule**: Do not generate task lists before maxims are loaded.

### Get available pipelines (for task design)

Before splitting tasks, list all project pipelines and descriptions to see if any are reusable:

```bash
bash <SYSTEM_SKILL_ROOT>/tools/pipeline/scripts/list-pipelines.sh
```

If a relevant pipeline exists, read it first and check whether it contains an explicit task blueprint.

**Task blueprint detection**:
- Contains `## Task Blueprint`
- Contains ordered headings like `### Task 1`, `### Task 2`, `### Task 3`

**Hard rule**:
- If task blueprint exists, create runtime tasks in the same order with a 1:1 mapping.
- Do not merge/split/reorder unless user explicitly asks.
- If any detail is missing, fill it inside that mapped task instead of inventing new phases.
- Only when no explicit task blueprint exists, fall back to normal task splitting.

### Task granularity standard

**Core test: Can an agent execute without asking questions?**

- Yes → good granularity
- No → split further or add details

Each task must:
- Specify files/components to create or modify
- Include concrete build/change/test actions

### Actions

1. Read project maxims and extract constraints for task design
2. Check relevant pipeline for explicit task blueprint
3. If blueprint exists, create tasks with 1:1 ordered mapping; otherwise split tasks with the above granularity
4. Ensure each task has explicit acceptance criteria aligned with maxims
5. Create tasks incrementally (each task builds on the previous)
6. **Present the task list to the user for confirmation**
7. Create the first real task

---

## Phase 4: Activate Stop Hook

**Goal**: Ensure the real task list is bound to the loop marker

After the first real task is created, Stop Hook will auto-bind to the most recent active task list for this loop session.

Since `0.3.2`, Stop Hook uses `/tmp/pensieve-loop-<taskListId>` marker to take over.

**Important**: No background process / `run_in_background: true` is needed.

---

## Phase 5: Execute Tasks

**Goal**: Run each task via isolated subagents

**Actions**:
1. Launch a general‑purpose agent for the first pending task:

```
Task(
  subagent_type: "general-purpose",
  prompt: "Read .claude/pensieve/loop/{date}-{slug}/_agent-prompt.md and execute task_id={id}"
)
```

The agent prompt template (`_agent-prompt.md`) is generated by init-loop.sh and includes:
- Role definition (Linus Torvalds)
- Loop context directory path + available context files
- Maxims file paths
- Execution flow and constraints

2. Subagent reads the prompt → TaskGet → execute → return
3. Stop Hook detects pending tasks → injects reinforcement → main window executes mechanically

---

## Phase 6: Wrap Up

**Goal**: End the loop and self‑improve based on execution experience

**Actions**:
1. When all tasks are complete, Stop Hook prompts the main window about self‑improve and provides the path to `tools/self-improve/_self-improve.md`. Regardless of the answer, the loop stops.
2. To end a loop early (`<taskListId>` is from Phase 4):

   ✅ **Correct**:
   ```bash
   bash <SYSTEM_SKILL_ROOT>/tools/loop/scripts/end-loop.sh <taskListId>
   ```

   ❌ **Incorrect** (missing task_list_id):
   ```bash
   bash <SYSTEM_SKILL_ROOT>/tools/loop/scripts/end-loop.sh
   ```

---

## Phase Selection Guide

| Task characteristics | Phase combination |
|---------------------|-------------------|
| Clear, small scope | tasks |
| Need code understanding | plan → tasks |
| Need technical design | plan → design → tasks |
| Unclear requirements | plan → requirements → design → tasks |

---

## Related Files

- `tools/loop/README.md` — Detailed documentation
- `<SYSTEM_SKILL_ROOT>/tools/loop/scripts/init-loop.sh` — Initialize directory + bind taskListId
- `<SYSTEM_SKILL_ROOT>/tools/loop/scripts/end-loop.sh` — End loop manually
