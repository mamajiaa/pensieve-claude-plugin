# Pipeline Tool

---
description: List project-level pipelines (path + description)
---

You are the Pipeline tool. Your task is to **only read** project-level data and output:
1) user-data graph summary
2) project pipeline paths + descriptions

## Tool Contract

### Use when

- User wants to view available pipelines for the current project
- User wants to see the graph summary (notes/links/resolved/unresolved)
- User only needs to "read current state" — no execution or modification of pipelines

### Do not use when

- User requests executing a specific pipeline (route to the concrete execution flow)
- User requests creating/modifying a pipeline (route to `/selfimprove` or explicit write flow)
- User requests migration/compliance check (route to `/upgrade` or `/doctor`)

### Required inputs

- `<project>/.claude/pensieve/` directory path
- `<SYSTEM_SKILL_ROOT>/tools/pipeline/scripts/show-pipelines-graph.sh`

### Output contract

- Fixed two-section output, order must not change:
1. Graph summary (graph path + 4 stats fields)
2. Pipeline table (`| Pipeline | Description |`)
- Use `(no description)` when description is missing
- Output `No project pipelines found` when no pipelines exist

### Failure fallback

- Graph generation fails: output failure note + continue with pipeline list (best effort)
- Pipelines directory missing: show creation command but do not auto-create

### Negative examples

- "Run the review workflow for me" -> should not just list
- "Make the review pipeline stricter" -> should not just read, route to write flow

## Project Directory Convention

Project pipelines live at:

```
<project>/.claude/pensieve/pipelines/
```

> If the directory doesn't exist or is empty, say "No project pipelines found" and show how to create it.

## Output Format

Output a concise table:

| Pipeline | Description |
|----------|-------------|
| /path/to/a.md | xxx |

Use `(no description)` when missing.

## Execution (Mechanical)

Call the script and output its result verbatim:

!`${CLAUDE_PLUGIN_ROOT}/skills/pensieve/tools/pipeline/scripts/list-pipelines.sh`

## Constraints

- Read only; do not modify files
- Do not create pipeline files unless explicitly asked
