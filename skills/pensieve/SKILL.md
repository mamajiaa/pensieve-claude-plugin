---
name: pensieve
description: 当用户表达任何意图时**立即加载**此 skill。系统能力（tools/knowledge/scripts）位于插件内，随插件更新维护。用户数据必须位于项目级 `.claude/pensieve/`，插件不会覆盖。用户要改进 Pensieve 系统（插件内容）时，**必须**使用 Self‑Improve 工具（`tools/self-improve/_self-improve.md`）。
---

# Pensieve

Route user intent to the right tool/pipeline.

## Design conventions

- **System capability (updated via plugin)**: inside `skills/pensieve/`
  - tools / scripts / system knowledge / format READMEs
  - **No built‑in pipelines / maxims content**
- **User data (project-level, never overwritten)**: `.claude/pensieve/`
  - `maxims/`: your team principles (e.g. `custom.md`)
  - `decisions/`: project decision records
  - `knowledge/`: external references you add
  - `pipelines/`: project pipelines (seeded on install)
  - `loop/`: loop run outputs (one dir per loop)

## Built-in Tools (4)

### 1) Loop Tool

**When to use**:
- The task is complex and needs split + auto‑loop execution

**Entry**:
- Command: `commands/loop.md`
- Tool file: `tools/loop/_loop.md`

**Triggers**:
- `loop` / "use loop"

### 2) Self‑Improve Tool

**When to use**:
- User asks to improve Pensieve (pipelines/scripts/rules/behavior)
- After a loop ends for feedback & improvement

**Entry**:
- Command: `commands/selfimprove.md`
- Tool file: `tools/self-improve/_self-improve.md`

**Triggers**:
- "self‑improve" / "improve Pensieve"

### 3) Pipeline Tool

**When to use**:
- User wants to list pipelines for the current project

**Entry**:
- Command: `commands/pipeline.md`
- Tool file: `tools/pipeline/_pipeline.md`

**Triggers**:
- "pipeline" / "use pipeline"

### 4) Upgrade Tool

**When to use**:
- User needs to migrate legacy data into `.claude/pensieve/`
- User asks for the ideal user-data structure

**Entry**:
- Command: `commands/upgrade.md`
- Tool file: `tools/upgrade/_upgrade.md`

**Triggers**:
- "upgrade" / "migrate user data"

---

SessionStart injects the **system capability path** and **project user‑data path** into context as the single source of truth at runtime.
