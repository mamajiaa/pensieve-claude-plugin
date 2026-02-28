---
description: 仅在任务复杂且必须拆成多个可验证子任务时使用；主窗口负责编排、子代理逐任务执行。若目标未确认或任务很小仍开 loop，会引入不必要流程成本并放大上下文噪音。触发词：loop / use loop / loop mode / 循环执行。
---

# Loop 工具

你负责把复杂工作拆成可执行原子任务，并在 Task 系统中按顺序推进。主窗口只做编排，每次仅分派一个子任务给子代理执行。

## Core Principles

- **Context isolation**: Each task runs in a subagent to prevent main window context explosion
- **Atomic tasks**: Each task should be independently executable and verifiable
- **User confirmation**: Always confirm context understanding before generating tasks
- **Clean handoff**: Subagents execute one task and return; main window continues to the next task
- **Linkable outputs**: If a loop output becomes `decision` or `pipeline`, include at least one `[[...]]` link via `基于/导致/相关`

## Tool Contract

### Use when

- 任务复杂，需要拆解为多个可验证子任务
- 需要长流程持续推进（主窗口按任务状态续跑）
- 需要隔离上下文，避免主窗口持续膨胀

### Do not use when

- 任务只涉及 1-2 个文件，单步可完成
- 目标不明确、约束未确认（先澄清，不直接开 loop）
- 用户明确要求“主窗口直接做，不启用子代理”

### Required inputs

- 已确认的目标/范围/约束（Phase 2 必须确认）
- `<SYSTEM_SKILL_ROOT>` 与 `<USER_DATA_ROOT>` 路径
- `LOOP_DIR`（由 `init-loop.sh` 输出）

### Output contract

- Phase 2 必须先输出上下文摘要并获得确认
- Phase 3 必须在 Claude Task 系统中直接创建真实任务（不可只输出 markdown/list）
- 执行期每次只推进一个任务，子代理完成后立即返回

### Failure fallback

- `init-loop.sh` 失败：停止推进并返回错误与修复建议，不创建任务
- `Task` 系统异常：停止推进并输出恢复建议（重试/缩小任务/手动收尾）
- 无法满足“单任务可执行”粒度：继续拆分或补充上下文，不强行开跑

### Negative examples

- “改 1 个文案文件，顺便 loop” -> 过度流程化，应直接完成
- “还没确认需求，先建 10 个任务” -> 禁止，必须先完成 Phase 2 确认

> **Path notes**: The script paths below are relative to the plugin root (parent of `skills/pensieve/`). Scripts self‑locate and can run from any working directory.
>
> **Important**: In real installations, the plugin lives in Claude Code's plugin cache, not inside your repo.
> Resolve the absolute system skill path via `CLAUDE_PLUGIN_ROOT/skills/pensieve`.
>
> Terms used below:
> - `<SYSTEM_SKILL_ROOT>`: resolved system skill path (e.g. `/.../plugins/.../skills/pensieve`)
> - `<USER_DATA_ROOT>`: project user data directory (e.g. `<project>/.claude/skills/pensieve`)

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
   LOOP_DIR=.claude/skills/pensieve/loop/2026-01-27-login
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

### Context Links (optional)
- 基于：[[前置决策或知识]]
- 导致：[[后续决策、流程或文档]]
- 相关：[[相关主题]]
```

2. **Present the context summary to the user and confirm understanding before proceeding**

3. **Create requirements/design docs as needed** (use templates):

   | Condition | Needed | Template |
   |----------|--------|----------|
   | Requirements are unclear (goal/scope/constraints not confirmed) | requirements | `loop/REQUIREMENTS.template.md` |
   | Implementation is not obvious | design | `loop/DESIGN.template.md` |

   Hard rule: only the two conditions above can trigger document creation. Do not use task count, duration, module count, or decision impact as independent triggers.

   After creation, fill the paths into `_context.md` under "Document References".

4. If the current loop is likely to produce a reusable `decision` or `pipeline`, prefill at least one entry in `Context Links`.

---

## Phase 3: Generate Tasks

**Goal**: Break down work into atomic, executable tasks

**CRITICAL**: Do not proceed without user confirmation from Phase 2.

### Load maxims first (mandatory)

Before splitting tasks, read all project maxims from:
- All maxim files under `<USER_DATA_ROOT>/maxims/` (`*.md`)

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
5. After Phase 2 confirmation, create tasks incrementally in Claude Task system (each task builds on the previous)
6. Do not treat a markdown checklist/bullet list as task creation
7. After creating tasks, show a concise snapshot (task id + subject), then create/run the first real task

---

## Phase 4: Main-Window Continuation

**Goal**: Continue the loop directly from the main window without hook automation

After the first real task is created, the main window should fetch the next pending task and dispatch one subagent at a time until all tasks complete.

**Important**: Do not rely on hooks or background bind processes.

---

## Phase 5: Execute Tasks

**Goal**: Run each task via isolated subagents

**Actions**:
1. Launch a general‑purpose agent for the first pending task:

```
Task(
  subagent_type: "general-purpose",
  prompt: "Read .claude/skills/pensieve/loop/{date}-{slug}/_agent-prompt.md and execute task_id={id}"
)
```

The agent prompt template (`_agent-prompt.md`) is generated by init-loop.sh and includes:
- Role definition (Linus Torvalds)
- Loop context directory path + available context files
- Maxims file paths
- Execution flow and constraints

2. Subagent reads the prompt → TaskGet → execute → return
3. 主窗口检查任务状态并继续分派下一个 pending 任务

---

## Phase 6: Wrap Up

**Goal**: End the loop and self-improve based on execution experience

**Actions**:
1. When all tasks are complete, the main window asks whether to run self-improve and provides the path `tools/self-improve/_self-improve.md`.
2. If this loop produced a new `decision` or `pipeline`, ensure the output note includes at least one `基于/导致/相关` link before wrap-up.

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
- `<SYSTEM_SKILL_ROOT>/tools/loop/scripts/init-loop.sh` — Initialize loop directory
