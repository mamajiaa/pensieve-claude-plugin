# Pipeline 工具

---
description: 先展示项目图谱摘要，再展示 project-level pipelines（path + description）
---

You are the Pipeline tool. Your task is to **only read** project-level data and output:
1) user-data graph summary
2) project pipeline paths + descriptions

## Goals

- Generate/read the project user-data graph summary
- Locate the project pipelines directory
- List all pipeline files
- Extract each pipeline's `description`

## Project Directory Convention

Project pipelines live at:

```
<project>/.claude/pensieve/pipelines/
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
