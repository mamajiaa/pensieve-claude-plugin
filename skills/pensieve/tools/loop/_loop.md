---
description: 仅在任务复杂且必须拆成多个可验证子任务时使用；主窗口负责编排、子代理逐任务执行。若目标未确认或任务很小仍开 loop，会引入不必要流程成本并放大上下文噪音。触发词：loop / use loop / loop mode / 循环执行。
---

# Loop 工具

> 工具边界见 `<SYSTEM_SKILL_ROOT>/references/tool-boundaries.md` | 共享规则见 `<SYSTEM_SKILL_ROOT>/references/shared-rules.md`

将复杂工作拆成可执行原子任务，在 Task 系统中按顺序推进。主窗口只做编排，每次仅分派一个子任务给子代理执行。

## Core Principles

- **Context isolation**: Each task runs in a subagent to prevent main window context explosion
- **Atomic tasks**: Each task should be independently executable and verifiable
- **Clean handoff**: Subagents execute one task and return; main window continues to the next task

## Tool Contract

### Use when

- 任务复杂，需要拆解为多个可验证子任务
- 需要长流程持续推进（主窗口按任务状态续跑）
- 需要隔离上下文，避免主窗口持续膨胀

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
- 无法满足"单任务可执行"粒度：继续拆分或补充上下文，不强行开跑

### Negative examples

- "改 1 个文案文件，顺便 loop" → 过度流程化，应直接完成
- "还没确认需求，先建 10 个任务" → 禁止，必须先完成 Phase 2 确认

---

## Phase 0: Simple Task Check

评估任务复杂度。满足以下全部条件时，**建议直接完成**：
- Only 1–2 files involved
- Scope is clear, no exploration needed
- Likely 1 task to finish

> This looks simple; finishing directly will be faster. Do you want to do it now or run a loop?

用户选直接完成 → 不开 loop。用户坚持 → 继续 Phase 1。

---

## Phase 1: Initialize

**Goal**: Prepare the loop directory before task splitting

```
bash <SYSTEM_SKILL_ROOT>/tools/loop/scripts/init-loop.sh <slug>
```

**slug**: short English identifier (e.g., `snake-game`, `auth-module`).

**IMPORTANT**: Do **not** run with `run_in_background: true`. You need `LOOP_DIR` immediately.

Script output (remember `LOOP_DIR`):
```
LOOP_DIR=.claude/skills/pensieve/loop/2026-01-27-login
```

---

## Phase 2: Capture Context

**Goal**: Document conversation context before task generation

1. Create `LOOP_DIR/_context.md`:

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

2. **Present context summary to user and confirm before proceeding**

3. **Create requirements/design docs as needed**:

   | Condition | Needed | Template |
   |----------|--------|----------|
   | Requirements unclear (goal/scope/constraints not confirmed) | requirements | `loop/REQUIREMENTS.template.md` |
   | Implementation not obvious | design | `loop/DESIGN.template.md` |

   Hard rule: only the two conditions above trigger document creation.

4. If loop likely produces `decision` or `pipeline`, prefill Context Links.

> 链接规则见 `<SYSTEM_SKILL_ROOT>/references/shared-rules.md` § 语义链接规则

---

## Phase 3: Generate Tasks

**Goal**: Break down work into atomic, executable tasks

**CRITICAL**: Do not proceed without user confirmation from Phase 2.

### Load maxims first (mandatory)

Read all project maxims from `<USER_DATA_ROOT>/maxims/*.md`. Use maxims to shape task boundaries and acceptance criteria.

**Hard rule**: Do not generate task lists before maxims are loaded.

### Get available pipelines

```bash
bash <SYSTEM_SKILL_ROOT>/tools/pipeline/scripts/list-pipelines.sh
```

If a relevant pipeline exists, read it and check for explicit task blueprint.

**Task blueprint detection**: Contains `## Task Blueprint` or ordered `### Task 1/2/3...` headings.

**Hard rule**:
- Blueprint exists → 1:1 ordered runtime tasks. Do not merge/split/reorder.
- No blueprint → normal task splitting.

### Task granularity standard

**Core test: Can an agent execute without asking questions?**

Each task must:
- Specify files/components to create or modify
- Include concrete build/change/test actions

### Actions

1. Read project maxims, extract constraints
2. Check relevant pipeline for blueprint
3. Blueprint → 1:1 mapping; else split with granularity standard
4. Ensure acceptance criteria aligned with maxims
5. Create tasks in Claude Task system (after Phase 2 confirmation)
6. Do not treat markdown checklist as task creation
7. Show concise snapshot (task id + subject), then create/run first task

---

## Phase 4: Main-Window Continuation

After first task creation, main window fetches next pending task and dispatches one subagent at a time until all tasks complete.

**Important**: Do not rely on hooks or background bind processes.

---

## Phase 5: Execute Tasks

**Goal**: Run each task via isolated subagents

1. Launch a general-purpose agent for the first pending task:

```
Task(
  subagent_type: "general-purpose",
  prompt: "Read .claude/skills/pensieve/loop/{date}-{slug}/_agent-prompt.md and execute task_id={id}"
)
```

The `_agent-prompt.md` (generated by init-loop.sh) includes:
- Role definition, loop context path, maxims paths, execution constraints

2. Subagent: TaskGet → execute → return
3. Main window checks task status, dispatches next pending task

---

## Phase 6: Wrap Up

1. All tasks complete → ask whether to run self-improve (`tools/self-improve/_self-improve.md`).
2. If loop produced `decision` or `pipeline`, ensure output includes linking per `<SYSTEM_SKILL_ROOT>/references/shared-rules.md`.

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
