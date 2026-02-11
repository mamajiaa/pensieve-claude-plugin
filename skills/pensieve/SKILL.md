---
name: pensieve
description: 当用户表达任何意图时**立即加载**此 skill。系统能力（tools/knowledge/scripts）位于插件内，随插件更新维护。用户数据必须位于项目级 `.claude/pensieve/`，插件不会覆盖。用户要改进 Pensieve 系统（插件内容）时，**必须**使用 Self‑Improve 工具（`tools/self-improve/_self-improve.md`）。
---

# Pensieve

将用户意图路由到正确的工具或 pipeline。

## 设计约定

- **系统能力（随插件更新）**：位于 `skills/pensieve/`
  - tools / scripts / system knowledge / 格式 README
  - **不内置 pipelines / maxims 内容**
- **用户数据（项目级，永不覆盖）**：`.claude/pensieve/`
  - `maxims/`：团队准则（每条准则一个文件）
  - `decisions/`：项目决策记录
  - `knowledge/`：外部参考知识
  - `pipelines/`：项目 pipelines（安装时种子化）
  - `loop/`：loop 运行产物（每次 loop 一个目录）

## 内置工具（5）

### 1) Loop 工具

**适用场景**：
- 任务复杂，需要拆解并自动循环执行

**入口**：
- Command：`commands/loop.md`
- Tool file：`tools/loop/_loop.md`

**触发词**：
- `loop` / "use loop"

### 2) Self‑Improve 工具

**适用场景**：
- 用户要求改进 Pensieve（pipelines/scripts/rules/behavior）
- loop 结束后做复盘与改进

**入口**：
- Command：`commands/selfimprove.md`
- Tool file：`tools/self-improve/_self-improve.md`

**触发词**：
- "self‑improve" / "improve Pensieve"

### 3) Pipeline 工具

**适用场景**：
- 用户想查看当前项目可用 pipelines

**入口**：
- Command：`commands/pipeline.md`
- Tool file：`tools/pipeline/_pipeline.md`

**触发词**：
- "pipeline" / "use pipeline"

### 4) Doctor 工具

**适用场景**：
- 升级后的强制验证（结构/格式合规）
- 安装后的可选快速体检
- 用户要求做用户数据体检

**入口**：
- Command：`commands/doctor.md`
- Tool file：`tools/doctor/_doctor.md`

**触发词**：
- "doctor" / "health check" / "检查格式" / "检查迁移"

### 5) Upgrade 工具

**适用场景**：
- 用户需要把历史数据迁移到 `.claude/pensieve/`
- 用户询问目标用户数据结构

**入口**：
- Command：`commands/upgrade.md`
- Tool file：`tools/upgrade/_upgrade.md`

**触发词**：
- "upgrade" / "migrate user data"

---

SessionStart 会在运行时注入**系统能力路径**与**项目用户数据路径**，作为单一事实源。
