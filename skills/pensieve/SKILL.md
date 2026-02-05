---
name: pensieve
description: 当用户表达任何意图时**立即加载**此 skill。系统能力（tools/knowledge/scripts）位于插件内，随插件更新维护。用户数据必须位于项目级 `.claude/pensieve/`，插件不会覆盖。用户要改进 Pensieve 系统（插件内容）时，**必须**使用 Self‑Improve 工具（`tools/self-improve/_self-improve.md`）。
---

# Pensieve

根据用户意图路由到对应 pipeline。

## 设计约定

- **系统能力（随插件更新）**：位于插件内部 `skills/pensieve/`
  - tools / scripts / 系统 knowledge / 格式规范 README
  - **不内置 pipelines / maxims 内容**
- **用户数据（项目级，永不覆盖）**：位于项目内 `.claude/pensieve/`
  - `maxims/`：你的个人/团队准则（例如 `custom.md`）
  - `decisions/`：项目决策记录
  - `knowledge/`：你补充的外部资料
  - `pipelines/`：项目级自定义流程（安装时写入初始 pipeline）
  - `loop/`：loop 运行产物与沉淀（每次 loop 一个目录）

## 内置 Tool（四种）

### 1) Loop Tool

**何时用**：
- 任务较复杂，需要拆分/自动循环执行

**入口**：
- 命令：`commands/loop.md`
- Tool 文件：`tools/loop/_loop.md`

**触发词**：
- `loop` / “用 loop”

### 2) Self‑Improve Tool

**何时用**：
- 用户明确要求改进 Pensieve（pipeline/脚本/规则/行为）
- Loop 结束后需要闭环学习

**入口**：
- 命令：`commands/selfimprove.md`
- Tool 文件：`tools/self-improve/_self-improve.md`

**触发词**：
- “自改进” / “改进 Pensieve”

### 3) Pipeline Tool

**何时用**：
- 用户想查看“当前项目有哪些 pipeline”

**入口**：
- 命令：`commands/pipeline.md`
- Tool 文件：`tools/pipeline/_pipeline.md`

**触发词**：
- “pipeline” / “使用 pipeline”

### 4) Upgrade Tool

**何时用**：
- 用户需要把旧结构的用户数据迁移到新的 `.claude/pensieve/` 目录
- 用户询问“理想用户数据结构是什么”

**入口**：
- 命令：`commands/upgrade.md`
- Tool 文件：`tools/upgrade/_upgrade.md`

**触发词**：
- “升级” / “迁移用户数据”

---

SessionStart hook 会把“插件系统能力路径”和“项目级用户数据路径”注入到上下文，作为运行时的唯一真相源。
