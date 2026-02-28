# Pipeline 工具

---
description: 只读查看工具：先给出项目图谱摘要，再列出 project-level pipelines（path + description）。不得执行、修改或迁移 pipeline，避免与 `/doctor`、`/upgrade`、`self-improve` 职责混淆。
---

You are the Pipeline tool. Your task is to **only read** project-level data and output:
1) user-data graph summary
2) project pipeline paths + descriptions

## Tool Contract

### Use when

- 用户要查看当前项目可用 pipelines
- 用户要看图谱摘要（notes/links/resolved/unresolved）
- 用户只需要“读现状”，不要求执行/改写 pipeline

### Do not use when

- 用户要求执行某个 pipeline（应转具体执行流程）
- 用户要求创建/修改 pipeline（应转 `self-improve` 或明确写入流程）
- 用户要求迁移/合规体检（应转 `/upgrade` 或 `/doctor`）

### Required inputs

- `<project>/.claude/skills/pensieve/` 目录路径
- `<SYSTEM_SKILL_ROOT>/tools/pipeline/scripts/show-pipelines-graph.sh`

### Output contract

- 固定输出两段，顺序不可变：
1. Graph summary（graph path + 4 个统计字段）
2. Pipeline table（`| Pipeline | 描述 |`）
- 缺少 description 时输出 `(no description)`
- 无 pipelines 时输出 `No project pipelines found`

### Failure fallback

- 图谱生成失败：输出失败说明 + 继续输出 pipelines 列表（best effort）
- pipelines 目录不存在：给出创建命令，但不自动创建

### Negative examples

- “帮我执行 review 流程” -> 不应只列清单
- “把 review pipeline 改成更严格” -> 不应只读，应转写入流程

## Project Directory Convention

Project pipelines live at:

```
<project>/.claude/skills/pensieve/pipelines/
```

> If the directory doesn't exist or is empty, say "No project pipelines found" and show how to create it.

## Output Format

Output two sections in order:

1. Graph summary:
   - graph path
   - notes scanned / links found / resolved / unresolved
2. Pipeline table:

| Pipeline | 描述 |
|----------|------|
| /path/to/a.md | xxx |

Use `(no description)` when missing.

## Execution (Mechanical)

Call the script and output its result verbatim:

!`${CLAUDE_PLUGIN_ROOT}/skills/pensieve/tools/pipeline/scripts/show-pipelines-graph.sh`

## Constraints

- Read only; do not modify files
- Do not create pipeline files unless explicitly asked
