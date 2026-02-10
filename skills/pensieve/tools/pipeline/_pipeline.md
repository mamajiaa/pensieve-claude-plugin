# Pipeline 工具

---
description: List project-level pipelines (path + description)
---

You are the Pipeline tool. Your task is to **only read** project-level pipelines and output their paths and descriptions.

## Goals

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

Output a concise table:

| Pipeline | 描述 |
|----------|------|
| /path/to/a.md | xxx |

Use `(no description)` when missing.

## Execution (Mechanical)

Call the script and output its result verbatim:

!`${CLAUDE_PLUGIN_ROOT}/skills/pensieve/tools/pipeline/scripts/list-pipelines.sh`

## Constraints

- Read only; do not modify files
- Do not create pipeline files unless explicitly asked
